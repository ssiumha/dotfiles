# Doc Gardening 스킬 템플릿

프로젝트 전용 doc-gardening 스킬 생성 시 아래 템플릿을 기반으로 한다.
프로젝트 스캔 결과에 따라 해당하는 섹션만 포함하고, `{placeholder}`를 실제 값으로 치환한다.

---

```yaml
---
name: doc-gardening
description: Checks documentation freshness against actual code. Use when "문서 점검", "doc gardening", "하네스 점검", or periodically to maintain documentation quality. Also use proactively when major code changes land (new packages, deleted features, renamed modules).
---
```

```markdown
# Doc Gardening — 문서 신선도 점검

아래 단계를 순서대로 실행하고 마지막에 보고서를 출력한다.

## 1. ARCHITECTURE.md 점검

{ARCHITECTURE.md가 없으면 이 섹션 전체 생략}

### 1a. 소스 디렉토리 검증
{프로젝트 스캔에서 발견된 소스 루트별로 하위 섹션 생성}

- `{소스_디렉토리_경로}` 하위 1-depth 디렉토리 목록을 수집한다
- ARCHITECTURE.md "{해당_섹션명}" 섹션의 목록과 비교한다
- 누락되거나 삭제된 항목을 기록한다

{BE↔FE 매핑 테이블이 있는 경우만}
### 1b. BE-FE 매핑 테이블 검증
- `{rules_또는_ARCHITECTURE_경로}`의 "{매핑_테이블명}" 테이블을 읽는다
- 테이블의 각 항목이 실제로 존재하는지 양방향 확인한다
- 존재하지 않는 항목을 기록한다

{핵심 파일 경로 테이블이 있는 경우만}
### 1c. 핵심 파일 경로 검증
- ARCHITECTURE.md "{파일_경로_테이블명}" 테이블의 모든 경로가 실제 존재하는지 확인한다
- 존재하지 않는 경로를 기록한다

## 2. Rules 점검

{.claude/rules/ 가 없으면 이 섹션 생략}

`.claude/rules/` 하위 모든 `.md` 파일에 대해:

- 파일 내에서 참조하는 소스 파일 경로가 실제 존재하는지 확인한다
- 경로 패턴: 백틱 안의 파일 경로{, 프로젝트별 경로 alias 설명}
- 존재하지 않는 참조를 기록한다

## 3. Docs 점검

{docs/ 가 없으면 이 섹션 생략}

### 3a. 링크 유효성
- `docs/` 하위 index.md, README.md 파일에서 마크다운 링크 `[text](path)`를 추출한다
- 각 링크의 대상 파일이 실제 존재하는지 확인한다 (상대 경로 기준)
- 깨진 링크를 기록한다

### 3b. 문서 신선도
- `docs/` 하위 모든 `.md` 파일의 마지막 수정일을 `git log -1 --format=%ci -- <file>` 로 확인한다
- {신선도_기준_일수}일 이상 수정되지 않은 문서를 기록한다

## 4. 보고서 출력

## Doc Gardening Report

### 신선도 점수: {score}/100

점수 산정:
- 기본 100점
- [STALE] 항목당 -5점
- [WARN] 항목당 -3점
- [BROKEN] 항목당 -10점
- 최소 0점

{점검한 섹션별로 보고서 블록 생성}

#### {섹션명}
- [OK] {검증 항목} {N}개 일치
- [STALE] {구체적 불일치 내용}
- [WARN] {참조 미존재 내용}
- [BROKEN] {링크 깨짐 내용}
- [INFO] {정보성 알림}

## 5. 갱신 제안

발견된 문제별로 구체적인 수정 방안을 제안한다:
- [STALE] → 해당 섹션의 현재 코드 상태와 비교하여 업데이트 내용 제안
- [WARN] → 참조 경로 수정 또는 삭제 제안
- [BROKEN] → 링크 수정 제안

사용자가 수정을 승인하면 해당 파일을 직접 업데이트한다.
```

---

## 스캔 → 치환 매핑

프로젝트 스캔 시 아래 정보를 수집하여 placeholder를 치환한다:

| Placeholder | 수집 방법 |
|-------------|-----------|
| `{소스_디렉토리_경로}` | 프로젝트 루트에서 주요 소스 디렉토리 탐색 (src/, app/, lib/ 등) |
| `{해당_섹션명}` | ARCHITECTURE.md에서 해당 디렉토리를 설명하는 섹션 헤더 |
| `{매핑_테이블명}` | ARCHITECTURE.md 또는 rules/architecture.md의 매핑 테이블 헤더 |
| `{파일_경로_테이블명}` | ARCHITECTURE.md의 핵심 파일 경로 테이블 헤더 |
| `{rules_또는_ARCHITECTURE_경로}` | 매핑 테이블이 위치한 파일 경로 |
| `{프로젝트별 경로 alias 설명}` | 예: "`@/` = `src/`" 같은 경로 alias 규칙 |
| `{신선도_기준_일수}` | 기본 90일. 프로젝트 규모에 따라 조정 |

## 섹션 포함 조건

| 조건 | 포함 섹션 |
|------|-----------|
| ARCHITECTURE.md 존재 | 1. ARCHITECTURE.md 점검 (하위 항목은 테이블 존재 여부에 따라) |
| `.claude/rules/` 존재 | 2. Rules 점검 |
| `docs/` 존재 | 3. Docs 점검 |
| 위 중 1개 이상 | 4. 보고서 + 5. 갱신 제안 (항상 포함) |
