
# Test Smell Catalog

> **Canonical**: 스멜의 정의·예시·스코어링은 `/principles check TEST-SMELLS`로 이동했다. 본 문서는 test-review 흐름에서 감지 Grep 패턴만 요약한다.

## 감지 Grep (빠른 스캔)

| Smell | 감지 힌트 |
|-------|----------|
| Eager Test | 테스트 1개에 assert 5개+ |
| Mystery Guest | `open\(['\"]/\|os\.environ\|os\.getenv` |
| Resource Optimism | `open\(['\"]/tmp/\|open\(['\"]\./\|urllib\|requests\.` |
| Test Run War | `global \|cls\.\|self\.__class__\.` |
| General Fixture | `setUp`/`beforeAll` 블록 10줄+ |
| Sensitive Equality | `assert.*str\(.*\)\|toEqual.*JSON\.stringify\|== .*0\.\d{5,}` |
| Slow Test | `time\.sleep\|await.*delay\|setTimeout` |
| Conditional Logic | 테스트 함수 내부 `if\|for\|while` |
| Obscure Test | `def test_[0-9]+$\|def test_[a-z]$` |
| Dead Test | `@.*skip\|assert True\|expect(true)\.toBe(true)\|assert 0개` |

## 판정·개선안

각 스멜에 대한 구체 예시, 심각도, 개선 패턴은 `/principles check TEST-SMELLS` 참조.
