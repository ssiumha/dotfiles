
# Test Review

기존 테스트 코드의 품질, overfitting, test smell, 커버리지 품질을 리뷰한다.

```
/test-review                    # git diff 기반 변경된 테스트 리뷰
/test-review src/tests/         # 지정 경로 리뷰
/test-review **/*_test.py       # glob 패턴으로 리뷰
```

## 핵심 철학

1. **리뷰만, 수정 안 함**: 리포트와 제안만 제공하고 코드를 직접 수정하지 않는다
2. **구현이 아닌 행위 기준**: 테스트가 구현 세부사항이 아닌 행위를 검증하는지 본다
3. **Codebase-grounded**: 추측이 아닌 실제 코드 확인으로 판단한다
4. **code-review 참조**: 품질 기준은 code-review의 체크리스트를 기반으로 하되, 여기서 중복 기술하지 않는다
5. **비례적 리뷰**: 파일 수에 비례하여 깊이를 조절한다 (1-3파일: 상세, 4-10: 주요 이슈, 10+: 패턴 기반)

## 심각도 기준

| 심각도 | 기준 | 예시 |
|:---:|------|------|
| **High** | 테스트가 무의미하거나 거짓 확신 제공 | 항상 통과, 구현 변경 시 깨지지 않음, 빈 assert |
| **Medium** | 유지보수 어려움 또는 신뢰도 저하 | 내부 구조 변경 시 불필요하게 깨짐, flaky 패턴 |
| **Low** | 개선 권장 | 가독성, 이름, 구조, 중복 |

---

## Phase 1: 리뷰 범위 결정

### 1.1. 대상 파일 결정

인자가 있으면 해당 경로/glob을 사용하고, 없으면 git diff 기반으로 감지한다:

```
인자 있음 → Glob으로 테스트 파일 탐색
인자 없음 → git diff --name-only HEAD 에서 테스트 파일 필터링
```

**테스트 파일 감지 패턴** (Glob):
- `*_test.*`, `*_spec.*`, `*.test.*`, `*.spec.*`
- `test_*.*`
- `tests/`, `__tests__/`, `spec/` 디렉토리 내 파일

### 1.2. 프레임워크 감지

테스트 파일의 import/require 패턴으로 프레임워크를 감지한다:

| 패턴 | 프레임워크 |
|------|-----------|
| `import pytest` / `from pytest` | pytest |
| `import unittest` | unittest |
| `from django.test` | Django Test |
| `import { describe, it, expect }` / `from 'vitest'` | Vitest |
| `import { render }` from `@testing-library` | Testing Library |
| `describe(` + `expect(` | Jest/Mocha |
| `import { Test }` from `@nestjs/testing` | NestJS Test |
| `@SpringBootTest` / `@Test` | JUnit/Spring |
| `RSpec.describe` / `it "..."` | RSpec |
| `func Test` + `testing.T` | Go testing |
| `#[test]` / `#[cfg(test)]` | Rust test |

### 1.3. 범위 요약

분석 전 사용자에게 범위를 보고한다:

```
리뷰 범위: N개 테스트 파일 (프레임워크: pytest)
- src/tests/test_user.py (120줄)
- src/tests/test_order.py (85줄)
```

---

## Phase 2: 정보 수집

### 2.1. 테스트 코드 Read

모든 대상 테스트 파일을 Read한다. 큰 파일(>500줄)은 Grep으로 구조 먼저 파악.

### 2.2. 구현 코드 Read

테스트가 검증하는 구현 코드를 Read한다:
- import/require 경로 추적
- 테스트 대상 함수/클래스의 시그니처와 로직 파악

### 2.3. 요구사항 수집 (있을 경우)

아래 위치에서 요구사항/스펙을 탐색한다:
- 테스트 파일 내 주석 (`REQ:`, `Fixes #`, `Per spec:`)
- `SPEC.md`, `requirements.md`, `stories/` 등
- 없으면 Phase 4를 "요구사항 문서 없음 — 스킵"으로 표기

---

## Phase 3: 5-Area 분석

