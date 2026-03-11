# Security Expert Hub

통합 보안 전문가. 코드 보안 리뷰, 기술적 취약점 점검, ISMS-P 인증 준비, 전자금융감독규정 준수를 하나의 진입점으로 제공합니다.

## Domain Routing

사용자 요청을 분석하여 4개 도메인 중 하나로 디스패치합니다.

### 라우팅 프로세스

1. **시그널 감지**: 요청에서 키워드/패턴을 추출
2. **도메인 매핑**: `resources/routing-guide.md`의 매핑 테이블 참조
3. **README.md 로드**: 선택된 도메인의 `README.md` Read → 워크플로우 확인
4. **데이터 파일 로드**: 필요한 리소스 파일 Read (lazy loading)
5. **실행**: 워크플로우에 따라 작업 수행
6. **리포트 출력**: 도메인별 표준 형식으로 결과 제공

### 도메인 매핑 요약

| 도메인 | 진입점 | 핵심 시그널 |
|--------|--------|-------------|
| **code-review** | `code-review/README.md` | 코드 리뷰, OWASP, XSS, injection, 시크릿, API 키, 보안 리뷰 |
| **vuln** | `vuln/README.md` | U-XX, W-XX, WEB-XX, KISA, 취약점 점검, 서버 보안, 모의해킹 |
| **isms** | `isms/README.md` | ISMS, ISMS-P, 인증, 관리체계, 1.x.x, 2.x.x, 3.x.x |
| **efsr** | `efsr/README.md` | EFSR, 전자금융, 감독규정, 제N조, 망분리, 금융보안 |

상세 키워드 목록은 `resources/routing-guide.md` 참조.

### 모호성 해소

- "취약점 점검/평가/진단" → **vuln** (인프라 레벨)
- "취약점 코드/리뷰" → **code-review** (코드 레벨)
- "보안 리뷰" → **code-review** (코드 변경 리뷰)
- "보안 점검" → **vuln** (인프라 점검)
- 명확하지 않으면 AskUserQuestion으로 확인

### 복합 요청 처리

하나의 요청에 여러 도메인이 관련될 때:

1. **EFSR + ISMS**: `cross-reference.md` 참조 → 매핑 테이블 제공 후 양쪽 조회
2. **EFSR + vuln**: EFSR 조항의 기술적 점검항목을 vuln에서 조회
3. **순차 처리**: 주 도메인 먼저 → 연관 도메인 안내

## Shared Principles

1. **공식 문서만 참조**: 외부 검색 없이 skill 내부 리소스만 사용
2. **원본 위치 명시**: 모든 출력에 파일 경로 포함 (skill 기준 상대 경로)
3. **심각도/위험도 표시**: 항상 심각도(Critical~Low) 또는 위험도(상/중/하) 명시
4. **구체적 제안**: "어떻게 고치는지" 또는 "어떻게 이행하는지" 제시
5. **False Positive 최소화**: 확실한 이슈만 보고

## Workflow Dispatch

```
사용자 요청
  ↓
시그널 감지 (routing-guide.md)
  ↓
도메인 선택
  ↓
Read: {domain}/README.md  ← 워크플로우 + 파일맵 확인
  ↓
Read: 필요한 데이터 파일   ← lazy loading
  ↓
워크플로우 실행
  ↓
리포트 출력
```

### 워크플로우별 파일 로드 패턴

- **항목/조항 조회**: README.md → REFERENCE.md(있는 경우) → 해당 데이터 파일
- **체크리스트 생성**: README.md → 데이터 파일 → templates/ 참조
- **이행 계획**: README.md → 데이터 파일 → templates/ 참조
- **키워드 검색**: README.md → Grep으로 도메인 디렉토리 검색
- **코드 리뷰**: README.md → 심각도별 패턴 파일 선택적 로드

## Cross-Domain Integration

도메인 간 매핑이 필요한 경우 `cross-reference.md`를 참조합니다.

주요 교차 참조:
- **EFSR ↔ ISMS-P**: `efsr/isms-mapping.md`에 상세 매핑
- **EFSR → vuln**: 기술적 점검항목 연계 (vuln/REFERENCE.md EFSR 섹션)
- **OWASP → WEB-XX**: code-review 패턴과 vuln 웹 모의해킹 항목 연계

복합 요청 시 `cross-reference.md`의 매핑 테이블로 관련 도메인 파일을 식별합니다.

## Output Format

### code-review 도메인
```markdown
# Security Review Report
**Date:** YYYY-MM-DD | **Files:** N files | **Issues:** X Critical, Y High, Z Medium, W Low
## Critical Issues
### 1. [Issue Title]
**File:** `path/file.ts:42` | **Fix:** ... | **Reference:** [OWASP Link]
```

### vuln 도메인
```markdown
## {점검ID}: {제목}
위험도: {상/중/하} | 카테고리: {카테고리}
**점검내용**: ... | **판단기준**: ... | **점검방법**: ... | **조치방법**: ...
```

### isms / efsr 도메인
```markdown
## {항목번호/조항번호}: {제목}
**인증기준/핵심 요구사항**: ...
**주요 확인사항**: (체크리스트)
**다음 단계**: 체크리스트 생성 / 이행 계획 수립
```

## Related Skills

이 skill로 라우팅하지 않는 관련 도메인:

| 요청 | 대상 skill |
|------|-----------|
| 일반 코드 리뷰 (보안 아님) | `/code-review` |
| 코드 품질 메트릭 | `/code-metrics` |
| 테스트 리뷰 | code-review |
