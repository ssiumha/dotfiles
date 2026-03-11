# 가상화 장비 취약점 점검항목

> 출처: KISA 주요정보통신기반시설 기술적 취약점 분석평가 방법 상세가이드 (2026)
> 총 항목: 25개 (HV-01 ~ HV-25)

## 1. 계정 관리

### HV-01 계정 로그오프/세션 관리

점검ID: HV-01 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 웹 콘솔 및 사용자 Shell Session Timeout 설정 여부 점검

**판단기준**:
- ✅ 양호: 웹 콘솔 및 사용자 Shell Session Timeout 설정이 600초(10분) 이하로 설정된 경우
- ❌ 취약: 웹 콘솔 및 사용자 Shell Session Timeout 설정이 600초(10분)를 초과하여 설정된 경우

**점검방법**:

**VMware ESXi, vCenter - 웹 콘솔 Session Timeout**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `UserVars.HostClientSessionTimeout` 설정이 600초(10분) 이하인지 확인

**XenServer, KVM - Shell Session Timeout**
```bash
# Session Timeout 확인
echo $TMOUT

# 설정 파일 확인
cat /etc/profile | grep TMOUT
```

**Nutanix - Shell Session Timeout**
```bash
# Controller VM에서 확인
sudo cat /etc/profile.d/os-security.sh

# SSH Idle Timeout 확인
sudo cat /etc/ssh/sshd_config | grep "ClientAliveInterval"
```

**조치방법**:

**VMware ESXi**
- 호스트 - 관리 - 시스템 - 고급 설정 - UserVars.HostClientSessionTimeout을 600 이하로 설정

**XenServer, KVM**
```bash
# /etc/profile에 추가
readonly TMOUT=600;
export TMOUT

# 설정 적용
source /etc/profile
```

**Nutanix**
```bash
# Shell Timeout 설정
sudo vi /srv/salt/security/CVM/shellCVM.sls
# readonly TMOUT=600 으로 설정

# SSH Idle Timeout 설정
sudo vi /srv/salt/security/CVM/sshd/sshdconfCVM
# ClientAliveInterval 600 설정

# 변경 설정 적용
sudo salt-call state.sls security/CVM/shellCVM
sudo salt-call state.sls security/CVM/sshdCVM
```

---

### HV-02 가상화 장비 외부접속 차단

점검ID: HV-02 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 허용할 호스트에 대한 접속 IP 제한 설정 여부 점검

**판단기준**:
- ✅ 양호: 허용된 IP에서만 관리 콘솔 및 원격 접속이 가능하도록 제한된 경우
- ❌ 취약: 허용된 IP에서만 관리 콘솔 및 원격 접속이 가능하도록 제한되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 네트워킹 - 방화벽 규칙으로 이동
3. SSH 서버 및 vSphere 웹 클라이언트의 "허용된 IP 주소" 확인

**XenServer, KVM**
```bash
# IPTables 정책 확인
iptables -nL --line-number
```

**Nutanix**
```bash
# Controller VM 접속하여 설정 확인
sudo cat /etc/hosts.allow | grep -v "^#"
```

**조치방법**:

**VMware ESXi**
- 네트워킹 - 방화벽 규칙 - vSphere Web Client(SSH 서버) - 설정 편집
- "다음 네트워크의 연결만 허용" 선택 후 접속 허용 IP 입력

**XenServer, KVM**
```bash
# SSH 원격 접속을 허용된 IP로만 제한
iptables -I RH-Firewall-1-INPUT 1 -p tcp -s <허용IP> --dport 22 -j ACCEPT
iptables -I RH-Firewall-1-INPUT 2 -p tcp -s 0.0.0.0/0 --dport 22 -j DROP

# 변경된 정책 저장 및 재시작
service iptables save
service iptables restart
```

**Nutanix**
```bash
# hosts.allow 파일에 SSH 접속 허용 IP 설정
sudo vi /srv/salt/security/CVM/network/hosts.allow
# sshd: 192.168.100.1 : ALLOW 형식으로 추가

# 변경 설정 적용
sudo salt-call state.sls security/CVM/networkCVM
```

---

### HV-03 가상화 장비 루트계정 관리

점검ID: HV-03 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 별도의 관리자 계정을 생성하여 관리 여부 점검

