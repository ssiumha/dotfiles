# CI/CD Pipelines

GitHub Actions, GitLab CI 파이프라인 설정 가이드입니다.

## GitHub Actions

### 기본 워크플로우

**.github/workflows/ci.yml**
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test:unit

      - name: E2E tests
        run: npm run test:e2e
        env:
          DATABASE_URL: postgres://test_user:test_pass@localhost:5432/test_db

      - run: npm run build
```

### 매트릭스 빌드

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node-version: [18, 20, 21]

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
```

### 캐싱

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'

  - uses: actions/cache@v3
    with:
      path: |
        ~/.npm
        .next/cache
      key: ${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
```

### 브랜치별 전략

```yaml
on:
  push:
    branches:
      - main      # 프로덕션
      - develop   # 스테이징
  pull_request:
    branches: [main]
  release:
    types: [published]

jobs:
  deploy-prod:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploy to production"

  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploy to staging"
```

### compose.yaml 사용

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start services
        run: docker compose -f compose.test.yaml up -d

      - name: Wait for ready
        run: |
          until docker compose exec -T test-db pg_isready; do
            sleep 1
          done

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci
      - run: npm test

      - name: Cleanup
        if: always()
        run: docker compose -f compose.test.yaml down -v
```

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

## 베스트 프랙티스

### 빠른 피드백
```yaml
# 병렬 실행
jobs:
  lint:
    steps:
      - run: npm run lint

  test:
    needs: []  # lint와 병렬
    steps:
      - run: npm test
```

### 빠른 종료
```yaml
strategy:
  fail-fast: true
```

### 시크릿 관리
```yaml
# GitHub Actions
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}

# GitLab CI (Settings > CI/CD > Variables)
variables:
  DATABASE_URL: $CI_DATABASE_URL
```

### 조건부 실행
```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
```

## 참고

- GitHub Actions: https://docs.github.com/actions
- GitLab CI: https://docs.gitlab.com/ee/ci/
