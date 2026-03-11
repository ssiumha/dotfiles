# TDD 패턴 카탈로그

Kent Beck의 "Test-Driven Development: By Example"에서 소개된 패턴들.

## Test List 패턴

구현 전 필요한 모든 테스트를 목록으로 작성.

**목적**:
- 작업 범위 명확화
- 진행 상황 추적
- 다음 단계 명확화

**사용법**:
1. 기능 분석
2. 테스트 케이스 나열
3. 단순→복잡 순서 정렬
4. 하나씩 진행하며 체크

## Isolated Test 패턴

각 테스트는 다른 테스트와 독립적으로 실행.

**원칙**:
- 테스트 간 의존성 없음
- 실행 순서 무관
- 공유 상태 피하기

**구현**:
```python
# 나쁜 예: 전역 상태 공유
counter = 0

def test_increment():
    global counter
    counter += 1
    assert counter == 1  # 다른 테스트 영향 받음

# 좋은 예: 독립적
def test_increment():
    counter = Counter()
    counter.increment()
    assert counter.value == 1
```

## Test First 패턴

코드 작성 전 테스트를 먼저 작성.

**이점**:
- 인터페이스 설계 우선
- 필요한 기능만 구현
- 테스트 가능한 설계

**주의**:
- 구현 상세에 의존하는 테스트 피하기
- 공개 API만 테스트

## Assert First 패턴

테스트를 뒤에서부터 작성 (Assert → Act → Arrange).

**순서**:
1. 기댓값 작성: `assert result == 5`
2. 호출 작성: `result = add(2, 3)`
3. 준비 작성: (필요 시) `calculator = Calculator()`

**장점**: 원하는 결과부터 생각

## Child Test 패턴

복잡한 테스트를 발견하면 더 작은 테스트로 분할.

**시나리오**:
- 테스트 작성 중 너무 복잡함을 깨달음
- 중간 단계 테스트 추가
- 작은 것부터 다시 시작

**예시**:
```
원래 계획: 파일 업로드 + 처리 + 저장 테스트

Child Test 분할:
1. 빈 파일 업로드 (가장 단순)
2. 작은 텍스트 파일 업로드
3. 파일 내용 읽기
4. 파일 처리
5. 처리 결과 저장
```

## Broken Test 패턴

작업 중단 시 의도적으로 실패하는 테스트 남기기.

**목적**: 재개 시 어디서부터 시작할지 명확

**사용법**:
```python
def test_user_registration_WIP():
    # TODO: 이메일 중복 체크 추가 필요
    assert False, "작업 중: 이메일 중복 체크 구현"
```

## Clean Check-in 패턴

커밋 전 모든 테스트가 통과하도록 보장.

**규칙**:
- 모든 테스트 통과
- 실패/스킵 테스트 없음
- 코드 정리 완료

**이점**: 항상 배포 가능한 상태
