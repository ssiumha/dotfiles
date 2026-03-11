# Unix 서버 취약점 점검항목

> 출처: KISA 주요정보통신기반시설 기술적 취약점 분석평가 방법 상세가이드 (2026)
> 총 항목: 67개 (U-01 ~ U-67)


## 계정관리

### U-01 root 계정 원격 접속 제한

> 점검ID: U-01 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 시스템 정책에 root 계정의 원격터미널 접속 차단 설정이 적용 여부 점검

**판단기준**:
- ✅ 양호: 원격터미널 서비스를 사용하지 않거나, 사용 시 root 직접 접속을 차단한 경우
- ❌ 취약: 원격터미널 서비스 사용 시 root 직접 접속을 허용한 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/default/login 파일 내에 CONSOLE 설정값 수정
CONSOLE=/dev/console
Step 1) /etc/ssh/sshd_config 파일 내의 PermitRootLogin 설정값 수정
PermitRootLogin No
```

**LINUX**:
```bash
Step 1) /etc/pam.d/login 파일 내에 auth required /lib/security/pam_securetty.so 입력
Step 2) /etc/securetty 파일 내에 pts/ 설정값 주석 처리 및 제거
#pts/0
#pts/1
#pts/2
Step 3) /etc/pam.d/login 파일 내에 모듈 추가
auth required /lib/security/pam_securetty.so
※ /etc/securetty 파일 내 pts/x 관련 설정이 존재하는 경우 PAM 모듈 설정과 관계없이 root 계정 접속을 허용하
므로 반드시 제거 필요
※ CentOS 8, Ubuntu 20.04 이상부터 /etc/securetty 파일이 존재하지 않으며 기본적으로 Telnet 서비스가 비활성
Step 1) /etc/ssh/sshd_config 파일에 PermitRootLogin 값 수정
PermitRootLogin No
```

**AIX**:
```bash
Step 1) /etc/security/user 파일에 rlogin 설정값 수정
rlogin = false
Step 1) /etc/ssh/sshd_config 파일에 PermitRootLogin 값 수정
PermitRootLogin No
l HP-UX
```

**HP-UX**:
```bash
Step 1) etc/securetty 파일 내에 console 값 수정
console
※ /etc/securetty 파일은 기본적으로 존재하지 않으므로 해당 파일이 존재하지 않는 경우 생성 후 설정할 것
Step 1) /opt/ssh/etc/sshd_config 파일 내에 PermitRootLogin 값 수정
PermitRootLogin No
```

### U-02 비밀번호 관리정책 설정

> 점검ID: U-02 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 비밀번호 관리 정책 설정 여부 점검

**판단기준**:
- ✅ 양호: 비밀번호 관리 정책이 설정된 경우
- ❌ 취약: 비밀번호 관리 정책이 설정되지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/default/passwd 파일 내에 비밀번호 설정값 수정
HISTORY=4
PASSLENGTH=8
MINDIGIT=1
MINUPPER=1
MINLOWER=1
MINSPECIAL=1
WHITESPACE=NO
|권고값|기능|설명|
|---|---|---|
|HISTORY= 10|이전 비밀번호 기억 개수|이전 10개의 암호를 기억함|
|MINDIFF= 4|이전 암호와 차이|이전 암호와 4자 이상 차이 요구|
|MINALPHA= 1|최소 문자 요구|최소 1자 이상 문자 요구|
|MINNONALPHA= 1|최소 숫자 또는 특수문자 요구|숫자 또는 특수문자 1자 이상 요구|
|MINUPPER= 1|최소 대문자 요구|최소 1자 이상 대문자 요구|
|MINLOWER= 1|최소 소문자 요구|최소 1자 이상 소문자 요구|
|MAXREPEATS= 0|연속 문자 사용 허용|0일 경우 문자 연속 사용이 불가|
|MINSPECIAL= 1|최소 특수문자 요구|최소 1자 이상 특수문자 요구|
|MINDIGIT= 1|최소 숫자 요구|최소 1자 이상 숫자 요구|
|NAMECHECK= YES|아이디와 비밀번호 동일 검증|아이디와 동일한 비밀번호 사용 불가|
|MAXDAYS= 90|비밀번호 최대 유효일 수|최대 90일 비밀번호가 유효|
|MINDAYS= 1|비밀번호 변경 최소일 수|비밀번호 최소 1일 후 변경 가능|
|MAXWEEKS= 12|비밀번호 최대 유효 주 수|최대 12주 비밀번호가 유효|
|MINWEEKS= 1|비밀번호 변경 최소일 수|비밀번호 최소 일주일 후 변경 가능|
|WARNWEEKS= 1|비밀번호 만료 전 알림 주 수|비밀번호 만료 일주일 전 알림|
|PASSLENGTH= 8|비밀번호 최소 길이|비밀번호 최소 길이 8|
|WHITESPACE= NO|비밀번호 공백문자 사용 여부|비밀번호에 공백문자 사용 금지 설정|
※ MINDIGIT, MINSPECIAL 설정이 적용되어 있는 경우 MINNONALPHA 설정은 적용되지 않음
※ MINDAYS 설정이 적용되어야 MAXDAYS 설정이 적용됨
※ 비밀번호 유효일 설정과 비밀번호 유효 주 설정은 중복 설정 불가함
※ WHITESPACE 기본값 : YES
```

**LINUX**:
```bash
Step 1) /etc/login.defs 파일에 PASS_MAX_DAYS / PASS_MIN_DAYS 값 수정
PASS_MAX_DAYS 90
PASS_MIN_DAYS 0
Step 2) /etc/security/pwquality.conf 파일에 정책 값 수정
minlen = 8
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
enforce_for_root
Step 3) /etc/security/pwhistory.conf 파일에 값 추가 및 수정
enforce_for_root
remember=4
file = /etc/security/opasswd
Step 4) /etc/pam.d/system-auth 파일에 값 수정
Step 5) /etc/login.defs 파일에 PASS_MAX_DAYS / PASS_MIN_DAYS 값 수정
PASS_MAX_DAYS 90
PASS_MIN_DAYS 1
※ pam_pwquality.so, pam_pwhistory.so 모듈은 pam_unix.so 모듈 위에 위치해야 적용됨
※ /etc/security/pwquality.conf 파일과 /etc/pam.d/system-auth 파일 중 어느 하나라도 비밀번호 관리 정책이
설정되어 있으면 양호
※ 비밀번호 복잡성 설정에서 최소 요구 항목의 값은 반드시 -1 로 설정되어야 함
※ /etc/pam.d/system-auth 파일에 enforce_for_root 추가
Step 1) /etc/security/pwquality.conf 파일에 정책 값 수정
minlen = 8
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
enforce_for_root
Step 2) /etc/pam.d/common-password 파일에 정책 값 수정
pam_pwquality.so, pam_pwhistory.so 모듈은 pam_unix.so 모듈 위에 위치해야 적용됨
Step 3) /etc/login.defs 파일에 값 수정
PASS_MAX_DAYS 90
PASS_MIN_DAYS 1
|권고값|기능|설명|
|---|---|---|
|difok = N|기존 비밀번호와 비교|기존 비밀번호에 포함되지 않는 문자를 최소 N개 이상<br>포함하도록 설정|
|minlen = 8|최소 비밀번호 길이 설정|최소 8자리 이상 설정|
|dcredit = -1|최소 숫자 요구|최소 숫자 1자 이상 요구|
|ucredit = -1|최소 대문자 요구|최소 대문자 1자 이상 요구|
|lcredit = -1|최소 소문자 요구|최소 소문자 1자 이상 요구|
|ocredit = -1|최소 특수문자 요구|최소 특수문자 1자 이상 요구|
|remember = N|최근 비밀번호 기억|최근 변경한 비밀번호를 N개 이상 기억하여 동일한<br>비밀번호로 변경하지 못하도록 설정|
|PASS_MIN_DAYS = 1|비밀번호 최소 사용 기간 설정|비밀번호 최소 사용 기간 설정 (단위 : 일)|
|PASS_MAX_DAYS = 90|비밀번호 최대 사용 기간 설정|비밀번호 최대 사용 기간 설정 (단위 : 일)|
※ /etc/security/pwquality.conf 파일과 /etc/pam.d/common-password(/etc/pam.d/system-auth) 파일 중 어느
하나라도 비밀번호 관리 정책이 설정되어 있으면 양호
※ 비밀번호 복잡성 설정에서 최소 요구 항목의 값은 반드시 -1 로 설정되어야 함
※ /etc/pam.d/system-auth 파일에 enforce_for_root 추가
```

**AIX**:
```bash
Step 1) etc/security/user 파일에 정책 값 수정
default :
minage = 1
maxage = 12
minalpha = 2
minother = 2
minspecialchar = 1
minlen = 8
mindiff = 4
histsize = 4
|권고값|기능|설명|
|---|---|---|
|histexpire= N|동일한 비밀번호 재사용 기간|비밀번호 재사용에 필요한 시간 (단위 : 주)|
|histsize= 4|이전 비밀번호 기억 개수|허용 비밀번호 반복 횟수|
|maxrepeats= 2|반복 가능한 동일 문자의 최대 수|비밀번호에서 반복될 수 있는 최대 문자 수|
|minalpha= 2|최소 알파벳 문자 포함|비밀번호에 필요한 최소 영문자 수|
|minother= 2|최소 알파벳 문자 이외의 문자 수|비밀번호에 필요한 최소 알파벳을 제외한 문자 수|
|minspecialchar= 1|최소 특수문자 포함|비밀번호에 필요한 최소 특수문자 수|
|mindiff= 4|이전 비밀번호와 동일 문자 수|이전 비밀번호와 구별되는 새 비밀번호의 최소 문자 수|
|minlen= 8|비밀번호 최소 길이|최소 비밀번호 길이|
|minage= 1|비밀번호 최소 사용 기간|비밀번호 변경에 필요한 최소 기간 (단위 : 주)|
|maxage= 12|비밀번호 최대 사용 기간|비밀번호 변경에 필요한 최대 시간 (단위 : 주)|
l HP-UX
Step 1) /etc/default/security 파일에 정책 값 수정
MIN_PASSWORD_LENGTH=8
PASSWORD_MIN_UPPER_CASE_CHARS=1
PASSWORD_MIN_LOWER_CASE_CHARS=1
PASSWORD_MIN_DIGIT_CASE_CHARS=1
PASSWORD_MIN_SPECIAL_CASE_CHARS=1
PASSWORD_MAXDAYS=90
PASSWORD_MINDAYS=1
HISTORY=4
|권고값|기능|설명|
|---|---|---|
|MIN_PASSWORD_LENG<br>TH= 8|비밀번호 최소 길이|최소 비밀번호 길이|
|PASSWORD_MIN_UPPE<br>R_CASE_CHARS= 1|최소 대문자 필요 개수|비밀번호에 필요한 최소 대문자 수|
|PASSWORD_MIN_LOWE|최소 소문자 필요 개수|비밀번호에 필요한 최소 소문자 수|
|권고값|기능|설명|
|---|---|---|
|R_CASE_CHARS= 1|||
|PASSWORD_MIN_DIGIT_<br>CHARS= 1|최소 숫자 필요 개수|비밀번호에 필요한 최소 숫자 수|
|PASSWORD_MIN_SPECI<br>AL_CHARS= 1|최소 특수문자 필요 개수|비밀번호에 필요한 최소 특수문자 수|
|PASSWORD_MINDAYS=<br>1|비밀번호 최소 사용 기간|비밀번호 변경에 필요한 최소 기간 (단위 : 일)|
|PASSWORD_MAXDAYS=<br>90|비밀번호 최대 사용 기간|비밀번호 변경에 필요한 최대 시간 (단위 : 일)|
|HISTORY= 4|이전 비밀번호 기억 개수|허용 비밀번호 반복 횟수|
사전에 나오는 단어나 이들의 조합
길이가 너무 짧거나 NULL( 공백 ) 인 비밀번호
키보드 자판의 일련의 나열 ( 예시 : abcd, qwert 등 )
사용자 계정 정보에서 유추 가능한 단어들 ( 예시 : 지역명, 부서명, 계정명, 사용자 이름 이니셜, root, admin 등 )
```

**HP-UX**:
```bash
Step 1) /etc/default/security 파일에 정책 값 수정
MIN_PASSWORD_LENGTH=8
PASSWORD_MIN_UPPER_CASE_CHARS=1
PASSWORD_MIN_LOWER_CASE_CHARS=1
PASSWORD_MIN_DIGIT_CASE_CHARS=1
PASSWORD_MIN_SPECIAL_CASE_CHARS=1
PASSWORD_MAXDAYS=90
PASSWORD_MINDAYS=1
HISTORY=4
|권고값|기능|설명|
|---|---|---|
|MIN_PASSWORD_LENG<br>TH= 8|비밀번호 최소 길이|최소 비밀번호 길이|
|PASSWORD_MIN_UPPE<br>R_CASE_CHARS= 1|최소 대문자 필요 개수|비밀번호에 필요한 최소 대문자 수|
|PASSWORD_MIN_LOWE|최소 소문자 필요 개수|비밀번호에 필요한 최소 소문자 수|
|권고값|기능|설명|
|---|---|---|
|R_CASE_CHARS= 1|||
|PASSWORD_MIN_DIGIT_<br>CHARS= 1|최소 숫자 필요 개수|비밀번호에 필요한 최소 숫자 수|
|PASSWORD_MIN_SPECI<br>AL_CHARS= 1|최소 특수문자 필요 개수|비밀번호에 필요한 최소 특수문자 수|
|PASSWORD_MINDAYS=<br>1|비밀번호 최소 사용 기간|비밀번호 변경에 필요한 최소 기간 (단위 : 일)|
|PASSWORD_MAXDAYS=<br>90|비밀번호 최대 사용 기간|비밀번호 변경에 필요한 최대 시간 (단위 : 일)|
|HISTORY= 4|이전 비밀번호 기억 개수|허용 비밀번호 반복 횟수|
사전에 나오는 단어나 이들의 조합
길이가 너무 짧거나 NULL( 공백 ) 인 비밀번호
키보드 자판의 일련의 나열 ( 예시 : abcd, qwert 등 )
사용자 계정 정보에서 유추 가능한 단어들 ( 예시 : 지역명, 부서명, 계정명, 사용자 이름 이니셜, root, admin 등 )
```

### U-03 계정 잠금 임계값 설정

> 점검ID: U-03 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 사용자 계정 로그인 실패 시 계정 잠금 임계값이 설정 여부 점검

**판단기준**:
- ✅ 양호: 계정 잠금 임계값이 10회 이하의 값으로 설정된 경우
- ❌ 취약: 계정 잠금 임계값이 설정되어 있지 않거나, 10회 이하의 값으로 설정되지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/default/login 파일에 RETRIES 값 수정
RETRIES=10
Step 1) /etc/security/policy.conf 파일에 LOCK_AFTER_RETRIES 값 수정
LOCK_AFTER_RETRIES=YES
UNLOCK_AFTER =2m
|옵션|설명|
|---|---|
|RETRIES|로그인 시도 횟수|
|LOCK_AFTER_RETRIES|로그인 시도 횟수와 같거나 초과 되면 잠금 여부|
|UNLOCK_AFTER|잠금시간 분(m), 시(h), 일(d), w(주) 단위로 설정 가능|
```

**LINUX**:
```bash
Step 1) /etc/pam.d/system-auth 파일에 deny 값 수정
auth required /lib/security/pam_tally.so 또는 /lib/security/pam_tally2.so deny=10 unlock_time=120 no_magic_root
account required /lib/security/pam_tally.so 또는 /lib/security/pam_tally2.so no_magic_root reset
※ /etc/pam.d/system-auth 파일 수정 시 모듈이 해당 경로에 존재하지 않을 경우, 모든 계정의 로그인이 되지 않
는 등 예기치 못한 상황이 발생할 수 있으므로 반드시 올바른 경로를 작성해야 함
Step 1) # authselect enable-feature with-faillock 입력하여 faillock 적용
# authselect current
Profile ID: sssd
Enabled features:
- with-fingerprint
- with-silent-lastlog
- with-faillock
Step 2) etc/securiy/faillock.conf 파일에 정책 값 수정
silent
deny = 10
unlock_time = 120
```

**AIX**:
```bash
Step 1) /etc/security/user 파일에 loginretries 값 수정
loginretries = 3
l HP-UX
Step 1) /tcb/files/auth/system/default 파일에 u_maxtries 값 수정
u_maxtries#3
※ HP-UX 서버에 계정 잠금 정책 설정을 위해서는 HP-UX 서버가 Trusted Mode 로 동작하고 있어야 하므로
Trusted Mode 로 전환 후 잠금 정책 적용
```

**HP-UX**:
```bash
Step 1) /tcb/files/auth/system/default 파일에 u_maxtries 값 수정
u_maxtries#3
※ HP-UX 서버에 계정 잠금 정책 설정을 위해서는 HP-UX 서버가 Trusted Mode 로 동작하고 있어야 하므로
Trusted Mode 로 전환 후 잠금 정책 적용
Step 1) /etc/default/security 파일에 AUTH_MAXTRIES 값 수정
AUTH_MAXTRIES=3
※ Standard 모드와 Shadow 모드만 적용 가능
|옵션|설명|
|---|---|
|no_magic_root|root 계정은 비밀번호 잠금 설정을 적용하지 않음|
|deny=N|N회 입력 실패 시 계정 잠금|
|unlock_time|계정이 잠긴 경우, 마지막 계정 실패 시간부터 설정된 시간이 지나면 자동으로 계정<br>잠금 해제 (단위 : 초)|
|reset|접속 시도 성공 시 실패한 횟수 초기화|
```

### U-04 비밀번호 파일 보호

> 점검ID: U-04 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 시스템의 사용자 계정(root, 일반 사용자) 정보가 저장된 파일(/etc/passwd, /etc/shadow 등)에 사용자 계정 비밀번호가 암호화 저장 여부 점검

**판단기준**:
- ✅ 양호: 쉐도우 비밀번호를 사용하거나, 비밀번호를 암호화하여 저장하는 경우
- ❌ 취약: 쉐도우 비밀번호를 사용하지 않고, 비밀번호를 암호화하여 저장하지 않는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX
Step 1) /etc/passwd 입력 후 파일 내 두 번째 필드가 x 표시되는지 확인
root:x:0:0:root:/root:/bin/bash
Step 2) # pwconv 명령으로 쉐도우 비밀번호 적용
※ SOLARIS 11 은 pwunconv 명령어가 존재하지 않음
```

