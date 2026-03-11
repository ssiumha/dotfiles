# TDD Practices - 참조 문서

이 문서는 TDD Practices 스킬의 핵심 용어 정의와 상세 참조 자료 목록입니다.

## 목차

1. [TDD 용어 정의](#tdd-용어-정의) (이 문서)
2. [테스트 주도 설계 원칙](#테스트-주도-설계-원칙) (이 문서)
3. [TDD 패턴 카탈로그](./resources/patterns.md)
4. [구현 전략](./resources/strategies.md)
5. [리팩토링 패턴](./resources/refactoring.md)
6. [AI 코딩과 TDD](./resources/ai-coding.md)

---

## TDD 용어 정의

### RED
실패하는 테스트를 작성하는 단계.

- **목적**: 다음에 구현할 기능을 테스트로 명시
- **완료 조건**: 테스트가 예상한 이유로 실패
- **주의사항**: 테스트가 바로 통과하면 이미 구현됨 또는 테스트 오류

### GREEN
테스트를 통과시키는 최소한의 코드를 작성하는 단계.

- **목적**: 테스트를 빠르게 통과시키기
- **완료 조건**: 작성한 테스트 + 모든 기존 테스트 통과
- **주의사항**: 과도한 일반화 금지, Fake It 허용

### REFACTOR
동작 변경 없이 코드를 개선하는 단계.

- **목적**: 중복 제거, 의도 명확화, 구조 개선
- **완료 조건**: 모든 테스트 여전히 통과
- **주의사항**: 기능 추가 절대 금지

### Test List
구현할 기능을 테스트 케이스 목록으로 작성한 것.

- **작성 시기**: TDD 세션 시작 시
- **순서**: 단순한 것부터 복잡한 순서
- **관리**: 완료한 항목 체크, 새로운 항목 추가

**예시**:
```
사용자 인증 Test List:
- [x] 유효한 자격증명으로 로그인
- [x] 잘못된 비밀번호
- [ ] 존재하지 않는 사용자
- [ ] 빈 비밀번호
- [ ] SQL injection 방어
```

### Triangulation (삼각측량)
여러 테스트로 일반화를 유도하는 전략.

- **사용 시기**: 구현 방법이 불명확할 때
- **방법**:
  1. 첫 테스트: 하드코딩
  2. 두 번째 테스트: 일반화 강제
  3. 세 번째 테스트: 패턴 확인

**예시**:
```python
# 1단계: 하드코딩
def fibonacci(n):
    return 1  # test: fib(1) == 1

# 2단계: 조건 추가
def fibonacci(n):
    if n <= 2:
        return 1  # test: fib(2) == 1
    return 2      # test: fib(3) == 2

# 3단계: 일반화
def fibonacci(n):
    if n <= 2:
        return 1
    return fibonacci(n-1) + fibonacci(n-2)
```

### Fake It Till You Make It
하드코딩된 값을 먼저 반환하고 나중에 일반화하는 전략.

- **장점**: 빠르게 GREEN, 안전한 진행
- **단점**: 여러 테스트 필요 (삼각측량)
- **언제**: 구현이 불명확하거나 작은 단계를 원할 때

### Obvious Implementation
구현이 명백할 때 바로 일반화된 코드를 작성하는 전략.

- **장점**: 빠른 진행
- **단점**: 실수 가능성
- **언제**: 구현이 매우 단순하고 명백할 때

---

## 테스트 주도 설계 원칙

TDD는 단순히 테스트 작성 기법이 아니라, 테스트를 통해 더 나은 설계를 만드는 방법론입니다.

### 1. 테스트 가능성은 좋은 설계의 지표

테스트하기 쉬운 코드는 결합도가 낮고 응집도가 높은 코드입니다.

- 테스트 작성이 어렵다면 → 설계 문제의 신호
- 테스트를 위해 코드를 쪼개는 과정 → 더 나은 구조 발견

### 2. 일반화는 여러 테스트를 통해 자연스럽게 도출

하드코딩된 특수 케이스에서 시작해 여러 테스트를 통과시키며 범용적 설계로 발전합니다.

- 첫 테스트: 특수 케이스 (Fake It)
- 두 번째 테스트: 일반화 필요성 발견
- 세 번째 테스트: 범용적 패턴 확정

### 3. 테스트의 어려움은 리팩토링 신호

부작용이 많거나 의존성이 강하게 결합된 코드는 테스트하기 어렵습니다.

- 테스트 설정이 복잡하다면 → 의존성 주입 고려
- 여러 것을 동시에 검증해야 한다면 → 단일 책임 원칙(SRP) 위반

### 4. 단순성은 테스트의 부산물

테스트 가능한 코드를 추구하다 보면 자연스럽게 단순한 구조가 나옵니다.

- 내부 상태 최소화
- 입력과 출력이 명확
- 부작용 제거

### 5. 선언적 구조로 테스트 최소화

고급 단계: 행위를 설정(configuration)으로 표현하여 테스트 자체를 줄입니다.

**예시**: Django의 `django-filters`
```python
# 5개의 필터 함수 + 5개의 테스트 대신
class UserFilter(FilterSet):
    name = CharFilter(lookup_expr='icontains')
    age = NumberFilter(lookup_expr='gte')
    # 설정만으로 필터 정의
```

설정 기반 구조는 개별 케이스 테스트보다 프레임워크 수준의 테스트로 충분합니다.

---

## 상세 참조 자료

상세한 패턴, 전략, 리팩토링 기법은 아래 파일들을 참조하세요:

- **[patterns.md](./resources/patterns.md)**: Kent Beck의 TDD 패턴 카탈로그 (Test List, Isolated Test, Test First, Assert First, Child Test, Broken Test, Clean Check-in)

- **[strategies.md](./resources/strategies.md)**: GREEN 단계 구현 전략 (Fake It Till You Make It, Obvious Implementation, Triangulation)

- **[refactoring.md](./resources/refactoring.md)**: REFACTOR 단계 리팩토링 패턴 (Extract Method, Rename, Inline Method, Extract Variable, Remove Duplication)

- **[ai-coding.md](./resources/ai-coding.md)**: Kent Beck의 Augmented Coding 접근법, AI Red Flags, System Prompt 원칙, AI와 TDD 워크플로우

---

**Skill 워크플로우는 [SKILL.md](./SKILL.md)를 참조하세요.**
