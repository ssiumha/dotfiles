# Security Domain Routing Guide

## 키워드 → 도메인 매핑

### code-review (코드 보안 리뷰)

| 시그널 | 비고 |
|--------|------|
| 코드 리뷰, 보안 리뷰, security review | 코드 변경 대상 |
| OWASP, XSS, injection, SSRF, CSRF | 웹 취약점 (코드 레벨) |
| 시크릿, secret, API 키, credential | 자격증명 노출 |
| hardcoded, 하드코딩 | 민감정보 하드코딩 |
| eval, pickle, shell=True, unsafe | 위험 함수 사용 |
| semgrep, gitleaks, npm audit, pip-audit | 보안 도구 |
| AI 생성 코드, AI code | AI 코드 보안 |

**로드**: `code-review/README.md` → 심각도별 패턴 파일 선택적 로드

### vuln (기술적 취약점 점검)

| 시그널 | 비고 |
|--------|------|
| U-XX, W-XX, WEB-XX, S-XX, N-XX | 점검항목 ID |
| D-XX, M-XX, HV-XX, CA-XX | 점검항목 ID |
| KISA, 금융보안원, 기반시설 | 출처 기관 |
| 취약점 점검, 취약점 평가, 취약점 진단 | 인프라 대상 |
| 서버 보안, unix, windows, 리눅스 | 서버 점검 |
| 모의해킹, 웹 해킹, pentest | 웹 모의해킹 |
| 네트워크장비, 보안장비, DBMS | 장비별 점검 |
| 클라우드, 가상화, 모바일 | 클라우드/모바일 |

**로드**: `vuln/README.md` → `vuln/REFERENCE.md` → 도메인별 데이터 파일

### isms (ISMS-P 인증)

| 시그널 | 비고 |
|--------|------|
| ISMS, ISMS-P, 인증, 관리체계 | 인증 제도 |
| 1.x.x, 2.x.x, 3.x.x (항목 번호) | 인증기준 번호 |
| 체크리스트, 이행 계획, GAP 분석 | 인증 작업 |
| 접근통제, 인적보안, 암호정책 | 보호대책 키워드 |
| 개인정보, 동의, 파기 | 개인정보 영역 |
| 클라우드 매핑, AWS, Azure | 클라우드 ISMS |
| 산출물, 결함사례 | 실무 자료 |

**로드**: `isms/README.md` → `isms/REFERENCE.md` → 영역별 데이터 파일

### efsr (전자금융감독규정)

| 시그널 | 비고 |
|--------|------|
| EFSR, 전자금융, 감독규정, 금융위원회 | 규정명 |
| 제N조, 제N조의N | 조항 번호 |
| 망분리, CISO, 정보보호위원회 | 금융 특화 키워드 |
| 재해복구, DR센터, 업무연속성 | 연속성 키워드 |
| 보안성심의, 보안성 심의 | 심의 키워드 |
| 자체전담반, 취약점평가 | 취약점관리 |
| 금융보안, 전자금융업자 | 대상 기관 |

**로드**: `efsr/README.md` → `efsr/REFERENCE.md` → 분야별 데이터 파일

## 모호성 해소 규칙

| 표현 | 도메인 | 이유 |
|------|--------|------|
| "취약점 점검/평가/진단" | vuln | 인프라 레벨 점검 |
| "취약점 코드/리뷰" | code-review | 코드 레벨 분석 |
| "보안 리뷰" | code-review | 코드 변경 리뷰 |
| "보안 점검" | vuln | 인프라 점검 |
| "EFSR 취약점" | efsr → vuln | EFSR 조항 → 기술적 점검항목 |
| "ISMS 인증 + 금융" | isms + efsr | cross-reference.md 참조 |
