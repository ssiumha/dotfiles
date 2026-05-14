# Bootstrap Checklist — Quantitative Verdict per Step

SKILL.md의 Step 0–8 판정 규칙을 명령·기댓값·exit-code 표로 정리. 각 검사는 **단일 명령**으로 실행 가능해야 하며, 결과는 **숫자 또는 exit code**로 PASS/WARN/FAIL을 결정한다. 산문 판단은 허용하지 않는다.

## 변수

- `$TF_DIR` : 작업 대상 디렉토리 (기본 `.`)
- `$SKILL_DIR` : `~/.claude/skills/terraform`
- `$TF_CTX_*` : Step 1에서 사용자에게 받은 값

---

## Step 0 — Preflight

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| terraform 설치 | `terraform -version` | exit 0 AND `^Terraform v[0-9]+\.[0-9]+\.[0-9]+` | otherwise |
| AWS profile 유효 | `aws sts get-caller-identity --profile "$P"` | exit 0 | otherwise |

FAIL 시 후속 step 실행 금지.

---

## Step 1 — ctx variables collected

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| 6 vars set | `[ -n "$TF_CTX_PROJECT" ] && [ -n "$TF_CTX_ENV" ] && [ -n "$TF_CTX_REGION" ] && [ -n "$TF_CTX_PROFILE" ] && [ -n "$TF_STATE_BUCKET" ] && [ -n "$TF_STATE_KEY" ]` | exit 0 | exit ≠ 0 |
| env 형식 | `printf %s "$TF_CTX_ENV" \| grep -qE '^(dev\|staging\|prod)$'` | exit 0 | exit ≠ 0 |
| project 형식 | `printf %s "$TF_CTX_PROJECT" \| grep -qE '^[a-z0-9-]+$'` | exit 0 | exit ≠ 0 |

---

## Step 2 — Templates copied

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| 4 files exist | `ls -1 "$TF_DIR"/{versions,backend,provider,ctx}.tf 2>/dev/null \| wc -l` | `4` | `< 4` |

---

## Step 3 — No placeholder leak

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| REPLACE- count | `grep -rE 'REPLACE-[a-z-]+' "$TF_DIR"/*.tf \| wc -l` | `0` | `≥ 1` |

---

## Step 4 — Version pin

| Check | Command | PASS | WARN | FAIL |
|-------|---------|------|------|------|
| required_version pinned | `grep -cE '^[[:space:]]*required_version[[:space:]]*=[[:space:]]*"(~>\|=)' "$TF_DIR/versions.tf"` | `1` | `0` AND `required_version` 존재 (`>=` 단독) | `0` AND 미정의 |
| providers pinned | `grep -cE 'version[[:space:]]*=[[:space:]]*"(~>\|=)' "$TF_DIR/versions.tf"` | `≥ 1` | — | `0` |
| providers have source | `grep -cE 'source[[:space:]]*=[[:space:]]*"[a-z0-9_-]+/[a-z0-9_-]+"' "$TF_DIR/versions.tf"` | `≥ 1` | — | `0` |

판정 보조:
```bash
# required_version 존재 여부 (WARN 판정용)
grep -cE '^[[:space:]]*required_version[[:space:]]*=' "$TF_DIR/versions.tf"
```

---

## Step 5 — S3 backend

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| backend "s3" 단일 | `grep -c 'backend "s3"' "$TF_DIR/backend.tf"` | `1` | `0` |
| 금지 backend | `grep -cE 'backend "(local\|remote\|http\|pg\|kubernetes)"' "$TF_DIR/backend.tf"` | `0` | `≥ 1` |
| 5 keys present | per key: `grep -cE "^[[:space:]]*<key>[[:space:]]*=" "$TF_DIR/backend.tf"` (bucket/key/region/profile/encrypt) | 각 `1` | 하나라도 `0` |
| encrypt = true | `grep -cE '^[[:space:]]*encrypt[[:space:]]*=[[:space:]]*true' "$TF_DIR/backend.tf"` | `1` | `0` |
| lock mechanism | `grep -cE '(use_lockfile[[:space:]]*=[[:space:]]*true\|dynamodb_table[[:space:]]*=)' "$TF_DIR/backend.tf"` | `≥ 1` | `0` |