**판단기준**:
- ✅ 양호: 별도의 관리자 계정을 생성하여 가상화 장비가 관리된 경우
- ❌ 취약: 루트 계정으로 가상화 장비가 관리된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 작업 - 사용 권한으로 이동
3. root 계정의 관리자 권한이 제거되고 별도의 관리자 권한이 존재하는지 확인

**조치방법**:

**VMware ESXi**
1. 별도 계정 생성: 호스트 - 관리 - 보안 및 사용자 - 사용자 추가
2. 관리자 권한 부여: 호스트 - 작업 - 사용 권한 - 사용자 추가
3. root 계정의 관리자 권한 제거

---

### HV-04 가상화 장비 계정 권한 관리

점검ID: HV-04 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 공용 계정 등 불필요한 계정이 존재하는지 여부 점검

**판단기준**:
- ✅ 양호: 불필요한 공용 계정 및 퇴사자 계정이 존재하지 않은 경우
- ❌ 취약: 불필요한 공용 계정 및 퇴사자 계정이 존재하는 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 보안 및 사용자 - 사용자로 이동
3. 등록된 계정 확인

**XenServer, KVM**
```bash
# 등록된 계정 확인
grep /bin/bash /etc/passwd | cut -f1 -d:
```

**Nutanix**
- Nutanix Web 콘솔 접속: `https://<Nutanix IP>:9440`
- Settings > Users and Roles > Local User Management 선택하여 계정 확인

**조치방법**:

**VMware ESXi**
- 호스트 - 관리 - 보안 및 사용자 - 사용자에서 불필요한 계정 삭제

**XenServer, KVM**
```bash
# 불필요한 계정 삭제
userdel -r <계정명>
```

**Nutanix**
- Settings > Users and Roles > Local User Management에서 불필요한 계정 삭제

---

### HV-05 가상화 장비 사용자 인증 강화

점검ID: HV-05 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 사용자 계정별 적절한 권한이 부여 여부 점검

**판단기준**:
- ✅ 양호: 계정별 불필요한 권한이 부여되지 않은 경우
- ❌ 취약: 계정별 불필요한 권한이 부여된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 작업 - 사용 권한으로 이동
3. 등록된 계정별 사용 권한 확인

**XenServer - Active Directory 미가입**
```bash
# bash 사용자 목록 확인
grep /bin/bash /etc/passwd | cut -f1 -d:
```

**XenServer - Active Directory 가입**
```bash
# 계정별 부여된 권한 확인
xe subject-list
```

**KVM**
```bash
# bash 계정 목록 확인
grep /bin/bash /etc/passwd | cut -f1 -d:
```

**Nutanix**
- 웹 콘솔 접속: `https://<Nutanix IP>:9440`
- Settings > Users and Roles > Local User Management에서 계정 및 권한 확인

**조치방법**:

**VMware ESXi**
- 불필요한 권한이 부여된 계정 선택 후 역할에 맞는 권한으로 변경

**XenServer - Active Directory 가입**
```bash
# 기존 역할 제거 및 새 역할 추가
xe subject-role-remove uuid=<subject uuid> role-name=<role_name_to_remove>
xe subject-role-add uuid=<subject uuid> role-name=<role_name_to_add>
```

**XenServer, KVM - 불필요한 계정 제거**
```bash
gpasswd -d <계정명> users
```

**Nutanix**
- Settings > Users and Roles > Local User Management에서 불필요한 권한 제거

---

### HV-06 비밀번호 관리정책 설정

점검ID: HV-06 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 로그인 계정에 대한 비밀번호 관리 정책 설정 여부 점검

**판단기준**:
- ✅ 양호: 로그인 계정 비밀번호 관리 정책이 적용된 경우 (영문/숫자/특수문자 2개 조합 시 10자리 이상, 3개 조합 시 8자리 이상, 비밀번호 변경 기간 90일 이하)
- ❌ 취약: 로그인 계정 비밀번호 관리 정책이 적용되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `Security.PasswordQualityControl` 설정값 확인 (N3, N4가 8 이상인지 확인)
4. `Security.PasswordMaxDays` 설정값 확인 (90일 이하인지 확인)

**VMware vCenter**
- vSphere Client 접속 후 관리 > Single Sign On > 구성 > 암호 정책에서 비밀번호 정책 확인

