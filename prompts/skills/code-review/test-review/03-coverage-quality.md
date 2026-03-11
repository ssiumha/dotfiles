
# 커버리지 품질 분석

커버리지 **수치**가 아닌 **질적** 측면을 분석한다. 100% 커버리지도 무의미할 수 있다.

---

## 핵심 원칙

> 커버리지 수치는 "테스트되지 않은 코드"를 찾는 도구이지, "잘 테스트된 코드"의 증거가 아니다.

---

## 1. 의미 있는 Assert vs 피상적 Assert

### 피상적 Assert (거짓 커버리지)

코드가 실행되지만 결과를 제대로 검증하지 않는 테스트:

```python
# ❌ 피상적 — 호출만 하고 결과 미검증
def test_process_order():
    result = process_order(order)
    assert result is not None              # None만 아니면 통과

# ❌ 피상적 — 타입만 검증
def test_get_users():
    users = get_users()
    assert isinstance(users, list)         # 빈 리스트도 통과

# ✅ 의미 있는 Assert
def test_process_order_calculates_total():
    order = Order(items=[Item("book", 10000)])
    result = process_order(order)
    assert result.total == 10000
    assert result.status == "processed"
```

**감지 힌트**:
```
# 피상적 assert 패턴
Grep: assert .* is not None
Grep: assert isinstance
Grep: assert len\(.+\) > 0
Grep: expect\(.+\)\.toBeDefined
Grep: expect\(.+\)\.toBeTruthy
```

### 판단 기준

| 수준 | 설명 | 심각도 |
|------|------|:---:|
| 값 검증 | 구체적 값 또는 속성 비교 | OK |
| 상태 검증 | 상태 변화 확인 | OK |
| 존재 검증만 | `not None`, `isDefined` | Medium |
| 타입 검증만 | `isinstance`, `typeof` | Medium |
| Assert 없음 | 호출만 하고 끝 | High |

---

## 2. Happy Path 편중 vs Edge/Error Case 균형

### 분석 방법

구현 코드의 분기점(if, switch, try/except)과 테스트를 대조한다:

```python
# 구현 코드
def divide(a, b):
    if b == 0:
        raise ValueError("division by zero")
    if a < 0 or b < 0:
        return abs(a) / abs(b)           # 음수 처리
    return a / b
```

**필요한 테스트**:
- ✅ Happy path: `divide(6, 3) == 2`
- ⚠️ Edge: `divide(-6, 3)` — 음수 처리
- ⚠️ Error: `divide(6, 0)` — 예외 발생
- ⚠️ Edge: `divide(0, 3)` — 0 나누기

### 균형 판단

| 비율 | 평가 |
|------|------|
| Happy 100% | ❌ Edge/Error 완전 누락 |
| Happy 70% + Edge/Error 30% | ⚠️ 기본은 되나 보완 필요 |
| Happy 50% + Edge 25% + Error 25% | ✅ 균형 잡힘 |

---

## 3. Branch 커버리지 관점

Line 커버리지보다 Branch 커버리지가 더 의미 있다.

### Line vs Branch

```python
def get_status(user):
    if user.is_active and user.has_subscription:    # 분기
        return "premium"
    return "basic"
```

- **Line 커버리지 100%**: `user(active=True, sub=True)` + `user(active=False, sub=False)` → 모든 줄 실행
- **Branch 커버리지**: `active=True, sub=False` 경로 미커버 (조건 조합)

### 확인 포인트

| 패턴 | 확인 내용 |
|------|----------|
| `if A and B` | A=True/B=False 조합 테스트됐는가 |
| `if A or B` | A=False/B=True 조합 테스트됐는가 |
| `try/except` | except 분기 테스트됐는가 |
| `switch/match` | 모든 case + default 테스트됐는가 |
| 삼항 연산자 | 양쪽 결과 테스트됐는가 |
| early return | return 전후 경로 모두 테스트됐는가 |

---

## 4. Dead Test 감지

> smell 관점은 `01-test-smell-catalog.md` #10 참조. 여기서는 커버리지 왜곡 관점에서 분류한다.

실행은 되지만 가치가 없는 테스트:

| 유형 | 설명 | 심각도 |
|------|------|:---:|
| Assert 없음 | 호출만 하고 검증 없음 | High |
| 항상 통과 | `assert True`, tautology | High |
| 중복 테스트 | 같은 것을 다른 이름으로 검증 | Low |
| Skip된 테스트 | 이유 없이 장기간 skip | Medium |
| 구현 변경 후 미갱신 | 이전 구현 기준으로 검증 | Medium |

---

## 5. Mutation Testing 사고실험

실제 mutation testing을 실행하지 않더라도, 코드를 읽으며 사고실험을 할 수 있다:

> "이 코드 한 줄을 바꾸면, 어떤 테스트가 실패할까?"

### 적용 방법

구현 코드의 핵심 로직을 보면서:

1. **연산자 변경**: `>` → `>=`, `+` → `-`, `and` → `or`
2. **반환값 변경**: `return True` → `return False`
3. **조건 제거**: `if` 블록 삭제
4. **상수 변경**: `timeout=30` → `timeout=0`

각 변경에 대해 실패하는 테스트가 있는지 확인한다.

### 판단

| 결과 | 의미 |
|------|------|
| 테스트 실패함 | ✅ 해당 로직이 적절히 커버됨 |
| 테스트 통과함 | ⚠️ 해당 로직을 실질적으로 검증하는 테스트 없음 |
| 확인 불가 | — 복잡한 경우 리포트에 의문점으로 기록 |

---

## 리포트 형식

```markdown
## 커버리지 품질

| 항목 | 상태 | 비고 |
|------|:---:|------|
| 의미 있는 assert | ✅/⚠️/❌ | 피상적 assert N건 |
| Happy/Edge/Error 균형 | ✅/⚠️/❌ | Edge case N건 누락 |
| Branch 커버리지 | ✅/⚠️/❌ | else 분기 미커버 N건 |
| Dead test | ✅/⚠️/❌ | assert 없는 테스트 N건 |
| Mutation 사고실험 | ✅/⚠️/❌ | 핵심 로직 미커버 N건 |
```
