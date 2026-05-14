---
name: terraform
description: >-
  Terraform/OpenTofu IaC bootstrap·검증을 step 단위 명령어 집합으로 강제. 도입 전
  provider/module vetting, 버전 pin, S3 backend, AWS profile·region·ctx(locals)
  명시, plan-time destroy/replace 가드(lifecycle.prevent_destroy·state 백업),
  보안 스캔(tfsec/checkov/trivy)을 grep/jq 카운트와 exit code로 정량 판정.
  Use when writing .tf files, bootstrapping a new terraform project, adding a
  provider/module, modifying resources, or reviewing IaC. Do NOT use for
  ad-hoc `aws` CLI (use devops/security) or Kubernetes manifests.
argument-hint: "[bootstrap|verify|vet|plan|scan|<tf-dir>]"
user-invocable: true
---

# Terraform Skill — Command-Driven Bootstrap, Vet, Plan-safety & Scan

각 step은 **명령 → 카운트/exit code → PASS/WARN/FAIL**. 산문 판단 금지. 앞선 step FAIL 시 후속 step 실행 금지. step 상세는 `resources/`로 위임 — 본문은 흐름과 핵심 명령만.

**핵심 철학**:
- **Command, not prose**: grep/jq 카운트 또는 exit code로만 판정
- **Vet before adopt**: provider/module은 `versions.tf`에 적기 전에 vetting 통과
- **Existing resources are sacred**: plan에서 `delete`/`replace` 1건이라도 자동 진행 금지
- **State 변경은 백업 후**: `state mv|rm|import` 직전에 백업 필수
- **No private info**: 모든 값은 사용자 입력에서만 — `REPLACE-<key>` 잔존 0

## Variables

- `$TF_DIR` 작업 디렉토리, `$SKILL_DIR=~/.claude/skills/terraform`
- `$TF_CTX_{PROJECT,ENV,REGION,PROFILE}`, `$TF_STATE_{BUCKET,KEY}` — Step 1 수집
- `$TF_PROVIDERS`, `$TF_MODULES` — Step 2 대상
- 필수 도구: `terraform`, `aws`, `jq`, `curl`, `gh`. 보안: `tfsec` 또는 `checkov` 또는 `trivy`

## Step 0 — Preflight

```bash
terraform -version && aws sts get-caller-identity --profile "$TF_CTX_PROFILE" && command -v jq curl gh
```
PASS: 모두 exit 0. 상세: `resources/01-bootstrap-checklist.md` §Step 0.

## Step 1 — Collect ctx

6개 변수 사용자 입력(추측 금지): project, env, region, profile, state_bucket, state_key. 식별은 project + env로 충분 — 개인 owner 묻지 않는다.
PASS: 6 vars set + project/env 형식 일치. 상세: `resources/01-bootstrap-checklist.md` §Step 1.

## Step 2 — Vet providers & modules (도입 전)

각 `<ns>/<name>@<pinned>`에 대해:
```bash
curl -fsSL "https://registry.terraform.io/v1/providers/$NS/$NAME" | jq '{tier,version,deprecation_status,source}'
gh api "repos/$OWNER/$REPO" --jq '{archived,disabled,owner_type:.owner.type,pushed_at,license:.license.spdx_id}'
gh api "repos/$OWNER/$REPO/security-advisories" --jq '[.[]?|select(.severity=="critical" or .severity=="high")]|length'
```
PASS: tier ∈ {official,partner}, deprecation=none, archived/disabled=false, owner.type=Organization, advisory=0, pinned-major == latest-major.
도입 금지: registry 메타 조회 실패, deprecated, archived, advisory ≥ 1. 상세: `resources/02-vetting-checklist.md`.

## Step 3 — Copy templates

```bash
for f in 01-versions 02-backend 03-provider 04-ctx; do cp "$SKILL_DIR/templates/${f}.tf" "$TF_DIR/${f#0?-}.tf"; done
ls -1 "$TF_DIR"/{versions,backend,provider,ctx}.tf | wc -l
```
PASS: `4`.

