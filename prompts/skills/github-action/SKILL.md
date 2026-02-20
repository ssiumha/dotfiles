---
name: github-action
description: GitHub Actions workflow 작성 종합 가이드. Use when creating/modifying GitHub Actions workflows, custom actions, reusable workflows, release automation, or CI/CD security hardening.
---

# GitHub Actions

GitHub Actions 워크플로우 작성, 커스텀 액션, 보안 강화를 위한 종합 가이드입니다.

**핵심 철학**:
- 최소 권한 (permissions)
- SHA 고정 (third-party actions)
- 재사용 (composite action / reusable workflow)
- OIDC (secretless cloud auth)
- 빠른 피드백 (concurrency + path filter + cache)

## Instructions

### 워크플로우: 요청 분석 및 리소스 선택

사용자 요청의 키워드를 분석하여 필요한 리소스만 로드합니다.

#### 키워드 매칭

| 키워드 | 리소스 |
|--------|--------|
| workflow, trigger, on, push, pull_request, schedule, dispatch | 01-workflow-basics.md |
| permissions, concurrency, environment, expressions, contexts | 01-workflow-basics.md |
| custom action, composite, action.yml, JavaScript action, Docker action | 02-custom-actions.md |
| reusable, workflow_call, shared workflow | 03-reusable-workflows.md |
| matrix, artifacts, cache, dynamic matrix, service containers, parallel jobs | 04-advanced-patterns.md |
| release, versioning, changelog, semantic-release, release-please | 05-release-deploy.md |
| deploy, environment, OIDC, deployment | 05-release-deploy.md |
| security, pin SHA, Dependabot, harden-runner, GITHUB_TOKEN, injection | 06-security.md |

#### 리소스 적용

1. **현재 상태 파악**: 기존 .github/workflows/ 확인
2. **리소스 로드**: 키워드 매칭으로 필요 리소스 Read
3. **설정 생성**: 워크플로우/액션 파일 생성
4. **검증**: YAML 문법, `act` 로컬 실행 또는 push 후 확인

## Examples

### CI 워크플로우 작성
User: "GitHub Actions로 PR 시 lint + test 돌려줘"
-> Read 01-workflow-basics.md
-> .github/workflows/ci.yml 생성 (permissions, concurrency, path filter 포함)

### 커스텀 액션 작성
User: "반복되는 setup 단계를 composite action으로 만들어줘"
-> Read 02-custom-actions.md
-> action.yml + 사용 예시 생성

### Reusable 워크플로우
User: "배포 워크플로우를 여러 서비스에서 재사용하게 해줘"
-> Read 03-reusable-workflows.md
-> workflow_call 기반 워크플로우 + caller 예시 생성

### 릴리즈 자동화
User: "main에 머지하면 자동으로 릴리즈하게 설정해줘"
-> Read 05-release-deploy.md
-> release-please 또는 semantic-release 워크플로우 생성

### 보안 강화
User: "GitHub Actions 보안 점검해줘"
-> Read 06-security.md
-> SHA 고정, permissions 최소화, Dependabot 설정

## Technical Details

- `resources/01-workflow-basics.md`: 트리거, permissions, concurrency, environments, expressions
- `resources/02-custom-actions.md`: composite, JavaScript, Docker 액션 작성
- `resources/03-reusable-workflows.md`: workflow_call, inputs/outputs/secrets
- `resources/04-advanced-patterns.md`: matrix, artifacts, caching, dynamic matrix
- `resources/05-release-deploy.md`: semantic-release, release-please, 환경별 배포
- `resources/06-security.md`: OIDC, SHA 고정, Dependabot, script injection 방지
