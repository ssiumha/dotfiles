
# Test Guidelines

테스트 작성의 핵심 원칙과 워크플로우를 제공하는 스킬입니다.

**핵심 철학**:
- 실제 구현 우선, Mock 과다는 설계 문제 신호
- 작은 단위부터 시작 (Bottom-up)
- 반복되는 패턴은 fixture/factory로 재사용
- Mock 필요 시 구조 진단 먼저, 필요하면 사용자와 논의
- **테스트 실패 = 실제 문제. 절대 우회하지 말 것**

## 테스트 문서화

테스트는 실행 가능한 스펙 문서입니다.

### describe/it 작성법

```typescript
// ❌ 모호함
describe('UserService', () => {
  it('works', () => {});
});

// ✅ 명확함
describe('UserService.login', () => {
  it('유효한 자격증명으로 로그인하면 토큰을 반환한다', () => {});
  it('잘못된 비밀번호면 AuthError를 던진다', () => {});
});
```

### 복잡한 테스트에 Why 주석

엣지 케이스, 버그 수정, 비직관적 로직은 **왜 필요한지** 주석:

```python
def test_handles_leap_year_edge_case():
    """
    2월 29일 처리 테스트
    - Fixes #234: 윤년 계산 오류
    - Per spec: ISO 8601
    """
    assert parse_date("2024-02-29") is not None
```

### 스펙/이슈 참조

```typescript
// 요구사항 참조
// REQ: 로그인 실패 5회 시 계정 잠금
it('5회 연속 실패 시 계정을 잠근다', () => {});

// 버그 수정 참조
// Fixes #456: 빈 문자열 입력 시 크래시
it('빈 입력을 gracefully 처리한다', () => {});
```

## 테스트 분리 단위

### 테스트 레벨 정의

| 레벨 | 범위 | 속도 | 비율 |
|------|------|------|------|
| 단위 | 함수/클래스 하나 | ms | 80% |
| 통합 | 모듈 간 상호작용 | 100ms-1s | 15% |
| E2E | 전체 시스템 | 초-분 | 5% |

### describe 그룹화 기준

```
describe('모듈/클래스명')
  └── describe('메서드명')
        └── it('상황_결과')
```

**그룹화 원칙**:
- 같은 setup을 공유하는 테스트끼리
- 같은 기능을 검증하는 테스트끼리
- 너무 깊은 중첩 피하기 (최대 3단계)

### 1테스트 = 1실패 원인

테스트 실패 시 **정확히 하나의 원인**만 있어야 함:

```python
# ❌ 여러 원인 가능
def test_user_flow():
    user = create_user()      # 실패 원인 1
    login(user)               # 실패 원인 2
    assert profile(user)      # 실패 원인 3

# ✅ 원인 명확
def test_create_user():
    user = create_user()
    assert user.id is not None

def test_login_returns_token():
    user = create_user()  # fixture로 분리 권장
    token = login(user)
    assert token is not None
```

## Instructions

### Workflow 1: 새 테스트 파일 생성

1. **테스트 대상 코드 분석**
   - Glob으로 관련 파일 찾기 (`*.test.*`, `*_test.*` 등)
   - **구현 코드 먼저 Read** (테스트 작성 전 필수)
   - Grep으로 기존 테스트 패턴 확인
   - **가장 작은 단위부터** (순수 함수, 단일 메서드)
   - 함수/메서드의 입력, 출력, 부수 효과 파악
   - 의존성 확인 (DB, 외부 API, 파일 시스템 등)

2. **테스트 전략 수립**
   - AAA 패턴 (Arrange-Act-Assert) 적용
   - 테스트 케이스 목록: Happy path, Edge cases, Error cases
   - **경계값 테스트**: `resources/boundary-testing.md` 참조 (숫자, 문자열, 날짜 경계)
   - 사용자에게 전략 설명 및 확인

3. **⚠️ Mock 필요성 판단 → 구조 진단**
   - Mock 대상 의존성 나열 (실제 사용되는 것만)
   - **의존성 3개 이상**: 구조 문제 가능성 언급
   - **질문하기**:
     - "이 클래스가 의존성을 직접 생성하나요? (new, import)"
     - "의존성 주입(DI)으로 변경하면 테스트가 쉬워질 수 있어요"
     - "더 작은 단위로 분리 가능한가요?"
   - **선택지 제시**: 구조 개선(권장) vs Mock 사용(임시)
   - 사용자 결정 후 진행

4. **Fixture/Factory 패턴 고려**
   - 반복되는 테스트 데이터 패턴 확인
   - 동일 데이터 3회 이상 반복 시 Factory 제안
   - 언어별 가이드에서 구현 방법 참조

