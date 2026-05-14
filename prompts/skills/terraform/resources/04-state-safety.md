# Resource Interference & State Safety — Step 10

기존 리소스를 덮어쓰거나 제거하는 변경을 *plan 단계*에서 차단. 4개 sub-step으로 정량 판정.

## 변수

```bash
STATEFUL_RE='aws_(db_instance|rds_cluster|s3_bucket|kms_key|dynamodb_table|efs_file_system|elasticache_cluster|elasticsearch_domain|opensearch_domain|iam_user|iam_role|secretsmanager_secret|cloudwatch_log_group|route53_zone)'
```

stateful 목록은 회사 정책에 맞춰 확장 가능. 데이터 영속성 또는 신원/권한 객체가 기준.

## 10a — lifecycle.prevent_destroy 강제

```bash
COUNT_STATEFUL=$(grep -rEo "resource \"${STATEFUL_RE}\"" "$TF_DIR" --include='*.tf' | wc -l)

# resource 블록 내부에 lifecycle { prevent_destroy = true } 가 있는지 (블록당 1매칭)
COUNT_PROTECTED=$(awk '
  /^resource "/ { in_res=1; type=$2; next }
  in_res && /lifecycle/ { in_lc=1 }
  in_res && in_lc && /prevent_destroy[[:space:]]*=[[:space:]]*true/ {
    gsub(/"/,"",type); if (type ~ /'"${STATEFUL_RE}"'/) c++
  }
  /^}/ && in_res { in_res=0; in_lc=0 }
  END { print c+0 }
' "$TF_DIR"/*.tf)
```

| 조건 | 판정 |
|------|------|
| `COUNT_STATEFUL == 0` | PASS (해당 없음) |
| `COUNT_PROTECTED == COUNT_STATEFUL` | PASS |
| `COUNT_PROTECTED >= COUNT_STATEFUL - 1` | WARN |
| 그 외 | FAIL |

목록 정확 추출:
```bash
grep -rEo "resource \"${STATEFUL_RE}\" \"[a-z0-9_-]+\"" "$TF_DIR" --include='*.tf'
```

## 10b — State 백업

apply/plan/state 조작 전에 항상 현재 state를 스냅샷.

```bash
mkdir -p "$TF_DIR/.tf-backups"
TS=$(date -u +%Y%m%dT%H%M%SZ)
BAK="$TF_DIR/.tf-backups/state-$TS.json"
terraform -chdir="$TF_DIR" state pull > "$BAK"
BAK_BYTES=$(wc -c < "$BAK")
RES_COUNT=$(jq -r '.resources | length' "$BAK" 2>/dev/null)
```

| 조건 | 판정 |
|------|------|
| `state pull` exit 0 AND `BAK_BYTES > 0` | PASS |
| `state pull` exit 0 AND `BAK_BYTES == 0` AND `RES_COUNT == 0` | PASS (신규 프로젝트) |
| `state pull` exit ≠ 0 | FAIL (backend 접근 실패 — Step 9 재확인) |

백업 보존:
- `.tf-backups/`는 `.gitignore` 권장 — 백업에는 평문 secret이 포함될 수 있음
- 사용자 자체 파일 보관 정책이 있다면 그것 우선

## 10c — Plan diff (destroy/replace)

```bash
terraform -chdir="$TF_DIR" plan -out=/tmp/tfplan -input=false -lock-timeout=60s
terraform -chdir="$TF_DIR" show -json /tmp/tfplan > /tmp/tfplan.json
```

카운트 (jq):

```bash
CREATE=$(jq '[.resource_changes[]? | select(.change.actions == ["create"])]                                | length' /tmp/tfplan.json)
UPDATE=$(jq '[.resource_changes[]? | select(.change.actions == ["update"])]                                | length' /tmp/tfplan.json)
DELETE=$(jq '[.resource_changes[]? | select(.change.actions == ["delete"])]                                | length' /tmp/tfplan.json)
REPLACE=$(jq '[.resource_changes[]? | select((.change.actions|join(",")) | test("delete.*create|create.*delete"))] | length' /tmp/tfplan.json)

DESTRUCT_STATEFUL=$(jq --arg re "$STATEFUL_RE" '
  [.resource_changes[]?
    | select(.type | test($re))
    | select(.change.actions
        | (contains(["delete"])
          or contains(["create","delete"])
          or contains(["delete","create"])))
  ] | length' /tmp/tfplan.json)
```

