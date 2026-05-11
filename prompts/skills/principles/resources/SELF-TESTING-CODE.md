---
name: SELF-TESTING-CODE
full_name: Self-Testing Code
category: testing
origin: Martin Fowler "Refactoring" (1999) → Fowler bliki "SelfTestingCode" (2014). XP의 핵심 실천(Kent Beck, 1999)과 같은 시기에 정착
one_liner: "테스트가 빌드와 결합되어 변경마다 자동 실행되어야 한다 — 그 외의 테스트는 옵션일 뿐"
---

# SELF-TESTING-CODE — 자체 테스트 가능한 코드

## 정의

> "You have Self-Testing Code when you can run a series of automated tests against the code base and if the tests pass you know there are no significant bugs in the code base. ... As you develop, you write tests so frequently that the act of writing tests becomes integrated with the act of writing the code itself." — Martin Fowler

테스트가 "있다"가 아니라, **5가지 조건을 모두 만족**해야 self-testing이다:

1. **자동화** — 사람의 클릭/확인 불필요
2. **빠름** — 변경 직후 즉시 실행 가능 (단위 테스트 보통 1분 이내)
3. **결정적** — 같은 코드 = 같은 결과 (flaky 아님)
4. **광범위** — 통과 = "심각한 버그 없음"이라 신뢰할 수 있을 만큼
5. **빌드에 묶임** — 테스트 실패 = 빌드 실패. 실행이 옵션이 아님

> "Self-testing code is a key enabler for many other techniques: continuous integration, refactoring, evolutionary design, etc. Without self-testing code, these things are impractical or impossible." — Fowler

## 핵심 판단

- **"테스트 통과 = 안전하게 배포 가능?"** — 아니면 self-testing 아님
- **"테스트가 빌드/CI에 강제로 포함되는가?"** — 옵션이면 안 돌림
- **"단위 테스트가 변경 직후 돌릴 만큼 빠른가?"** — 30분이면 아무도 안 돌림
- **"flaky 테스트를 즉시 격리/수정하는가, 방치하는가?"** — 방치 = 신뢰도 0

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 빌드 명령에 테스트 미포함 | `make`/`just`/CI yaml에 test 단계 부재 |
| 커버리지 시계열 하락 추세 | coverage 리포트 비교 |
| 단위 테스트 실행 시간 > 5분 | CI 로그 시간 측정 |
| flaky 테스트 방치 | `@flaky\|skip\|pending\|xit` 카운트 추세 |
| 핵심 모듈 커버리지 0 또는 매우 낮음 | 커버리지 리포트 + 변경 빈도 교차 |
| PR에 테스트 추가 비율 낮음 | PR diff에서 test 파일 변경 비율 |
| 새 기능 머지 후 테스트 실패 발견 빈도 | post-merge revert/hotfix 비율 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "로컬에서는 통과했는데" | 환경 의존, 결정성 부재 |
| "이 테스트는 가끔 실패해요" | flaky 방치 |
| "테스트 돌리려면 30분 걸려요" | 변경마다 안 돌림 |
| "그 영역은 테스트가 없어서 무서워요" | Self-Testing 부재의 자백 |
| 수동 QA로 회귀 잡는 문화 | 테스트가 신뢰 안 됨 |
| "릴리스 전에만 전체 테스트" | 통합 빈도 부족 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 빌드=테스트 통과, 단위 1분 이내, flaky 0, 핵심 모듈 커버리지 80%+, PR마다 테스트 함께 |
| **WARN** | 빌드에 묶이나 일부 영역 커버리지 낮음, 단위 5분 이내, flaky 1-2개 추적 중 |
| **FAIL** | 테스트가 빌드 옵션 OR 커버리지 50% 미만 OR 단위 10분+ OR flaky 다수 방치 OR 수동 QA 의존 |

## Self-Testing의 5조건 — 무엇이 빠지면 무너지나

```
1. 자동화 빠짐 → "이번 릴리스는 QA 팀이 수동으로..."
                  → CI 불가, 회귀 늦게 발견

2. 빠름 빠짐  → 단위 테스트 30분
                → 개발자가 변경 후 안 돌림 → 통합 시점에 폭발

3. 결정성 빠짐 → flaky 테스트 방치
                 → "또 그거네 retry"가 표준 → 진짜 실패 묻힘

4. 광범위 빠짐 → 커버리지 30%
                 → 통과해도 안전하다고 신뢰 불가
                 → 결국 수동 검증 병행

5. 빌드 결합 빠짐 → `make build`만 돌리면 끝
                    → 테스트는 "원하는 사람만"
                    → 테스트가 깨진 채 머지됨
```

