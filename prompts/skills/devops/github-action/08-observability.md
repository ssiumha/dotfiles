# Observability — 실패 원인을 파이프라인 밖에서도 알 수 있게

## 원칙

CI가 빨간 불이 되면 **로그를 끝까지 읽지 않고도 원인·범위·재현 방법**이 드러나야 한다. 가시성은 사후약방문이 아니라 워크플로 설계 단계에서 심는다.

5개 축:

1. **Logs** — 구조화된 섹션, 의미 있는 메시지
2. **Step Summary** — markdown 리포트 (테스트 결과, 커버리지, 벤치마크)
3. **Annotations** — PR diff 옆에 붙는 inline error/warning
4. **Artifacts** — 로그·리포트·스크린샷을 다운로드 가능하게
5. **Naming & Timing** — job·step 이름과 실행 시간으로 병목 식별

## 1. Logs

### `::group::` 으로 섹션화

긴 출력을 접을 수 있게:

```bash
echo "::group::Installing dependencies"
npm ci
echo "::endgroup::"

echo "::group::Running tests"
npm test
echo "::endgroup::"
```

스크립트 내부에서도 가능 — GHA 환경에서만 의미 있고 로컬에선 무해 (그냥 `::group::` 텍스트가 찍힘).

### 로그 메시지 원칙

- **무엇을 하고 있는지** + **왜** 를 한 줄로
- 실패 시 **무엇을 기대했고 무엇이 왔는지** 둘 다
- 외부 호출(네트워크, DB)은 대상과 소요 시간 기록
- `set -x` 대신 명시적 로그 — 민감값 노출 위험 피함

```bash
# ❌
echo "done"

# ✅
echo "✓ Migrated 142 rows from users → users_v2 (2.3s)"
```

### 민감값 마스킹

secrets는 GHA가 자동 마스킹하지만, **조합·파생값은 안 됨**:

```bash
# ❌ TOKEN이 base64됐다고 자동 마스킹 안 됨
echo "Auth: $(echo -n "$GITHUB_TOKEN" | base64)"

# ✅ 명시적 add-mask
encoded=$(echo -n "$GITHUB_TOKEN" | base64)
echo "::add-mask::$encoded"
```

## 2. Step Summary — `$GITHUB_STEP_SUMMARY`

workflow run 페이지 상단에 표시되는 markdown. PR 리뷰어·장애 대응자가 로그 펼치지 않고도 핵심을 본다.

```bash
# 테스트 리포트
{
  echo "## Test Results"
  echo ""
  echo "| Suite | Pass | Fail | Duration |"
  echo "|-------|------|------|----------|"
  echo "| unit | 142 | 0 | 12s |"
  echo "| integration | 38 | 2 | 48s |"
  echo ""
  echo "### Failed tests"
  echo ""
  echo '```'
  cat test-failures.txt
  echo '```'
} >> "$GITHUB_STEP_SUMMARY"
```

**넣을 것**:
- 테스트/커버리지/lint 요약 표
- 빌드 artifact 크기·버전
- 배포 대상 환경·리전·리비전
- 변경된 파일 요약 (path filter 결과)
- 벤치마크 비교 (base vs PR)

**넣지 말 것**: 전체 로그 덤프, 민감값, 바이너리 출력.

## 3. Annotations — 인라인 경고

workflow command로 PR diff 옆 annotation 생성:

```bash
echo "::error file=src/user.ts,line=42,col=8::Null check missing"
echo "::warning file=src/api.ts,line=10::Deprecated API usage"
echo "::notice file=Dockerfile,line=3::Consider pinning base image digest"
```

많은 도구가 이미 GHA 포맷을 지원:
- ESLint: `--format=@eslint/github-action`
- Ruff: `--output-format=github`
- mypy: `mypy --output=github` (일부 플러그인)
- JUnit XML → `dorny/test-reporter` action

추출된 스크립트가 structured output(JSON/SARIF)을 뱉으면 `07-script-extraction.md`의 경계에서 annotation으로 변환 — 로컬에선 그냥 텍스트, CI에선 annotation.

## 4. Artifacts — 사후 분석용

**실패했을 때 가장 먼저 받고 싶은 것**을 artifact로:

```yaml
- name: Run E2E
  run: just ci-e2e

- name: Upload e2e artifacts
  if: always()  # 실패해도 업로드
  uses: actions/upload-artifact@v4
  with:
    name: e2e-results-${{ matrix.browser }}
    path: |
      playwright-report/
      test-results/
      logs/
    retention-days: 14
```

**원칙**:
- `if: always()` — 실패 시에도 업로드 (가장 필요한 순간)
- matrix면 `name`에 matrix 값 포함 (덮어쓰기 방지)
- 민감값 파일(.env, 인증서) 제외 — `.gitignore` 패턴 재사용
- `retention-days` 명시 — 기본 90일, 대용량이면 줄임

**넣을 것**: 스크린샷, HTML 커버리지 리포트, 로그 번들, JUnit XML, build artifact, docker image inspect 덤프.

## 5. Naming & Timing

### Job / Step name

```yaml
# ❌ 무슨 작업인지 요약에서 안 보임
jobs:
  job1:
    steps:
      - run: npm ci
      - run: npm test

