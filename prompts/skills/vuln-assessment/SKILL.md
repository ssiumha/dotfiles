---
name: vuln-assessment
description: KISA/금융보안원 기술적 취약점 점검항목 제공. Use when performing vulnerability assessments, server security audits (Unix/Windows), or web penetration testing checklists.
user_invocable: true
---

# 취약점 점검항목 조회

KISA 주요정보통신기반시설 가이드와 금융보안원 전자금융기반시설 취약점 평가 기준을 기반으로 한 기술적 취약점 점검항목을 제공합니다. (총 292개 항목)

## Instructions

### 워크플로우 1: 항목 ID로 조회

특정 점검항목 ID로 상세 정보를 조회합니다.

1. **점검ID 파싱**
   - U-XX: Unix 서버 항목 → `server/unix.md`
   - W-XX: Windows 서버 항목 → `server/windows.md`
   - WEB-XX: 웹 모의해킹 항목 → `pentest/web.md`
   - S-XX: 보안장비 항목 → `network/security.md`
   - N-XX: 네트워크장비 항목 → `network/network.md`
   - D-XX: DBMS 항목 → `database/dbms.md`
   - M-XX: 이동통신 항목 → `cloud/mobile.md`
   - HV-XX: 가상화 항목 → `cloud/virtualization.md`
   - CA-XX: 클라우드 항목 → `cloud/cloud.md`

2. **해당 파일에서 항목 검색**
   - Grep으로 점검ID 패턴 검색: `### {점검ID}`
   - 해당 섹션 전체 반환 (점검내용, 판단기준, 점검방법, 조치방법)

3. **결과 포맷**
   ```
   ## {점검ID}: {제목}
   위험도: {상/중/하} | 카테고리: {카테고리}

   **점검내용**: ...
   **판단기준**: 양호/취약 조건
   **점검방법**: 명령어/스크립트
   **조치방법**: 설정 변경 방법
   ```

### 워크플로우 2: 영역별 전체 조회

특정 영역의 전체 점검항목을 조회합니다.

1. **영역 키워드 매핑**
   - "unix", "유닉스", "리눅스" → `server/unix.md` (67개)
   - "windows", "윈도우" → `server/windows.md` (64개)
   - "web", "웹", "모의해킹" → `pentest/web.md` (26개)
   - "security", "보안장비" → `network/security.md` (23개)
   - "network", "네트워크", "네트워크장비" → `network/network.md` (38개)
   - "dbms", "데이터베이스", "db" → `database/dbms.md` (26개)
   - "mobile", "이동통신", "모바일" → `cloud/mobile.md` (4개)
   - "virtualization", "가상화", "vm" → `cloud/virtualization.md` (25개)
   - "cloud", "클라우드" → `cloud/cloud.md` (19개)

2. **파일 읽기**
   - 해당 영역 파일 전체 Read
   - 또는 카테고리별 요약 제공

3. **결과 포맷**
   - 전체: 해당 파일 내용 반환
   - 요약: 카테고리별 항목 목록 테이블

### 워크플로우 3: 키워드 검색

키워드로 관련 점검항목을 검색합니다.

1. **REFERENCE.md에서 키워드 검색**
   - 키워드 검색 가이드 테이블 활용
   - 매칭되는 점검ID 목록 추출

2. **상세 정보 필요 시**
   - 해당 점검ID로 워크플로우 1 실행
   - 여러 항목인 경우 요약 목록 우선 제공

3. **결과 포맷**
   ```
   "{키워드}" 관련 점검항목:

   | 점검ID | 제목 | 위험도 |
   |--------|------|--------|
   | U-01   | root 계정 원격접속 제한 | 상 |
   ...

   상세 조회: /vuln {점검ID}
   ```

### 워크플로우 4: EFSR 연계 조회

전자금융감독규정 이행을 위한 점검항목을 조회합니다.

1. **EFSR 요구사항 매핑**
   - REFERENCE.md의 "EFSR 연계" 섹션 참조
   - 요구사항별 관련 점검항목 추출

