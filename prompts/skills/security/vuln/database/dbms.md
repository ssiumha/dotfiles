# DBMS 취약점 점검항목

> 출처: KISA 주요정보통신기반시설 기술적 취약점 분석평가 방법 상세가이드 (2026)
> 총 항목: 26개 (D-01 ~ D-26)

---

## 1. 계정 관리

### D-01 기본 계정의 비밀번호, 정책 등을 변경하여 사용

> 점검ID: D-01 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: DBMS 기본 계정의 초기 비밀번호 및 권한 정책을 변경하여 사용하는지 점검

**판단기준**:
- ✅ 양호: 기본 계정의 초기 비밀번호를 변경하거나 잠금설정한 경우
- ❌ 취약: 기본 계정의 초기 비밀번호를 변경하지 않거나 잠금설정을 하지 않은 경우

**점검방법**:

**Oracle DB**
```sql
-- 기본 계정 사용 여부 및 정책 확인
SQL> SELECT USERNAME, ACCOUNT_STATUS, PROFILE FROM DBA_USERS;

-- 비밀번호 변경
SQL> ALTER USER <기본 계정명> IDENTIFIED BY <신규 비밀번호>;

-- 계정 잠금 설정
SQL> SELECT username, account_status, lock_date, expiry_date, profile FROM dba_users WHERE account_status ='OPEN';
SQL> ALTER USER <기본 계정명> ACCOUNT LOCK;
```

**MSSQL**
```sql
-- sa 계정 비밀번호 변경
ALTER LOGIN sa WITH PASSWORD = '신규 비밀번호';
```

**MySQL**
```sql
-- root 계정 비밀번호 변경 (MySQL 5.7)
mysql> UPDATE user SET authentication_string = PASSWORD('신규 비밀번호') WHERE User = 'root';
mysql> flush privileges;

-- root 계정 비밀번호 변경 (MySQL 8.0)
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '신규 비밀번호';
mysql> flush privileges;
```

**Altibase**
```sql
-- 비밀번호 정책 확인
SELECT * FROM system_.sys_users_;

-- ALTER USER 명령어로 비밀번호 변경
ALTER USER sys IDENTIFIED BY [신규 비밀번호];
```

**Tibero**
```sql
-- sys 계정 비밀번호 변경
ALTER USER sys IDENTIFIED BY [신규 비밀번호];
```

**PostgreSQL**
```bash
$ sudo –u postgres psql
# ALTER USER postgres WITH PASSWORD '신규 비밀번호';
# \q
```

**Cubrid**
```sql
-- 사용자 계정 비밀번호 사용 여부 확인
csql> SELECT name, password FROM db_user;
csql> SELECT * FROM db_password;

-- 사용자 계정 비밀번호 변경
csql> ALTER USER "사용자 계정명" PASSWORD '신규 비밀번호';
```

**조치방법**:
- 기본(관리자) 계정의 초기 비밀번호 및 권한 정책 변경
- Oracle 기본 계정: scott/tiger, system/manager, sys/change_on_install, dbsnmp/dbsnmp 등
- 비밀번호는 영문, 숫자, 특수문자를 조합하여 8자 이상으로 설정

---

### D-02 데이터베이스의 불필요 계정을 제거하거나, 잠금설정 후 사용

> 점검ID: D-02 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: DBMS에 존재하는 계정 중 DB 관리나 운용에 사용하지 않는 불필요한 계정이 존재하는지 점검

**판단기준**:
- ✅ 양호: 계정 정보를 확인하여 불필요한 계정이 없는 경우
- ❌ 취약: 인가되지 않은 계정, 퇴직자 계정, 테스트 계정 등 불필요한 계정이 존재하는 경우

**점검방법**:

**Oracle DB**
```sql
-- 불필요한 계정 및 Object 삭제
SQL> DROP USER [삭제할 계정];
```

**MSSQL**
```sql
-- 불필요한 계정 삭제
EXEC sp_droplogin '삭제할 계정';
```

**MySQL**
```sql
-- 불필요한 계정 삭제
DROP USER '삭제할 계정'@'호스트명 or IP';
FLUSH PRIVILEGES;
```

**Altibase**
```sql
-- 모든 사용자 확인
SELECT * FROM system_.sys_users_;

-- 불필요한 계정 삭제
DROP USER user_name CASCADE;
```

**Tibero**
```sql
-- 모든 사용자 확인
SELECT * FROM all_users;
SELECT * FROM dba_users;
SELECT * FROM user_users;

-- 불필요한 계정 삭제
DROP USER user_name CASCADE;
```

**PostgreSQL**
```sql
-- 모든 사용자 확인
SELECT * FROM system_.sys_users_;
-- 또는 명령어: \du

-- 불필요한 계정 삭제
DROP ROLE '삭제할 계정';
```

**Cubrid**
```sql
-- 사용자 계정 목록 확인
csql> SELECT name, password FROM db_user;

-- 불필요한 계정 삭제
csql> DROP USER [삭제할 계정];
```

**조치방법**:
- 계정별 용도를 파악한 후 불필요한 계정 삭제
- Demonstration 계정(SCOTT, PM, ADAMS, CLARK 등) 제거
- 퇴사자 및 직무 변경으로 더 이상 사용하지 않는 계정 제거

---

### D-03 비밀번호 사용 기간 및 복잡도를 기관의 정책에 맞도록 설정

> 점검ID: D-03 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 기관 정책에 맞게 비밀번호 사용 기간 및 복잡도 설정이 적용되어 있는지 점검

**판단기준**:
- ✅ 양호: 기관 정책에 맞게 비밀번호 사용 기간 및 복잡도 설정이 적용된 경우
- ❌ 취약: 기관 정책에 맞게 비밀번호 사용 기간 및 복잡도 설정이 적용되지 않은 경우

**점검방법**:

**Oracle DB**
```sql
-- PASSWORD_LIFE_TIME Profile 파라미터 변경
SQL> ALTER PROFILE <프로파일명> LIMIT PASSWORD_LIFE_TIME xx;

-- Profile 값과 관련된 사용자 변경
SQL> ALTER PROFILE <계정명> PROFILE <변경할 프로파일명>;

-- 비밀번호 정책 설정 변경
SQL> ALTER PROFILE <프로파일명> LIMIT
FAILED_LOGIN_ATTEMPTS 3
PASSWORD_LIFE_TIME 30
PASSWORD_REUSE_TIME 30
PASSWORD_VERIFY_FUNCTION verify_function
PASSWORD_GRACE_TIME 5;
```

**MSSQL**
```
보안 → 로그인 → 각 로그인 계정 → 속성 → "암호 만료 강제 적용" 설정
[관리 도구] > [로컬 보안 정책] > [보안 설정] > [계정 정책] > [암호 정책] > 최대 암호 사용 기간: '60일' 설정
```

**MySQL**
```sql
-- 비밀번호 정책 확인
mysql> SHOW VARIABLES LIKE 'validate_password%';

-- 비밀번호 정책 설정
SET GLOBAL validate_password.policy = 'MEDIUM';
SET GLOBAL validate_password.length = 8;
SET GLOBAL validate_password.mixed_case_count = 1;
SET GLOBAL validate_password.number_count = 1;
SET GLOBAL validate_password.special_char_count = 1;

-- 비밀번호 LifeTime 설정
mysql> SHOW VARIABLES LIKE 'default_password_lifetime';
mysql> SET GLOBAL default_password_lifetime=90;
mysql> ALTER USER <계정명>'@'<호스트명 or IP>' PASSWORD EXPIRE INTERVAL 91 DAY;
```

**Altibase**
```sql
-- 비밀번호 정책 확인
SELECT * FROM system_.sys_users_;

-- 비밀번호 정책 설정
ALTER USER [계정명] LIMIT (Property 숫자);
-- 예: ALTER USER TESTUSER LIMIT (FAILED_LOGIN_ATTEMPTS 7, PASSWORD_LOCK_TIME 7);
```

