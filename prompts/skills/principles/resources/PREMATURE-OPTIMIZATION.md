---
name: PREMATURE-OPTIMIZATION
full_name: Premature Optimization Is the Root of All Evil
category: simplicity
origin: Donald Knuth, "Structured Programming with go to Statements" *ACM Computing Surveys* (1974) — Tony Hoare가 먼저 언급한 것을 Knuth가 정착
one_liner: "측정 없이 최적화하지 마라. 97%는 잊고 결정적 3%에만 집중"
---

# PREMATURE-OPTIMIZATION — 섣부른 최적화

## 정의

> "Programmers waste enormous amounts of time thinking about, or worrying about, the speed of non-critical parts of their programs, and these attempts at efficiency actually have a strong negative impact when debugging and maintenance are considered. **We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil.** Yet we should not pass up our opportunities in that critical 3%." — Knuth, 1974

흔히 "최적화하지 마라"로 잘못 인용되지만, Knuth의 진짜 주장은 다르다:

1. **97%의 코드에서 작은 효율성은 잊어라** — 핫스팟 외 최적화는 시간 낭비 + 가독성/디버깅 비용
2. **결정적인 3%의 기회는 놓치지 마라** — 무조건 단순함이 아니라 **측정 후 핵심 집중**
3. **"premature"가 핵심** — 측정 전에 한 최적화가 잘못된 것
4. **profiling 도구가 답** — 추측이 아닌 측정

## 핵심 판단

- **"이 최적화가 핫스팟에 있는가?"** — 프로파일러로 확인했는가
- **"단순한 대안 대비 얼마나 빠른가?"** — 측정값이 있는가, 추측인가
- **"이 복잡도의 가독성 비용을 정당화하는가?"** — 1ms 위해 100줄을 더 복잡하게?
- **"JIT/컴파일러/런타임이 이미 해주는 일은 아닌가?"** — loop unrolling, inlining, escape analysis 등

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| "성능을 위해" / "최적화" 주석에 벤치마크 결과 부재 | grep `optim\|성능\|perf` 후 인근 수치 부재 비율 |
| 비핫스팟에 수동 캐싱 / 메모이제이션 | 캐시 변수 위치 vs 프로파일링 결과 |
| 비트 트릭 / loop unrolling이 일반 비즈니스 로직에 | grep 비트 연산자 + 도메인 코드 위치 |
| 마이크로벤치마크 결과 코드에 / 커밋 메시지에 부재 | 성능 변경 PR에 측정 첨부 비율 |
| 복잡한 자료구조가 작은 N(n≤100)에 사용 | 자료구조 선택 vs 데이터 크기 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "혹시 모르니 빠르게" 추가된 캐시 | 측정 없는 추측 |
| 가독성 명백히 희생한 코드에 단순 대안 비교 부재 | 결정 근거 부재 |
| 같은 함수에 최적화 시도가 여러 번 반복 | 잘못된 곳을 만지고 있음 |
| 알고리즘 복잡도 개선 없이 상수만 줄이려는 시도 | 본질적 개선이 아님 |
| 핫스팟이 무엇인지 팀이 답하지 못함 | 측정 자체가 안 됨 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 성능 변경에 벤치마크 첨부, 핫스팟 분석 후 최적화, 단순 대안 비교 존재 |
| **WARN** | 일부 최적화에 근거 부재이나 비핫스팟이고 영향 작음 |
| **FAIL** | 측정 없는 최적화 다수 OR 핫스팟 외 영역의 복잡한 최적화 OR "성능을 위해" 주석에 수치 0 |

## Knuth가 진짜 말한 것 vs 잘못된 인용

```
❌ 잘못된 인용
"Premature optimization is the root of all evil"
→ "최적화는 악이다, 하지 마라"

✅ Knuth의 원문 맥락
"We should forget about small efficiencies, say about 97% of the time:
 premature optimization is the root of all evil.
 Yet we should not pass up our opportunities in that critical 3%."
→ "측정 없이 추측으로 하는 작은 최적화가 악이다.
   결정적 3%는 반드시 잡아라."
```

같은 1974년 논문에서 Knuth는 **프로파일러의 가치**를 강하게 옹호했다. "측정하라, 그 다음 최적화하라"가 진짜 메시지.

## 위반 패턴 예시

```python
# ❌ 비핫스팟의 비트 트릭 — 가독성 희생, 이득 0
def is_even(n):
    return (n & 1) == 0  # n % 2 == 0 가 명백

# ❌ 측정 없는 캐시 — 메모리 누수 + 복잡도
_cache = {}
def get_user_name(id):
    if id in _cache:  # 정말 병목? 캐시 무효화는?
        return _cache[id]
    name = db.query(...)
    _cache[id] = name
    return name

# ❌ "성능을 위해" 주석에 벤치마크 부재
# 성능을 위해 한 번에 처리
batch = []
for item in items:
    batch.append(transform(item))
    if len(batch) >= 100:
        process_batch(batch)
        batch = []
# → 벤치마크 결과? 단순 process(item) 대비 얼마나 빠른가?

# ✅ 측정 후 핫스팟에만
# Profiling 결과 image_resize가 80% 시간 차지 (cProfile, 2026-04-15)
# 단순 PIL: 850ms / Cython 확장: 120ms (7배)
@cython.compile
def image_resize(img, target):
    ...
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 추측 기반 최적화 | **프로파일러 먼저** — cProfile/perf/flamegraph로 핫스팟 확인 |
| "느린 것 같은" 코드 | **벤치마크 작성** — pytest-benchmark, hyperfine 등으로 측정 |
| 가독성 희생한 최적화 | **단순 대안과 비교 + 측정값 주석** — 정당화 못 하면 되돌림 |
| 비핫스팟의 복잡 코드 | **단순화** — 99% 시간 안 쓰는 곳은 단순함이 우선 |
| 알고리즘 복잡도 문제 | **자료구조/알고리즘 변경** — 상수 최적화는 마지막 |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[KISS]] | KISS는 일반론 "단순하게", PO는 성능 영역 특화 "측정 없는 복잡함은 악" |
| [[YAGNI]] | YAGNI는 기능, PO는 성능 — 둘 다 "필요할 때까지 하지 마라" 변형 |
| [[GOODHARTS-LAW]] | 잘못된 지표(마이크로벤치마크) 최적화 = 실제 성능 악화 가능 |
| [[LEAKY-ABSTRACTION]] | 모든 추상화는 누수 — 핫스팟에서 추상화 비용 측정 필요 |
| [[COMMENT-WHY]] | 최적화 코드는 WHY 주석 필수 (벤치마크 결과 + 단순 대안과의 차이) |

## 주의

- **반대 함정**: "Knuth가 최적화하지 말라 했어"로 핫스팟 최적화도 회피하는 것. 이건 원전 무시
- **3%는 진짜 3%가 아닐 수 있다** — 시스템마다 다름. 측정으로 정의
- 알고리즘 복잡도(O(n²) → O(n log n))는 "마이크로 최적화"가 아님. 처음부터 옳은 알고리즘 선택
- 컴파일러/런타임/JIT가 자동으로 해주는 최적화를 손으로 하면 오히려 방해 (escape analysis 깨기 등)
- "측정 = 프로파일러"만이 아니다. **로깅, APM, 사용자 응답시간** 모두 측정의 형태
- 보안 코드(timing attack)는 예외 — 일정 시간 보장이 정확성 요건
