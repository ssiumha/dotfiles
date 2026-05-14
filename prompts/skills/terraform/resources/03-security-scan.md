# Security Scan — Step 10

tfsec / checkov / trivy / gitleaks 중 가용한 도구로 IaC 보안 스캔. 모두 JSON으로 받아 `jq`로 HIGH+CRITICAL 카운트만 판정에 사용.

## 도구 가용성 점검

```bash
HAS_TFSEC=$(command -v tfsec >/dev/null && echo 1 || echo 0)
HAS_CHECKOV=$(command -v checkov >/dev/null && echo 1 || echo 0)
HAS_TRIVY=$(command -v trivy >/dev/null && echo 1 || echo 0)
HAS_GITLEAKS=$(command -v gitleaks >/dev/null && echo 1 || echo 0)

AVAIL=$((HAS_TFSEC + HAS_CHECKOV + HAS_TRIVY))
```

- PASS 진입 조건: `AVAIL >= 1`
- 도구 0개 → 전체 step SKIP, 매트릭스에 `SKIP` 표기, 전체 판정은 최소 WARN

## tfsec

```bash
tfsec "$TF_DIR" --format json --soft-fail > /tmp/tfsec.json
HIGH_CRIT=$(jq '[.results[]? | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' /tmp/tfsec.json)
CRIT=$(jq '[.results[]? | select(.severity=="CRITICAL")] | length' /tmp/tfsec.json)
TOP=$(jq -r '[.results[]? | select(.severity=="HIGH" or .severity=="CRITICAL")] | .[0:5][] | "\(.severity) \(.rule_id) \(.location.filename):\(.location.start_line) \(.description)"' /tmp/tfsec.json)
```

## checkov

```bash
checkov -d "$TF_DIR" -o json --quiet --compact > /tmp/checkov.json 2>/dev/null || true
HIGH_CRIT_CK=$(jq '[.results.failed_checks[]? | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' /tmp/checkov.json)
CRIT_CK=$(jq '[.results.failed_checks[]? | select(.severity=="CRITICAL")] | length' /tmp/checkov.json)
```

## trivy (config + secret)

```bash
trivy config "$TF_DIR" --format json --severity HIGH,CRITICAL --quiet > /tmp/trivy-conf.json
HIGH_CRIT_TV=$(jq '[.Results[]?.Misconfigurations[]?] | length' /tmp/trivy-conf.json)

trivy fs --scanners vuln,secret "$TF_DIR" --format json --severity HIGH,CRITICAL --quiet > /tmp/trivy-fs.json
SECRETS_TV=$(jq '[.Results[]?.Secrets[]?] | length' /tmp/trivy-fs.json)
```

## gitleaks (state/.tf 누출 secrets)

```bash
gitleaks detect --source "$TF_DIR" --no-banner --report-format json --report-path /tmp/gitleaks.json --exit-code 0
LEAKS=$(jq 'length' /tmp/gitleaks.json)
```

## 합산 판정

```bash
TOTAL_HC=$((HIGH_CRIT + HIGH_CRIT_CK + HIGH_CRIT_TV))
TOTAL_C=$((CRIT + CRIT_CK))
TOTAL_SECRETS=$((SECRETS_TV + LEAKS))
```

| 조건 | 판정 |
|------|------|
| `TOTAL_C >= 1` 또는 `TOTAL_SECRETS >= 1` | **FAIL** |
| `TOTAL_HC >= 3` | **FAIL** |
| `1 <= TOTAL_HC <= 2` AND `TOTAL_C == 0` AND `TOTAL_SECRETS == 0` | **WARN** |
| 모두 `0` | **PASS** |

## 보고 형식

```
[Security Scan]
  tools used   : tfsec={HAS_TFSEC} checkov={HAS_CHECKOV} trivy={HAS_TRIVY} gitleaks={HAS_GITLEAKS}
  high+crit    : {TOTAL_HC}
  critical     : {TOTAL_C}
  secrets      : {TOTAL_SECRETS}
  verdict      : {PASS|WARN|FAIL}

[Top findings] (HIGH+CRITICAL, max 5)
  {SEVERITY} {RULE_ID} {FILE}:{LINE} {SHORT_DESC}
  ...
```

## 후속 처리

- FAIL: 각 finding의 `rule_id` 기준으로 SKILL.md Step 11 매트릭스에 반영. 수정 전까지 `apply` 금지.
- WARN: 사용자에게 보고 후 진행 여부 확인. 무시할 finding은 `# tfsec:ignore:<rule_id>` 또는 `# checkov:skip=<id>` 코멘트로 명시(이유 포함).
- 도구 자체의 룰 업데이트 주기: tfsec/checkov는 정기 갱신 → CI에서도 같은 명령 사용 권장 (devops/github-action 참조)

## 정책 vs 룰 우선순위

1. **회사/팀 보안 정책**이 우선 (사용자가 별도 알려준 경우)
2. 다음으로 tfsec/checkov/trivy 내장 룰
3. 충돌 시 사용자 정책으로 ignore 처리, 이유를 PR 설명에 기록

## 환경별 임계 조정

| env | HIGH+CRITICAL 임계 |
|-----|--------------------|
| `prod` | `0`만 PASS |
| `staging` | `≤ 1` WARN, 그 외 FAIL |
| `dev` | `≤ 2` WARN, 그 외 FAIL |

`$TF_CTX_ENV` 값에 따라 step 10의 PASS/WARN 경계를 좁힌다.
