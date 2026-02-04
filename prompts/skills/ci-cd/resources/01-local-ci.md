# Local CI Automation

로컬 개발 환경에서 lint와 test를 자동으로 실행하는 패턴입니다.

## 핵심 개념

- **Justfile**: Make보다 간결한 task runner
- **E2E 테스트**: 실제 DB 컨테이너 사용 (Mock 최소화)
- **Pre-commit hooks**: 커밋 전 자동 검증
- **언어별 도구**: `languages/{언어}.md` 참조

## Justfile 패턴

### 기본 구조

```justfile
# 기본: just 명령 시 help 표시
default:
    @just --list

# Lint
lint:
    npx biome check .

# Test
test:
    npx vitest run

# Format
format:
    npx biome format --write .

# 전체 CI
ci: lint test
    @echo "✓ All checks passed!"

# 개발 서버
dev:
    npm run dev
```

### 변수 및 환경

```justfile
# 환경변수 기본값
db_url := env_var_or_default('DATABASE_URL', 'postgres://localhost/dev')

# DB 마이그레이션
migrate:
    DATABASE_URL={{db_url}} npx prisma migrate dev

# 의존성 체크 후 테스트
test: install-if-needed
    npm test

install-if-needed:
    [ -d node_modules ] || npm install
```

## E2E 테스트 전략

### compose.yaml (테스트용)

```yaml
services:
  test-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_pass
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test_user"]
      interval: 5s
      timeout: 5s
      retries: 5
    tmpfs:
      - /var/lib/postgresql/data  # 메모리 사용 (빠름)
```

### Justfile 통합

```justfile
# 테스트 DB 시작
db-test-up:
    docker compose up -d test-db
    @until docker compose exec test-db pg_isready -U test_user; do sleep 1; done

# 테스트 DB 정리
db-test-down:
    docker compose down test-db -v

# E2E 테스트
test-e2e: db-test-up
    DATABASE_URL=postgres://test_user:test_pass@localhost:5433/test_db npm run test:e2e
    just db-test-down
```

### 테스트 격리 (Transaction Rollback)

```typescript
// 각 테스트 후 롤백
beforeEach(async () => {
  await db.raw('BEGIN')
})

afterEach(async () => {
  await db.raw('ROLLBACK')
})
```

## Pre-commit Hooks

### Husky (Node.js)

```json
{
  "scripts": {
    "prepare": "husky install"
  },
  "devDependencies": {
    "husky": "^8.0.0",
    "lint-staged": "^14.0.0"
  }
}
```

**.husky/pre-commit**
```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
just test-unit
```

**lint-staged**
```json
{
  "lint-staged": {
    "*.{js,ts}": ["biome check --apply"],
    "*.{json,md}": ["biome format --write"]
  }
}
```

## 공통 Justfile 태스크

```justfile
# 의존성 관리
install:
    npm install

update:
    npm update

audit:
    npm audit

# 정리
clean:
    rm -rf dist/ build/

clean-all: clean
    rm -rf node_modules/

clean-docker:
    docker compose down -v

# 개발 워크플로우
setup: install
    just db-up
    just migrate

dev:
    npm run dev

check: lint test
    @echo "✓ Ready to commit"

# DB 관리
db-up:
    docker compose up -d

db-down:
    docker compose down

db-logs:
    docker compose logs -f db

db-shell:
    docker compose exec db psql -U user -d app_dev
```

## 베스트 프랙티스

### 빠른 피드백
- Lint: 5초 이내
- 유닛 테스트: 30초 이내
- E2E는 별도 명령 (`just test-e2e`)

### 점진적 실행
```justfile
quick: lint test-unit
full: lint test-unit test-e2e
ci: full build
```

### 캐시 활용
```justfile
# 변경된 파일만 lint
lint-changed:
    git diff --name-only | grep '\.ts$' | xargs biome check

# 변경된 테스트만
test-changed:
    vitest --changed
```

## 트러블슈팅

### DB 연결 실패
```justfile
db-health:
    docker compose exec test-db pg_isready -U test_user

db-logs:
    docker compose logs test-db
```

## 참고

- Just: https://github.com/casey/just
- Docker Compose: https://docs.docker.com/compose/
- 언어별 도구: `languages/{언어}.md`
