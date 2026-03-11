
# Test Smell Catalog

10가지 대표적인 test smell 패턴. 각 smell의 정의, 감지 방법, 심각도, 예시를 포함한다.

---

## 1. Eager Test

하나의 테스트가 너무 많은 기능을 검증한다.

- **심각도**: Medium
- **감지**: 하나의 테스트에 assert 5개 이상, 또는 서로 다른 메서드를 여러 번 호출
- **위험**: 실패 시 원인 파악 어려움, 테스트 유지보수 비용 증가

```python
# ❌ Eager Test
def test_user_operations():
    user = create_user("Alice")
    assert user.name == "Alice"          # 생성 검증
    user.update_email("a@b.com")
    assert user.email == "a@b.com"       # 수정 검증
    user.deactivate()
    assert not user.is_active            # 비활성화 검증

# ✅ 분리
def test_create_user_sets_name():
    user = create_user("Alice")
    assert user.name == "Alice"

def test_update_email_changes_email():
    user = create_user("Alice")
    user.update_email("a@b.com")
    assert user.email == "a@b.com"
```

---

## 2. Mystery Guest

테스트가 외부 파일, DB, 환경변수 등 보이지 않는 데이터에 의존한다.

- **심각도**: Medium
- **감지**: 파일 경로 하드코딩, 환경변수 직접 참조, 외부 DB 데이터 가정
- **위험**: 환경에 따라 테스트 결과가 달라짐 (flaky)

```python
# ❌ Mystery Guest
def test_parse_config():
    config = parse_config("/etc/app/config.yaml")  # 파일 존재 가정
    assert config["db_host"] == "localhost"

# ✅ 인라인 데이터
def test_parse_config():
    yaml_content = "db_host: localhost\ndb_port: 5432"
    config = parse_config_from_string(yaml_content)
    assert config["db_host"] == "localhost"
```

---

## 3. Resource Optimism

테스트가 외부 리소스의 존재/상태를 낙관적으로 가정한다.

- **심각도**: Medium
- **감지**: 파일/디렉토리 존재 가정, 네트워크 연결 가정, 특정 포트 가용 가정
- **위험**: CI 환경 등에서 실패

```python
# ❌ Resource Optimism
def test_read_log():
    with open("/tmp/app.log") as f:      # 파일 존재 가정
        assert "ERROR" not in f.read()

# ✅ 리소스 직접 생성
def test_read_log(tmp_path):
    log_file = tmp_path / "app.log"
    log_file.write_text("INFO: started")
    assert "ERROR" not in log_file.read_text()
```

---

## 4. Test Run War

공유 리소스로 인해 병렬 실행 시 테스트 간 간섭이 발생한다.

- **심각도**: High
- **감지**: 전역 변수 수정, 공유 파일 쓰기, 같은 DB 테이블 사용 (격리 없이)
- **위험**: 순서 의존성, 비결정적 실패 (flaky)

```python
# ❌ Test Run War
counter = 0

def test_increment():
    global counter
    counter += 1
    assert counter == 1         # 다른 테스트가 먼저 실행되면 실패

def test_double_increment():
    global counter
    counter += 2
    assert counter == 2         # 실행 순서에 의존

# ✅ 격리
def test_increment():
    counter = 0
    counter += 1
    assert counter == 1

def test_double_increment():
    counter = 0
    counter += 2
    assert counter == 2
```

---

## 5. General Fixture

테스트에 필요하지 않은 데이터까지 포함하는 과도하게 큰 fixture.

- **심각도**: Low
- **감지**: setUp/beforeAll에서 10줄 이상의 데이터 생성, 대부분의 테스트가 fixture 일부만 사용
- **위험**: 테스트 의도 불명확, 불필요한 느림

