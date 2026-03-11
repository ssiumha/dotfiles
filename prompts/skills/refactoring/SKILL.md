---
name: refactoring
description: "기존 코드의 안전한 리팩토링. Characterization Test로 동작 보존하며 구조 개선"
user-invocable: true
tags: [refactoring, characterization-test, behavior-preservation, legacy]
triggers:
  keywords: [리팩토링, 레거시 코드, 동작 보존, 구조 개선, 기존 코드 개선, characterization test]
---

# Refactoring

기존 코드를 안전하게 리팩토링하는 ANALYZE-PRESERVE-IMPROVE 워크플로우.

## tidy와의 구분

| | tidy | refactoring |
|--|------|-------------|
| 규모 | 분 단위 소규모 정리 | 시간~일 단위 구조 변경 |
| 테스트 | 기존 테스트 의존 | **Characterization Test 새로 작성** |
| 범위 | 단일 패턴 (guard clause, dead code 등) | 모듈 추출, 클래스 분리, API 마이그레이션 |
| 커밋 | 1 tidying = 1 commit | 단계별 incremental commit |

## tdd와의 구분

| | tdd | refactoring |
|--|---------------|-------------|
| 대상 | **새 기능** (코드 없음) | **기존 코드** (동작 있음) |
| 테스트 | Specification Test (기대 동작 정의) | Characterization Test (현재 동작 캡처) |
| 사이클 | RED-GREEN-REFACTOR | ANALYZE-PRESERVE-IMPROVE |

## ANALYZE-PRESERVE-IMPROVE Cycle

### Phase 1: ANALYZE

현재 코드 구조를 파악하고 리팩토링 대상을 식별한다.

**구조 분석**:
- 모듈 의존성, import 패턴 (`/dep-graph` 활용)
- 결합도 메트릭 (`/code-metrics` 활용)
- 데이터 흐름, 공유 상태, 결합 지점

**문제 패턴 식별** (ast-grep 활용):
- God class: 너무 많은 메서드/책임
- Feature envy: 다른 클래스 데이터를 과도하게 사용
- Long parameter list: 누락된 추상화
- Duplicate code: 모듈 간 중복 패턴

**산출물**: 현재 구조 + 문제 영역 + 리팩토링 대상 + 리스크 평가

### Phase 2: PRESERVE

변경 전 안전망을 구축한다. **이 단계를 건너뛰지 않는다.**

**Characterization Test 작성**:
1. 핵심 코드 경로를 식별
2. 경로를 실행하는 테스트 작성
3. 테스트를 먼저 실패시켜 **실제 출력**을 확인
4. 실제 출력을 기대값으로 업데이트
5. 놀라운 동작이 있으면 문서화

> Characterization Test는 "정답"을 검증하는 게 아니라 **"현재 동작"**을 기록한다.
> 리팩토링 후 이 테스트가 깨지면 동작이 바뀐 것이다.

네이밍: `test_characterize_{component}_{scenario}`

**Behavior Snapshot** (복잡한 출력일 때):
- API 응답, 직렬화 출력, 상태 변환, 에러 메시지

**Safety Net 검증**:
- 기존 테스트 100% 통과
- 새 characterization test가 리팩토링 대상을 커버
- Flaky 테스트 없음 확인

### Phase 3: IMPROVE

**한 번에 큰 변경을 하지 않는다.** 패턴:

```
가장 작은 구조 변경 → 전체 테스트 → 실패 시 즉시 revert → 성공 시 commit → 반복
```

**안전한 리팩토링 패턴**:
- **Extract Method**: 반복 코드 블록 또는 긴 메서드 → 명명된 함수로 분리
- **Extract Class**: 다중 책임 클래스 → 관련 메서드/필드를 새 클래스로 이동 (원본 API는 위임으로 유지)
- **Move Method**: Feature envy → 데이터가 있는 클래스로 이동
- **Inline**: 불필요한 간접 참조 제거
- **Rename**: ast-grep rewrite로 모든 참조를 원자적으로 변경

**각 변환 후 검증**:
1. Unit test (빠른 피드백)
2. Characterization test (동작 보존 확인)
3. 새 warning/error 없음 확인

## 실행 순서

```
1. 리팩토링 범위 확인 (SPEC 또는 사용자 요청)
2. ANALYZE: 대상 코드 구조 분석
3. PRESERVE: Characterization Test 작성 + 기존 테스트 통과 확인
4. IMPROVE: 점진적 변환 (각 단계마다 테스트 + 커밋)
5. 검증: 전후 메트릭 비교 + 모든 테스트 통과
```

## Behavior Preservation 원칙

리팩토링의 황금률: **관찰 가능한 동작이 전후 동일해야 한다.**

- 기존 테스트 전부 통과
- API 계약 동일
- 부작용(side effects) 동일
- 성능 특성이 허용 범위 내

## Troubleshooting

**테스트 실패 시**: 즉시 revert → 어떤 테스트가 왜 실패했는지 분석 → 더 작은 단위로 재시도

**Characterization Test가 flaky**: 비결정적 요소 식별 → 외부 의존성 mock → 시간/순서 의존 제거

**성능 저하**: 전후 프로파일링 → 핫 패스 확인 → 최적화 또는 트레이드오프 문서화

## See Also

- `/tidy` — 분 단위 소규모 코드 정리
- `/tdd` — 새 기능의 테스트 주도 개발
- `/code-metrics` — 결합도/복잡도 정량 측정
- `/dep-graph` — 파일 간 의존성 시각화
- `/strategic-thinking` — 리팩토링 범위 결정 시 체계적 판단

> Origin: moai-adk workflow-ddd (ANALYZE-PRESERVE-IMPROVE cycle) 기반, dots 스타일로 재구성