**Tibero**
```sql
-- 사용자별 비밀번호 PROFILE 적용 여부 확인
SELECT * FROM dba_users;

-- PROFILE 설정 내용 확인
SELECT * FROM dba_profiles;

-- PROFILE 생성
CREATE PROFILE prof LIMIT
failed_login_attempts 3
password_lock_time 1/1440
password_life_time 90
password_reuse_time unlimited
password_reuse_max 10
password_grace_time 10
password_verify_function verify_function;
```

**조치방법**:
- 기관 정책에 맞게 비밀번호 사용 기간 및 복잡도 정책 설정
- 영문, 숫자, 특수문자 조합 8자 이상
- 주기적인 비밀번호 변경 필요

---

### D-04 데이터베이스 관리자 권한을 꼭 필요한 계정 및 그룹에 대해서만 허용

> 점검ID: D-04 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 관리자 권한이 필요한 계정 및 그룹에만 관리자 권한을 부여하였는지 점검

**판단기준**:
- ✅ 양호: 관리자 권한이 필요한 계정 및 그룹에만 관리자 권한이 부여된 경우
- ❌ 취약: 관리자 권한이 필요 없는 계정 및 그룹에 관리자 권한이 부여된 경우

**점검방법**:

**Oracle DB**
```sql
-- SYSDBA 권한 점검
SQL> SELECT username FROM v$pwfile_users WHERE username NOT IN (SELECT grantee FROM dba_role_privs WHERE granted_role='DBA') AND username != 'INTERNAL' AND SYSDBA = 'TRUE';

-- Admin에 부적합 계정 존재 여부 점검
SQL> SELECT grantee, privilege FROM dba_sys_privs WHERE grantee NOT IN ('SYS', 'SYSTEM', 'AQ_ADMINISTRATOR_ROLE', 'DBA', 'DSYS', 'BACSYS', 'SCHEDULER_ADMIN', 'MSYS') AND admin_option= 'YES' AND grantee NOT IN (SELECT grantee FROM dba_role_privs WHERE granted_role='DBA');

-- 관리자 권한 제거
SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE = '계정명';
REVOKE <권한> FROM <계정명>;

-- 필요한 테이블별 권한 부여
GRANT <권한> ON <테이블명> TO <계정명>;

-- Role을 통한 권한 부여
GRANT <Role_name> TO <계정명>;
```

**MSSQL**
```sql
-- sysadmin 서버 역할의 계정 목록 확인 후 불필요한 계정 삭제
EXEC sp_droprolemember 'user_name', 'sysadmin';
-- 예: EXEC sp_dropsrvrolemember 'user01', 'sysadmin';
```

**MySQL**
```sql
-- SUPER 권한(관리자 권한)이 부여되어 있는 계정 확인
SELECT GRANTEE FROM INFORMATION_SCHEMA.USER_PRIVILEGES WHERE PRIVILEGE_TYPE = 'SUPER';

-- 불필요한 SUPER 권한 회수
REVOKE SUPER ON *.* FROM '<계정명>';
FLUSH PRIVILEGES;

-- 필요한 권한만 제한적으로 부여
GRANT BINLOG_ADMIN, SYSTEM_VARIABLES_ADMIN ON *.* TO 'test'@'localhost';
REVOKE SUPER ON *.* FROM 'test'@'localhost';
FLUSH PRIVILEGES;
```

**Altibase**
```sql
-- 계정별 부여된 시스템 권한 목록 확인
SELECT grantee_id FROM system_.sys_grant_system_;
SELECT user_id, user_name FROM system_.sys_users_;
SELECT priv_id, priv_name FROM system_.sys_privileges_;
```

**Tibero**
```sql
-- 계정별 부여된 시스템 권한 목록 확인
SELECT * FROM dba_users;
SELECT * FROM dba_sys_privs;
```

**PostgreSQL**
```sql
-- 모든 사용자 확인
SELECT * FROM pg_user;
SELECT username, usesuper FROM pg_shadow;
-- 또는 명령어: \du

-- 불필요한 관리자 권한 회수
ALTER ROLE <계정명> NOSUPERUSER;
ALTER ROLE <계정명> NOCREATEROLE;
ALTER ROLE <계정명> NOCREATEDB;
ALTER ROLE <계정명> NOREPLICATION;
ALTER ROLE <계정명> NOBYPASSRLS;
```

**Cubrid**
```sql
-- DBA 권한을 가진 사용자 계정 확인
SELECT a.name FROM db_user a, table(direct_groups) AS t(roles) WHERE roles.name = 'DBA';

-- DBA 권한 회수
REVOKE ALL PRIVILEGES ON test FROM 'GRANT_TEST';
-- 또는 명시적으로 회수
REVOKE SELECT ON test FROM 'GRANT_TEST';
REVOKE INSERT ON test FROM 'GRANT_TEST';
-- ... 기타 권한

-- DBA 권한을 가진 불필요 계정 삭제
DROP USER 'GRANT_TEST';

-- 필요한 경우 적절한 권한으로 새 계정 생성
CREATE USER [계정명] PASSWORD '비밀번호' GROUPS [그룹명];
```

**조치방법**:
- 관리자 권한이 필요한 계정 및 그룹에만 관리자 권한 부여
- 일반 사용자는 필요한 최소 권한만 부여

---

### D-05 비밀번호 재사용에 대한 제약 설정

> 점검ID: D-05 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: 비밀번호 변경 시 이전 비밀번호를 재사용할 수 없도록 비밀번호 제약 설정이 되어있는지 점검

**판단기준**:
- ✅ 양호: 비밀번호 재사용 제한 설정을 적용한 경우
- ❌ 취약: 비밀번호 재사용 제한 설정을 적용하지 않은 경우

**점검방법**:

**Oracle DB**
```sql
-- SQL*Plus 설정 확인
-- Check for both reuse max and reuse time not set
SELECT profile FROM DBA_PROFILES WHERE (resource_name = 'PASSWORD_REUSE_MAX' AND limit IN ('UNLIMITED', 'NULL')) OR (profile IN (SELECT profile FROM DBA_PROFILES WHERE resource_name = 'PASSWORD_REUSE_TIME') AND limit IN ('UNLIMITED', 'NULL'));

-- Check for reuse max with value that is less than allowed minimum
SELECT profile FROM DBA_PROFILES WHERE resource_name = 'PASSWORD_REUSE_MAX' AND limit NOT IN ('UNLIMITED', 'NULL') AND REGEXP_LIKE(limit, '^[0-9]+$') AND TO_NUMBER(limit) < 10;

-- Check for reuse time that is less than allowed minimum
SELECT profile FROM DBA_PROFILES WHERE resource_name = 'PASSWORD_REUSE_TIME' AND limit NOT IN ('UNLIMITED', 'NULL') AND REGEXP_LIKE(limit, '^[0-9]+$') AND TO_NUMBER(limit) < 365;

-- PASSWORD_REUSE_TIME 및 PROFILE 파라미터 수정
SQL> ALTER PROFILE default LIMIT password_reuse_time 365 password_reuse_max 10;
SQL> ALTER PROFILE [프로파일명] LIMIT password_reuse_time DEFAULT password_reuse_max default;
```

**Altibase**
```sql
-- 비밀번호 정책 확인
SELECT * FROM system_.sys_users_;

-- 정책 적용
ALTER USER [계정명] LIMIT (Property 숫자);
-- 예: ALTER USER TESTUSER LIMIT (FAILED_LOGIN_ATTEMPTS 7, PASSWORD_LOCK_TIME 7);
```

**Tibero**
```sql
-- 사용자별 비밀번호 PROFILE 적용 여부 확인
SELECT * FROM dba_users;

-- PROFILE 생성
CREATE PROFILE prof LIMIT
failed_login_attempts 3
password_lock_time 1/1440
password_life_time 90
password_reuse_time unlimited
password_reuse_max 10
password_grace_time 10
password_verify_function verify_function;
```

