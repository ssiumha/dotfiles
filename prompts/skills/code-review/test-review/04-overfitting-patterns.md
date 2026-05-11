
# Overfitting 패턴

> **Canonical**: 구현 세부사항 결합(fragile test) 원칙은 `/principles check TEST-BEHAVIOR`로 이동했다. 본 문서는 test-review 흐름에서 기계적 감지 Grep만 요약한다.

## 감지 Grep (빠른 스캔)

| 패턴 | Grep |
|------|------|
| 내부 상태 직접 접근 | `\._[a-z_]+\|\.internal[A-Z]\|\(.*as any\)\|\["_` |
| Mock 과다 (파일당 count) | `@patch\|@mock\.patch\|jest\.fn\(\)\|jest\.mock\|sinon\.stub\|vi\.fn\(\)\|vi\.mock` |
| Mock 호출 검증 | `assert_called\|toHaveBeenCalled\|calledWith\|callCount` |
| 하드코딩된 해시/토큰 | `assert.*==.*[\"'][a-f0-9]{32}\|expect.*toBe.*[\"'][a-f0-9]{32}` |
| 순서 의존 힌트 | `test_[0-9]+_\|global [a-z]\|cls\.\|self\.__class__\.` |
| 구현 구조 미러링 | (수동) 테스트가 구현의 step마다 assert |

## 종합 스캔 순서

```
1. Mock 과다 (count)
2. Mock 호출 검증
3. 내부 상태 접근
4. 순서 의존 힌트
5. 하드코딩 해시/토큰
```

## 판정·개선안

각 패턴의 예시, 심각도, 개선 방법(✅ 사례)은 `/principles check TEST-BEHAVIOR` 참조.