**AIX**:
```bash
Step 1) /etc/security/passwd 파일에 암호화 여부 확인
※ AIX 는 기본적으로 /etc/security/passwd 파일에 비밀번호를 암호화하여 저장 관리함
l HP-UX
Step 1) /etc/passwd 파일에 암호화 확인
Step 2) # pwconv 명령으로 쉐도우 비밀번호 적용
※ HP-UX 서버는 Trusted Mode 로 전환할 경우 비밀번호를 암호화하여 /tcb/files/auth 디렉터리에 계정 이니셜
과 계정 이름에 따라 파일로 저장 관리할 수 있으므로 Trusted Mode 인지 확인 후 UnTrusted Mode 인 경우 모
드를 전환함
※ Trusted mode 전환 방법 : root 계정으로 아래 명령어 실행
# /etc/tsconvert
※ UnTrusted mode 전환 방법 : root 계정으로 아래 명령어 실행
# /etc/tsconvert –r
※ HP-UX 11.11 의 경우 Shadow Password Bundle 을 설치하여야 /etc/shadow 파일 생성됨
```

**HP-UX**:
```bash
Step 1) /etc/passwd 파일에 암호화 확인
Step 2) # pwconv 명령으로 쉐도우 비밀번호 적용
※ HP-UX 서버는 Trusted Mode 로 전환할 경우 비밀번호를 암호화하여 /tcb/files/auth 디렉터리에 계정 이니셜
과 계정 이름에 따라 파일로 저장 관리할 수 있으므로 Trusted Mode 인지 확인 후 UnTrusted Mode 인 경우 모
드를 전환함
※ Trusted mode 전환 방법 : root 계정으로 아래 명령어 실행
# /etc/tsconvert
※ UnTrusted mode 전환 방법 : root 계정으로 아래 명령어 실행
# /etc/tsconvert –r
※ HP-UX 11.11 의 경우 Shadow Password Bundle 을 설치하여야 /etc/shadow 파일 생성됨
```

### U-05 root 이외의 UID가 ‘0’ 금지

> 점검ID: U-05 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 사용자 계정 정보가 저장된 파일(/etc/passwd, /etc/shadow 등)에 root(UID=0) 계정과 동일한 UID를 가진 계정이 존재 여부 점검

**판단기준**:
- ✅ 양호: root 계정과 동일한 UID를 갖는 계정이 존재하지 않는 경우
- ❌ 취약: root 계정과 동일한 UID를 갖는 계정이 존재하는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) usermod 명령어를 이용하여 # usermod -u < 변경할 UID> < 사용자 이름  - 명령으로 0 이외의 중복되지 않
는 UID 로 변경
※ “:”( 콜론 ) 을 사용하여 필드를 구분함
※ 세 번째 필드 (UID) 가 0 인 경우 슈퍼 유저 권한을 가지며, 0 이외의 계정은 일반, 시스템 계정으로 볼 수 있음
```

### U-06 사용자 계정 su 기능 제한

> 점검ID: U-06 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: su 명령어 사용을 허용하는 사용자를 지정한 그룹이 설정 여부 점검

**판단기준**:
- ✅ 양호: su 명령어를 특정 그룹에 속한 사용자만 사용하도록 제한된 경우 ※ 일반 사용자 계정 없이 root 계정만 사용하는 경우 su 명령어 사용 제한 불필요
- ❌ 취약: su 명령어를 모든 사용자가 사용하도록 설정된 경우


**점검방법**:
```bash
# /etc/group 파일 내 wheel 그룹 (su 명령어 사용 그룹 ) 및 그룹 내 구성원 존재 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
, AIX, HP-UX
Step 1) /etc/group 파일 내 wheel 그룹 (su 명령어 사용 그룹 ) 및 그룹 내 구성원 존재 여부 확인
Step 2) ls –l /usr/bin/su 입력 후 wheel 그룹이 su 명령어를 사용할 수 있는지 설정 여부 확인
Step 3) wheel group 생성 (wheel 그룹이 존재하지 않는 경우 )
# groupadd wheel
su 명령 그룹 변경
# chgrp wheel /usr/bin/su
su 명령어 권한 변경
# chmod 4750 /usr/bin/su
wheel 그룹에 su 명령 허용 계정 등록
# usermod -G wheel <username>
또는 직접 /etc/group 파일을 수정하여 필요한 계정 등록
wheel:x:10: -> wheel:x:10:root,admin
```

**LINUX**:
```bash
Step 1) /etc/group 파일 내 wheel 그룹 (su 명령어 사용 그룹 ) 확인
Step 2) ls 명령어를 이용하여 # ls -l /usr/bin/su 입력 후 su 명령어 그룹과 권한 확인
Step 3) wheel group 생성 (wheel 그룹이 존재하지 않는 경우 )
# groupadd wheel
su 명령 그룹 변경
# chgrp wheel /usr/bin/su
su 명령어 권한 변경
# chmod 4750 /usr/bin/su
wheel 그룹에 su 명령 허용 계정 등록
# usermod -G wheel <username>
※ /etc/group 파일에서 기본 그룹의 경우 사용자 이름은 생략되며 자동으로 포함됨
Step 1) /etc/group 입력 후 wheel 그룹 (su 명령어 사용 그룹 ) 확인
예시 ) wheel:x:1002:
Step 2) etc/pam.d/su 파일 내 su 명령어 허용 그룹 확인
Step 3) usr/bin/su 파일 내 su 명령어 그룹과 권한 확인
Step 4) /etc/pam.d/su 파일에 모듈 값 수정
auth required pam_wheel.so use_uid
auth required pam_wheel.so group=wheel
```

### U-07 불필요한 계정 제거

> 점검ID: U-07 | 위험도: 하 | 카테고리: 계정관리

**점검내용**: 시스템 계정 중 불필요한 계정(퇴직, 전직, 휴직 등의 이유로 사용하지 않는 계정 및 장기적으로 사용하지 않는 계정 등)이 존재 여부 점검

**판단기준**:
- ✅ 양호: 불필요한 계정이 존재하지 않는 경우
- ❌ 취약: 불필요한 계정이 존재하는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/passwd 파일 내 계정을 확인 후 “# userdel < 사용자 이름 >” 명령으로 불필요한 사용자 계정 제거
※ AIX 경우 rmuser 명령어 사용
※ /etc/passwd 파일에서 계정 앞에 # 을 삽입하여도 주석으로 처리되지 않으므로 조치 시에는 반드시 계정을 제
거하도록 권고함
```

### U-08 관리자 그룹에 최소한의 계정 포함

> 점검ID: U-08 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: 시스템 관리자 그룹에 최소한(root 계정과 시스템 관리에 허용된 계정)의 계정만 존재 여부 점검

**판단기준**:
- ✅ 양호: 관리자 그룹에 불필요한 계정이 등록되어 있지 않은 경우
- ❌ 취약: 관리자 그룹에 불필요한 계정이 등록된 경우


**점검방법**:
```bash
# /etc/group 파일에 root 그룹에 포함된 계정 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/group 파일에 root 그룹에 포함된 계정 확인
Step 2) 불필요한 계정을 그룹원에서 제거
# gpasswd -d < 사용자 이름      - root
※ AIX 의 경우 chgrpmem -m - < 사용자 이름 - root 명령어 사용
```

### U-09 계정이 존재하지 않는 GID 금지

> 점검ID: U-09 | 위험도: 하 | 카테고리: 계정관리

**점검내용**: 그룹 설정 파일(/etc/group)에 불필요한 그룹이 존재 여부 점검

**판단기준**:
- ✅ 양호: 시스템 관리나 운용에 불필요한 그룹이 제거된 경우
- ❌ 취약: 시스템 관리나 운용에 불필요한 그룹이 존재하는 경우


**점검방법**:
```bash
# /etc/group, /etc/gshadow 파일에 계정이 존재하지 않거나, 불필요한 그룹 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/group, /etc/gshadow 파일에 계정이 존재하지 않거나, 불필요한 그룹 확인
Step 2) 불필요한 그룹 제거
# groupdel < 그룹 이름
※ 해당 그룹 제거 시 그룹 권한으로 존재하는 파일이 존재하는지 확인이 필요하며, 사용자가 없는 그룹이더라도
추후 권한 할당을 위해 그룹을 먼저 생성하였을 가능성도 존재하므로 확인 필요
```

### U-10 동일한 UID 금지

> 점검ID: U-10 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: /etc/passwd 파일 내 UID가 동일한 사용자 계정 존재 여부 점검

**판단기준**:
- ✅ 양호: 동일한 UID로 설정된 사용자 계정이 존재하지 않는 경우
- ❌ 취약: 동일한 UID로 설정된 사용자 계정이 존재하는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/passwd 파일에 동일한 UID 가 존재하는지 확인
Step 2) 명령으로 중복된 UID 로 변경
# usermod -u < 변경할 UID> < 사용자 이름
※ AIX 의 경우 chuser id=< 변경할 UID> < 사용자 이름 - 명령어 사용
```

### U-11 사용자 shell 점검

> 점검ID: U-11 | 위험도: 하 | 카테고리: 계정관리

**점검내용**: 로그인이 불필요한 계정(adm, sys, daemon 등)에 쉘 부여 여부 점검

**판단기준**:
- ✅ 양호: 로그인이 필요하지 않은 계정에 /bin/false(/sbin/nologin) 쉘이 부여된 경우
- ❌ 취약: 로그인이 필요하지 않은 계정에 /bin/false(/sbin/nologin) 쉘이 부여되지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/passwd 파일을 참고하여 로그인이 불필요한 계정에 /bin/false(/sbin/nologin) 쉘 부여 여부 확인
# cat /etc/passwd | grep –E “^daemon|^bin|^sys|^adm|^listen|^nobody|^nobody4|^noaccess|^diag|^operator|^
games|^gopher” | grep -v admin
Step 2) 로그인이 불필요한 계정에 /bin/false 또는 /sbin/nologin 쉘 부여
# usermod -s /bin/false < 계정명
# usermod –s /sbin/nologin < 계정명
**로그인이 불필요한 계정 목록**
deamon, bin, sys, adm, listen, nobody, nobody4, noaccess, diag, operator, games, gopher
```

### U-12 세션 종료 시간 설정

> 점검ID: U-12 | 위험도: 하 | 카테고리: 계정관리

**점검내용**: 사용자 쉘에 대한 환경설정 파일에서 Session Timeout 설정 여부 점검

**판단기준**:
- ✅ 양호: Session Timeout이 600초(10분) 이하로 설정된 경우
- ❌ 취약: Session Timeout이 600초(10분) 이하로 설정되지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/profile 파일 내 TMOUT 값 설정
TMOUT=600
export TMOUT
```

### U-13 안전한 비밀번호 암호화 알고리즘 사용

> 점검ID: U-13 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: 안전한 비밀번호 암호화 알고리즘을 사용 여부 점검

**판단기준**:
- ✅ 양호: SHA-2 이상의 안전한 비밀번호 암호화 알고리즘을 사용하는 경우
- ❌ 취약: 취약한 비밀번호 암호화 알고리즘을 사용하는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/passwd 파일 내 암호화 필드 값 확인
Step 2) /etc/security/policy.conf 파일 내 CRYPT_DEFAULT 값 설정
CRYPT_DEFAULT = 5 또는 6
※ CRYPT_DEFAULT = 5: SHA-256 / 6 : SHA-512
```

**LINUX**:
```bash
Step 1) /etc/shadow( 또는 /etc/passwd) 파일 내 암호화 필드 값 확인
Step 2) /etc/login.defs 파일 내 ENCRYPT_METHOD 값 설정
ENCRYPT_METHOD <SHA-2 이상 암호화 알고리즘 (SHA-256 또는 SHA-512)>
Step 3) /etc/pam.d/system-auth 파일 내 안전한 알고리즘 설정
password  sufficient  pam_unix.so <SHA-2 이상 암호화 알고리즘
Step 1) /etc/shadow( 또는 /etc/passwd) 파일 내의 암호화 필드 값 확인
Step 2) /etc/login.defs 파일 내 ENCRYPT_METHOD 값 설정
ENCRYPT_METHOD <SHA-2 이상 암호화 알고리즘 (SHA-256 또는 SHA-512 또는 yescrypt)>
Step 3) /etc/pam.d/common-password 파일 내 안전한 알고리즘 설정
password[success=2 default=ignore] pam_unix.so <SHA-2 이상 암호화 알고리즘
```

**AIX**:
```bash
Step 1) /etc/security/passwd 파일 내 비밀번호 암호화 알고리즘 확인
password = {< 암호화 알고리즘 >}< 해시값
Step 2) 안전한 암호화 알고리즘 설정
# chsec -f /etc/security/login.cfg –s usw –a pwd_algorithm=<SHA-2 이상 암호화 알고리즘 (SHA-256 또는 SHA-512)>
※ /etc/security/pwdalg.cfg 파일을 참조하여 OS 에서 정의된 암호화 알고리즘 확인 가능
l HP-UX
Step 1) /etc/shadow 파일 내의 암호화 필드 값 확인
Step 2) /etc/default/security 파일 내 CRYPT_DEFAULT 값 설정
CRYPT_DEFAULT = 5 또는 6
※ HP-UX 11i v2 이상이며, PHI 및 shadow password 를 사용하지 않는 경우 취약
※ CRYPT_DEFAULT = 5: SHA-256 / 6 : SHA-512
```

**HP-UX**:
```bash
Step 1) /etc/shadow 파일 내의 암호화 필드 값 확인
Step 2) /etc/default/security 파일 내 CRYPT_DEFAULT 값 설정
CRYPT_DEFAULT = 5 또는 6
※ HP-UX 11i v2 이상이며, PHI 및 shadow password 를 사용하지 않는 경우 취약
※ CRYPT_DEFAULT = 5: SHA-256 / 6 : SHA-512
```


## 파일 및 디렉터리 관리

### U-14 root 홈, 패스 디렉터리 권한 및 패스 설정

> 점검ID: U-14 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: root 계정의 PATH 환경변수에 “.”(마침표)이 포함 여부 점검

**판단기준**:
- ✅ 양호: PATH 환경변수에 “.” 이 맨 앞이나 중간에 포함되지 않은 경우
- ❌ 취약: PATH 환경변수에 “.” 이 맨 앞이나 중간에 포함된 경우


**점검방법**:
```bash
# PATH 환경변수 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) PATH 환경변수 확인
# echo $PATH
Step 2) 환경설정 파일 내 PATH 변숫값 수정
PATH=$PATH:$HOME/bin:< 상대 경로     - 또는 상대 경로 삭제
**Shell 종류별 환경설정 파일**
|Bourne Shell(sh)|/etc/profile, $HOME/.profile|
|---|---|
|C Shell(csh)|/etc/csh.cshrc, /etc/csh.login, $HOME/.cshrc, $HOME/.login|
|Korn Shell(ksh)|/etc/profile, $HOME/.profile, $HOME/.kshrc|
|Bash Shell(bash)|/etc/profile, $HOME/.bash_profile, $HOME/.bashrc, /etc/bash.bashrc|
```

### U-15 파일 및 디렉터리 소유자 설정

> 점검ID: U-15 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 소유자가 존재하지 않는 파일 및 디렉터리의 존재 여부 점검

**판단기준**:
- ✅ 양호: 소유자가 존재하지 않는 파일 및 디렉터리가 존재하지 않는 경우
- ❌ 취약: 소유자가 존재하지 않는 파일 및 디렉터리가 존재하는 경우


**점검방법**:
```bash
# 소유자와 그룹이 존재하지 않는 파일 및 디렉터리 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) 소유자와 그룹이 존재하지 않는 파일 및 디렉터리 확인
# find / \( -nouser -o -nogroup \) -xdev -ls 2>/dev/null
Step 2) 소유자가 존재하지 않는 파일 또는 디렉터리 제거
# rm < 파일 이름
# rm -r < 디렉터리 이름
Step 3) 사용 중인 파일 및 디렉터리의 경우 소유자 및 그룹 변경
# chown < 사용자 이름     - < 파일 및 디렉터리 이름
# chgrp < 그룹 이름      - < 파일 및 디렉터리 이름
※ 소유자 또는 그룹이 존재하지 않는 파일은 파일 속성의 해당 필드에 UID, GID 가 숫자로 표시됨
```

### U-16 /etc/passwd 파일 소유자 및 권한 설정