**조치방법**:
- PASSWORD_REUSE_TIME, PASSWORD_REUSE_MAX 파라미터 설정
- 이전 비밀번호 재사용 방지

---

### D-06 DB 사용자 계정을 개별적으로 부여하여 사용

> 점검ID: D-06 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: DB 접근 시 사용자별로 서로 다른 계정을 사용하여 접근하는지 점검

**판단기준**:
- ✅ 양호: 사용자별 계정을 사용하고 있는 경우
- ❌ 취약: 공용 계정을 사용하고 있는 경우

**점검방법**:

**Oracle DB**
```sql
-- 계정 확인
SQL> SELECT username FROM dba_users ORDER BY username;

-- 공용 계정 삭제
SQL> DROP USER '공용 계정';

-- 사용자별, 응용 프로그램별 계정 생성
SQL> CREATE USER '<계정명>' IDENTIFIED BY '<비밀번호>';

-- 권한 부여
SQL> GRANT connect, resource TO [계정명];
```

**MSSQL**
```sql
-- 공용계정 삭제
EXEC sp_droplogin '공용 계정';

-- 사용자별, 응용 프로그램별 계정 생성
CREATE LOGIN '생성 계정' WITH PASSWORD = '비밀번호';
CREATE USER '생성 계정' FOR LOGIN '생성 계정' WITH DEFAULT_SCHEMA ='생성 계정';
ALTER USER '생성 계정';
EXEC sp_adduser '생성 계정', '생성 계정', 'db_owner';
EXEC sp_adduser '생성 계정', '생성 계정', '생성 계정';
EXEC sp_grantdbaccess '생성 계정', '생성 계정';
```

**MySQL**
```sql
-- 공용 계정 삭제
mysql> DROP USER <계정명>@<호스트명 or IP>

-- 사용자 계정 생성
mysql> create user '<계정명>'@'<호스트명 or IP>' identified by '비밀번호';

-- 권한 설정
mysql> grant select, insert on DB이름.테이블명 to '<계정명>'@'<호스트명 or IP>';
mysql> grant all privileges on DB이름.* to '<계정명>'@'<호스트명 or IP>';
mysql> flush privileges;
```

**Altibase**
```sql
-- DB에 생성된 계정 확인
SELECT * FROM system_.sys_users_;

-- 공용 계정 삭제
DROP USER <계정명> CASCADE;

-- 사용자별, 응용 프로그램별 계정 생성
CREATE USER <계정명> IDENTIFIED BY <비밀번호>;
```

**Tibero**
```sql
-- DB에 생성된 계정 확인
SELECT * FROM dba_users_;

-- 공용 계정 삭제
DROP USER [삭제할 계정] CASCADE;

-- 사용자별, 응용 프로그램별 계정 생성
CREATE USER [계정명] IDENTIFIED BY [비밀번호];
```

**PostgreSQL**
```sql
-- 모든 사용자 확인
SELECT * FROM pg_shadow;
-- 또는 명령어: \du

-- 불필요 계정 삭제
DROP ROLE '삭제할 계정';

-- 계정 생성 및 권한 추가
CREATE USER '생성할 계정';
ALTER ROLE '계정명' '권한명' '권한명' ····;
\du (계정 생성 및 권한 확인)
```

**조치방법**:
- 사용자별 계정 생성 및 권한 부여
- 공용 계정 사용 금지

---

### D-07 root 권한으로 서비스 구동 제한

> 점검ID: D-07 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: 서비스 구동 시 root 계정 또는 root 권한으로 구동되는지 점검

**판단기준**:
- ✅ 양호: DBMS가 root 계정 또는 root 권한이 아닌 별도의 계정 및 권한으로 구동되고 있는 경우
- ❌ 취약: DBMS가 root 계정 또는 root 권한으로 구동되고 있는 경우

**점검방법**:

**Oracle DB**
```bash
# 실행 중인 프로세스 확인
$ ps –ef | grep pmon

# Oracle Listener 프로세스 사용자 확인
$ ps –ef | grep tnslsnr

# 사용자 계정을 'Oracle'로 전환
$ su – oracle
$ lsnrctl stop
$ sqlplus / as sysdba
$ shutdown immediate

# Oracle 서비스 재시작
$ lsnrctl start
$ sqlplus / as sysdba
$ startup
```

**MySQL**
```bash
# 실행 중인 프로세스 확인
# ps –ef | grep mysqld

# mysql server configuration 파일 확인
# cat [mysql server configuration 파일 위치] | grep user

# mysql server configuration 파일 설정
# vi [mysql server configuration 파일 위치] (일반적으로 /etc/my.cnf.d/mysql-server.cnf)
# [mysqld] 그룹에 user = [mysqld를 구동할 시스템의 일반 사용자 계정] 추가
```

**Altibase**
```bash
# 실행 중인 프로세스 확인
# ps –ef | grep altibase | grep –v grep

# Altibase 디렉터리 및 파일을 Altibase 전용 계정으로 소유자 변경
# chown –R [계정명]:[그룹명] '[Altibase 디렉터리 위치]'

# Altibase 전용 계정으로 DB 구동
```

**Cubrid**
```bash
# 실행 중인 프로세스 확인
# ps –ef | egrep 'cub_master|cub_broker|cub_manager' | grep –v grep

# 삭제 후 cubrid 계정으로 재설치 또는 언로드/로드를 통해 기존 데이터 이관
```

**조치방법**:
- DBMS 구동 계정을 root가 아닌 별도 계정으로 변경
- 전용 서비스 계정 사용

---

### D-08 안전한 암호화 알고리즘 사용

> 점검ID: D-08 | 위험도: 상 | 카테고리: 계정관리

**점검내용**: 해시 알고리즘 SHA-256 이상의 암호화 알고리즘을 사용하는지 점검

**판단기준**:
- ✅ 양호: 해시 알고리즘 SHA-256 이상의 암호화 알고리즘을 사용하고 있는 경우
- ❌ 취약: 해시 알고리즘 SHA-256 미만의 암호화 알고리즘을 사용하고 있는 경우

**점검방법**:

**Oracle DB**
```sql
-- SQL*Plus 쿼리를 통한 암호화 알고리즘 확인
SELECT username, password_versions FROM dba_users;

-- sqlnet.ora 파일 수정
$ vi /u01/app/oracle/product/11.2.0/xe/network/admin/sqlnet.ora
SQLNET.ALLOWED_LOGON_VERSION_SERVER = 12
SQLNET.ALLOWED_LOGON_VERSION_CLIENT = 12

-- Oracle DB 알고리즘: 10G(MD5), 11G(SHA-1), 12C(SHA-512, AES)
```

**MSSQL**
```sql
-- 저장된 비밀번호 해시 값 확인
select name, password_hash from sys.sql_logins;

-- 일반 이용자 패스워드 해시 알고리즘 변경
USE <데이터베이스명>
GO
ALTER TABLE <테이블명> ADD <신규 해시 칼럼명> varbinary(256)
GO
UPDATE <테이블명> SET <신규 해시 칼럼명> = HASHBYTES('SHA2_256', <기존 해시 칼럼명>)
GO
ALTER TABLE <테이블명> DROP COLUMN <기존 해시 칼럼명>
GO
```

**MySQL**
```sql
-- 계정별 암호화 알고리즘 확인
-- MySQL 5.7
mysql> SELECT user, host, plugin FROM mysql.user;
mysql> SELECT host, user, plugin, password AS authentication_string FROM mysql.user;

-- MySQL 8.0
mysql> SELECT user, host, plugin FROM mysql.user;
mysql> SELECT host, user, plugin, authentication_string FROM mysql.user;

-- 비밀번호 및 암호화 알고리즘 설정
-- MySQL 5.7 (mysql_native_password 기본)
CREATE USER '계정명'@'host' IDENTIFIED BY '비밀번호';
ALTER USER '계정명'@'host' IDENTIFIED '신규 비밀번호';

-- MySQL 8.0 (caching_sha2_password(SHA-256) 기본)
mysql> CREATE USER '계정명'@'localhost' IDENTIFIED WITH caching_sha2_password BY '비밀번호';
mysql> ALTER USER '계정명'@'localhost' IDENTIFIED WITH caching_sha2_password BY '비밀번호';
```

