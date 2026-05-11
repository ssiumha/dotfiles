---
name: BEYONCE-RULE
full_name: "Beyoncé Rule"
category: process
origin: Google Engineering Culture
one_liner: "중요하면 테스트로 보호하라. 테스트 없이 '깨지면 안 돼'는 의미 없다"
---

# BEYONCE-RULE — Beyoncé Rule

## 정의

> "If you liked it, then you should have put a test on it."

중요한 동작이라면 테스트로 보호해야 한다. "이건 절대 깨지면 안 돼"라고 말하면서 테스트가 없으면, 그건 소원이지 보호가 아니다. **테스트가 있는 것만 보장된다.** 테스트가 없으면 언제든 깨질 수 있고, 깨져도 아무도 모른다.

## 핵심 판단

- **"이 동작이 깨지면 문제인가?"** — 문제라면 테스트가 있어야 한다
- **"이 변경이 기존 동작을 깨뜨리는지 알 수 있는가?"** — 테스트 없이는 모른다
- **"이 코드의 중요 경로에 테스트가 있는가?"** — 없으면 Beyoncé Rule 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 결제/인증 등 핵심 경로에 테스트 없음 | 핵심 모듈의 테스트 커버리지 확인 |
| 변경 빈도 높은 파일에 테스트 없음 | git log 변경 빈도 vs 테스트 존재 여부 |
| 장애 이력 있는 모듈에 회귀 테스트 없음 | 장애 기록 vs 테스트 확인 |
| `// important: don't change this` 주석 | grep 경고성 주석 + 테스트 부재 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "이건 깨지면 큰일인데 테스트가 없어" | 핵심 동작 미보호 |
| "수동으로 확인해야 해" | 자동 검증 부재 |
| "리팩토링하고 싶은데 무서워" | 테스트 부재로 변경 공포 |
| 같은 버그가 반복 발생 | 회귀 테스트 미작성 |
| "배포하면 기도해야 해" | 테스트 커버리지 부족 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 핵심 경로에 테스트 존재, 장애 후 회귀 테스트 추가, 변경 시 테스트 동반 |
| **WARN** | 핵심 경로 일부만 테스트, 회귀 테스트 누락 있음 |
| **FAIL** | 핵심 경로에 테스트 없음 OR 장애 반복인데 회귀 테스트 없음 OR "기도 배포" |

## 무엇을 테스트해야 하는가

우선순위 기준:

```
반드시 테스트 (Beyoncé Rule 필수):
  1. 결제, 인증, 권한 — 비즈니스 크리티컬
  2. 이전에 장애가 났던 곳 — 회귀 테스트
  3. 변경 빈도 높은 곳 — 깨질 확률 높음
  4. 복잡한 비즈니스 로직 — 엣지 케이스 많음

테스트 있으면 좋음:
  5. 유틸리티 함수 — 순수 함수라 테스트 쉬움
  6. 데이터 변환 — 입출력이 명확
  
테스트 안 해도 됨:
  7. 단순 getter/setter — 타입 시스템으로 충분
  8. 프레임워크 기능 — 프레임워크가 테스트함
  9. 설정/상수 — 변경 시 빌드 에러로 감지
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 핵심 경로에 테스트 없음 | **Characterization Test** — 현재 동작을 먼저 기록하는 테스트 |
| 장애 발생 | **회귀 테스트 의무화** — 장애 수정 PR에 반드시 테스트 포함 |
| 리팩토링 공포 | **Golden Master Test** — 현재 출력을 스냅샷으로 보호 후 리팩토링 |
| 테스트 작성 부담 | **핵심 경로만 먼저** — 전부 테스트가 아니라 중요한 것부터 |
| "테스트할 시간이 없어" | **테스트 없이 머지 차단 (핵심 경로)** — 시스템으로 강제 |

## 테스트 품질 — "있기만 하면" 안 된다

Beyoncé Rule은 "**의미 있게 보호**"여야 한다. 아래 3축으로 품질을 검증한다.

### 1. 의미 있는 assert vs 피상적 assert

코드를 실행하되 결과를 제대로 검증하지 않는 테스트는 거짓 커버리지다.

```python
# ❌ 피상적 — 호출만 하고 결과 미검증
def test_process_order():
    result = process_order(order)
    assert result is not None              # None만 아니면 통과

# ❌ 피상적 — 타입만 검증
def test_get_users():
    users = get_users()
    assert isinstance(users, list)         # 빈 리스트도 통과

# ✅ 구체적 값·상태 검증
def test_process_order_calculates_total():
    order = Order(items=[Item("book", 10000)])
    result = process_order(order)
    assert result.total == 10000
    assert result.status == "processed"