각 영역의 상세 기준은 `resources/` 파일을 참조한다.

### 3.1 Overfitting 분석

> 상세: `resources/04-overfitting-patterns.md`

테스트가 구현 세부사항에 과도하게 결합되어 있는지 분석한다.

**감지 포인트**:
- 내부 상태 직접 접근 (`_private`, `internal`)
- 과도한 Mock (3개 이상 Mock/patch)
- Mock 호출 횟수/인자 검증 (`assert_called_with`, `toHaveBeenCalledWith`)
- 하드코딩된 기대값 (의도 불명확)
- 순서 의존적 테스트
- private 함수 직접 테스트

**Grep 감지 힌트**:
```
# Mock 과다
Grep: @patch|@mock|jest\.fn|sinon\.stub|Mock\(  (count > 3 per test)

# 내부 상태 접근
Grep: \._[a-z]|\.internal|\.private|\(.*as any\)

# Mock 호출 검증
Grep: assert_called|toHaveBeenCalled|calledWith|called_once
```

### 3.2 Test Smell 감지

> 상세: `resources/01-test-smell-catalog.md`

10가지 test smell 패턴을 체크한다:

1. **Eager Test** — 하나의 테스트가 너무 많은 것을 검증
2. **Mystery Guest** — 외부 데이터에 의존 (파일, DB 등)
3. **Resource Optimism** — 리소스 존재를 가정
4. **Test Run War** — 공유 리소스로 인한 테스트 간 간섭
5. **General Fixture** — 과도하게 큰 공유 fixture
6. **Sensitive Equality** — 깨지기 쉬운 동등성 비교
7. **Slow Test** — 불필요하게 느린 테스트
8. **Conditional Logic** — 테스트 내 if/for 로직
9. **Obscure Test** — 의도가 불명확한 테스트
10. **Dead Test** — 실행되지 않는 테스트

### 3.3 테스트 품질

> 기준: code-review의 품질 체크리스트 참조

아래 항목을 확인한다:

| 항목 | 확인 내용 |
|------|----------|
| AAA 구조 | Arrange-Act-Assert 명확한가 |
| 독립성 | 테스트 간 의존성 없는가 |
| 명확한 이름 | 동작/상황/결과를 설명하는가 |
| 단일 관심사 | 1테스트 = 1실패 원인인가 |
| DAMP 준수 | 각 테스트가 독립적으로 이해 가능한가 |
| 테스트 진정성 | skip/disabled/조건부 assert 없는가 |
| Mock 사용 | Goldilocks Rule 준수하는가 |

### 3.4 통합/E2E 리뷰

> 상세: `resources/02-integration-e2e-criteria.md`

통합 또는 E2E 테스트가 있을 경우에만 수행한다. 없으면 "해당 없음"으로 표기.

**감지 기준** (통합/E2E 테스트 판별):
- DB 연결 (실제 또는 in-memory)
- HTTP 요청 (supertest, requests, httpx)
- 여러 모듈 간 상호작용
- E2E 프레임워크 (Playwright, Cypress, Selenium)

**리뷰 포인트**:
- 추상화 레벨 적절성
- DB/네트워크/파일 격리
- Flakiness 패턴
- Setup/Teardown 완전성

### 3.5 커버리지 품질

> 상세: `resources/03-coverage-quality.md`

코드 커버리지의 **질적** 측면을 분석한다 (수치가 아닌 의미).

**분석 포인트**:
- 의미 있는 assert vs 피상적 assert (호출만 하고 결과 미검증)
- Happy path 편중 vs Edge case/Error case 균형
- Branch 커버리지 관점 (조건문의 양쪽 경로)
- Dead test 감지 (assert 없는 테스트, 항상 통과하는 테스트)
- Mutation testing 사고실험 ("이 코드를 바꾸면 어떤 테스트가 잡을까?")

---

## Phase 4: 요구사항 커버리지

요구사항/스펙이 있을 경우에만 수행한다.

### 4.1. 매핑 생성

요구사항과 테스트를 매핑한다:

```
| 요구사항 | 테스트 | 상태 |
|---------|--------|:---:|
| 로그인 성공 시 토큰 반환 | test_login_returns_token | ✅ |
| 5회 실패 시 계정 잠금 | - | ❌ 누락 |
```

### 4.2. 누락 시나리오 식별

테스트되지 않은 요구사항, 엣지 케이스, 에러 시나리오를 식별한다.

---

## Phase 5: 리포트 생성

### 5.1. 헤더

```markdown
# Test Review Report

**Files**: N files | **Issues**: X High, Y Medium, Z Low | **Verdict**: PASS/WARN/FAIL
**Framework**: pytest | **Date**: YYYY-MM-DD
```

### 5.2. 영역별 테이블

각 분석 영역에서 발견된 이슈를 테이블로 정리한다:

```markdown
## Overfitting 분석

| 테스트 | 문제 | 심각도 | 파일:라인 |
|--------|------|:---:|----------|
| test_user_save | 내부 상태 _flag 직접 확인 | High | test_user.py:42 |
| test_calc_total | Mock 호출 횟수 검증 | Medium | test_order.py:18 |

## Test Smell 감지

| Smell | 테스트 | 설명 | 심각도 |
|-------|--------|------|:---:|
| Eager Test | test_user_flow | 3개 동작을 1테스트에서 검증 | Medium |
| Dead Test | test_old_feature | assert 없음 | High |

## 테스트 품질

| 항목 | 상태 | 비고 |
|------|:---:|------|
| AAA 구조 | ✅ | |
| 독립성 | ⚠️ | test_b가 test_a 결과에 의존 |
| 명확한 이름 | ❌ | test_1, test_2 등 |
| 단일 관심사 | ✅ | |
| DAMP 준수 | ⚠️ | 과도한 헬퍼 추상화 |
| 테스트 진정성 | ✅ | |
| Mock 사용 | ⚠️ | 내부 모듈 Mock 2건 |

## 통합/E2E 리뷰

(해당 시에만 표시)

| 항목 | 상태 | 비고 |
|------|:---:|------|
| DB 격리 | ✅ | 트랜잭션 롤백 |
| Flakiness | ⚠️ | sleep 기반 대기 1건 |

## 커버리지 품질

| 항목 | 상태 | 비고 |
|------|:---:|------|
| 의미 있는 assert | ⚠️ | 3개 테스트에서 반환값 미검증 |
| Edge case | ❌ | 빈 입력, null 미테스트 |
| Error case | ✅ | 주요 예외 시나리오 커버 |
| Branch 커버리지 | ⚠️ | else 분기 미커버 2건 |

## 요구사항 커버리지

(요구사항 있을 시에만 표시)

## 테스트 실행 결과

(main agent가 테스트 실행 결과를 제공한 경우에만 표시)
```

### 5.3. 권장 사항

심각도순으로 구체적 개선안을 나열한다:

```markdown
## 권장 사항

1. **[High]** `test_old_feature` — assert 없는 dead test. 의미 있는 검증 추가 또는 삭제 필요
2. **[High]** `test_user_save:42` — `user._flag` 내부 상태 직접 접근. public API 통해 검증으로 변경
3. **[Medium]** `test_user_flow` — 3개 동작을 1테스트에서 검증 (Eager Test). 테스트 분리 권장
4. **[Low]** `test_1`, `test_2` — 테스트명이 동작을 설명하지 않음. `test_메서드_상황_결과` 패턴 권장
```

### 5.4. Verdict (총평)

| 조건 | 총평 |
|------|------|
| High 0개 + Medium 0-2개 | **PASS** — 테스트 품질 양호 |
| High 0개 + Medium 3개 이상 | **WARN** — 개선 권장 |
| High 1개 이상 | **FAIL** — 수정 필수 |

---

## Phase 6: 후속 안내

총평 결과에 따라 다음 행동을 안내한다:

| 총평 | 안내 |
|------|------|
| **PASS** | "테스트 품질에 큰 문제가 없습니다." |
| **WARN** | "아래 항목을 확인하세요: [WARN 목록]. 테스트 작성 기준은 `/plan-review tdd`를 참조하세요." |
| **FAIL** | "아래 항목을 수정해야 합니다: [FAIL 목록]. `/plan-review tdd`로 작성 기준을 확인한 뒤 수정하세요." |

### 관련 Skill 제안

| 상황 | 제안 |
|------|------|
| 테스트 작성/수정 필요 | `/plan-review tdd` |
| TDD 워크플로우 필요 | `/plan-review tdd` |
| 보안 관련 테스트 부족 | `/security` |
| Mock 구조 문제 | `/plan-review tdd` (Workflow 2: Mock 과다 진단) |

---

## 원칙

1. **독립 평가**: 테스트만으로 의도 파악 → 구현 코드는 overfitting 검증에만 사용
2. **정적 분석 기반**: 코드 구조와 패턴으로 품질 평가 (테스트 실행은 main agent 영역)
3. **요구사항 기준**: 구현이 아닌 요구사항 대비 평가
4. **구체적 피드백**: 문제 테스트와 파일:라인 명시
5. **개선안 제시**: 문제점만 지적하지 않고 해결 방향 제안
6. **비례적 깊이**: 파일 수에 따라 분석 깊이 조절

---

## Examples

### Example 1: 기본 리뷰

```
User: /test-review
```

→ `git diff --name-only HEAD`에서 테스트 파일을 찾아 전체 리뷰 수행.

### Example 2: 특정 경로 리뷰

```
User: /test-review src/tests/test_user.py
```

→ 지정된 파일만 리뷰. 구현 코드(`src/user.py`)도 함께 Read하여 overfitting 분석.

### Example 3: glob 패턴

```
User: /test-review **/*_spec.ts
```

→ 매칭되는 모든 spec 파일을 리뷰.

### Example 4: 리포트 예시 (축약)

```markdown
# Test Review Report

**Files**: 3 files | **Issues**: 1 High, 2 Medium, 1 Low | **Verdict**: FAIL
**Framework**: pytest | **Date**: 2026-02-27

## Overfitting 분석
| 테스트 | 문제 | 심각도 | 파일:라인 |
|--------|------|:---:|----------|
| test_save_user | user._internal 직접 접근 | High | test_user.py:42 |

## Test Smell 감지
| Smell | 테스트 | 설명 | 심각도 |
|-------|--------|------|:---:|
| Conditional Logic | test_discount | for 루프 내 if/else | Medium |
| Obscure Test | test_process | 의도 불명확, assert msg 없음 | Medium |

## 테스트 품질
| 항목 | 상태 |
|------|:---:|
| AAA 구조 | ✅ |
| 독립성 | ✅ |
| 명확한 이름 | ⚠️ |

## 커버리지 품질
| 항목 | 상태 | 비고 |
|------|:---:|------|
| Edge case | ❌ | 빈 입력 미테스트 |

## 권장 사항
1. **[High]** `test_save_user:42` — `user._internal` 접근 제거, public API 사용
2. **[Medium]** `test_discount` — for/if 제거, parametrize 사용
3. **[Medium]** `test_process` — 의도를 설명하는 테스트명과 assert msg 추가
4. **[Low]** 전체적으로 테스트명을 `test_메서드_상황_결과` 패턴으로 개선

**Verdict**: FAIL — High 이슈 1건 수정 필수. `/plan-review tdd`로 작성 기준을 확인하세요.
```

---

## 연동

```
code-review (테스트 작성)
  → test-review (테스트 리뷰)  ← 현재 skill
    → code-review (수정 가이드)

tdd (TDD 워크플로우)
  → test-review (완료 후 검증)
```

| Skill | 관계 | 설명 |
|-------|------|------|
| `code-review` | 보완 | 작성 기준 참조, 수정 시 안내 |
| `tdd` | 선행 | TDD 완료 후 품질 검증으로 연결 |
| `security` | 위임 | 보안 테스트 심층 검토 |