**XenServer**
```bash
# 비밀번호 설정 확인
cat /etc/login.defs | grep -i "PASS_MAX_DAYS"
cat /etc/login.defs | grep -i "PASS_MIN_DAYS"
cat /etc/login.defs | grep -i "PASS_MIN_LEN"
```

**KVM (RHEL 8 이후)**
- 설정 파일 확인: `/etc/security/faillock.conf`, `/etc/security/pwquality.conf`

**Nutanix**
```bash
# 비밀번호 최대 사용 기간 확인
sudo cat /etc/login.defs | grep -v "^#" | grep "PASS_MAX_DAYS"

# 비밀번호 최소 길이 확인
cat /etc/login.defs | grep -v "^#" | grep "PASS_MIN_LEN"
```

**조치방법**:

**VMware ESXi**
- Security.PasswordQualityControl: N3, N4를 8 이상으로 설정
- Security.PasswordMaxDays: 90 이하로 설정

**XenServer**
```bash
vi /etc/login.defs
# PASS_MIN_LEN 8
# PASS_MAX_DAYS 90
# PASS_MIN_DAYS 7
```

**KVM (RHEL 8 이후)**
- `/etc/security/pwquality.conf`에 복잡도 정책 설정

**Nutanix**
```bash
# 비밀번호 최대 사용 기간 설정
sudo vi /srv/salt/security/CVM/pamCVM.sls
# PASS_MAX_DAYS 90 설정

# 비밀번호 최소 길이 설정
sudo vi /srv/salt/security/CVM/pamCVM.sls
# PASS_MIN_LEN 8 이상 설정

# 변경 설정 적용
sudo salt-call state.sls security/CVM/pamCVM
```

---

### HV-07 계정 잠금 임계값 설정

점검ID: HV-07 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 로그인 계정에 대한 계정 잠금 임계값 설정 여부 점검

**판단기준**:
- ✅ 양호: 로그인 시도 실패 횟수에 따른 계정 잠금 설정이 적용된 경우
- ❌ 취약: 로그인 시도 실패 횟수에 따른 계정 잠금 설정이 적용되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 관리 - 설정 - 시스템 - 고급 설정으로 이동
3. `Security.AccountLockFailures` 설정이 5 이하로 설정되어 있는지 확인
4. `Security.AccountUnlockTime` 설정이 600초(10분) 이상으로 설정되어 있는지 확인

**VMware vCenter**
- vSphere Client 접속 후 관리 > Single Sign On > 구성 > 잠금정책에서 설정 확인
  - 실패한 최대 로그인 시도 횟수
  - 실패 시간 간격
  - 잠금 해제 시간

**KVM (RHEL 8 이후)**
- 설정 파일 확인: `/etc/security/faillock.conf`, `/etc/security/pwquality.conf`

**조치방법**:

**VMware ESXi**
- Security.AccountLockFailures: 5 이하로 설정
- Security.AccountUnlockTime: 600초(10분) 이상으로 설정

**KVM**
```bash
# /etc/pam.d/system-auth 설정 예시
vi /etc/pam.d/system-auth
# auth required /lib/security/pam_tally.so deny=5 unlock_time=120 no_magic_root
# account required /lib/security/pam_tally.so no_magic_root reset
```

---

## 2. 시스템 서비스 관리

### HV-08 시스템 사용 주의사항 출력 설정

점검ID: HV-08 | 위험도: 중 | 카테고리: 시스템서비스관리

**점검내용**: 원격 로그인 시 시스템 사용 주의사항 출력 여부 점검

**판단기준**:
- ✅ 양호: 시스템 사용 주의사항이 출력된 경우
- ❌ 취약: 시스템 사용 주의사항 미출력 또는 표시 문구 내에 시스템 버전 정보가 노출된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `Annotations.WelcomeMessage` 설정 값 확인

**VMware vCenter**
- vSphere Client 접속 후 관리 > Single Sign On > 구성 > 로그인 배너(또는 로그인 메시지) 설정 확인

**XenServer, KVM**
```bash
# 배너 설정 확인
cat /etc/ssh/sshd_config | grep "Banner"
```

**Nutanix - 관리 웹 콘솔**
- 웹 콘솔 접속: `https://<Nutanix IP>:9440`
- Settings > Appearance > Welcome Banner 확인

