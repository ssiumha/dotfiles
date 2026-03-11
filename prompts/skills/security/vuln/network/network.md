# 네트워크장비 취약점 점검항목

> 출처: KISA 주요정보통신기반시설 기술적 취약점 분석평가 방법 상세가이드 (2026)
> 총 항목: 38개 (N-01 ~ N-38)

### N-01 비밀번호 설정

> 점검ID: N-01 | 위험도: 상 | 카테고리: 계정 관리

**점검내용**: 관리 터미널(콘솔, SSH, https 등)을 통해 네트워크 장비 접근 시 기본 비밀번호(기본 관리자 계정도 함께 변경하도록 권고)를 사용하는지 점검

**판단기준**:
- ✅ 양호: 기본 비밀번호를 변경한 경우
- ❌ 취약: 기본 비밀번호를 변경하지 않거나 비밀번호를 설정하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) enable 비밀번호 설정 확인
Router> enable
Router# show running-config
Step 2) VTY, 콘솔, 보조 (AUX) 포트의 로그인 인증 방식 및 비밀번호 설정 확인
login: 라인 비밀번호 인증
login local: 로컬 사용자 인증
login authentication: AAA 인증
no login: 인증 없이 사용자 모드 (User EXEC mode) 접근
Step 3) enable 비밀번호 설정
Router# config terminal ( 단축 명령 conf t)
Router(config)# enable secret < 비밀번호      - 또는 Router(config)# enable password < 비밀번호
Router(config)# end
Step 4) 가상 터미널 (VTY) 비밀번호 설정
Router# config terminal
Router(config)# line vty ?
<0X4> First Line number
Router(config)# line vty 0 4
Router(config-line)# login
Router(config-line)# password < 비밀번호

**조치방법**:
기본 비밀번호를 관리기관의 비밀번호 작성규칙을 준용하여 변경

---

### N-02 비밀번호 복잡성 설정

> 점검ID: N-02 | 위험도: 상 | 카테고리: 계정 관리

**점검내용**: 네트워크 장비에 기관 정책에 맞는 계정 비밀번호 복잡성 정책이 적용되어 있는지 점검 비밀번호 복잡성 정책 설정 기능이 장비에 존재하지 않는 경우 기관 정책에 맞게 계정 비밀번호를 설정하여 사용하는지 점검

**판단기준**:
- ✅ 양호: 기관 정책에 맞는 비밀번호 복잡성 정책을 설정하거나, 비밀번호 복잡성 설정 기능이 없는 장비는<br>기관 정책에 맞게 비밀번호를 사용하는 경우
- ❌ 취약: 기관 정책에 맞지 않는 비밀번호를 설정하여 사용하는 경우

**점검방법**:
l 공통
Step 1) 장비에 비밀번호 복잡성 정책을 설정하거나 비밀번호 복잡성 설정 기능이 없는 장비는 기관 정책에 따
라 비밀번호를 설정하여 사용하는지 확인
Step 2) 기반시설 관리기관의 비밀번호 작성규칙과 관련 법규를 준수하여 비밀번호 복잡성 정책을 설정하고 안
전한 비밀번호를 사용
※ 비밀번호 작성규칙 예시
-                            -                            비밀번호는 다음 사항을 반영하고 숫자 문자 특수문자 등을 혼합하여 안전하게 설정하고 정기적으로 변경
사용해야 함
1. 사용자 계정 ( 아이디 ) 과 동일하지 않은 것
2. 개인 신상 및 부서 명칭 등과 관계가 없는 것
3. 일반 사전에 등록된 단어의 사용을 피할 것
4. 동일한 단어 또는 숫자를 반복하여 사용하지 말 것
5. 사용된 비밀번호는 재사용하지 말 것
6. 동일한 비밀번호를 여러 사람이 공유하여 사용하지 말 것
7. 응용프로그램 등을 이용한 자동 비밀번호 입력기능을 사용하지 말 것
l Cisco IOS
Step 1) 비밀번호 복잡성 관련 설정 확인
Router# show running-config
Step 2) 비밀번호의 최소 길이 설정 ( 기존 비밀번호는 영향을 받지 않음 )
Router# config terminal

**조치방법**:
관리기관의 비밀번호 작성규칙에 맞게 비밀번호 복잡성 정책 및 비밀번호 설정

---

### N-03 암호화된 비밀번호 사용

> 점검ID: N-03 | 위험도: 상 | 카테고리: 계정 관리

**점검내용**: 계정 비밀번호 암호화 설정이 적용되어 있는지 점검

**판단기준**:
- ✅ 양호: 비밀번호 암호화 설정을 적용한 경우
- ❌ 취약: 비밀번호 암호화 설정을 적용하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) enable secret 사용 확인
Router# show running-config
Step 2) 계정명 secret 사용 확인
Router# show running-config
Step 3) Password-Encryption 서비스 동작 확인
Router# show running-config
Step 4) enable secret 설정
enable secret 명령어를 사용하여 enable 비밀번호를 일방향 암호화 저장
enable secret 와 enable password 명령어로 각각 비밀번호를 사용하는 경우 enable
secret 명령어의 우선순위가 높으며 보안상 비밀번호를 서로 다르게 입력해야 함
Router# config terminal
Router(config)# enable secret < 비밀번호
Step 5) username secret 설정
(config)# username secret 명령어를 사용하여 로컬 사용자 비밀번호를 일방향 암호화 저장
enable secret 과 enable password 명령어로 비밀번호를 설정하여 같이 사용하는 경우 enable secret 명령
어로 설정한 비밀번호의 우선순위가 높으며 보안상 비밀번호 서로 다르게 입력해야 함
Router# config terminal
Router(config)# username < 사용자 이름      - secret < 비밀번호
Step 6) Password-Encryption 서비스 설정

**조치방법**:
비밀번호 암호화 설정 적용

---

### N-04 계정 잠금 임계값 설정

> 점검ID: N-04 | 위험도: 상 | 카테고리: 계정 관리

**점검내용**: 사용자 계정에 대해 로그인 실패 임계값이 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: 로그인 실패 임계값이 5회 이하의 값으로 설정된 경우
- ❌ 취약: 로그인 실패 임계값이 설정되어 있지 않거나, 5회 초과의 값으로 설정된 경우