5. **테스트 코드 작성**
   - Write tool로 테스트 파일 생성
   - **점진적 작성**: 테스트 1개 작성 → 실행 → 다음 테스트
   - 명확한 테스트명 사용 (무엇을_언제_어떻게)
   - 각 테스트는 독립적으로 실행 가능하게

6. **테스트 실행 및 검증**
   - Bash tool로 테스트 실행
   - **실패 시**: 테스트 우회 금지, 실제 구현 문제 해결 (원칙 5 참조)
   - 사용자에게 결과 보고

### Workflow 2: 기존 테스트 리뷰/수정

1. **테스트 파일 읽기**
   - Glob으로 테스트 파일 목록 확인
   - 큰 파일(>500줄)은 Grep으로 구조 먼저 파악
   - Read tool로 테스트 코드 분석 (필요 시 offset/limit)
   - 구현 코드도 함께 Read (테스트만 보지 말 것)
   - 중복 패턴 식별

2. **품질 체크리스트 적용**
   - 테스트 독립성, 명확성, AAA 패턴 확인
   - Mock 과다 사용 검토
   - 재사용성 확인

3. **테스트 우회 패턴 찾기 (⚠️ 중요)**
   - 테스트 우회 패턴 검색 (원칙 5 참조)
   - **발견 시 즉시 사용자에게 보고**

4. **개선 제안 및 사용자 확인**
   - 발견된 문제점 나열
   - 구체적인 개선 방법 제시
   - 사용자 확인 후 수정

### Workflow 3: 실패 테스트 디버깅

1. **실패 정보 수집**
   - Bash로 verbose 실행, 정확한 에러 메시지 확인
   - 어떤 assertion이 실패했는지 파악

2. **코드 분석**
   - 구현과 테스트 모두 Read (아직 안 읽었다면)
   - 실패 원인 판단: 구현 버그 vs 테스트 문제

3. **문제 해결**
   - 구현 버그 → 구현 코드 수정
   - 스펙 불명확 → 사용자에게 스펙 확인
   - 테스트 과다 엄격 → 사용자 승인 후 조정
   - **절대 테스트 우회 금지** (원칙 5 참조)

## 테스트 작성 원칙

### 1. 작은 단위부터 시작 (Bottom-up)

**올바른 순서**: 순수 함수 → 단일 클래스 → 모듈 통합 → E2E

**작은 단위의 장점**:
- 빠른 피드백 (밀리초 단위)
- 명확한 실패 원인
- 쉬운 디버깅

**테스트 비율 (Google 권장)**:
- 단위 테스트 80%: 빠른 피드백, 이상 케이스 커버
- 통합/E2E 테스트 20%: 실제 동작 검증

### 2. AAA 패턴 (Arrange-Act-Assert)

- **Arrange**: 데이터/객체 준비, Fixture/Factory 활용
- **Act**: 테스트 대상 **단 한 번** 호출
- **Assert**: 예상 결과 비교, 부수 효과 확인

### 3. 테스트 독립성

- 각 테스트는 독립적으로 실행
- 테스트 간 실행 순서 무관
- Fixture는 각 테스트마다 fresh하게

### 4. DAMP > DRY 원칙

테스트 코드는 DRY(중복 제거)보다 **DAMP(Descriptive and Meaningful Phrases)**를 우선합니다.

**왜 DAMP인가?**:
- 테스트 실패 시 원인 파악 용이성이 최우선
- 각 테스트가 독립적으로 이해 가능해야 함
- 헬퍼 메서드 과도한 공통화 → 컨텍스트 불투명화

```python
# ❌ 과도한 DRY - 실패 시 원인 파악 어려움
def test_order_processing():
    order = create_order()  # 내부에서 무슨 일이?
    assert process(order) == expected_result()  # 기대값이 뭐지?

# ✅ DAMP - 명시적이고 이해하기 쉬움
def test_order_with_discount_applies_10_percent():
    order = Order(items=[Item("book", 10000)], discount_code="SAVE10")
    result = process(order)
    assert result.total == 9000
```

```typescript
// ❌ 과도한 DRY
it('processes order', () => {
  const order = createTestOrder();
  expect(process(order)).toEqual(expectedResult());
});

// ✅ DAMP
it('applies 10% discount when valid code provided', () => {
  const order = { items: [{ name: 'book', price: 10000 }], discountCode: 'SAVE10' };
  expect(process(order).total).toBe(9000);
});
```

### 5. 1테스트 = 1논리