**Nutanix - SSH**
```bash
# 배너 파일 확인
cat /etc/issue
cat /etc/ssh/sshd_config | grep "Banner"
```

**조치방법**:

**VMware ESXi**
- Annotations.WelcomeMessage에 시스템 사용 주의사항 문구 입력

**XenServer, KVM**
```bash
# /etc/ssh/sshd_config에 배너 설정
vi /etc/ssh/sshd_config
# Banner /etc/issue.net

# 배너 내용 작성
vi /etc/issue.net
# 예시: This system is for the use of authorized users only.
```

**Nutanix - 웹 콘솔**
- Settings > Appearance > Welcome Banner에 배너 입력 후 Enable Banner 체크

**Nutanix - SSH**
```bash
# AHV, Controller VM에서 배너 파일 설정
sudo vi /etc/issue
# 배너 내용 입력

# ssh 설정 파일에서 배너 경로 설정
sudo vi /etc/ssh/sshd_config
# Banner /etc/issue

# ssh 데몬 재시작
systemctl restart sshd
```

---

### HV-09 NTP 및 시각 동기화 설정

점검ID: HV-09 | 위험도: 중 | 카테고리: 시스템서비스관리

**점검내용**: NTP 설정을 통한 시간 동기화 여부 점검

**판단기준**:
- ✅ 양호: NTP 서버와 시간 동기화 설정을 적용한 경우
- ❌ 취약: NTP 서버와 시간 동기화 설정을 적용하지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 시간 및 날짜로 이동
3. NTP 설정 확인

**VMware vCenter**
- vCenter Server 관리 페이지 접속: `https://<주소>:5480/`
- 시간 > 시간 동기화 > NTP 설정 확인

**KVM**
```bash
# PHC 사용 여부 확인 및 설정
echo ptp_kvm > /etc/modules-load.d/ptp_kvm.conf
echo "refclock PHC /dev/ptp0 poll 2" >> /etc/chrony.conf
systemctl restart chronyd
```

**XenServer**
- XenServer 접속 - Network and Management Interface > Network Time (NTP) > Provide NTP Servers Manually에서 NTP 서버 지정

**Nutanix**
- 웹 콘솔 접속: `https://<Nutanix IP>:9440`
- Settings > NTP Servers에서 NTP 서버 설정 확인

**조치방법**:

**VMware ESXi**
- 호스트 - 관리 - 시스템 - 시간 및 날짜 - NTP 설정 편집에서 NTP 서버 정보 입력

**Nutanix**
```bash
# NTP 서버 설정
# Settings > NTP Servers에서 Add

# 타임존 설정
ncli cluster set-timezone timezone="Asia/Seoul"

# Nutanix 호스트 타임존 설정
hostssh "date; mv /etc/localtime /etc/localtime.bak; ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime; date"
```

---

### HV-10 SNMP Community String 복잡성 적용

점검ID: HV-10 | 위험도: 중 | 카테고리: 시스템서비스관리

**점검내용**: SNMP Community String 복잡성 적용 여부 점검

**판단기준**:
- ✅ 양호: SNMP Community String이 복잡도를 만족하는 경우 (SNMP v3 사용 권장)
- ❌ 취약: SNMP Community String이 복잡도를 만족하지 않는 경우

**점검방법**:

**VMware ESXi**
```bash
# SSH로 ESXi 호스트 접속 후 확인
esxcli system snmp get
```

**VMware vCenter**
```bash
# SNMP 사용 확인
if [[ $(vim-cmd proxysvc/service_list | grep 'TSM') ]]; then
  echo "SNMP service is running on vcenter"
else
  echo "SNMP service is not running on vcenter"
fi

# Community String 확인
cat /etc/vmware/snmp.xml | grep community | awk -F '"' '{print $4}'
```

**KVM**
```bash
# SNMP 파일에서 Community String 확인
sudo vi /etc/snmp/snmpd.conf
```

**XenServer**
- XenCenter 접속 - 해당 서버 설정 - SNMP - SNMP 활성화 여부 및 Community String 값 확인

**Nutanix**
- 웹 콘솔 접속: `https://<Nutanix IP>:9440`
- Settings > SNMP 확인

**조치방법**:

**VMware ESXi**
```bash
# Community String 값 변경
esxcli system snmp set --communities <변경값>
```