**점검방법**:
l Cisco IOS
Step 1) 현재 설정된 보안 정책 확인
Router# show running-config
1. login block-for 사용 확인
2. 로그인 실패 임계값 확인
Step 2) 로그인 실패 임계값 설정 확인
Router# show login
로그인 실패 임계값 설정 확인
Step 3) 로그인 실패 임계값 초과 후 계정 잠금 설정
login block-for 설정
Router# config terminal
Router(config)# login block-for < 계정 잠금 시간       - attempts < 로그인 실패 횟수 (default: 3)> within < 로그
인 실패 허용 시간 범위 (default: 15)>
l Juniper
Step 1) root authentication 설정을 이용하여 [edit system] 레벨에서 syslog 설정 확인
user@host> configure
[edit]
user@host# show version
Step 2) 로그인 실패 임계값 설정
user@host> configure

**조치방법**:
로그인 실패 임계값을 5회 이하로 설정

---

### N-05 사용자·명령어별 권한 설정

> 점검ID: N-05 | 위험도: 중 | 카테고리: 계정 관리

**점검내용**: 네트워크 장비 사용자의 업무에 따라 계정별로 장비 관리 권한을 차등(관리자 권한은 최소한의 계정만 허용) 부여하고 있는지 점검

**판단기준**:
- ✅ 양호: 업무에 맞게 계정의 권한이 차등 부여된 경우
- ❌ 취약: 업무에 맞게 계정의 권한이 차등 부여되지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) 사용자 명령어별 레벨 설정 확인
Router# show privilege
Step 2) 사용자별 권한 수준 지정
Router# config terminal
Router(config)# 계정명 [ID] privilege [1-15] secret [PASS] 또는
Router(config)# 계정명 [ID] privilege [1-15] password [PASS]
Step 3) 명령어별 권한 수준 지정
Router(config)# privilege exec level [1-15] [ 서비스명 ]
아래의 중요한 명령어에는 반드시 레벨 15 를 적용해야 함
connect, telnet, rlogin, show ip access-list, show logging
Router# config terminal
Router(config)# privilege exec level 15 connect
Router(config)# privilege exec level 15 telnet
Router(config)# privilege exec level 15 rlogin
Router(config)# privilege exec level 15 show ip access-list
Router(config)# privilege exec level 15 show logging
※ 시스코 IOS 에서는 0 에서 15 까지 16 개의 서로 다른 권한 수준을 규정하고 있으며, 레벨 1 과 레벨 15 는 기본적
으로 정의되어 있음
※ 사용자 EXEC 모드는 레벨 1 에서 실행되며 privileged EXEC 모드는 레벨 15 에서 실행되고, IOS 각 명령어는

**조치방법**:
업무에 맞게 계정별 권한 차등(관리자 권한 최소화) 부여 ※ 한 명의 관리자가 네트워크 장비를 관리할 경우는 해당하지 않음

---

### N-06 VTY 접근(ACL) 설정

> 점검ID: N-06 | 위험도: 상 | 카테고리: 접근 관리

**점검내용**: 원격 터미널(VTY)을 통해 네트워크 장비 접근 시 지정된 IP에서만 접근할 수 있도록 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: 가상 터미널(VTY) 접근을 제한하는 ACL을 설정한 경우
- ❌ 취약: 가상 터미널(VTY) 접근을 제한하는 ACL을 설정하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) Access List 설정하고 VTY 라인에 적용 여부 확인
Router# show running-config
Step 2) VTY 접근 허용 IP 설정
Router# config terminal
Router(config)# access-list <ACL 번호       - permit <IP 주소
Router(config)# access-list <ACL 번호       - deny any log
Router(config)# line vty ?
<0X4> First Line number
Router(config)# line vty 0 4
Router(config)# access-class <ACL 번호      - in
l Radware Alteon
Step 1) 장비로 접속하여 Telnet 또는 SSH 사용자의 접속 IP 설정 확인 (Access Policies)
Step 2) # cfg
# sys
# access
# mgmt
# add
Enter Management Network Address: <IP 주소
Enter Management Network Mask: < 서브넷마스크

**조치방법**:
가상 터미널(VTY)에 특정 IP주소만 접근할 수 있도록 설정

---

### N-07 Session Timeout 설정

> 점검ID: N-07 | 위험도: 상 | 카테고리: 접근 관리

**점검내용**: 기관 정책에 맞게 Session Timeout 설정이 적용되어 있는지 점검

**판단기준**:
- ✅ 양호: Session Timeout 시간을 10분 이하로 설정한 경우
- ❌ 취약: Session Timeout 시간을 설정하지 않거나 10분 초과로 설정한 경우

**점검방법**:
l Cisco IOS
Step 1) 각 Line Access 의 exec-timeout 설정 확인
Router# show running-config
Step 2) Console
Router# config terminal
Router(config)# line con 0
Router(config-line)# exec-timeout 5 0
Step 3) VTY
Router# config terminal
Router(config)# line vty 0 4
Router(config-line)# exec-timeout 5 0
Step 4) AUX
Router# config terminal
Router(config)# line aux 0
Router(config-line)# exec-timeout 5 0
l Radware Alteon
Step 1) idle timeout in minutes 설정 확인
Step 2) # cfg
# sys
# idle <idle timeout in minutes, affects both console and telnet>

**조치방법**:
Session Timeout 설정 (10분 이하 권고)

---

### N-08 VTY 접속 시 안전한 프로토콜 사용

> 점검ID: N-08 | 위험도: 중 | 카테고리: 접근 관리

**점검내용**: 네트워크 장비 정책에 암호화 프로토콜(ssh)을 이용한 터미널 접근만 허용하도록 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: 장비 정책에 VTY 접근 시 암호화 프로토콜(ssh) 이용한 접근만 허용하고 있는 경우
- ❌ 취약: 장비 정책에 VTY 접근 시 평문 프로토콜(telnet) 이용한 접근을 허용하고 있는 경우

