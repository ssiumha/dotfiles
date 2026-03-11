# Docker & Compose

Docker 컨테이너 환경 및 compose.yaml 패턴 가이드입니다.

## compose.yaml (v2)

### 기본 구조

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://user:pass@db:5432/app_dev
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app_dev
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  db_data:
```

### 환경별 설정

**개발:** `compose.yaml`
**프로덕션:** `compose.prod.yaml` (오버라이드)

```bash
# 개발
docker compose up

# 프로덕션
docker compose -f compose.yaml -f compose.prod.yaml up
```

## Dockerfile 패턴

### 멀티스테이지 빌드

```dockerfile
# Base
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./

# Dependencies
FROM base AS deps
RUN npm ci

# Development
FROM base AS development
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Production
FROM node:20-alpine AS production
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
COPY --from=build --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs package*.json ./

USER nodejs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### 이미지 최적화

```dockerfile
# 1. Alpine 사용
FROM node:20-alpine

# 2. 레이어 캐싱
COPY package*.json ./
RUN npm ci
COPY . .

# 3. .dockerignore 활용
# 4. 멀티스테이지로 빌드 도구 제거
```

## .dockerignore

```
node_modules/
.git/
tests/
*.test.ts
coverage/
.env.local
dist/
.vscode/
.DS_Store
README.md
```

## Justfile 통합

```justfile
# Docker 시작
up:
    docker compose up -d

# 로그
logs service="":
    @if [ -z "{{service}}" ]; then \
        docker compose logs -f; \
    else \
        docker compose logs -f {{service}}; \
    fi

# 재시작
restart service:
    docker compose restart {{service}}

# 정지
down:
    docker compose down

# 정지 + 볼륨 삭제
down-volumes:
    docker compose down -v

# 빌드
build:
    docker compose build

# 빌드 + 시작
rebuild: build up

# 헬스체크
health:
    docker compose ps

# 셸 접속
shell service:
    docker compose exec {{service}} sh

# DB 접속
db-shell:
    docker compose exec db psql -U user -d app_dev
```

## 헬스체크

### PostgreSQL
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U $POSTGRES_USER"]
  interval: 5s
  timeout: 5s
  retries: 5
```

### Redis
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 5s
  timeout: 3s
  retries: 5
```

### HTTP
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## 환경변수

### .env

```
POSTGRES_DB=app_dev
POSTGRES_USER=user
POSTGRES_PASSWORD=pass
NODE_ENV=development
```

### compose.yaml

```yaml
services:
  app:
    env_file:
      - .env
    environment:
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
```

## 볼륨

### Named (프로덕션)
```yaml
volumes:
  db_data:
    driver: local
```

### Bind (개발)
```yaml
services:
  app:
    volumes:
      - .:/app
      - /app/node_modules
```

### tmpfs (테스트)
```yaml
services:
  test-db:
    tmpfs:
      - /var/lib/postgresql/data
```

## 베스트 프랙티스

### 보안
```dockerfile
# Non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs
```

### 리소스 제한
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

### 재시작 정책
```yaml
services:
  app:
    restart: unless-stopped  # 프로덕션
```

### 로깅
```yaml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 트러블슈팅

### 빌드 캐시
```bash
docker compose build --no-cache
```

## 참고

- Compose: https://docs.docker.com/compose/
- Dockerfile: https://docs.docker.com/develop/dev-best-practices/
- 멀티스테이지: https://docs.docker.com/build/building/multi-stage/
