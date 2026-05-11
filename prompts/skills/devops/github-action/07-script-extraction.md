# Script Extraction — 워크플로 얇게, 로직은 스크립트로

## 원칙

`run:` 블록에 담긴 쉘·Python·Node 스크립트는 **GitHub Actions 밖에서 실행·테스트·재현할 수 없다**. 로직은 로컬과 CI 어디서도 같은 명령으로 실행되는 스크립트(Justfile recipe, `scripts/*.sh`, CLI)로 빼고, 워크플로는 **조립(trigger, matrix, secrets, artifact, concurrency)** 에만 집중한다.

> 이름 있는 원칙은 아니다. 12-Factor Factor 10 "Dev/Prod Parity"의 CI 적용 사례이자 "Pipeline as Code"의 실천 방식.

## 판단 기준

### 추출 (스크립트로 뺄 것)

| 신호 | 이유 |
|------|------|
| `run:` 블록이 2줄 이상이거나 파이프·조건·루프 포함 | 로컬 재현 가치 |
| 같은 로직이 여러 job/workflow에 반복 | DRY + 로컬 공유 |
| 디버깅·재시도가 필요할 가능성 있음 | 로컬에서 반복 실행 가능해야 |
| 로컬 개발자가 "이거 그대로 돌려보고 싶다" | lint·test·build·package 대부분 해당 |
| heredoc으로 Python/Node 임베딩 | YAML 안의 다른 언어는 거의 항상 추출 대상 |

### 남김 (워크플로에 유지)

| 신호 | 이유 |
|------|------|
| `${{ github.event.* }}` / `${{ needs.* }}` / `${{ matrix.* }}` 직접 참조 | GHA 고유 컨텍스트 — 추출 불가 |
| `actions/checkout`, `actions/upload-artifact`, `actions/cache` 호출 | runner 전용 API |
| job-level `permissions`, `concurrency`, `environment`, OIDC `id-token` | workflow orchestration |
| `if: failure() / always()` 같은 상태 기반 분기 | GHA 실행 모델 |
| 한 줄짜리 명령 (`just ci-test`, `npm ci`) | 이미 충분히 얇음 |

## 추출 대상 선택

| 대상 | 언제 |
|------|------|
| **Justfile recipe** | 로컬 개발자가 자주 호출, 네이밍이 중요 — `task-naming` skill 참조 |
| **`scripts/*.sh`** | 복잡도 낮고 쉘 파이프라인으로 충분 |
| **Python/Node CLI** | 외부 API 호출, JSON/YAML 파싱, 복잡한 로직 |
| **Composite Action** | GHA 전용 로직이지만 여러 workflow에서 재사용 (로컬 재현은 포기) |

우선순위: **Justfile recipe > scripts > CLI > composite action**. 로컬 친화도가 낮아질수록 오른쪽.

## Bridging — GHA 컨텍스트를 스크립트로 넘기기

GHA 변수는 스크립트 경계에서 **환경변수로 변환**. 커맨드 인자 내부에 `${{ }}`를 끼워 넣지 않는다 (shell injection 위험).

```yaml
# ❌ 나쁨 — shell injection 위험, 로컬 재현 불가
- run: ./scripts/deploy.sh ${{ github.event.head_commit.message }}

# ✅ 좋음 — env 경계, 로컬에서도 COMMIT_MSG=... ./scripts/deploy.sh 로 재현
- run: ./scripts/deploy.sh
  env:
    COMMIT_MSG: ${{ github.event.head_commit.message }}
    MATRIX_OS: ${{ matrix.os }}
    TARGET_ENV: ${{ inputs.environment }}
```

### Secrets

```yaml
- run: just deploy
  env:
    AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
    # never pass secrets via command args — shell history/logs에 남는다
```

### Step output

스크립트가 값을 돌려줘야 하면 stdout 또는 `$GITHUB_OUTPUT`:

```bash
# scripts/detect-version.sh — 로컬·CI 공통
#!/usr/bin/env bash
version=$(git describe --tags --abbrev=0)
echo "$version"                                         # 로컬
[[ -n "$GITHUB_OUTPUT" ]] && echo "version=$version" >> "$GITHUB_OUTPUT"  # CI
```