> 점검ID: U-16 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/passwd 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/passwd 파일의 소유자가 root이고, 권한이 644 이하인 경우
- ❌ 취약: /etc/passwd 파일의 소유자가 root가 아니거나, 권한이 644 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/passwd 파일 소유자 및 권한 확인
# ls -l /etc/passwd
Step 2) /etc/passwd 파일 소유자 및 권한 변경
# chown root /etc/passwd
# chmod 644 /etc/passwd
```

### U-17 시스템 시작 스크립트 권한 설정

> 점검ID: U-17 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 시스템 시작 스크립트 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: 시스템 시작 스크립트 파일의 소유자가 root이고, 일반 사용자의 쓰기 권한이 제거된 경우
- ❌ 취약: 시스템 시작 스크립트 파일의 소유자가 root가 아니거나, 일반 사용자의 쓰기 권한이 부여된 경우


**점검방법**:
```bash
# 시스템 시작 스크립트 파일 소유자 및 권한 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) 시스템 시작 스크립트 파일 소유자 및 권한 확인
# ls -al `readlink -f /etc/rc*.d/ | sed ‘s/$/*/’`
Step 2) 시스템 시작 스크립트 파일 소유자 및 권한 변경
# chown root < 파일 이름
# chmod o-w < 파일 이름
```

**LINUX**:
```bash
Step 1) 시스템 시작 스크립트 파일 소유자 및 권한 확인
# ls -al `readlink -f /etc/rc.d/*/* | sed ‘s/$/*/’`
Step 2) 시스템 시작 스크립트 파일 소유자 및 권한 변경
# chown root < 파일 이름
# chmod o-w < 파일 이름
Step 1) 시스템 시작 스크립트 파일 소유자 및 권한 확인
# ls -al `readlink -f /etc/systemd/system/* | sed ‘s/$/*/’`
Step 2) 시스템 시작 스크립트 파일 소유자 및 권한 변경
# chown root /etc/systemd/system/< 파일 이름
# chmod o-w /etc/systemd/system/< 파일 이름
```

**AIX**:
```bash
Step 1) 시스템 시작 스크립트 파일 소유자 및 권한 확인
# find /etc/rc.d/*/* -type l -exec ls -l {} +
Step 2) 시스템 시작 스크립트 파일 소유자 및 권한 변경
# chown root < 파일 이름
# chmod o-w < 파일 이름
l HP-UX
Step 1) 시스템 시작 스크립트 파일 소유자 및 권한 확인
# find /sbin/rc*.d/ -type l -exec ls -l {} +
Step 2) 시스템 시작 스크립트 파일 소유자 및 권한 변경
# chown root < 파일 이름
# chmod o-w < 파일 이름
```

**HP-UX**:
```bash
Step 1) 시스템 시작 스크립트 파일 소유자 및 권한 확인
# find /sbin/rc*.d/ -type l -exec ls -l {} +
Step 2) 시스템 시작 스크립트 파일 소유자 및 권한 변경
# chown root < 파일 이름
# chmod o-w < 파일 이름
```

### U-18 /etc/shadow 파일 소유자 및 권한 설정

> 점검ID: U-18 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/shadow 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/shadow 파일의 소유자가 root이고, 권한이 400 이하인 경우
- ❌ 취약: /etc/shadow 파일의 소유자가 root가 아니거나, 권한이 400 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX
Step 1) /etc/shadow 파일 소유자 및 권한 변경
# chown root /etc/shadow
# chmod 400 /etc/shadow
```

**AIX**:
```bash
Step 1) /etc/security/passwd 파일 소유자 및 권한 변경
# chown root /etc/security/passwd
# chmod 400 /etc/security/passwd
l HP-UX
Step 1) /tcb/files/auth/ 디렉터리 소유자 및 권한 변경
# chown root /tcb/files/auth
# chmod 400 /tcb/files/auth
```

**HP-UX**:
```bash
Step 1) /tcb/files/auth/ 디렉터리 소유자 및 권한 변경
# chown root /tcb/files/auth
# chmod 400 /tcb/files/auth
```

### U-19 /etc/hosts 파일 소유자 및 권한 설정

> 점검ID: U-19 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/hosts 파일의 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/hosts 파일의 소유자가 root이고, 권한이 644 이하인 경우
- ❌ 취약: /etc/hosts 파일의 소유자가 root가 아니거나, 권한이 644 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/hosts 파일 소유자 및 권한 변경
# chown root /etc/hosts
# chmod 644 /etc/hosts
```

### U-20 /etc/(x)inetd.conf 파일 소유자 및 권한 설정

> 점검ID: U-20 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/(x)inetd.conf 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/(x)inetd.conf 파일의 소유자가 root이고, 권한이 600 이하인 경우
- ❌ 취약: /etc/(x)inetd.conf 파일의 소유자가 root가 아니거나, 권한이 600 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, AIX, HP-UX
Step 1) /etc/inetd.conf 파일 소유자 및 권한 변경
# chown root /etc/inetd.conf
# chmod 600 /etc/inetd.conf
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 소유자 및 권한 변경
# chown root /etc/inetd.conf
# chmod 600 /etc/inetd.conf
Step 1) /etc/xinetd.conf 파일 소유자 및 권한 변경
# chown root /etc/xinetd.conf
# chmod 600 /etc/xinetd.conf
Step 2) /etc/xinetd.d/ 디렉터리 내 모든 파일의 소유자 및 권한 변경
# chown -R root /etc/xinetd.d/
# chmod - R 600 /etc/xinetd.d/
```

### U-21 /etc/(r)syslog.conf 파일 소유자 및 권한 설정

> 점검ID: U-21 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/(r)syslog.conf 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/(r)syslog.conf 파일의 소유자가 root(또는 bin, sys)이고, 권한이 640 이하인 경우
- ❌ 취약: /etc/(r)syslog.conf 파일의 소유자가 root(또는 bin, sys)가 아니거나, 권한이 640 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/(r)syslog.conf 파일 소유자 및 권한 변경
# chown root /etc/(r)syslog.conf
# chmod 640 /etc/(r)syslog.conf
```

### U-22 /etc/services 파일 소유자 및 권한 설정

> 점검ID: U-22 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/services 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/services 파일의 소유자가 root(또는 bin, sys)이고, 권한이 644 이하인 경우
- ❌ 취약: /etc/services 파일의 소유자가 root(또는 bin, sys)가 아니거나, 권한이 644 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/services 파일 소유자 및 권한 변경
# chown root /etc/services
# chmod 644 /etc/services
```

### U-23 SUID, SGID, Sticky bit 설정 파일 점검

> 점검ID: U-23 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 불필요하거나 악의적인 파일에 SUID, SGID, Sticky bit 설정 여부 점검

**판단기준**:
- ✅ 양호: 주요 실행 파일의 권한에 SUID와 SGID에 대한 설정이 부여되어 있지 않은 경우
- ❌ 취약: 주요 실행 파일의 권한에 SUID와 SGID에 대한 설정이 부여된 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) SUID, SGID 가 설정된 파일 확인
# find / -user root -type f \( -perm -04000 -o -perm -02000 \) -xdev -exec ls -al {} \;
Step 2) 불필요한 특수 권한 제거
# chmod -s < 파일 이름
Step 3) 반드시 사용이 필요한 경우 특정 그룹에서만 사용하도록 제한하여 일반 사용자의 Setuid 사용 제한
# chgrp < 그룹 이름      - <SUID 를 설정할 파일
# chmod 4750 <SUID 를 설정할 파일
```

### U-24 사용자, 시스템 환경변수 파일 소유자 및 권한 설정

> 점검ID: U-24 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 홈 디렉터리 내의 환경변수 파일에 대한 소유자 및 접근 권한이 관리자 또는 해당 계정으로 설정 여부 점검

**판단기준**:
- ✅ 양호: 홈 디렉터리 환경변수 파일 소유자가 root 또는 해당 계정으로 지정되어 있고, 홈 디렉터리 환경변수 파일에 root 계정과 소유자만 쓰기 권한이 부여된 경우
- ❌ 취약: 홈 디렉터리 환경변수 파일 소유자가 root 또는 해당 계정으로 지정되지 않거나, 홈 디렉터리 환경변수 파일에 root 계정과 소유자 외에 쓰기 권한이 부여된 경우


**점검방법**:
```bash
# 홈 디렉터리 환경변수 파일 소유자 및 권한 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) 홈 디렉터리 환경변수 파일 소유자 및 권한 확인
# ls -l < 홈 디렉터리 환경변수 파일
환경변수 파일 종류 : .profile, .kshrc, .cshrc, .bashrc, .bash_profile, .login, .exrc, .netrc 등
Step 2) 홈 디렉터리 환경변수 파일 소유자 및 권한 변경
# chown <root 또는 파일 소유자      - < 홈 디렉터리 환경변수 파일
# chmod o-w < 홈 디렉터리 환경변수 파일
```

### U-25 world writable 파일 점검

> 점검ID: U-25 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 불필요한 world writable 파일 여부 점검

**판단기준**:
- ✅ 양호: world writable 파일이 존재하지 않거나, 존재 시 설정 이유를 인지하고 있는 경우
- ❌ 취약: world writable 파일이 존재하나 설정 이유를 인지하지 못하고 있는 경우


**점검방법**:
```bash
# world writable 파일 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) world writable 파일 확인
# find / -type f -perm -2 -exec ls -l {} \;
Step 2) 일반 사용자 쓰기 권한 제거
# chmod o-w < 파일 이름
Step 3) 불필요한 world writable 파일 제거
# rm < 파일 이름
```

### U-26 /dev에 존재하지 않는 device 파일 점검

> 점검ID: U-26 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 허용할 호스트에 대한 접속 IP주소 제한 및 포트 제한 설정 여부 점검

**판단기준**:
- ✅ 양호: /dev 디렉터리에 대한 파일 점검 후 존재하지 않는 device 파일을 제거한 경우
- ❌ 취약: /dev 디렉터리에 대한 파일 미점검 또는 존재하지 않는 device 파일을 방치한 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /dev 디렉터리 내 불필요하거나 존재하지 않는 device 파일 확인 및 삭제
# find /dev -type f -exec ls -l {} \;
# rm < 파일 이름
```

### U-27 $HOME/.rhosts, hosts.equiv 사용 금지

> 점검ID: U-27 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: $HOME/.rhosts 및 /etc/hosts.equiv 파일에 대해 적절한 소유자 및 접근 권한 설정 여부 점검

**판단기준**:
- ✅ 양호: rlogin, rsh, rexec 서비스를 사용하지 않거나, 사용 시 아래와 같은 설정이 적용된 경우 1. /etc/hosts.equiv 및 $HOME/.rhosts 파일 소유자가 root 또는 해당 계정인 경우 2. /etc/hosts.equiv 및 $HOME/.rhosts 파일 권한이 600 이하인 경우 3. /etc/hosts.equiv 및 $HOME/.rhosts 파일 설정에 “+” 설정이 없는 경우
- ❌ 취약: rlogin, rsh, rexec 서비스를 사용하며 아래와 같은 설정이 적용되지 않은 경우 1. /etc/hosts.equiv 및 $HOME/.rhosts 파일 소유자가 root 또는 해당 계정이 아닌 경우 2. /etc/hosts.equiv 및 $HOME/.rhosts 파일 권한이 600을 초과한 경우 3. /etc/hosts.equiv 및 $HOME/.rhosts 파일 설정에 “+” 설정이 존재하는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/hosts.equiv, $HOME/.rhosts 파일 소유자 및 권한 변경
# chown <root 또는 해당 계정      - /etc/hosts.equiv
# chmod 600 /etc/hosts.equiv
# chown <root 또는 해당 계정     - $HOME/.rhosts
# chmod 600 $HOME/.rhosts
Step 2) /etc/hosts.equiv, $HOME/.rhosts 파일 내 “+” 옵션이 부여된 계정 확인
Step 3) /etc/hosts.equiv, vi $HOME/.rhosts 파일 내 “+” 옵션 제거 후 허용 호스트 및 계정 등록
```

### U-28 접속 IP 및 포트 제한

> 점검ID: U-28 | 위험도: 상 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 허용할 호스트에 대한 접속 IP주소 제한 및 포트 제한 설정 여부 점검

**판단기준**:
- ✅ 양호: 접속을 허용할 특정 호스트에 대한 IP주소 및 포트 제한을 설정한 경우
- ❌ 취약: 접속을 허용할 특정 호스트에 대한 IP주소 및 포트 제한을 설정하지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) TCP Wrapper 에 설정된 접근제한 확인
Step 2) 서비스 차단 및 허용 설정값 수정
# vi /etc/hosts.deny
ALL:ALL
# vi /etc/hosts.allow
< 허용할 서비스    - : < 허용할 IP 주소
예시 ) sshd : 192.168.18.129, 192.168.18.180
※ TCP Wrapper 접근제어 가능 서비스 : SYSTAT, FINGER, FTP, TELNET, RLOGIN, RSH, TALK, EXEC,
TFTP, SSH
※ hosts.allow, hosts.deny 두 파일이 존재하지 않는 경우 모든 접근을 허용함
Step 1) Packet Filter 에 설정된 접근제한 확인 및 수정
Step 2) /etc/firewall/pf.conf 파일에 허용할 IP 및 포트 정책 추가
예시 ) SSH 서비스 제한
# pass in quick proto tcp from 192.168.1.0/24 to any port = 22 keep state
# block in quick proto tcp from any to any port = 22 keep state
Step 3) 설정한 접근제한 정책 적용
# svcadm refresh svc:/network/firewall:default
```

**LINUX**:
```bash
Step 1) TCP Wrapper 에 설정된 접근제한 확인
Step 2) 서비스 차단 및 허용 설정값 수정
# vi /etc/hosts.deny
ALL:ALL
# vi /etc/hosts.allow
< 허용할 서비스    - : < 허용할 IP 주소
예시 ) sshd : 192.168.18.129, 192.168.18.180
※ TCP Wrapper 접근제어 가능 서비스 : SYSTAT, FINGER, FTP, TELNET, RLOGIN, RSH, TALK, EXEC,
TFTP, SSH
※ hosts.allow, hosts.deny 두 파일이 존재하지 않는 경우 모든 접근을 허용함
Step 1) Iptables 에 설정된 접근제한 확인
# iptables -L
Step 2) Iptables 에 허용할 IP 및 포트 정책 추가
# iptables -A INPUT -p < 프로토콜      - -s <IP 주소      - --dport < 목적지 포트      - -j ACCEPT
Step 3) 설정한 접근제한 정책 적용
# iptables-save
```

**AIX**:
```bash
Step 1) TCP Wrapper 에 설정된 접근제한 확인
Step 2) 서비스 차단 및 허용 설정값 수정
# vi /etc/hosts.deny
ALL:ALL
# vi /etc/hosts.allow
< 허용할 서비스    - : < 허용할 IP 주소
예시 ) sshd : 192.168.18.129, 192.168.18.180
※ TCP Wrapper 접근제어 가능 서비스 : SYSTAT, FINGER, FTP, TELNET, RLOGIN, RSH, TALK, EXEC,
TFTP, SSH
※ hosts.allow, hosts.deny 두 파일이 존재하지 않는 경우 모든 접근을 허용함
Step 1) IPfilter 에 설정된 접근제한 확인 및 수정
# vi /etc/ipf/ipf.conf
Step 2) /etc/ipf/ipf.conf 파일에 허용할 IP 및 포트 정책 추가
예시 ) SSH 서비스 제한
# pass in quick proto tcp from 192.168.1.0/24 to any port = 22 keep state
# block in quick proto tcp from any to any port = 22 keep state
Step 3) IPfilter 서비스 재시작
l HP-UX
```

**HP-UX**:
```bash
Step 1) inetd.sec 에 설정된 접근제한 확인 및 수정
# vi /var/adm/inetd.sec
Step 2) 아래와 같이 수정 또는 삽입
특정 서비스로의 모든 IP 접근 차단 시 : < 서비스    - deny *.*.*.*
특정 서비스로의 일부 IP 접근 허용 시 : < 서비스    - allow < 접속을 허용할 IP 주소
Step 1) TCP Wrapper 에 설정된 접근제한 확인
Step 2) 서비스 차단 및 허용 설정값 수정
# vi /etc/hosts.deny
ALL:ALL
# vi /etc/hosts.allow
< 허용할 서비스    - : < 허용할 IP 주소
예시 ) sshd : 192.168.18.129, 192.168.18.180
※ TCP Wrapper 접근제어 가능 서비스 : SYSTAT, FINGER, FTP, TELNET, RLOGIN, RSH, TALK, EXEC,
TFTP, SSH
※ hosts.allow, hosts.deny 두 파일이 존재하지 않는 경우 모든 접근을 허용함
```

### U-29 hosts.lpd 파일 소유자 및 권한 설정

> 점검ID: U-29 | 위험도: 하 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: /etc/hosts.lpd 파일의 제거 및 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/hosts.lpd 파일이 존재하지 않거나, 불가피하게 사용 시 /etc/hosts.lpd 파일의 소유자가 root이고, 권한이 600 이하인 경우
- ❌ 취약: /etc/hosts.lpd 파일이 존재하며, 파일의 소유자가 root가 아니거나, 권한이 600 이하가 아닌 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/hosts.lpd 파일 소유자 및 권한 확인 및 수정
# ls –l /etc/hosts.lpd
# chown root /etc/hosts.lpd
# chmod 600 /etc/hosts.lpd
```

### U-30 UMASK 설정 관리

> 점검ID: U-30 | 위험도: 중 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 시스템 UMASK 값이 022 이상 설정 여부 점검

**판단기준**:
- ✅ 양호: UMASK 값이 022 이상으로 설정된 경우
- ❌ 취약: UMASK 값이 022 미만으로 설정된 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/profile 파일 내 UMASK 설정 확인 및 수정
# vi /etc/profile
umask 022
export umask
Step 1) /etc/default/login 파일 내 UMASK 설정 확인 및 수정
# vi /etc/default/login
UMASK=022
```