테스트 내 조건문은 위험 신호입니다.

**피해야 할 패턴**:
- 테스트 내 if/else, for 조건문
- 여러 시나리오를 하나의 테스트에 몰아넣기

```python
# ❌ 여러 시나리오를 하나에
def test_calculate_discount():
    for discount in [0, 10, 50, 100]:
        if discount > 50:
            assert calculate(discount) == "invalid"
        else:
            assert calculate(discount) > 0

# ✅ 파라미터화 테스트로 분리
@pytest.mark.parametrize("discount,expected", [
    (0, 1000),
    (10, 900),
    (50, 500),
])
def test_calculate_discount_valid(discount, expected):
    assert calculate(discount) == expected

def test_calculate_discount_over_50_is_invalid():
    assert calculate(100) == "invalid"
```

```typescript
// ❌ 여러 시나리오를 하나에
it('calculates discount', () => {
  [0, 10, 50, 100].forEach(discount => {
    if (discount > 50) {
      expect(calculate(discount)).toBe('invalid');
    } else {
      expect(calculate(discount)).toBeGreaterThan(0);
    }
  });
});

// ✅ test.each로 분리
it.each([
  [0, 1000],
  [10, 900],
  [50, 500],
])('calculates %i%% discount as %i', (discount, expected) => {
  expect(calculate(discount)).toBe(expected);
});

it('rejects discount over 50%', () => {
  expect(calculate(100)).toBe('invalid');
});
```

### 6. 명확한 테스트명

**패턴**: `메서드명_상황_예상결과`

**좋은 예**:
- `calculateTotal_withValidInput_returnsCorrectSum`
- `fetchUser_whenUserNotFound_throwsNotFoundError`

### 7. 테스트 실패 대응 원칙 (⚠️ 중요)

```
❌ 절대 금지:
- 테스트 주석 처리
- skip, xfail, disabled 사용
- 조건부 assert (if 문 안에 assert)
- 테스트 조건을 스펙과 무관하게 수정
- 항상 통과하는 의미 없는 assert
- Mock으로 무작정 우회

✅ 올바른 대응:
1. 실패 원인 정확히 파악
2. 구현 코드 수정 (스펙 준수)
3. 스펙이 잘못됐다면 사용자와 논의
4. 테스트는 실패 상태로 유지하고 이슈 추적
```

**테스트는 거짓말하지 않는다**:
- 테스트 실패 = 구현 문제 or 스펙 오해
- 테스트를 수정해서 통과시키는 것은 자기기만
- 실패하는 테스트가 통과하는 거짓 테스트보다 낫다

## Fixture & Factory 패턴

### Fixture
- 테스트에 필요한 고정된 상태/데이터
- Setup/Teardown으로 관리
- 각 테스트마다 fresh한 상태

### Factory 패턴
- 테스트 데이터 생성 재사용 함수/클래스
- 기본값 + 필요 시 override
- 동일 데이터 3회 이상 반복 시 사용

### 재사용성 판단

```
✅ Fixture/Factory 만들기:
- 동일 데이터 3회 이상 반복
- 복잡한 객체 생성 (5개 이상 속성)
- Setup/Teardown 공통

❌ 불필요:
- 1-2개 테스트에서만 사용
- 매우 간단한 데이터
```

## 거짓 양성(False Positive) 방지

### 거짓 양성이란?

**로직은 정상인데 리팩토링으로 테스트가 실패하는 현상**입니다.
거짓 양성이 많으면 테스트 신뢰도가 하락하고, 개발자가 테스트를 무시하게 됩니다.

### 원인: 구현 세부사항 의존

```python
# ❌ 구현 세부사항에 의존 - 거짓 양성 발생
def test_apply_discount():
    mock_discount = Mock()
    service = OrderService(discount_calculator=mock_discount)
    service.calculate_price(100)

    # 내부적으로 어떤 함수를 호출했는지 검증
    mock_discount.apply.assert_called_once_with(100)  # 리팩토링하면 깨짐
```

```typescript
// ❌ 구현 세부사항에 의존
it('applies discount', () => {
  const mockDiscount = jest.fn();
  const service = new OrderService({ discountCalculator: { apply: mockDiscount } });
  service.calculatePrice(100);

  expect(mockDiscount).toHaveBeenCalledWith(100);  // 리팩토링하면 깨짐
});
```

### 해결: 행위(결과) 기반 검증

```python
# ✅ 행위 기반 - 최종 결과값만 검증
def test_apply_discount():
    service = OrderService(discount_calculator=RealDiscountCalculator())
    result = service.calculate_price(100)

    assert result == 90  # 어떻게 계산했는지는 중요하지 않음
```

