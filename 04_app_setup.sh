#!/bin/bash

# OrbStack 업데이트 문구 삭제
run_vm() {
    orb -m ubuntu-2404-dev "$@" 2>&1 \
    | tr -d '\r' \
    | sed '/╭────────────────/,+8d'
}


# 04-1. 
# 환경 변수
run_vm sudo -u agent-admin bash -c 'grep -q "AGENT_HOME" /home/agent-admin/.bashrc || cat <<EOF >> /home/agent-admin/.bashrc

export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=\$AGENT_HOME/upload_files
export AGENT_KEY_PATH=\$AGENT_HOME/api_keys
export AGENT_LOG_DIR=/var/log/agent-app

EOF'

# 적용 확인
run_vm sudo -u agent-admin bash -ic 'echo $AGENT_HOME'
run_vm sudo -u agent-admin bash -ic 'echo $AGENT_PORT'
run_vm sudo -u agent-admin bash -ic 'echo $AGENT_UPLOAD_DIR'
run_vm sudo -u agent-admin bash -ic 'echo $AGENT_KEY_PATH'
run_vm sudo -u agent-admin bash -ic 'echo $AGENT_LOG_DIR'
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."


# 04-2. 
# 키 파일 생성
run_vm sudo -u agent-admin bash -ic 'echo "agent_api_key_test" > $AGENT_KEY_PATH/secret.key'
run_vm sudo -u agent-admin bash -ic 'chmod 660 $AGENT_KEY_PATH/secret.key'

# 적용 확인
run_vm sudo -u agent-admin bash -ic 'ls -l $AGENT_KEY_PATH'
echo ""
echo "설정이 정상 적용되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."


# 04-3. 
# agent_app 앱 설정

run_vm sudo pkill -f agent-app-linux-x86 || true     # 기존 실행이 존재할 시 종료시킴

run_vm sudo -u agent-admin bash -ic 'cp /mnt/mac/Users/innuendo3712/Downloads/agent-app/agent-app-linux-x86 $AGENT_HOME/'
run_vm sudo -u agent-admin bash -ic 'chmod +x $AGENT_HOME/agent-app-linux-x86'

run_vm sudo -u agent-admin bash -ic 'nohup $AGENT_HOME/agent-app-linux-x86 > /tmp/agent-app.log 2>&1 &'

sleep 3

# BOOT Sequence 확인
run_vm cat /tmp/agent-app.log
echo ""
echo "Boot Sequence 5단계가 모두 [OK]로 출력되었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."

# 포트 LISTEN 확인
sleep 3
run_vm sudo ss -tulnp | grep 15034
echo ""
echo "앱이 정상적으로 포트를 열었는지 확인하세요."
read -p "다음 단계로 진행하려면 Enter를 누르세요..."