**점검방법**:
l Cisco IOS
Step 1) SSH 활성화 확인
Router# show ip ssh
SSH Enabled – version 1.5
Authentication timeout: 120 secs; Authentication retries: 3 ( 활성화 )
%SSH has not been enabled ( 비 활성화 )
Step 2) Cisco IOS 이미지 확인
Router# show version
SSHv2 서버를 지원하는 릴리즈별 k9(3DES) 소프트웨어 이미지를 사용하는지 확인
( 예, 7200p-ipbasek9-mz.152-4.M11.bin)
Step 3) SSH 설정
Router# config terminal
Router(config)# hostname < 호스트명
Router(config)# ip domain-name < 도메인명
Router(config)# crypto key generate rsa
How many bits in the modulus [512]: 2048
Router(config)# ip ssh time-out < 초
Router(config)# ip ssh version 2 (SSH 버전 2 사용 )
Router(config)# ip ssh authentication-retries [ 횟수 ] <- 재시도 횟수
Step 4) VTY 라인에 SSH 사용 설정

**조치방법**:
암호화 프로토콜만 VTY에 접근할 수 있도록 설정

---

### N-09 불필요한 보조 입출력 포트 사용 금지

> 점검ID: N-09 | 위험도: 중 | 카테고리: 접근 관리

**점검내용**: 사용하지 않는 보조(AUX) 포트 및 콘솔 점검 장비 관리나 운용에 쓰이지 않는 포트 및 인터페이스가 비활성화되어 있는지 점검

**판단기준**:
- ✅ 양호: 불필요한 포트 및 인터페이스 사용을 제한한 경우
- ❌ 취약: 불필요한 포트 및 인터페이스 사용을 제한하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) 불필요한 포트 및 인터페이스 사용 확인
Router# show running
불필요한 보조 입출력 포트의 오른쪽 끝부분에 Up ( 활성화 )
불필요한 보조 입출력 포트의 오른쪽 끝부분에 Down ( 비활성화 )
Step 2) AUX 포트 접속 차단
Router# config terminal
Router(config)# line aux 0
Router(config-line)# no password ( 어떤 사용자도 접속 금지 )
Router(config-line)# transport input none ( 어떤 입력도 받지 않음 )
Router(config-line)# no exec ( 어떤 명령도 실행 안 됨 )
Router(config-line)# exec-timeout 0 1 (1 초 지나면 자동 타임아웃 )
l Juniper Junos
Step 1) 불필요한 포트 및 인터페이스 사용 확인
user@host>configure
[edit]
user@host#show
root authentication 설정을 이용하여 [edit system] 레벨에서 interface 차단 설정 확인
Step 2) 보조 (AUX) 포트 비활성화 설정
[edit system ports]

**조치방법**:
불필요한 포트 및 인터페이스 사용 제한 또는 비활성화

---

### N-10 로그인 시 경고 메시지 설정

> 점검ID: N-10 | 위험도: 중 | 카테고리: 접근 관리

**점검내용**: 터미널 접속 화면에 비인가자의 불법 접근에 대한 경고 메시지를 표시하도록 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: 로그온 시 접근에 대한 경고 메시지를 설정한 경우
- ❌ 취약: 로그온 시 접근에 대한 경고 메시지를 설정하지 않거나 시스템 관련 정보가 노출되는 경우

**점검방법**:
l Cisco IOS
Step 1) 배너 설정 내용 확인
Router# show running-config
Step 2) 배너 설정
Router# config terminal
Enter configuration commands, one per line. End with CNTL/Z.
Router(config)# banner motd #
Enter TEXT message. End with the character '#'.
< 배너 문구 입력     - #
Router(config)# banner login #
Enter TEXT message. End with the character '#'.
< 배너 문구 입력     - #
Router(config)# banner exec #
Enter TEXT message. End with the character '#'.
< 배너 문구 입력     - #
Router(config)#
※ 바람직한 배너 예시
This system have to access authorized user and only use for officially.
During using equipment, privacy of individuals is not guaranteed.
All access and usage is monitored and recorded and can be provided evidence as court or related organization.

**조치방법**:
네트워크 장비 접속 시 경고 메시지 설정

---

### N-11 원격로그 서버 사용

> 점검ID: N-11 | 위험도: 중 | 카테고리: 접근 관리

**점검내용**: 네트워크 장비의 로그를 별도의 원격 로그 서버에 보관하도록 설정하였는지를 점검

**판단기준**:
- ✅ 양호: 별도의 로그 서버를 통해 로그를 관리하는 경우
- ❌ 취약: 별도의 로그 서버가 없는 경우

**점검방법**:
l Cisco IOS
Step 1) Logging 설정 확인
Router# show running-config
Step 2) Log 정보 확인
Router# show logging
Step 3) 라우터 로깅 설정
Router# config terminal
Router(config)# logging on (log 를 console 이외도 전달 )
Router(config)# logging trap informational (severity level 설정 )
Router(config)# logging 192.168.3.1 (syslog 서버 )
Router(config)# logging facility local6 (syslog facility 설정 )
Router(config)# logging source-interface serial 0 (syslog interface)
|클래스 명|설명|
|---|---|
|Operator|clear, network, reset, trace, view|
|read-only|view|
|Superuser|all|
|unauthorized|None|
l Radware Alteon
Step 1) /syslog/host 에서 syslog host 설정 확인

**조치방법**:
Syslog 등을 이용하여 로그 저장 설정

---

### N-12 주기적 보안 패치 및 벤더 권고사항 적용

> 점검ID: N-12 | 위험도: 상 | 카테고리: 패치 관리

**점검내용**: 패치 적용 정책에 따라 주기적인 패치를 하고 있는지 점검

**판단기준**:
- ✅ 양호: 주기적으로 보안 패치 및 벤더 권고사항을 적용하는 경우
- ❌ 취약: 주기적으로 보안 패치 및 벤더 권고사항을 적용하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) 버전 정보 확인
Router# show version
l Juniper Junos
Step 1) 버전 정보 확인
user@host# show version
l 공통
Step 1) 주기적으로 보안 패치 및 벤더 권고사항을 검토 이후 적용
Step 2) 패치 식별
1. 각 네트워크 장비의 하드웨어, 소프트웨어, EOL, 패치 적용 현황을 문서화하여 관리
2. 운영 중인 네트워크 장비의 보안 패치 및 벤더 권고사항을 입수
Step 3) 패치 분석
1. 취약점의 영향도와 발생 가능성을 분석하여 패치 적용 여부와 우선순위를 결정
2. 패치 없이 네트워크 장비 설정 변경 등으로 해결이 가능한 경우 대체 조치를 수행
Step 4) 패치 테스트
1. 테스트베드 또는 시뮬레이션에서 운영환경과 최대한 유사하게 테스트 환경 구축
GNS3(Graphical Network Simulator): 오픈 소스 무료 소프트웨어로 가상과 실제 네트워크를 에뮬레이
션, 구성, 테스트, 문제해결을 목적으로 사용
2. 패치가 식별한 문제를 해결하고 정상 동작하는지 체크리스트를 구성하여 검증
Step 5) 패치 적용