**LINUX**:
```bash
Step 1) /etc/profile 파일 내 UMASK 설정 확인 및 수정
# vi /etc/profile
umask 022
export umask
Step 1) /etc/login.defs 파일 내 UMASK 설정 확인 및 수정
# vi /etc/login.defs
UMASK 022
```

**AIX**:
```bash
Step 1) /etc/profile 파일 내 UMASK 설정 확인 및 수정
# vi /etc/profile
umask 022
export umask
Step 1) /etc/security/user 파일 내 UMASK 설정 확인 및 수정
# vi /etc/security/user
default : umask = 022 또는 < 사용자 이름      - : umask = 022
l HP-UX
```

**HP-UX**:
```bash
Step 1) /etc/profile 파일 내 UMASK 설정 확인 및 수정
# vi /etc/profile
umask 022
export umask
Step 1) /etc/default/securitz 파일 내 UMASK 설정 수정
UMASK = 022
```

### U-31 홈디렉토리 소유자 및 권한 설정

> 점검ID: U-31 | 위험도: 중 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 홈 디렉토리의 소유자 외 타 사용자가 해당 홈 디렉토리를 수정할 수 없도록 제한 설정 여부 점검

**판단기준**:
- ✅ 양호: 홈 디렉토리 소유자가 해당 계정이고, 타 사용자 쓰기 권한이 제거된 경우
- ❌ 취약: 홈 디렉토리 소유자가 해당 계정이 아니거나, 타 사용자 쓰기 권한이 부여된 경우


**점검방법**:
```bash
# 사용자별 홈 디렉토리 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) 사용자별 홈 디렉토리 확인
# cat /etc/passwd
Step 2) 사용자별 홈 디렉토리 소유자 및 권한 확인
# ls -ald < 사용자 홈 디렉토리
Step 3) 사용자별 홈 디렉토리 소유자를 해당 사용자로 변경 및 일반 사용자 권한 제거
# chown < 사용자 이름     - < 사용자 홈 디렉토리
# chmod o-w < 사용자 홈 디렉토리
```

### U-32 홈 디렉토리로 지정한 디렉토리의 존재 관리

> 점검ID: U-32 | 위험도: 중 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 사용자 계정과 홈 디렉토리의 일치 여부 점검

**판단기준**:
- ✅ 양호: 홈 디렉토리가 존재하지 않는 계정이 발견되지 않는 경우
- ❌ 취약: 홈 디렉토리가 존재하지 않는 계정이 발견된 경우


**점검방법**:
```bash
# 사용자별 홈 디렉토리 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) 사용자별 홈 디렉토리 확인
# cat /etc/passwd
Step 2) 홈 디렉토리가 존재하지 않는 사용자 계정이 불필요한 계정일 경우, 해당 계정 삭제
# userdel < 사용자 이름
Step 3) 사용중인 계정일 시, 해당 계정의 홈 디렉토리 설정
# vi /etc/passwd
예시 ) example:x:1000:1000::/home/example:/bin/bash
```

### U-33 숨겨진 파일 및 디렉토리 검색 및 제거

> 점검ID: U-33 | 위험도: 하 | 카테고리: 파일 및 디렉터리 관리

**점검내용**: 숨겨진 파일 및 디렉토리 내 의심스러운 파일 존재 여부 점검

**판단기준**:
- ✅ 양호: 불필요하거나 의심스러운 숨겨진 파일 및 디렉토리를 제거한 경우
- ❌ 취약: 불필요하거나 의심스러운 숨겨진 파일 및 디렉토리를 제거하지 않은 경우


**점검방법**:
```bash
# 특정 디렉토리 내 불필요한 파일 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) 특정 디렉토리 내 불필요한 파일 확인
# ls -al < 디렉토리 이름
Step 2) 숨겨진 파일 및 디렉토리 확인
# find / -type f –name “.*”
# find / -type d -name “.*”
Step 3) 불필요하거나 의심스러운 숨겨진 파일 및 디렉토리 제거
# rm < 파일 이름
# rm -r < 디렉토리 이름
```


## 서비스 관리

### U-34 Finger 서비스 비활성화

> 점검ID: U-34 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: Finger 서비스 비활성화 여부 점검

**판단기준**:
- ✅ 양호: Finger 서비스가 비활성화된 경우
- ❌ 취약: Finger 서비스가 활성화된 경우


**점검방법**:
```bash
# /etc/inetd.conf 파일 내 Finger 서비스 활성화 여부 확인 및 비활성화
```

**조치방법**:


**SOLARIS**:
```bash
(5.9 이하 버전)
Step 1) /etc/inetd.conf 파일 내 Finger 서비스 활성화 여부 확인 및 비활성화
Finger 서비스 항목 주석 처리
예시 ) #finger stream tcp nowait bin /usr/lbin/fingered fingerd
Step 2) inetd 서비스 재시작
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 Finger 서비스 활성화 여부 확인 및 비활성화
Finger 서비스 항목 주석 처리
예시 ) #finger stream tcp nowait bin /usr/lbin/fingered fingerd
Step 2) inetd 서비스 재시작
Step 1) /etc/xinetd.d/finger 파일 내 Finger 서비스 활성화 여부 확인 및 비활성화
finger 의 disable 옵션을 yes 로 수정
Step 2) 설정 적용 및 xinetd 서비스 재시작
# systemctl restart xinetd
```

**AIX**:
```bash
, HP-UX
Step 1) /etc/inetd.conf 파일 내 Finger 서비스 활성화 여부 확인 및 비활성화
Finger 서비스 항목 주석 처리
예시 ) #finger stream tcp nowait bin /usr/lbin/fingered fingerd
Step 2) inetd 서비스 재시작
```

### U-35 공유 서비스에 대한 익명 접근 제한 설정

> 점검ID: U-35 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 공유 서비스의 익명 접근 제한 설정 여부 점검

**판단기준**:
- ✅ 양호: 공유 서비스에 대해 익명 접근을 제한한 경우
- ❌ 취약: 공유 서비스에 대해 익명 접근을 허용한 경우


**점검방법**:
```bash
# FTP 계정 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) FTP 계정 확인
# cat /etc/passwd | grep ftp
# cat /etc/passwd | grep anonymous
Step 2) FTP 계정 제거
# userdel ftp
# userdel anonymous
Step 1) Anonymous FTP 활성화 여부 확인
# cat /etc/vsftpd/vsftpd.conf | grep anonymous_enable
Step 2) Anonymous FTP 비활성화
# vi /etc/vsftpd/vsftpd.conf
anonymous_enable 옵션을 NO 로 수정
```

**LINUX**:
```bash
Step 1) FTP 계정 확인
# cat /etc/passwd | grep ftp
# cat /etc/passwd | grep anonymous
Step 2) FTP 계정 제거
# userdel ftp
# userdel anonymous
Step 1) Anonymous FTP 활성화 여부 확인
# cat /etc/vsftpd.conf | grep anonymous_enable
# cat /etc/vsftpd/vsftpd.conf | grep anonymous_enable
Step 2) Anonymous FTP 비활성화
# vi /etc/vsftpd/vsftpd.conf
anonymous_enable 옵션을 NO 로 수정
Step 3) 변경된 설정 적용 및 재시작
# systemctl restart vsftpd
```

**AIX**:
```bash
Step 1) FTP 계정 확인
# cat /etc/passwd | grep ftp
# cat /etc/passwd | grep anonymous
Step 2) FTP 계정 제거
# rmuser ftp
# rmuser anonymous
Step 1) Anonymous FTP 활성화 여부 확인
# cat /etc/vsftpd.conf | grep anonymous_enable
Step 2) Anonymous FTP 비활성화
# vi /etc/vsftpd.conf
anonymous_enable 옵션을 NO 로 수정
Step 3) 서비스 재시작
# kill -1 <PID>
```

**HP-UX**:
```bash
Step 1) FTP 계정 확인
# cat /etc/passwd | grep ftp
# cat /etc/passwd | grep anonymous
Step 2) FTP 계정 제거
# userdel ftp
# userdel anonymous
Step 1) Anonymous FTP 활성화 여부 확인
# cat /etc/vsftpd.conf | grep anonymous_enable
Step 2) Anonymous FTP 비활성화
# vi /etc/vsftpd.conf
anonymous_enable 옵션을 NO 로 수정
Step 3) 서비스 재시작
# kill -1 <PID>
```

### U-36 r 계열 서비스 비활성화

> 점검ID: U-36 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: r-command 서비스 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 불필요한 r 계열 서비스가 비활성화된 경우
- ❌ 취약: 불필요한 r 계열 서비스가 활성화된 경우


**점검방법**:
```bash
# /etc/inetd.conf 파일 내 불필요한 r 계열 서비스 활성화 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
(5.9 이하 버전)
Step 1) /etc/inetd.conf 파일 내 불필요한 r 계열 서비스 활성화 여부 확인
# vi /etc/inetd.conf
Step 2) 불필요한 r 계열 서비스 관련 필드 주석처리
예시 ) #shell stream tcp  nowait root /usr/sbin/in.rshd  in.rshd
Step 3) 서비스 재시작
# kill -HUP [inetd PID]
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 불필요한 r 계열 서비스 활성화 여부 확인
Step 2) 불필요한 r 계열 서비스 관련 필드 주석 처리
# vi /etc/inetd.conf
예시 ) # rlogin stream tcp nowait root /usr/sbin/in.rlogind in.rlogind
Step 3) inetd 서비스 재시작
Step 1) /etc/xinetd.d/< 파일 이름  - 파일 내 불필요한 r 계열 서비스 활성화 여부 확인
Step 2) 불필요한 r 계열 서비스 비활성화
disable 값을 yes 로 수정
Step 3) 설정 적용 및 서비스 재시작
# systemctl restart xinetd
```

**AIX**:
```bash
, HP-UX
Step 1) /etc/inetd.conf 파일 내 불필요한 r 계열 서비스 활성화 여부 확인
Step 2) 불필요한 r 계열 서비스 관련 필드 주석 처리
# vi /etc/inetd.conf
예시 ) #login  stream tcp6  nowait root  /usr/sbin/rlogind   rlogind
Step 3) 변경된 설정 적용
- AIX : # refresh –s inetd
-HP-UX : # inetd -c
```

### U-37 crontab 설정파일 권한 설정 미흡

> 점검ID: U-37 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: crontab 및 at 서비스 관련 파일의 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: crontab 및 at 명령어에 일반 사용자 실행 권한이 제거되어 있으며, cron 및 at 관련 파일 권한이 640 이하인 경우
- ❌ 취약: crontab 및 at 명령어에 일반 사용자 실행 권한이 부여되어 있으며, cron 및 at 관련 파일 권한이 640 이상인 경우


**점검방법**:
```bash
# crontab, cron 작업 목록 파일, cron 관련 파일 소유자 및 권한 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) crontab, cron 작업 목록 파일, cron 관련 파일 소유자 및 권한 확인
# ls –l /usr/bin/crontab
# ls -l /var/spool/cron/crontabs/<cron 작업 목록 파일
# ls -l /etc/cron.d/<cron 관련 파일
Step 2) at, at 작업 목록 파일 소유자 및 권한 확인
# ls –l /usr/bin/at
# ls -l /var/spool/cron/atjobs/<at 작업 목록 파일
Step 3) crontab 파일 및 at 파일 소유자를 root 로, 파일 권한을 750 으로 변경
Step 4) cron 작업 목록 파일, cron 관련 파일 및 at 작업 목록 파일 소유자를 root 로, 파일 권한을 640 으로 변경
※ crontab 및 at 명령어는 SUID 가 설정되어 있으므로 SUID 설정 제거 필요
```

**LINUX**:
```bash
Step 1) crontab, cron 작업 목록 파일, cron 관련 파일 소유자 및 권한 확인
# ls –l /usr/bin/crontab
# ls -l /var/spool/cron/<cron 작업 목록 파일 >, # ls -l /var/spool/cron/crontabs/<cron 작업 목록 파일
# ls -l /etc/<cron 관련 파일
Step 2) at, at 작업 목록 파일 소유자 및 권한 확인
# ls –l /usr/bin/at
# ls -l /var/spool/at/<at 작업 목록 파일 >, # ls -l /var/spool/cron/atjobs/<at 작업 목록 파일
Step 3) crontab 파일 및 at 파일 소유자를 root 로, 파일 권한을 750 으로 변경
Step 4) cron 작업 목록 파일, cron 관련 파일 및 at 작업 목록 파일 소유자를 root 로, 파일 권한을 640 으로 변경
※ crontab 및 at 명령어는 SUID 가 설정되어 있으므로 SUID 설정 제거 필요
```

**AIX**:
```bash
, HP-UX
Step 1) crontab, cron 작업 목록 파일, cron 관련 파일 소유자 및 권한 확인
# ls –l /usr/bin/crontab
# ls -l /var/spool/cron/crontabs/<cron 작업 목록 파일
# ls -l /var/adm/cron/<cron 관련 파일
Step 2) at, at 작업 목록 파일 소유자 및 권한 확인
# ls –l /usr/bin/at
# ls -l /var/spool/cron/atjobs/<at 작업 목록 파일
Step 3) crontab 파일 및 at 파일 소유자를 root 로, 파일 권한을 750 으로 변경
Step 4) cron 작업 목록 파일, cron 관련 파일 및 at 작업 목록 파일 소유자를 root 로, 파일 권한을 640 으로 변경
※ crontab 및 at 명령어는 SUID 가 설정되어 있으므로 SUID 설정 제거 필요
|cron 관련 설정 파일|설명|
|---|---|
|crontab|예약 작업을 등록하는 파일|
|cron.hourly|시간 단위 예약 실행 스크립트 등록 파일|
|cron.daily|일 단위 예약 실행 스크립트 등록 파일|
|cron.weekly|주 단위 예약 실행 스크립트 등록 파일|
|cron.monthly|월 단위 예약 실행 스크립트 등록 파일|
|cron.allow|crontab 명령어 허용 사용자 등록 파일|
|cron.deny|crontab 명령어 차단 사용자 등록 파일|
|/var/spool/cron 또는<br>/var/spool/cron/crontab|사용자별 설정된 cron 작업 목록|
※ cron.allow, cron.deny 두 파일 모두 존재하지 않을 시, root 계정만 cron 등록 가능
|at 관련 설정 파일|설명|
|---|---|
|at|예약 작업을 등록하는 파일|
|at.allow|at 명령어 허용 사용자 등록 파일|
|at.deny|at 명령어 차단 사용자 등록 파일|
|/var/spool/at 또는<br>/var/spool/cron/atjobs|사용자별 설정된 at 작업 목록|
※ at.allow, at.deny 두 파일 모두 존재하지 않을 시, root 계정만 at 등록 가능
```

### U-38 DoS 공격에 취약한 서비스 비활성화

> 점검ID: U-38 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 사용하지 않는 DoS 공격에 취약한 서비스의 실행 여부 점검

**판단기준**:
- ✅ 양호: DoS 공격에 취약한 서비스가 비활성화된 경우
- ❌ 취약: DoS 공격에 취약한 서비스가 활성화된 경우


**점검방법**:
```bash
# 서비스 데몬 활성화 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) 서비스 데몬 활성화 여부 확인
# inetadm | grep enable | egrep “echo|discard|daytime|chargen”
Step 2) 불필요한 서비스 데몬 중지
# inetadm -d < 중지하고자 하는 서비스 데몬
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 서비스 활성화 여부 확인
서비스 대상 : echo, discard, daytime, chargen
Step 2) /etc/inetd.conf 파일 수정 ( 주석 제거 )
예시 ) echo stream tcp nowait root internal
Step 3) inetd 서비스 재시작
# inetd
Step 1) /etc/xinetd.d/< 파일명  - 파일 내 서비스 활성화 여부 확인
예시 ) service echo{
disable     = no
...
Step 2) 서비스 비활성화
disable = yes
Step 3) 설정 적용 및 서비스 재시작
# service xinetd restart
```

**AIX**:
```bash
, HP-UX
Step 1) /etc/inetd.conf 파일 내 서비스 활성화 여부 확인
대상 서비스 : echo, discard, daytime, chargen
Step 2) /etc/inetd.conf 파일 수정 ( 주석 처리 )
# echo stream tcp   nowait root  internal
# discard stream tcp   nowait root  internal
# chargen stream tcp   nowait root  internal
# daytime stream tcp   nowait root  internal
# echo dgram  udp   wait  root  internal
# discard dgram  udp   wait  root  internal
# chargen dgram  udp   wait  root  internal
# daytime dgram  udp   wait  root  internal
Step 3) 설정 적용
refresh –s inetd
```

### U-39 불필요한 NFS 서비스 비활성화

> 점검ID: U-39 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 불필요한 NFS 서비스 사용 여부 점검

**판단기준**:
- ✅ 양호: 불필요한 NFS 서비스 관련 데몬이 비활성화된 경우
- ❌ 취약: 불필요한 NFS 서비스 관련 데몬이 활성화된 경우


