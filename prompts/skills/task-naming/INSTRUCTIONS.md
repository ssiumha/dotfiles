# Task Naming Convention

Justfile/Makefile 명령어의 네이밍 규칙 적용 및 검증.

**범위**: Justfile, Makefile만. npm scripts, mise tasks는 대상 아님.

**핵심 철학**:
- 실수하기 어려워야 한다 — 규칙이 단순해야 예외에서 헤매지 않음
- 이름을 모르더라도 추측할 수 있어야 한다 — 패턴이 예측 가능하면 암기 불필요
- 한번 정한 이름은 영구적이다 — 스크립트에 박히므로 처음에 잘 정해야

**근거**: POSIX, clig.dev, 12 Factor CLI, AWS/gcloud CLI, DDD, The Poetics of CLI Names

## 7개 원칙

1. **실수하기 어려워야 한다** — 규칙 하나로 모든 판단이 가능. 예외 최소화
2. **그룹을 보고 기능이 예측 가능** — 그룹명에서 소속 명령어 3개+ 떠올릴 수 있어야. `misc`/`tool`/`util` 금지
3. **보이되 묻히지 않는다 (메뉴판 원칙)** — 2단계 기본, 최대 3단계. 그룹 당 3-7개. flat 덤프도 깊은 트리도 아님
4. **이름이 의도를 완성한다** — bare noun 금지 (`android` → `android-build`). 이름만 보면 행위가 드러나야
5. **모든 명령어는 설명을 갖는다** — 동사-시작 명령형, 80자 이내. `just --list`로 탐색 가능
6. **환경은 이름이 아닌 파라미터** — task runner는 항상 로컬 실행. `local-` 접두사 불필요. dev/prod는 argument로
7. **도구 관용을 따른다** — just/make는 hyphen `-`, mise/npm은 colon `:`

## 세부 규칙

### 어순: GAT (group-action-target)

```
[group] - [action] - [target/variant]
```

**명사 그룹** (서비스/인프라 도메인) — `group-action[-target]`:
```
api-run              group(api) + action(run)
api-check            group(api) + action(check)
docker-build-api     group(docker) + action(build) + target(api)
db-migrate ENV       group(db) + action(migrate) + arg(ENV)
```

**동사 그룹** (크로스서비스 행위에만) — `group-target[-variant]`:
```
deploy-api ENV       group(deploy) + target(api) + arg(ENV)
deploy-all ENV       group(deploy) + target(all)
build-android        group(build) + target(android)
test-unit            group(test) + target(unit)
```

동사 그룹 사용 조건: 같은 행위가 여러 서비스에 걸칠 때만.
서비스 고유 행위는 서비스 그룹에 넣는다.

### Justfile 그룹핑

`[group('name')]` 속성 사용 (just 1.x+):

```just
[group('db')]
# Run database migrations for target environment
db-migrate ENV:
    ...
```

### Description

```just
# Run database migrations for target environment
db-migrate ENV:
```

- 동사(imperative)로 시작: Run, Deploy, Build, Check, ...
- 80자 이내
- 마침표 없음
- argument가 있으면 값 범위 명시: `(dev|prod)` 또는 `for target environment`

### 축약어

팀 내 통용되면 허용. 프로젝트에서 처음 쓰는 축약어는 Justfile 상단에:
```just
# Abbreviations: be=backend, fe=frontend, stg=staging
```

### Private/Internal

`_` 접두사: `_aws-sso-login`, `_ensure-hook`

### 표준 동사

`resources/01-verb-vocabulary.md` 참조. 핵심 19개:
run, up, down, build, deploy, check, test, migrate, rollback, seed, list, status, log, init, setup, clean, reset, create, fmt

목록은 추천이지 제한이 아님. 단, 같은 행위에 다른 동사 혼용 금지:
- 시작: `run`(단일) / `up`(전체) — `start`, `serve` 사용 금지
- 중지: `down` — `stop`, `halt` 사용 금지

## Instructions

### 워크플로우 1: Audit

기존 Justfile/Makefile의 네이밍을 4 Phase로 검증한다.

1. **대상 파일 읽기**
   - Justfile 또는 Makefile을 Read
   - public 명령어 목록 추출

2. **Phase 1: 구조 체크**
   - [ ] (Justfile) 모든 public 명령어에 `[group('name')]` 속성이 있는가?
   - [ ] (Justfile) `just --list` 출력이 그룹별로 정리되는가?
   - [ ] (Makefile) 명령어가 prefix 기반으로 그룹핑되어 있는가? (`## Section` 주석 포함)
   - [ ] 그룹 당 3-7개 범위인가?
   - [ ] 그룹 수가 5-8개 이내인가?

