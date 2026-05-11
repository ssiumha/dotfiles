---
name: TEST-BEHAVIOR
full_name: "Test Behavior, Not Implementation"
category: testing
origin: Kent Beck (*Test-Driven Development: By Example*, 2002), Steve Freeman & Nat Pryce (*Growing Object-Oriented Software Guided by Tests*, 2009), Martin Fowler
one_liner: "구현이 아니라 관찰 가능한 행위를 테스트하라 — What, not How"
---

# TEST-BEHAVIOR — 행위 검증 우선

## 정의

> "Test what, not how."
> "Tests should fail only when behavior changes, not when implementation changes."

테스트는 **외부에서 관찰 가능한 행위**(입력→출력, 상태 변화, 이벤트 발생)를 검증해야 한다. 내부 구현(private 메서드, 내부 상태, 호출 순서)을 검증하면, **리팩토링만 해도 테스트가 깨진다**. 이것이 fragile test의 근본 원인이다.

## 핵심 판단

세 가지 질문으로 판정한다:

1. **"구현을 바꿨는데 동작이 같다면, 이 테스트는 통과해야 하는가?"** → 그렇다면 OK. 아니면 구현에 결합
2. **"이 테스트가 깨졌을 때, 진짜 기능이 깨진 것인가?"** → 그렇다면 OK. 리팩토링만으로 깨지면 위반
3. **"외부 사용자가 이 동작에 의존하는가?"** → 그렇다면 테스트할 가치 있음. 내부 상세면 테스트할 필요 없음

## 위반 패턴 6종

기존 code-review의 overfitting 6 패턴을 행위 검증 관점으로 통합.

### 1. 내부 상태 직접 접근 (심각도: High)

private/internal 속성이나 메서드를 테스트한다.

```python
# ❌
def test_user_save():
    user = User()
    user.save()
    assert user._internal_flag == True     # private 상태
    assert user._dirty == False

# ✅ public API로 검증
def test_user_save_persists():
    user = User(name="Alice")
    user.save()
    loaded = User.find_by_name("Alice")
    assert loaded.name == "Alice"
```

**Grep 감지**: `\._[a-z_]+`, `\.internal[A-Z]`, `\(.*as any\)`, `\["_`

### 2. 과도한 Mock (심각도: Medium 3-4개, High 5개+)

3개 이상 의존성을 Mock하면 실제 동작이 검증되지 않는다.

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

# ✅ 실제 또는 Fake
def test_process_charges_payment():
    payment = FakePayment()
    service = OrderService(payment=payment)
    service.process(order)
    assert payment.charged_amount == order.total
```

**Grep 감지**: `@patch|@mock\.patch`, `jest\.fn\(\)|jest\.mock`, `sinon\.stub|sinon\.spy`, `vi\.fn\(\)|vi\.mock` (파일당 count)

### 3. Mock 호출 검증 (심각도: Medium)

Mock이 어떻게 호출되었는지(인자, 횟수)를 검증한다. 내부 협력 방식에 결합된다.

```python
# ❌ 호출 방식 검증
def test_send_notification():
    mock_sender = Mock()
    service = NotificationService(sender=mock_sender)
    service.notify(user, "hello")
    mock_sender.send.assert_called_once_with(
        to=user.email, subject="Notification", body="hello"
    )

# ✅ 최종 결과 검증
def test_send_notification():
    sender = FakeEmailSender()
    service = NotificationService(sender=sender)
    service.notify(user, "hello")
    assert len(sender.sent_emails) == 1
    assert sender.sent_emails[0].to == user.email
```

**Grep 감지**: `assert_called|toHaveBeenCalled|calledWith|callCount`

### 4. 하드코딩된 기대값 — 의도 불명확 (심각도: Low~Medium)

```python
# ❌ 왜 84? 왜 이 해시값?
def test_1():
    assert foo(42) == 84
def test_hash():
    assert hash_password("secret") == "5ebe2294ecd0e0f08eab7690d2a6ee69"

# ✅ 속성/법칙 기반
def test_double_returns_twice_input():
    assert double(42) == 42 * 2
def test_hash_is_deterministic():
    assert hash_password("secret") == hash_password("secret")
def test_hash_differs_for_different_inputs():
    assert hash_password("a") != hash_password("b")