**점검방법**:
```bash
# NFS 서비스 데몬 활성화 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) NFS 서비스 데몬 활성화 확인
# inetadm | egrep “nfs|statd|lockd”
Step 2) 불필요한 서비스 데몬 중지
# inetadm -d < 중지하고자 하는 서비스 데몬
```

**LINUX**:
```bash
Step 1) NFS 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep nfs
Step 2) 불필요한 NFS 서비스 중지
# systemctl stop < 서비스명
Step 3) NFS 서비스 비활성화
# systemctl disable < 서비스명
```

**AIX**:
```bash
Step 1) NFS 프로세스 활성화 여부 확인
# ps -ef | grep nfsd
Step 2) NFS 서비스 관련 데몬 중지
# kill –9 <PID>
Step 3) NFS 시동 스크립트 위치 확인
# ls -al /etc/rc.d/rc*.d/* | grep nfs
Step 4) NFS 시동 스크립트 이름 변경
# mv /etc/rc.d/rc2.d/S60nfs /etc/rc.d/rc2.d/_S60nfs
Step 1) NFS 서비스 활성화 여부 확인
# lssrc -a | grep nfs
Step 2) NFS 서비스 관련 데몬 중지
# stopsrc -g nfs
Step 3) /etc/inittab 파일 수정 ( 주석 처리 )
# rcnfs:23456789:wait:/etc/rc.nfs > /dev/console
# Start NFS Daemons
Step 4) /etc/inittab 파일 설정 적용
#init q
l HP-UX
Step 1) NFS 서비스 활성화 여부 확인 및 관련 데몬 PID 확인
# ps -ef | grep -E “nfsd|statd|lockd”
Step 2) NFS 서비스 관련 데몬 중지
# kill -9 <PID>
Step 3) /etc/rc.config.d/nfsconf 파일 수정
NFS_SERVER=0
Step 4) 설정 적용
# /usr/sbin/nfs.server start
```

**HP-UX**:
```bash
Step 1) NFS 서비스 활성화 여부 확인 및 관련 데몬 PID 확인
# ps -ef | grep -E “nfsd|statd|lockd”
Step 2) NFS 서비스 관련 데몬 중지
# kill -9 <PID>
Step 3) /etc/rc.config.d/nfsconf 파일 수정
NFS_SERVER=0
Step 4) 설정 적용
# /usr/sbin/nfs.server start
```

### U-40 NFS 접근 통제

> 점검ID: U-40 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: NFS(Network File System)의 접근 통제 설정 적용 여부 점검

**판단기준**:
- ✅ 양호: 접근 통제가 설정되어 있으며 NFS 설정 파일 접근 권한이 644 이하인 경우
- ❌ 취약: 접근 통제가 설정되어 있지 않고 NFS 설정 파일 접근 권한이 644를 초과하는 경우


**점검방법**:
```bash
# 파일 소유자 및 권한 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) 파일 소유자 및 권한 확인
# ls -l /etc/dfs/dfstab
# ls -l /etc/dfs/sharetab
Step 2) /etc/dfs/dfstab 파일 내 공유 중인 디렉터리에 접근할 수 있는 사용자 및 부여 권한 확인
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/dfs/dfstab
Step 4) 파일 권한을 644 로 변경
# chmod 644 /etc/dfs/dfstab
Step 5) /etc/dfs/dfstab 파일에 디렉터리 공유를 허용할 사용자 및 해당 사용자의 권한 설정
예시 ) 사용자의 읽기, 쓰기 권한 접속 허용 : share -F nfs -o rw, ro /export/home/example
사용자의 권한 접속 제한 : share -F nfs -o rw=client1:client2, ro=client1:client2 /export/home/example
Step 6) NFS 서비스 설정 적용
# shareall
※ 읽기 (ro), 쓰기 (rw) 권한에 각각 사용자를 설정하여야 읽기, 쓰기 권한 모두 제한 가능
```

**LINUX**:
```bash
Step 1) 파일 소유자 및 권한 확인
# ls -l /etc/exports
Step 2) /etc/exports 파일 내 공유 중인 디렉터리에 접근할 수 있는 사용자 및 부여 권한 확인
# cat /etc/exports
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/exports
Step 4) 파일 권한을 644 로 변경
# chmod 644 /etc/exports
Step 5) /etc/exports 파일에 디렉터리 공유를 허용할 사용자 및 해당 사용자의 권한 설정
예시 ) /home/example host1 (ro, root_squash)
Step 6) NFS 서비스 설정 적용
# exportfs -ra
```

**AIX**:
```bash
Step 1) 파일 소유자 및 권한 확인
# ls -l /etc/exports
Step 2) /etc/exports 파일 내 공유 중인 디렉터리에 접근할 수 있는 사용자 및 부여 권한 확인
# cat /etc/exports
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/exports
Step 4) 파일 권한을 644 로 변경
# chmod 644 /etc/exports
Step 5) /etc/exports 파일에 디렉터리 공유를 허용할 사용자 및 해당 사용자의 권한 설정
예시 ) /home/example –sec=sys:krb5p:krb5i:krb5:dh,ro=host1, access=host1
Step 6) NFS 서비스 재시작
# exportfs -u, exportfs –a
l HP-UX
Step 1) 파일 소유자 및 권한 확인
# ls -l /etc/dfs/dfstab
# ls -l /etc/dfs/sharetab
Step 2) /etc/dfs/dfstab 파일 내 공유 중인 디렉터리에 접근할 수 있는 사용자 및 부여 권한 확인
# cat /etc/dfs/dfstab
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/dfs/dfstab
Step 4) 파일 권한을 644 로 변경
# chmod 644 /etc/dfs/dfstab
Step 5) /etc/dfs/dfstab 파일에 디렉터리 공유를 허용할 사용자 및 해당 사용자의 권한 설정
예시 ) 사용자의 읽기, 쓰기 권한 접속 허용 : share -F nfs -o rw, ro /export/home/example
사용자의 권한 접속 제한 : share -F nfs -o rw=client1:client2, ro=client1:client2 /export/home/example
Step 6) NFS 서비스 설정 적용
# shareall
※ 읽기 (ro), 쓰기 (rw) 권한에 각각 사용자를 설정하여야 읽기, 쓰기 권한 모두 제한 가능
```

**HP-UX**:
```bash
Step 1) 파일 소유자 및 권한 확인
# ls -l /etc/dfs/dfstab
# ls -l /etc/dfs/sharetab
Step 2) /etc/dfs/dfstab 파일 내 공유 중인 디렉터리에 접근할 수 있는 사용자 및 부여 권한 확인
# cat /etc/dfs/dfstab
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/dfs/dfstab
Step 4) 파일 권한을 644 로 변경
# chmod 644 /etc/dfs/dfstab
Step 5) /etc/dfs/dfstab 파일에 디렉터리 공유를 허용할 사용자 및 해당 사용자의 권한 설정
예시 ) 사용자의 읽기, 쓰기 권한 접속 허용 : share -F nfs -o rw, ro /export/home/example
사용자의 권한 접속 제한 : share -F nfs -o rw=client1:client2, ro=client1:client2 /export/home/example
Step 6) NFS 서비스 설정 적용
# shareall
※ 읽기 (ro), 쓰기 (rw) 권한에 각각 사용자를 설정하여야 읽기, 쓰기 권한 모두 제한 가능
Step 1) 파일 소유자 및 권한 확인
# ls -l /etc/exports
Step 2) /etc/exports 파일 내 디렉터리에 접근할 수 있는 사용자 및 부여 권한 확인
# cat /etc/exports
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/exports
Step 4) 파일 권한을 644 로 변경
# chmod 644 /etc/exports
Step 5) /etc/exports 파일에 디렉터리 공유를 허용할 사용자 및 해당 사용자의 권한 설정
예시 ) /home/example host1 (ro, root_squash)
Step 6) NFS 서비스 설정 적용
# exportfs -ra
```

### U-41 불필요한 automountd 제거

> 점검ID: U-41 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: automountd 서비스 데몬의 실행 여부 점검

**판단기준**:
- ✅ 양호: automountd 서비스가 비활성화된 경우
- ❌ 취약: automountd 서비스가 활성화된 경우


**점검방법**:
```bash
# automount 서비스 데몬 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) automount 서비스 데몬 확인
#svcs -a | grep autofs
Step 2) autofs 서비스 데몬 확인
# svcs -l svc:/system/filesystem/autofs:default
Step 3) 서비스 데몬 중지
# svcadm disable < 중지하고자 하는 서비스 데몬
Step 4) autumount 또는 autofs 데몬 제거
# pkg uninstall < 삭제할 관련 데몬의 패키지명
```

**LINUX**:
```bash
Step 1) automount 또는 autofs 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep -E “automount|autofs”
Step 2) automount 또는 autofs 서비스 중지
# systemctl stop < 서비스명
Step 3) automount 또는 autofs 서비스 비활성화
# systemctl disable < 서비스명
```

**AIX**:
```bash
Step 1) automount 또는 autofs 서비스 활성화 여부 확인
# ps -ef | grep automountd
# ps -ef | grep autofs
Step 2) autumount 또는 autofs 서비스 중지
# kill -9 <PID>
Step 3) autumount 또는 autofs 데몬 제거
# installp –u < 삭제할 관련 데몬의 패키지명
Step 1) automount 또는 autofs 서비스 활성화 여부 확인
# lssrc -a | grep -E “automountd|autofs”
Step 2) automount 또는 autofs 서비스 중지
# stopsrc –s automountd
# stopsrc -s autofs
Step 3) /etc/inittab 파일 수정 ( 주석 처리 )
#automountd:2:once:/usr/sbin/automountd > /dev/console 2>$1
Step 4) /etc/inittab 파일 설정 적용
# init q
l HP-UX
Step 1) automount 또는 autofs 서비스 활성화 여부 확인
# ps -ef | grep automountd
# ps -ef | grep autofs
Step 2) autumount 또는 autofs 서비스 중지
# kill -9 <PID>
Step 3) /etc/rc.config.d/nfsconf 파일 수정
AUTOFS=0
```

**HP-UX**:
```bash
Step 1) automount 또는 autofs 서비스 활성화 여부 확인
# ps -ef | grep automountd
# ps -ef | grep autofs
Step 2) autumount 또는 autofs 서비스 중지
# kill -9 <PID>
Step 3) /etc/rc.config.d/nfsconf 파일 수정
AUTOFS=0
```

### U-42 불필요한 RPC 서비스 비활성화

> 점검ID: U-42 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 불필요한 RPC 서비스의 실행 여부 점검

**판단기준**:
- ✅ 양호: 불필요한 RPC 서비스가 비활성화된 경우
- ❌ 취약: 불필요한 RPC 서비스가 활성화된 경우


**점검방법**:
```bash
# RPC 서비스 관련 데몬 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) RPC 서비스 관련 데몬 확인
# inetadm | grep rpc | grep enabled | egrep “ttdbserver|rex|rstart|rusers|spray|wall|rquota”
Step 2) 불필요한 RPC 서비스 확인
# inetadm | egrep “ttbd|rex|rstat|ruser|spray|wall|rquoata
Step 3) 서비스 데몬 중지
# svcadm disable < 서비스 데몬
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 불필요한 RPC 서비스 활성화 여부 확인
# cat /etc/inetd.conf
Step 2) etc/inetd.conf 파일 수정 ( 주석 처리 )
#rpc.cmsd/2-4 dgram rpc/udp wait root /usr/dt/bin/rpc.cmsd rpc.cmsd
Step 3) inetd 서비스 재시작
# systemctl restart inetd
Step 1) /etc/xinetd.d/ 디렉터리 내 존재하는 불필요한 RPC 서비스 활성화 여부 확인
#cat /etc/xinetd.d/< 파일명
예시 ) service rpc-statd{
disable     = no
...
Step 2) /etc/xinetd.d/ 디렉터리 내 존재하는 불필요한 rpc 파일을 열어 disable 설정값 수정
disable = yes
Step 3) 설정 적용 및 서비스 재시작
# systemctl restart xinetd
```

**AIX**:
```bash
, HP-UX
Step 1) /etc/inetd.conf 파일 내 불필요한 RPC 서비스 활성화 여부 확인
Step 2) /etc/inetd.conf 파일 수정 ( 주석 처리 )
# rexd  sunrpc_tcp   tcp   wait  root  /usr/sbin/rpc.rexd rexd 100017 1
# rstatd sunrpc_udp   udp   wait  root /usr/sbin/rpc.rstatd rstatd 100001 1-3
Step 3) inetd 설정 적용
refresh –s inetd
```

### U-43 NIS, NIS+ 점검

> 점검ID: U-43 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 안전하지 않은 NIS 서비스의 비활성화, 안전한 NIS+ 서비스의 활성화 여부 점검

**판단기준**:
- ✅ 양호: NIS 서비스가 비활성화되어 있거나, 불가피하게 사용 시 NIS+ 서비스를 사용하는 경우
- ❌ 취약: NIS 서비스가 활성화된 경우


**점검방법**:
```bash
# NIS 서비스 데몬 구동 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) NIS 서비스 데몬 구동 여부 확인
# svcs -a |grep nis
Step 2) NIS 관련 서비스 데몬 확인
# svcs -a | grep nis
Step 3) NIS 서비스 데몬 중지
# svcadm disable < 서비스 데몬
```

**LINUX**:
```bash
Step 1) NIS 관련 서비스 데몬 활성화 여부 확인
# systemctl list-units --type=service | grep –E “ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated”
Step 2) NIS 관련 서비스 데몬 중지
# systemctl stop < 서비스명
Step 3) NIS 관련 서비스 데몬 비활성화
# systemctl disable < 서비스명
※ Redhat 계열 리눅스는 RHEL 8 버전부터 NIS(yp rpms) 패키지가 제거되었음
```

**AIX**:
```bash
Step 1) NIS 관련 서비스 데몬 활성화 여부 확인
# ps -ef | grep -E “ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated”
Step 2) NIS 관련 서비스 중지
# kill –9 <PID>
Step 3) NIS 관련 서비스 시동 스크립트 위치 확인
# ls -al /etc/rc.d/rc*.d/* | grep –E “ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated”
Step 4) NIS 관련 서비스 시동 스크립트 이름 변경
# mv /etc/rc.d/rc2.d/S73ypbind /etc/rc.d/rc2.d/_S73ypbind
Step 1) NIS 관련 서비스 데몬 활성화 여부 확인
# lssrc -a | grep -E “ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated”
Step 2) NIS 관련 서비스 중지
# stopsrc -s <NIS 관련 서비스명
Step 3) etc/inittab 파일 수정 ( 주석 처리 )
#ypserv:2:wait:/usr/lib/netsvc/yp/ypserv >> /dev/console 2>&1
#ypbind:2:wait:/usr/lib/netsvc/yp/ypbind >> /dev/console 2>&1
Step 4) /etc/inittab 파일 설정 적용
# init q
l HP-UX
Step 1) NIS 관련 서비스 데몬 활성화 여부 확인
# ps -ef | grep -E “ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated”
Step 2) NIS 관련 서비스 중지
# kill -9 <PID>
Step 3) etc/rc.config.d/namesrvs 파일 수정
NIS_MASTER_SERVER=0
NIS_SLAVE_SERVER=0
NIS_CLIENT_SERVER=0
|NIS 관련 서비스 데몬|설명|
|---|---|
|ypserv|master와 slave 서버에서 실행되며 클라이언트로부터의 ypbind 요청에 응답|
|ypbind|모든 NIS 시스템에서 실행되며 클라이언트와 서버를 바인딩하고 초기화함|
|rpc.yppasswdd|사용자들이 비밀번호를 변경하기 위해 사용|
|ypxfrd|NIS 마스터 서버에서만 실행되며 고속으로 NIS 맵 전송|
|rpc.ypupdated|NIS 마스터 서버에서만 실행되며 고속으로 암호화하여 NIS 맵 전송|
```

**HP-UX**:
```bash
Step 1) NIS 관련 서비스 데몬 활성화 여부 확인
# ps -ef | grep -E “ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated”
Step 2) NIS 관련 서비스 중지
# kill -9 <PID>
Step 3) etc/rc.config.d/namesrvs 파일 수정
NIS_MASTER_SERVER=0
NIS_SLAVE_SERVER=0
NIS_CLIENT_SERVER=0
|NIS 관련 서비스 데몬|설명|
|---|---|
|ypserv|master와 slave 서버에서 실행되며 클라이언트로부터의 ypbind 요청에 응답|
|ypbind|모든 NIS 시스템에서 실행되며 클라이언트와 서버를 바인딩하고 초기화함|
|rpc.yppasswdd|사용자들이 비밀번호를 변경하기 위해 사용|
|ypxfrd|NIS 마스터 서버에서만 실행되며 고속으로 NIS 맵 전송|
|rpc.ypupdated|NIS 마스터 서버에서만 실행되며 고속으로 암호화하여 NIS 맵 전송|
```

### U-44 tftp, talk 서비스 비활성화

> 점검ID: U-44 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: tftp, talk, ntalk 서비스의 활성화 여부 점검

**판단기준**:
- ✅ 양호: tftp, talk, ntalk 서비스가 비활성화된 경우
- ❌ 취약: tftp, talk, ntalk 서비스가 활성화된 경우