**Tibero**
```sql
-- 암호화 알고리즘 확인
SELECT "TS#", "ENCRYPTIONALG", "ENCRYPTEDTS" FROM V$ENCRYPTED_TABLESPACES;

-- 암호화 알고리즘 적용
ALTER TABLESPACE "ENCRYPTED_TS" ENCRYPTION USING '적용할 암호화 알고리즘';
```

**PostgreSQL**
```sql
-- 계정별 암호화 알고리즘 확인
postgres=# SELECT usename, passwd FROM pg_shadow;

-- 알고리즘 적용 (default: SCRAM-SHA-256)
-- user 생성 시
postgres=# CREATE USER 계정명 password '설정할 비밀번호';

-- 기존 user 적용
postgres=# ALTER USER 계정명 WITH password '설정할 비밀번호';
```

**조치방법**:
- SHA-256 이상의 암호화 알고리즘 적용
- 각 DBMS별 안전한 알고리즘 설정

---

### D-09 일정 횟수의 로그인 실패 시 이에 대한 잠금정책 설정

> 점검ID: D-09 | 위험도: 중 | 카테고리: 계정관리

**점검내용**: DBMS 설정 중 일정 횟수의 로그인 실패 시 계정 잠금 정책에 대한 설정이 되어있는지 점검

**판단기준**:
- ✅ 양호: 로그인 시도 횟수를 제한하는 값을 설정한 경우
- ❌ 취약: 로그인 시도 횟수를 제한하는 값을 설정하지 않은 경우

**점검방법**:

**Oracle DB**
```sql
-- Failed_login_attempts Profile 파라미터 수정
SQL> ALTER PROFILE LIMIT FAILED_LOGIN_ATTEMPTS XX; (XX회 이하로 설정)

-- Profile 적용
SQL> connect / as sysdba
SQL> @$Ora_Home/rdbms/admin/utlpwdmg.

-- 또는 default profile에 unlimited로 설정
SQL> ALTER PROFILE DEFAULT LIMIT PASSWORD_LOCK_TIME UNLIMITED;
SQL> ALTER PROFILE [Profile명] LIMIT PASSWORD_LOCK_TIME XX;
```

**Altibase**
```sql
-- 정책 확인
SELECT * FROM system_.sys_users_;

-- 정책 적용
ALTER USER 계정명 LIMIT (Property 숫자);
-- 예: ALTER USER testuser LIMIT (FAILED_LOGIN_ATTEMPTS 7);
```

**Tibero**
```sql
-- 사용자별 비밀번호 PROFILE 적용 여부 확인
SELECT * FROM dba_users;

-- PROFILE 설정 내용 확인
SELECT * FROM dba_profiles;

-- PROFILE 생성
CREATE PROFILE prof LIMIT
FAILED_LOGIN_ATTEMPTS 3
PASSWORD_LOCK_TIME 1/1440
PASSWORD_LIFE_TIME 90
PASSWORD_REUSE_TIME UNLIMITED
PASSWORD_REUSE_MAX 10
PASSWORD_GRACE_TIME 10
PASSWORD_VERIFY_FUNCTION verify_function;
```

**조치방법**:
- 로그인 시도 횟수 제한 값 설정
- 자동 잠금 및 해제 정책 수립

---

## 2. 접근 관리

### D-10 원격에서 DB 서버로의 접속 제한

> 점검ID: D-10 | 위험도: 상 | 카테고리: 접근관리

**점검내용**: 지정된 IP주소만 DB 서버에 접근 가능하도록 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: DB 서버에 지정된 IP주소에서만 접근 가능하도록 제한한 경우
- ❌ 취약: DB 서버에 지정된 IP주소에서만 접근 가능하도록 제한하지 않은 경우

**점검방법**:

**Windows OS**
```
시작 → 제어판 → 시스템 및 보안 → Windows Defender 방화벽 → 고급 설정 → 인바운드 규칙
→ 원격 데스크톱 – 사용자 모드(TCP-In/UDP-In)
→ 속성 → 영역 → 원격 IP 주소 → 다음 IP 주소 → 추가 → IP 주소 입력
```

**Oracle DB**
```bash
# oracle 계정으로 로그인
su - oracle

# sqlnet.ora 파일 오픈 및 수정
vi $ORA_NET/sqlnet.ora

# sqlnet.ora 파일의 끝에 다음 추가
tcp.validnode_checking = yes
tcp.invited_nodes = (127.0.0.1, [allowed IP's])

# Listener 재시작
$ORACLE_HOME/bin/lsnrctl stop
$ORACLE_HOME/bin/lsnrctl start
```

**MySQL**
```sql
-- user 테이블 조회 및 접속 IP 변경
mysql> UPDATE user SET host = '<접속 IP>' WHERE user ='<계정명>' and host='%';
```

**Altibase**
```bash
# Altibase HDB Property 파일 수정
$Altibase_HOME/conf/altibase.properties의 IP Access Control Lists에서 내부 정책에 맞게 수정

# 접근 제어 설정 확인
iSQL> SELECT name, value1 FROM v$property WHERE name LIKE 'ACCESS_CONTROL_%';
```

**PostgreSQL**
```bash
# postgresql.conf 파일 설정
# listen_addresses 설정 (*, localhost, 특정 IP 등)

# pg_hba.conf 파일 설정
TYPE     DATABASE      USER      CIDR-ADDRESS      METHOD
host     (DB명)        (사용자)   (접속 허용 IP)     md5
```

**Tibero**
```bash
# $TB_SID.tip 파일 설정
LSNR_INVITED_IP=192.168.1.1;192.168.2.0/24;192.1.0.0/16

# 또는 파일로 관리
LSNR_INVITED_IP_FILE=절대경로

# 실시간 적용
ALTER SYSTEM LISTENER PARAMETER RELOAD;
```

**조치방법**:
- DB 서버에 대해 지정된 IP주소에서만 접근 가능하도록 설정
- 방화벽 및 DB 설정 파일에서 IP 제한 적용

---

### D-11 DBA 이외의 인가되지 않은 사용자가 시스템 테이블에 접근할 수 없도록 설정

> 점검ID: D-11 | 위험도: 상 | 카테고리: 접근관리

**점검내용**: 시스템 테이블에 일반 사용자 계정이 접근할 수 없도록 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: 시스템 테이블에 DBA만 접근 가능하도록 설정되어 있는 경우
- ❌ 취약: 시스템 테이블에 DBA 외 일반 사용자 계정이 접근 가능하도록 설정되어 있는 경우

**점검방법**:

**Oracle DB, Tibero**
```sql
-- DBA만 접근 가능한 테이블의 권한 확인
SQL> SELECT grantee, privilege, owner, table_name FROM dba_tab_privs WHERE (owner = 'SYS' or table_name LIKE 'DBA_%') AND privilege <> 'EXECUTE' AND grantee NOT IN ('PUBLIC', 'AQ_ADMINISTRATOR_ROLE', 'AQ_USER_ROLE', 'AURORA$JIS$UTILITY$', 'OSE$HTTP$ADMIN', 'TRACESVR', 'CTXSYS', 'DBA', 'DELETE_CATALOG_ROLE', 'EXECUTE_CATALOG_ROLE', 'EXP_FULL_DATABASE', 'GATHER_SYSTEM_STATISTICS', 'HS_ADMIN_ROLE', 'IMP_FULL_DATABASE', 'LOGSTDBY_ADMINISTRATOR', 'MDSYS', 'ODM', 'OEM_MONITOR', 'OLAPSYS', 'ORDSYS', 'OUTLN', 'RECOVERY_CATALOG_OWNER', 'SELECT_CATALOG_ROLE', 'SNMPAGENT', 'SYSTEM', 'WKSYS', 'WKUSER', 'WMSYS', 'WM_ADMIN_ROLE', 'XDB', 'LBACSYS', 'PERFSTAT', 'XDBADMIN') AND grantee NOT IN (SELECT grantee FROM dba_role_privs WHERE granted_role = 'DBA') ORDER BY grantee;

-- 불필요한 권한 회수
SQL> REVOKE <권한> ON <Object> FROM user;
```

