---
disable-model-invocation: true
name: principles
description: "소프트웨어 공학 원칙 바스켓. 원칙 카탈로그 열람, 코드/설계/프로세스/테스트의 원칙 준수도 평가, 위반 식별 및 개선 가이드. Use when 원칙 평가, 원칙 점검, 원칙 검증, principles check, 코드 품질 근본 진단, 설계 원칙 리뷰, 아키텍처 원칙 점검, 프로세스 원칙 점검, 테스트 원칙 점검, 테스트 설계, or when other review skills need a principled foundation. Do NOT use for specific code review (use code-review), security audit (use security), or strategic decisions (use strategic-thinking)."
user-invocable: true
argument-hint: "[evaluate|catalog|check <principle>] [target]"
---

# Principles

소프트웨어 공학 원칙 바스켓 + 범용 평가 도구.

> "모든 비결이 1990년대 교재에 다 적혀 있다."

## 핵심 철학

- **모든 원칙은 상황에 따라 적용된다** — 원칙은 법이 아니라 방향이다. 맹목적 적용은 원칙 위반보다 나쁘다
- **원칙은 도구다** — 외우는 것이 아니라 적용하는 것
- **맥락이 원칙보다 우선** — 원칙 간 충돌 시 현재 맥락에서 판단한다. YAGNI와 OCP가 충돌하면? 상황이 답한다
- **위반에는 이유가 있다** — 의도된 위반(trade-off)과 무지한 위반을 구분. 의도된 위반은 기록한다
- **점진적 개선** — 100% 준수가 아니라 가장 큰 위반부터 해소

## 원칙 카탈로그

`resources/` 아래에 원칙당 1파일. 각 파일은 frontmatter에 `category` 포함.

현재 등록된 원칙:

