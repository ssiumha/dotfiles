---
name: code-review-typescript
description: TypeScript type safety review checklist. Injected into code-reviewer agent for TypeScript/TSX projects.
---

# TypeScript Type Safety Review

TypeScript/TSX 코드의 타입 안전성을 검증하는 체크리스트.

## Checks

### Critical
- **any type usage**: `: any` 또는 `as any` 사용
- **Type assertions abuse**: `as` 키워드로 타입 체크 우회
- **@ts-ignore/@ts-expect-error**: 정당한 사유 없이 타입 에러 억제

### High
- **Implicit any**: 파라미터, 변수, 반환 타입에 암시적 any
- **Loose type definitions**: `object`, `Function`, `{}` 대신 구체적 타입 사용
- **Type narrowing missing**: null/undefined 체크 없이 접근

### Configuration
- **strict mode**: `tsconfig.json`에 `"strict": true` 필수
- **noImplicitAny**: 활성화 확인
- **strictNullChecks**: 활성화 확인

## Detection Patterns

```typescript
// Critical
: any                  // any 타입
as any                 // any 단언
@ts-ignore             // 타입 에러 무시
@ts-expect-error       // 타입 에러 억제

// High
function fn(data) {}   // 암시적 any
: object               // 느슨한 타입
: Function             // 느슨한 타입
: {}                   // 빈 오브젝트 타입
```

## Output

`code-reviewer` 리뷰 결과의 Issues 섹션에 통합:

**[Critical/High/Medium]** `파일:라인` - 타입 안전성 문제 → 수정 예시
