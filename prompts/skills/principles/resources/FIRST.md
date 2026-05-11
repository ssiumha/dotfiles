---
name: FIRST
full_name: "FIRST Principles of Unit Testing"
category: testing
origin: Tim Ottinger & Jeff Langr (2005), 대중화는 Robert C. Martin *Clean Code* (2008)
one_liner: "테스트는 Fast, Independent, Repeatable, Self-validating, Timely해야 한다"
---

# FIRST — 단위 테스트의 5대 품질 속성

## 정의

> Fast · Independent · Repeatable · Self-validating · Timely

좋은 단위 테스트가 갖춰야 할 5가지 속성. 하나라도 빠지면 테스트 스위트는 빠르게 망가진다. 느린 테스트는 돌리지 않게 되고, 순서에 의존하면 플레이키해지고, assert가 없으면 있으나 마나다.

## 5가지 속성

| 속성 | 의미 | 기본 임계값 |
|------|------|-------------|
| **Fast** | 단위 테스트 1건은 ms 단위. 느리면 개발자가 돌리지 않는다 | 단위 테스트 <100ms, 전체 스위트 <10s |
| **Independent** | 테스트 간 순서·공유 상태 의존 없음. 단독 실행도 성공 | 랜덤 실행 통과율 100% |
| **Repeatable** | 같은 코드면 항상 같은 결과. 환경·시간·네트워크에 비의존 | 100회 연속 실행 동일 결과 |
| **Self-validating** | assert로 통과/실패가 자동 판정. "로그 보고 판단"은 실패 | 테스트당 의미 있는 assert ≥1 |
| **Timely** | 코드와 같은 시점에 작성. "나중에 쓸게"는 영영 안 쓴다 | 구현 PR과 동일 PR에 테스트 |

## 핵심 판단

- **"이 테스트를 100번 돌려도 같은 결과가 나오는가?"** — 아니면 Repeatable 위반
- **"이 테스트 하나만 돌려도 통과하는가?"** — 아니면 Independent 위반
- **"assert가 있는가, 있다면 의미 있게 검증하는가?"** — `assert True`는 Self-validating 위반
- **"테스트 실행 시간이 피드백 루프를 방해하는가?"** — 그렇다면 Fast 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 속성 | 신호 | 검증 방법 |
|------|------|-----------|
| Fast | 테스트 런타임 >1s | 테스트 프레임워크 리포트 |
| Fast | `time.sleep`, `setTimeout`, 실제 네트워크 호출 | grep `sleep\|network\|requests\.` |
| Independent | 전역/모듈 변수 수정 | grep `global \|cls\.`, 클래스 변수 공유 |
| Independent | 번호 붙은 테스트명 | grep `test_[0-9]+_` |
| Independent | 랜덤 실행 시 실패 | `pytest --randomly`, Jest `--randomize` |
| Repeatable | `Date.now()`, `datetime.now()` 직접 사용 | grep 시간 관련 API |
| Repeatable | seed 없는 랜덤 | grep `random\(\)`, `Math.random` |
| Self-validating | assert/expect 0개 | grep 테스트 함수 내 assert 부재 |
| Self-validating | `assert True`, tautology | grep `assert True`, `expect(true)` |
| Timely | 구현 파일만 변경된 PR | git show --stat 로 테스트 동반 여부 |

### 판단 필요

| 속성 | 신호 |
|------|------|
| Fast | "테스트는 커피 한 잔 마시고 와야 끝남" |
| Independent | "혼자 돌리면 되는데 전체 돌리면 깨짐" |
| Repeatable | "가끔 깨져요. 재시도하면 됩니다" (flaky) |
| Self-validating | "수동으로 출력 확인해야 함" |
| Timely | "테스트는 다음 스프린트에 추가하겠습니다" |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 5속성 모두 충족. 느린 테스트 <5%, 플레이키 0%, assert 부재 0건 |
| **WARN** | 1-2개 속성 경계선 (느린 테스트 5-15%, 플레이키 1-3건) |
| **FAIL** | Independent/Repeatable 위반 있음 OR Self-validating 위반 다수 OR 느린 테스트 >15% |

## 속성별 개선 패턴

### Fast — 느린 테스트 잡기

| 원인 | 처방 |
|------|------|
| 실제 네트워크 호출 | Fake/in-process stub |
| 실제 DB | in-memory DB (SQLite), 트랜잭션 롤백 |
| `sleep` 기반 대기 | 이벤트 기반 대기 (`waitUntil`) |
| 큰 fixture | 최소 fixture + 필요한 것만 |

### Independent — 순서 의존 잡기

```python
# ❌ Independent 위반
class TestUserFlow:
    user = None  # 공유 상태

    def test_1_create(self):
        TestUserFlow.user = create_user()

    def test_2_update(self):
        TestUserFlow.user.name = "Bob"  # test_1에 의존

# ✅ Independent
def test_create_user():
    user = create_user()
    assert user.id

def test_update_user_name():
    user = create_user()  # 각 테스트가 직접 생성
    user.name = "Bob"
    user.save()
    assert User.find(user.id).name == "Bob"
```

### Repeatable — 결정적 실행 만들기

```python
# ❌ Repeatable 위반
def test_expires_soon():
    token = create_token()
    assert token.expires_at > datetime.now()  # 실행 시점 의존

# ✅ 시간 주입
def test_expires_soon(frozen_clock):
    frozen_clock.set("2026-01-01T00:00:00Z")
    token = create_token()
    assert token.expires_at.year == 2026
```

### Self-validating — 진짜 검증 추가

```python
# ❌ 호출만 함
def test_process():
    result = process(order)
    assert result is not None  # None만 아니면 통과

# ✅ 구체적 검증
def test_process_calculates_total():
    order = Order(items=[Item("book", 10000)])
    result = process(order)
    assert result.total == 10000
    assert result.status == "processed"
```

### Timely — 함께 작성

- TDD: 실패 테스트 → 구현 → 통과 순서
- TAD(Test After Development)도 가능하나 같은 PR 안에서
- "나중에 테스트 추가" PR은 머지하지 않는 룰

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[SELF-TESTING-CODE]] | FIRST는 개별 테스트의 5속성, Self-Testing은 코드베이스 전체의 disciplined practice. FIRST가 "테스트가 어떻게 작동해야 하나", Self-Testing이 "그 테스트가 빌드와 어떻게 결합되어야 하나" |
| [[BEYONCE-RULE]] | Timely = "중요하면 지금 테스트하라". FIRST가 HOW, Beyoncé가 WHAT |
| [[FAIL-FAST]] | Self-validating이 fail fast의 테스트 계층 구현 |
| [[TEST-BEHAVIOR]] | Independent/Repeatable을 깨는 주 원인이 구현 의존 테스트 |
| [[TEST-SMELLS]] | Slow Test → Fast, Test Run War → Independent, Dead Test → Self-validating |
| [[GOODHARTS-LAW]] | "테스트 수"를 목표화하면 Self-validating 무의미 테스트 양산 |

## 주의

- FIRST는 **단위 테스트** 기준. 통합/E2E는 Fast(상대적)를 완화해도 된다
- Self-validating ≠ "assert 많이". 단일 개념 검증이 더 명확하다 (Assertion Roulette 주의)
- Timely는 테스트 주도 개발(TDD)을 강제하지 않는다. 핵심은 **같은 시점**
- Repeatable 깨지는 1순위 원인은 시간(`now()`), 2순위는 시드 없는 랜덤, 3순위는 순서 의존
