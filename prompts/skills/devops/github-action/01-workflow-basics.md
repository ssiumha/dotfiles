# Workflow Basics

## 트리거 (on)

### push / pull_request

```yaml
on:
  push:
    branches: [main, 'releases/**']
    tags: ['v*']
    paths: ['src/**', '**.ts']
    paths-ignore: ['docs/**']
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
```

### workflow_dispatch (수동 + 입력)

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        type: choice
        options: [staging, production]
        required: true
      dry-run:
        type: boolean
        default: false
```

### schedule

```yaml
on:
  schedule:
    - cron: '30 5 * * 1-5'   # 평일 05:30 UTC
```

### 복합 트리거

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  release:
    types: [published]
  workflow_dispatch:
```

---

## Permissions

워크플로우 레벨에서 최소 권한 설정, job 레벨에서 필요 시 확장.

```yaml
permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    # contents: read 상속

  release:
    permissions:
      contents: write
      pull-requests: write
      id-token: write         # OIDC
    runs-on: ubuntu-latest
```

### 주요 scope

| Scope | 용도 |
|---|---|
| `contents: read` | checkout |
| `contents: write` | release 생성, 커밋 push |
| `pull-requests: write` | PR 코멘트, 라벨 |
| `issues: write` | 이슈 코멘트 |
| `packages: write` | GHCR push |
| `id-token: write` | OIDC 토큰 |
| `security-events: write` | SARIF 업로드 |
| `deployments: write` | deployment status |

---

## Concurrency

같은 PR/브랜치의 중복 실행 취소:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ !contains(github.ref, 'release/') }}
```

배포 직렬화:

```yaml
jobs:
  deploy:
    concurrency:
      group: production-deploy
      cancel-in-progress: false
```

---

## Environments

보호 규칙(리뷰어, 대기 시간) + 환경별 secrets:

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://example.com
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.PROD_API_KEY }}
```

---

## Expressions & Contexts

### 조건부 실행

```yaml
steps:
  - if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    run: echo "main push"

  - if: contains(github.event.pull_request.labels.*.name, 'deploy')
    run: echo "deploy label"

  - if: always()       # 이전 step 실패해도 실행
    run: echo "cleanup"

  - if: success()      # 기본값
  - if: failure()      # 이전 step 실패 시
  - if: cancelled()    # 워크플로우 취소 시
```

### Outputs (job 간 데이터 전달)

```yaml
jobs:
  build:
    outputs:
      version: ${{ steps.meta.outputs.version }}
    steps:
      - id: meta
        run: echo "version=1.2.3" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    steps:
      - env:
          VERSION: ${{ needs.build.outputs.version }}
        run: echo "Deploying $VERSION"
```

### 유용한 함수

```yaml
# JSON 파싱
fromJSON(needs.prepare.outputs.matrix)

# 문자열
contains(github.event.head_commit.message, '[skip ci]')
startsWith(github.ref, 'refs/tags/')
format('Hello {0}', github.actor)

# hashFiles (캐시 키)
hashFiles('**/package-lock.json')
hashFiles('**/*.gradle', '**/gradle-wrapper.properties')
```

---

## 기본 워크플로우 템플릿

```yaml
name: CI

on:
  push:
    branches: [main]
    paths: ['src/**', 'tests/**', 'package*.json']
  pull_request:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm run build
```
