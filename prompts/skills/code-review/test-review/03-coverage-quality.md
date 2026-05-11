
# 커버리지 품질 분석

커버리지 **수치**가 아닌 **질적** 측면을 분석한다.

> **원칙 위임**: 평가 기준(의미 있는 assert·Happy/Edge/Error 균형·Mutation 사고실험)은 `/principles check BEYONCE-RULE` 참조. 본 문서는 test-review 흐름용 Grep 힌트와 체크리스트에 집중.

---

## 1. 피상적 Assert 감지 (Grep)

```
assert .* is not None
assert isinstance
assert len\(.+\) > 0
expect\(.+\)\.toBeDefined
expect\(.+\)\.toBeTruthy
```

수준 분류는 BEYONCE-RULE "의미 있는 assert vs 피상적" 표 참조.

## 2. Branch 커버리지 조합 체크 (수행)

Line 커버리지 100%로는 조건 조합을 보장하지 못한다.

| 패턴 | 확인 조합 |
|------|----------|
| `if A and B` | A=True/B=False, A=False/B=True |
| `if A or B` | A=False/B=True, A=True/B=False |
| `try/except` | except 분기 실제 트리거 |
| `switch/match` | 모든 case + default |
| 삼항 연산자 | 양쪽 결과 |
| early return | return 전후 경로 모두 |

## 3. Dead Test 감지 (수행)

| 유형 | 감지 힌트 |
|------|----------|
| Assert 없음 | 테스트별 assert/expect 카운트 = 0 |
| 항상 통과 | `assert True`, `expect(true).toBe(true)` |
| Skip 방치 | `@.*skip` + reason 없음 또는 장기 존재 |
| 주석 처리 | `^\s*#.*def test_\|^\s*\/\/.*it\(` |
| 구현 변경 후 미갱신 | 실제 구현 대비 assert가 stale한지 수동 확인 |

> 심각도·원칙 관점은 `/principles check TEST-SMELLS` (Dead Test) 및 `/principles check BEYONCE-RULE` 참조.

## 4. Mutation 사고실험 (선택)

실제 mutation testing을 돌리지 않더라도, 구현 핵심 로직에 가상의 변경을 적용하고 어떤 테스트가 실패할지 추론한다. 방법론은 `/principles check BEYONCE-RULE` 참조.

---

## 리포트 형식

```markdown
## 커버리지 품질

| 항목 | 상태 | 비고 |
|------|:---:|------|
| 의미 있는 assert | ✅/⚠️/❌ | 피상적 assert N건 |
| Happy/Edge/Error 균형 | ✅/⚠️/❌ | Edge case N건 누락 |
| Branch 조합 | ✅/⚠️/❌ | else/and-조합 미커버 N건 |
| Dead test | ✅/⚠️/❌ | assert 없는 테스트 N건, skip 방치 N건 |
| Mutation 사고실험 | ✅/⚠️/❌ | 핵심 로직 미커버 N건 |
```
