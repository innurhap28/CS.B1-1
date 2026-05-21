#!/bin/bash

# 인스턴스 이름 설정
VM_NAME="ubuntu-2404-dev"

echo "🚀 OrbStack을 사용하여 Ubuntu 24.04 인스턴스 생성을 시작합니다..."

# 1. OrbStack 인스턴스 생성 (Ubuntu 24.04 이미지 사용)
# -u noble 은 Ubuntu 24.04의 코드네임입니다.
orb create ubuntu:noble $VM_NAME

# 2. 인스턴스 시작
echo "⌛ 인스턴스 시작 중..."
orb start $VM_NAME

# 3. 내부 환경 설정 (업데이트 및 필수 도구 설치)
echo "📦 내부 패키지 업데이트 및 기본 도구 설치 중..."
orb -m $VM_NAME sudo apt-get update
orb -m $VM_NAME sudo apt-get upgrade -y
orb -m $VM_NAME sudo apt-get install -y build-essential curl git wget net-tools

# 과제 수행에 필요한 도구 설치
orb -m $VM_NAME sudo apt-get install -y openssh-server ufw acl

# 4. 완료 메시지
echo "---"
echo "✅ OrbStack Ubuntu 24.04 빌드 완료!"
echo "접속하려면 다음 명령어를 입력하세요:"
echo "👉 orb -m $VM_NAME"
echo "---"