# 구현 전략

GREEN 단계에서 테스트를 통과시키는 3가지 전략.

## 1. Fake It Till You Make It

**전략**: 하드코딩 → 삼각측량 → 일반화

**단계**:
1. 첫 테스트: 예상 값을 하드코딩
2. 두 번째 테스트: 다른 값으로 일반화 강제
3. 필요 시 세 번째 테스트로 확신

**장점**:
- 안전한 진행 (작은 단계)
- 과도한 일반화 방지
- 명확한 피드백

**단점**:
- 여러 테스트 필요
- 느린 진행

**예시**:
```python
# Step 1: Fake It
def calculate_discount(price):
    return 10  # 하드코딩

# Step 2: 두 번째 테스트로 강제
def calculate_discount(price):
    if price == 100:
        return 10
    return 20  # 두 번째 케이스

# Step 3: 일반화
def calculate_discount(price):
    return price * 0.1
```

## 2. Obvious Implementation

**전략**: 구현이 명백하면 바로 작성

**언제 사용**:
- 매우 단순한 로직
- 확신이 있을 때
- 유사 패턴 반복 시

**주의사항**:
- 실수 가능성
- 테스트 실패 시 Fake It으로 전환

**예시**:
```python
# 명백한 구현
def test_reverse_string():
    assert reverse("hello") == "olleh"

def reverse(s):
    return s[::-1]  # 명백하므로 바로 구현
```

## 3. Triangulation

**전략**: 두 개 이상의 예시로 일반화 패턴 발견

**과정**:
1. 특수 케이스 하드코딩
2. 다른 예시로 패턴 드러내기
3. 일반 규칙 추출

**장점**:
- 확신을 가지고 일반화
- 과도한 추상화 방지

**예시**:
```python
# Test 1
def test_sum_empty():
    assert sum_list([]) == 0

def sum_list(nums):
    return 0  # 하드코딩

# Test 2 - 삼각측량
def test_sum_single():
    assert sum_list([5]) == 5

def sum_list(nums):
    if len(nums) == 0:
        return 0
    return nums[0]  # 여전히 특수 케이스

# Test 3 - 일반화 강제
def test_sum_multiple():
    assert sum_list([1, 2, 3]) == 6

def sum_list(nums):
    return sum(nums)  # 이제 일반화
```
