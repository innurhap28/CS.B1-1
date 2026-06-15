#!/bin/bash

source ../library.sh


# 05-1. 
# monitor.sh 생성
run_vm sudo tee /home/agent-admin/agent-app/bin/monitor.sh > /dev/null << 'EOF'
#!/bin/bash

APP_NAME="agent-app-linux-x86"
APP_PORT="15034"
LOG_DIR="/var/log/agent-app"
LOG_FILE="$LOG_DIR/monitor.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PID=$$
APP_PID=$(pgrep -f "$APP_NAME" | head -n 1)

mkdir -p "$LOG_DIR"
echo "===== SYSTEM MONITOR RESULT ====="

# Health Check (실패 시 종료) : Process
echo "[HEALTH CHECK]"
if ! pgrep -f "$APP_NAME" > /dev/null; then
    echo "[$TIMESTAMP] [ERROR] process not running" >> "$LOG_FILE"
    exit 1
else echo "Checking process '$APP_NAME'... [OK] (PID=$APP_PID)"
fi

# Health Check (실패 시 종료) : Port
if ! ss -lntp | grep -q ":$APP_PORT "; then
    echo "[$TIMESTAMP] [ERROR] port $APP_PORT not listening" >> "$LOG_FILE"
    exit 1
else echo "Checking port $APP_PORT... [OK]"
fi

# Firewall Check (경고만 출력)
FIREWALL_STATUS="INACTIVE"

if systemctl is-active --quiet ufw 2>/dev/null; then
    FIREWALL_STATUS="ACTIVE"
elif [ -r /etc/ufw/ufw.conf ] && grep -qE '^ENABLED=yes' /etc/ufw/ufw.conf 2>/dev/null; then
    FIREWALL_STATUS="ACTIVE"
elif systemctl is-active --quiet firewalld 2>/dev/null; then
    FIREWALL_STATUS="ACTIVE"
fi

if [[ "${FIREWALL_STATUS}" != "ACTIVE" ]]; then
    echo "[WARNING] Firewall is not active."
fi

# Resource Usage (경고만 출력)
CPU=$(top -bn1 | awk '/Cpu\(s\)/ {print int(100 - $8)}')
MEM=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')
DISK=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

echo "[RESOURCE MONITORING]"
echo "CPU Usage : $CPU%"
echo "MEM Usage : $MEM%"
echo "DISK Used : $DISK%"

if [ "$CPU" -gt 20 ]; then
    WARNING="${WARNING}CPU,"
    echo "[WARNING] CPU usage high: ${CPU}% > 20%"
fi

if [ "$MEM" -gt 10 ]; then
    WARNING="${WARNING}MEM,"
    echo "[WARNING] MEM usage high: ${MEM}% > 10"
fi

if [ "$DISK" -gt 80 ]; then
    WARNING="${WARNING}DISK,"
    echo "[WARNING] DISK usage high: ${DISK}% > 80"
fi

# Log Rotation
MAX_SIZE=$((10 * 1024 * 1024))
MAX_FILES=10

if [ -f "$LOG_FILE" ]; then
    FILE_SIZE=$(stat -c%s "$LOG_FILE")

    if [ "$FILE_SIZE" -ge "$MAX_SIZE" ]; then

        # 9 -> 10, 8 -> 9 ...
        for ((i=MAX_FILES-1; i>=1; i--)); do
            if [ -f "${LOG_FILE}.${i}" ]; then
                mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
            fi
        done

        # 현재 로그를 .1로 이동
        mv "$LOG_FILE" "${LOG_FILE}.1"

        # 10개 초과 삭제
        [ -f "${LOG_FILE}.11" ] && rm -f "${LOG_FILE}.11"

        touch "$LOG_FILE"
    fi
fi

# logging
echo ""
echo "[$TIMESTAMP] PID:$APP_PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}% FIREWALL:${FIREWALL_STATUS} WARNING:${WARNING}" >> "$LOG_FILE"
echo "[INFO] Log appended: /var/log/agent-app/monitor.log"

exit 0
EOF

run_vm sudo bash /home/agent-admin/agent-app/bin/monitor.sh

prompt_step "monitor.sh이 정상적으로 출력되는지 확인하세요."

# 권한 설정
run_vm sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
run_vm sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh

run_vm sudo chown -R root:agent-core /var/log/agent-app
run_vm sudo chmod 2770 /var/log/agent-app


# 05-2. 
# 자동 실행(cron) 설정
run_vm sudo -u agent-admin bash -c '(crontab -l 2>/dev/null; echo "* * * * * /home/agent-admin/agent-app/bin/monitor.sh") | crontab -'

run_vm sudo -u agent-admin crontab -l
prompt_step "Cron 등록이 되었는지 확인하세요."

echo ""
echo "monitor log 생성 확인까지 1분이 소요됩니다."

echo "Before:"
run_vm sudo wc -l /var/log/agent-app/monitor.log

echo ""
echo "1분 대기 중..."
sleep 65

echo ""
echo "After:"
run_vm sudo wc -l /var/log/agent-app/monitor.log

echo ""
echo "최근 로그:"
run_vm sudo tail -n 10 /var/log/agent-app/monitor.log

# 상태 겁증
run_vm pgrep -f agent-app-linux-x86 || echo "[FAIL] process"
run_vm sudo ss -tulnp | grep 15034 || echo "[FAIL] port"

prompt_step "검증이 완료되었습니다."