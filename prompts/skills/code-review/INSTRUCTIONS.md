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
| 둘 다 / 전체 품질 체크 | 순차 실행 (Type Safety → Lint Audit) | 전체 |

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
5. 결과 통합하여 Output Format으로 출력

## Workflow 2: Lint Audit

`resources/03-lint-audit.md`의 4-phase 워크플로우를 따른다:
1. 프로젝트 분석 (스택/CI/도구 감지)
2. 현황 진단 (lint/타입/죽은코드/커밋 위생)
3. 리포트 생성
4. 자동화 제안

## Workflow 3: Test Review

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

### 권장 조치
1. [우선] ...
2. [중간] ...
3. [낮음] ...
```

## Related Skills

| 스킬 | 용도 | 사용 시점 |
|------|------|----------|
| `/security` | 보안 취약점 검토 | auth, 사용자 입력, API, 배포 전 |
| `/code-metrics` | 구조 메트릭 | 복잡도, 결합도, 응집도 분석 |
| `/plan-review tdd` | TDD 워크플로우 | RED-GREEN-REFACTOR 개발 진행 |
