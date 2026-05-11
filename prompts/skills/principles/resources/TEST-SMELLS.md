---
name: TEST-SMELLS
full_name: "Test Smell Catalog"
category: testing
origin: Gerard Meszaros *xUnit Test Patterns* (2007), 확장은 Arie van Deursen et al., 실무 정리
one_liner: "유지보수 불가능한 테스트를 만드는 10가지 안티패턴 — 원인과 처방 카탈로그"
---

# TEST-SMELLS — 테스트 안티패턴 카탈로그

## 정의

테스트 스위트가 썩어가는 전형적 패턴. Meszaros의 xUnit 스멜을 실무에서 자주 마주치는 10가지로 정리한다. 각 스멜은 **증상(smell)** 이지 원인(root cause)이 아니다 — 스멜을 발견하면 원칙(FIRST, TEST-BEHAVIOR, DAMP) 중 어느 것을 위반했는지 추적한다.

## 핵심 판단

- **"이 테스트가 왜 이 모양인가?"** — 스멜 분류 → 원인 원칙 추적 → 처방
- **"스멜을 방치하면?"** — BROKEN-WINDOWS. 하나 썩으면 전체가 썩는다

---

## 10가지 스멜

### 1. Eager Test — 한 테스트에 여러 시나리오

한 테스트 함수가 너무 많은 것을 검증한다.

- **심각도**: Medium
- **감지**: assert 5개+, 서로 다른 메서드를 여러 번 호출
- **원인**: 단일 관심사 분리 실패 (SRP 원리의 테스트 적용)
- **위험**: 실패 시 원인 파악 어려움, 첫 실패에서 멈춰 나머지 미검증

```python
# ❌
def test_user_operations():
    user = create_user("Alice")
    assert user.name == "Alice"
    user.update_email("a@b.com")
    assert user.email == "a@b.com"
    user.deactivate()
    assert not user.is_active

# ✅ 분리
def test_create_user_sets_name():
    user = create_user("Alice")
    assert user.name == "Alice"

def test_update_email_changes_email():
    user = create_user("Alice")
    user.update_email("a@b.com")
    assert user.email == "a@b.com"
```

### 2. Mystery Guest — 외부 데이터에 숨어 의존

테스트가 외부 파일, DB, 환경변수 등 **테스트 코드에 보이지 않는** 데이터에 의존한다.

- **심각도**: Medium
- **감지**: 파일 경로 하드코딩, 환경변수 직접 참조, 외부 DB 데이터 가정
- **원인**: 입력 데이터가 테스트 내부에 없음 (DAMP 위반)
- **위험**: 환경 따라 결과 다름, 읽는 사람이 외부 파일을 찾아가야 함

```python
# ❌
def test_parse_config():
    config = parse_config("/etc/app/config.yaml")
    assert config["db_host"] == "localhost"

# ✅ 인라인 데이터
def test_parse_config():
    yaml_content = "db_host: localhost\ndb_port: 5432"
    config = parse_config_from_string(yaml_content)
    assert config["db_host"] == "localhost"
```

### 3. Resource Optimism — 리소스 존재를 낙관적으로 가정

외부 리소스가 항상 거기 있고, 접근 가능하다고 가정한다.

- **심각도**: Medium
- **감지**: 파일/디렉토리 존재 가정, 네트워크 연결 가정, 특정 포트 가용 가정
- **원인**: 테스트 격리 부족 (FIRST Repeatable 위반)
- **위험**: CI/다른 환경에서 실패

```python
# ❌
def test_read_log():
    with open("/tmp/app.log") as f:
        assert "ERROR" not in f.read()

# ✅ 리소스 직접 생성
def test_read_log(tmp_path):
    log_file = tmp_path / "app.log"
    log_file.write_text("INFO: started")
    assert "ERROR" not in log_file.read_text()
```

### 4. Test Run War — 병렬 실행 시 간섭

공유 리소스(전역 변수, 파일, DB 테이블)로 테스트 간 간섭이 발생한다.

- **심각도**: High
- **감지**: 전역 변수 수정, 공유 파일 쓰기, 격리 없는 DB 사용
- **원인**: FIRST Independent 위반
- **위험**: 순서 의존, 플레이키, 병렬 실행 불가

```python
# ❌
counter = 0

def test_increment():
    global counter
    counter += 1
    assert counter == 1    # 다른 테스트가 먼저 실행되면 실패

# ✅ 격리
def test_increment():
    counter = 0
    counter += 1
    assert counter == 1
```

### 5. General Fixture — 과도하게 큰 공유 셋업