```typescript
// ✅ 행위 기반
it('applies 10% discount', () => {
  const service = new OrderService({ discountCalculator: new RealDiscountCalculator() });
  expect(service.calculatePrice(100)).toBe(90);
});
```

### 공개 API만 테스트

- private 함수 직접 테스트 → 깨지기 쉬운 테스트
- public 인터페이스를 통해 간접 검증

```python
# ❌ private 함수 직접 테스트
def test_internal_calculation():
    service = OrderService()
    result = service._calculate_tax(100)  # private 함수 직접 호출
    assert result == 10

# ✅ public API를 통해 검증
def test_order_includes_tax():
    service = OrderService()
    result = service.calculate_total(100)  # public 메서드
    assert result == 110  # 세금 포함된 결과
```

```typescript
// ❌ private 함수 직접 테스트
it('calculates tax internally', () => {
  const service = new OrderService();
  expect((service as any).calculateTax(100)).toBe(10);  // private 접근
});

// ✅ public API를 통해 검증
it('order total includes tax', () => {
  const service = new OrderService();
  expect(service.calculateTotal(100)).toBe(110);
});
```

### 거짓 양성 체크리스트

- [ ] Mock의 호출 횟수/인자를 검증하고 있지 않은가?
- [ ] private 함수를 직접 테스트하고 있지 않은가?
- [ ] 내부 상태 변경을 직접 검증하고 있지 않은가?
- [ ] 리팩토링해도 테스트가 통과하는가?

## Mock/Stub 사용 철학

### ⚠️ Mock 과다 = 설계 문제 신호

Mock이 많이 필요하다면 먼저 질문하기:

**구조 진단 질문:**
1. 테스트 대상이 의존성을 직접 생성하나요? (new, import)
   → DI 패턴 미적용 신호
2. Mock 대상이 3개 이상인가요?
   → 책임 과다 (SRP 위반) 가능성
3. 내부 구현을 Mock해야 하나요?
   → 강한 결합 신호

**대응 우선순위:**
1. 구조 개선 제안 (DI 적용, 책임 분리)
2. 인터페이스 추출 + Fake 구현
3. 사용자 승인 후 Mock (임시 해결책으로 명시)

### Robert Martin Goldilocks Rule

> "Mock across architecturally significant boundaries, but not within those boundaries."

```
✅ Mock OK (아키텍처 경계):
- 외부 API (결제, 이메일, 3rd party)
- 파일 시스템 대량 I/O
- 현재 시간 의존성
- 네트워크 요청
- 느린 연산 (> 1초)

⚠️ 판단 필요 (100ms - 1초):
- DB 쿼리 → In-memory DB 고려
- 파일 읽기 → 작은 파일은 실제 사용

❌ Mock 피하기 (내부 경계):
- 같은 모듈 내 클래스/함수
- 프로젝트 내부 의존성
- 순수 함수
- 빠른 계산 (< 100ms)
```

### Mock 필요 시 워크플로우

1. **진단**: 왜 Mock이 필요한지 분석
2. **질문**: 사용자에게 구조 개선 의향 확인
3. **선택지 제시**:
   ```
   A. 구조 개선 (권장)
      - DI 적용, 책임 분리
      - 장기적으로 테스트 용이성 향상

   B. Mock 사용 (임시)
      - 현재 구조 유지
      - 기술 부채로 기록
   ```
4. **사용자 결정에 따라 진행**

### Test Double 유형

1. **Dummy**: 전달만 됨 (사용되지 않음)
2. **Stub**: 미리 정의된 응답 반환
3. **Spy**: 호출 기록 + 실제 동작
4. **Fake**: 간단한 구현 (In-memory DB 등) ← 권장
5. **Mock**: 행위 검증 ← 구조 진단 후 사용

## 테스트하기 어려운 구조 개선

Mock이 과다하게 필요한 코드는 구조 개선으로 해결할 수 있습니다.

### DI 미적용 패턴 (Bad)

```python
# ❌ 의존성을 직접 생성 → Mock 필수
class OrderService:
    def __init__(self):
        self.payment = PaymentGateway()  # 직접 생성
        self.email = EmailService()      # 직접 생성
        self.logger = Logger()           # 직접 생성

    def process(self, order):
        self.payment.charge(order.total)
        self.email.send(order.user, "주문 완료")
```

테스트하려면 PaymentGateway, EmailService, Logger 모두 Mock 필요.

### DI 적용 패턴 (Good)