| 원칙 | 카테고리 | 한줄 요약 |
|------|----------|-----------|
| SRP | design | 클래스(모듈)는 변경의 이유가 하나여야 한다 |
| OCP | design | 확장에 열려 있고 수정에 닫혀 있어야 한다 |
| LoD | design | 직접 친구에게만 말하라 — a.b.c.d() 금지 |
| ORTHOGONALITY | design | A를 바꿔도 B에 영향이 없다 |
| COI | design | 상속보다 합성을 선호한다 |
| DIP | design | 고수준이 저수준에 의존하지 않는다. 둘 다 추상에 의존 |
| POLA | design | 이름을 보고 예상한 대로 동작해야 한다 |
| ENCAPSULATION | design | 내부를 숨기고 인터페이스만 노출한다 |
| LEAKY-ABSTRACTION | design | 모든 비자명 추상화는 어느 정도 누수된다 — 추상화는 공짜가 아니다 |
| TDA | design | 객체에게 상태를 물어서 판단하지 말고, 해야 할 일을 시켜라 |
| UL | design | 도메인 전문가와 개발자가 같은 언어를 쓴다. 코드가 곧 도메인 용어 |
| INTENTION-REVEALING-NAMES | design | 이름은 무엇을 하는지가 아니라 왜 존재하는지를 드러낸다 |
| SoC | architecture | 서로 다른 관심사를 섞지 않는다 |
| COHESION-COUPLING | architecture | 모듈 내부는 높은 응집, 모듈 간은 낮은 결합 |
| CONWAYS-LAW | architecture | 시스템 구조는 그 시스템을 만든 조직의 커뮤니케이션 구조를 따른다 |
| BC | architecture | 같은 단어도 맥락이 다르면 다른 모델이다. 경계를 명확히 긋는다 |
| GALLS-LAW | architecture | 작동하는 복잡한 시스템은 작동하는 단순한 시스템에서 진화한 것이다 |
| AMDAHLS-LAW | architecture | 병렬화로 얻는 속도 향상은 순차 구간의 비율에 의해 제한된다 |
| STRANGLER-FIG | architecture | 레거시를 한 번에 교체하지 않고, 새 시스템이 점진적으로 감싸면서 대체한다 |
| SSoT | architecture | 모든 사실은 단 하나의 권위 있는 출처를 가진다. 나머지는 모두 파생 |
| 12FACTOR-APP | architecture | 클라우드 네이티브 SaaS 12계명 — codebase·config·stateless·logs 등 |
| KISS | simplicity | 가장 단순한 해결책을 선택한다 |
| YAGNI | simplicity | 현재 필요하지 않은 기능을 구현하지 않는다 |
| DRY | simplicity | 모든 지식은 단 하나의 표현을 가져야 한다 |
| ROT | simplicity | 세 번 반복되면 추상화한다. 그 전에는 복붙이 낫다 |
| PREMATURE-OPTIMIZATION | simplicity | 측정 없이 최적화하지 마라. 97%는 잊고 결정적 3%에만 집중 (Knuth) |
| FAIL-FAST | process | 오류를 가능한 한 빨리 감지한다 |
| BOY-SCOUT | process | 코드를 발견했을 때보다 깨끗하게 남겨라 |
| CHESTERTONS-FENCE | process | 울타리가 왜 있는지 모르면 치우지 마라 |
| COMMENT-WHY | process | 주석은 코드가 답할 수 없는 WHY만 적는다. WHAT/HOW는 코드 자체로 |
| BROKEN-WINDOWS | process | 깨진 유리창을 방치하면 건물 전체가 망가진다. 시스템이 품질을 강제해야 한다 |
| TECHNICAL-DEBT | process | 의식적이고 신중한 차입은 건강하다. 인지되지 않은 부채가 위험 |
| GOODHARTS-LAW | process | 측정 지표가 목표가 되면, 좋은 지표가 아니게 된다 |
| BEYONCE-RULE | process | 중요하면 테스트로 보호하라. 테스트 없이 '깨지면 안 돼'는 의미 없다 |
| IDEMPOTENCY | process | 같은 작업을 여러 번 수행해도 결과가 동일하다 |
| COLLECTIVE-OWNERSHIP | process | 단 한 명만 만질 수 있는 코드는 부채. 모든 코드는 모두가 고칠 수 있어야 |
| DbC | contract | precondition·postcondition·invariant으로 모듈 간 계약을 명시한다 |
| LSP | contract | 하위 타입은 상위 타입의 계약을 깨지 않고 대체할 수 있어야 한다 |
| ISP | contract | 클라이언트가 사용하지 않는 메서드에 의존하지 않아야 한다 |
| CQS | contract | 메서드는 상태를 바꾸거나 값을 반환하거나, 둘 중 하나만 |
| POSTELS-LAW | contract | 보낼 때는 엄격하게, 받을 때는 관대하게 |
| UAP | contract | 저장된 속성이든 계산된 값이든 호출자에게 동일한 방식으로 접근한다 |
| HYRUMS-LAW | contract | API 사용자가 충분히 많으면, 명세에 없는 모든 관찰 가능한 동작에도 누군가 의존한다 |
| FIRST | testing | 테스트는 Fast·Independent·Repeatable·Self-validating·Timely해야 한다 |
| SELF-TESTING-CODE | testing | 테스트가 빌드와 결합되어 변경마다 자동 실행되어야 한다 (Fowler) |
| TEST-BEHAVIOR | testing | 구현이 아니라 관찰 가능한 행위를 테스트하라 — fragile test 방지 |
| TEST-PYRAMID | testing | 단위 많이, 통합 적당, E2E 소수 — 역피라미드(아이스크림 콘) 회피 |
| DAMP | testing | 테스트에서는 DRY보다 Descriptive And Meaningful Phrases가 우선 |
| TEST-SMELLS | testing | 테스트 안티패턴 10종 카탈로그 (Eager/Mystery Guest/Dead Test 등) |
| UNIX-PHILOSOPHY | tooling | 하나만 잘하기 + 조합 가능 + 텍스트 스트림. CLI·도구 설계의 기둥 |
| CONVENTION-OVER-CONFIG | tooling | 합리적 기본값으로 90% 해결, 벗어날 때만 설정 |
| PROGRESSIVE-DISCLOSURE | tooling | 초보엔 단순, 전문가엔 강력 — 복잡도를 필요한 사람에게만 |
| 12FACTOR-CLI | tooling | 모던 CLI UX 12계명 — help·flags·streams·errors·XDG 등 |

원칙 추가 시 `resources/{NAME}.md`를 생성하고 이 테이블을 갱신한다.

## Instructions

### 모드 1: `catalog` — 원칙 열람

`/principles catalog` 또는 `/principles catalog SRP`

1. 인자 없으면 위 테이블 출력
2. 카테고리 지정 시 해당 카테고리 원칙만 필터
3. 원칙명 지정 시 `resources/{NAME}.md`를 Read하여 상세 출력

### 모드 2: `check <principle>` — 단건 점검

`/principles check SRP` 또는 `/principles check OCP src/`

1. `resources/{principle}.md`를 Read → 스코어링 기준 로드
2. 대상 식별: 경로 지정 시 해당 파일/디렉토리, 없으면 `git diff`
3. 기계적 검증 항목은 실제 도구로 측정 (wc, grep, ast-grep 등)
4. 판단 필요 항목은 코드를 읽고 평가
5. 스코어링 기준에 따라 PASS/WARN/FAIL 판정

출력 형식:
```
## {원칙명} 점검

### 판정: {PASS | WARN | FAIL}

#### 기계적 검증
| 항목 | 임계값 | 측정값 | 결과 |
|------|--------|--------|------|
| 파일 행 수 | <300 | 245 | PASS |
| import 수 | <10 | 12 | FAIL |

#### 판단 평가
- {관찰}: {근거}

#### 개선안
1. {구체적 제안} — {관련 스킬}

#### 의도된 위반?
{trade-off 설명 또는 N/A}
```

### 모드 3: `evaluate` — 종합 평가 (기본 모드)