**KVM**
```bash
# Community String 설정 후 재시작
sudo vi /etc/snmp/snmpd.conf
sudo systemctl enable snmpd
sudo systemctl start snmpd
```

**Nutanix - 불필요한 경우 비활성화**
- Settings > SNMP > Enable for Nutanix objects 체크 해제

**Nutanix - v3 사용 (권장)**
- Settings > SNMP > Users > New User로 SNMP User 생성
- Traps > New Trap receiver로 Trap 설정

**Nutanix - v2c 사용 시**
- Settings > SNMP > Traps > 편집하여 Community String 복잡도 만족하도록 설정

---

### HV-11 MOB(Managed Object Browser) 서비스 비활성화

점검ID: HV-11 | 위험도: 상 | 카테고리: 시스템서비스관리

**점검내용**: MOB 서비스 비활성화 여부 점검

**판단기준**:
- ✅ 양호: MOB(Managed Object Browser)가 비활성화된 경우
- ❌ 취약: MOB(Managed Object Browser)가 활성화된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `Config.HostAgent.plugins.solo.enableMob` 설정값 확인

**VMware vCenter**
- vSphere Client 접속 후 호스트 및 클러스터 > [vCenter 서버] > 구성 > 설정 > 고급 설정 > `config.vpxd.enableDebugBrowse` 확인

**조치방법**:

**VMware ESXi**
- Config.HostAgent.plugins.solo.enableMob 값을 false로 설정

**VMware vCenter**
- config.vpxd.enableDebugBrowse 값을 false로 설정

---

### HV-12 ESXi Shell 비활성화

점검ID: HV-12 | 위험도: 상 | 카테고리: 시스템서비스관리

**점검내용**: ESXi Shell(TSM, TSM-SSH) 비활성화 여부 점검

**판단기준**:
- ✅ 양호: ESXi Shell(TSM, TSM-SSH) 서비스가 비활성화된 경우
- ❌ 취약: ESXi Shell(TSM, TSM-SSH) 서비스가 활성화된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 서비스로 이동
3. TSM, TSM-SSH 서비스 활성화 여부 확인

**조치방법**:

**VMware ESXi**
- TSM, TSM-SSH 서비스가 활성화되어 있는 경우 중지 클릭

---

### HV-13 ESXi Shell 세션 종료 시간 설정

점검ID: HV-13 | 위험도: 상 | 카테고리: 시스템서비스관리

**점검내용**: ESXi Shell(TSM, TSM-SSH)의 Session Timeout 설정의 적정성 여부 점검

**판단기준**:
- ✅ 양호: Session Timeout 값(ESXiShellInteractiveTimeOut)이 600 이하로 설정된 경우
- ❌ 취약: Session Timeout 값(ESXiShellInteractiveTimeOut)이 0이거나, 600초과로 설정된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 관리 - 설정 - 시스템 - 고급 설정으로 이동
3. `UserVars.ESXiShellInteractiveTimeOut` 설정값 확인

**조치방법**:

**VMware ESXi**
- UserVars.ESXiShellInteractiveTimeOut 값을 600 이하로 설정

---

### HV-14 원격 로그 서버 이용

점검ID: HV-14 | 위험도: 중 | 카테고리: 시스템서비스관리

**점검내용**: 원격 로그 서버를 이용한 로그 저장 여부 점검

**판단기준**:
- ✅ 양호: 원격 로그 서버 또는 스토리지가 연동 설정된 경우
- ❌ 취약: 원격 로그 서버 또는 스토리지가 연동 설정되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `Syslog.global.logHost` 설정값 확인

**VMware vCenter**
- vCenter Server 관리 페이지 접속: `https://<주소>:5480/`
- Syslog > Syslog 설정 여부 확인

**KVM**
```bash
# /etc/rsyslog.conf 파일 확인
# 원격 로그 서버 전송 지시어 확인
# logger 명령어로 전송 여부 확인
```

**XenServer**
```bash
# udp 514 Port 확인
netstat -an | grep "udp" | egrep "514"
```

**Nutanix**
```bash
# 원격 로깅 서버 설정 확인
ncli rsyslog-config list
```

**조치방법**:

**VMware ESXi**
- Syslog.global.logHost에 원격 로그 서버 또는 스토리지 입력
- 형식: `protocol://hostname|ipv4|'['ipv6']'[:port]`
- 예시:
  - `tcp://10.0.1.10:3555`
  - `udp://10.0.1.10`
  - `ssl://syslog.com`