## Step 4 — Substitute placeholders

`sed -i.bak -e "s|REPLACE-project|$TF_CTX_PROJECT|g" …` 6개 키 치환 후:
```bash
grep -rE 'REPLACE-[a-z-]+' "$TF_DIR"/*.tf | wc -l
```
PASS: `0`.

## Step 5 — Version pin

```bash
grep -cE '^[[:space:]]*required_version[[:space:]]*=[[:space:]]*"(~>|=)' versions.tf   # = 1
grep -cE 'version[[:space:]]*=[[:space:]]*"(~>|=)' versions.tf                          # ≥ 1
grep -cE 'source[[:space:]]*=[[:space:]]*"[a-z0-9_-]+/[a-z0-9_-]+"' versions.tf         # ≥ 1
```
PASS: 위 조건 모두. WARN: `>=` 단독. 상세: `resources/01-bootstrap-checklist.md` §Step 4.

## Step 6 — Backend S3

```bash
grep -c 'backend "s3"' backend.tf            # = 1
grep -cE 'backend "(local|remote|http|pg|kubernetes)"' backend.tf  # = 0
```
+ `bucket/key/region/profile/encrypt` 5키 각 `= 1`, `encrypt = true`, lock(`use_lockfile=true` 또는 `dynamodb_table=`) `≥ 1`. 상세: §Step 5.

## Step 7 — Provider (no env dependency)

```bash
grep -cE '^[[:space:]]*region[[:space:]]*=' provider.tf   # ≥ 1
grep -cE '^[[:space:]]*profile[[:space:]]*=' provider.tf  # ≥ 1
grep -cE 'provider[[:space:]]+"aws"[[:space:]]*\{[[:space:]]*\}' provider.tf  # = 0
```
상세: §Step 6.

## Step 8 — ctx (locals)

5 keys (`project,env,region,profile,tags`) 모두 `≥ 1`. 상세: §Step 7.

## Step 9 — terraform CLI

```bash
terraform fmt -recursive -check "$TF_DIR" && terraform -chdir="$TF_DIR" init -backend=true -input=false && terraform -chdir="$TF_DIR" validate
```
PASS: 셋 모두 exit 0 AND `validate` stdout `Success!`.

## Step 10 — Plan & state safety (리소스 간섭 가드)

상세 + 환경별 임계: `resources/04-state-safety.md`.

- **10a prevent_destroy**: stateful resource(`aws_db_instance|rds_cluster|s3_bucket|kms_key|dynamodb_table|efs_file_system|iam_user|iam_role|secretsmanager_secret|…`)에 `lifecycle.prevent_destroy = true` 강제. `protected == stateful` PASS.
- **10b state backup**: `terraform state pull > .tf-backups/state-$TS.json`. exit 0 AND (bytes > 0 OR 신규).
- **10c plan diff**: `terraform plan -out + show -json | jq` 로 `DELETE`, `REPLACE`, stateful-destroy 카운트. `DELETE=0 AND REPLACE=0` PASS, stateful 또는 ≥3 FAIL.
- **10d import/state-op**: `import` 블록은 같은 dir의 resource와 매칭. `state mv|rm`은 메인에서만, 10b 백업 PASS 후.

Step 10 verdict: 4 sub 모두 PASS → PASS. FAIL ≥ 1 → apply·후속 step 차단.

## Step 11 — Security scan

```bash
tfsec "$TF_DIR" --format json --soft-fail | jq '[.results[]?|select(.severity=="HIGH" or .severity=="CRITICAL")]|length'
checkov -d "$TF_DIR" -o json --quiet --compact 2>/dev/null | jq '[.results.failed_checks[]?|select(.severity=="HIGH" or .severity=="CRITICAL")]|length'
trivy config "$TF_DIR" --format json --severity HIGH,CRITICAL --quiet | jq '[.Results[]?.Misconfigurations[]?]|length'
gitleaks detect --source "$TF_DIR" --no-banner --report-format json --exit-code 0
```
PASS: 가용 도구 ≥ 1개 실행 AND 합산 HIGH+CRITICAL `0` AND secrets `0`. env별 임계는 `resources/03-security-scan.md`.

