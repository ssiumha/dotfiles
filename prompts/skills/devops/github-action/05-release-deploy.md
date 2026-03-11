# Release & Deploy

## 릴리즈 자동화 도구 선택

| 도구 | 방식 | 적합한 경우 |
|------|------|-------------|
| release-please | PR 기반 (머지 시 릴리즈) | 릴리즈 전 검토 필요 |
| semantic-release | 완전 자동 (push 시 릴리즈) | 빠른 릴리즈 사이클 |
| gh release | 수동/스크립트 | 간단한 프로젝트 |

---

## release-please (Google)

main push → Release PR 자동 생성 → PR 머지 시 릴리즈 + 태그:

```yaml
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@<full-sha>  # v4.x.x
        id: release
        with:
          release-type: node    # node, python, go, ruby, simple 등

  publish:
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'
      - run: npm ci
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**팁**: Release PR에서 CI 체크를 돌리려면 PAT 사용 (GITHUB_TOKEN은 다른 워크플로우 트리거 불가).

---

## semantic-release

커밋 메시지 컨벤션 → 자동 버전 결정:

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
      - run: npm ci
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

커밋 컨벤션: `feat:` → minor, `fix:` → patch, `BREAKING CHANGE:` → major.

---

## gh CLI 릴리즈

```yaml
- name: Create Release
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TAG: ${{ github.ref_name }}
  run: |
    gh release create "$TAG" \
      --title "Release $TAG" \
      --generate-notes \
      dist/*.tar.gz dist/*.zip
```

---

## Docker 이미지 빌드 + Push

### GitHub Container Registry (GHCR)

```yaml
name: Build & Push

on:
  push:
    branches: [main]
    tags: ['v*']

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@<full-sha>  # v3.x.x
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@<full-sha>  # v5.x.x
        id: meta
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha

      - uses: docker/build-push-action@<full-sha>  # v6.x.x
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 환경별 배포 파이프라인

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, production]

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
        run: |
          docker build -t "app:${IMAGE_TAG}" .
          docker save "app:${IMAGE_TAG}" -o image.tar
      - uses: actions/upload-artifact@v4
        with:
          name: image
          path: image.tar

  deploy-staging:
    needs: build
    environment:
      name: staging
      url: https://staging.example.com
    runs-on: ubuntu-latest
    steps:
      - env:
          IMAGE_TAG: ${{ needs.build.outputs.image-tag }}
        run: ./deploy.sh staging "$IMAGE_TAG"

  deploy-production:
    needs: [deploy-staging, build]
    if: github.event_name == 'push' || github.event.inputs.environment == 'production'
    environment:
      name: production
      url: https://example.com
    runs-on: ubuntu-latest
    steps:
      - env:
          IMAGE_TAG: ${{ needs.build.outputs.image-tag }}
        run: ./deploy.sh production "$IMAGE_TAG"
```
