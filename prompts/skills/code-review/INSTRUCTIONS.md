# Code Review

코드 품질, 타입 안전성, lint/죽은 코드를 검토하는 통합 스킬.

## Core Principles

1. **측정 우선** — 수치로 현황 파악 후 개선
2. **심각도 분류** — Critical > High > Medium 순 우선순위
3. **근거 제시** — 각 지적에 파일:라인 + 수정 예시
4. **점진적 개선** — 한 번에 모든 문제 해결 X, 우선순위별 적용
5. **자동화 지향** — 반복 체크는 도구/스크립트화 제안
6. **언어 무관 원칙** — 타입 안전성, 불필요 코드 제거, 일관성은 모든 언어 공통

## Workflow Selection

요청을 분석하여 적절한 워크플로우를 선택한다:

| 요청 패턴 | 워크플로우 | 리소스 |
|-----------|-----------|--------|
| 코드 리뷰, 타입 체크, 타입 안전성 | Type Safety Review | 언어별 checklist |
| lint 감사, 프로젝트 건강, 죽은 코드 | Lint Audit | `03-lint-audit.md` |
| 테스트 리뷰, 테스트 품질, test smell, overfitting | Test Review | `test-review/INSTRUCTIONS.md` |
| terraform, IaC, 인프라 코드 리뷰 | Terraform Review | `04-checklist-terraform.md` |
| 전체 품질 체크, 다각적 리뷰 | Parallel Review Mode | 4개 에이전트 병렬 |
| 둘 다 / Type Safety + Lint | 순차 실행 (Type Safety → Lint Audit) | 전체 |

**라우팅 (이 스킬이 아닌 경우)**:
- 보안 리뷰 → `/security`
- 구조 메트릭 (복잡도, 결합도) → `/code-metrics`

## Workflow 1: Type Safety Review

### 1. 언어 감지

```
tsconfig.json 존재 → TypeScript → resources/01-checklist-typescript.md
pyproject.toml / setup.py 존재 → Python → resources/02-checklist-python.md
둘 다 → 두 체크리스트 모두 적용
```

### 2. 리뷰 범위 결정

| 인자 | 범위 |
|------|------|
| 파일/디렉토리 경로 | 해당 경로만 |
| 없음 + staged changes 있음 | staged 파일만 |
| 없음 + staged 없음 | 프로젝트 전체 (src/ 우선) |

### 3. 체크 실행

1. 해당 언어 checklist 리소스를 로드
2. Detection Patterns으로 파일 스캔 (Grep)
3. 발견 항목을 심각도별 분류
4. 타입 체크 도구 실행 (tsc / mypy)
5. 결과 통합하여 Output Format으로 출력 (Verdict 포함)

## Workflow 2: Terraform Review

### 1. 파일 감지

```
*.tf 파일 존재 → Terraform → resources/04-checklist-terraform.md
```

### 2. 리뷰 범위 결정

| 인자 | 범위 |
|------|------|
| 파일/디렉토리 경로 | 해당 경로만 |
| 없음 + staged changes 있음 | staged .tf 파일만 |
| 없음 + staged 없음 | 프로젝트 전체 .tf 파일 |

### 3. 체크 실행

1. `04-checklist-terraform.md` 로드
2. Grep Patterns으로 .tf 파일 스캔
3. data source → resource 매핑하여 lifecycle 누락 확인
4. 발견 항목을 심각도별 분류
5. `terraform validate` 실행 (가능한 경우)
6. 결과 통합하여 Output Format으로 출력 (Verdict 포함)

## Workflow 3: Lint Audit

`resources/03-lint-audit.md`의 4-phase 워크플로우를 따른다:
1. 프로젝트 분석 (스택/CI/도구 감지)
2. 현황 진단 (lint/타입/죽은코드/커밋 위생)
3. 리포트 생성 (Verdict 포함)
4. 자동화 제안

## Workflow 4: Test Review

`test-review/INSTRUCTIONS.md`의 6-phase 워크플로우를 따른다:
1. 리뷰 범위 결정 (인자 또는 git diff 기반)
2. 정보 수집 (테스트 코드 + 구현 코드 Read)
3. 5-Area 분석 (overfitting, test smell, 품질, 통합/E2E, 커버리지)
4. 요구사항 커버리지 (있을 경우)
5. 리포트 생성 (심각도별 이슈 + 권장사항 + verdict)
6. 후속 안내