```python
# ❌ General Fixture
@pytest.fixture
def setup_everything():
    user = create_user()
    order = create_order(user)
    payment = create_payment(order)
    shipping = create_shipping(order)
    review = create_review(user, order)
    return user, order, payment, shipping, review

def test_user_name(setup_everything):
    user, _, _, _, _ = setup_everything    # order, payment 등 불필요
    assert user.name == "Alice"

# ✅ 필요한 것만
@pytest.fixture
def user():
    return create_user()

def test_user_name(user):
    assert user.name == "Alice"
```

---

## 6. Sensitive Equality

깨지기 쉬운 동등성 비교 (toString, JSON 직렬화, 부동소수점 등).

- **심각도**: Medium
- **감지**: `str()`, `repr()`, `JSON.stringify()` 비교, float `==` 비교, 타임스탬프 직접 비교
- **위험**: 포맷 변경, 로케일 변경 등으로 깨짐

```python
# ❌ Sensitive Equality
def test_user_display():
    user = User("Alice", age=30)
    assert str(user) == "User(name=Alice, age=30)"    # repr 변경 시 깨짐

def test_calculation():
    assert calculate() == 0.30000000000000004          # 부동소수점

# ✅ 속성별 비교 / 근사값
def test_user_display():
    user = User("Alice", age=30)
    assert user.name == "Alice"
    assert user.age == 30

def test_calculation():
    assert calculate() == pytest.approx(0.3)
```

---

## 7. Slow Test

불필요하게 느린 테스트. 단위 테스트는 ms 단위여야 한다.

- **심각도**: Low (단일), Medium (다수)
- **감지**: `sleep()`, `time.sleep()`, 실제 네트워크 호출, 큰 데이터셋 생성
- **위험**: 피드백 루프 지연, 개발자가 테스트 실행을 회피

```python
# ❌ Slow Test
def test_retry_logic():
    time.sleep(3)                          # 불필요한 대기
    result = service.get_status()
    assert result == "ready"

# ✅ 시간 추상화
def test_retry_logic(fake_clock):
    fake_clock.advance(seconds=3)
    result = service.get_status()
    assert result == "ready"
```

---

## 8. Conditional Logic

테스트 내에 if/else, for, while 등 조건/반복 로직이 있다.

- **심각도**: Medium
- **감지**: 테스트 함수 내 `if`, `for`, `while`, 삼항 연산자
- **위험**: 테스트 자체에 버그 발생 가능, 실패 원인 불명확

```python
# ❌ Conditional Logic
def test_discounts():
    for rate in [0, 10, 50, 100]:
        result = calculate_discount(rate)
        if rate > 50:
            assert result == "invalid"
        else:
            assert result > 0

# ✅ Parametrize
@pytest.mark.parametrize("rate,expected", [
    (0, 1000), (10, 900), (50, 500),
])
def test_valid_discount(rate, expected):
    assert calculate_discount(rate) == expected

def test_over_50_is_invalid():
    assert calculate_discount(100) == "invalid"
```

---

## 9. Obscure Test

테스트의 의도를 파악하기 어렵다. 이름, 구조, 주석 모두 불명확.

- **심각도**: Low
- **감지**: `test_1`, `test_a` 등 의미 없는 이름, assert 메시지 없음, 매직 넘버
- **위험**: 유지보수 시 "이 테스트가 왜 있지?" 의문

```python
# ❌ Obscure Test
def test_1():
    assert foo(42) == 84

# ✅ 명확한 의도
def test_double_returns_twice_the_input():
    assert double(42) == 84
```

---

## 10. Dead Test

실행되지 않거나 의미 없는 테스트. 커버리지 품질 왜곡의 주범.

- **심각도**: High
- **감지**: `@skip`, `pass`만 있는 테스트, 주석 처리된 테스트, 항상 통과하는 assert
- **위험**: 거짓 안심감 제공, 커버리지 수치 왜곡

> 상세 유형별 분류와 Grep 감지 힌트는 `03-coverage-quality.md` §4 참조

```python
# ❌ Dead Test — skip
@pytest.mark.skip(reason="TODO")
def test_important_feature():
    ...

# ❌ Dead Test — 항상 통과
def test_something():
    assert True
```
