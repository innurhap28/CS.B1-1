#!/bin/bash

APP_NAME="agent-app-linux-x86"
APP_PORT="15034"

LOG_DIR="/var/log/agent-app"
LOG_FILE="$LOG_DIR/monitor.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PID=$$

# 로그 디렉토리 확인
mkdir -p "$LOG_DIR"

# Health Check (실패 시 종료)
# Process..
if ! pgrep -f "$APP_NAME" > /dev/null; then
    echo "[$TIMESTAMP] [ERROR] process not running" >> "$LOG_FILE"
    exit 1
fi

# Port..
if ! ss -lntp | grep -q ":$APP_PORT "; then
    echo "[$TIMESTAMP] [ERROR] port $APP_PORT not listening" >> "$LOG_FILE"
    exit 1
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

WARNING="NONE"

if [ "$CPU" -gt 20 ]; then
    echo "[WARNING] CPU usage high: ${CPU}%"
fi

if [ "$MEM" -gt 10 ]; then
    echo "[WARNING] MEM usage high: ${MEM}%"
fi

if [ "$DISK" -gt 80 ]; then
    echo "[WARNING] DISK usage high: ${DISK}%"
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
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}% FIREWALL:${FIREWALL_STATUS} WARNING:${WARNING}" >> "$LOG_FILE"

exit 0