```python
# ✅ 의존성 주입 → Fake로 테스트 가능
class OrderService:
    def __init__(self, payment, email, logger):
        self.payment = payment  # 주입받음
        self.email = email      # 주입받음
        self.logger = logger    # 주입받음

    def process(self, order):
        self.payment.charge(order.total)
        self.email.send(order.user, "주문 완료")

# 테스트
def test_process_order():
    fake_payment = FakePaymentGateway()
    fake_email = FakeEmailService()
    fake_logger = FakeLogger()

    service = OrderService(fake_payment, fake_email, fake_logger)
    service.process(order)

    assert fake_payment.charged_amount == 10000
    assert fake_email.sent_to == "user@example.com"
```

### 개선 효과

| 항목 | DI 미적용 | DI 적용 |
|------|-----------|---------|
| Mock 필요성 | 필수 (3개) | 불필요 (Fake 사용) |
| 테스트 속도 | Mock 설정 오버헤드 | 빠름 |
| 의존성 명시성 | 숨겨짐 | 명시적 |
| 재사용성 | 낮음 | 높음 |

### 구조 개선 체크리스트

- [ ] 의존성이 생성자에서 주입되는가?
- [ ] 인터페이스/프로토콜로 추상화되었는가?
- [ ] Fake 구현이 존재하는가?
- [ ] 단일 책임 원칙(SRP)을 준수하는가?

## 품질 체크리스트

### 테스트 구조
- [ ] 작은 단위부터 테스트 (순수 함수 → 클래스 → 통합)
- [ ] AAA 패턴 명확
- [ ] 독립적 실행 가능
- [ ] 명확한 테스트명
- [ ] 단일 관심사
- [ ] DAMP 원칙 준수 (각 테스트가 독립적으로 이해 가능)
- [ ] 1테스트 = 1논리 (테스트 내 if/else, for 없음)
- [ ] 테스트 비율 적절 (단위 80%, 통합/E2E 20%)

### 테스트 진정성 (⚠️ 중요)
- [ ] 주석 처리된 테스트 없음
- [ ] skip/disabled 테스트 없음
- [ ] 조건부 assert 없음 (if 문 안에 assert)
- [ ] 실제 스펙 검증
- [ ] 의미 있는 assert
- [ ] Mock 우회 없음

### 거짓 양성 방지
- [ ] Mock 호출 횟수/인자 검증 최소화
- [ ] private 함수 직접 테스트 없음
- [ ] 공개 API를 통한 간접 검증
- [ ] 리팩토링해도 테스트 통과

### 재사용성
- [ ] Fixture/Factory 적절히 사용
- [ ] 공통 Setup/Teardown 정리

### Mock 사용
- [ ] 아키텍처 경계에서만 사용 (Goldilocks Rule)
- [ ] 의존성 3개 이상 시 구조 진단 완료
- [ ] 구조 개선 vs Mock 사용 선택지 제시함
- [ ] 내부 모듈/클래스는 Mock하지 않음

### 테스트 품질
- [ ] 빠른 실행 (< 1초)
- [ ] 명확한 실패 원인
- [ ] Edge case/error case 검증
- [ ] Flaky 아님 (항상 같은 결과)

## Examples

### 새 테스트 작성 (Mock 불필요)
```
User: "UserService 테스트 작성해줘"
→ Workflow 1: 코드 분석 (순수 함수 위주)
→ 의존성 확인: 없음
→ AAA 패턴으로 테스트 작성
→ 실행 및 검증
```

### Mock 과다 감지 → 구조 개선 제안
```
User: "OrderService 테스트 작성해줘"
→ Workflow 1: 코드 분석
→ 의존성 확인: PaymentGateway, EmailService, Logger (3개)
→ ⚠️ 구조 진단: "의존성 3개, DI 미적용"
→ 질문: "구조 개선(권장) vs Mock 사용(임시)?"
→ 사용자 선택에 따라 진행
```

### 기존 테스트 리뷰 (Mock 과다 발견)
```
User: "테스트 코드 리뷰해줘"
→ Workflow 2: 테스트 파일 분석
→ Mock 10개 발견
→ ⚠️ "Mock 과다 - Goldilocks Rule 위반"
→ 구조 개선 제안 (DI 적용, 책임 분리)
```

## Technical Details

언어별 테스트 도구/문법은 rules 참조 (테스트 파일 수정 시 해당 rule이 컨텍스트에 자동 추가됨):
- Python (`*_test.py`, `test_*.py`): `rules/python-test.md`
- TypeScript (`*.test.ts`, `*.spec.ts`): `rules/typescript-test.md`