**XenServer**
```bash
# Syslog.conf 파일 수정
vi /etc/sysconfig/syslog
# SYSLOGD_OPTIONS="-m 0" 설정
```

**Nutanix**
```bash
# 원격 로깅 서버 설정
ncli rsyslog-config add-server name=<alias> ip-address=<원격 로그 서버 IP> port=<포트> network-protocol=tcp relp-enabled=no

# 로그 레벨 설정
ncli rsyslog-config add-module module-name=syslog_module level=info server-name=<alias>
```

---

### HV-15 시스템 주요 이벤트 로그 설정

점검ID: HV-15 | 위험도: 상 | 카테고리: 시스템서비스관리

**점검내용**: 시스템 주요 이벤트 로그가 설정 여부 점검

**판단기준**:
- ✅ 양호: 로그 기록 정책이 내부 정책에 부합하게 설정된 경우
- ❌ 취약: 로그 기록 정책이 내부 정책에 부합하게 설정되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `Config.HostAgent.log.level` 설정값 확인

**VMware vCenter**
- vSphere Client 접속 후 호스트 및 클러스터 > [vCenter 서버] > 구성 > 설정 > 고급 설정 > `config.log.level` 확인

**KVM**
```bash
# libvirt 설정 파일 확인
cat /etc/libvirt/libvirtd.conf
# log_level 확인
```

**조치방법**:

**VMware ESXi**
- Config.HostAgent.log.level을 내부 정책에 맞게 설정
- 로깅 수준: None, Quiet, Panic, Error, Warning, Information, Verbose, Trivia

**KVM**
```bash
# libvirt 설정 파일 수정
vi /etc/libvirt/libvirtd.conf
# log_level = <레벨> 설정 (1:DEBUG, 2:INFO, 3:WARNING, 4:ERROR)

# libvirt 데몬 재시작
systemctl restart libvirtd.service
```

---

### HV-16 비휘발성 경로 내 로그 파일 저장

점검ID: HV-16 | 위험도: 상 | 카테고리: 시스템서비스관리

**점검내용**: 비휘발성 경로에 로그파일 저장 여부 점검

**판단기준**:
- ✅ 양호: 로그 파일 경로가 존재하며, 해당 경로가 비휘발성 경로에 저장된 경우
- ❌ 취약: 로그 파일 경로가 존재하지 않거나, 휘발성 경로에 저장된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 호스트 - 관리 - 시스템 - 고급 설정으로 이동
3. `Syslog.global.LogDir` 설정값 확인

**조치방법**:

**VMware ESXi**
- Syslog.global.LogDir을 비휘발성 경로로 설정
- 휘발성 경로 예시: /scratch/, /tmp, /var/tmp, /run, /dev/shm, /dev/pts 등

---

## 3. 가상 머신 관리

### HV-17 코어덤프 수집 기능 활성화

점검ID: HV-17 | 위험도: 상 | 카테고리: 가상머신관리

**점검내용**: 코어 덤프 수집 기능 활성화 여부 점검

**판단기준**:
- ✅ 양호: 코어 덤프 수집 기능이 활성화(true)된 경우
- ❌ 취약: 코어 덤프 수집 기능이 비활성화(false)된 경우

**점검방법**:

**VMware ESXi**
```bash
# SSH로 ESXi 호스트 접속 후 확인
esxcli system coredump network get
```

**조치방법**:

**VMware ESXi**
```bash
# VMkernel 네트워크 인터페이스와 원격 코어 덤프 서버 설정
esxcli system coredump network set --interface-name <VMkernel 인터페이스명> --server-ipv4 <IP 주소> --server-port <Port 번호>

# 예시
esxcli system coredump network set --interface-name vmk0 --server-ipv4 10.0.1.10 --server-port 6500

# 네트워크 코어 덤프 구성 활성화
esxcli system coredump network set --enable true

# 활성화 여부 확인
esxcli system coredump network check
```

---

### HV-18 가상 머신의 장치 변경 제한 설정

점검ID: HV-18 | 위험도: 상 | 카테고리: 가상머신관리

**점검내용**: 가상 머신 장치 변경 제한 설정 적용 여부 점검

