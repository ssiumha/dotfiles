# Reusable Workflows

`workflow_call` 트리거로 워크플로우를 함수처럼 재사용.

## 정의 (called workflow)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  workflow_call:
    inputs:
      environment:
        type: string
        required: true
      image-tag:
        type: string
        required: true
    secrets:
      DEPLOY_TOKEN:
        required: true
    outputs:
      deploy-url:
        description: 'Deployed URL'
        value: ${{ jobs.deploy.outputs.url }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    outputs:
      url: ${{ steps.deploy.outputs.url }}
    steps:
      - uses: actions/checkout@v4
      - id: deploy
        env:
          ENVIRONMENT: ${{ inputs.environment }}
          IMAGE_TAG: ${{ inputs.image-tag }}
          TOKEN: ${{ secrets.DEPLOY_TOKEN }}
        run: |
          ./deploy.sh "$ENVIRONMENT" "$IMAGE_TAG"
          echo "url=https://${ENVIRONMENT}.example.com" >> $GITHUB_OUTPUT
```

---

## 호출 (caller workflow)

### 명시적 secrets 전달

```yaml
jobs:
  deploy-staging:
    uses: ./.github/workflows/deploy.yml
    with:
      environment: staging
      image-tag: ${{ needs.build.outputs.tag }}
    secrets:
      DEPLOY_TOKEN: ${{ secrets.STAGING_TOKEN }}
```

### secrets: inherit

같은 org/repo의 모든 secrets를 상속:

```yaml
jobs:
  deploy-staging:
    uses: ./.github/workflows/deploy.yml
    with:
      environment: staging
      image-tag: latest
    secrets: inherit
```

### 다른 레포의 워크플로우

```yaml
jobs:
  deploy:
    uses: my-org/infra/.github/workflows/deploy.yml@main
    with:
      environment: production
      image-tag: v1.2.3
    secrets:
      DEPLOY_TOKEN: ${{ secrets.PROD_TOKEN }}
```

---

## Output 사용

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy.yml
    with:
      environment: staging
      image-tag: latest
    secrets: inherit

  notify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - env:
          DEPLOY_URL: ${{ needs.deploy.outputs.deploy-url }}
        run: echo "Deployed to $DEPLOY_URL"
```

---

## 제약사항

- 중첩 호출 가능: 최대 4레벨 깊이까지 (순환 참조 불가)
- environment secrets는 `workflow_call`로 전달 불가 → repo/org secrets 사용
- caller의 `env:` 컨텍스트는 called workflow에 전달되지 않음
- 같은 워크플로우 파일 내에서 `workflow_call`과 다른 트리거 혼용 가능

---

## Composite Action vs Reusable Workflow

| | Composite Action | Reusable Workflow |
|---|---|---|
| 재사용 단위 | step | job(s) |
| 자체 runner | X (caller의 runner) | O (자체 runs-on) |
| secrets 접근 | caller의 secrets 사용 | 명시적 전달 필요 |
| environments | X | O |
| 중첩 | 가능 | 가능 (최대 4레벨) |
| 적합한 경우 | setup, lint 등 step 묶기 | 배포, 전체 CI 파이프라인 |

---

## 패턴: 환경별 배포 파이프라인

```yaml
# .github/workflows/release.yml
name: Release Pipeline

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tag }}
    steps:
      - uses: actions/checkout@v4
      - id: meta
        run: echo "tag=sha-${GITHUB_SHA::7}" >> $GITHUB_OUTPUT
      - env:
          IMAGE_TAG: ${{ steps.meta.outputs.tag }}
        run: docker build -t "app:${IMAGE_TAG}" .

  deploy-staging:
    needs: build
    uses: ./.github/workflows/deploy.yml
    with:
      environment: staging
      image-tag: ${{ needs.build.outputs.image-tag }}
    secrets: inherit

  deploy-production:
    needs: [deploy-staging, build]
    uses: ./.github/workflows/deploy.yml
    with:
      environment: production
      image-tag: ${{ needs.build.outputs.image-tag }}
    secrets: inherit
```
