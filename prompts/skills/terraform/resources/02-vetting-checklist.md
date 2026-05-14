# Provider/Module Vetting Checklist — Step 2

도입 전 정량 점검. registry 메타 + GitHub 메타를 명령으로 조회하여 8개 항목을 카운트/문자열 매칭으로 판정한다.

## 입력 정규화

사용자가 부르는 의존성을 다음 두 형태 중 하나로 표준화한 뒤 호출:

- Provider: `<namespace>/<name>@<pinned>` (예: `hashicorp/aws@5.70.0`)
- Module (registry): `<namespace>/<name>/<system>@<pinned>` (예: `terraform-aws-modules/vpc/aws@5.0.0`)
- Module (git): `git::<url>?ref=<tag>` — 이 경우 registry 메타 조회 SKIP, GitHub 메타만 사용

추출:
```bash
NS=<namespace>; NAME=<name>; SYSTEM=<aws|google|...>; PINNED=<X.Y.Z>
```

## Provider 메타 (Terraform Registry)

```bash
META=$(curl -fsSL "https://registry.terraform.io/v1/providers/$NS/$NAME")
TIER=$(printf %s "$META" | jq -r '.tier')
LATEST=$(printf %s "$META" | jq -r '.version')
SOURCE=$(printf %s "$META" | jq -r '.source')
DEP=$(printf %s "$META" | jq -r '.deprecation_status // "none"')
PUBLISHED=$(printf %s "$META" | jq -r '.published_at')
```

| 변수 | 의미 | PASS 기준 |
|------|------|-----------|
| `TIER` | official / partner / community | `official` 또는 `partner` |
| `LATEST` | registry 최신 | semver 파싱 가능 |
| `SOURCE` | GitHub URL (대개) | `https://github.com/.+` |
| `DEP` | deprecation_status | `none` |
| `PUBLISHED` | 최신 release timestamp | 24개월 내 |

## Module 메타

```bash
MMETA=$(curl -fsSL "https://registry.terraform.io/v1/modules/$NS/$NAME/$SYSTEM")
MLATEST=$(printf %s "$MMETA" | jq -r '.version')
MSOURCE=$(printf %s "$MMETA" | jq -r '.source')
MVERIFIED=$(printf %s "$MMETA" | jq -r '.verified')
MDOWNLOADS=$(printf %s "$MMETA" | jq -r '.downloads')
```

| 변수 | PASS 기준 |
|------|-----------|
| `MVERIFIED` | `true` (HashiCorp 검증) — `false`는 WARN |
| `MLATEST` | semver, pinned와 비교 |
| `MSOURCE` | github URL 추출 가능 |
| `MDOWNLOADS` | `>= 10000` — 미만은 WARN |

## GitHub 메타 (source repo)

```bash
# SOURCE 또는 MSOURCE에서 owner/repo 추출
OWNER=$(printf %s "$SOURCE" | sed -E 's|https?://github.com/([^/]+)/([^/]+).*|\1|')
REPO=$(printf %s "$SOURCE" | sed -E 's|https?://github.com/([^/]+)/([^/]+).*|\2|' | sed 's/\.git$//')

GH=$(gh api "repos/$OWNER/$REPO" --jq '{archived,disabled,owner_type:.owner.type,pushed_at,license:(.license.spdx_id // "NONE"),stars:.stargazers_count}')
```

| 필드 | PASS 기준 | WARN | FAIL |
|------|-----------|------|------|
| `archived` | `false` | — | `true` |
| `disabled` | `false` | — | `true` |
| `owner_type` | `Organization` | `User` | 누락 |
| `pushed_at` | 12개월 내 | 12-24개월 | 24개월 초과 |
| `license` | OSI 승인 SPDX (`Apache-2.0`/`MIT`/`MPL-2.0`/`BSD-*`/`GPL-*`) | 비표준 | `NONE` |
| `stars` (참고) | ≥ 50 | 10-49 | < 10 (커뮤니티 검증 부족) |

## 보안 advisory 조회

```bash
# GitHub Security Advisory
gh api -X GET "repos/$OWNER/$REPO/security-advisories" \
  --jq '[.[]? | select(.state=="published" and .severity=="critical" or .severity=="high")] | length'

# osv.dev (선택)
curl -fsSL -X POST https://api.osv.dev/v1/query \
  -d "{\"package\":{\"name\":\"$NS/$NAME\",\"ecosystem\":\"Terraform\"}}" \
  | jq '[.vulns[]?] | length'
```
- PASS: 둘 다 `0`
- FAIL: 어느 하나라도 `≥ 1` AND 공개된 critical/high