**판단기준**:
- ✅ 양호: 가상 머신의 장치 설정 변경 방지 설정이 활성화(true)된 경우
- ❌ 취약: 가상 머신의 장치 설정 변경 방지 설정이 없거나, 비활성화(false)된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 가상 시스템 - [가상 머신 선택] > 설정 편집 - VM 옵션 - 고급 - 구성 매개 변수로 이동
3. `isolation.device.edit.disable`, `isolation.device.connectable.disable` 설정값 확인

**조치방법**:

**VMware ESXi**
- isolation.device.edit.disable 값을 TRUE로 설정
- isolation.device.connectable.disable 값을 TRUE로 설정
- 매개 변수가 존재하지 않을 경우 추가

---

### HV-19 가상 머신의 불필요한 장치 제거

점검ID: HV-19 | 위험도: 상 | 카테고리: 가상머신관리

**점검내용**: 불필요한 장치(USB, CD/DVD, 플로피 디스크, 병렬 포트, 직렬 포트) 제거 여부 점검

**판단기준**:
- ✅ 양호: 불필요한 장치가 가상 머신에 연결되지 않은 경우
- ❌ 취약: 불필요한 장치가 가상 머신에 연결된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 가상 시스템 - [가상 머신 선택] > 설정 편집 - 가상 하드웨어로 이동
3. 장치 연결상태 확인

**XenServer**
```bash
# 장치 연결상태 확인 명령어
lspci                           # PCI 장치 목록
lsblk                           # 블록 디바이스 목록
ifconfig 또는 ip addr           # 네트워크 인터페이스
xe vm-list name-label="<VM명>"  # 가상 머신 목록
xe vbd-list vm-uuid=<VM_UUID>   # VM 디스크 확인
xe vdi-list                     # 가상 디스크 이미지 목록
xe vif-list                     # 네트워크 인터페이스 목록
lsusb                           # USB 장치 확인
df -h                           # 디스크 용량 확인
```

**조치방법**:

**VMware ESXi**
- 가상 하드웨어에서 불필요한 외부 장치 비활성화

**XenServer**
- 불필요한 외부 장치 비활성화

---

### HV-20 가상 머신 콘솔 클립보드 복사&붙여넣기 기능 비활성화

점검ID: HV-20 | 위험도: 상 | 카테고리: 가상머신관리

**점검내용**: 가상 머신 콘솔 복사 기능 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 가상 머신 콘솔 복사 기능이 비활성화 되어 있거나, 복사 제한이 설정된 경우
- ❌ 취약: 가상 머신 콘솔 복사 기능이 활성화 되어 있거나, 복사 제한이 설정되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 가상 시스템 - [가상 머신 선택] > 설정 편집 - VM 옵션 - 고급 - 구성 매개 변수로 이동
3. `isolation.tools.copy.disable`, `isolation.tools.paste.disable`, `isolation.tools.setGUIOptions.enable` 설정값 확인

**조치방법**:

**VMware ESXi**
- isolation.tools.copy.disable 값을 TRUE로 설정
- isolation.tools.paste.disable 값을 TRUE로 설정
- isolation.tools.setGUIOptions.enable 값을 FALSE로 설정
- 매개 변수가 존재하지 않을 경우 추가

---

### HV-21 가상 머신 콘솔 드래그 앤 드롭 기능 비활성화

점검ID: HV-21 | 위험도: 상 | 카테고리: 가상머신관리

**점검내용**: 가상 머신 드래그 앤 드롭 기능 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 가상 머신 콘솔 드래그 앤 드롭 기능이 비활성화되어 있거나, 제한 설정된 경우
- ❌ 취약: 가상 머신 콘솔 드래그 앤 드롭 기능이 활성화되어 있거나, 제한 설정되지 않은 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 가상 시스템 - [가상 머신 선택] > 설정 편집 - VM 옵션 - 고급 - 구성 매개 변수로 이동
3. `isolation.tools.dnd.disable` 설정값 확인

**조치방법**:

**VMware ESXi**
- isolation.tools.dnd.disable 값을 TRUE로 설정
- 매개 변수가 존재하지 않을 경우 추가

---

## 4. 가상 네트워크 관리

### HV-22 가상 스위치 MAC 주소 변경 정책 비활성화

점검ID: HV-22 | 위험도: 상 | 카테고리: 가상네트워크관리

