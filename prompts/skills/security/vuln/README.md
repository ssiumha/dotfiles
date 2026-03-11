# 취약점 점검항목 조회

KISA 주요정보통신기반시설 기술적 취약점 분석평가 가이드 기반 292개 점검항목을 제공한다.

## Workflows

### 1. 항목 ID 조회

점검ID prefix로 파일을 특정하고, `### {점검ID}` 패턴으로 Grep 검색하여 상세 반환한다.

| Prefix | 영역 | 파일 | 항목 수 |
|--------|------|------|:-------:|
| U-XX | Unix 서버 | `./server/unix.md` | 67 |
| W-XX | Windows 서버 | `./server/windows.md` | 64 |
| WEB-XX | 웹 모의해킹 | `./pentest/web.md` | 26 |
| S-XX | 보안장비 | `./network/security.md` | 23 |
| N-XX | 네트워크장비 | `./network/network.md` | 38 |
| D-XX | DBMS | `./database/dbms.md` | 26 |
| M-XX | 이동통신 | `./cloud/mobile.md` | 4 |
| HV-XX | 가상화 | `./cloud/virtualization.md` | 25 |
| CA-XX | 클라우드 | `./cloud/cloud.md` | 19 |

결과 포맷:

```
## {점검ID}: {제목}
위험도: {상/중/하} | 카테고리: {카테고리}

**점검내용**: ...
**판단기준**: 양호/취약 조건
**점검방법**: 명령어/스크립트
**조치방법**: 설정 변경 방법
```

### 2. 영역별 전체 조회

키워드("unix", "유닉스", "windows", "윈도우", "web", "웹", "dbms" 등)로 영역을 매핑하여 해당 파일 전체를 Read하거나 카테고리별 요약 테이블을 제공한다.

### 3. 키워드 검색

`./REFERENCE.md`의 키워드 검색 가이드 테이블에서 매칭되는 점검ID 목록을 추출한다. 상세가 필요하면 Workflow 1로 연계한다.

```
"{키워드}" 관련 점검항목:

| 점검ID | 제목 | 위험도 |
|--------|------|--------|
| U-01   | root 계정 원격접속 제한 | 상 |
```

### 4. EFSR 연계 조회

`./REFERENCE.md`의 EFSR 연계 섹션과 `../efsr/`의 전자금융감독규정 제37조의2를 참조하여 이행 점검 체크리스트를 생성한다.

## 중요 원칙

1. **정확한 출처 명시** -- 모든 항목은 KISA 또는 금융보안원 공식 가이드 기반
2. **점검/조치 분리** -- 점검방법과 조치방법을 명확히 구분하여 제공
3. **위험도 표시** -- 상/중/하 위험도를 항상 함께 표시

## Example

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

## Technical Details

- `./REFERENCE.md` -- 전체 292개 항목 목록, 키워드 검색 가이드, EFSR 연계 매핑
- `./server/unix.md` -- Unix 서버 67개 항목 상세
- `./server/windows.md` -- Windows 서버 64개 항목 상세
- `./pentest/web.md` -- 웹 모의해킹 26개 항목 상세
- `./network/security.md` -- 보안장비 23개 항목 상세
- `./network/network.md` -- 네트워크장비 38개 항목 상세
- `./database/dbms.md` -- DBMS 26개 항목 상세
- `./cloud/mobile.md` -- 이동통신 4개 항목 상세
- `./cloud/virtualization.md` -- 가상화 25개 항목 상세
- `./cloud/cloud.md` -- 클라우드 19개 항목 상세
