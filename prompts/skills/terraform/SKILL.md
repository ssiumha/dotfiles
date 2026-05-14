---
name: terraform
description: >-
  Terraform/OpenTofu IaC bootstrap·검증을 step 단위 명령어 집합으로 강제 실행.
  terraform/provider 버전 pin, S3 backend 고정, AWS profile·region·ctx(locals)
  명시를 grep/terraform CLI로 정량 판정. Use when writing .tf files,
  bootstrapping a new terraform project, configuring backend/providers, or
  reviewing IaC. Do NOT use for ad-hoc `aws` CLI (use devops/security) or
  Kubernetes manifests.
argument-hint: "[bootstrap|verify|<tf-dir>]"
user-invocable: true
---

# Terraform Skill — Command-Driven Bootstrap & Verify

각 step은 **명령 → 기대 결과 → 판정 규칙**으로 정의된다. 산문 판단 금지 — `grep`/`terraform` exit code 와 카운트로만 PASS/FAIL을 결정한다.

**핵심 철학**:
- **Command, not prose**: 모든 판정 기준은 실행 가능한 명령으로 표현
- **Quantitative gate**: 카운트·exit code 만으로 PASS/WARN/FAIL 결정
- **No private info**: 모든 값은 사용자에게 묻고, 코드에는 `REPLACE-<key>` 잔존 0개일 때 PASS
- **Cheapest first**: grep → fmt → init → validate 순. 앞 step FAIL이면 뒤 step 실행 금지

## Variables

이 skill 본문의 `$TF_DIR`은 작업 대상 디렉토리(기본 `.`). `$SKILL_DIR`은 `~/.claude/skills/terraform`. 모든 명령은 `cd $TF_DIR` 가정.

---

## Step 0 — Preflight

```bash
terraform -version
```
- PASS: exit 0 그리고 stdout 1행 매치 `^Terraform v[0-9]+\.[0-9]+\.[0-9]+`
- FAIL: 미설치 → 사용자에게 설치 안내 후 중단

```bash
aws sts get-caller-identity --profile "$AWS_PROFILE_CANDIDATE"
```
- 사용할 profile 후보(사용자 입력) 각각에 대해 실행, exit 0 이면 사용 가능
- FAIL: 모든 후보 실패 → profile 재확인 요청, 중단

---

## Step 1 — Collect ctx (사용자 입력)

사용자에게 정량적으로 다음을 받는다 (AskUserQuestion 또는 직접 질문):

| key | 형식 | 예 |
|-----|------|----|
| project | `[a-z0-9-]+` | — (사용자 제공) |
| env | `dev`\|`staging`\|`prod` | — |
| owner | 팀명 또는 이메일 | — |
| region | AWS region ID | — |
| profile | `aws configure` profile 이름 | — |
| state_bucket | tfstate S3 bucket 이름 | — |
| state_key | tfstate object key | `<project>/<env>/terraform.tfstate` |

수집 결과를 환경변수로 export (이 세션 한정):
```bash
export TF_CTX_PROJECT=... TF_CTX_ENV=... TF_CTX_OWNER=...
export TF_CTX_REGION=... TF_CTX_PROFILE=...
export TF_STATE_BUCKET=... TF_STATE_KEY=...
```

판정: 7개 변수 모두 비어있지 않음 → PASS. 하나라도 비면 FAIL, Step 2 진입 금지.

---

## Step 2 — Copy templates

```bash
cp "$SKILL_DIR/templates/01-versions.tf" "$TF_DIR/versions.tf"
cp "$SKILL_DIR/templates/02-backend.tf"  "$TF_DIR/backend.tf"
cp "$SKILL_DIR/templates/03-provider.tf" "$TF_DIR/provider.tf"
cp "$SKILL_DIR/templates/04-ctx.tf"      "$TF_DIR/ctx.tf"
```

검증:
```bash
ls -1 "$TF_DIR"/{versions,backend,provider,ctx}.tf | wc -l
```
- PASS: `4`
- FAIL: `< 4` → 누락 파일 재복사

---

## Step 3 — Substitute placeholders (no private info leak)

치환은 **사용자가 제공한 값으로만**. 추측·기본값 주입 금지.