**조치방법**:
장비별 제공하는 최신 취약점 정보를 파악 후 최신 패치 및 업그레이드를 수행

---

### N-13 로깅 버퍼 크기 설정

> 점검ID: N-13 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: 버퍼 메모리의 크기를 어느 정도로 설정하고 있는지 점검

**판단기준**:
- ✅ 양호: 저장되는 로그 데이터보다 버퍼 용량이 큰 경우
- ❌ 취약: 저장되는 로그 데이터보다 버퍼 용량이 작은 경우

**점검방법**:
l Cisco IOS
Step 1) 버퍼 메모리 설정 확인
Router> enable
Router# show logging 로그에 대한 정보를 확인
메모리 (RAM) 에 저장된 로그는 'show logging' 으로 확인할 수 있고, 'clear logging' 을 실행하거나 RAM
에 저장된 로그는 전원 종료 시 삭제
Step 2) 버퍼 메모리 설정
Router# config terminal
Router(config)# logging on ( 로그를 메모리에 백업 )
Router(config)# logging buffered 16000 (16KByte 할당 )
Router(config)# logging buffered information (severity 레벨 설정 )
l Piolink PLOS
Step 1) (config)# show logging 로그에 대한 정보를 확인
Step 2) (config)#logging buffer <size> ( 설정 범위 1~1000KB, 기본설정 100KB)
(config)#logging priority <event> <level>

**조치방법**:
로그에 대한 정보를 확인하여 장비 성능을 고려한 최대 버퍼 크기를 설정

---

### N-14 정책에 따른 로깅 설정

> 점검ID: N-14 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: 정책에 따른 로깅 설정이 이루어지고 있는지 점검

**판단기준**:
- ✅ 양호: 로그 기록 정책에 따라 로깅 설정이 되어 있는 경우
- ❌ 취약: 로그 기록 정책 미수립 또는 로깅 설정이 미흡한 경우

**점검방법**:
l Cisco IOS
Step 1) 로그에 대한 정보 확인
Router> enable
Router# show logging
l Juniper Junos
Step 1) 로그에 대한 정보 확인
user@host> configure
[edit]
user@host# show log messages
l Cisco IOS, Juniper Junos
Step 1) 콘솔 로깅
콘솔 로그 메시지는 오직 콘솔 포트에서만 보이므로 이 로그를 보기 위해서는 반드시 콘솔 포트에 연결해
야 함
Step 2) Buffered 로깅
Buffered 로깅은 로그를 라우터의 RAM 에 저장하는데 이 버퍼가 가득 차게 되면 오래된 로그는 자동으
로 새로운 로그에 의해 대체됨
Step 3) Terminal 로깅
Terminal monitor 명령을 사용하여 로깅을 설정하면 라우터에서 발생하는 로그 메시지를 VTY terminal 에
보냄
Step 4) Syslog

**조치방법**:
로그 기록 정책을 수립하고 정책에 따른 로깅 설정

---

### N-15 NTP 및 시각 동기화 설정

> 점검ID: N-15 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: 네트워크 장비의 NTP 서버 연동 및 시간 동기화 설정 적용 여부 점검

**판단기준**:
- ✅ 양호: NTP 서버를 통한 시스템 간 실시간 시간 동기화가 설정된 경우
- ❌ 취약: NTP 서버와 연동되어 있지 않아 시스템 간 실시간 시간 동기화 설정이 되어있지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) NTP 서버 설정 확인
Router# show running-config
Step 2) Global Configuration 모드에서 ntp server 명령을 실행
Router# config terminal
Router(config)# ntp server <NTP 서버 IP>
l Radware Alteon
Step 1) /sys/ntp 에서 NTP 서버 설정 확인
Step 2) # cfg
# /sys/ntp
# on
# prisrvr [NTP 서버 IP]
# intrval [ 동기화 주기 ]
tzone +9:00
# apply
# save
l Juniper Junos
Step 1) root authentication 설정을 이용하여 [edit system] 레벨에서 NTP 서비스 설정 확인
user@host> configure
[edit]

**조치방법**:
NTP 사용 시 신뢰할 수 있는 서버로 설정

---

### N-16 Timestamp 로그 설정

> 점검ID: N-16 | 위험도: 하 | 카테고리: 로그 관리

**점검내용**: 네트워크 장비 설정 중 timestamp를 설정하여 로그 시간을 기록할 수 있게 하였는지 점검

**판단기준**:
- ✅ 양호: timestamp 로그 설정이 되어 있는 경우
- ❌ 취약: timestamp 로그 설정이 되어 있지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) service timestamps 설정 확인
Router> enable
Router# show running-config
Step 2) timestamp 로그 설정
1. 로그 메시지의 타임스탬프를 UTC 시간대로 밀리초 단위까지 표시
Router# config terminal
Router(config)# service timestamps log datetime msec show-timezone
2. 로그 메시지의 타임스탬프를 로컬 시간대로 밀리초 단위까지 표시
Router(config)# clock timezone KST 9
Router(config)# service timestamps log datetime msec localtime show-timezone

**조치방법**:
로그에 시간 정보가 기록될 수 있도록 timestamp 로그 설정

---

### N-17 SNMP 서비스 확인

> 점검ID: N-17 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: 네트워크 장비의 SNMP 서비스를 사용하지 않는 경우 비활성화 상태인지 점검