**점검방법**:
```bash
# tftp, talk 서비스 활성화 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) tftp, talk 서비스 활성화 여부 확인
# inetadm | egrep “tftp|talk”
Step 2) 불필요한 서비스 데몬 중지
# inetadm -d < 서비스 데몬명
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 tftp, talk, ntalk 서비스 활성화 여부 확인
# cat /etc/inetd.conf
Step 2) /etc/inetd.conf 파일 수정 ( 주석 처리 )
#tftp  dgram udp nobody  /usr/sbin/tftpd tftpd -n
#talk  stream tcp wait root  /usr/sbin/talkd talkd
#ntalk dgram udp wait root  /usr/sbin/talkd talkd
Step 3) inetd 서비스 재시작
# systemctl restart inetd
Step 1) /etc/xinetd.d/ 디렉터리 내 존재하는 tftp, talk, ntalk 파일에 대해 서비스 활성화 여부 확인
예시 ) service tftp{
disable     = no
...
Step 2) /etc/xinetd.d/ 디렉터리 내 존재하는 tftp, talk, ntalk 파일에 대한 설정값 변경
disable = yes
Step 3) 설정 적용 및 서비스 재시작
# systemctl restart xinetd
```

**AIX**:
```bash
, HP-UX
Step 1) 서비스 활성화 여부 확인
# /etc/inetd.conf | grep -E “tftp|talk|ntalk” tftp, talk, ntalk
Step 2) /etc/inetd.conf 파일 수정 ( 주석 처리 )
#tftp  dgram  udp6  SRC  nobody /usr/sbin/tftpd    tftpd -n
#talk  dgram  udp   wait  root   /usr/sbin/talkd    talkd
#ntalk  dgram  udp   wait  root   /usr/sbin/talkd    talkd
Step 3) intetd 설정 적용
refresh –s inetd
```

### U-45 메일 서비스 버전 점검

> 점검ID: U-45 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 취약한 버전의 메일 서비스 이용 여부 점검

**판단기준**:
- ✅ 양호: 메일 서비스 버전이 최신 버전인 경우
- ❌ 취약: 메일 서비스 버전이 최신 버전이 아닌 경우


**점검방법**:
```bash
# Sendmail 버전 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) Sendmail 버전 확인
# /usr/sbin/sendmail -d grep Version
Step 2) 최신 버전 확인 및 보안 패치 진행
Sendmail 홈페이지 (http://www.sendmail.org/) 에 접속하여 다운로드 및 보안 패치 적용
Step 1) Sendmail 서비스 활성화 여부 확인
# svcs -a | grep sendmail
Step 2) Sendmail 서비스 비활성화
# svcadm disable sendmail
```

**LINUX**:
```bash
Step 1) Sendmail 버전 확인
# sendmail –d0 -bt
Step 2) 최신 버전 확인 및 보안 패치 진행
Sendmail 홈페이지 [(http://www.sendmail.org/)](http://www.sendmail.org/) 에 접속하여 다운로드 및 보안 패치 적용
Step 1) Sendmail 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep sendmail
Step 2) Sendmail 서비스 중지
# systemctl stop sendmail
Step 3) Sendmail 서비스 비활성화
# systemctl disable sendmail
```

**AIX**:
```bash
Step 1) Sendmail 버전 확인
# sendmail –d0 -bt
Step 2) 최신 버전 확인 및 보안 패치 진행
Sendmail 홈페이지 [(http://www.sendmail.org/)](http://www.sendmail.org/) 에 접속하여 다운로드 및 보안 패치 적용
Step 1) Sendmail 서비스 활성화 여부 확인
# lssrc -a | grep sendmail
Step 2) Sendmail 서비스 중지
# stopsrc -s sendmail
Step 3) /etc/rc.tcpip 파일 수정 ( 주석 처리 )
#start /usr/lib/sendmail “$src_running” “-bd -q${qpi}”
```

**HP-UX**:
```bash
Step 1) Sendmail 버전 확인
# sendmail –d0 –bt
Step 2) 최신 버전 확인 및 보안 패치 진행
Sendmail 홈페이지 [(http://www.sendmail.org/)](http://www.sendmail.org/) 에 접속하여 다운로드 및 보안 패치 적용
Step 1) Sendmail 서비스 활성화 여부 및 PID 확인
# ps -ef | grep sendmail
Step 2) Sendmail 서비스 종료
# kill -9 <PID>
Step 3) /etc/rc.config.d/mailservs 파일 수정
SENDMAIL_SERVER=0
```

### U-46 일반 사용자의 메일 서비스 실행 방지

> 점검ID: U-46 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: SMTP 서비스 사용 시 일반 사용자의 q 옵션 제한 여부 점검

**판단기준**:
- ✅ 양호: 일반 사용자의 메일 서비스 실행 방지가 설정된 경우
- ❌ 취약: 일반 사용자의 메일 서비스 실행 방지가 설정되어 있지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/mail/sendmail.cf 파일 내 PrivacyOptions 설정에 restrictqrun 값 추가
PrivacyOptions = authwarnings, novrfy, noexpn, restrictqrun
Step 2) Sendmail 서비스 재시작
```

### U-47 스팸 메일 릴레이 제한

> 점검ID: U-47 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: SMTP 서버의 릴레이 기능 제한 여부 점검

**판단기준**:
- ✅ 양호: 릴레이 제한이 설정된 경우
- ❌ 취약: 릴레이 제한이 설정되어 있지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/mail/sendmail.cf 파일 내 릴레이 허용 설정 여부 확인
Step 2) /etc/mail/sendmail.mc 파일 수정
FEATURE(`promiscuous_relay’)dnl < 해당 설정 제거
Step 3) sendmail.cf 설정 파일 재생성
# m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
Step 4) /etc/mail/access 파일에 특정 IP, Domain, Email 주소, 네트워크에 대한 접근제한 설정
예시 ) localhost.localdomain  RELAY
localhost        RELAY
127.0.0.1        RELAY
spam.com       REJECT
§ /etc/mail/access 파일을 생성하거나 수정하였을 경우
# makemap hash /etc/mail/access.db < /etc/mail/access 명령으로 DB 파일 생성
Step 5) 설정 적용 및 재시작
# systemctl restart sendmail
※ Sendmail 8.9 이상 버전부터는 기본적으로 스팸 메일 릴레이 제한 설정이 적용됨
```

### U-48 expn, vrfy 명령어 제한

> 점검ID: U-48 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: SMTP 서비스 사용 시 expn, vrfy 명령어 사용 금지 설정 여부 점검

**판단기준**:
- ✅ 양호: noexpn, novrfy 옵션이 설정된 경우
- ❌ 취약: noexpn, novrfy 옵션이 설정되어 있지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/mail/sendmail.cf 파일 내 PrivacyOptions 설정 확인
Step 2) PrivacyOptions 옵션 수정
PrivacyOptions = authwarnings, novrfy, noexpn, restrictqrun
PrivacyOptions = restrictqrun, goaway
Step 3) Sendmail 서비스 재시작
※ goaway : authwarnings, noexpn, novrfy, noveb, needmailhelo, needexpnhelo, needvrfyhelo, nobodyreturn 기능
이 통합된 단축 옵션
```

### U-49 DNS 보안 버전 패치

> 점검ID: U-49 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: BIND 최신 버전 사용 유무 및 주기적 보안 패치 여부 점검

**판단기준**:
- ✅ 양호: 주기적으로 패치를 관리하는 경우
- ❌ 취약: 주기적으로 패치를 관리하고 있지 않은 경우


**점검방법**:
```bash
# DNS 서비스 활성화 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) DNS 서비스 활성화 여부 확인
# svcs -a | grep bind
Step 2) DNS 서비스 비활성화
# svcadm disable bind
Step 3) BIND 버전 확인
# named -v
Step 4) DNS 서비스 최신 패치 버전 확인 및 업데이트
ISC 홈페이지 https://www.isc.org/downloads/
※ BIND 9 취약점 정보 (BIND 9 Vulnerability matrix) https://kb.isc.org/v1/docs/en/aa-00913
```

**LINUX**:
```bash
Step 1) DNS 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep named
Step 2) DNS 서비스 비활성화
# systemctl stop named
Step 3) BIND 버전 확인
# named –v
Step 4) DNS 서비스 최신 패치 버전 확인 및 업데이트
ISC 홈페이지 https://www.isc.org/downloads/
※ BIND 9 취약점 정보 (BIND 9 Vulnerability matrix) https://kb.isc.org/v1/docs/en/aa-00913
```

**AIX**:
```bash
Step 1) DNS 서비스 활성화 여부 확인
lssrc -a | grep named
Step 2) DNS 서비스 비활성화
# stopsrc -s named
Step 3) BIND 버전 확인
# named –v
Step 4) DNS 서비스 최신 패치 버전 확인 및 업데이트
ISC 홈페이지 https://www.isc.org/downloads/
※ BIND 9 취약점 정보 (BIND 9 Vulnerability matrix) https://kb.isc.org/v1/docs/en/aa-00913
l HP-UX
Step 1) DNS 서비스 활성화 여부 확인
# ps -ef | grep named
Step 2) DNS 서비스 중지
# /sbin/init.d/named stop
Step 3) etc/rc.config.d/namesrvs 파일 내 NAMED 값을 0 으로 수정
NAMED=0
Step 4) BIND 버전 확인
# named –v
Step 5) DNS 서비스 최신 패치 버전 확인 및 업데이트
ISC 홈페이지 https://www.isc.org/downloads/
※ BIND 9 취약점 정보 (BIND 9 Vulnerability matrix) https://kb.isc.org/v1/docs/en/aa-00913
```

**HP-UX**:
```bash
Step 1) DNS 서비스 활성화 여부 확인
# ps -ef | grep named
Step 2) DNS 서비스 중지
# /sbin/init.d/named stop
Step 3) etc/rc.config.d/namesrvs 파일 내 NAMED 값을 0 으로 수정
NAMED=0
Step 4) BIND 버전 확인
# named –v
Step 5) DNS 서비스 최신 패치 버전 확인 및 업데이트
ISC 홈페이지 https://www.isc.org/downloads/
※ BIND 9 취약점 정보 (BIND 9 Vulnerability matrix) https://kb.isc.org/v1/docs/en/aa-00913
```

### U-50 DNS ZoneTransfer 설정

> 점검ID: U-50 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: Secondary Name Server로만 Zone 정보 전송 제한 여부 점검

**판단기준**:
- ✅ 양호: Zone Transfer를 허가된 사용자에게만 허용한 경우
- ❌ 취약: Zone Transfer를 모든 사용자에게 허용한 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) xfrnets 설정 확인
# cat /etc/named.boot | grep xfrnets 또는 # cat /etc/bind/named.boot | grep xfrnets
Step 2) allow-transfer 설정 확인
# cat /etc/named.conf | grep allow-transfer 또는 # cat /etc/bind/named.conf.options | grep allow-transfer
Step 3) / etc(/bind)/named.boot 파일의 xfrnets 설정값 수정
xfrnets <zone transfer 를 허용할 IP>
Step 4) /etc(/bind)/named.conf 파일의 allow-transfer 설정값 수정
allow-transfer { <zone transfer 를 허용할 IP>; };
Step 5) DNS 서비스 재시작
※ DNS 서비스 Zone 파일명은 임의 지정이 가능하므로 DNS 설정 파일의 Include 구문으로 참조하는 파일명 점검
```

### U-51 DNS 서비스의 취약한 동적 업데이트 설정 금지

> 점검ID: U-51 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: DNS 서비스의 취약한 동적 업데이트 설정 여부 점검

**판단기준**:
- ✅ 양호: DNS 서비스의 동적 업데이트 기능이 비활성화되었거나, 활성화 시 적절한 접근통제를 수행하고 있는 경우
- ❌ 취약: DNS 서비스의 동적 업데이트 기능이 활성화 중이며 적절한 접근통제를 수행하고 있지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) allow-update 설정 확인
# cat /etc/named.conf | grep allow-update 또는 # cat /etc/bind/named.conf.options | grep allow-update
Step 2) /etc(/bind)/named.conf 파일의 allow-update 설정값 수정
allow-update { none; };
Step 3) DNS 서비스 재시작
```

### U-52 Telnet 서비스 비활성화

> 점검ID: U-52 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: 원격 접속 시 Telnet 프로토콜 사용 여부 점검

**판단기준**:
- ✅ 양호: 원격 접속 시 Telnet 프로토콜을 비활성화하고 있는 경우
- ❌ 취약: 원격 접속 시 Telnet 프로토콜을 사용하는 경우


**점검방법**:
```bash
# Telnet 서비스 활성화 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) Telnet 서비스 활성화 여부 확인
# svcs -a | grep telnet
Step 2) Telnet 서비스 비활성화
# svcadm disable svc:/network/telnet:default
Step 3) SSH 서비스 실행
# svcadm enable ssh
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 Telnet 서비스 활성화 여부 확인
Step 2) 해당 옵션이 허용된 경우 설정 제거
예시 ) telnet stream tcp   nowait root  /usr/sbin/in.telnetd 주석 처리 혹은 명령어 줄 삭제
Step 3) inetd 서비스 재시작
# service inetd restart
Step 4) SSH 서비스 실행
# service sshd start
Step 1) /etc/xinetd.d/telnet 파일 내 Telnet 서비스 활성화 여부 확인
# cat /etc/xinetd.d/telnet
Step 2) /etc/xinetd.d/telnet 파일의 disable 설정값 수정
disable = yes
Step 3) 설정 적용 및 서비스 재시작
# systemctl restart xinetd
Step 4) SSH 서비스 실행
# systemctl start sshd
```

**AIX**:
```bash
Step 1) /etc/inetd.conf 파일 내 Telnet 서비스 활성화 여부 확인
Step 2) 해당 옵션이 허용된 경우 설정 제거
예시 ) telnet stream tcp6  nowait root  /usr/sbin/telnetd   telnetd –a 주석 처리 혹은 명령어 줄 삭제
Step 3) inetd 설정 적용
# refresh –s inetd
Step 4) SSH 서비스 실행
# startsrc -s sshd
l HP-UX
Step 1) /etc/inetd.conf 파일 내 Telnet 서비스 활성화 여부 확인
# cat /etc/inetd.conf | grep telnet
Step 2) 해당 옵션이 허용된 경우 설정 제거
# telnet stream tcp6  nowait root  /usr/sbin/telnetd   telnetd –a 주석 처리 혹은 명령어 줄 삭제
Step 3) inetd 설정 적용
# inetd –c
Step 4) SSH 서비스 실행
# /sbin/init.d/secsh start
```

**HP-UX**:
```bash
Step 1) /etc/inetd.conf 파일 내 Telnet 서비스 활성화 여부 확인
# cat /etc/inetd.conf | grep telnet
Step 2) 해당 옵션이 허용된 경우 설정 제거
# telnet stream tcp6  nowait root  /usr/sbin/telnetd   telnetd –a 주석 처리 혹은 명령어 줄 삭제
Step 3) inetd 설정 적용
# inetd –c
Step 4) SSH 서비스 실행
# /sbin/init.d/secsh start
```

### U-53 FTP 서비스 정보 노출 제한

> 점검ID: U-53 | 위험도: 하 | 카테고리: 서비스 관리

**점검내용**: FTP 서비스 정보 노출 여부 점검