---

## Step 6 — Provider not env-dependent

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| region 명시 | `grep -cE '^[[:space:]]*region[[:space:]]*=' "$TF_DIR/provider.tf"` | `≥ 1` | `0` |
| profile 명시 | `grep -cE '^[[:space:]]*profile[[:space:]]*=' "$TF_DIR/provider.tf"` | `≥ 1` | `0` |
| empty provider 금지 | `grep -cE 'provider[[:space:]]+"aws"[[:space:]]*\{[[:space:]]*\}' "$TF_DIR/provider.tf"` | `0` | `≥ 1` |

---

## Step 7 — locals.ctx

| Check | Command | PASS | WARN | FAIL |
|-------|---------|------|------|------|
| locals 블록 | `grep -c '^locals' "$TF_DIR/ctx.tf"` | `≥ 1` | — | `0` |
| 5 keys present | per key in `project,env,region,profile,tags`: `grep -cE "^[[:space:]]+<k>[[:space:]]*=" "$TF_DIR/ctx.tf"` | 5/5 모두 `≥ 1` | 4/5 | `≤ 3/5` |

---

## Step 8 — terraform CLI

| Check | Command | PASS | FAIL |
|-------|---------|------|------|
| fmt | `terraform fmt -recursive -check "$TF_DIR"` | exit 0 | exit ≠ 0 |
| init | `terraform -chdir="$TF_DIR" init -backend=true -input=false` | exit 0 | exit ≠ 0 |
| validate | `terraform -chdir="$TF_DIR" validate` | exit 0 AND stdout `Success!` | otherwise |

---

## Step 9 — Final verdict

집계 규칙:
```
F = FAIL count
W = WARN count
verdict =
  PASS  if F == 0 and W <= 1
  WARN  if F == 0 and W >= 2
  FAIL  if F >= 1
```

FAIL 시 가장 앞선 FAIL step부터 수정. 그 step부터 모든 후속 step 재실행.

---

## 권장 검증 sweep (one-shot)

```bash
set -e
cd "$TF_DIR"

# Step 3
test "$(grep -rE 'REPLACE-[a-z-]+' *.tf | wc -l | tr -d ' ')" = "0"

# Step 4
grep -qE '^[[:space:]]*required_version[[:space:]]*=[[:space:]]*"(~>|=)' versions.tf
grep -qE 'version[[:space:]]*=[[:space:]]*"(~>|=)' versions.tf
grep -qE 'source[[:space:]]*=[[:space:]]*"[a-z0-9_-]+/[a-z0-9_-]+"' versions.tf

# Step 5
test "$(grep -c 'backend "s3"' backend.tf)" = "1"
test "$(grep -cE 'backend "(local|remote|http|pg|kubernetes)"' backend.tf)" = "0"
for k in bucket key region profile encrypt; do
  test "$(grep -cE "^[[:space:]]*${k}[[:space:]]*=" backend.tf)" = "1"
done
grep -qE '^[[:space:]]*encrypt[[:space:]]*=[[:space:]]*true' backend.tf
grep -qE '(use_lockfile[[:space:]]*=[[:space:]]*true|dynamodb_table[[:space:]]*=)' backend.tf

# Step 6
grep -qE '^[[:space:]]*region[[:space:]]*=' provider.tf
grep -qE '^[[:space:]]*profile[[:space:]]*=' provider.tf
test "$(grep -cE 'provider[[:space:]]+"aws"[[:space:]]*\{[[:space:]]*\}' provider.tf)" = "0"

# Step 7
grep -q '^locals' ctx.tf
for k in project env region profile tags; do
  grep -qE "^[[:space:]]+${k}[[:space:]]*=" ctx.tf
done

# Step 8
terraform fmt -recursive -check .
terraform init -backend=true -input=false
terraform validate
```

이 스크립트가 exit 0 → 전체 PASS. 그렇지 않으면 실패한 명령부터 수정.
