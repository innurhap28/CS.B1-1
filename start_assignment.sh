#!/bin/bash

bash 01_security.sh

echo "===================="
echo "01. SSH 설정 및 방화벽 설정을 완료했습니다."
read -p "다음 단계로 넘어가려면 Enter를 누르세요.."
echo "===================="

bash 02_user_setup.sh

echo "===================="
echo "02. 계정/그룹 생성 및 디렉토리 구조 생성을 완료했습니다."
read -p "다음 단계로 넘어가려면 Enter를 누르세요.."
echo "===================="

bash 03_user_modify.sh

echo "===================="
echo "03. 디렉토리 권한 설정(ACL 포함)을 완료했습니다."
read -p "다음 단계로 넘어가려면 Enter를 누르세요.."
echo "===================="

bash 04_app_setup.sh

echo "===================="
echo "03. 앱 실행 준비를 완료했습니다."
read -p "다음 단계로 넘어가려면 Enter를 누르세요.."
echo "===================="

bash 05_operations.sh

echo "===================="
echo "모든 단계를 완료했습니다."
read -p "종료하려면 Enter를 누르세요.."
echo "===================="