`/principles evaluate` 또는 `/principles evaluate src/`

인자 없이 호출하면 이 모드로 진입한다.

#### Step 1: 대상 식별

| 입력 | 대상 |
|------|------|
| 경로 지정 | 해당 파일/디렉토리 |
| 없음 | `git diff --cached` → `git diff` → 현재 디렉토리 |

#### Step 2: 원칙 선별

등록된 모든 원칙의 frontmatter를 확인하여, 대상에 관련된 원칙만 선별한다.

**테스트 파일 감지 시 우선 선별**: 대상 경로가 아래 패턴에 해당하면 testing 카테고리 원칙(FIRST, TEST-BEHAVIOR, TEST-PYRAMID, DAMP, TEST-SMELLS, BEYONCE-RULE)을 우선 평가한다:
- `*_test.*`, `*_spec.*`, `*.test.*`, `*.spec.*`, `test_*.*`
- `tests/`, `__tests__/`, `spec/` 디렉토리 내
- 프레임워크 import: `pytest`, `unittest`, `jest`, `vitest`, `@testing-library`, `RSpec`, `testing.T`, `#[test]`

#### Step 3: 각 원칙별 check 실행

선별된 원칙에 대해 모드 2(check)를 순차 실행한다.

#### Step 4: 스코어카드 출력

```markdown
## 원칙 스코어카드

| 원칙 | 카테고리 | 판정 | 근거 (1줄) |
|------|----------|------|-----------|
| SRP | design | PASS | 각 모듈이 단일 책임 |
| OCP | design | WARN | switch 2곳, 변경 빈도 낮음 |

### 요약
- PASS: N개 / WARN: M개 / FAIL: K개
- **가장 시급한 개선**: {FAIL 중 영향도 가장 큰 항목}
- **가장 큰 강점**: {PASS 중 의미 있는 항목}

### 개선 로드맵 (FAIL → WARN 순)
1. {항목}: {구체적 개선 방법} — {관련 스킬}
```

## 테스트 설계 시 사용

테스트 코드를 **쓰기 전** / **쓴 후**로 나눠 적용한다.

### 쓰기 전 (설계 체크)

```
테스트 대상 식별
  └─ BEYONCE-RULE: 이것이 보호할 만큼 중요한가?
  └─ TEST-PYRAMID: 이 검증을 가장 낮은 레벨에서 할 수 있는가?

검증 방식 설계
  └─ TEST-BEHAVIOR: 행위를 검증하는가, 구현을 검증하는가?
  └─ FIRST: 이 테스트가 Independent, Repeatable, Fast한가?
```

### 쓴 후 (품질 리뷰)

```
개별 테스트
  └─ DAMP: 이 테스트 하나만 읽어서 이해되는가?
  └─ TEST-SMELLS: 10종 안티패턴 중 해당되는 것이 있는가?
  └─ FIRST Self-validating: assert가 의미 있게 검증하는가?

테스트 스위트
  └─ TEST-PYRAMID: 단위/통합/E2E 비율이 피라미드인가?
  └─ BEYONCE-RULE: Happy/Edge/Error 균형이 있는가?
```

### 설계 시 체크리스트 소환

`/principles check FIRST` 혹은 `/principles check TEST-BEHAVIOR` 등으로 단건 소환하면 각 원칙 파일의 "설계 시 체크리스트" 섹션을 출력한다.

빠른 설계 승인:
```
/principles evaluate tests/new_feature_test.py
```

## 다른 스킬과의 연동

| 스킬 | 관계 |
|------|------|
| `code-review` (test-review) | 테스트 원칙 기준을 여기로 위임. 수행 로직(Glob/감지/리포트)은 test-review에 유지 |
| `plan-review tdd` | TDD 작성 전 FIRST/TEST-BEHAVIOR 체크, 작성 후 DAMP/TEST-SMELLS 리뷰 |
| `qa` | 자동화 테스트 품질은 여기. QA 자체는 수동 체크리스트 |
| `refactoring` | Characterization Test 품질(Sensitive Equality 주의)은 여기 참조 |
| `design-first` | 설계 단계에서 원칙 체크리스트로 활용 |
| `tidy` | tidying 대상 선정 시 원칙 위반 순위 참조 |

## Examples

### Example 1: 단건 점검
```
User: /principles check SRP src/services/payment.py
→ resources/SRP.md 로드
→ wc -l: 450줄 (FAIL), import 수: 8 (PASS), public 메서드: 12 (FAIL)
→ 판단: 결제+환불+정산 3가지 책임 혼재
→ FAIL — Extract Class 제안
```

### Example 2: 종합 평가
```
User: /principles evaluate
→ git diff 기준 변경 파일 식별
→ SRP, OCP 순차 check
→ 스코어카드 출력 (PASS 1, WARN 1)
```

### Example 3: 카탈로그 열람
```
User: /principles catalog design
→ design 카테고리 원칙 목록 출력: SRP, OCP
```