```bash
sed -i.bak \
  -e "s|REPLACE-project|$TF_CTX_PROJECT|g" \
  -e "s|REPLACE-env|$TF_CTX_ENV|g" \
  -e "s|REPLACE-owner|$TF_CTX_OWNER|g" \
  -e "s|REPLACE-region|$TF_CTX_REGION|g" \
  -e "s|REPLACE-profile|$TF_CTX_PROFILE|g" \
  -e "s|REPLACE-state-bucket|$TF_STATE_BUCKET|g" \
  -e "s|REPLACE-state-key|$TF_STATE_KEY|g" \
  "$TF_DIR"/versions.tf "$TF_DIR"/backend.tf "$TF_DIR"/provider.tf "$TF_DIR"/ctx.tf

rm -f "$TF_DIR"/*.tf.bak
```

검증:
```bash
grep -rEn 'REPLACE-[a-z-]+' "$TF_DIR" || echo "OK"
```
- PASS: stdout `OK` (잔존 0건)
- FAIL: 매칭 1건 이상 → 해당 키 재수집 후 재치환

---

## Step 4 — Version pin gate

```bash
grep -cE '^[[:space:]]*required_version[[:space:]]*=[[:space:]]*"(~>|=)' "$TF_DIR/versions.tf"
```
- PASS: `1`
- WARN: `required_version =` 있으나 `(~>|=)` 아닌 경우 (`>=` 단독)
- FAIL: `0`

```bash
grep -cE 'version[[:space:]]*=[[:space:]]*"(~>|=)' "$TF_DIR/versions.tf"
```
- PASS: 1 이상 (≥ 선언된 provider 수)
- FAIL: `0`

provider source 명시:
```bash
grep -cE 'source[[:space:]]*=[[:space:]]*"[a-z0-9_-]+/[a-z0-9_-]+"' "$TF_DIR/versions.tf"
```
- PASS: 1 이상

---

## Step 5 — Backend S3 gate

```bash
grep -c 'backend "s3"' "$TF_DIR/backend.tf"
```
- PASS: `1`
- FAIL: `0` 또는 `backend "local"` / `backend "remote"` 검출

필수 키 5종 (bucket, key, region, profile, encrypt):
```bash
for k in bucket key region profile encrypt; do
  grep -cE "^[[:space:]]*${k}[[:space:]]*=" "$TF_DIR/backend.tf"
done
```
- PASS: 모두 `1`
- FAIL: 하나라도 `0`

`encrypt = true`:
```bash
grep -cE '^[[:space:]]*encrypt[[:space:]]*=[[:space:]]*true' "$TF_DIR/backend.tf"
```
- PASS: `1`

잠금 메커니즘 (둘 중 하나):
```bash
grep -cE '(use_lockfile[[:space:]]*=[[:space:]]*true|dynamodb_table[[:space:]]*=)' "$TF_DIR/backend.tf"
```
- PASS: `1` 이상
- FAIL: `0`

---

## Step 6 — Provider gate (no env-var dependency)

```bash
grep -cE '^[[:space:]]*region[[:space:]]*=' "$TF_DIR/provider.tf"
grep -cE '^[[:space:]]*profile[[:space:]]*=' "$TF_DIR/provider.tf"
```
- PASS: 둘 다 `1` 이상
- FAIL: 하나라도 `0` (= env 의존)

빈 provider 블록 금지:
```bash
grep -cE 'provider[[:space:]]+"aws"[[:space:]]*\{[[:space:]]*\}' "$TF_DIR/provider.tf"
```
- PASS: `0`
- FAIL: `1` 이상

---

## Step 7 — ctx (locals) gate

```bash
grep -c '^locals' "$TF_DIR/ctx.tf"
```
- PASS: `1` 이상

필수 키 6종:
```bash
for k in project env owner region profile tags; do
  grep -cE "^[[:space:]]+${k}[[:space:]]*=" "$TF_DIR/ctx.tf"
done
```
- PASS: 모두 `1` 이상
- WARN: 5/6
- FAIL: ≤ 4/6

---

## Step 8 — terraform CLI gate

```bash
terraform fmt -recursive -check "$TF_DIR"
```
- PASS: exit 0
- FAIL: exit ≠ 0 → `terraform fmt -recursive "$TF_DIR"` 실행 후 재검사

```bash
terraform -chdir="$TF_DIR" init -backend=true -input=false
```
- PASS: exit 0
- FAIL: exit ≠ 0 → stderr 첫 줄 보고, 사용자 확인 (bucket/profile 오류 가능)

```bash
terraform -chdir="$TF_DIR" validate
```
- PASS: exit 0 그리고 stdout `Success!` 포함
- FAIL: exit ≠ 0