테스트가 필요하지 않은 데이터까지 포함하는 크고 일반적인 fixture.

- **심각도**: Low (단일), Medium (전반적)
- **감지**: `setUp`/`beforeAll`에 10줄+ 데이터 생성, 대부분 테스트가 fixture 일부만 사용
- **원인**: DAMP 위반 (테스트 의도가 fixture 뒤에 숨음)
- **위험**: 테스트 느려짐, 의도 불명확

```python
# ❌
@pytest.fixture
def setup_everything():
    user = create_user()
    order = create_order(user)
    payment = create_payment(order)
    shipping = create_shipping(order)
    review = create_review(user, order)
    return user, order, payment, shipping, review

def test_user_name(setup_everything):
    user, _, _, _, _ = setup_everything
    assert user.name == "Alice"

# ✅ 필요한 것만
@pytest.fixture
def user():
    return create_user()

def test_user_name(user):
    assert user.name == "Alice"
```

### 6. Sensitive Equality — 깨지기 쉬운 동등성 비교

`toString()`, JSON 직렬화, 부동소수점 같은 포맷·표현에 의존한다.

- **심각도**: Medium
- **감지**: `str()`/`repr()`/`JSON.stringify()` 비교, float `==`, 타임스탬프 직접 비교
- **원인**: TEST-BEHAVIOR 위반 (내부 표현에 결합)
- **위험**: 포맷·로케일·부동소수점 정밀도 변화로 깨짐

```python
# ❌
def test_user_display():
    user = User("Alice", age=30)
    assert str(user) == "User(name=Alice, age=30)"

def test_calculation():
    assert calculate() == 0.30000000000000004

# ✅ 속성별 / 근사값
def test_user_display():
    user = User("Alice", age=30)
    assert user.name == "Alice"
    assert user.age == 30

def test_calculation():
    assert calculate() == pytest.approx(0.3)
```

### 7. Slow Test — 불필요하게 느림

단위 테스트가 ms 단위를 넘어간다.

- **심각도**: Low (단일), Medium (다수)
- **감지**: `sleep`, 실제 네트워크 호출, 큰 데이터셋 생성
- **원인**: FIRST Fast 위반
- **위험**: 피드백 루프 붕괴, 개발자가 테스트 회피

```python
# ❌
def test_retry_logic():
    time.sleep(3)
    result = service.get_status()
    assert result == "ready"

# ✅ 시간 추상화
def test_retry_logic(fake_clock):
    fake_clock.advance(seconds=3)
    result = service.get_status()
    assert result == "ready"
```

### 8. Conditional Test Logic — `if`/`for` 안에 assert

테스트 함수 내에 조건문·반복문이 있고, 그 안에서 assert한다.

- **심각도**: Medium
- **감지**: 테스트 함수 내 `if`, `for`, `while`, 삼항 연산자
- **원인**: 단일 경로 테스트 원칙 위반 (실패 경로가 여러 개)
- **위험**: 테스트 자체에 버그 발생 가능, 실패 원인 불명확

```python
# ❌
def test_discounts():
    for rate in [0, 10, 50, 100]:
        result = calculate_discount(rate)
        if rate > 50:
            assert result == "invalid"
        else:
            assert result > 0

# ✅ parametrize
@pytest.mark.parametrize("rate,expected", [
    (0, 1000), (10, 900), (50, 500),
])
def test_valid_discount(rate, expected):
    assert calculate_discount(rate) == expected

def test_over_50_is_invalid():
    assert calculate_discount(100) == "invalid"
```

### 9. Obscure Test — 의도 불명확

이름, 구조, 주석 어디에도 "이 테스트가 무엇을 검증하는지" 없다.

- **심각도**: Low (소수), Medium (전반)
- **감지**: `test_1`/`test_a` 같은 이름, assert 메시지 없음, 매직 넘버
- **원인**: DAMP 위반
- **위험**: 유지보수 시 "왜 이 테스트가 있지?" 의문

```python
# ❌
def test_1():
    assert foo(42) == 84

# ✅
def test_double_returns_twice_the_input():
    assert double(42) == 84
```

### 10. Dead Test — 실행되지 않거나 의미 없는

skip 처리, assert 없음, 항상 통과하는 tautology.

- **심각도**: High
- **감지**: `@skip`, `pass`만 있는 테스트, 주석 처리, `assert True`, assert 0개
- **원인**: FIRST Self-validating 위반
- **위험**: 거짓 안심감, 커버리지 수치 왜곡

