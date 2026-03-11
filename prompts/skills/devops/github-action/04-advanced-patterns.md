# Advanced Patterns

## Matrix Strategy

### 기본

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      max-parallel: 4
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node: [18, 20, 22]
        exclude:
          - os: macos-latest
            node: 18
        include:
          - os: ubuntu-latest
            node: 22
            experimental: true

    runs-on: ${{ matrix.os }}
    continue-on-error: ${{ matrix.experimental == true }}

    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm test
```

### Dynamic Matrix

이전 job 출력으로 matrix 동적 생성:

```yaml
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set.outputs.matrix }}
    steps:
      - id: set
        run: |
          echo 'matrix={"include":[{"env":"staging"},{"env":"prod"}]}' >> $GITHUB_OUTPUT

  deploy:
    needs: prepare
    strategy:
      matrix: ${{ fromJSON(needs.prepare.outputs.matrix) }}
    runs-on: ubuntu-latest
    steps:
      - env:
          DEPLOY_ENV: ${{ matrix.env }}
        run: ./deploy.sh "$DEPLOY_ENV"
```

---

## Artifacts

### Upload (v4)

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-outputs
    path: |
      dist/
      !dist/**/*.map
    retention-days: 7
    if-no-files-found: error
    compression-level: 6
```

### Download

```yaml
jobs:
  build:
    steps:
      - uses: actions/upload-artifact@v4
        with:
          name: binaries
          path: bin/

  deploy:
    needs: build
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: binaries
          path: ./bin

      # 전체 artifact 다운로드
      - uses: actions/download-artifact@v4
        with:
          merge-multiple: true
          path: ./all
```

**규칙**: job 간 데이터 전달은 artifacts. cache는 best-effort이므로 보장 불가.

---

## Caching

### 기본 패턴

```yaml
- uses: actions/cache@v4
  id: cache
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-

- if: steps.cache.outputs.cache-hit != 'true'
  run: npm ci
```

### Restore / Save 분리

```yaml
- id: restore
  uses: actions/cache/restore@v4
  with:
    path: .build-cache
    key: ${{ runner.os }}-build-${{ hashFiles('src/**') }}

- run: make build

- if: success()
  uses: actions/cache/save@v4
  with:
    path: .build-cache
    key: ${{ steps.restore.outputs.cache-primary-key }}
```

### 캐시 키 팁

- `runner.os` 포함 (OS별 바이너리 분리)
- lock file hash 포함 (package-lock.json, yarn.lock, Gemfile.lock)
- `restore-keys`는 prefix 매칭 fallback
- matrix 사용 시 node version 등 포함

```yaml
key: ${{ runner.os }}-node${{ matrix.node }}-${{ hashFiles('**/package-lock.json') }}
```

### 언어별 캐시 경로

| 언어 | 경로 |
|------|------|
| npm | `~/.npm` |
| yarn | `${{ steps.yarn-cache.outputs.cache-dir }}` |
| pnpm | `${{ steps.pnpm-cache.outputs.store }}` |
| pip | `~/.cache/pip` |
| Go | `~/go/pkg/mod`, `~/.cache/go-build` |
| Gradle | `~/.gradle/caches`, `~/.gradle/wrapper` |
| Rust | `~/.cargo/registry`, `target/` |

---

## 병렬 Job + 의존성

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    # lint와 병렬 실행
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
```

---

## Service Containers

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379

    steps:
      - run: npm run test:e2e
        env:
          DATABASE_URL: postgres://test:test@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
```

---

## 조건부 실행 패턴

### Path 필터

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
      - 'package*.json'
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

### Skip CI

```yaml
jobs:
  ci:
    if: "!contains(github.event.head_commit.message, '[skip ci]')"
```

### 브랜치별 분기

```yaml
jobs:
  deploy-prod:
    if: github.ref == 'refs/heads/main'
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
```
