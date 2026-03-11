# Routing Guide

## Keyword → Domain Mapping

| 시그널 | 도메인 | 로드 파일 |
|--------|--------|-----------|
| Justfile, task runner, just | ci-cd | ci-cd/README.md |
| lint, formatter, biome, eslint | ci-cd | ci-cd/README.md |
| test, E2E, 통합테스트 | ci-cd | ci-cd/README.md |
| pre-commit, hooks, husky | ci-cd | ci-cd/README.md |
| GitLab CI, .gitlab-ci.yml | ci-cd | ci-cd/README.md |
| 로컬 CI, 파이프라인 (GitHub 미언급) | ci-cd | ci-cd/README.md |
| Dockerfile, 이미지 빌드 | docker | docker/README.md |
| compose, compose.yaml, 서비스 오케스트레이션 | docker | docker/README.md |
| 컨테이너, container, 멀티스테이지 | docker | docker/README.md |
| .dockerignore, 빌드 컨텍스트 | docker | docker/README.md |
| GitHub Actions, workflow, action.yml | github-action | github-action/README.md |
| trigger, push, pull_request, schedule | github-action | github-action/README.md |
| custom action, composite, reusable | github-action | github-action/README.md |
| matrix, artifacts, cache (GHA) | github-action | github-action/README.md |
| release, changelog, semantic-release | github-action | github-action/README.md |
| deploy, OIDC, environment (GHA) | github-action | github-action/README.md |
| security, SHA 고정, Dependabot (GHA) | github-action | github-action/README.md |

## Disambiguation

| 입력 | 판정 | 이유 |
|------|------|------|
| "CI/CD 설정" | ci-cd | 로컬 우선 원칙 |
| "CI/CD + GitHub" | github-action | GitHub 명시 |
| "Docker 설정" | docker | 단일 도메인 |
| "Docker + GitHub Actions 배포" | docker + github-action | 복합 |
| "파이프라인 + 테스트" | ci-cd | 로컬 CI |
| "워크플로우 만들어줘" | github-action | workflow = GHA |
| "컨테이너 배포 자동화" | docker + github-action | 복합 |
