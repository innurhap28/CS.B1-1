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