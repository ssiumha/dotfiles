# Security

## SHA 고정

Third-party action은 반드시 full SHA로 고정:

```yaml
# Bad - 태그는 변경 가능
- uses: actions/checkout@v4

# Good - SHA 고정 + 태그 코멘트
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

First-party GitHub actions(actions/*)는 태그 사용 가능. 커뮤니티 액션은 항상 SHA 고정.

2025년 `tj-actions/changed-files` 공급망 공격(CVE-2025-30066)이 이 원칙을 재확인.

---

## Dependabot for Actions

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      github-actions:
        patterns: ["*"]
```

SHA 고정된 액션 관리는 Renovate 또는 StepSecurity 사용.

---

## OIDC (Secretless Cloud Auth)

장기 credentials 대신 런타임 토큰 교환:

### 필수 permission

```yaml
permissions:
  id-token: write
  contents: read
```

### AWS

```yaml
- uses: aws-actions/configure-aws-credentials@<full-sha>  # v4.x.x
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions-role
    role-session-name: github-deploy
    aws-region: us-east-1
```

AWS IAM trust policy에 `token.actions.githubusercontent.com` OIDC provider 설정, `sub` claim 조건으로 repo/branch 제한.

### GCP

```yaml
# SHA 고정 필수 (third-party)
- uses: google-github-actions/auth@<full-sha>  # v2.x.x
  with:
    workload_identity_provider: 'projects/123/locations/global/workloadIdentityPools/pool/providers/github'
    service_account: 'sa@project.iam.gserviceaccount.com'
```

### Azure

```yaml
# SHA 고정 필수 (third-party)
- uses: azure/login@<full-sha>  # v2.x.x
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## GITHUB_TOKEN 최소 권한

```yaml
# 워크플로우 기본: 읽기 전용
permissions:
  contents: read

jobs:
  build:
    # 상속: contents: read
    runs-on: ubuntu-latest

  release:
    permissions:
      contents: write       # 릴리즈 생성
      packages: write       # GHCR push
    runs-on: ubuntu-latest
```

---

## Script Injection 방지

```yaml
# Bad - 직접 삽입 (PR title에 악성 코드 가능)
- run: echo "${{ github.event.pull_request.title }}"

# Good - 환경변수 경유
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "$PR_TITLE"
```

주의할 컨텍스트:
- `github.event.pull_request.title`
- `github.event.pull_request.body`
- `github.event.issue.title`
- `github.event.comment.body`
- `github.head_ref`

---

## pull_request_target 주의

`pull_request_target`은 base repo 컨텍스트에서 실행 → write 권한 있음.

```yaml
# DANGEROUS - PR 코드를 write 권한으로 실행
on: pull_request_target
steps:
  - uses: actions/checkout@v4
    with:
      ref: ${{ github.event.pull_request.head.sha }}  # 위험!
  - run: npm test  # 악성 코드 실행 가능
```

안전 패턴: `pull_request_target`에서는 base repo 코드만 checkout, PR 코드는 별도 sandbox에서 실행.

---

## Harden Runner

런타임 네트워크 모니터링:

```yaml
# SHA 고정 필수 (third-party)
- uses: step-security/harden-runner@<full-sha>  # v2.x.x
  with:
    egress-policy: audit
    allowed-endpoints: >
      github.com:443
      registry.npmjs.org:443
```

---

## Dependency Review

PR에서 취약/라이선스 위반 의존성 감지:

```yaml
name: Dependency Review
on: [pull_request]

permissions:
  contents: read

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: moderate
          deny-licenses: GPL-2.0, AGPL-3.0
```

---

## 체크리스트

- [ ] `permissions:` 워크플로우 레벨 설정
- [ ] third-party actions SHA 고정
- [ ] `.github/dependabot.yml` 설정
- [ ] 사용자 입력 expression → 환경변수 경유
- [ ] `pull_request_target` 사용 시 코드 격리
- [ ] cloud auth는 OIDC (secrets에 long-lived credentials 금지)
- [ ] secrets는 environment 또는 org 레벨 관리
