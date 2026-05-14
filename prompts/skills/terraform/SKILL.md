---
name: terraform
description: >-
  Terraform/OpenTofu IaC bootstrap·검증을 step 단위 명령어 집합으로 강제. 도입 전
  provider/module vetting(tier·archive·maintainer·latest), 버전 pin, S3 backend,
  AWS profile·region·ctx(locals) 명시, 보안 스캔(tfsec/checkov/trivy)을 grep
  카운트와 exit code로 정량 판정. Use when writing .tf files, bootstrapping a
  new terraform project, adding a provider/module, configuring backend, or
  reviewing IaC. Do NOT use for ad-hoc `aws` CLI (use devops/security) or
  Kubernetes manifests.
argument-hint: "[bootstrap|verify|vet|scan|<tf-dir>]"
user-invocable: true
---

# Terraform Skill — Command-Driven Bootstrap, Vet & Scan

각 step은 **명령 → 기대 결과 → 판정 규칙**으로 정의된다. 산문 판단 금지 — `grep`/`jq`/exit code/카운트로만 PASS/WARN/FAIL을 결정한다. 앞선 step FAIL 시 후속 step 실행 금지.

**핵심 철학**:
- **Command, not prose**: 모든 판정 기준은 실행 가능한 명령으로 표현
- **Quantitative gate**: 카운트·exit code 만으로 PASS/WARN/FAIL 결정
- **Vet before adopt**: 모든 provider/module은 tier·archive·maintainer·latest를 도입 *전*에 검증
- **No private info**: 모든 값은 사용자에게 묻고, 코드에는 `REPLACE-<key>` 잔존 0개일 때 PASS
- **Cheapest first**: ctx 수집 → vetting → 정적 gate → fmt → init → validate → 보안 스캔

## Variables

- `$TF_DIR` : 작업 대상 디렉토리 (기본 `.`)
- `$SKILL_DIR` : `~/.claude/skills/terraform`
- `$TF_CTX_*` : Step 1에서 수집
- `$TF_PROVIDERS` : `namespace/name@version,namespace/name@version` (Step 2 대상)
- `$TF_MODULES` : `namespace/name/system@version` 또는 `git::url?ref=v` 리스트
- 도구 가용: `terraform`, `aws`, `jq`, `curl`, `gh`, `tfsec`/`checkov`/`trivy` (있는 것 사용)

---

## Step 0 — Preflight

```bash
terraform -version
```
- PASS: exit 0 AND `^Terraform v[0-9]+\.[0-9]+\.[0-9]+`

```bash
aws sts get-caller-identity --profile "$P"
```
- PASS: exit 0 (profile 후보별)

```bash
command -v jq curl gh
```
- PASS: 모두 발견. `tfsec`/`checkov`/`trivy` 중 최소 1개 가용.

FAIL 시 후속 step 진입 금지.

---

## Step 1 — Collect ctx (사용자 입력)

다음 6개 변수를 사용자에게 받아 export (추측·기본값 금지). 식별은 저장소 이름과 프로젝트 이름으로 충분 — 개인 owner는 묻지 않는다.

| key | 형식 | 검증 명령 |
|-----|------|----------|
| `TF_CTX_PROJECT` | `^[a-z0-9-]+$` | `printf %s "$TF_CTX_PROJECT" \| grep -qE '^[a-z0-9-]+$'` |
| `TF_CTX_ENV` | `dev`\|`staging`\|`prod` | `printf %s "$TF_CTX_ENV" \| grep -qE '^(dev\|staging\|prod)$'` |
| `TF_CTX_REGION` | AWS region | `[ -n "$TF_CTX_REGION" ]` |
| `TF_CTX_PROFILE` | aws profile | `[ -n "$TF_CTX_PROFILE" ]` |
| `TF_STATE_BUCKET` | S3 bucket | `[ -n "$TF_STATE_BUCKET" ]` |
| `TF_STATE_KEY` | `<project>/<env>/terraform.tfstate` | `[ -n "$TF_STATE_KEY" ]` |

PASS: 6개 검증 모두 exit 0.

---

## Step 2 — Vet providers & modules (도입 전)

`$TF_PROVIDERS`의 각 `<ns>/<name>@<pinned>`에 대해 4가지 정량 점검. 상세 표/스크립트는 `resources/02-vetting-checklist.md`.

