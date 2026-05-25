#!/bin/bash

APP_NAME="agent-app-linux-x86"
APP_PORT="15034"

LOG_DIR="/var/log/agent-app"
LOG_FILE="$LOG_DIR/monitor.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PID=$$

# 로그 디렉토리 확인
mkdir -p "$LOG_DIR"

# process health check
if ! pgrep -f "$APP_NAME" > /dev/null; then
    echo "[$TIMESTAMP] [ERROR] process not running" >> "$LOG_FILE"
    exit 1
fi

# port health check
if ! ss -lntp | grep -q ":$APP_PORT "; then
    echo "[$TIMESTAMP] [ERROR] port $APP_PORT not listening" >> "$LOG_FILE"
    exit 1
fi

# firewall check
FIREWALL_STATUS="ACTIVE"

if ! ufw status | grep -q "Status: active"; then
    FIREWALL_STATUS="INACTIVE"
    echo "[$TIMESTAMP] [WARNING] firewall inactive" >> "$LOG_FILE"
fi

# resource usage
CPU=$(top -bn1 | awk '/Cpu\(s\)/ {print int(100 - $8)}')
MEM=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')
DISK=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

WARNING="NONE"

if [ "$CPU" -gt 20 ]; then
    WARNING="CPU"
fi

if [ "$MEM" -gt 10 ]; then
    WARNING="$WARNING MEM"
fi

if [ "$DISK" -gt 80 ]; then
    WARNING="$WARNING DISK"
fi

# logging
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}% FIREWALL:${FIREWALL_STATUS} WARNING:${WARNING}" >> "$LOG_FILE"

exit 0