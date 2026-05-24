#!/bin/bash

VM_NAME="ubuntu-2404-dev"

# OrbStack 업데이트 문구 삭제
run_vm() {
    orb -m $VM_NAME "$@" 2>&1 \
    | tr -d '\r' \
    | sed '/╭────────────────/,+8d'
}


# 01-1. 
# SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정
run_vm sudo sed -i 's/#Port 22/Port 20022/g' /etc/ssh/sshd_config
run_vm sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config

# 변경 사항 적용
# Ubuntu 24.04는 ssh.socket도 사용되므로 포트 변경 적용 시 socket 비활성화가 필요
run_vm sudo systemctl disable --now ssh.socket || true
run_vm sudo systemctl restart ssh

# 포트 변경 적용 여부 확인
run_vm sudo ss -tulnp | grep 20022

echo ""
echo "SSH 설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."


# 01-2. 
# 외부에서 들어오는 연결 비허용 및 서버가 외부로 나가는 통신 허용
run_vm sudo ufw default deny incoming
run_vm sudo ufw default allow outgoing

# 인바운드 허용 포트 20022/tcp, 15034/tcp
run_vm sudo ufw allow 20022/tcp
run_vm sudo ufw allow 15034/tcp

# 방화벽(UFW) 활성화
run_vm sudo ufw enable

# 적용 여부 확인
run_vm sudo ufw status

echo ""
echo "UFW 설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."