목록 (보고용):

```bash
jq -r '.resource_changes[]?
  | select(.change.actions | (contains(["delete"]) or contains(["create","delete"]) or contains(["delete","create"])))
  | "  \(.change.actions|join("+")) \(.type).\(.name)"' /tmp/tfplan.json
```

| 조건 | 판정 |
|------|------|
| `DELETE == 0` AND `REPLACE == 0` | PASS |
| `DESTRUCT_STATEFUL == 0` AND `DELETE + REPLACE <= 2` | WARN (사용자 확인 후 진행) |
| `DESTRUCT_STATEFUL >= 1` OR `DELETE + REPLACE >= 3` | FAIL |

FAIL 시 후속 step·apply 모두 차단. 의도된 변경이면:
1. 해당 resource에 `lifecycle.prevent_destroy = true` 또는 적절한 이동(`moved` 블록) 작성
2. import 대상이라면 10d 참조

## 10d — Import / state-op 가드

`terraform import`, `import` 블록(>= 1.5), `terraform state mv|rm`은 모두 state를 직접 바꾼다.

### import 블록 검사

```bash
grep -cE '^[[:space:]]*import[[:space:]]*\{' "$TF_DIR"/*.tf
```

import 블록 1개 이상이면:

```bash
# 각 import의 to = ... 대상 resource 블록이 같은 디렉토리에 존재해야 함
awk '/^[[:space:]]*import[[:space:]]*\{/,/^}/' "$TF_DIR"/*.tf \
  | grep -E '^[[:space:]]*to[[:space:]]*=' \
  | sed -E 's/.*=\s*//; s/[[:space:]]*$//'
```

| 조건 | 판정 |
|------|------|
| import 0개 | PASS |
| import N개 AND 각 `to` 가 같은 디렉토리의 resource로 해소됨 AND 10c PASS/WARN | PASS |
| 위 조건 미충족 | FAIL |

### state mv / state rm 가드

skill 자체가 `terraform state mv|rm`을 실행하지 않는다. 사용자가 직접 메인에서 실행할 때 다음을 강제:

1. 10b 백업이 같은 세션에 PASS인 상태여야 한다
2. `mv` 대상은 `moved` 블록(>= 1.1)으로 코드에 남기는 것을 우선
3. `rm`은 다른 manager로 이양하거나 진짜 제거할 때만 — 이유를 PR 설명에 기록

## 10e — Step 10 합산

```
10a prevent_destroy : {PASS|WARN|FAIL}  (protected/stateful = <p>/<s>)
10b state backup    : {PASS|FAIL}       (bytes=<b> resources=<r>)
10c plan diff       : {PASS|WARN|FAIL}  (C=<c> U=<u> D=<d> R=<r> S=<s>)
10d import/state-op : {PASS|FAIL}
```

Step 10 verdict:
- PASS: 4개 sub 모두 PASS
- WARN: FAIL 0 AND WARN ≥ 1
- FAIL: FAIL ≥ 1 → apply·후속 step 모두 차단

## one-shot sweep

```bash
set -e
cd "$TF_DIR"
STATEFUL_RE='aws_(db_instance|rds_cluster|s3_bucket|kms_key|dynamodb_table|efs_file_system|elasticache_cluster|elasticsearch_domain|opensearch_domain|iam_user|iam_role|secretsmanager_secret|cloudwatch_log_group|route53_zone)'

mkdir -p .tf-backups
terraform state pull > ".tf-backups/state-$(date -u +%Y%m%dT%H%M%SZ).json"

terraform plan -out=/tmp/tfplan -input=false -lock-timeout=60s
terraform show -json /tmp/tfplan > /tmp/tfplan.json

D=$(jq '[.resource_changes[]?|select(.change.actions==["delete"])]|length' /tmp/tfplan.json)
R=$(jq '[.resource_changes[]?|select((.change.actions|join(","))|test("delete.*create|create.*delete"))]|length' /tmp/tfplan.json)
S=$(jq --arg re "$STATEFUL_RE" '[.resource_changes[]?|select(.type|test($re))|select(.change.actions|(contains(["delete"])or contains(["create","delete"])or contains(["delete","create"])))]|length' /tmp/tfplan.json)

test "$D" = "0" && test "$R" = "0" && test "$S" = "0"
```

exit 0 → 10c PASS. 아니면 위 표로 WARN/FAIL 판정.