```bash
# 단일 provider 점검 — ns, name, pinned 를 사용자 입력에서 채워 호출
META=$(curl -fsSL "https://registry.terraform.io/v1/providers/$NS/$NAME")
TIER=$(printf %s "$META" | jq -r '.tier')                 # official|partner|community
LATEST=$(printf %s "$META" | jq -r '.version')
SOURCE=$(printf %s "$META" | jq -r '.source')             # https://github.com/<owner>/<repo>
DEP=$(printf %s "$META" | jq -r '.deprecation_status // "none"')

# GitHub 메타 (source가 github.com인 경우)
GH=$(gh api "repos/$OWNER/$REPO" --jq '{archived,disabled,owner_type:.owner.type,pushed_at}')
```

| Check | PASS | WARN | FAIL |
|-------|------|------|------|
| Registry 메타 조회 | exit 0 | — | 실패 (= 미공개/오타) |
| `tier` | `official` 또는 `partner` | `community` | 누락 |
| `deprecation_status` | `none` | — | `active` (deprecated) |
| GitHub `archived` | `false` | — | `true` |
| GitHub `disabled` | `false` | — | `true` |
| GitHub `owner.type` | `Organization` | `User` (개인 fork) | 누락 |
| Pinned vs latest | 같거나 직전 minor | 2 minor 이상 뒤처짐 | major 뒤처짐 |
| Push 최신성 (`pushed_at`) | 12개월 내 | 12-24개월 | 24개월 초과 |

**Module**도 동일 패턴(`https://registry.terraform.io/v1/modules/<ns>/<name>/<system>`) + git source는 `gh api` 메타로 점검.

전체 PASS: 위 8개 항목에서 FAIL 0건 AND WARN ≤ 2건.

FAIL 시 해당 provider/module은 채택 금지 — 대안 검토 후 재실행.

---

## Step 3 — Copy templates

```bash
cp "$SKILL_DIR/templates/01-versions.tf" "$TF_DIR/versions.tf"
cp "$SKILL_DIR/templates/02-backend.tf"  "$TF_DIR/backend.tf"
cp "$SKILL_DIR/templates/03-provider.tf" "$TF_DIR/provider.tf"
cp "$SKILL_DIR/templates/04-ctx.tf"      "$TF_DIR/ctx.tf"
ls -1 "$TF_DIR"/{versions,backend,provider,ctx}.tf | wc -l
```
- PASS: `4`

---

## Step 4 — Substitute placeholders

```bash
sed -i.bak \
  -e "s|REPLACE-project|$TF_CTX_PROJECT|g" \
  -e "s|REPLACE-env|$TF_CTX_ENV|g" \
  -e "s|REPLACE-region|$TF_CTX_REGION|g" \
  -e "s|REPLACE-profile|$TF_CTX_PROFILE|g" \
  -e "s|REPLACE-state-bucket|$TF_STATE_BUCKET|g" \
  -e "s|REPLACE-state-key|$TF_STATE_KEY|g" \
  "$TF_DIR"/versions.tf "$TF_DIR"/backend.tf "$TF_DIR"/provider.tf "$TF_DIR"/ctx.tf
rm -f "$TF_DIR"/*.tf.bak

grep -rE 'REPLACE-[a-z-]+' "$TF_DIR"/*.tf | wc -l
```
- PASS: `0`

Step 2에서 vet 통과한 provider/module pin도 `versions.tf` / 호출부에 반영 후 placeholder 0 유지.

---

## Step 5 — Version pin gate

```bash
grep -cE '^[[:space:]]*required_version[[:space:]]*=[[:space:]]*"(~>|=)' "$TF_DIR/versions.tf"
grep -cE 'version[[:space:]]*=[[:space:]]*"(~>|=)' "$TF_DIR/versions.tf"
grep -cE 'source[[:space:]]*=[[:space:]]*"[a-z0-9_-]+/[a-z0-9_-]+"' "$TF_DIR/versions.tf"
```
- PASS: 1행 `1`, 2행 `≥ 1`, 3행 `≥ 1`
- WARN: `required_version`이 `>=` 단독 (1행 `0` AND `^required_version` 검출)
- FAIL: 셋 중 하나라도 `0` 위 조건 아님

---

## Step 6 — Backend S3 gate

