---
name: code-review-python
description: Python type hints and typing review checklist. Injected into code-reviewer agent for Python projects. Use when reviewing Python code for type safety or auditing type annotations.
---

# Python Type Safety Review

Python 코드의 타입 힌트와 타입 안전성을 검증하는 체크리스트.

## Checks

### Critical
- **Any overuse**: `typing.Any` 남용으로 타입 안전성 무력화
- **Type ignore abuse**: `# type: ignore` 정당한 사유 없이 사용
- **Untyped public APIs**: public 함수/메서드에 타입 어노테이션 누락

### High
- **Missing function signatures**: 파라미터/반환 타입 누락
- **Missing return types**: `-> ReturnType` 어노테이션 없음
- **Generic collections**: `list`, `dict` 대신 `list[T]`, `dict[K, V]` 사용
- **Optional handling**: nullable 값에 `Optional[T]` 또는 `T | None` 미사용

### Medium
- **Incomplete annotations**: typed/untyped 파라미터 혼재
- **Type compatibility**: 할당 시 타입 불일치
- **Import issues**: `typing` 모듈 import 누락

## Detection Patterns

```python
# Critical
Any                    # typing.Any 사용
# type: ignore         # 타입 에러 억제
def public_func(data): # 타입 없는 public 함수

# High
def func(x):          # 파라미터 타입 누락
def func() -> None:   # 반환 타입 확인
list, dict             # Generic 미사용 (3.9+ 기준)
```

## Output

`code-reviewer` 리뷰 결과의 Issues 섹션에 통합:

**[Critical/High/Medium]** `파일:라인` - 타이핑 문제 → 수정 예시
