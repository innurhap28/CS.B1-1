#!/bin/bash

VM_NAME="ubuntu-2404-dev"


# 02-1.
# 그룹(agent-core/common) 및 계정(agent-admin/dev/test) 생성
orb -m $VM_NAME sudo groupadd agent-core
orb -m $VM_NAME sudo groupadd agent-common

orb -m $VM_NAME sudo useradd -m agent-admin
orb -m $VM_NAME sudo useradd -m agent-dev
orb -m $VM_NAME sudo useradd -m agent-test

# 사용자의 기본 로그인 쉘을 bash로 변경
orb -m $VM_NAME sudo usermod -s /bin/bash agent-admin
orb -m $VM_NAME sudo usermod -s /bin/bash agent-dev
orb -m $VM_NAME sudo usermod -s /bin/bash agent-test

# 그룹에 계정을 할당
orb -m $VM_NAME sudo usermod -aG agent-common agent-admin
orb -m $VM_NAME sudo usermod -aG agent-common agent-dev
orb -m $VM_NAME sudo usermod -aG agent-common agent-test
orb -m $VM_NAME sudo usermod -aG agent-core agent-admin
orb -m $VM_NAME sudo usermod -aG agent-core agent-dev

# 적용 확인
orb -m $VM_NAME id agent-admin
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

orb -m $VM_NAME id agent-dev
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

orb -m $VM_NAME id agent-test
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."


# 02-2. 
# 디렉토리 구조 설정
orb -m $VM_NAME sudo mkdir -p /home/agent-admin/agent-app/{upload_files,api_keys,bin}
orb -m $VM_NAME sudo ls -la /home/agent-admin/agent-app
echo ""
echo "디렉토리가 잘 생성되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

orb -m $VM_NAME sudo mkdir -p /var/log/agent-app
orb -m $VM_NAME sudo ls -ld /var/log/agent-app
echo ""
echo "디렉토리가 잘 생성되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."


# 02-3. 
# 디렉토리 권한 설정