# ✅
jobs:
  unit-tests:
    name: Unit tests (Node ${{ matrix.node }})
    steps:
      - name: Install dependencies
        run: npm ci
      - name: Run Jest
        run: npm test
```

workflow run 요약에서 **어느 job·step이 실패했는가**가 즉시 보인다.

### Timing

- GHA 요약 페이지에서 각 step 시간 노출 — 긴 step은 자연히 눈에 띔
- 병목이 의심되면 내부에서도 타이밍 출력:

```bash
t0=$(date +%s)
./heavy-task.sh
echo "heavy-task took $(($(date +%s) - t0))s"
```

## 실패 컨텍스트

실패 시에만 추가 정보 수집:

```yaml
- name: Run integration tests
  id: itest
  run: just ci-integration

- name: Collect diagnostics on failure
  if: failure() && steps.itest.conclusion == 'failure'
  run: |
    echo "::group::Docker compose logs"
    docker compose logs --tail=200
    echo "::endgroup::"
    echo "::group::Container state"
    docker compose ps
    echo "::endgroup::"
    docker compose logs > logs/compose.log

- name: Upload diagnostics
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: diagnostics-${{ github.run_id }}
    path: logs/
```

### `continue-on-error`의 함정

`continue-on-error: true`를 쓰면 step은 실패해도 **job은 성공**으로 표시된다. 가시성 관점에서 최악 — 빨간 불이 안 뜬다. 꼭 필요하면:
- annotation으로 명시 (`::warning::`)
- Step Summary에 "이 step 실패함" 표시
- 가능하면 `continue-on-error` 대신 별도 job + `needs: [...]` 관계로 분리

## Debug 모드

### Repository 레벨 — 재실행 시

workflow run 페이지 → "Re-run jobs" → "Enable debug logging" 체크.

내부적으로 두 secret을 설정한 것과 동등:
- `ACTIONS_STEP_DEBUG=true` — step 내부 상세 로그
- `ACTIONS_RUNNER_DEBUG=true` — runner 자체 상세 로그

원인 찾으면 **반드시 끄기** — 평시에 켜두면 민감값이 더 자주 로그에 노출될 위험.

### 임시 디버그 step

```yaml
- name: Dump context
  if: runner.debug == '1'
  run: |
    echo "::group::GitHub context"
    echo '${{ toJson(github) }}'
    echo "::endgroup::"
    echo "::group::Env"
    env | sort
    echo "::endgroup::"
```

`runner.debug == '1'`은 debug 모드일 때만 실행되어 평시에는 무해.

## Anti-patterns

| 안티패턴 | 문제 |
|----------|------|
| 실패 원인이 `Error: exit code 1` 한 줄만 남음 | 재현 정보 부재 |
| `echo $PASSWORD` 같은 명시적 민감값 출력 | 마스킹 우회, 로그 유출 |
| 모든 step에 `continue-on-error: true` | 빨간 불 안 뜸, 실패가 숨김 |
| artifact 없이 E2E 실패 | 스크린샷·로그 없이 원인 추적 불가 |
| Step Summary 빈 상태 | 로그 전체를 펼쳐야 상황 파악 가능 |
| `set -x` 를 secrets 있는 구간에서 사용 | 환경변수가 전개되어 로그에 노출 |
| 각 step 이름이 기본값 (`Run xxx`) | 요약 페이지에서 job 흐름 추적 불가 |

## 체크리스트

신규 workflow 작성 후 자가 점검:

- [ ] 모든 job·step에 의미 있는 `name:` 있음
- [ ] 긴 로그 블록이 `::group::`로 접혀 있음
- [ ] 테스트/빌드 결과 요약이 `$GITHUB_STEP_SUMMARY`에 기록됨
- [ ] 실패 시 diagnostics artifact가 `if: always()`로 업로드됨
- [ ] lint/test 도구가 GHA annotation 포맷을 출력하거나 wrapper로 변환됨
- [ ] `continue-on-error` 사용처가 정당화됨 (없으면 더 좋음)
- [ ] debug secrets는 평시에 꺼져 있음
- [ ] artifact에 민감값 파일이 포함되지 않음

## 다른 리소스와의 관계

| 리소스 | 관계 |
|--------|------|
| `07-script-extraction.md` | 추출된 스크립트가 structured output 내면 여기의 annotation·Step Summary로 연결 |
| `01-workflow-basics.md` | job·step 네이밍 기본 |
| `06-security.md` | 민감값 마스킹·secrets 취급 |
| `04-advanced-patterns.md` | matrix / artifact / cache는 가시성의 기반 인프라 |