**판단기준**:
- ✅ 양호: 사용하지 않는 SNMP 서비스를 비활성화한 경우
- ❌ 취약: 사용하지 않는 SNMP 서비스를 비활성화하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) SNMP 설정 확인
Router# show running-config
Step 2) SNMP 서비스 동작 확인
Router# show snmp
SNMP 서비스 비활성화 시 “%SNMP agent not enabled” 문구 출력
Step 3) Router# config terminal
Router(config)# no snmp-server
l Radware Alteon
Step 1) SNMP 서비스 확인
>> Main# /cfg/dump
/c/sys
snmp r
Step 2) >> Main# /cfg/sys/access/snmp
Current SNMP access: disabled
Enter new SNMP access (disabled/read-only/read-write) [d/r/w]:
l Passport
Step 1) SNMP 서비스가 불필요하다면 서비스 중지
l Juniper Junos
Step 1) snmp 서비스 설정 확인

**조치방법**:
장비별 제공하는 최신 취약점 정보를 파악 후 최신 패치 및 업그레이드를 수행

---

### N-18 SNMP Community String 복잡성 설정

> 점검ID: N-18 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: SNMP 서비스 사용 시 Community String을 기본 설정(public, private)으로 사용하고 있는지 점검

**판단기준**:
- ✅ 양호: SNMP 서비스를 비활성화하거나 SNMP Community String을 복잡성 기준(영어 대·소문자,<br>숫자, 특수문자 중 3종류 이상을 조합하여 8자리 이상)에 맞게 설정한 경우
- ❌ 취약: SNMP Community String을 기본 설정(public, private)으로 사용하고 있거나, 복잡성 기준에<br>맞지 않게 설정한 경우

**점검방법**:
l Cisco IOS
Step 1) SNMP 설정 확인
Router# show running-config
Step 2) Community String 문자열 변경
Router# config terminal
Router(config)# snmp-server Community <Community String>
l Radware Alteon / Passport
Step 1) SNMP 설정에서 Community String 설정 확인
Step 2) Radware Alteon
# cfg/sys/ssnmp
# rcomm - SNMP read community string 을 설정 ( 최대 32 자, Default String – public)
# wcomm - SNMP write community string 을 설정 ( 최대 32 자, Default String – private)
# apply
# save
Step 3) Passport
# config snmp-v3 community commname <Comm Idx> new-commname <value>
l Juniper Junos
Step 1) snmp community 설정에서 Community String 확인
[edit]
user@host# show

**조치방법**:
public, private 외 복잡성 기준에 맞는 Community String을 설정 ※ SNMP Community String 복잡성 기준 : 영어 대·소문자, 숫자, 특수문자 중 3종류 이상을 조합하여 8자리 이상으로 구성

---

### N-19 SNMP ACL 설정

> 점검ID: N-19 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: SNMP 서비스 사용 시 네트워크 장비 ACL(Access List)을 설정하여 SNMP 접속 대상 호스트를 지정하여 접근이 가능한 IP를 제한하였는지 점검

**판단기준**:
- ✅ 양호: SNMP 서비스를 비활성화하거나 SNMP 접근을 제한하는 ACL을 설정한 경우
- ❌ 취약: SNMP 접근을 제한하는 ACL을 설정하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) SNMP 설정 확인
Router# show running-config
Step 2) Access-List 설정 확인
Router# show running-config
Step 3) 글로벌 구성 모드에서 snmp-server community 명령어로 ACL 적용
Router# config terminal
Router(config)# access-list <ACL 번호       - permit <IP 주소
Router(config)# access-list <ACL 번호       - deny any log
Router(config)# snmp-server community <Community String> RO <ACL 번호
l Passport
Step 1) config snmp-v3 에서 접근목록 설정 확인
Step 2) # config snmp-v3 community create <Comm Idx> <name> <security> [tag]
# config snmp-v3 group-member create <user name> <model>  [<group name>]
# config snmp-v3 group-access create <group name> <prefix> <model> <level>
# config snmp-v3 group-access view <group name> <prefix> <model> <level> [read <value>] [write
<value>] [notify <value>]
l Juniper Junos
Step 1) edit snmp 에서 접근목록 설정 확인
Step 2) [edit snmp]

**조치방법**:
SNMP 접근에 대한 ACL(Access List) 설정

---

### N-20 SNMP Community 권한 설정

> 점검ID: N-20 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: SNMP Community에 필요하지 않은 쓰기 권한을 허용하는지 점검

**판단기준**:
- ✅ 양호: SNMP 커뮤니티 권한이 읽기 전용(RO)인 경우
- ❌ 취약: SNMP 커뮤니티 권한이 불필요하게 읽기 쓰기(RW)인 경우

**점검방법**:
l Cisco IOS
Step 1) SNMP 설정 확인
Router# show running-config
Step 2) SNMP Community String 권한 설정 (RW 권한 삭제 권고 )
Router# config terminal
Router(config)# snmp-server community <String> RO
Router(config)# snmp-server community <String> RW
l Passport
Step 1) config snmp 에서 SNMP community 권한 확인
Step 2) SNMP Community String 권한 설정 (RW 권한 삭제 권고 )
# config snmp-v3 community create <Comm Idx> <name> <security> [tag <value>]
# config snmp-v3 group-member create <user name> <model> [<group name>]
# config snmp-v3 group-access create <group name> <prefix> <model> <level>
# config snmp-v3 group-access view <group name> <prefix> <model> <level> [read<value>] [write
<value>] [notify <value>]
l Radware Alteon
Step 1) >> Main# /cfg/sys/access/snmp
Current SNMP access: read-write
Enter new SNMP access (disabled/read-only/read-write) [d/r/w]: r
>> Main# apply

**조치방법**:
SNMP Community String 권한 설정 (RW 권한 삭제 권고)

---

### N-21 TFTP 서비스 차단

> 점검ID: N-21 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: 네트워크 장비 서비스 중 불필요한 TFTP 서비스가 구동되어 있거나 TFTP 서비스 사용 시 ACL을 적용하여 허용된 시스템에서만 TFTP 서비스를 사용하도록 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: TFTP 서비스를 차단한 경우
- ❌ 취약: 네트워크 장비의 TFTP 서비스를 차단하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) TFTP 설정 정보 확인
Router# show running-config
Step 2) Router# config terminal
Router(config)# no service tftp

