# CI/CD Pipelines

GitLab CI 파이프라인 설정 가이드입니다.

> **GitHub Actions**: `/github-action` skill을 참조하세요.

## GitLab CI

### 기본 파이프라인

**.gitlab-ci.yml**
```yaml
image: node:20-alpine

stages:
  - lint
  - test
  - build

variables:
  POSTGRES_DB: test_db
  POSTGRES_USER: test_user
  POSTGRES_PASSWORD: test_pass

services:
  - postgres:16-alpine

before_script:
  - npm ci

lint:
  stage: lint
  script:
    - npm run lint
    - npm run typecheck

test:
  stage: test
  variables:
    DATABASE_URL: "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB"
  script:
    - npm run test:unit
    - npm run test:e2e
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'

build:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  only:
    - main
```

### 캐싱

```yaml
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/
    - .npm/

before_script:
  - npm ci --cache .npm --prefer-offline
```

### 시크릿 관리

```yaml
# GitLab CI (Settings > CI/CD > Variables)
variables:
  DATABASE_URL: $CI_DATABASE_URL
```

## compose.test.yaml

```yaml
services:
  test-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_pass
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test_user"]
      interval: 5s
      timeout: 5s
      retries: 5
    tmpfs:
      - /var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
```

## 참고

- GitLab CI: https://docs.gitlab.com/ee/ci/
- GitHub Actions: `/github-action` skill