3. **Phase 2: 네이밍 체크**
   - [ ] GAT 어순(group-action-target)을 따르는가?
   - [ ] bare noun 없는가? (동사 생략된 명령어)
   - [ ] 명사 그룹 내 action 위치가 일관적인가?
   - [ ] 동사 그룹이 크로스서비스 행위에만 사용되는가?

4. **Phase 3: Description 체크**
   - [ ] 모든 public 명령어에 `# description`이 있는가?
   - [ ] description이 동사(imperative)로 시작하는가?
   - [ ] 80자 이내인가?
   - [ ] ENV 등 argument의 값 범위가 description에 명시되어 있는가?

5. **Phase 4: 일관성 체크**
   - [ ] 같은 행위에 다른 동사를 사용하지 않는가? (run vs start vs serve)
   - [ ] 축약어가 프로젝트 내에서 일관적인가?
   - [ ] private 명령어가 `_` 접두사를 사용하는가?
   - [ ] 축약어 목록이 Justfile 상단에 명시되어 있는가? (해당 시)

6. **결과 출력**
   - Phase별 pass/fail 요약
   - 위반 항목마다 `current → suggested` 표

   출력 형식:
   ```
   ## Audit Report: {파일명}

   ### Phase 1: 구조 — {PASS|FAIL}
   - [x] 그룹 속성: 12/15 명령어에 있음 (3개 누락)
   - [ ] 그룹 당 크기: [docker] 그룹 9개 (초과)

   ### Phase 2: 네이밍 — {PASS|FAIL}
   | Current | Issue | Suggested |
   |---------|-------|-----------|
   | `android` | bare noun | `build-android` |
   | `fetch-api` | GAT 위반 | `api-fetch-spec` |

   ### Phase 3: Description — {PASS|FAIL}
   - 5/15 명령어에 description 누락

   ### Phase 4: 일관성 — {PASS|FAIL}
   - `run` vs `start` 혼용 발견
   ```

### 워크플로우 2: Create

새 명령어 이름을 결정한다.

1. **사용자 의도 파악**
   - "어떤 행위를 하고 싶은가?" 확인
   - 예: "DB rollback 명령 추가하고 싶어"

2. **기존 명령어 확인**
   - 같은 Justfile의 기존 명령어 목록 Read
   - 같은 도메인(그룹)의 기존 명령어 패턴 확인

3. **GAT 공식 적용**
   - **그룹 결정**: 기존 그룹에 속하는가? 새 그룹이 필요한가?
     - 기존 그룹 `[db]`에 `db-migrate`가 있으면 → 같은 그룹
   - **동사 선택**: `resources/01-verb-vocabulary.md` 참조
     - 기존 명령어와 같은 동사 패밀리 사용 (`migrate` 있으면 `rollback`)
   - **타겟/variant 결정**: 필요한 경우만

4. **제안 생성**
   ```just
   [group('db')]
   # Rollback last database migration for target environment
   db-rollback ENV:
       ...
   ```

5. **체크리스트 검증** (Phase 2-3 항목)
   - GAT 어순 맞는가?
   - description 동사-시작인가?
   - 같은 그룹 내 기존 명령어와 일관적인가?
   - 동사가 표준 목록에 있는가? (없으면 의미 명확한지 확인)

## 중요 원칙

1. **예측 가능성 > 간결함**: 이름이 길어도 추측 가능한 게 낫다
2. **그룹 내 일관성이 핵심**: 프로젝트 간보다 그룹 내 일관성이 중요
3. **동사 목록은 추천**: 의미가 명확하면 목록 밖 동사도 OK. 다만 같은 행위에 다른 동사 혼용은 금지

## Examples

### Audit
User: "/task-naming audit ~/pj/myapp/Justfile"
→ 워크플로우 1 → Phase 1-4 체크 → 위반 리포트 출력

### Create
User: "DB rollback 명령 추가하고 싶어"
→ 워크플로우 2 → 기존 `db-migrate` 확인 → `db-rollback ENV` 제안 + description + group 속성

### 암묵적 트리거
User: "Justfile에 docker 정리 명령어 추가해줘"
→ 워크플로우 2 → 기존 `[docker]` 그룹 확인 → `docker-clean` 제안