```bash
grep -c 'backend "s3"' "$TF_DIR/backend.tf"
grep -cE 'backend "(local|remote|http|pg|kubernetes)"' "$TF_DIR/backend.tf"
for k in bucket key region profile encrypt; do
  grep -cE "^[[:space:]]*${k}[[:space:]]*=" "$TF_DIR/backend.tf"
done
grep -cE '^[[:space:]]*encrypt[[:space:]]*=[[:space:]]*true' "$TF_DIR/backend.tf"
grep -cE '(use_lockfile[[:space:]]*=[[:space:]]*true|dynamodb_table[[:space:]]*=)' "$TF_DIR/backend.tf"
```
- PASS: 1행 `1`, 2행 `0`, 5키 모두 `1`, encrypt `1`, lock `≥ 1`

---

## Step 7 — Provider gate (no env-var dependency)

```bash
grep -cE '^[[:space:]]*region[[:space:]]*=' "$TF_DIR/provider.tf"
grep -cE '^[[:space:]]*profile[[:space:]]*=' "$TF_DIR/provider.tf"
grep -cE 'provider[[:space:]]+"aws"[[:space:]]*\{[[:space:]]*\}' "$TF_DIR/provider.tf"
```
- PASS: 1,2행 `≥ 1`; 3행 `0`

---

## Step 8 — ctx (locals) gate

```bash
grep -c '^locals' "$TF_DIR/ctx.tf"
for k in project env region profile tags; do
  grep -cE "^[[:space:]]+${k}[[:space:]]*=" "$TF_DIR/ctx.tf"
done
```
- PASS: 1행 `≥ 1`, 5키 모두 `≥ 1`
- WARN: 4/5
- FAIL: ≤ 3/5

---

## Step 9 — terraform CLI gate

```bash
terraform fmt -recursive -check "$TF_DIR"
terraform -chdir="$TF_DIR" init -backend=true -input=false
terraform -chdir="$TF_DIR" validate
```
- PASS: 셋 모두 exit 0 AND `validate` stdout에 `Success!`
- FAIL: 하나라도 exit ≠ 0 → stderr 첫 줄 보고

---

## Step 10 — Security scan

가용한 도구로 IaC 보안 스캔. 둘 이상 있으면 모두 실행(중복 검출 무방). 상세 규칙은 `resources/03-security-scan.md`.

```bash
# 둘 이상 가용 시 모두 실행, JSON으로 받아 jq로 카운트
tfsec "$TF_DIR" --format json --soft-fail \
  | jq '[.results[]? | select(.severity=="CRITICAL" or .severity=="HIGH")] | length'

checkov -d "$TF_DIR" -o json --quiet --compact 2>/dev/null \
  | jq '[.results.failed_checks[]? | select(.severity=="CRITICAL" or .severity=="HIGH")] | length'

trivy config "$TF_DIR" --format json --severity HIGH,CRITICAL --quiet \
  | jq '[.Results[]?.Misconfigurations[]?] | length'
```

판정:
- PASS: 가용 도구 ≥ 1개 실행 AND 각 도구의 HIGH+CRITICAL 카운트 `0`
- WARN: HIGH+CRITICAL 카운트 ≤ 2 AND 모두 사용자 확인 필요
- FAIL: HIGH+CRITICAL 카운트 ≥ 3 OR `CRITICAL` ≥ 1

추가 도구 가용 시:
- **Provider/Module CVE**: `trivy fs --scanners vuln,misconfig,secret "$TF_DIR"`
- **State 누출 secrets**: `gitleaks detect --source "$TF_DIR" --no-banner`

---

## Step 11 — Verdict

```
Step | Check                          | Result
-----|--------------------------------|-------
0    | preflight (terraform/aws/jq)   | {PASS|FAIL}
1    | ctx 6 vars                     | {PASS|FAIL}
2    | vet providers/modules          | {PASS|WARN|FAIL}  (per-item)
3    | 4 templates copied             | {PASS|FAIL}
4    | REPLACE- count == 0            | {PASS|FAIL}  (n=<count>)
5    | version pin                    | {PASS|WARN|FAIL}
6    | backend "s3" + 5 keys + lock   | {PASS|FAIL}
7    | provider region/profile        | {PASS|FAIL}
8    | locals.ctx 5 keys              | {PASS|WARN|FAIL}
9    | terraform fmt/init/validate    | {PASS|FAIL}
10   | security scan H+C count        | {PASS|WARN|FAIL}  (n=<count>)
```

전체 판정:
- **PASS**: FAIL 0 AND WARN ≤ 1
- **WARN**: FAIL 0 AND WARN ≥ 2 → 사용자 확인 후 진행
- **FAIL**: FAIL ≥ 1 → 가장 앞선 FAIL step부터 재실행