```yaml
- id: detect
  run: ./scripts/detect-version.sh
- run: echo "Deploying ${{ steps.detect.outputs.version }}"
```

## 로컬 재현

### `act` — GHA 로컬 runner

```bash
act -j test                    # 특정 job 실행
act -W .github/workflows/ci.yml
act --secret-file .secrets     # secrets 주입
```

한계: `act`는 Ubuntu runner에 가까울 뿐 완전 동등하지 않다. matrix(특히 macos/windows), OIDC, GitHub-hosted 전용 API는 재현 불가. **스크립트 자체는 `just ci-test` 같은 recipe로 직접 부르는 것이 더 빠르고 확실**.

### Justfile recipe 네이밍

`task-naming` skill의 GAT (group-action-target) 규칙에 따라:

```justfile
# ci 접두로 묶으면 CI 관점에서 부를 수 있음
ci-lint:       just lint
ci-test:       just test
ci-build:      just build
ci-e2e:        docker compose -f compose.e2e.yaml run --rm e2e

# 개발자는 lint/test/build 직접 호출, CI는 ci-* 변형으로 호출
```

## Anti-patterns

| 안티패턴 | 문제 |
|----------|------|
| `run:` 안에 30줄짜리 bash 스크립트 | 로컬 재현 불가, 테스트 불가, diff 리뷰 지옥 |
| `run: \| python -c "import json; ..."` (heredoc Python) | 언어 IDE 지원 상실, lint 안 됨, import 없음 |
| 같은 7줄 bash가 5개 workflow에 복붙 | DRY 위반, 변경 시 모두 고쳐야 |
| 스크립트가 `$GITHUB_*` 환경변수에 강하게 의존 | 로컬에선 조건 분기 없이 터짐 |
| `run:` 블록에서 `jq`/`yq`로 복잡한 파싱 | 한 번 실수하면 silent fail, 스크립트로 빼서 테스트 |
| GHA-only 래퍼 스크립트 (`scripts/ci/*.sh`만 존재, 로컬 경로 없음) | Parity의 본뜻 어긋남 |

## Before / After

### Before — 워크플로 안에 모든 로직

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: |
          npm ci
          npm run lint
          npm run test -- --coverage
          if [ -f coverage/coverage-summary.json ]; then
            pct=$(jq '.total.lines.pct' coverage/coverage-summary.json)
            if (( $(echo "$pct < 80" | bc -l) )); then
              echo "Coverage $pct% below threshold"
              exit 1
            fi
          fi
```

### After — 로직은 Justfile, workflow는 조립

```justfile
# Justfile
install:       npm ci
lint:          npm run lint
test:          npm run test -- --coverage
check-coverage:
    @pct=$(jq '.total.lines.pct' coverage/coverage-summary.json); \
    if [ "$(echo "$pct < 80" | bc -l)" = "1" ]; then \
      echo "Coverage $$pct% below threshold"; exit 1; \
    fi

ci-test: install lint test check-coverage
```

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - uses: extractions/setup-just@v2
      - run: just ci-test
```

로컬 개발자는 `just ci-test` 하나면 CI가 하는 전부를 돌릴 수 있다. 커버리지 임계값 로직은 Justfile 한 군데만 바꾸면 로컬·CI 동시 반영.

## 다른 리소스와의 관계

| 리소스 | 관계 |
|--------|------|
| `../ci-cd/` (Justfile, pre-commit) | 추출 대상의 주요 목적지 — recipe 설계는 ci-cd 도메인 |
| `01-workflow-basics.md` | 추출 후 워크플로가 얇아졌을 때 올바른 조립 패턴 |
| `02-custom-actions.md` | GHA-only 재사용은 composite action (로컬 parity 포기) |
| `08-observability.md` | 추출된 스크립트가 stdout에 뱉는 구조화된 출력이 GHA annotation으로 연결 |
| `task-naming` skill | Justfile recipe 네이밍 규칙 |