---

## Step 9 — Verdict

각 Step의 결과로 다음 매트릭스 채워 보고:

```
Step | Check                       | Result
-----|-----------------------------|-------
0    | terraform -version          | {PASS|FAIL}
0    | aws sts get-caller-identity | {PASS|FAIL}
1    | ctx 7 vars collected        | {PASS|FAIL}
2    | 4 templates copied          | {PASS|FAIL}
3    | REPLACE- count == 0         | {PASS|FAIL}  (n=<count>)
4    | required_version pinned     | {PASS|WARN|FAIL}
4    | provider versions pinned    | {PASS|FAIL}  (n=<count>)
5    | backend "s3" exists         | {PASS|FAIL}
5    | backend 5 keys present      | {PASS|FAIL}  (n=<0..5>)
5    | encrypt = true              | {PASS|FAIL}
5    | lock mechanism              | {PASS|FAIL}
6    | provider region/profile     | {PASS|FAIL}
6    | no empty provider block     | {PASS|FAIL}
7    | locals.ctx 6 keys           | {PASS|WARN|FAIL} (n=<0..6>)
8    | terraform fmt -check        | {PASS|FAIL}
8    | terraform init              | {PASS|FAIL}
8    | terraform validate          | {PASS|FAIL}
```

전체 판정:
- **PASS**: FAIL 0건 AND WARN ≤ 1건 → bootstrap 완료, resource 추가 가능
- **WARN**: FAIL 0건 AND WARN ≥ 2건 → 사용자 확인 후 진행
- **FAIL**: FAIL ≥ 1건 → 가장 앞선 FAIL step으로 돌아가 수정, 그 이후 step 재실행

상세 판정 규칙: `resources/01-bootstrap-checklist.md`

---

## 중요 원칙

1. **명령으로만 판정**: "괜찮아 보입니다" 금지. grep 카운트 또는 exit code로만 PASS/FAIL 결정.
2. **추측·기본값 주입 금지**: region/profile/bucket 모두 사용자 입력에서만 채운다. 코드·메모리·세션 컨텍스트에서 추측하지 않는다.
3. **앞선 FAIL은 가드**: Step N FAIL 시 Step N+1 실행 금지. cascade 방지.
4. **env 의존 금지**: provider가 `AWS_PROFILE`/`AWS_REGION`을 읽으면 리뷰만으로 어느 계정에 적용되는지 알 수 없다.
5. **버전 pin은 비용 0**: `~>` 또는 `=` 모두 허용. `>=` 단독은 WARN.
6. **Apply는 메인에서**: `terraform apply`는 사용자 확인 후 메인 컨텍스트에서 직접 실행. skill 자동 실행 금지.

## 안티패턴

### ❌ 산문 판정
"backend 설정이 잘 되어 보입니다" → 카운트 없음 → 통과 불명확

### ✅ 카운트 판정
`grep -c 'backend "s3"' backend.tf == 1` AND 5 keys present == 5

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
→ Step 0 (preflight) → Step 1 (ctx 수집) → Step 2-3 (템플릿 복사·치환) → Step 4-7 (정적 grep gate) → Step 8 (terraform CLI gate) → Step 9 매트릭스 보고

### 기존 .tf 리뷰
User: "이 main.tf bootstrap 통과하는지 확인"
→ Step 0 → Step 4-7 만 실행 (이미 파일 있음) → Step 8 → Step 9 매트릭스 보고 → FAIL 항목별 수정 제안

### Resource 추가 전 가드
User: "S3 버킷 리소스 추가"
→ 먼저 Step 4-8 실행 → PASS 시 resource 추가, FAIL 시 bootstrap 수정부터

## Technical Details

- `templates/01-versions.tf` — terraform + required_providers pin 템플릿
- `templates/02-backend.tf` — S3 backend (lockfile / dynamodb 옵션)
- `templates/03-provider.tf` — provider aws + alias 예
- `templates/04-ctx.tf` — locals.ctx 스켈레톤
- `resources/01-bootstrap-checklist.md` — Step별 grep/exit-code 판정 규칙 상세

## Related Skills

- **devops**: terraform을 CI에서 실행 (OIDC + plan/apply workflow)
- **code-review**: terraform/IaC 리뷰 (lifecycle, state, credentials)
- **security**: IAM/네트워크 보안 점검
- **mise-config**: 로컬 terraform 버전 관리
