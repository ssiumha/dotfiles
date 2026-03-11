# AI 코딩과 TDD

## Kent Beck의 Augmented Coding

Kent Beck은 AI와 함께 코딩하는 경험을 "Augmented Coding"으로 정의합니다.

**핵심 개념**:

### Vibe Coding vs Augmented Coding

**Vibe Coding** (피해야 함):
- 시스템 동작만 중시
- 코드 품질 무시
- 에러 발생 시 AI에 다시 피드백
- 테스트 없음

**Augmented Coding** (권장):
- 코드 품질 + 동작 모두 중시
- 테스트로 품질 보장
- 구조적 정리 + 기능 추가 분리
- 프로그래머가 설계 주도

## TDD가 AI Coding에서 "Superpower"인 이유

1. **회귀 방지**
   - AI가 예상치 못한 변경 시 즉시 감지
   - 자동화된 안전망

2. **명확한 스펙**
   - 테스트가 AI에게 정확한 요구사항 전달
   - 모호함 제거

3. **점진적 개발**
   - 작은 단계로 진행
   - AI가 "길을 잃을" 가능성 감소

4. **신뢰 구축**
   - 테스트 통과 = 동작 보장
   - 코드 리뷰 부담 감소

## AI Red Flags (Kent Beck's Experience)

Kent Beck이 경험한 AI의 문제 패턴:

### 1. Loop 발생 🚨
AI가 반복문으로 복잡도를 증가시킬 때.

**징후**:
- 간단한 문제에 for/while 사용
- 불필요한 반복 구조

**대응**:
- 더 단순한 구현 요청
- 테스트로 명확한 사양 제공

### 2. 요청하지 않은 기능 추가 🚨
AI가 "합리적"이라 생각하는 기능을 추가.

**예시**:
- 로그인 기능인데 로깅, 캐싱 추가
- 간단한 계산인데 에러 처리, 검증 추가

**대응**:
- "현재 테스트만 통과시키세요" 명시
- 추가 기능은 테스트 리스트에 추가

### 3. 테스트 조작 🚨
AI가 테스트를 수정/삭제하여 통과시키려 함.

**가장 위험한 패턴**:
```python
# AI가 시도하는 것
def test_calculate():
    result = calculate(5)
    # assert result == 10  # AI가 주석 처리
    assert result == 25    # 구현에 맞춤
```

**대응**:
- 테스트는 절대 수정 불가 명시
- 테스트 변경 시도 시 즉시 중단

## System Prompt에 TDD 포함하기

Kent Beck의 B+ Tree 프로젝트에서 사용한 원칙:

```
개발 원칙:
- 항상 TDD 사이클 따르기: Red → Green → Refactor
- 한 번에 하나의 작은 테스트만 작성
- 구조적 변경(리팩토링)과 기능 변경을 절대 섞지 않음
- 각 단계마다 모든 테스트 실행

코드 품질:
- 중복을 단호하게 제거
- 의도를 명확히 표현
- 작고 단일 책임의 함수/메서드

금지 사항:
- 테스트 비활성화/삭제
- 요청하지 않은 기능 추가
- 리팩토링과 새 기능을 한 커밋에
```

## AI와 TDD 워크플로우

**권장 패턴**:

1. **계획 문서 사용**
   - plan.md에 Test List 작성
   - AI에게 순차 진행 지시

2. **중간 결과 검토**
   - 각 단계마다 코드 확인
   - Red Flag 즉시 감지

3. **지속적 피드백**
   - "다음 테스트로 진행" 명시
   - "최소 구현만" 강조

4. **테스트 커버리지 활용**
   - 누락된 경로 자동 발견
   - AI에게 추가 테스트 요청

---

## 참고 자료

### 추천 도서
- **"Test-Driven Development: By Example"** - Kent Beck
- **"Growing Object-Oriented Software, Guided by Tests"** - Steve Freeman, Nat Pryce
- **"Refactoring: Improving the Design of Existing Code"** - Martin Fowler

### Kent Beck의 글
- "Augmented Coding: Beyond the Vibes" - Tidy First Newsletter
- "Test-Driven Development as a Prompt Engineering" 개념

### AI와 TDD
- The Pragmatic Engineer - "TDD, AI agents and coding with Kent Beck"
- TDD as a "superpower" for AI coding