**조치방법**:
네트워크 장비의 불필요한 TFTP 서비스를 비활성화 설정

---

### N-22 Spoofing 방지 필터링 적용

> 점검ID: N-22 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: 사설 네트워크, 루프백 등 특수 용도로 배정하여 라우팅이 불가능한 IP주소를 스푸핑 방지 필터링(Anti-Spoofing Filtering)을 적용하여 차단하는지 점검

**판단기준**:
- ✅ 양호: 경계 라우터 또는 보안 장비에 스푸핑 방지 필터링을 적용한 경우
- ❌ 취약: 경계 라우터 또는 보안 장비에 스푸핑 방지 필터링을 적용하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) IP spoofing 방지 설정 확인
Router# show running
Step 2) 스푸핑 방지 필터링 ACL 구성
access-list 번호는 100~199 구간을 사용하여 Extended access-list 를 사용
router# configure terminal
router(config)# access-list <ACL 번호       - deny ip 0.0.0.0 0.255.255.255 any
router(config)# access-list <ACL 번호       - deny ip 10.0.0.0 0.255.255.255 any
router(config)# access-list <ACL 번호       - deny ip 127.0.0.0 0.255.255.255 any
router(config)# access-list <ACL 번호       - deny ip 169.254.0.0 0.0.255.255 any
router(config)# access-list <ACL 번호       - deny ip 172.16.0.0 0.15.255.255 any
router(config)# access-list <ACL 번호       - deny ip 192.0.2.0 0.0.0.255 any
router(config)# access-list <ACL 번호       - deny ip 192.168.0.0 0.0.255.255 any
router(config)# access-list <ACL 번호       - deny ip 224.0.0.0 15.255.255.255 any
router(config)# access-list <ACL 번호       - permit ip any any
Step 3) 서비스제공업체 (SP) 와 연결된 인터페이스에 ACL 적용
router(config)# interface serial < 인터페이스
router(config-if)# ip access-group <ACL 번호       - in
l Juniper Junos
Step 1) Configure Firewall Filters 와 Apply Firewall Filters 설정 확인

**조치방법**:
경계 라우터 또는 보안 장비에서 스푸핑 방지 필터링 적용

---

### N-23 DDoS 공격 방어 설정 또는 DDoS 장비 사용

> 점검ID: N-23 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: DDoS 공격 방어 설정을 적용하거나 DDoS 대응 장비를 사용하는지 점검

**판단기준**:
- ✅ 양호: 경계 라우터에서 DDoS 공격 방어 설정을 하거나 DDoS 대응 장비를 사용하는 경우
- ❌ 취약: 경계 라우터에서 DDoS 공격 방어 설정을 하지 않거나 DDoS 대응 장비를 사용하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) DDoS 방어 설정 요소 확인
Router# show running
l Juniper Junos
Step 1) DDoS 방어 설정 요소 확인
[edit]
user@host# show configuration
l 공통
Step 1) 스푸핑 방지 필터링 등을 제외한 DDoS 공격 방어 설정은 DDoS 공격 발생 시 공격 유형과 상황을 고려
하여 적용
1. ACL(Access Control List)
- 스푸핑 방지 필터링을 사전 적용 (N-13)
- DDoS 공격 유형에 따라 공격 대상 IP 주소, 프로토콜, 포트를 임시 차단
2. Rate limiting
- 특정 유형의 트래픽에 대역폭과 일정 시간 동안 전송량을 제한
- DDoS 공격 유형에 따라 UDP, ICMP, TCP SYN 패킷의 대역폭을 제한함으로써 다른 서비스에 필요
한 대역폭을 확보
- 하드웨어 기반 전용 모듈이 없는 경우 정책 수에 따라 라우터의 CPU 부하가 증가
3. TCP Intercept
- TCP SYN Flooding 공격로부터 서버를 보호하며 Intercept 또는 Watch 모드로 설정

**조치방법**:
DDoS 공격 방어 설정 점검

---

### N-24 사용하지 않는 인터페이스 비활성화

> 점검ID: N-24 | 위험도: 상 | 카테고리: 기능 관리

**점검내용**: 사용하지 않는 인터페이스가 비활성화 상태인지 점검

**판단기준**:
- ✅ 양호: 사용하지 않는 인터페이스가 비활성화된 경우
- ❌ 취약: 사용하지 않는 인터페이스가 비활성화되지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) 사용하지 않는 인터페이스 확인
Router# show interface
비활성화한 인터페이스는 Administratively down 으로 표시
Step 2) 사용하지 않는 인터페이스 비활성화 (shutdown)
Router# config terminal
Router(config)# interface < 인터페이스
Router(config-line)# shutdown
l Radware Alteon
Step 1) 사용하지 않는 인터페이스 확인
>> Main# /cfg/dump
>> Main# /info/link
Step 2) 사용하지 않는 인터페이스 비활성화 (dis)
>> Main# /cfg/port < 포트 >/dis
>> Main# apply
l Juniper Junos
Step 1) 사용하지 않는 인터페이스 확인
[edit]
user@host# show interface terse
비활성화한 인터페이스는 admin 열을 down 으로 표시

**조치방법**:
네트워크 장비에서 사용하지 않는 모든 인터페이스 비활성화 설정

---

### N-25 TCP Keepalive 서비스 설정

> 점검ID: N-25 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: TCP Keepalive 서비스를 사용하는지 점검

**판단기준**:
- ✅ 양호: TCP Keepalive 서비스를 설정한 경우
- ❌ 취약: TCP Keepalive 서비스를 설정하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) TCP Keepalive 서비스 설정 확인
Router# show running-config
Step 2) 네트워크 장비로 들어오는 TCP 연결에 TCP Keepalive 서비스를 설정
Router# config terminal
Router(config) service tcp-keepalives-in
Step 3) 네트워크 장비에서 나가는 TCP 연결에 TCP Keepalive 서비스를 설정
Router# config terminal
Router(config) service tcp-keepalives-out

**조치방법**:
네트워크 장비에서 TCP Keepalive 서비스를 사용하도록 설정

---

### N-26 Finger 서비스 차단

> 점검ID: N-26 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: 네트워크 장비 서비스 중 Finger 서비스를 비활성화하고 있는지 점검

