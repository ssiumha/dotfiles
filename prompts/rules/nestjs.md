---
paths: "**/*.module.ts"
---

# NestJS 개발 규칙

## DI 안전성

> DI(Dependency Injection) 시점에 에러 발생 시 앱 전체 부팅 실패

### 생성자에서 예외 금지

```typescript
// ❌ 금지: 앱 부팅 실패
constructor() {
  if (process.env.APP_ENV === 'prod') {
    throw new NotFoundException();
  }
}
```

### 올바른 패턴

| 방식 | 적용 위치 | 예시 |
|------|----------|------|
| Guard | 클래스/메서드 | `@UseGuards(NonProdGuard)` |
| 메서드 체크 | 각 엔드포인트 | `if (prod) throw` |
| 조건부 등록 | 모듈 | `controllers: prod ? [] : [Ctrl]` |

### Guard 예시

```typescript
@Injectable()
export class NonProdGuard implements CanActivate {
  canActivate(): boolean {
    if (process.env.APP_ENV === 'prod') {
      throw new NotFoundException();
    }
    return true;
  }
}
```

## 생성자 허용 작업

- 의존성 주입
- 간단한 초기화 (예외 없이)
- 로깅

## 리뷰 체크포인트

생성자에 다음이 있으면 경고:
- `throw` 문
- 외부 API 호출
- 동기 파일 접근
