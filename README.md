# 시스템 관제 자동화 스크립트 개발


## 01. 프로젝트 개요

본 프로젝트는 리눅스 기반 서버 환경에서 다음을 직접 구성하고 자동화하는 것을 목표로 한다.


## 02. 프로젝트 체크리스트
- [x] SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정
- [x] 방화벽(UFW) 활성화 및 20022/tcp, 15034/tcp만 허용
- [x] 계정(agent-admin/dev/test) 및 그룸(agent-common/core) 생성
- [x] 디렉토리 구조 및 권한(ACL 포함) 
- [x] 앱 Boot Sequence 5단계 [OK] 및 "Agent READY" 확인
- [x] monitor.sh 실행 결과(프로세스/포트/리소스/경고)
- [x] /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인)
- [x] crontab 매분 실행 등록 및 자동 실행 확인 (1분 후 로그 증가)


## 03. 수행 내역

## 03-1. SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정

본 단계에서는 SSH 기본 설정을 수정하여 외부 공격 가능성을 줄이고, root 계정의 원격 접속을 차단하여 서버 보안 수준을 강화하였다.

---

### 1) SSH 설정 파일 수정

SSH 설정 파일(/etc/ssh/sshd_config)을 수정하여 포트 및 root 로그인 정책을 변경한다.

#### (1) sed를 이용한 자동 수정
```
sudo sed -i 's/#Port 22/Port 20022/g' /etc/ssh/sshd_config  
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config  
```
---

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

### 4) 정리

- SSH 기본 포트(22)를 20022로 변경하여 외부 공격 표면을 축소하였다.
- root 계정의 원격 SSH 로그인을 차단하여 보안성을 강화하였다.
- Ubuntu 24.04의 ssh.socket 구조를 고려하여 서비스 재시작을 수행하였다.
- ss 명령어를 통해 포트 변경이 정상적으로 반영되었는지 검증하였다.

### 03-2. 방화벽(UFW) 활성화 및 20022/tcp, 15034/tcp만 허용

### 03-3. 계정(agent-admin/dev/test) 및 그룸(agent-common/core) 생성

### 03-4. 디렉토리 구조 및 권한(ACL 포함) 

### 03-5. 앱 Boot Sequence 5단계 [OK] 및 "Agent READY" 확인

### 03-6. monitor.sh 실행 결과(프로세스/포트/리소스/경고)

### 03-7. /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인)

### 03-8. crontab 매분 실행 등록 및 자동 실행 확인 (1분 후 로그 증가)