**판단기준**:
- ✅ 양호: Finger 서비스를 차단하는 경우
- ❌ 취약: Finger 서비스를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) Finger 서비스 설정 확인 (12.1(5) 및 12.1(5)T 이상은 기본적으로 비활성화 )
Router# show running-config
Step 2) Finger 서비스 비활성화
Router# config terminal
Router(config)# no service finger ( 이전 )
Router(config)# no ip finger
※ 최근 출시되는 IOS 는 no service finger 명령 대신 no ip finger 명령을 사용하기도 함
l Juniper Junos
Step 1) root authentication 설정을 이용하여 [edit system] 레벨에서 Finger 서비스 설정 확인
user@host> configure
[edit]
user@host# show
Step 2) Finger 서비스 비활성화
user@host> configure
[edit]
user@host# edit system services
[edit system services]
user@host# delete finger
[edit system services]

**조치방법**:
장비별 Finger 서비스 제한 설정

---

### N-27 웹 서비스 차단

> 점검ID: N-27 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: 웹 서비스를 이용하여 네트워크 장비를 관리할 경우, 웹 서비스를 비활성화하거나 허용된 IP에서만 접속할 수 있게 ACL을 적용하였는지 점검

**판단기준**:
- ✅ 양호: 불필요한 웹 서비스를 차단하거나 허용된 IP에서만 웹서비스 관리 페이지에 접속이 가능한 경우
- ❌ 취약: 불필요한 웹 서비스를 차단하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) 불필요한 웹서비스 확인
Router# show running-config 웹 서비스 설정 확인
Step 2) 불필요한 웹서비스 관련 설정
Router# config terminal
Router(config)# no ip http server
Router(config)# no ip http secure-server
Router# config terminal
Router(config)# ip http active-session-modules exclude_webexec
Router(config)# ip http secure-active-session-modules exclude_webexec
l Radware Alteon
Step 1) 불필요한 웹서비스 확인
>> Main# /cfg/dump
>> Main# /info/link
Step 2) 불필요한 웹서비스 관련 설정
>> Main# /cfg/sys/access/https/https dis
>> Main# /cfg/sys/access/http dis (HTTP 는 Alteon 29.5 버전부터 지원하지 않음 )
>> Main# apply
l Juniper Junos
Step 1) 불필요한 웹서비스 확인

**조치방법**:
HTTP 서비스 차단 또는 HTTP 서버를 관리하는 관리자 접속 IP 설정

---

### N-28 TCP/UDP small 서비스 차단

> 점검ID: N-28 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: TCP/UDP Small 서비스가 제한되어 있는지 점검

**판단기준**:
- ✅ 양호: TCP/UDP Small 서비스가 제한된 경우
- ❌ 취약: TCP/UDP Small 서비스가 제한되지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) no service tcp-small-servers 및 no service tcp-small-servers 설정 확인
Router# show running-config
Step 2) Global Configuration 모드에서 TCP/UDP Small 서비스를 비활성화 설정
Router# config terminal
Router(config)# no service tcp-small-servers
Router(config)# no service udp-small-servers
Router(config)# end

**조치방법**:
TCP/UDP Small Service 제한 설정

---

### N-29 Bootp 서비스 차단

> 점검ID: N-29 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: BOOTP 서비스의 차단 여부 점검

**판단기준**:
- ✅ 양호: BOOTP 서비스가 제한된 경우
- ❌ 취약: BOOTP 서비스가 제한되지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) ip bootp server 설정 확인
Router# show running-config
Step 2) BOOTP 차단 설정
Router# config terminal
Router(config)# no ip bootp server
또는
DHCP 서비스 (DHCP 서버 및 릴레이 ) 는 유지하고 BOOTP 만 차단하는 경우
Router(config)# ip dhcp bootp ignore
※ 라우터를 자동 재부팅하는 취약점이 존재하므로 서비스를 차단하여 방어하기를 권고함
l Radware Alteon
Step 1) #bootp disable 설정 확인
Step 2) BOOTP 차단 설정 (dis)
>> Main# /cfg/sys/bootp dis
>> Main# apply
l Juniper Junos
Step 1) bootp 서비스 설정 확인
user@switch>show configuration & show interfaces detail
Step 2) DHCP 서버 IP 주소와 서버가 연결된 스위치에 대한 인터페이스 지정 옵션 제거
user@switch> configure

**조치방법**:
장비별 BOOTP 서비스 제한 설정

---

### N-30 CDP 서비스 차단

> 점검ID: N-30 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: CDP 서비스를 차단하는지 점검

**판단기준**:
- ✅ 양호: CDP 서비스를 차단하는 경우
- ❌ 취약: CDP 서비스를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) cdp run, global cdp 설정 확인
Router# show running-config
Router# show cdp
Step 2) cdp 서비스 차단 설정
Router# config terminal
Router(config)# no cdp run
Router(config)# interface FastEthernet0/1
Router(config-if)# no cdp enable
※ CDP 를 라우터 전체에서 사용하지 못하도록 하기 위해서는 no cdp run 명령어가 사용되며, 특정 인터페이스
에서 사용하지 못하도록 하려면 no cdp enable 명령어를 사용함

**조치방법**:
Ÿ 장비별 CDP 서비스 제한 설정 Ÿ CDP는 Cisco 전용 프로토콜이지만 일부 다른 벤더도 지원하며, CDP와 유사한 IEEE 표준인 LLDP(Link Layer Discovery Protocol, IEEE 802.1AB)도 불필요할 경우 비활성화

---

### N-31 Directed-broadcast 차단

> 점검ID: N-31 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: Directed-broadcast를 차단하는지 점검

**판단기준**:
- ✅ 양호: Directed Broadcasts를 차단하는 경우
- ❌ 취약: Directed Broadcasts를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) Directed-Broadcast 설정 확인
Router# show running-config
Step 2) Interface Configuration 모드에서 no ip directed-broadcast 명령을 실행하여 비활성화
Router# config terminal
Router(config)# interface < 인터페이스
Router(config-if)# no ip directed-broadcast
l Radware Alteon
Step 1) dirbr 에서 disable 설정 확인
Step 2) dirbr 서비스 비활성화
# cfg/l3/frwd
# dirbr disable
# apply
# save
l Passport
Step 1) config 에서 ip directed-broadcast 설정 확인
Step 2) directed-broadcast 서비스 비활성화
# config vlan <vid> ip directed-broadcast
# disable

