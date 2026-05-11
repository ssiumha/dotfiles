---
name: DAMP
full_name: "Descriptive And Meaningful Phrases"
category: testing
origin: Jay Fields (*Working Effectively with Unit Tests*, 2014), 초기 언급은 Yegge의 블로그
one_liner: "테스트 코드에서는 DRY보다 가독성 — 각 테스트를 혼자 읽고 이해할 수 있어야 한다"
---

# DAMP — Descriptive And Meaningful Phrases

## 정의

> "DAMP not DRY."
> "Tests are specifications. A spec read as running prose beats a spec hidden behind indirection."

프로덕션 코드에서는 DRY가 좋지만, **테스트 코드에서는 다르다**. 테스트는 실행되는 명세(specification)다. 테스트 한 개를 읽으면 그 한 개만으로 **무엇을 검증하는지, 실패 시 원인이 무엇인지** 이해할 수 있어야 한다. DRY로 헬퍼·픽스처·베이스 클래스에 흩뿌리면 매번 추적해야 한다.

## 핵심 판단

- **"이 테스트 하나만 봐서 실패 원인을 이해할 수 있는가?"** → 아니면 DAMP 위반
- **"입력값·기대값이 테스트 안에 보이는가, 헬퍼 안에 숨었는가?"** → 숨었으면 위반
- **"테스트 이름만 보고 무엇을 검증하는지 알 수 있는가?"** → 아니면 DAMP 위반

## DRY vs DAMP — 어디에 무엇을 적용하나

| 항목 | 프로덕션 코드 | 테스트 코드 |
|------|---------------|------------|
| 중복 허용도 | 낮음 (DRY) | **높음 (DAMP)** |
| 핵심 가치 | 유지보수성 | **독해성** |
| 추상화 | 적극 추출 | **보수적 추출** |
| 판단 기준 | "변경 시 여러 곳 바꿔야 하면 중복" | "읽을 때 추적해야 하면 과도한 추상화" |

> DRY가 틀린 것이 아니라 **적용 층위가 다르다**. 상세는 `resources/DRY.md`.

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| 헬퍼 메서드 깊이 3단+ | `setupUser()` → `buildUser()` → `defaultUserData()` 추적 |
| 테스트 함수 내 로직 부재 (셋업만 `setUp`에 전부) | 테스트 본문이 "helper 한 줄 + assert 한 줄" |
| 매직 넘버/문자열 외부 상수 참조 | `assert result == EXPECTED_TOTAL` (값이 어디?) |
| 테스트 이름이 `test_1`, `test_a` | grep 무의미 이름 |

### 판단 필요

| 신호 | 설명 |
|------|------|
| "이 테스트가 왜 실패했는지 모르겠어" | Obscure Test |
| 테스트 읽고 구현 코드로 점프해야 이해됨 | 의도 불명확 |
| 공유 fixture 하나에 수십 개 테스트가 매달림 | General Fixture |
| 헬퍼 수정했더니 무관해 보이는 테스트가 깨짐 | 과도한 DRY의 역효과 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 테스트 이름이 설명적, AAA 구조 명확, 핵심 값이 테스트 안에 명시 |
| **WARN** | 헬퍼 2단 이상 의존, 일부 테스트가 외부 상수에 의존, 이름 일부 불명확 |
| **FAIL** | 공유 fixture에 과도 의존, 헬퍼 3단+ 일반화, 테스트명이 동작 미설명 |

## 개선 패턴

### 1. 인라인 데이터 우선

```python
# ❌ DRY 과도 — 값이 어디 있는지 불명
DEFAULT_USER_DATA = {"name": "Alice", "age": 30, "email": "a@b.com"}

def test_user_creation():
    user = create_user(DEFAULT_USER_DATA)
    assert user.is_valid()

# ✅ DAMP — 필요한 값이 테스트 안에
def test_user_creation_with_valid_data():
    user = create_user({"name": "Alice", "age": 30, "email": "a@b.com"})
    assert user.is_valid()
```

### 2. 최소한의 fixture

```python
# ❌ General Fixture
@pytest.fixture
def setup_everything():
    user = create_user()
    order = create_order(user)
    payment = create_payment(order)
    return user, order, payment

def test_user_name(setup_everything):
    user, _, _ = setup_everything    # order, payment 불필요
    assert user.name == "Alice"

# ✅ 필요한 것만
@pytest.fixture
def user():
    return create_user(name="Alice")

def test_user_name(user):
    assert user.name == "Alice"
```

### 3. 서술적 이름

```python
# ❌
def test_1(): ...
def test_user(): ...
def test_foo_42(): ...

# ✅ {대상}_{상황}_{결과}
def test_double_returns_twice_the_input(): ...
def test_login_with_invalid_password_raises(): ...
def test_discount_is_capped_at_50_percent(): ...
```

### 4. AAA 구조 드러내기

```python
def test_apply_coupon_reduces_total():
    # Arrange
    cart = Cart(items=[Item("book", 10000)])
    coupon = Coupon(rate=0.1)

    # Act
    cart.apply_coupon(coupon)

    # Assert
    assert cart.total == 9000
```

### 5. Eager Test 분리

하나의 테스트 함수에 여러 시나리오를 몰아넣지 않는다 → TEST-SMELLS 참조.

## 테스트는 명세다

좋은 테스트 스위트는 **테스트 이름만으로 도메인 명세**가 된다:

```
test_order:
  - test_create_order_with_empty_cart_raises
  - test_apply_coupon_reduces_total
  - test_coupon_over_50_percent_is_invalid
  - test_cancelled_order_refunds_payment
  - test_cancelled_order_sends_notification
```

각 이름이 요구사항 한 줄에 매핑된다. 이는 코드베이스에 대한 실행 가능한 문서다.

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| DRY | 상충 관계. 테스트에서는 DAMP 우선. 구현에서는 DRY 우선 |
| KISS | DAMP는 KISS의 테스트 버전 — 읽기 쉬운 게 가장 간단하다 |
| TEST-SMELLS | Obscure Test, General Fixture는 DAMP 위반의 전형적 증상 |
| UL (Ubiquitous Language) | 서술적 이름은 도메인 언어와 일치해야 한다 |
| POLA | 테스트도 "이름 보고 예상한 대로 검증"해야 한다 |

## 주의

- DAMP ≠ "무조건 복붙". 3번 이상 반복되는 **정말 같은** setup은 헬퍼로 빼도 된다 (Rule of Three)
- 픽스처 자체가 나쁜 게 아니다. **테스트가 이해하려면 픽스처를 열어봐야 하는 상황**이 문제
- 헬퍼는 "부차적 세팅"만 숨긴다 (데이터베이스 준비 등). **검증의 핵심 값**은 테스트에 노출
- 테스트 코드에 약간의 중복이 있어도 괜찮다 — 프로덕션 코드보다 훨씬 덜 자주 바뀐다