5개 중 하나라도 빠지면 **다른 모든 실천이 흔들린다**: CI는 의미 없고, 리팩토링은 도박이고, 신규 입사자는 두려워한다.

## 좋은 예 vs 나쁜 예

```yaml
# ❌ Self-Testing 위반 예시 (CI yaml)
build:
  - npm install
  - npm run build
test:                  # ← 별도 job, 실패해도 빌드는 통과 가능
  - npm test
  continue-on-error: true  # ← flaky 우회

# ✅ Self-Testing 만족
build:
  - npm install
  - npm run build
  - npm test           # ← 같은 단계, 실패 시 즉시 빌드 실패
  - npm run test:coverage -- --threshold=80  # ← 커버리지 게이트
```

```python
# ❌ flaky 방치
@pytest.mark.flaky(reruns=5)  # 5번 다시 돌려보자
def test_payment_async():
    ...  # 진짜 race condition을 회피만 함

# ✅ flaky를 결정적으로
def test_payment_async():
    with freeze_time("2026-04-23 10:00:00"):  # 시간 고정
        result = process_payment(...)
        assert result.status == "completed"  # 결정적
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 테스트가 빌드와 분리됨 | **빌드 단계에 통합** — `make build`가 `test` 실행, 실패 시 빌드 실패 |
| 테스트 실행이 너무 느림 | **단위/통합 분리, 병렬화, fixture 캐싱** — 단위는 1분 이내 목표 |
| flaky 테스트 누적 | **즉시 격리 + 기한 내 수정** — 격리 1주 + 미수정 시 삭제 |
| 핵심 모듈 커버리지 0 | **Characterization Test 먼저** — 동작 캡처 후 리팩토링 |
| 새 기능에 테스트 부재 | **CI에서 PR 단위 커버리지 게이트** (Codecov patch coverage 등) |
| "릴리스 전 전체 테스트" 문화 | **commit/push마다 자동 실행** — feedback loop 단축 |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[FIRST]] | FIRST는 개별 테스트의 5속성, Self-Testing은 코드베이스 전체의 disciplined practice. 메타 차원 |
| [[TEST-PYRAMID]] | Pyramid는 단위/통합/E2E 비율, Self-Testing은 "무엇이든 빌드와 결합되어 자동 실행되는가" |
| [[BEYONCE-RULE]] | 중요한 것은 테스트로 보호 — Self-Testing이 그 보호를 자동 강제하는 시스템 |
| [[BROKEN-WINDOWS]] | flaky 방치/커버리지 하락은 깨진 유리창, Self-Testing이 시스템 강제 형태 |
| [[COLLECTIVE-OWNERSHIP]] | 테스트 보호 없이는 Collective Ownership 불가 — 다른 사람이 안전하게 못 만짐 |
| [[REFACTORING]] (skill) | Fowler의 원전 메시지: "Self-Testing 없이는 안전한 리팩토링 불가" |
| [[CHESTERTONS-FENCE]] | 테스트는 "왜 이렇게 짰는지"의 실행 가능한 형태 — 제거 시 무엇이 깨지는지 즉시 알려줌 |

## 잘못된 통념 교정

| 통념 | 실제 |
|------|------|
| "테스트 코드 짜기 = Self-Testing" | 빌드와 결합 + 5조건 만족이어야 |
| "커버리지 100%면 self-testing" | 커버리지는 측정 한 단면. flaky/느림이면 무용 |
| "TDD 안 하면 self-testing 안 됨" | TDD는 한 방법, self-testing은 결과. 사후 작성도 self-testing 가능 |
| "테스트는 QA 팀 일" | self-testing은 작성자가 함께 짜는 것 — XP의 핵심 |

## 주의

- self-testing은 도달점이지 한 번에 만드는 것이 아님. **추세가 중요** — 커버리지 ↑, flaky ↓, 실행 시간 →
- 레거시 코드에 갑자기 80% 커버리지를 강제하면 잘못된 테스트만 양산. **변경하는 영역부터 점진적**
- "1분 단위 테스트"는 절대 기준이 아님. 프로젝트 크기에 따라 다름. 핵심은 **개발자가 변경마다 돌릴 만큼 빠른가**
- E2E는 Self-Testing 정의에 포함되되 비율은 작아야 함 ([[TEST-PYRAMID]])
- 보안/규제 영역에서는 수동 검증이 추가로 필요할 수 있다 — Self-Testing이 그것을 대체하진 않음
- Self-Testing은 코드 품질의 **결과** 측정 도구이기도 하다 — 테스트하기 어려운 코드 = 결합도 높은 코드 ([[COHESION-COUPLING]])
