#!/bin/bash

VM_NAME="ubuntu-2404-dev"

# OrbStack 업데이트 문구 삭제
run_vm() {
    orb -m $VM_NAME "$@" 2>&1 \
    | tr -d '\r' \
    | sed '/╭────────────────/,+8d'
}


# 02-1.
# 그룹(agent-core/common) 및 계정(agent-admin/dev/test) 생성
run_vm sudo groupadd agent-core
run_vm sudo groupadd agent-common

run_vm sudo useradd -m agent-admin
run_vm sudo useradd -m agent-dev
run_vm sudo useradd -m agent-test

# 사용자의 기본 로그인 쉘을 bash로 변경
run_vm sudo usermod -s /bin/bash agent-admin
run_vm sudo usermod -s /bin/bash agent-dev
run_vm sudo usermod -s /bin/bash agent-test

# 그룹에 계정을 할당
run_vm sudo usermod -aG agent-common agent-admin
run_vm sudo usermod -aG agent-common agent-dev
run_vm sudo usermod -aG agent-common agent-test
run_vm sudo usermod -aG agent-core agent-admin
run_vm sudo usermod -aG agent-core agent-dev

# 적용 확인
run_vm id agent-admin
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

run_vm id agent-dev
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

run_vm id agent-test
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."


# 02-2. 
# 디렉토리 구조 설정
run_vm sudo mkdir -p /home/agent-admin/agent-app/{upload_files,api_keys,bin}
run_vm sudo ls -la /home/agent-admin/agent-app
echo ""
echo "디렉토리가 잘 생성되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

run_vm sudo mkdir -p /var/log/agent-app
run_vm sudo ls -ld /var/log/agent-app
echo ""
echo "디렉토리가 잘 생성되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."
