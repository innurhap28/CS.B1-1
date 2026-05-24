#!/bin/bash

# OrbStack 업데이트 문구 삭제
run_vm() {
    orb -m ubuntu-2404-dev "$@" 2>&1 \
    | tr -d '\r' \
    | sed '/╭────────────────/,+8d'
}


# 03-1.
# 디렉토리 권한 기본 설정

# 기본 소유권 설정
run_vm sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app
run_vm sudo chown -R agent-admin:agent-core /home/agent-admin/agent-app/api_keys
run_vm sudo chown -R agent-dev:agent-core /home/agent-admin/agent-app/bin
run_vm sudo chown -R agent-admin:agent-core /var/log/agent-app

# 기본 권한 설정
# setgid bit을 설정하여 새 파일 생성 시 그룹 자동 상속
run_vm sudo chmod 2770 /home/agent-admin/agent-app/upload_files
run_vm sudo chmod 2770 /home/agent-admin/agent-app/api_keys
run_vm sudo chmod 2770 /home/agent-admin/agent-app/bin
run_vm sudo chmod 2770 /var/log/agent-app


# 03-2.
# ACL 설정
run_vm sudo setfacl -R -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files
run_vm sudo setfacl -R -d -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files

run_vm sudo setfacl -R -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys
run_vm sudo setfacl -R -d -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys

run_vm sudo setfacl -R -m g:agent-core:rwx /home/agent-admin/agent-app/bin
run_vm sudo setfacl -R -d -m g:agent-core:rwx /home/agent-admin/agent-app/bin

run_vm sudo setfacl -R -m g:agent-core:rwx /var/log/agent-app
run_vm sudo setfacl -R -d -m g:agent-core:rwx /var/log/agent-app

# monitor.sh 권한 설정
# run_vm sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
# run_vm sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh

# ACL 확인
run_vm sudo getfacl /home/agent-admin/agent-app/upload_files
echo ""
echo "권한이 잘 부여되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."