2. **체크리스트 형태로 제공**
   ```
   ## EFSR 제37조의2 이행 점검항목

   ### 접근통제
   - [ ] U-01: root 계정 원격접속 제한
   - [ ] U-18: 접속 IP 및 포트 제한
   ...

   ### 계정관리
   - [ ] U-02: 패스워드 복잡성 설정
   ...
   ```

## 중요 원칙

1. **정확한 출처 명시**: 모든 항목은 KISA 또는 금융보안원 공식 가이드 기반
2. **점검/조치 분리**: 점검방법과 조치방법을 명확히 구분하여 제공
3. **위험도 표시**: 상/중/하 위험도를 항상 함께 표시

## Examples

### 예시 1: 단일 항목 조회

User: "/vuln U-01"
```
## U-01: root 계정 원격접속 제한
위험도: 상 | 카테고리: 계정관리

**점검내용**: root 계정으로 원격 접속(SSH, Telnet)이 가능한지 점검

**판단기준**:
- 양호: 원격 터미널 서비스를 사용하지 않거나, root 직접 접속을 차단한 경우
- 취약: root 계정으로 원격 접속이 허용된 경우

**점검방법**:
cat /etc/ssh/sshd_config | grep -i PermitRootLogin

**조치방법**:
# /etc/ssh/sshd_config 수정
PermitRootLogin no
systemctl restart sshd
```

### 예시 2: 영역 전체 조회

User: "/vuln 서버 unix"
→ server/unix.md 전체 내용 반환 (67개 항목)

### 예시 3: 키워드 검색

User: "/vuln root 원격"
```
"root 원격" 관련 점검항목:

| 점검ID | 제목 | 위험도 |
|--------|------|--------|
| U-01 | root 계정 원격접속 제한 | 상 |
| U-44 | root 이외의 UID가 '0' 금지 | 중 |
| U-45 | root 계정 su 제한 | 하 |

상세 조회: /vuln U-01
```

### 예시 4: SQL Injection 점검

User: "/vuln SQL Injection"
```
## WEB-01: SQL Injection
위험도: 상 | 카테고리: 입력값 검증

**점검내용**: SQL 쿼리에 악의적인 입력값 삽입 가능 여부

**점검방법**:
1. 입력 필드에 ' OR '1'='1 삽입
2. UNION SELECT 구문 삽입 시도
3. Time-based: ' AND SLEEP(5)-- 삽입

**조치방법**:
- Prepared Statement 사용
- 입력값 검증 및 이스케이프
- WAF 적용
```

### 예시 5: EFSR 연계 조회

User: "/vuln efsr"
```
## EFSR 제37조의2 이행 점검항목

### 접근통제 (5개 항목)
- [ ] U-01: root 계정 원격접속 제한
- [ ] U-18: 접속 IP 및 포트 제한
- [ ] W-06: 관리자 그룹에 최소한의 사용자 포함
- [ ] W-20: 원격 시스템에서 강제로 시스템 종료
- [ ] W-21~W-24: 공유 폴더 관련

### 계정관리 (30개 항목)
- [ ] U-01~U-05, U-44~U-54
- [ ] W-01~W-14

### 패치관리 (2개 항목)
- [ ] U-42: 최신 보안패치 적용
- [ ] W-40: 최신 보안 패치 적용

### 로그관리 (8개 항목)
- [ ] U-43: 로그의 정기적 검토 및 보고
- [ ] U-72: 시스템 로깅 설정
- [ ] W-41, W-49~W-54: Windows 감사 정책

### 웹취약점 (26개 항목)
- [ ] WEB-01~WEB-26
```

## Technical Details

상세 점검항목은 다음 파일을 참조하세요:

- `REFERENCE.md`: 전체 292개 항목 목록 및 키워드 검색 가이드
- `server/unix.md`: Unix 서버 67개 항목 상세
- `server/windows.md`: Windows 서버 64개 항목 상세
- `pentest/web.md`: 웹 모의해킹 26개 항목 상세
- `network/security.md`: 보안장비 23개 항목 상세
- `network/network.md`: 네트워크장비 38개 항목 상세
- `database/dbms.md`: DBMS 26개 항목 상세
- `cloud/mobile.md`: 이동통신 4개 항목 상세
- `cloud/virtualization.md`: 가상화 25개 항목 상세
- `cloud/cloud.md`: 클라우드 19개 항목 상세