```

| 수준 | 설명 | 심각도 |
|------|------|:---:|
| 값 검증 | 구체적 값/속성 비교 | OK |
| 상태 검증 | 상태 변화 확인 | OK |
| 존재 검증만 | `not None`, `isDefined` | Medium |
| 타입 검증만 | `isinstance`, `typeof` | Medium |
| Assert 없음 | 호출만 | High |

**Grep 힌트**:
```
assert .* is not None
assert isinstance
assert len\(.+\) > 0
expect\(.+\)\.toBeDefined|toBeTruthy
```

### 2. Happy/Edge/Error 균형

구현의 분기점(if, try/except, switch)마다 테스트가 있어야 한다.

```python
# 구현
def divide(a, b):
    if b == 0:
        raise ValueError("division by zero")
    if a < 0 or b < 0:
        return abs(a) / abs(b)
    return a / b
```

| 경우 | 필요 여부 |
|------|-----------|
| Happy: `divide(6, 3) == 2` | ✅ |
| Edge: `divide(-6, 3)` 음수 처리 | ✅ |
| Error: `divide(6, 0)` 예외 발생 | ✅ |
| Edge: `divide(0, 3)` 0 나누기 | ✅ |

**균형 판단**:

| 비율 | 평가 |
|------|------|
| Happy 100% | ❌ Edge/Error 완전 누락 |
| Happy 70% + Edge/Error 30% | ⚠️ 기본은 되나 보완 필요 |
| Happy 50% + Edge 25% + Error 25% | ✅ 균형 |

**Branch 커버리지 관점**:

```python
def get_status(user):
    if user.is_active and user.has_subscription:
        return "premium"
    return "basic"
```

- Line 커버리지 100%: `(active=T, sub=T)` + `(active=F, sub=F)` 두 테스트
- Branch 커버리지: `(active=T, sub=F)` 조합 미커버

조건별 확인:
- `if A and B` → A=T/B=F 조합 테스트됐는가
- `if A or B` → A=F/B=T 조합 테스트됐는가
- `try/except` → except 분기 테스트됐는가
- `switch/match` → 모든 case + default 테스트됐는가

### 3. Mutation Testing 사고실험

실제 mutation testing을 돌리지 않더라도, 코드를 읽으며 사고실험을 할 수 있다.

> "이 코드 한 줄을 바꾸면, 어떤 테스트가 실패할까?"

**적용 방법**:

1. **연산자 변경**: `>` → `>=`, `+` → `-`, `and` → `or`
2. **반환값 변경**: `return True` → `return False`
3. **조건 제거**: `if` 블록 삭제
4. **상수 변경**: `timeout=30` → `timeout=0`

| 결과 | 의미 |
|------|------|
| 테스트 실패함 | ✅ 해당 로직이 적절히 커버됨 |
| 테스트 통과함 | ⚠️ 해당 로직을 실질적으로 검증하는 테스트 없음 |

> 커버리지 수치가 높아도 mutation 통과율이 낮으면 Beyoncé Rule 위반 — "보호하는 척" |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[SELF-TESTING-CODE]] | Beyoncé가 "무엇을 보호할지" 결정, Self-Testing이 그 보호를 빌드/CI에 자동 강제하는 시스템. Beyoncé만 있고 Self-Testing 없으면 "테스트 있는데 아무도 안 돌림" |
| [[FAIL-FAST]] | 테스트는 fail-fast의 핵심 수단 |
| [[BROKEN-WINDOWS]] | 테스트 없는 코드 = 깨진 유리창. 방치하면 확산 |
| [[CHESTERTONS-FENCE]] | 테스트가 "울타리" 역할 — 테스트 없이 제거하면 위험 |
| [[GOODHARTS-LAW]] | "커버리지 80%"가 목표가 되면 의미 없는 테스트 양산. Beyoncé는 "중요한 것"에 집중 |
| [[DbC]] | 계약(pre/postcondition)을 테스트로 검증 |
| [[FIRST]] | Beyoncé가 "무엇을 보호할지", FIRST가 "어떻게 보호할지" |
| [[TEST-BEHAVIOR]] | 보호는 행위 기반이어야. 구현 기반 보호는 리팩토링 시 깨짐 |

## 주의

- Beyoncé Rule ≠ "모든 것을 테스트하라". 중요한 것을 테스트하라
- 100% 커버리지가 목표가 아니다. **0% 커버리지인 핵심 경로**가 문제
- 테스트의 질이 양보다 중요. assert 없는 테스트는 보호가 아니다
- E2E 테스트만으로는 부족. 단위 테스트가 더 빠르고 정확하게 문제를 잡는다 (Test Pyramid)
- "테스트 작성 비용"보다 "장애 비용"이 항상 크다