---

## 중요 원칙

1. **명령으로만 판정**: "괜찮아 보입니다" 금지. grep/jq 카운트 또는 exit code로만.
2. **도입 전 vetting**: provider/module을 `versions.tf`에 적기 *전에* Step 2 통과 필수. 통과 못한 의존성은 코드에 등장 금지.
3. **공적 maintainer 우선**: tier `official`/`partner` 또는 GitHub owner type `Organization`을 선호. 개인(`User`) 단독 제공은 WARN — 대안이 없을 때만 사용자 확인 후 채택.
4. **archived/deprecated는 즉시 FAIL**: 도입 시점에 archived/deprecated인 패키지는 채택 금지 — 가까운 미래에 보안 패치가 끊긴다.
5. **추측·기본값 주입 금지**: region/profile/bucket 모두 사용자 입력에서만.
6. **앞선 FAIL은 가드**: Step N FAIL → Step N+1 실행 금지.
7. **보안 스캔은 비용 0**: tfsec/checkov/trivy 중 1개라도 실행. 도구가 없으면 설치 안내 후 그 step만 SKIP 표기(다른 step PASS여도 전체 WARN).
8. **Apply는 메인에서**: `terraform apply`는 사용자 확인 후 메인 컨텍스트에서 직접 실행.

## 안티패턴

### ❌ 산문 판정
"backend 설정이 잘 되어 보입니다" → 카운트 없음 → 통과 불명확

### ✅ 카운트 판정
`grep -c 'backend "s3"' backend.tf == 1` AND 5 keys present == 5

### ❌ Vetting 생략
사용자가 부른 라이브러리/모듈 이름을 그대로 `versions.tf`에 핀

### ✅ Step 2 선행
Registry tier + GitHub archive + maintainer type 확인 후에만 핀 작성

### ❌ 기본값 추측
provider에 `region = "<추측-region>"` 하드코딩 (사용자에게 묻지 않음)

### ✅ 사용자 입력
Step 1에서 수집한 `$TF_CTX_REGION`만 치환

### ❌ env 의존
```hcl
provider "aws" {}
```

### ✅ 코드 명시
```hcl
provider "aws" {
  region  = local.ctx.region
  profile = local.ctx.profile
}
```

## Examples

### 신규 프로젝트 Bootstrap
User: "이 디렉토리에 terraform 시작"
→ Step 0 (preflight) → Step 1 (ctx 수집) → Step 2 (aws provider vet: tier=official, archived=false) → Step 3-4 (템플릿/치환) → Step 5-8 (정적 gate) → Step 9 (terraform CLI) → Step 10 (tfsec 0 HIGH+CRITICAL) → Step 11 매트릭스 보고

### 신규 module 추가
User: "terraform-aws-modules/vpc 모듈 추가"
→ Step 2만 단독 실행: registry 메타 + GitHub(`terraform-aws-modules/terraform-aws-vpc`) archived/owner type 점검 → PASS면 `module "vpc"` 블록 작성, FAIL이면 대안 검색

### 기존 .tf 도입 전 사전점검
User: "이 main.tf 도입 안전한지 검토"
→ Step 0, 2, 5-10 실행 → vet 매트릭스 + 보안 스캔 결과만 보고

## Technical Details

- `templates/01-versions.tf` — terraform + required_providers pin 템플릿
- `templates/02-backend.tf` — S3 backend (lockfile / dynamodb 옵션)
- `templates/03-provider.tf` — provider aws + alias
- `templates/04-ctx.tf` — locals.ctx 스켈레톤
- `resources/01-bootstrap-checklist.md` — Step 0-9 grep/exit-code 판정 표 + one-shot sweep
- `resources/02-vetting-checklist.md` — Step 2 registry/GitHub 메타 점검 명령 + 판정
- `resources/03-security-scan.md` — Step 10 tfsec/checkov/trivy 도구별 명령 + 카운트 추출

## Related Skills

- **devops**: terraform을 CI에서 실행 (OIDC + plan/apply workflow)
- **code-review**: terraform/IaC 리뷰 (lifecycle, state, credentials)
- **security**: IAM/네트워크 보안 점검 (Step 10 결과의 정성적 후속 분석)
- **feed**: provider 공급망 advisory 모니터링
- **mise-config**: 로컬 terraform 버전 관리