**조치방법**:
장치별로 Directed Broadcasts 제한 설정

---

### N-32 Source Routing 차단

> 점검ID: N-32 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: Source Routing을 차단하는지 점검

**판단기준**:
- ✅ 양호: ip-source-route를 차단하는 경우
- ❌ 취약: ip-source-route를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) Global Configuration 모드에서 no ip source-route 명령어를 실행하여 비활성화
Router# config terminal
Router(config)# no ip source-route
l Juniper Junos
Step 1) ip source route 설정 확인
user@host# show route
Step 2) [edit]
user@host# set chassis no-source-route
※ Junos 8.5 버전 이후부터 기본적으로 IPv4 소스 라우팅 비활성화 상태

**조치방법**:
각 인터페이스에서 ip-source-route 차단 설정

---

### N-33 Proxy ARP 차단

> 점검ID: N-33 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: Proxy ARP를 차단하는지 점검

**판단기준**:
- ✅ 양호: Proxy ARP를 차단하는 경우
- ❌ 취약: Proxy ARP를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) Interface Configuration 모드에서 no ip proxy-arp 명령어를 실행하여 비활성화
Router# config terminal
Router(config)# interface < 인터페이스
Router(config-if)# no ip proxy-arp
l Juniper Junos
Step 1) 각 인터페이스에서 proxy-arp 설정을 확인
user@host# show
Step 2) [edit interfaces < 인터페이스  - unit < 유닛 >]
user@host# delete proxy-arp

**조치방법**:
각 인터페이스에서 Proxy ARP 비활성화 설정

---

### N-34 ICMP unreachable, redirect 차단

> 점검ID: N-34 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: ICMP unreachable, ICMP redirect를 차단하는지 점검

**판단기준**:
- ✅ 양호: ICMP unreachable, ICMP redirect를 차단하는 경우
- ❌ 취약: ICMP unreachable, ICMP redirect를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) 각 인터페이스에서 no ip unreachables 과 no ip redirects 설정을 확인
Router> enable
Router# show running-config
※ Global Configuration 모드의 ip icmp redirects 명령어는 ICMP redirection 메시지 유형을 호스트 또는 서브넷으
로 지정하는 명령어로 ICMP redirection 차단과 무관
Step 2) Interface Configuration 모드에서 no ip unreachables 과 no ip redirects 명령어를 실행
Router# config terminal
Router(config)# interface < 인터페이스
Router(config-if)# no ip unreachables
Router(config-if)# no ip redirects
Router(config-if)# end
※ Null Interface 는 no ip unreachables 외 다른 모든 명령어는 무시됨
l Juniper Junos
Step 1) ICMP unreachables, ICMP redirects 적용 확인
user@host# show
Step 2) ICMP redirect 차단
전체 장비에서 ICMP redirect 비활성화
[edit system]
user@host#set no-redirects

**조치방법**:
각 인터페이스에서 ICMP unreachables, ICMP redirects 비활성화

---

### N-35 identd 서비스 차단

> 점검ID: N-35 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: identd 서비스를 차단하는지 점검

**판단기준**:
- ✅ 양호: identd 서비스를 차단하는 경우
- ❌ 취약: identd 서비스를 차단하지 않는 경우

**점검방법**:
l Cisco IOS
Step 1) identd 서비스 확인
Router> enable
Router# show running-config
Step 2) Global Configuration 모드에서 no ip identd 명령어를 실행하여 비활성화
Router# config terminal
Router(config)# no ip identd
※ 기본적으로 ip identd 설정을 별도로 설정하지 않으면 비활성화 상태이며, 구성에서 no ip identd 명령어가 표시되
지 않음

**조치방법**:
idnetd 서비스 비활성화

---

### N-36 Domain Lookup 차단

> 점검ID: N-36 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: Domain Lookup을 차단하는지 점검

**판단기준**:
- ✅ 양호: Domain Lookup을 차단하는 경우
- ❌ 취약: Domain Lookup을 차단하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) no ip domain-lookup 설정을 확인
Router> enable
Router# show running-config
Step 2) Global Configuration 모드에서 no ip domain lookup 명령어를 실행
Router# config terminal
Router(config)# no ip domain lookup
또는
Router(config)# no ip domain-lookup
※ IOS 12.2 버전부터 ip domain-lookup 을 ip domain lookup 로 변경하고 두 명령어 모두 지원

**조치방법**:
Domain Lookup 비활성화

---

### N-37 pad 차단

> 점검ID: N-37 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: PAD 서비스를 차단하는지 점검

**판단기준**:
- ✅ 양호: PAD 서비스를 차단하는 경우
- ❌ 취약: PAD 서비스를 차단하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) no service pad 설정을 확인
Router> enable
Router# show running-config
Step 2) Global Configuration 모드에서 no service pad 명령어를 사용하여 비활성화
Router# config terminal
Router(config)# no service pad

**조치방법**:
PAD 서비스 비활성화

---

### N-38 mask-reply 차단

> 점검ID: N-38 | 위험도: 중 | 카테고리: 기능 관리

**점검내용**: mask-reply를 차단하는지 점검

**판단기준**:
- ✅ 양호: mask-reply를 차단하는 경우
- ❌ 취약: mask-reply를 차단하지 않은 경우

**점검방법**:
l Cisco IOS
Step 1) mask-reply 차단 여부 확인
Router# show running-config
Step 2) show ip interface 실행 결과에서 ICMP Address mask-reply 차단 여부 확인
Router# show ip interface
Serial1/0 is up, line protocol is up (connected)
ICMP mask replies are never sent
Step 3) Interface Configuration 모드에서 no ip mask-reply 명령어를 사용하여 비활성화
Router# config terminal
Router(config)# interface < 인터페이스
Router(config-if)# no ip mask-reply
※ 기본적으로 ip mask-reply 명령은 비활성화 상태이기 때문에 구성 내용에서 no ip mask-reply 명령이 표시되지 않음

**조치방법**:
각 인터페이스에서 mask-reply 비활성화

---

