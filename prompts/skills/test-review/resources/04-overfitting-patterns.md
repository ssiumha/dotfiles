
# Overfitting 패턴

테스트가 구현 세부사항에 과도하게 결합되어, 리팩토링 시 불필요하게 깨지는 패턴.
test-verifier의 6가지 패턴을 확장하고 Grep 감지 힌트를 추가한다.

---

## 1. 내부 상태 직접 접근

private/internal 속성이나 메서드를 직접 테스트한다.

- **심각도**: High
- **위험**: 내부 구현 변경 시 테스트가 깨지지만, 행위는 정상

```python
# ❌
def test_user_save():
    user = User()
    user.save()
    assert user._internal_flag == True     # 내부 상태 직접 확인
    assert user._dirty == False

# ✅
def test_user_save_persists():
    user = User(name="Alice")
    user.save()
    loaded = User.find_by_name("Alice")
    assert loaded.name == "Alice"          # 공개 API로 검증
```

**Grep 감지**:
```
\._[a-z_]+        # Python private 접근
\.internal[A-Z]    # internal 속성
\(.*as any\)       # TypeScript private 우회
\["_               # 딕셔너리 통한 private 접근
```

---

## 2. 과도한 Mock

3개 이상의 의존성을 Mock하여 실제 동작 검증이 불가능하다.

- **심각도**: Medium (3-4개), High (5개 이상)
- **위험**: 테스트가 Mock 설정만 검증, 실제 통합 동작 미검증

```python
# ❌ Mock 5개 — 실제 동작 검증 불가
@patch('module.payment')
@patch('module.email')
@patch('module.logger')
@patch('module.cache')
@patch('module.metrics')
def test_process(m1, m2, m3, m4, m5):
    service = OrderService()
    service.process(order)
    m1.charge.assert_called_once()

# ✅ 실제 의존성 사용 (또는 Fake)
def test_process_charges_payment():
    payment = FakePayment()
    service = OrderService(payment=payment)
    service.process(order)
    assert payment.charged_amount == order.total
```

**Grep 감지**:
```
@patch|@mock\.patch     # Python mock (파일당 count)
jest\.fn\(\)|jest\.mock  # Jest mock
sinon\.stub|sinon\.spy   # Sinon
vi\.fn\(\)|vi\.mock      # Vitest mock
```

---

## 3. Mock 호출 검증

Mock이 특정 인자로, 특정 횟수로 호출되었는지 검증한다.

- **심각도**: Medium
- **위험**: 내부 호출 방식 변경 시 깨지지만, 최종 결과는 동일

```python
# ❌ 호출 방식 검증
def test_send_notification():
    mock_sender = Mock()
    service = NotificationService(sender=mock_sender)
    service.notify(user, "hello")
    mock_sender.send.assert_called_once_with(
        to=user.email,
        subject="Notification",
        body="hello"
    )

# ✅ 최종 결과 검증
def test_send_notification():
    sender = FakeEmailSender()
    service = NotificationService(sender=sender)
    service.notify(user, "hello")
    assert len(sender.sent_emails) == 1
    assert sender.sent_emails[0].to == user.email
```

**Grep 감지**:
```
assert_called_with|assert_called_once_with   # Python
toHaveBeenCalledWith|toHaveBeenCalledTimes   # Jest/Vitest
calledWith|calledOnce|callCount              # Sinon
```

---

## 4. 하드코딩된 기대값

테스트에서 기대값이 하드코딩되어 있어 의도가 불명확하다.

- **심각도**: Low (명확한 경우), Medium (의도 불명확)
- **위험**: "왜 이 값인지" 모르면 유지보수 어려움

```python
# ❌ 하드코딩 — 의도 불명확
def test_calculate():
    result = calculate(5, 3)
    assert result == 8                     # 왜 8?

# ✅ 의도 명확
def test_addition_of_positive_numbers():
    assert calculate(5, 3) == 5 + 3        # 덧셈임을 명시

# ❌ 하드코딩 — 해시값
def test_hash():
    assert hash_password("secret") == "5ebe2294ecd0e0f08eab7690d2a6ee69"

# ✅ 속성 기반
def test_hash_is_deterministic():
    assert hash_password("secret") == hash_password("secret")

def test_hash_differs_for_different_inputs():
    assert hash_password("a") != hash_password("b")
```

---

## 5. 순서 의존적 테스트

테스트가 특정 실행 순서에 의존한다.

- **심각도**: High
- **위험**: 병렬 실행, 단독 실행 시 실패

**감지 방법**: 아래 패턴을 찾는다:
- 전역 변수 수정 후 다른 테스트에서 참조
- `setUp`에서 이전 테스트 결과에 의존
- 테스트 이름에 숫자 순서 (`test_1_create`, `test_2_update`)
- 공유 상태 (모듈 레벨 변수, 클래스 변수)

```python
# ❌ 순서 의존
class TestUserFlow:
    user = None

    def test_1_create(self):
        TestUserFlow.user = create_user()
        assert TestUserFlow.user.id

    def test_2_update(self):
        TestUserFlow.user.name = "Bob"    # test_1 결과에 의존
        TestUserFlow.user.save()

# ✅ 독립적
class TestUserOperations:
    def test_create_user(self):
        user = create_user()
        assert user.id

    def test_update_user_name(self):
        user = create_user()              # 각 테스트가 직접 생성
        user.name = "Bob"
        user.save()
        assert User.find(user.id).name == "Bob"
```

**Grep 감지**:
```
test_1_|test_2_|test_3_           # 번호 붙은 테스트명
cls\.|self\.__class__\.           # 클래스 변수 공유
global [a-z]                      # 전역 변수 수정
```

---

## 6. 구현 구조 미러링

테스트가 구현의 내부 구조를 그대로 반영한다.

- **심각도**: Medium
- **위험**: 리팩토링 시 테스트도 동일하게 수정 필요 → 테스트의 안전망 역할 상실

```python
# ❌ 구현 구조 미러링 — 구현의 각 단계를 그대로 검증
def test_process_order():
    order = create_order()
    # 구현의 step 1
    validated = validate_order(order)
    assert validated.is_valid
    # 구현의 step 2
    priced = calculate_price(validated)
    assert priced.total == 10000
    # 구현의 step 3
    saved = save_order(priced)
    assert saved.id is not None

# ✅ 행위 기반 — 최종 결과만 검증
def test_process_order():
    order = create_order(items=[Item("book", 10000)])
    result = process_order(order)
    assert result.id is not None
    assert result.total == 10000
    assert result.status == "processed"
```

---

## 종합 감지 전략

리뷰 시 아래 Grep을 순서대로 실행하여 빠르게 스캔한다:

```
# 1. Mock 과다 (파일당 count)
Grep: @patch|jest\.mock|vi\.mock|sinon (count mode)

# 2. Mock 호출 검증
Grep: assert_called|toHaveBeenCalled|calledWith

# 3. 내부 상태 접근
Grep: \._[a-z]|\(.*as any\)|\.internal

# 4. 순서 의존 힌트
Grep: test_[0-9]+_|global [a-z]|cls\.

# 5. 하드코딩 해시/토큰
Grep: assert.*==.*["'][a-f0-9]{32}|expect.*toBe.*["'][a-f0-9]{32}
```

각 감지 결과를 Overfitting 분석 테이블에 정리한다.