## Step 12 — Verdict

매트릭스 형식:
```
Step | Check                            | Result
0    | preflight                        | {PASS|FAIL}
1    | ctx 6 vars                       | {PASS|FAIL}
2    | vet providers/modules            | {PASS|WARN|FAIL}
3-4  | templates copied + placeholders  | {PASS|FAIL}
5-8  | static gates                     | {PASS|WARN|FAIL}
9    | fmt/init/validate                | {PASS|FAIL}
10a-d| prevent_destroy/backup/plan/import | {PASS|WARN|FAIL}
11   | security scan H+C+secrets        | {PASS|WARN|FAIL}
```
전체: FAIL 0 AND WARN ≤ 1 → PASS / FAIL ≥ 1 → FAIL → 가장 앞선 FAIL부터 재실행.

## 중요 원칙

1. **명령으로만 판정**: grep/jq 카운트 또는 exit code. "괜찮아 보입니다" 금지.
2. **도입 전 vetting**: provider/module은 Step 2 통과 후에만 코드에 등장.
3. **공적 maintainer 우선**: tier `official`/`partner` 또는 GitHub `Organization`. 개인(`User`)·archived·deprecated는 채택 금지.
4. **추측·기본값 주입 금지**: region/profile/bucket 모두 사용자 입력에서만.
5. **앞선 FAIL은 가드**: Step N FAIL → Step N+1 실행 금지.
6. **기존 리소스는 기본 불가침**: plan에서 `delete`/`replace` 1건이라도 자동 진행 금지. stateful이면 즉시 FAIL.
7. **State 변경은 백업 후**: `state mv|rm|import` 직전에 10b PASS 필수. 백업 없는 state 조작 금지.
8. **데이터 조회는 readonly**: `data` 블록 결과를 다시 `resource`로 재선언하지 않는다(이중 관리 = 충돌).
9. **Apply는 메인에서**: skill 자동 실행 금지. 사용자 확인 후 메인에서 직접.

## Examples

### 신규 프로젝트 Bootstrap
Step 0 → 1 (ctx) → 2 (provider vet) → 3-4 (템플릿/치환) → 5-8 (정적 gate) → 9 (CLI) → 10 (신규라 destroy 0) → 11 (보안 스캔) → 12 매트릭스.

### 신규 module 추가
Step 2만 단독: registry tier + GitHub archived/owner_type + advisory. PASS면 module 블록 작성, FAIL이면 대안 검색.

### 기존 리소스 변경 안전성 확인
Step 9 → Step 10 (backup → plan diff): `DELETE`/`REPLACE` 카운트와 stateful 여부 보고. destroy/replace > 0 시 사용자 확인 전 apply 차단.

## Technical Details

- `templates/01-versions.tf`, `02-backend.tf`, `03-provider.tf`, `04-ctx.tf` — bootstrap 4파일
- `resources/01-bootstrap-checklist.md` — Step 0-9 정량 판정 표 + one-shot sweep
- `resources/02-vetting-checklist.md` — Step 2 registry/GitHub 메타 명령 + 매트릭스
- `resources/03-security-scan.md` — Step 11 도구별 명령 + env별 임계
- `resources/04-state-safety.md` — Step 10 lifecycle/state-backup/plan-diff/import 가드

## Related Skills

- **devops**: terraform을 CI에서 실행 (OIDC + plan/apply workflow)
- **code-review**: terraform/IaC 리뷰 (lifecycle, state, credentials)
- **security**: Step 11 결과의 정성적 후속 분석
- **feed**: provider 공급망 advisory 모니터링
- **mise-config**: 로컬 terraform 버전 관리
