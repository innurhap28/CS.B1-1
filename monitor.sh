#!/bin/bash

APP_NAME="agent_app"
PORT="15034"

LOG_DIR="/var/log/agent-app"
LOG_FILE="$LOG_DIR/monitor.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PID=$$

########################################
# 1. 프로세스 체크
########################################

pgrep -f "$APP_NAME" > /dev/null

if [ $? -ne 0 ]; then
    echo "[ERROR] $APP_NAME process not running"
    exit 1
fi

########################################
# 2. 포트 LISTEN 체크
########################################

ss -tuln | grep ":$PORT " | grep LISTEN > /dev/null

if [ $? -ne 0 ]; then
    echo "[ERROR] Port $PORT not listening"
    exit 1
fi

########################################
# 3. 방화벽 상태 체크
########################################

if command -v ufw > /dev/null; then
    ufw status | grep -i active > /dev/null

    if [ $? -ne 0 ]; then
        echo "[WARNING] UFW inactive"
    fi

elif command -v firewall-cmd > /dev/null; then
    firewall-cmd --state > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "[WARNING] firewalld inactive"
    fi
fi

########################################
# 4. 시스템 자원 수집
########################################

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM=$(free | awk '/Mem:/ {printf("%.1f"), $3/$2 * 100}')
DISK=$(df / | awk 'END {gsub("%",""); print $5}')

########################################
# 5. 임계값 경고
########################################

CPU_INT=${CPU%.*}

if [ "$CPU_INT" -gt 20 ]; then
    echo "[WARNING] CPU usage high: ${CPU}%"
fi

MEM_INT=${MEM%.*}

if [ "$MEM_INT" -gt 10 ]; then
    echo "[WARNING] Memory usage high: ${MEM}%"
fi

if [ "$DISK" -gt 80 ]; then
    echo "[WARNING] Disk usage high: ${DISK}%"
fi

########################################
# 6. 로그 기록
########################################

echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"