**점검내용**: MAC 주소 변경 정책 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 가상 스위치 MAC 주소 변경 정책이 거부로 설정된 경우
- ❌ 취약: 가상 스위치 MAC 주소 변경 정책이 허용으로 설정된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 네트워킹 - 가상 스위치 - [가상 스위치 선택] > 설정 편집 - 보안으로 이동
3. MAC 주소 변경 정책 설정 확인

**조치방법**:

**VMware ESXi**
- MAC 주소 변경 정책을 '거부'로 변경 후 저장

---

### HV-23 가상 스위치 무차별(Promiscuous) 모드 정책 비활성화

점검ID: HV-23 | 위험도: 상 | 카테고리: 가상네트워크관리

**점검내용**: 무차별(Promiscuous) 모드 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 가상 스위치 무차별(Promiscuous) 모드 정책 설정이 거부로 설정된 경우
- ❌ 취약: 가상 스위치 무차별(Promiscuous) 모드 정책 설정이 허용으로 설정된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 네트워킹 - 가상 스위치 - [가상 스위치 선택] > 설정 편집 - 보안으로 이동
3. 무차별 모드 정책 설정 확인

**XenServer**
```bash
# 가상 스위치 Promiscuous 모드 조회
# uuid 확인
xe pif-list network-name-label=<네트워크 이름>
xe vif-list vm-name-label=<VM 이름>

# promiscuous 값 확인
xe pif-param-list uuid=<uuid_of_pif>
xe vif-param-list uuid=<uuid_of_vif>
```

**조치방법**:

**VMware ESXi**
- 무차별 모드 정책을 '거부'로 변경 후 저장

**XenServer**
```bash
# promiscuous 값 설정
xe pif-param-set uuid=<uuid_of_pif> other-config:promiscuous="false"
xe vif-param-set uuid=<uuid_of_vif> other-config:promiscuous="false"
```

---

### HV-24 가상 스위치 위조전송(Forged Transmits) 모드 정책 비활성화

점검ID: HV-24 | 위험도: 상 | 카테고리: 가상네트워크관리

**점검내용**: 가상 스위치 위조전송(Forged Transmits) 모드 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 가상 스위치에 위조 전송(Forged Transmits) 모드 설정이 거부로 설정된 경우
- ❌ 취약: 가상 스위치에 위조 전송(Forged Transmits) 모드 설정이 허용으로 설정된 경우

**점검방법**:

**VMware ESXi**
1. Web 콘솔 페이지 접속: `https://<VMware ESXi IP>`
2. 네트워킹 - 가상 스위치 - [가상 스위치 선택] > 설정 편집 - 보안으로 이동
3. 위조 전송 정책 설정 확인

**조치방법**:

**VMware ESXi**
- 위조 전송 정책을 '거부'로 변경 후 저장

---

### HV-25 주기적 보안 패치 및 벤더 권고사항 적용

점검ID: HV-25 | 위험도: 상 | 카테고리: 가상네트워크관리

**점검내용**: 가상화 장비 및 관리서버 들에 대해 주기적인 보안 패치와 벤더 권고사항 적용 여부를 확인

**판단기준**:
- ✅ 양호: 패치 절차를 수립하여 주기적으로 패치 및 벤더 권고사항을 확인 및 적용하는 경우
- ❌ 취약: 패치 절차가 수립되어 있지 않거나 주기적으로 패치를 설치하지 않는 경우

**점검방법**:

주기적으로 보안 패치 및 벤더 권고사항을 검토 후 적용

**조치방법**:

장비별 제공하는 최신 취약점 정보를 파악 후 최신 패치 및 업그레이드를 수행

**보안패치 및 보안권고 정보 제공 사이트**:

| 구분 | 보안패치 및 보안권고 정보제공 사이트 |
|------|-------------------------------------|
| VMware ESXi, vCenter | https://support.broadcom.com/web/ecx/security-advisory |
| XenServer | https://support.citrix.com/support-home/home<br>https://xenbits.xen.org/xsa |
| KVM | 운영 중인 리눅스 배포판(Red Hat, Ubuntu, SUSE 등)의 공식 보안공지를 통해 확인 |
| Nutanix | https://www.nutanix.com/trust/security-advisories |

**참고**: 서비스 영향을 고려하여 벤더사와 협의 후 적용