**판단기준**:
- ✅ 양호: FTP 접속 배너에 노출되는 정보가 없는 경우
- ❌ 취약: FTP 접속 배너에 노출되는 정보가 있는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX
Step 1) 배너 설정 확인
# cat /etc/vsftpd.conf | grep ftpd_banner 또는
# cat /etc/vsftpd/vsftpd.conf | grep ftpd_banner
Step 2) 해당 옵션이 설정되지 않은 경우 주석 제거 및 옵션 설정
# ftpd_banner=< 변경할 배너
Step 3) vsFTP 서비스 재시작
# systemctl restart vsftpd
```

**AIX**:
```bash
Step 1) 메시지 카탈로그 파일 추출
# dspcat -g /usr/lib/nls/msg/en_US/ftpd.cat > /tmp/ftpd.msg
Step 2) 배너 설정 확인
# cat /tmp/ftpd.msg
“(%s) FTP server (%s) ready.”
Step 3) /tmp/ftpd.msg 파일 내 배너 설정 변경
“< 변경할 배너 >”
Step 4) ftpd.cat 파일 생성
# gencat /usr/lib/nls/msg/en_US/ftpd.cat /tmp/ftpd.msg
Step 1) 배너 설정 확인
# cat /etc/vsftpd.conf | grep ftpd_banner
Step 2) 해당 옵션이 설정되지 않은 경우 주석 제거 및 옵션 설정
ftpd_banner=< 변경할 배너
Step 3) vsFTP 서비스 PID 확인
# ps -ef | grep vsftp
Step 4) vsFTP 서비스 재시작
# kill -1 <PID>
```

**HP-UX**:
```bash
Step 1) FTP 설정 파일 경로 확인
# cat /etc/inetd.conf | grep ftp
Step 2) ftpaccess 설정 확인
# cat /etc/ftpd/ftpaccess
Wu-ftpd v2.4 미만 : suppresshostname, suppressversion, banner < 파일 경로      - 설정 확인
Wu-ftpd v2.4 이상 : greeting, banner < 파일 경로      - 설정 확인
Step 3) 배너 설정 확인
# cat < 기본 FTP 배너 설정 파일 경로
Step 4) /etc/inetd.conf 파일 설정값 변경
ftp stream tcp nowait root /usr/lbin/ftpd ftpd –a /etc/ftpd/ftpaccess
Step 5) 배너 파일 수정
vi 편집기를 이용하여 배너 파일을 열어 변경할 배너 작성
Step 6) /etc/ftpd/ftpaccess 파일의 suppresshostname, suppressversion, greeting 옵션 설정값 변경
Wu-ftpd v2.4 미만 : suppresshostname yes
suppressversion yes
banner < 경고 메시지가 작성된 파일 경로
Wu-ftpd v2.4 이상 : greeting terse
banner < 경고 메시지가 작성된 파일 경로
Step 7) inetd 설정 적용
# inetd –c
※ 해당 파일이 존재하지 않는 경우 “cp /usr/newconfig/etc/ftpd/examples/ftpaccess /etc/ftpd/ftpaccess”
명령으로 파일 생성
Step 1) 배너 설정 확인
# cat /etc/vsftpd.conf | grep ftpd_banner
Step 2) /etc/vsftpd.conf 파일의 ftpd_banner 설정값 변경
ftpd_banner=< 변경할 배너
Step 3) vsFTP 서비스 PID 확인
# ps -ef | grep vsftp
Step 4) vsFTP 서비스 재시작
# kill -1 <PID>
```

### U-54 암호화되지 않는 FTP 서비스 비활성화

> 점검ID: U-54 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: 암호화되지 않은 FTP 서비스 비활성화 여부 점검

**판단기준**:
- ✅ 양호: 암호화되지 않은 FTP 서비스가 비활성화된 경우
- ❌ 취약: 암호화되지 않은 FTP 서비스가 활성화된 경우


**점검방법**:
```bash
# FTP 서비스 활성화 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) FTP 서비스 활성화 여부 확인
# svcs -a | grep vsftpd
Step 2) FTP 서비스 비활성화
# svcadm disable vsftpd
Step 1) FTP 서비스 활성화 여부 확인
# svcs -a | grep proftpd
Step 2) FTP 서비스 비활성화
# svcadm disable proftpd
```

**LINUX**:
```bash
Step 1) /etc/inetd.conf 파일 내 FTP 서비스 활성화 여부 확인
Step 2) /etc/inetd.conf 파일의 설정값 변경 ( 주석 처리 )
# ftp stream tcp nowait root /usr/sbin/tcpd /usr/sbin/in.ftpd
Step 3) inetd 서비스 재시작
# service inetd restart
Step 1) /etc/xinetd.d/ftp 파일 내 FTP 서비스 활성화 여부 확인
service ftp 단락 확인
Step 2) /etc/xinetd.d/ftp 파일의 설정값 변경
service ftp{disable     = yes}
Step 3) 설정 적용 및 재시작
# systemctl restart xinetd
```

**AIX**:
```bash
, HP-UX
Step 1) /etc/inetd.conf 파일 내 FTP 서비스 활성화 여부 확인
# cat /etc/inetd.conf
Step 2) /etc/inetd.conf 파일의 설정값 변경 ( 주석 처리 )
# ftp stream tcp nowait root /usr/sbin/tcpd /usr/sbin/in.ftpd
Step 3) inetd 설정 적용
# refresh -s inetd
```

### U-55 FTP 계정 shell 제한

> 점검ID: U-55 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: FTP 기본 계정에 쉘 설정 여부 점검

**판단기준**:
- ✅ 양호: FTP 계정에 /bin/false(/sbin/nologin) 쉘이 부여된 경우
- ❌ 취약: FTP 계정에 /bin/false(/sbin/nologin) 쉘이 부여되어 있지 않은 경우


**점검방법**:
```bash
# ftp 계정의 일곱 번째 필드에 등록된 로그인 쉘 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) ftp 계정의 일곱 번째 필드에 등록된 로그인 쉘 확인
# cat /etc/passwd | grep ftp
예시 ) ftp:x:134:65534::/srv/ftp:/usr/sbin/nologin
Step 2) ftp 계정 로그인 쉘 변경
/etc/passwd 파일 직접 수정 : ftp:x:134:65534::/srv/ftp:/bin/false 또는 /sbin/nologin
usermod 명령어를 사용하여 수정
# usermod -s /bin/false < 계정
```

### U-56 FTP 서비스 접근 제어 설정

> 점검ID: U-56 | 위험도: 하 | 카테고리: 서비스 관리

**점검내용**: FTP 서비스에 비인가자의 접근 가능 여부 점검

**판단기준**:
- ✅ 양호: 특정 IP주소 또는 호스트에서만 FTP 서버에 접속할 수 있도록 접근 제어 설정을 적용한 경우
- ❌ 취약: FTP 서버에 접근 제어 설정을 적용하지 않은 경우


**점검방법**:
```bash
# ftpusers 파일 소유자 및 권한 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) ftpusers 파일 소유자 및 권한 확인
# ls -l /etc/ftpusers 또는 # ls -l /etc/ftpd/ftpusers
Step 2) 접근 제한 설정 확인
# cat /etc/ftpusers 또는 # cat /etc/ftpd/ftpusers
Step 3) 파일 소유자를 root 로 변경
# chown root /etc/ftpusers 또는 # chown root /etc/ftpd/ftpusers
Step 4) 파일 권한을 640 으로 변경
# chmod 640 /etc/ftpusers 또는 # chmod 640 /etc/ftpd/ftpusers
Step 5) /etc(/ftpd)/ftpusers 파일에 FTP 서비스에 접근을 차단할 사용자 설정
```

### U-57 Ftpusers 파일 설정

> 점검ID: U-57 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: FTP 서비스에 root 계정 접근 제한 설정 여부 점검

**판단기준**:
- ✅ 양호: root 계정 접속을 차단한 경우
- ❌ 취약: root 계정 접속을 허용한 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) root 계정 접근 제한 설정 확인
# cat /etc/ftpusers 또는 # cat /etc/ftpd/ftpusers
Step 2) /etc(/ftpd)/ftpusers 파일의 설정값 변경 (#root 주석 제거 )
```

### U-58 불필요한 SNMP 서비스 구동 점검

> 점검ID: U-58 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: SNMP 서비스 활성화 여부 점검

**판단기준**:
- ✅ 양호: SNMP 서비스를 사용하지 않는 경우
- ❌ 취약: SNMP 서비스를 사용하는 경우


**점검방법**:
```bash
# SNMP 서비스 활성화 여부 및 경로 확인
```

**조치방법**:


**SOLARIS**:
```bash
(5.9 이하 버전)
Step 1) SNMP 서비스 활성화 여부 및 경로 확인
# ps -ef | grep snmp
Step 2) 서비스 중지 및 이름 변경
# /etc/init.d/init.snmpdx stop
# mv /etc/rc3.d/S76snmpdx /etc/rc3.d/_S76snmpdx
※ rc*/_S**snmpdx 의  - 수치는 각각 다름
```

**LINUX**:
```bash
Step 1) SNMP 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep snmpd
Step 2) 불필요한 SNMP 서비스가 활성화 (loaded active running) 인 경우 서비스 중지 및 비활성화
# systemctl stop snmpd
# systemctl disable snmpd
```

**AIX**:
```bash
Step 1) SNMP 서비스 활성화 여부 확인
# lssrc -a | grep snmp
Step 2) 불필요한 SNMP 서비스가 활성화 (active) 중인 경우 서비스 중지
# stopsrc –s snmpd
Step 3) /etc/rc.tcpip 파일 내에 SNMP 설정값 주석 처리
# start /usr/sbin/snmpd $src_running
Step 4) 설정 적용
# /etc/rc.tcpip
l HP-UX
Step 1) SNMP 서비스 활성화 여부 확인
# ps -ef | grep snmp
Step 2) 불필요한 SNMP 서비스가 활성화 (active) 중인 경우 서비스 중지
# /sbin/init.d/snmpd stop
```

**HP-UX**:
```bash
Step 1) SNMP 서비스 활성화 여부 확인
# ps -ef | grep snmp
Step 2) 불필요한 SNMP 서비스가 활성화 (active) 중인 경우 서비스 중지
# /sbin/init.d/snmpd stop
```

### U-59 안전한 SNMP 버전 사용

> 점검ID: U-59 | 위험도: 상 | 카테고리: 서비스 관리

**점검내용**: 안전한 SNMP 버전 사용 여부 점검

**판단기준**:
- ✅ 양호: SNMP 서비스를 v3 이상으로 사용하는 경우
- ❌ 취약: SNMP 서비스를 v2 이하로 사용하는 경우


**점검방법**:
```bash
# SNMP v3 사용 여부 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) SNMP v3 사용 여부 확인
# snmpwalk -v3 -l authPriv -u < 사용자 이름      - -a < 사용자 인증 프로토콜      - -A < 사용자 인증 암호      - -x < 사
용자 암호화 프로토콜   - -X < 사용자 암호화 암호   - <SNMP 서버 IP 주소
(SHA 인증 프로토콜, AES 암호화 프로토콜 사용 예시 )
# snmpwalk -v3 -l authPriv -u myuser -a SHA -A myauthpass -x AES -X myprivpass 192.168.18.190
Step 2) 사용하지 않을 경우 snmp v3 사용자 생성
# net-snmp-create-v3-user -ro -A < 사용자 인증 암호      - -X < 사용자 암호화 암호      - -a < 사용자 인증 프로토
콜   - -x < 사용자 암호화 프로토콜   - < 사용자 이름
예시 ) # net-snmp-create-v3-user -ro -A myauthpass -X myprivpass -a SHA -x AES myuser
Step 3) /etc/snmp/snmpd.conf 파일 내의 SNMPv3 사용자 추가
# createUser < 사용자 이름      - < 사용자 인증 프로토콜      - < 사용자 인증 암호      - < 사용자 암호화 프로토콜
< 사용자 암호화 암호
SHA 인증 프로토콜, AES 암호화 프로토콜 사용 예시 )
# createUser myuser SHA myauthpass AES myprivpass
Step 4) SNMPv3 사용자 읽기 / 쓰기 권한 추가
< 읽기 / 쓰기 권한    - < 사용자 이름
# rouser myuser
Step 5) SNMP 서비스 실행
```

### U-60 SNMP Community String 복잡성 설정

> 점검ID: U-60 | 위험도: 중 | 카테고리: 서비스 관리

**점검내용**: SNMP Community String 복잡성 설정 여부 점검

**판단기준**:
- ✅ 양호: SNMP Community String 기본값인 “public”, “private”이 아닌 영문자, 숫자 포함 10자리 이상 또는 영문자, 숫자, 특수문자 포함 8자리 이상인 경우 ※ SNMP v3의 경우 별도 인증 기능을 사용하고, 해당 비밀번호가 복잡도를 만족하는 경우 양호
- ❌ 취약: 아래의 내용 중 하나라도 해당되는 경우 1. SNMP Community String 기본값인 “public”, “private”일 경우 2. 영문자, 숫자 포함 10자리 미만인 경우 3. 영문자, 숫자, 특수문자 포함 8자리 미만인 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
(9 이하 버전)
Step 1) /etc/snmp/conf/snmpd.conf 파일 내의 Community String 설정 값 수정
read-community < 변경 값
write-community < 변경 값
Step 2) SNMP 서비스 재시작
```

**LINUX**:
```bash
Step 1) /etc/snmp/snmpd.conf 파일 내의 Community String 설정 값 수정
com2sec notConfigUser default    < 변경 값
Step 2) 설정 적용 및 SNMP 서비스 재시작
# systemctl restart snmpd
Step 1) /etc/snmp/snmpd.conf 파일 내의 Community String 설정 값 수정
rocommunity < 변경 값     - default
rwcommunity < 변경 값     - default
Step 2) 설정 적용 및 SNMP 서비스 재시작
# systemctl restart snmpd
```

**AIX**:
```bash
Step 1) /etc/snmpdv3.conf 파일 내의 Community String 설정 값 수정
COMMUNITY < 새로운 Community String> < 새로운 Community String> noAuthNoPriv 0.0.0.0 0.0.0.0
Step 2) SNMP 서비스 중지 및 실행
# stopsrc -s snmpd
# startsrc -s snmpd
l HP-UX
Step 1) /etc/snmpd.conf 파일 내의 Community String 설정 값 수정
get-community-name : < 변경 값
set-community-name : < 변경 값
Step 2) SNMP 서비스 재시작
```

**HP-UX**:
```bash
Step 1) /etc/snmpd.conf 파일 내의 Community String 설정 값 수정
get-community-name : < 변경 값
set-community-name : < 변경 값
Step 2) SNMP 서비스 재시작
```


## 패치 관리

### U-61 SNMP Access Control 설정

> 점검ID: U-61 | 위험도: 상 | 카테고리: 패치 관리

**점검내용**: SNMP 접근 제어 설정 여부 점검

**판단기준**:
- ✅ 양호: SNMP 서비스에 접근 제어 설정이 되어 있는 경우
- ❌ 취약: SNMP 서비스에 접근 제어 설정이 되어 있지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/net-snmp/snmp/snmpd.conf 파일 내의 SNMP 접근 제어 설정
rocommunity <String 값      - < 허용할 네트워크 주소 추가
rwcommunity <String 값     - < 허용할 네트워크 주소 추가
Step 2) 설정 적용 및 SNMP 서비스 재시작
# svcadm restart net-snmp
```

**LINUX**:
```bash
Step 1) /etc/snmp/snmpd.conf 파일 내의 SNMP 접근 제어 설정
com2sec notConfigUser < 허용할 네트워크 주소 추가      - <String 값
Step 2) 설정 적용 및 SNMP 서비스 재시작
# systemctl restart snmpd
Step 1) /etc/snmp/snmpd.conf 파일 내의 SNMP 접근 제어 설정
rocommunity <String 값      - < 허용할 네트워크 주소 추가
rwcommunity <String 값     - < 허용할 네트워크 주소 추가
Step 2) 설정 적용 및 SNMP 서비스 재시작
# systemctl restart snmpd
```

**AIX**:
```bash
Step 1) /etc/snmpdv3.conf 파일 내의 SNMP 접근 제어 설정
COMMUNITY <String 값     -  <String 값     -  noAuthNoPriv < 허용할 네트워크 주소     - < 허용할 넷마스크 주소
Step 2) SNMP 서비스 중지 및 실행
# stopsrc –s snmpd
# startsrc –s snmpd
l HP-UX
Step 1) /etc/snmpd.conf 파일 내의 SNMP 접근 제어 설정
trap-dest : < 허용할 네트워크 주소 추가
Step 2) SNMP 서비스 재시작
```

**HP-UX**:
```bash
Step 1) /etc/snmpd.conf 파일 내의 SNMP 접근 제어 설정
trap-dest : < 허용할 네트워크 주소 추가
Step 2) SNMP 서비스 재시작
```

### U-62 로그인 시 경고 메시지 설정

> 점검ID: U-62 | 위험도: 하 | 카테고리: 패치 관리

**점검내용**: 서버 및 서비스에 로그온 시 불필요한 정보 차단 설정 및 불법적인 사용에 대한 경고 메시지 출력 여부 점검

**판단기준**:
- ✅ 양호: 서버 및 Telnet, FTP, SMTP, DNS 서비스에 로그온 시 경고 메시지가 설정된 경우
- ❌ 취약: 서버 및 Telnet, FTP, SMTP, DNS 서비스에 로그온 시 경고 메시지가 설정되어 있지 않은 경우


**점검방법**:
```bash
# /etc/motd 파일과 /etc/issue 파일 내에 로그온 시 경고 메시지 입력
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/motd 파일과 /etc/issue 파일 내에 로그온 시 경고 메시지 입력
Step 1) /etc/issue.net 파일 내에 로그온 시 경고 메시지 입력
Step 2) /etc/default/telnetd 파일 내에 배너 경고 메시지 수정
BANNER=< 로그온 시 경고 메시지
```

**LINUX**:
```bash
Step 1) /etc/motd, /etc/issue 파일 내에 경고 메시지 수정
Step 1) /etc/issue.net 파일 내에 로그온 경고 메시지 수정
```

**AIX**:
```bash
Step 1) /etc/motd, /etc/issue 파일 내에 설정된 서버 로그온 경고 메시지 수정
Step 1) /etc/security/login.cfg 파일 내에 설정된 경고 메시지 수정
default:
~~ ~~
이하 생략
herald=< 경고 메시지
```

**HP-UX**:
```bash
Step 1) /etc/motd, /etc/issue 파일 내에 설정된 로그온 경고 메시지 수정
Step 1) /etc/inetd.conf 파일 내에 설정된 경고 메시지 파일 경로 확인 및 수정
telnet stream tcp6 nowait root /usr/lbin/telnetd telnetd -b /etc/issue 또는 <Telnet 배너 설정 파일 경로
Step 2) <Telnet 배너 설정 파일 경로  - 파일 내에 설정된 경고 메시지 수정
( 일반적으로 /etc/issue 파일 사용 )
Step 3) inetd 설정 적용
# inetd –c
```


## 로그 관리

### U-63 sudo 명령어 접근 관리

> 점검ID: U-63 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: /etc/sudoers 파일 권한 적절성 여부 점검

**판단기준**:
- ✅ 양호: /etc/sudoers 파일 소유자가 root이고, 파일 권한이 640인 경우
- ❌ 취약: /etc/sudoers 파일 소유자가 root가 아니거나, 파일 권한이 640을 초과하는 경우