**MSSQL**
```sql
-- system tables 접근 권한 제거
REVOKE <권한> ON <Object> FROM [계정명]|[PUBLIC]|[GUEST];

-- stored procedure 또는 information_schema views를 통해 접근
```

**MySQL**
```sql
-- 사용자 계정에 부여된 권한 확인
SHOW GRANTS FOR <계정명>;

-- 필요한 데이터베이스 및 테이블에만 권한 적용
GRANT <권한> privileges ON <DB명>.<테이블명> to '<계정명>'@'<호스트명 or IP>';
```

**Altibase**
```sql
-- sys_tables_ 조회하여 system_ 외 접근 계정 유무 확인
SELECT * FROM system_.sys_tables_;

-- 불필요 접근 권한 해제
```

**PostgreSQL**
```sql
-- 사용자 및 역할 권한 정보 조회
SELECT * FROM information_schema.role_table_grants;

-- 스키마의 Table에 대한 접근 권한 제거
REVOKE [all,select,insert,update...] ON all tables IN schema '스키마명' FROM '계정명';
```

**조치방법**:
- 시스템 테이블에 일반 사용자 계정이 접근할 수 없도록 설정
- DBA 계정만 시스템 테이블 접근 가능하도록 제한

---

### D-12 안전한 리스너 비밀번호 설정 및 사용

> 점검ID: D-12 | 위험도: 상 | 카테고리: 접근관리

**점검내용**: 오라클 데이터베이스 Listener의 비밀번호 설정 여부 점검

**판단기준**:
- ✅ 양호: Listener의 비밀번호가 설정된 경우
- ❌ 취약: Listener의 비밀번호가 설정되어 있지 않은 경우

**점검방법**:

**Oracle DB**
```bash
# Listener 비밀번호 설정
LSNRCTL> change_password
Old password: <Old Password>
New password: <New password>
Reenter new password: <New password>
Password change for LISTENER
The command completed successfully

LSNRCTL> set password
LSNRCTL> save_config

# Listener 매개변수 설정
# $TNS_ADMIN/listener.ora 파일에 추가
PASSWORDS_<listener_name> = <Encrypted Password>
ADMIN_RESTRICTIONS_<listener_name> = ON

# Listener 재시작 및 상태 확인
LSNRCTL> lsnrctl stop
LSNRCTL> lsnrctl start
LSNRCTL> lsnrctl reload
LSNRCTL> lsnrctl status

# Oracle 12c release 2 이후 버전은 Listener 비밀번호 설정을 지원하지 않음
```

**조치방법**:
- Listener 비밀번호 설정
- Oracle 12c R2 이후는 해당사항 없음

---

### D-13 불필요한 ODBC/OLE-DB 데이터 소스와 드라이브를 제거하여 사용

> 점검ID: D-13 | 위험도: 중 | 카테고리: 접근관리

**점검내용**: 사용하지 않는 불필요한 ODBC/OLE-DB가 설치되어 있는지 점검

**판단기준**:
- ✅ 양호: 불필요한 ODBC/OLE-DB가 설치되지 않은 경우
- ❌ 취약: 불필요한 ODBC/OLE-DB가 설치된 경우

**점검방법**:

**Windows NT/2000/2003/2008/2012/2016**
```
시작 → 설정 → 제어판 → 관리 도구 → 데이터 원본(ODBC) > 시스템 DSN
→ 사용하지 않는 데이터 소스 제거
```

**Windows 2019/2022**
```
시작 → 설정 → 제어판 → 시스템 및 보안 → 관리 도구
→ ODBC 데이터 원본 관리자(32비트/64비트) > 시스템 DSN
→ 해당 드라이브 클릭 → 사용하지 않는 데이터 소스 제거
```

**조치방법**:
- 불필요한 ODBC/OLE-DB 제거
- ODBC 데이터 소스 관리자 도구 사용

---

### D-14 데이터베이스의 주요 설정 파일, 비밀번호 파일 등과 같은 주요 파일들의 접근 권한이 적절하게 설정

> 점검ID: D-14 | 위험도: 중 | 카테고리: 접근관리

**점검내용**: 데이터베이스의 주요 파일들에 대해 관리자를 제외한 일반 사용자의 파일 수정 권한을 제거하였는지 점검

**판단기준**:
- ✅ 양호: 주요 설정 파일 및 디렉터리의 권한 설정 시 일반 사용자의 수정 권한을 제거한 경우
- ❌ 취약: 주요 설정 파일 및 디렉터리의 권한 설정 시 일반 사용자의 수정 권한을 제거하지 않은 경우

**점검방법**:

**Oracle DB (Unix OS)**
```bash
# 디렉터리 또는 파일의 권한 점검
$ORACLE_HOME/bin/oracle (755)
$ORACLE_HOME/bin/[sqlplus,sqlldr,sqlload,proc,oraenv,oerr,exp,imp,tkprof,tnsping,wrap] (755)
$ORACLE_HOME/bin/[svrmgrl, lsnrctl, dbsnmp] (750)
$ORACLE_HOME/network (755)
$ORACLE_HOME/network/admin/[listener.ora, sqlnet.ora 등] (755)
$ORACLE_HOME/lib (755)
$ORACLE_HOME/network/admin/[tnsnames.ora, protocol.ora, sqlpnet.ora] (644)
$ORACLE_HOME/dbs/init.ora (640)
$ORACLE_HOME/dbs/init<SID>.ora (640)

# 파일 권한 변경
# chmod <적용 권한> <파일명>

# redo 파일, 데이터베이스 설정 파일, 데이터 파일 위치 확인
SQL> Select value from v$parameter where name='spfile';
SQL> Select 'Control Files: '||value from v$parameter where name='control_files';
SQL> select 'Logfile: '||member from v$logfile;
SQL> select 'Datafile: '||name from v$datafile;
```

**Oracle DB (Windows OS)**
```
패스워드 파일(orapw<SID>) 접근 권한은 administrators, system group, owner group, oracle service account, DBA에게 모든 권한 또는 그 이하로 설정하고 다른 그룹은 제거
```

**MySQL (Unix OS)**
```bash
# 설정 파일(my.cnf, my.ini)의 접근 권한 설정
# 위치: /etc/my.cnf, <각 홈디렉터리>/my.cnf
# chmod 600 ./my.cnf
```

**MySQL (Windows OS)**
```
설정 파일의 접근 권한은 Administrators, SYSTEM, Owner에게 모든 권한 또는 그 이하로 설정하고 다른 그룹은 제거
```

**PostgreSQL (Unix OS)**
```bash
# 주요 설정 파일 권한 설정
# 환경설정 파일(postgresql.conf): 640 이하
# chmod 640 [$datadir]/postgresql.conf

# DB 접속 통제 설정 파일(pg_hba.conf, pg_ident.conf): 640 이하
# chmod 640 ./pg_hba.conf
# chmod 640 ./pg_ident.conf

# 히스토리 파일(.psql_history): 600 이하
# chmod 600 .psql_history

# Log 파일(pg_log): 640 이하
# chmod 640 [Log 파일]
```

