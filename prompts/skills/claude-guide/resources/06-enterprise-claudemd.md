## 대규모 프로젝트 CLAUDE.md

대규모 엔터프라이즈 프로젝트는 일반 권장 범위를 초과할 수 있습니다.

### 언제 200줄+ CLAUDE.md가 필요한가?

- 프로젝트 고유 규칙이 많은 경우 (REST API 표준, 로깅 표준, i18n 등)
- DDD 같은 복잡한 아키텍처를 사용하는 경우
- 규제 준수 요구사항이 있는 경우 (금융, 의료 등)
- 체크리스트가 필요한 경우 (새 Controller, 새 Service 등)

### 대규모 프로젝트 권장 섹션

```markdown
1. Project Overview        # 프로젝트 개요
2. Quick Commands          # 개발 명령어
3. Services                # 서비스 엔드포인트
4. Environment Variables   # 환경변수
5. Architecture            # 아키텍처 가이드라인 (패키지 구조, 계층 의존성)
6. REST API Standards      # API 응답 패턴, 로깅 표준
7. Internationalization    # i18n 메시지 사용법
8. Swagger Documentation   # API 문서화 규칙
9. Checklists              # 체크리스트 (새 컨트롤러, 새 서비스, PR)
10. Testing Strategy       # 테스트 전략, 디렉토리 구조
11. Troubleshooting        # 자주 발생하는 문제 해결
12. References             # 상세 문서 링크
```

### 코드 예시 패턴 (✅/❌)

올바른 방법과 잘못된 방법을 대비하여 명확하게 가이드:

```java
// ✅ 올바른 패턴: ApiResult 래퍼 사용
@PostMapping
public ResponseEntity<ApiResult<UserResponse>> createUser(...) {
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(ApiResult.success(response, message));
}

// ❌ 잘못된 패턴: ApiResult 없이 직접 반환
@GetMapping
public ResponseEntity<List<UserResponse>> getUsers() {
    return ResponseEntity.ok(service.getAll());  // 이렇게 하지 마세요
}
```

**효과**: AI가 명확한 패턴을 학습하여 일관된 코드 생성

### 체크리스트 패턴

새 기능 구현 시 빠뜨리기 쉬운 사항을 명시적으로 나열:

```markdown
### New Controller Checklist

- [ ] **ApiResult 패턴 적용**: 모든 엔드포인트가 `ResponseEntity<ApiResult<T>>` 반환
- [ ] **MessageSourceService 주입**: 다국어 메시지 처리를 위해 필수
- [ ] **Swagger 문서화**: `@Tag`, `@Operation`, `@ApiResponses` 어노테이션 추가
- [ ] **로깅 표준 준수**: GET은 `debug`, POST/PUT/DELETE는 `info` 레벨
- [ ] **메시지 파일 업데이트**: messages_ko.properties에 메시지 키 추가
```

**효과**: AI가 코드 생성 후 자체 검증 가능

### 템플릿

대규모 프로젝트용 템플릿: `templates/enterprise.md`

---

## CLAUDE.md 예시

```markdown
# MyApp

웹 기반 사용자 관리 시스템

## 퀵 커맨드
- Build: `npm run build`
- Dev: `npm run dev` (http://localhost:3000)
- Test: `npm test`
- Deploy: `./scripts/deploy.sh`

## 서비스
- API: http://localhost:3000/api
- Admin: http://localhost:3001
- Redis: localhost:6379

## 환경변수 필수
- DATABASE_URL
- REDIS_URL
- JWT_SECRET

## 주의사항
- DB 마이그레이션은 항상 백업 후 실행
- Redis는 개발 시 docker compose로 자동 실행
```