```python
# ❌ skip
@pytest.mark.skip(reason="TODO")
def test_important_feature():
    ...

# ❌ 항상 통과
def test_something():
    assert True

# ❌ assert 없음
def test_process():
    result = process(order)    # 호출만. 검증 없음
```

**Dead Test 유형별 심각도**:

| 유형 | 설명 | 심각도 |
|------|------|:---:|
| Assert 없음 | 호출만 하고 검증 없음 | High |
| 항상 통과 | `assert True`, tautology | High |
| Skip (장기간) | 이유 없이 skip 지속 | Medium |
| 구현 변경 후 미갱신 | 이전 구현 기준으로 검증 | Medium |
| 중복 테스트 | 같은 것을 다른 이름으로 | Low |

---

## 스멜 → 원인 원칙 매핑

| 스멜 | 뿌리 원칙 |
|------|----------|
| Eager Test | SRP(테스트 관심사 분리) + DAMP |
| Mystery Guest | DAMP |
| Resource Optimism | FIRST Repeatable |
| Test Run War | FIRST Independent |
| General Fixture | DAMP |
| Sensitive Equality | TEST-BEHAVIOR |
| Slow Test | FIRST Fast |
| Conditional Logic | (단일 경로 검증) + DAMP |
| Obscure Test | DAMP |
| Dead Test | FIRST Self-validating + BEYONCE-RULE |

## 기계적 감지 (Grep 패턴)

```bash
# Eager Test: assert 5개+ 테스트
grep -c "assert\|expect" {test_file} | test별 집계

# Mystery Guest
grep "open\(['\"]/\|os\.environ\|os\.getenv" {tests}

# Resource Optimism
grep "open\(['\"]/tmp/\|open\(['\"]\./\|urllib\|requests\." {tests}

# Test Run War
grep "global \|cls\.\|self\.__class__\." {tests}

# Sensitive Equality
grep "assert.*str\(.*\)\|== .*\"<.*>\"\|toEqual.*JSON\.stringify" {tests}

# Slow Test
grep "time\.sleep\|await.*delay\|setTimeout" {tests}

# Conditional Logic
# (테스트 함수 AST로 검사 — if/for 존재)
ast-grep pattern 'def test_$_($$$): $$$'   # 그 중 if/for 포함 테스트

# Obscure Test
grep "def test_[0-9]*$\|def test_[a-z]$" {tests}    # 무의미 이름

# Dead Test
grep "@.*skip\|assert True\|expect(true)\.toBe(true)" {tests}
# assert 0개: 테스트별 assert/expect 카운트
```

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | High 스멜(Test Run War, Dead Test) 0건, Medium 스멜 <5%, Low는 자연스러운 수준 |
| **WARN** | High 스멜 1-2건 OR Medium 스멜 5-15% |
| **FAIL** | High 스멜 3건+ OR 다수 스멜이 누적 OR Dead Test 전반 |

## 설계 시 체크리스트

테스트 쓴 직후 스스로 점검:

- [ ] 이 테스트는 **한 가지**를 검증하는가? (Eager)
- [ ] 이 테스트만 읽어도 **입력과 기대값**이 보이는가? (Mystery Guest, Obscure)
- [ ] 외부 리소스 없이 **독립적으로** 돌아가는가? (Resource Optimism, Test Run War)
- [ ] **다른 테스트와 상태를 공유**하지 않는가? (Test Run War)
- [ ] 내부 표현(toString, JSON)이 아니라 **속성**을 비교하는가? (Sensitive Equality)
- [ ] **ms 단위**로 실행되는가? (Slow Test)
- [ ] `if`/`for` 없이 **단일 경로**인가? (Conditional Logic)
- [ ] 이름이 **검증 대상과 기대**를 설명하는가? (Obscure)
- [ ] `assert`가 있고 **의미 있게** 검증하는가? (Dead Test)

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| FIRST | 1/4/7/10번이 직접 위반 |
| TEST-BEHAVIOR | 6번이 직접 위반 |
| DAMP | 2/5/9번이 직접 위반 |
| BROKEN-WINDOWS | 스멜 방치 = 깨진 유리창. 초기에 잡아야 |
| BOY-SCOUT | 근처 수정 시 스멜 있으면 정리하고 떠난다 |
| BEYONCE-RULE | Dead Test는 Beyoncé 위반 (보호 없이 "소원만") |

## 주의

- 스멜은 **증상**이지 병이 아니다. 원칙 위반으로 소급해 처방한다
- 모든 스멜을 동시에 잡으려 하지 말고 High부터 순차적으로
- 스멜 검사기(Jest, pytest-testmon 등) 자동화 권장. 수동 점검은 휘발됨