## 버전 차이 판정

```bash
# pinned vs latest
PIN_MAJ=$(printf %s "$PINNED" | cut -d. -f1)
PIN_MIN=$(printf %s "$PINNED" | cut -d. -f2)
LAT_MAJ=$(printf %s "$LATEST" | cut -d. -f1)
LAT_MIN=$(printf %s "$LATEST" | cut -d. -f2)
```

| 차이 | 판정 |
|------|------|
| `PIN_MAJ < LAT_MAJ` | FAIL (major 뒤처짐) |
| `PIN_MAJ == LAT_MAJ` AND `LAT_MIN - PIN_MIN >= 2` | WARN |
| `PIN_MAJ == LAT_MAJ` AND `LAT_MIN - PIN_MIN <= 1` | PASS |
| `PINNED == LATEST` | PASS |

## 의존성당 최종 매트릭스

```
provider/module : <ns>/<name>
  tier           : {official|partner|community}   → {PASS|WARN}
  deprecation    : {none|active}                  → {PASS|FAIL}
  verified       : {true|false}  (module만)        → {PASS|WARN}
  archived       : {false|true}                   → {PASS|FAIL}
  owner_type     : {Organization|User}            → {PASS|WARN}
  pushed_at      : <ISO8601>  (≤12mo / ≤24mo / >24mo) → {PASS|WARN|FAIL}
  license        : <SPDX|NONE>                    → {PASS|WARN|FAIL}
  advisories     : <count>                        → {PASS|FAIL}
  pinned vs latest: <delta>                       → {PASS|WARN|FAIL}
```

전체 PASS: FAIL 0 AND WARN ≤ 2. FAIL 시 채택 금지.

## one-shot 스크립트 골격

```bash
vet_provider() {
  local NS=$1 NAME=$2 PINNED=$3
  local META TIER LATEST SOURCE DEP OWNER REPO GH F W
  META=$(curl -fsSL "https://registry.terraform.io/v1/providers/$NS/$NAME") || { echo "FAIL: registry $NS/$NAME"; return 1; }
  TIER=$(printf %s "$META" | jq -r '.tier')
  LATEST=$(printf %s "$META" | jq -r '.version')
  SOURCE=$(printf %s "$META" | jq -r '.source')
  DEP=$(printf %s "$META" | jq -r '.deprecation_status // "none"')
  OWNER=$(printf %s "$SOURCE" | sed -E 's|.*github.com/([^/]+)/.*|\1|')
  REPO=$(printf %s "$SOURCE" | sed -E 's|.*github.com/[^/]+/([^/]+).*|\1|' | sed 's/\.git$//')
  GH=$(gh api "repos/$OWNER/$REPO" --jq '{archived,disabled,owner_type:.owner.type,pushed_at,license:(.license.spdx_id // "NONE")}')

  printf 'vet %s/%s@%s | tier=%s latest=%s dep=%s gh=%s\n' "$NS" "$NAME" "$PINNED" "$TIER" "$LATEST" "$DEP" "$GH"

  F=0; W=0
  [ "$DEP" = "none" ] || F=$((F+1))
  [ "$(printf %s "$GH" | jq -r .archived)" = "false" ] || F=$((F+1))
  [ "$(printf %s "$GH" | jq -r .disabled)" = "false" ] || F=$((F+1))
  case "$TIER" in official|partner) ;; community) W=$((W+1)) ;; *) F=$((F+1)) ;; esac
  [ "$(printf %s "$GH" | jq -r .owner_type)" = "Organization" ] || W=$((W+1))
  printf 'verdict %s/%s : F=%s W=%s\n' "$NS" "$NAME" "$F" "$W"
  [ $F -eq 0 ]
}
```

사용: `vet_provider hashicorp aws 5.70.0`

## SKIP 처리

- registry 메타 조회 실패: 미공개 provider/module → 채택 금지 (FAIL)
- `gh` CLI 미인증: `gh auth status` 확인 후 재시도. 인증 불가하면 `curl -fsSL https://api.github.com/repos/$OWNER/$REPO`로 fallback
- `jq` 미설치: 설치 안내 후 step 차단