## Output Format

```markdown
## Code Review Report

### Findings

**[Critical]** `파일:라인` - 문제 설명 → 수정 예시
**[High]** `파일:라인` - 문제 설명 → 수정 예시
**[Medium]** `파일:라인` - 문제 설명 → 수정 예시

### Summary
- Critical: N개
- High: N개
- Medium: N개
- 총 SLOC: N (오류 밀도: X.XX)

### Verdict: {PASS | WARN | FAIL}

### 권장 조치
1. [우선] ...
2. [중간] ...
3. [낮음] ...
```

## Verdict 판정

| 조건 | 판정 |
|------|------|
| Critical 0개 + High 0-2개 | **PASS** — 품질 양호 |
| Critical 0개 + High 3개 이상 | **WARN** — 개선 권장 |
| Critical 1개 이상 | **FAIL** — 수정 필수 |

## 후속 안내

| Verdict | 안내 |
|---------|------|
| **PASS** | "코드 품질에 큰 문제가 없습니다." |
| **WARN** | 개선 항목 안내. 근본 원인 진단이 필요하면 `/principles check` 참조 |
| **FAIL** | 수정 필수 항목 안내. `/principles check`로 원칙 위반 여부 확인 |

## Parallel Review Mode

`전체 품질 체크`, `다각적 리뷰`, 또는 명시적으로 병렬 리뷰 요청 시 활성화한다.

### 실행 방식

4개 에이전트를 **병렬로 스폰**하여 독립적으로 분석한 뒤, 결과를 통합한다.

| Agent | 역할 | 모델 | 도구 |
|-------|------|------|------|
| #1 Checklist | 언어/IaC별 체크리스트 기반 패턴 스캔 | haiku | Grep, Read |
| #2 Bug Hunter | 변경 코드에서 버그/위험 패턴 탐지 (shallow scan) | sonnet | Read, Grep |
| #3 History | git blame/log으로 과거 맥락 기반 리뷰 | haiku | Bash(git), Read |
| #4 Web Best Practices | 웹 검색으로 관련 best practice/사례 확인 | haiku | WebSearch, WebFetch |

### 에이전트 프롬프트 가이드

각 에이전트에게 전달할 정보:
- 리뷰 대상 파일 목록 + 변경 범위
- 해당 언어/IaC의 checklist 리소스 경로 (#1만)
- 발견한 이슈마다 **심각도 점수(0-100)** 부여

### Scoring Rubric (에이전트에게 그대로 전달)

| 점수 | 기준 |
|------|------|
| 0 | False positive. 가볍게 봐도 문제 아님, 또는 기존 코드 문제 |
| 25 | 문제일 수 있으나 검증 불가. 스타일 이슈이면서 체크리스트에 명시되지 않은 것 |
| 50 | 실제 문제이나 nitpick 수준. PR 전체 맥락에서 중요도 낮음 |
| 75 | 높은 확신. 실제로 발생할 문제이며, 기능에 직접 영향. 체크리스트에 명시된 항목 |
| 100 | 절대 확신. 반드시 발생하는 문제. 증거로 직접 확인 완료 |

### 결과 통합

1. 4개 에이전트 결과 수집
2. **점수 80 미만 필터링** — 남은 이슈만 최종 리포트에 포함
3. 중복 이슈 병합
4. Output Format에 맞춰 출력 (각 이슈에 발견 출처 Agent# 표기)

### False Positive 예시 (에이전트에게 전달)

- 기존 코드의 문제 (이번 변경과 무관)
- Linter/타입체커가 잡을 수 있는 문제 (CI에서 별도 실행)
- 의도적 기능 변경을 버그로 지적
- 코드에서 명시적으로 suppress한 항목 (lint ignore 등)
- 수정하지 않은 라인에 대한 지적

## Related Skills

| 스킬 | 용도 | 사용 시점 |
|------|------|----------|
| `/security` | 보안 취약점 검토 | auth, 사용자 입력, API, 배포 전 |
| `/code-metrics` | 구조 메트릭 | 복잡도, 결합도, 응집도 분석 |
| `/plan-review tdd` | TDD 워크플로우 | RED-GREEN-REFACTOR 개발 진행 |
| `/principles check <name>` | 설계 원칙 점검 | 이슈의 근본 원인이 원칙 위반일 때 (SRP, OCP, DRY, LoD 등). 스코어링 기준 + 기계적 검증 방법 제공 |
