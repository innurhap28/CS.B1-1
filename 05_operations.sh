#!/bin/bash

# OrbStack 업데이트 문구 삭제
run_vm() {
    orb -m ubuntu-2404-dev "$@" 2>&1 \
    | tr -d '\r' \
    | sed '/╭────────────────/,+8d'
}


# 05-1. 
# monitor.sh 생성
run_vm sudo tee /home/agent-admin/agent-app/bin/monitor.sh > /dev/null << 'EOF'
#!/bin/bash

AGENT_HOME=/home/agent-admin/agent-app
LOG_DIR=/var/log/agent-app
LOG_FILE=$LOG_DIR/monitor.log

PID=$$

# 프로세스 체크
pgrep -f agent-app-linux-x86 > /dev/null
if [ $? -ne 0 ]; then
  echo "[ERROR] process not running"
  exit 1
fi

# 포트 체크
ss -tulnp | grep 15034 > /dev/null
if [ $? -ne 0 ]; then
  echo "[ERROR] port not listening"
  exit 1
fi

# CPU / MEM / DISK
CPU=$(top -bn1 | awk -F',' '/Cpu\(s\)/ {print 100 - $8}')
MEM=$(free | awk '/Mem:/ {printf "%.2f", $3/$2 * 100}')
DISK=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

WARN=""

[ "${CPU%.*}" -gt 20 ] && WARN="$WARN CPU"
[ "${MEM%.*}" -gt 10 ] && WARN="$WARN MEM"
[ "$DISK" -gt 80 ] && WARN="$WARN DISK"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}% WARN:$WARN" >> $LOG_FILE

# firewall check (warning only)
ufw status >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "[WARNING] firewall inactive" >> $LOG_FILE
fi

exit 0
EOF

# 권한 설정
run_vm sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
run_vm sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh

run_vm sudo chown -R root:agent-core /var/log/agent-app
run_vm sudo chmod 2770 /var/log/agent-app


# 05-2. 
# 자동 실행(cron) 설정
run_vm sudo -u agent-admin bash -c '(crontab -l 2>/dev/null; echo "* * * * * /home/agent-admin/agent-app/bin/monitor.sh") | crontab -'

run_vm sudo -u agent-admin crontab -l
echo ""
echo "Cron 등록이 되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

echo ""
echo "monitor log 생성 확인까지 1분이 소요됩니다."

sleep 60

run_vm sudo tail -n 10 /var/log/agent-app/monitor.log
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

# 상태 겁증
run_vm pgrep -f agent-app-linux-x86 || echo "[FAIL] process"
run_vm sudo ss -tulnp | grep 15034 || echo "[FAIL] port"

echo ""
echo "검증이 완료되었습니다."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."