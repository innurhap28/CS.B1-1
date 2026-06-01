#!/bin/bash

APP_NAME="agent-app-linux-x86"
APP_PORT="15034"

LOG_DIR="/var/log/agent-app"
LOG_FILE="$LOG_DIR/monitor.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PID=$$
APP_PID=$(pgrep -f "$APP_NAME" | head -n 1)

# 로그 디렉토리 확인
mkdir -p "$LOG_DIR"

echo "===== SYSTEM MONITOR RESULT ====="

# Health Check (실패 시 종료)
# Process..
echo "[HEALTH CHECK]"
if ! pgrep -f "$APP_NAME" > /dev/null; then
    echo "[$TIMESTAMP] [ERROR] process not running" >> "$LOG_FILE"
    exit 1
    else echo "Checking process '$APP_NAME'... [OK] (PID=$APP_PID)"
fi

# Port..
if ! ss -lntp | grep -q ":$APP_PORT "; then
    echo "[$TIMESTAMP] [ERROR] port $APP_PORT not listening" >> "$LOG_FILE"
    exit 1
    else echo "Checking port $APP_PORT... [OK]"
fi

# Firewall Check (경고만 출력)
FIREWALL_STATUS="ACTIVE"

if ! ufw status | grep -q "Status: active"; then
    FIREWALL_STATUS="INACTIVE"
    echo "[$TIMESTAMP] [WARNING] firewall inactive" >> "$LOG_FILE"
fi

# Resource Usage
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

MAX_SIZE=$((10 * 1024 * 1024))
MAX_FILES=10

# Log Rotation
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