**PostgreSQL (Windows OS)**
```
주요 환경설정 파일의 접근 권한은 Administrators, SYSTEM, Owner에게 모든 권한 또는 필요 권한만 부여하여 설정하고 기타 다른 그룹은 권한 제거
```

**Cubrid**
```bash
# cubrid.conf 파일 권한 확인
# ls –l $_CUBRID_DATABASES/conf/cubrid.conf

# cubrid.conf 파일 권한 설정 (600 또는 640)
# sudo chmod 640 /root/CUBRID-11.2.8.0824-bf70ab7-Linux.x86_64/conf/cubrid.conf
```

**조치방법**:
- 주요 설정 파일 및 디렉터리의 권한 설정 변경
- 일반 사용자의 수정 권한 제거

---

### D-15 관리자 이외의 사용자가 오라클 리스너의 접속을 통해 리스너 로그 및 trace 파일에 대한 변경 제한

> 점검ID: D-15 | 위험도: 하 | 카테고리: 접근관리

**점검내용**: Listener 관련 설정 파일의 접근 권한을 관리자만 가능하게 하고 Listener 파라미터의 변경 방지에 대한 옵션 설정 여부 점검

**판단기준**:
- ✅ 양호: Listener 관련 설정 파일에 대한 권한이 관리자로 설정되어 있으며, Listener로 파라미터를 변경할 수 없게 옵션이 설정된 경우
- ❌ 취약: Listener 관련 설정 파일에 대한 권한이 일반 사용자로 설정되어 있고, Listener로 파라미터를 변경할 수 없게 옵션이 설정되지 않은 경우

**점검방법**:

**Oracle DB**
```bash
# 파일 권한 확인
# $ORACLE_HOME/network/admin 디렉터리 권한 확인
# Unix: ls –a
# Windows: 파일 속성

LSNRCTL> status ListenerName

# listener.ora 파일에서 ADMIN_RESTRICTIONS_<listener name> = ON 설정 확인

# ADMIN_RESTRICTIONS_LISTENER 설정 추가
# listener.ora 파일에 ADMIN_RESTRICTIONS_<listener name>=ON 추가
# listener 재실행 또는 lsnrctl reload
```

**조치방법**:
- 주요 파일 및 로그 파일에 대한 권한을 관리자로 제한
- ADMIN_RESTRICTIONS 옵션 설정

---

### D-16 Windows 인증 모드 사용

> 점검ID: D-16 | 위험도: 하 | 카테고리: 접근관리

**점검내용**: DB 로그인 시 Windows 인증 모드 적절성 점검

**판단기준**:
- ✅ 양호: Windows 인증 모드를 사용하고 sa 계정이 비활성화되어 있는 경우, 또는 sa 계정 활성화 시 강력한 암호 정책을 설정한 경우
- ❌ 취약: 혼합 인증 모드를 사용하고, 활성화된 sa 계정에 대한 강력한 암호 정책 설정을 하지 않은 경우

**점검방법**:

**MSSQL**
```
SQL Server Management Studio > 해당 서버 우클릭 → 속성 → 보안 → 서버 인증
→ Windows 인증 모드(W)를 클릭하여 활성화
```

**조치방법**:
- Windows 인증 모드 사용
- kerberos 보안 프로토콜 활용

---

## 3. 옵션 관리

### D-17 Audit Table은 데이터베이스 관리자 계정으로 접근하도록 제한

> 점검ID: D-17 | 위험도: 하 | 카테고리: 옵션관리

**점검내용**: Audit Table 접근 권한이 관리자 계정으로 제한되고 있는지 점검

**판단기준**:
- ✅ 양호: Audit Table 접근 권한이 관리자 계정으로 설정한 경우
- ❌ 취약: Audit Table 접근 권한이 일반 계정으로 설정한 경우

**점검방법**:

**Oracle DB, Tibero**
```sql
-- 설정 확인
SQL> SELECT owner FROM dba_tables WHERE table_name = 'AUD$';

-- 불필요한 권한 삭제 (SYS 또는 SYSTEM 제외)
REVOKE <권한> ON <Object> FROM <계정명>;
```

**Altibase**
```sql
-- 사용자 계정 조회하여 SYSTEM_, SYS의 USER_ID 확인
SELECT * FROM system_.sys_users_;

-- 시스템 테이블 조회 내용 중 AUDIT 관련 테이블 정보의 TABLE_ID 확인
SELECT * FROM system_.sys_tables_;

-- 불필요한 권한 삭제
REVOKE <권한> ON [audit_table] FROM [계정명];
```

**Tibero**
```bash
# <$TB_SID.tip> 파일에 설정
AUDIT_TRAIL=DB_EXTENDED

# 또는
AUDIT_TRAIL=OS
AUDIT_FILE_DEST=/home/Tibero/audit/audit_trail.log
AUDIT_FILE_SIZE=10M

# 감사 기록 조회
SELECT * FROM dba_audit_trail;
SELECT * FROM user_audit_trail;
```

**조치방법**:
- Audit Table 접근 권한을 관리자 계정으로 제한
- 감사 파일이 있는 디렉터리는 일반 사용자 접근 불가하도록 설정

---

### D-18 응용프로그램 또는 DBA 계정의 Role이 Public으로 설정되지 않도록 조정

> 점검ID: D-18 | 위험도: 상 | 카테고리: 옵션관리

**점검내용**: 응용 프로그램 또는 DBA 계정의 Role이 Public으로 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: DBA 계정의 Role이 Public으로 설정되지 않은 경우
- ❌ 취약: DBA 계정의 Role이 Public으로 설정된 경우

**점검방법**:

**Oracle DB**
```sql
-- DBA Role 설정 확인
SQL> SELECT granted_role FROM dba_role_privs WHERE grantee = 'PUBLIC';

-- PUBLIC 그룹의 권한 취소
SQL> REVOKE [Role name] FROM PUBLIC;
```

**Altibase**
```sql
-- 사용자 정보 조회하여 Object 권한, 시스템 권한이 Public 또는 Guest에게 부여되어 있는지 확인
SELECT * FROM system_.sys_users_;
SELECT * FROM system_.sys_grant_object_;
SELECT * FROM system_.sys_grant_system_;

-- 불필요 권한 회수
REVOKE <권한> ON <Object> FROM [계정명];
```

**Tibero**
```sql
-- 사용자 정보 조회하여 Role 부여가 적절한지 확인
SELECT * FROM dba_role_privs;
SELECT * FROM user_role_privs;

-- 불필요 권한 회수
REVOKE <권한> FROM [계정명];
```

**조치방법**:
- DBA 계정의 Role 설정에서 Public 그룹 권한 취소

---

### D-19 OS_ROLES, REMOTE_OS_AUTHENTICATION, REMOTE_OS_ROLES를 FALSE로 설정

> 점검ID: D-19 | 위험도: 상 | 카테고리: 옵션관리

**점검내용**: OS_ROLES, REMOTE_OS_AUTHENTICATION, REMOTE_OS_ROLES가 FALSE로 설정이 적용되어 있는지 점검

**판단기준**:
- ✅ 양호: OS_ROLES, REMOTE_OS_AUTHENTICATION, REMOTE_OS_ROLES 설정이 FALSE로 설정된 경우
- ❌ 취약: OS_ROLES, REMOTE_OS_AUTHENTICATION, REMOTE_OS_ROLES 설정이 TRUE로 설정되지 않은 경우

**점검방법**:

**Oracle DB**
```sql
-- OS_ROLES 확인
SQL> SHOW PARAMETER os_roles;
SQL> SELECT value FROM v$parameter WHERE name = 'os_roles';
-- Oracle_HomeDirectory/admin/pfile/init.ora에서 OS_ROLE = FALSE 추가 및 인스턴스 재시작

-- REMOTE_OS_AUTHENTICATION 확인
SQL> SHOW PARAMETER remote_os_authent;
SQL> SELECT value FROM v$parameter WHERE name = 'remote_os_authent';
-- Oracle_HomeDirectory/admin/pfile/init.ora에서 remote_os_authent = FALSE 추가 및 인스턴스 재시작

-- REMOTE_OS_ROLES 확인
SQL> SHOW PARAMETER remote_os_roles;
SQL> SELECT value FROM v$parameter WHERE name = 'remote_os_roles';
-- Oracle_HomeDirectory/admin/pfile/init.ora에서 remote_os_roles = FALSE 추가 및 인스턴스 재시작

-- 버전 9i 이후는 SPFILE을 재생성해야 하므로, DBMS를 Shutdown 시키면 spfile이 재생성됨
```

**조치방법**:
- OS_ROLES, REMOTE_OS_AUTHENTICATION, REMOTE_OS_ROLES 설정을 FALSE로 변경
- init.ora 파일 수정 및 인스턴스 재시작

---

### D-20 인가되지 않은 Object Owner의 제한

> 점검ID: D-20 | 위험도: 하 | 카테고리: 옵션관리

**점검내용**: Object Owner가 인가된 계정에게만 존재하는지 점검

**판단기준**:
- ✅ 양호: Object Owner가 SYS, SYSTEM, 관리자 계정 등으로 제한된 경우
- ❌ 취약: Object Owner가 일반 사용자에게도 존재하는 경우

**점검방법**:

**Oracle DB**
```sql
-- 설정 확인
SQL> SELECT DISTINCT owner FROM dba_objects WHERE owner NOT IN ('SYS', 'SYSTEM', 'MDSYS', 'CTXSYS', 'ORDSYS', 'ORDPLUGINS', 'AURORA$JIS$UTILITY$', 'HR', 'ODM', 'ODM_MTR', 'OE', 'APDBA', 'OLAPSYS', 'OSE$HTTP$ADMIN', 'OUTLN', 'LBACSYS', 'MTSYS', 'PM', 'PUBLIC', 'QS', 'QS_ADM', 'QS_CB', 'QS_CBADM', 'DBSNMP', 'QS_CS', 'QS_ES', 'QS_OS', 'QS_WS', 'RMAN', 'SH', 'WKSYS', 'WMSYS', 'XDB') AND owner NOT IN (SELECT grantee FROM dba_role_privs WHERE granted_role = 'DBA');

-- 권한 취소
SQL> REVOKE <권한> ON <Object> FROM user;
```

**Altibase**
```sql
-- 사용자에게 부여된 Object 권한 정보 확인
SELECT * FROM system_.sys_grant_object_;
SELECT * FROM system_.sys_privileges_;

-- 불필요한 권한 회수
REVOKE <권한> ON <Object> FROM [소유자];
```

**Tibero**
```sql
-- 데이터베이스 내 모든 스키마 Object 특권의 정보 조회
SELECT * FROM dba_tbl_privs;
```

**PostgreSQL**
```sql
-- Object 권한 정보 확인
postgres=# SELECT DISTINCT relowner FROM pg_class WHERE relowner NOT IN (SELECT usesysid FROM pg_user WHERE usesuper = TRUE);
```

**조치방법**:
- Object Owner를 SYS, SYSTEM, 관리자 계정으로 제한 설정

---

### D-21 인가되지 않은 GRANT OPTION 사용 제한

> 점검ID: D-21 | 위험도: 중 | 카테고리: 옵션관리

**점검내용**: 일반 사용자에게 GRANT OPTION이 ROLE에 의하여 부여되어 있는지 점검

**판단기준**:
- ✅ 양호: WITH_GRANT_OPTION이 ROLE에 의하여 설정된 경우
- ❌ 취약: WITH_GRANT_OPTION이 ROLE에 의하여 설정되지 않은 경우

**점검방법**:

**Oracle DB, Tibero**
```sql
-- 설정 확인
SQL> SELECT grantee || ':' || owner || '.' || table_name FROM dba_tab_privs WHERE grantable = 'YES' and owner NOT IN ('SYS', 'MDSYS', 'ORDPLUGINS', 'ORDSYS', 'SYSTEM', 'WMSYS', 'SDB', 'LBACSYS') AND grantee NOT IN (SELECT grantee FROM dba_role_privs WHERE granted_role = 'DBA') ORDER BY grantee;

-- 권한 회수, 재부여
SQL> REVOKE role FROM user;
```

**MySQL**
```sql
-- 설정 확인
SELECT user, grant_priv FROM mysql.user;

-- 권한 회수
REVOKE <권한> ON <대상> FROM [계정명];
```

**Altibase**
```sql
-- 일반 사용자에게 with grant option이 부여(1)되어 있는 경우 취약
SELECT * FROM system_.sys_users_;
SELECT * FROM system_.sys_grant_object_;
SELECT * FROM system_.sys_privileges_;

-- 권한 회수
REVOKE <권한> ON <Object> FROM [계정명];
```

**조치방법**:
- WITH_GRANT_OPTION이 ROLE에 의하여 설정되도록 변경

---

### D-22 데이터베이스의 자원 제한 기능을 TRUE로 설정

> 점검ID: D-22 | 위험도: 하 | 카테고리: 옵션관리

**점검내용**: RESOURCE_LIMIT 값이 TRUE로 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: RESOURCE_LIMIT 설정이 TRUE로 되어있는 경우
- ❌ 취약: RESOURCE_LIMIT 설정이 FALSE로 되어있는 경우

**점검방법**:

**Oracle DB**
```bash
# init.ora 설정 파일에 RESOURCE_LIMIT = TRUE 추가
# (Oracle_HomeDirectory/admin/pfile/init.ora)
#vi /Oracle_HomeDirectory/admin/pfile/init.ora
```

```sql
-- SQL*Plus에서 명령어로 설정 추가 및 확인
SQL> ALTER SYSTEM SET RESOURCE_LIMIT = TRUE;
SQL> SHOW PARAMETER RESOURCE_LIMIT;
```

**조치방법**:
- RESOURCE_LIMIT 설정을 TRUE로 설정 변경

---

### D-23 xp_cmdshell 사용 제한

> 점검ID: D-23 | 위험도: 상 | 카테고리: 옵션관리

**점검내용**: xp_cmdshell의 사용 여부 점검

**판단기준**:
- ✅ 양호: xp_cmdshell이 비활성화 되어 있거나, 활성화 되어 있으면 다음 조건을 모두 만족하는 경우
  1. public의 실행(Execute) 권한이 부여되어 있지 않은 경우
  2. 서비스 계정(애플리케이션 연동)에 sysadmin 권한이 부여되어 있지 않은 경우
- ❌ 취약: xp_cmdshell이 활성화 되어 있고, 양호의 조건을 만족하지 않는 경우

**점검방법**:

**MSSQL - xp_cmdshell 사용이 불필요한 경우**
```
SQL Server Management Studio > 개체 탐색기 → 컴퓨터 이름 우클릭 → 패싯 → 일반
→ XPCmdShellEnabled 값 확인
```

```sql
-- 쿼리문으로 확인
SELECT name, value FROM sys.configurations WHERE name = 'xp_cmdshell';
-- value가 1이면 활성화, 0이면 비활성화

-- XPCmdShellEnabled 값을 false로 설정
EXEC sp_configure 'show advanced options', 1; GO
RECONFIGURE; GO
EXEC sp_configure 'xp_cmdshell', 0; GO
RECONFIGURE GO
```

**MSSQL - xp_cmdshell 사용이 필요한 경우**
```sql
-- xp_cmdshell의 public 실행 권한 제거
REVOKE EXECUTE ON master.dbo.xp_cmdshell TO public

-- 서비스 계정의 sysadmin 권한 제거
-- sysadmin 권한이 부여된 계정 확인
EXEC sp_helpsrvrolemember 'sysadmin'

-- sysadmin 권한 제거
EXEC master..sp_dropsrvrolemember @loginame = N'<계정명>', @rolename = N'sysadmin'
```

