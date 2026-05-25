# 시스템 관제 자동화 스크립트 개발


## 01. 프로젝트 개요

본 프로젝트는 리눅스 기반 서버 환경에서 다음을 직접 구성하고 자동화하는 것을 목표로 한다.


## 02. 프로젝트 체크리스트
- [x] [SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정](#03-1-ssh-포트-변경20022-및-root-원격-접속-차단-설정)
- [x] [방화벽(UFW) 활성화 및 20022/tcp, 15034/tcp만 허용](#03-2-방화벽ufw-활성화-및-20022tcp-15034tcp만-허용)
- [x] [계정(agent-admin/dev/test) 및 그룸(agent-common/core) 생성](#03-3-계정agent-admindevtest-및-그룸agent-commoncore-생성)
- [x] [디렉토리 구조 및 권한(ACL 포함)](#03-4-디렉토리-구조-및-권한acl-포함)
- [x] [앱 Boot Sequence 5단계 [OK] 및 "Agent READY" 확인](#03-5-앱-boot-sequence-5단계-ok-및-agent-ready-확인)
- [x] [monitor.sh 실행 결과(프로세스/포트/리소스/경고)](#03-6-monitorsh-실행-결과프로세스포트리소스경고)
- [x] [/var/log/agent-app/monitor.log 누적 기록 확인(최근 라인)](#03-7-varlogagent-appmonitorlog-누적-기록-확인최근-라인)
- [x] [crontab 매분 실행 등록 및 자동 실행 확인 (1분 후 로그 증가)](#03-8-crontab-매분-실행-등록-및-자동-실행-확인-1분-후-로그-증가)


## 03. 수행 내역

## 03-1. SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정

> 본 단계에서는 SSH 기본 설정을 수정하여 외부 공격 가능성을 줄이고, root 계정의 원격 접속을 차단하여 서버 보안 수준을 강화하였다.

---
### 1) SSH 설정 파일 수정
SSH 설정 파일(/etc/ssh/sshd_config)을 수정하여 포트 및 root 로그인 정책을 변경한다.

#### (1) sed를 이용한 자동 수정
```
sudo sed -i 's/#Port 22/Port 20022/g' /etc/ssh/sshd_config  
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config  
```

#### (2) vi를 이용한 수동 수정
```
sudo vi /etc/ssh/sshd_config  
```
파일에서 아래 항목을 찾는다.
```
#Port 22  
#PermitRootLogin prohibit-password  
```
다음과 같이 수정한다.
```
Port 20022  
PermitRootLogin no  
```
---

### 2) Ubuntu 24.04 (ssh.socket 처리)
Ubuntu 24.04에서는 systemd의 ssh.socket이 기본 활성화되어 있어 설정 변경만으로 포트가 즉시 반영되지 않을 수 있다.  
따라서 socket을 비활성화한 후 SSH 서비스를 재시작해야 한다.
```
sudo systemctl disable --now ssh.socket || true  
sudo systemctl restart ssh  
```
---

### 3) 설정 적용 확인
SSH 포트가 정상적으로 변경되었는지 확인한다.
```
sudo ss -tulnp | grep 20022  
sudo ss -tulnp | grep ssh  
```
둘 중 하나에서라도 20022 포트가 LISTEN 상태로 출력되면 정상 적용된 것이다.

---

### 4) 설계 의도
- SSH 기본 포트(22)를 20022로 변경하여 외부 공격 표면을 축소하였다.
- root 계정의 원격 SSH 로그인을 차단하여 보안성을 강화하였다.
- Ubuntu 24.04의 ssh.socket 구조를 고려하여 서비스 재시작을 수행하였다.
- ss 명령어를 통해 포트 변경이 정상적으로 반영되었는지 검증하였다.


---
## 03-2. 방화벽(UFW) 활성화 및 20022/tcp, 15034/tcp만 허용

> 본 단계에서는 UFW(Uncomplicated Firewall)를 활성화하여 서버의 네트워크 접근을 제어하고, 요구된 서비스 포트만 최소 개방하는 보안 정책을 구성하였다.  
이를 통해 기본적으로 모든 인바운드 트래픽을 차단하고, 필요한 포트만 명시적으로 허용하는 “최소 권한 네트워크 정책”을 적용하였다.

**UFW를 본 과제에서 채택한 이유:**

UFW는 Ubuntu 기본 환경과 높은 호환성을 가지며, firewalld보다 설정이 단순하고 직관적이어서 최소 권한 기반 방화벽 정책을 빠르게 구성하고 검증할 수 있기 때문에 선택하였다.

---
### 1) 기본 정책 설정
```
sudo ufw default deny incoming  
sudo ufw default allow outgoing
```
UFW의 기본 동작 방식을 “전체 차단 → 예외 허용” 구조로 변경

- incoming deny: 외부에서 들어오는 모든 요청을 기본적으로 차단
- outgoing allow: 서버가 외부로 나가는 요청은 허용 (패키지 업데이트, API 호출 등 정상 운영 유지)

서버는 외부에서 직접 접근이 불가능한 상태가 된다.

---
### 2) 필수 포트 허용
기본 차단 정책에서 예외적으로 허용할 포트를 정의한다. 
```
sudo ufw allow 20022/tcp  
sudo ufw allow 15034/tcp  
```
- 20022/tcp: SSH 원격 접속 포트 (관리자 접근용)
- 15034/tcp: 애플리케이션 서비스 포트 (앱 외부 제공용)

서버가 완전히 닫혀 있는 상태에서 **딱 두 개의 서비스만 외부에 공개되는 구조**로 제한된다.

---
### 3) 방화벽 활성화 및 적용 확인
```
sudo ufw enable  
sudo ufw status  
```

---
### 4) 설계 의도
- 기본 inbound 차단으로 외부 공격 표면 최소화
- SSH(20022), APP(15034)만 허용하여 서비스 단순화
- 정책 기반 네트워크 접근 제어 구성


---
## 03-3. 계정(agent-admin/dev/test) 및 그룸(agent-common/core) 생성
> 본 단계에서는 다중 사용자 환경에서 역할 기반 권한 분리를 구현하기 위해 계정과 그룹을 생성하였다.  
리눅스 서버는 기본적으로 모든 사용자가 동일한 자원에 접근할 수 있는 구조이기 때문에, 실제 운영 환경에서는 역할별 계정을 분리하고 그룹 단위로 권한을 제어하는 방식이 필수적이다.  
이를 통해 최소 권한 원칙(Principle of Least Privilege)을 적용한 사용자 관리 구조를 구성한다.

---

### 1) 그룹 생성
서버 내 권한 단위를 정의하기 위해 두 개의 그룹을 생성한다.

- agent-core: 핵심 시스템 및 민감 자원 접근 그룹  
- agent-common: 일반 공유 자원 접근 그룹  
```
sudo groupadd agent-core  
sudo groupadd agent-common  
```
---

### 2) 계정 생성
역할에 따라 3개의 사용자 계정을 생성하며 기본 로그인 쉘을 bash로 지정한다. 

- agent-admin: 운영 및 관리 담당  
- agent-dev: 개발 및 시스템 구성 담당  
- agent-test: 테스트 및 검증 담당  
```
sudo useradd -m -s /bin/bash agent-admin  
sudo useradd -m -s /bin/bash agent-dev  
sudo useradd -m -s /bin/bash agent-test  
```
---

### 3) 그룹 할당
각 계정을 역할에 맞는 그룹에 추가하여 권한을 분리한다.
```
sudo usermod -aG agent-common agent-admin  
sudo usermod -aG agent-common agent-dev  
sudo usermod -aG agent-common agent-test  

sudo usermod -aG agent-core agent-admin  
sudo usermod -aG agent-core agent-dev  
```
---

### 4) 설정 확인
계정별 그룹 할당 상태를 확인하여 정상 적용 여부를 검증한다.
```
id agent-admin  
id agent-dev  
id agent-test  
```
---

### 5) 설계 의도
- 운영/개발/테스트 계정을 분리하여 역할 기반 접근 제어 구조 구성  
- 그룹 단위 권한 관리를 통해 개별 사용자 권한 설정 부담 최소화  
- agent-core / agent-common 분리를 통해 민감 자원 접근 통제  
- 최소 권한 원칙을 기반으로 한 서버 보안 구조 설계  


---
## 03-4. 디렉토리 구조 및 권한(ACL 포함)

> 본 단계에서는 서비스 운영에 필요한 디렉토리 구조를 구성하고, 그룹 기반 권한 설정과 ACL을 함께 적용하여 디렉토리 접근 제어를 설계하였다.  
리눅스 기본 권한(chmod/chown)만으로는 디렉토리 내부에서 생성되는 파일의 권한까지 일관되게 제어하기 어렵기 때문에, ACL을 함께 사용하여 보다 정밀한 권한 통제를 구현한다.

---

### 1) 디렉토리 구조 생성
서비스 실행 및 데이터 분리를 위해 AGENT_HOME 기준 디렉토리를 구성한다.
```
sudo mkdir -p /home/agent-admin/agent-app/upload_files  
sudo mkdir -p /home/agent-admin/agent-app/api_keys  
sudo mkdir -p /home/agent-admin/agent-app/bin  
sudo mkdir -p /var/log/agent-app  
```
---

### 2) 기본 소유권 및 권한 설정

각 디렉토리는 역할에 따라 소유자와 그룹을 분리하여 기본 접근 권한을 설정한다.
```
sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app  
sudo chown -R agent-admin:agent-core /home/agent-admin/agent-app/api_keys  
sudo chown -R agent-dev:agent-core /home/agent-admin/agent-app/bin  
sudo chown -R agent-admin:agent-core /var/log/agent-app  

sudo chmod 2770 /home/agent-admin/agent-app/upload_files  
sudo chmod 2770 /home/agent-admin/agent-app/api_keys  
sudo chmod 2770 /home/agent-admin/agent-app/bin  
sudo chmod 2770 /var/log/agent-app  
```
---

### 3) ACL 설정

디렉토리 단위 권한 외에도 ACL을 적용하여 그룹별 세부 접근 권한을 추가로 제어한다.
```
sudo setfacl -R -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files  
sudo setfacl -R -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys  
sudo setfacl -R -m g:agent-core:rwx /home/agent-admin/agent-app/bin  
sudo setfacl -R -m g:agent-core:rwx /var/log/agent-app  
```
---

### 4) ACL을 사용하는 이유 (핵심 개념)

ACL을 사용하는 가장 중요한 이유는 **디렉토리 권한과 파일 생성 권한이 자동으로 동일하게 유지되지 않기 때문**이다.

기본 chmod/chown 방식에서는:

- 디렉토리에 권한을 설정해도  
- 내부에서 새로 생성되는 파일은 생성 시점의 umask 영향을 받음  
- 결과적으로 권한이 “따로 설정된 파일”이 되어버림

즉, 디렉토리 안에서 생성된 파일이 기존 권한 정책을 벗어나 **일관되지 않은 권한 구조**가 될 수 있다.

이를 해결하기 위해 ACL을 사용하면:

- 기본 권한 외에도 그룹 권한을 강제 유지 가능
- 디렉토리 내부에서 생성되는 파일에도 동일한 접근 정책 적용 가능
- 운영 환경에서 권한 일관성 확보 가능

---

### 5) 설계 의도

- upload_files: 일반 공유 영역 (agent-common 접근)
- api_keys / logs: 민감 데이터 영역 (agent-core 제한)
- chmod + setgid + ACL 조합으로 권한 일관성 유지
- ACL을 통해 “새로 생성되는 파일까지 포함한 권한 통제” 구현


---
## 03-5. 앱 Boot Sequence 5단계 [OK] 및 "Agent READY" 확인

> 본 단계에서는 애플리케이션을 agent-admin 계정으로 실행하고, 환경변수 기반 실행 환경 및 키 파일 기반 인증 구조를 적용하여 서비스 초기화 과정을 검증하였다.  
또한 Boot Sequence 로그 및 포트 LISTEN 상태를 통해 애플리케이션이 실제 서비스 상태로 정상 전환되었는지를 확인하였다.

---

### 1) 실행 환경 구성 및 서비스 실행

애플리케이션은 root가 아닌 일반 사용자(agent-admin) 권한으로 실행되었으며,  
환경변수 기반 설정을 통해 실행 환경이 외부 설정에 의해 제어되도록 구성하였다.

또한 API 키 파일을 별도 경로로 분리하여 민감 정보가 코드와 분리된 구조를 유지하였다.

실행 명령은 다음과 같다.
```
nohup $AGENT_HOME/agent-app-linux-x86 > /tmp/agent-app.log 2>&1 &
```
---

### 2) 환경 변수 및 디렉토리 설정 확인

실행 환경은 다음과 같이 구성되어 있다.

- AGENT_HOME: /home/agent-admin/agent-app  
- AGENT_PORT: 15034  
- AGENT_UPLOAD_DIR: /home/agent-admin/agent-app/upload_files  
- AGENT_KEY_PATH: /home/agent-admin/agent-app/api_keys  
- AGENT_LOG_DIR: /var/log/agent-app  

---

### 3) 키 파일 기반 인증 구조 확인

다음 위치에 API 키 파일이 정상 생성되었음을 확인하였다.

/var/log 또는 출력 결과:
secret.key

파일 내용:
agent_api_key_test

또한 ACL 설정을 통해 agent-core 그룹이 해당 파일에 접근 가능한 구조로 구성되었다.

---

### 4) Boot Sequence 및 Agent READY 확인 결과

애플리케이션 실행 로그에서 다음과 같은 초기화 과정을 확인하였다.
```
- [1/5] User Account Check → [OK] (agent-admin 실행 확인)  
- [2/5] Environment Variables → [OK]  
- [3/5] Required Files → [OK] (secret.key 정상 인식)  
- [4/5] Port Availability → [OK] (15034 사용 가능)  
- [5/5] Log Permission → [OK] (/var/log/agent-app 쓰기 가능)  
```
최종 결과:
```
All Boot Checks Passed!  
Agent READY  
```
이 결과는 애플리케이션이 모든 의존성 및 실행 조건을 만족하고 정상적으로 서비스 상태로 전환되었음을 의미한다.

---

### 5) 서비스 포트 LISTEN 상태 확인

애플리케이션이 실제 네트워크 서비스로 동작하는지 확인하기 위해 포트 상태를 점검하였다.
```
tcp LISTEN 0 1 0.0.0.0:15034 0.0.0.0:* users:(("agent-app-linux",pid=5397,fd=4))
```
해당 결과를 통해 다음을 확인할 수 있다:

- 15034 포트가 정상적으로 LISTEN 상태
- 0.0.0.0 바인딩 → 외부 접근 가능한 서비스 상태
- agent-app 프로세스가 실제 네트워크 서비스로 동작 중

---

### 6) 설계 의도

- agent-admin 계정을 통한 비루트 서비스 실행으로 보안성 확보
- 환경변수 기반 구조를 통해 실행 환경과 코드 분리
- 키 파일 기반 인증 구조로 민감 정보 외부화
- Boot Sequence 기반 초기화 검증으로 서비스 안정성 확인
- 포트 LISTEN 확인을 통해 실제 서비스 상태까지 End-to-End 검증

## 03-6. monitor.sh 실행 결과(프로세스/포트/리소스/경고)



## 03-7. /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인)
```
innuendo3712@c5r7s3 CS.B1-1 % orb -m ubuntu-2404-dev sudo tail -n 10 /var/log/agent-app/monitor.log
[2026-05-25 23:54:02] [WARNING] firewall inactive
[2026-05-25 23:54:02] PID:4432 CPU:100% MEM:4% DISK_USED:1% FIREWALL:INACTIVE WARNING:CPU
[2026-05-25 23:55:01] [WARNING] firewall inactive
[2026-05-25 23:55:01] PID:4451 CPU:3% MEM:5% DISK_USED:1% FIREWALL:INACTIVE WARNING:NONE
[2026-05-25 23:56:01] [WARNING] firewall inactive
[2026-05-25 23:56:01] PID:4470 CPU:1% MEM:3% DISK_USED:1% FIREWALL:INACTIVE WARNING:NONE
[2026-05-25 23:57:01] [WARNING] firewall inactive
[2026-05-25 23:57:01] PID:4494 CPU:100% MEM:5% DISK_USED:1% FIREWALL:INACTIVE WARNING:CPU
[2026-05-25 23:58:01] [WARNING] firewall inactive
[2026-05-25 23:58:01] PID:4513 CPU:1% MEM:4% DISK_USED:1% FIREWALL:INACTIVE WARNING:NONE
```
## 03-8. crontab 매분 실행 등록 및 자동 실행 확인 (1분 후 로그 증가)