**점검방법**:
```bash
# /etc/sudoers 파일 소유자 및 권한 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX, AIX, HP-UX
Step 1) /etc/sudoers 파일 소유자 및 권한 확인
# ls -l /etc/sudoers
Step 2) /etc/sudoers 파일 소유자를 root, 권한 640 으로 변경
# chown root /etc/sudoers
# chmod 640 /etc/sudoer
**Step 3)** s
```

### U-64 주기적 보안 패치 및 벤더 권고사항 적용

> 점검ID: U-64 | 위험도: 상 | 카테고리: 로그 관리

**점검내용**: 시스템에서 최신 패치가 적용 여부 점검

**판단기준**:
- ✅ 양호: 패치 적용 정책을 수립하여 주기적으로 패치 관리를 하고 있으며, 패치 관련 내용을 확인하고 적용하였을 경우
- ❌ 취약: 패치 적용 정책을 수립하지 않고 주기적으로 패치 관리를 하지 않거나, 패치 관련 내용을 확인하지 않고 적용하지 않고 있는 경우


**점검방법**:
```bash
# IFO 에 ‘i’ 가 있는 곳에 설치된 패키지 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) IFO 에 ‘i’ 가 있는 곳에 설치된 패키지 확인
# pkg list -af entire | head -5 IFO
예시 ) NAME (PUBLISHER) VERSION IFO
entire 11.4-11.4.42.0.0.11.0 i-
entire 11.4-11.4.0.0.1.15.0 --
entire 0.5.11-0.175.3.1.0.5.3 --
entire 0.5.11-0.175.3.1.0.5.2 --
Step 2) 최신 패키지 확인
# pkg list -af entire@latest
예시 ) NAME (PUBLISHER) VERSION IFO
entire 11.4-11.4.42.0.0.11.0 i-
Step 3) OS 버전으로 업데이트 후 재부팅
# pkg update --accept
Step 1) IFO 에 ‘i’ 가 있는 곳에 설치된 패키지 확인
# pkg list -af entire | head -5
예시 ) NAME (PUBLISHER) VERSION IFO
entire 11.4-11.4.42.0.0.11.0 i-
entire 11.4-11.4.0.0.1.15.0 --
entire 0.5.11-0.175.3.1.0.5.3 --
entire 0.5.11-0.175.3.1.0.5.2 --
Step 2) 최신 패키지 확인
# pkg list -af entire@latest
예시 ) NAME (PUBLISHER) VERSION IFO
entire 11.4-11.4.42.0.0.11.0 i-
Step 3) 업데이트 프리뷰
# pkg update –nv entire@ 버전 이름
Step 4) 업데이트 후 재부팅
# pkg update —accept entire@ 버전 이름
※ Oracle support 있는지 구분하려면 pkg publisher 명령어를 사용하여 support 리포지토리 (repository) 가 있어야
https://pkg.oracle.com/solaris/support/
※ Oracle support 없으면 분기별로만 업데이트가 가능함
※ Oracle support 있다면 매달 업데이트 (SRU) 와 Critical Patch Updates 가 support 리포지토리에 담겨 있음
※ Critical Patch Updates 에 대하여 자세한 사항은 아래 링크 참고
https://docs.oracle.com/en/operating-systems/solaris/oracle-solaris/11.4/update-sys-add-sw/critical-patch-updat
e-packages.html
※ 자세한 Oracle support 내용은 아래 링크 참고
https://docs.oracle.com/en/operating-systems/solaris/oracle-solaris/11.4/update-sys-add-sw/accessing-support-u
pdates.html
```

**LINUX**:
```bash
Step 1) OS 및 커널 버전 확인
# hostnamectl
Step 2) EOL 상태가 아닌 Linux OS 버전으로 업데이트
Step 3) 최신 보안 패치가 적용된 Kernel 버전으로 업데이트
```

**AIX**:
```bash
Step 1) 설치된 OS 또는 버전 확인
# oslevel -s
Step 2) 서버에 적용되어 있는 패치 리스트 확인
# instfix -i | grep ML
# instfix -i | grep SP
Step 3) 아래 사이트에 접속하여 최신 패치를 찾아 업데이트
https://www.ibm.com/support/fixcentral
Step 4) 최신 패치를 다운로드 받은 후 OS 패치 설치 진행
# smitty installp
Step 5) Install Software 선택 후 INPUT device / directory for software 항목에 패치 파일 경로 입력
Step 6) SOFTWARE to install 항목에서 all-latest 선택
Step 7) ACCEPT new license agreements 항목을 yes 로 설정 후 설치 진행
※ 패치 진행 중 문제가 발생한 경우, Apply 설치만 기본 버전으로 재설정 가능
※ Apply, Commit 된 패키지 확인은 lslpp -l 명령어로 확인 가능
Step 1) 설치된 OS 또는 버전 확인
# oslevel -s
Step 2) 서버에 적용되어 있는 패치 리스트 확인
# instfix -i | grep ML
# instfix -i | grep SP
Step 3) OS 패치 롤백 진행
# smitty install_reject
Step 4) SOFTWARE name 항목에서 Apply 설치된 OS Patch 선택
Preview 항목 Yes 로 설정
Step 5) 소프트웨어 제거에 문제가 없는지 확인 후 진행
l HP-UX
```

**HP-UX**:
```bash
Step 1) 서버에 적용된 패치 리스트 확인
# swlist –l product
Step 2) 아래 사이트에 접속 후 패치를 찾아 업데이트
https://support.hpe.com/hpsc/patch/content?action=home
Step 3) patch 파일을 /tmp 디렉터리 내 저장
예시 ) /tmp/patch_10
Step 4) HP-UX 에서 shell archive 를 품
# sh patch_10
- patch_10.depot, patch_10.text 가 생성됨
Step 5) patch_10.depot 설치
# swinstall -s /tmp/patch_10.depot ( 절대경로 입력 )
# swinstall -x autoreboot=true -x patch_match_target=true \ -s /tmp/patch_10.depot
```

### U-65 NTP 및 시각 동기화 설정

> 점검ID: U-65 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: NTP 및 시각 동기화 설정 여부 점검

**판단기준**:
- ✅ 양호: NTP 및 시각 동기화 설정이 기준에 따라 적용된 경우
- ❌ 취약: NTP 및 시각 동기화 설정이 기준에 따라 적용되어 있지 않은 경우


**점검방법**:
```bash
# 동기화된 NTP 서버 확인
```

**조치방법**:


**SOLARIS**:
```bash
, AIX, HP-UX
Step 1) 동기화된 NTP 서버 확인
# ntpq -pn
예시 ) <IP 주소 1> <IP 주소 2>  3 u  67  64  12   3.11 -425167 7877.17
Step 2) /etc/ntp.conf 파일 내의 NTP 설정값 수정 ( 필요시 기존 서버 제거 후 새로운 NTP 서버 추가 )
server <NTP 서버
Step 3) NTP 서비스 재시작
```

**LINUX**:
```bash
Step 1) NTP 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep ntp
Step 2) 동기화된 NTP 서버 확인
# ntpq -pn
예시 ) *<IP 주소 1>   133.243.238.244 2 u  53  64 377  5.730  +2.025  8.323
+<IP 주소 2> <IP 주소 3>  3 u  49  64 377  5.838 -16.050 16.484
-<IP 주소 4>  <IP 주소 5>   2 u  2  64 377 187.934  -8.059 81.846
( 이하 생략 )
Step 3) /etc/ntp.conf 파일 내에 NTP 서버 추가
server <NTP 서버
Step 4) 설정 적용 및 재시작
# systemctl restart ntp
※ Redhat 계열 리눅스는 RHEL 8 버전부터 Chrony 서비스로 변경
Step 1) Chrony 서비스 활성화 여부 확인
# systemctl list-units --type=service | grep chrony
Step 2) 동기화된 Chrony 서버 확인
# chronyc sources
예시 ) ^- <IP 주소   -     3 6 37  4 -135us[ +209us] +/- 56ms
^- <IP 주소     -     3 6 37  5 +841us[+1184us] +/- 57ms
( 이하 생략 )
Step 3) /etc/chrony.conf 파일 내에 NTP 서버 추가
server <NTP 서버
Step 4) 설정 적용 및 재시작
# systemctl restart chrony
```

### U-66 정책에 따른 시스템 로깅 설정

> 점검ID: U-66 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: 내부 정책에 따른 시스템 로깅 설정 여부 점검

**판단기준**:
- ✅ 양호: 로그 기록 정책이 보안 정책에 따라 설정되어 수립되어 있으며, 로그를 남기고 있는 경우
- ❌ 취약: 로그 기록 정책 미수립 또는 정책에 따라 설정되어 있지 않거나, 로그를 남기고 있지 않은 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
Step 1) /etc/syslog.conf 파일 내에 설정된 로그 기록 정책 수정
|로그|로그 파일 경로|
|---|---|
|mail.debug|/var/log/mail.log|
|*.info|/var/log/syslog.log|
|*.alert|/var/log/syslog.log|
|*.alert|/dev/console|
|*.alert|root|
|*.emerg|*|
Step 2) 설정 적용 및 재시작
# svcadm refresh svc:/system/system-log:default
Step 1) /etc/rsyslog.conf 파일 내에 설정된 로그 기록 정책 수정
|로그|로그 파일 경로|
|---|---|
|*.info;mail.none;authpriv.none;cron.none|/var/log/messages|
|authpriv.*|/var/log/auth.log|
|mail.*|/var/log/mail.log|
|cron.*|/var/log/cron.log|
|alert.*|/dev/console|
|emerg.*|*|
Step 2) 설정 적용 및 재시작
# svcadm resfresh svc:/system/system-log:rsyslog
```

**LINUX**:
```bash
Step 1) /etc/rsyslog.conf 또는 /etc/rsyslog.d/default.conf 파일 내에 설정된 로그 기록 정책 수정
|로그|로그 파일 경로|
|---|---|
|*.info;mail.none;authpriv.none;cron.none|/var/log/messages|
|auth,authpriv.*|/var/log/secure|
|mail.*|/var/log/maillog|
|cron.*|/var/log/cron|
|*.alert|/dev/console|
|*.emerg|*|
Step 2) 설정 적용 및 재시작
# systemctl restart rsyslog
```

**AIX**:
```bash
Step 1) /etc/syslog.conf 파일 내에 설정된 로그 기록 정책 수정
|로그|로그 파일 경로|
|---|---|
|*.emerg|*|
|*.alert|/dev/console|
|*.alert|/var/adm/alert.log|
|*.err|/var/adm/error.log|
|mail.info|/var/adm/mail.log|
|auth.info|/var/adm/auth.log|
|daemon.info|/var/adm/daemon.log|
|*.emerg;*.alert;*.crit;*.err;*.warning;*.notice;*.info|/var/adm/messages|
Step 2) 설정 적용
# refresh -s syslogd
l HP-UX
Step 1) /etc/syslog.conf 파일 내에 설정된 로그 기록 정책 수정
|로그|로그 파일 경로|
|---|---|
|*.emerg|*|
|*.alert|/dev/console|
|*.alert|root|
|*.err|/var/adm/syslog/error.log|
|mail.info|/var/adm/syslog/mail.log|
|auth.info|/var/adm/syslog/auth.log|
|*.emerg;*.alert;*.crit;*.err;*.warning;*.notice;*.info|/var/adm/syslog/syslog.log|
Step 2) SYSLOG 데몬 재시작
# kill -1 <PID>
|구분|왼쪽 필드|오른쪽 필드|
|---|---|---|
|형식|A, B|C|
|예시|mail.debug;cron.crit;auth.info|/var/log/syslog.log|
|설명|A 서비스 데몬의 B 로그 레벨 이상|A 서비스 데몬의 B 로그 레벨 이상|
/var/log/syslog.log : 해당 파일에 로그를 기록
/dev/console : 모니터 화면과 같은 지정된 콘솔로 메시지 출력
user : 지정된 사용자의 화면에 메시지 출력
- : 현재 로그인되어 있는 모든 사용자의 화면에 메시지 출력
@192.168.0.1 : 지정된 호스트로 로그 전송
**서비스 데몬 종류**
|메시지|설명|
|---|---|
|auth|로그인 등의 인증 프로그램 유형에서 발행된 메시지|
|authpriv|개인 인증을 요구하는 프로그램 유형에서 발행된 메시지|
|cron|cron, at 데몬에서 발행된 메시지|
|daemon|Telnet, FTP 등 데몬에서 발행한 메시지|
|kern|커널에서 발행된 메시지|
|lpr|프린터 유형의 프로그램에서 발행된 메시지|
|mail|메일 시스템에서 발행된 메시지|
|news|유즈넷 뉴스 프로그램에서 발행된 메시지|
|syslog|syslog 프로그램 유형에서 발행된 메시지|
|user|사용자 프로세스 관련 메시지|
|uucp|시스템에서 발행된 메시지|
|local0|여분으로 남겨둔 유형|
**메시지 우선 순위**
|등급|메시지|설명|
|---|---|---|
|4 (높음)|Emergency[emerg]|매우 위험한 상황|
|3|Alert[alert]|즉각적인 조치를 해야 하는 상황|
|2|Critical[crit]|하드웨어 등의 심각한 오류가 발생한 상황|
|1|Error[err]|에러 발생 시|
|0|Warning[warning]|주의를 요구하는 메시지|
|-1|Notice[notice]|에러가 아닌 알림에 관한 메시지|
|-2|Information[info]|단순한 프로그램에 대한 정보 메시지|
|-3 (낮음)|Debug[Dedug]|프로그램 실행 오류 발생 시|
```

**HP-UX**:
```bash
Step 1) /etc/syslog.conf 파일 내에 설정된 로그 기록 정책 수정
|로그|로그 파일 경로|
|---|---|
|*.emerg|*|
|*.alert|/dev/console|
|*.alert|root|
|*.err|/var/adm/syslog/error.log|
|mail.info|/var/adm/syslog/mail.log|
|auth.info|/var/adm/syslog/auth.log|
|*.emerg;*.alert;*.crit;*.err;*.warning;*.notice;*.info|/var/adm/syslog/syslog.log|
Step 2) SYSLOG 데몬 재시작
# kill -1 <PID>
|구분|왼쪽 필드|오른쪽 필드|
|---|---|---|
|형식|A, B|C|
|예시|mail.debug;cron.crit;auth.info|/var/log/syslog.log|
|설명|A 서비스 데몬의 B 로그 레벨 이상|A 서비스 데몬의 B 로그 레벨 이상|
/var/log/syslog.log : 해당 파일에 로그를 기록
/dev/console : 모니터 화면과 같은 지정된 콘솔로 메시지 출력
user : 지정된 사용자의 화면에 메시지 출력
- : 현재 로그인되어 있는 모든 사용자의 화면에 메시지 출력
@192.168.0.1 : 지정된 호스트로 로그 전송
**서비스 데몬 종류**
|메시지|설명|
|---|---|
|auth|로그인 등의 인증 프로그램 유형에서 발행된 메시지|
|authpriv|개인 인증을 요구하는 프로그램 유형에서 발행된 메시지|
|cron|cron, at 데몬에서 발행된 메시지|
|daemon|Telnet, FTP 등 데몬에서 발행한 메시지|
|kern|커널에서 발행된 메시지|
|lpr|프린터 유형의 프로그램에서 발행된 메시지|
|mail|메일 시스템에서 발행된 메시지|
|news|유즈넷 뉴스 프로그램에서 발행된 메시지|
|syslog|syslog 프로그램 유형에서 발행된 메시지|
|user|사용자 프로세스 관련 메시지|
|uucp|시스템에서 발행된 메시지|
|local0|여분으로 남겨둔 유형|
**메시지 우선 순위**
|등급|메시지|설명|
|---|---|---|
|4 (높음)|Emergency[emerg]|매우 위험한 상황|
|3|Alert[alert]|즉각적인 조치를 해야 하는 상황|
|2|Critical[crit]|하드웨어 등의 심각한 오류가 발생한 상황|
|1|Error[err]|에러 발생 시|
|0|Warning[warning]|주의를 요구하는 메시지|
|-1|Notice[notice]|에러가 아닌 알림에 관한 메시지|
|-2|Information[info]|단순한 프로그램에 대한 정보 메시지|
|-3 (낮음)|Debug[Dedug]|프로그램 실행 오류 발생 시|
```

### U-67 로그 디렉터리 소유자 및 권한 설정

> 점검ID: U-67 | 위험도: 중 | 카테고리: 로그 관리

**점검내용**: 로그에 대한 접근 통제 및 관리 여부 점검

**판단기준**:
- ✅ 양호: 디렉터리 내 로그 파일의 소유자가 root이고, 권한이 644 이하인 경우
- ❌ 취약: 디렉터리 내 로그 파일의 소유자가 root가 아니거나, 권한이 644를 초과하는 경우


**점검방법**:
```bash
# 설정 파일 내용 확인
```

**조치방법**:


**SOLARIS**:
```bash
, LINUX
Step 1) /var/log/ 디렉터리 내 로그 파일의 소유자 및 권한 변경
# chown root /var/log/< 파일 이름
# chmod 644 /var/log/< 파일 이름
```

**AIX**:
```bash
Step 1) /var/adm/ 디렉터리 내 로그 파일의 소유자 및 권한 변경
# chown root /var/adm/< 파일 이름
# chmod 644 /var/adm/< 파일 이름
l HP-UX
Step 1) /var/adm/syslog/ 디렉터리 내 로그 파일의 소유자 및 권한 변경
# chown root /var/adm/syslog/< 파일 이름
# chmod 644 /var/adm/syslog/< 파일 이름
