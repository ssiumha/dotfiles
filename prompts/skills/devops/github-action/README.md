# GitHub Actions Domain

GitHub Actions 워크플로우 작성, 커스텀 액션, 보안 강화를 위한 종합 가이드입니다.

## 핵심 철학

- 최소 권한 (permissions)
- SHA 고정 (third-party actions)
- 재사용 (composite action / reusable workflow)
- OIDC (secretless cloud auth)
- 빠른 피드백 (concurrency + path filter + cache)

## 리소스 선택

| 키워드 | 리소스 |
|--------|--------|
| workflow, trigger, on, push, pull_request, schedule | 01-workflow-basics.md |
| permissions, concurrency, environment, expressions | 01-workflow-basics.md |
| custom action, composite, action.yml, Docker action | 02-custom-actions.md |
| reusable, workflow_call, shared workflow | 03-reusable-workflows.md |
| matrix, artifacts, cache, service containers | 04-advanced-patterns.md |
| release, changelog, semantic-release, release-please | 05-release-deploy.md |
| deploy, environment, OIDC, deployment | 05-release-deploy.md |
| security, SHA 고정, Dependabot, harden-runner | 06-security.md |

## Workflow

1. 기존 `.github/workflows/` 확인
2. 키워드 매칭으로 필요 리소스 Read
3. 워크플로우/액션 파일 생성
4. YAML 문법 검증, `act` 로컬 실행 또는 push 후 확인