```

### 5. 순서 의존적 테스트 (심각도: High)

여러 테스트가 같은 상태를 공유하며, 특정 순서로만 성공한다.

```python
# ❌
class TestUserFlow:
    user = None
    def test_1_create(self):
        TestUserFlow.user = create_user()
    def test_2_update(self):
        TestUserFlow.user.name = "Bob"  # test_1 성공에 의존

# ✅ 각 테스트가 독립적으로 상태 준비
def test_create_user():
    user = create_user()
    assert user.id

def test_update_user_name():
    user = create_user()
    user.name = "Bob"; user.save()
    assert User.find(user.id).name == "Bob"
```

> 순서 의존은 FIRST (Independent)와도 겹친다. 원인이 "내부 상태 공유"면 TEST-BEHAVIOR, "전역 상태 관리 부재"면 FIRST 관점.

### 6. 구현 구조 미러링 (심각도: Medium)

테스트가 구현의 단계별 내부 구조를 그대로 반영한다.

```python
# ❌ 구현 step을 따라가며 검증
def test_process_order():
    order = create_order()
    validated = validate_order(order)      # step 1
    assert validated.is_valid
    priced = calculate_price(validated)    # step 2
    assert priced.total == 10000
    saved = save_order(priced)             # step 3
    assert saved.id is not None

# ✅ 최종 행위
def test_process_order():
    order = create_order(items=[Item("book", 10000)])
    result = process_order(order)
    assert result.id is not None
    assert result.total == 10000
    assert result.status == "processed"
```

## 추가 안티패턴: 과도한 상세 (통합/E2E)

통합 테스트에서 구현의 세부(SQL 컬럼 인덱스, 내부 로그 형식)를 검증하는 것도 같은 위반.

```python
# ❌ SQL 컬럼 인덱스에 결합
def test_create_user(client, db):
    client.post("/users", json={"name": "Alice"})
    result = db.execute("SELECT * FROM users WHERE name = 'Alice'")
    assert result.fetchone()[2] == "Alice"

# ✅ API 계약 검증
def test_create_user(client):
    response = client.post("/users", json={"name": "Alice"})
    assert response.status_code == 201
    assert response.json()["name"] == "Alice"
```

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | High 위반(내부 상태 접근, Mock 5개+, 순서 의존) 0건, Medium 위반 <10% |
| **WARN** | High 위반 1-2건 OR Medium 위반 10-25% |
| **FAIL** | High 위반 3건+ OR 테스트 대부분이 Mock 호출 검증 위주 OR 구현 구조 미러링 전반 |

## 설계 시 체크리스트

새 테스트를 쓰기 전:

- [ ] 이 테스트가 검증하는 것은 **외부에서 관찰 가능한가**?
- [ ] private/internal 접근이 필요한가? → 필요하면 설계를 다시 본다
- [ ] Mock이 4개 이상인가? → 테스트 대상이 너무 많은 협력자를 가진 것일 수 있음 (SRP 위반)
- [ ] `assert_called_with` 같은 호출 검증에 의존하는가? → 결과 검증으로 바꿀 수 있는지 검토
- [ ] 하드코딩 숫자/문자열에 **의도**가 있는가?

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| ENCAPSULATION | 내부 상태 접근 = 캡슐화 위반. 테스트가 캡슐화 깨는 것을 강제하면 설계가 잘못된 것 |
| LSP / DbC | 행위 기반 테스트 = 계약(precondition/postcondition) 검증 |
| HYRUMS-LAW | public 관찰값에 의존하는 건 피할 수 없지만, 내부에 의존하는 건 선택 |
| SRP | Mock이 많다 = 협력자가 많다 = 단일 책임 위반 가능성 |
| FIRST | 순서 의존은 Independent도 위반. 두 원칙이 같은 증상을 다른 각도로 본다 |
| TEST-SMELLS | Sensitive Equality, Fragile Test와 직접 연결 |

## 주의

- "구현을 바꿨는데 테스트도 같이 바뀐" 경험 = 이 원칙 위반의 가장 명확한 신호
- Mock 자체가 나쁜 게 아니다. **경계(외부 시스템)에서의 Mock**은 필요. 내부 협력자 Mock이 문제
- Characterization Test는 예외 — 레거시 코드의 현재 행위를 기록해야 하므로 의도적으로 구현에 밀착
- TDD는 이 원칙의 자연스러운 구현 방식 (테스트를 먼저 쓰면 구현 상세에 결합할 수 없다)