**조치방법**:
- xp_cmdshell 설정 값을 0 또는 False로 설정
- 필요한 경우 public 실행 권한 및 sysadmin 권한 제거

---

### D-24 Registry Procedure 권한 제한

> 점검ID: D-24 | 위험도: 상 | 카테고리: 옵션관리

**점검내용**: Registry Procedure의 권한 설정 확인 및 점검

**판단기준**:
- ✅ 양호: 제한이 필요한 시스템 확장 저장 프로시저들이 DBA 외 guest/public에게 부여되지 않은 경우
- ❌ 취약: 제한이 필요한 시스템 확장 저장 프로시저들이 DBA 외 guest/public에게 부여된 경우

**점검방법**:

**MSSQL**
```
SQL Server Management Studio > 개체 탐색기 → 데이터베이스
→ 시스템 데이터베이스 → master > 프로그래밍 기능 → 확장 저장 프로시저 → 시스템 확장 저장 프로시저
→ 각 시스템 확장 저장 프로시저 → 마우스 우클릭 → 속성
→ 사용 권한 → public 실행 권한 제거(체크 해제)
```

**시스템 확장 저장 프로시저 제한 목록**:
- sys.xp_readdmultistring
- sys.xp_regdeletekey
- sys.xp_regdeletevalue
- sys.xp_regenumvalues
- sys.xp_regread
- sys.xp_regremovemultistring
- sys.xp_regwrite

**조치방법**:
- guest/public에게 부여된 시스템 확장 저장 프로시저 권한 제거

---

## 4. 패치 관리

### D-25 주기적 보안 패치 및 벤더 권고 사항 적용

> 점검ID: D-25 | 위험도: 상 | 카테고리: 패치관리

**점검내용**: 안전한 버전의 데이터베이스를 사용하고 있는지 점검

**판단기준**:
- ✅ 양호: 보안 패치가 적용된 버전을 사용하는 경우
- ❌ 취약: 보안 패치가 적용되지 않는 버전을 사용하는 경우

**점검방법**:

**Oracle DB**
```sql
-- 제품 버전 현황 확인
SQL> SELECT banner FROM v$version WHERE banner LIKE 'Oracle%';

-- 최신 버전 확인
-- http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
```

**MSSQL**
```sql
-- 제품 버전 현황 확인
SELECT @@version

-- 또는
SELECT SERVERPROPERTY('productversion') AS ProductVersion, SERVERPROPERTY('productlevel') AS ProductLevel, SERVERPROPERTY('edition') AS Edition;

-- 최신 버전 확인
-- http://support.microsoft.com/kb/321185/en-us
```

**MySQL**
```sql
-- 제품 버전 현황 확인
mysql> SELECT VERSION();

-- 최신 버전 확인
-- http://downloads.mysql.com/archives.php
```

**Altibase**
```sql
-- 제품 버전 현황 확인
SELECT PRODUCT_SIGNATURE FROM v$database;

-- 최신 패치 노트 확인
-- http://support.Altibase.com/kr/patch-note
```

**Tibero**
```bash
# 제품 버전 현황 확인
tbboot –v

# 최신 패치 노트 확인
# http://technet.tmaxsoft.com/
# Tibero 패치 정책: 매 분기 초 픽스셋 발표(년간 총 4회 배포)
```

**PostgreSQL**
```sql
-- 제품 버전 현황 확인
SELECT VERSION();

-- 최신 버전 확인
-- http://www.postgresql.org/support/security
```

**Cubrid**
```bash
# 제품 버전 현황 확인
cubrid_rel

# 최신 버전 확인
-- https://cubrid.com/release_note/
```

**조치방법**:
- 보안 패치가 적용된 버전으로 업데이트
- 벤더 권고 사항 주기적 확인 및 적용

---

### D-26 데이터베이스의 접근, 변경, 삭제 등의 감사 기록이 기관의 감사 기록 정책에 적합하도록 설정

> 점검ID: D-26 | 위험도: 상 | 카테고리: 패치관리

**점검내용**: 감사 기록 정책 설정이 기관 정책에 적합하게 설정되어 있는지 점검

**판단기준**:
- ✅ 양호: DBMS의 감사 로그 저장 정책이 수립되어 있으며, 정책 설정이 적용된 경우
- ❌ 취약: DBMS에 대한 감사 로그 저장을 하지 않거나, 정책 설정이 적용되지 않은 경우

**점검방법**:

**Oracle DB**
```sql
-- 데이터베이스 감사 기록 정책 및 백업 정책 수립
-- DBMS에 대한 기본적인 감사 설정

SQL> connect sys as sysdba
Enter password: ********
Connected.

SQL> ALTER SYSTEM SET AUDIT_TRAIL=DB SCOPE=SPFILE;
System altered.

SQL> shutdown immediate
Database closed.
Database dismounted.
ORACLE instance shut down.

SQL> startup
ORACLE instance started.

SQL> AUDIT SESSION WHENEVER NOT SUCCESSFUL;
Audit succeeded.
```

**MSSQL**
```
-- MSSQL 2000
[SQL SERVER] > [등록정보] > [보안] > [감사수준] > '모두' 선택

-- MSSQL 2005, 2008, 2012, 2016, 2019, 2022
[SQL SERVER] > [마우스 우클릭] > [속성] > [보안] > [로그인 감사] 옵션
→ '실패한 로그인과 성공한 로그인 모두' 선택
```

**조치방법**:
- DBMS에 대한 감사 로그 저장 정책 수립, 적용
- 데이터, 로그, 응용 프로그램에 대한 감사 기록 정책 수립

---

## 참고사항

### 비밀번호 관리 방법

1. 영문, 숫자, 특수문자를 조합하여 계정명과 상이한 8자 이상의 비밀번호 설정
   - 2가지 종류 이상 조합: 최소 10자리 이상
   - 3가지 종류 이상 조합: 최소 8자리 이상
   - 문자 종류: 영문 대문자(26개), 영문 소문자(26개), 숫자(10개), 특수문자(32개)

2. 시스템마다 상이한 비밀번호 사용

3. 비밀번호를 기록해 놓을 경우 변형하여 기록

4. 가급적 자주 비밀번호를 변경

### 주요 용어

- **기본 계정**: DB 설치 후 초기에 기본으로 생성되어있는 DBMS 관리용 계정(예: sa)
- **불필요한 계정**: SCOTT, PM, ADAMS, CLARK 등의 Demonstration 계정 및 퇴사나 직무 변경 등으로 더 이상 사용하지 않는 계정
- **무차별 대입 공격(Brute Force Attack)**: 특정 암호를 해독하기 위해 가능한 모든 값을 대입하는 공격 방법
- **사전 대입 공격(Dictionary Attack)**: 사전에 있는 단어를 입력하여 비밀번호를 알아내거나 암호를 해독하는데 사용되는 컴퓨터 공격 방법
- **Role**: 사용자에게 허가할 수 있는 권한들의 집합
- **Object(객체)**: ALTER, DELETE, EXECUTE, INDEX, INSERT, SELECT 등
- **오라클 Listener**: 클라이언트가 원격에서 오라클 DB에 접근할 때 접근 요청을 처리하기 위한 서버 쪽 프로세스, 혹은 네트워크 인터페이스(TCP/1521 포트 사용)
- **listener.ora**: 오라클 서버에서 클라이언트의 요청을 듣고, 클라이언트와의 통신 환경을 설정하는 파일
- **trace 파일**: 데이터베이스에 문제가 발생했을 시 문제를 진단하고 디버깅할 수 있도록 다양한 정보를 제공하는 파일
- **kerberos 보안 프로토콜**: 개방된 컴퓨터 네트워크 내에서 서비스 요구를 인증하기 위한 보안 시스템
- **sa 계정**: 데이터베이스 서버 설치 시 자동으로 생성되며 DB 서버 관리자 계정
