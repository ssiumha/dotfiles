# L4 — 배포 안전성

판정 질문: **"배포가 잘못됐을 때 되돌릴 수 있는가?"**

배포를 자동화했는지가 아니라, **되돌리는 경로가 있는지**가 이 축의 핵심이다. 자동 배포는 잘못된 것을 더 빨리 퍼뜨리는 도구이기도 하다.

## Checks

### Critical

- **롤백 경로 없음**: 이전 버전으로 되돌리는 절차가 코드에도 문서에도 없음. 장애 시 유일한 선택지가 "고쳐서 다시 배포"가 된다
- **비가역 마이그레이션이 배포와 원자적으로 묶임**: 컬럼 drop·타입 변경이 앱 배포와 같은 단계에서 실행되어, 앱만 롤백해도 스키마가 안 맞는다
- **배포 전 검증이 배포를 막지 못함**: CI가 테스트를 돌리지 않거나, 실패해도 배포가 진행됨(`continue-on-error: true`, deploy job에 `needs:` 없음). 깨진 코드가 그대로 나간다
- **프로덕션 배포 산출물 버전 미고정**: 이미지 태그가 `:latest`이거나 **태그가 아예 없다**(`image: nginx` = 암묵적 latest). 무엇이 돌고 있는지 확정할 수 없고, 롤백 대상도 특정할 수 없다
  - **스코프를 반드시 확인한다** — `compose.override.y*ml`·dev 전용 파일의 `:latest`는 결함이 아니다. 프로덕션 경로(기본 `compose.yaml`, `*.prod.*`, 배포 스크립트가 지정하는 파일)에 있을 때만 Critical

### High

- **헬스체크 없음**: 컨테이너가 떠 있지만 응답 불가한 상태를 아무도 모름. 오케스트레이터가 교체·재시작 판단을 못 한다
- **readiness와 liveness 미구분** (k8s): 시작 중인 파드로 트래픽이 들어가거나, 일시적 지연에 파드가 계속 죽는다
- **무중단 전략 없음**: 배포 중 다운타임 발생. compose에서 `down` → `up` 순서로 도는 스크립트가 대표적
- **의존 순서 미정의**: `depends_on`에 조건이 없어 DB가 준비되기 전에 앱이 뜬다
- **롤백 경로가 문서 서술뿐**: 실행 가능한 명령·스크립트가 아니라 산문으로만 존재. 장애 중에 해석이 필요하다

### Medium

- **배포 후 스모크 체크 없음**: 배포 성공 = 컨테이너 기동으로만 판단
- **DORA 지표가 나쁜 쪽으로 치우침**: 아래 근사 측정 결과 배포 빈도가 낮으면서 변경 실패율이 높음 — 배치가 크다는 신호
- **마이그레이션 재실행 안전성 불명**: 같은 마이그레이션이 두 번 돌면 깨지는 구조 (`IDEMPOTENCY`)
- **환경별 설정이 분리되지 않음**: 같은 compose로 dev·prod를 돌려 실수 여지가 큼
- **배포 이력 추적 불가**: 무엇이 언제 나갔는지 기록이 없음

## Detection Patterns

```
# 배포 경로 (L0에서 확보)
Glob  .github/workflows/*deploy*  Justfile  Makefile  deploy*.sh  scripts/deploy*

# 롤백 흔적
Grep  "rollback|롤백|revert|previous|prev_tag|--rollback" 배포 스크립트·workflow
Grep  "helm rollback|kubectl rollout undo|docker compose .*:(previous|prev)"

# 헬스체크
compose:  healthcheck:  test:  interval:  start_period:
k8s:      readinessProbe:  livenessProbe:  startupProbe:
Grep      "/health|/healthz|/ready|/actuator/health" 라우트

# 이미지 태그 고정 — 프로덕션 경로 파일에 한정해서 검사한다
Grep  "image:\s*\S+:latest"           ← 명시적 latest
Grep  "image:\s*[^\s:]+\s*$"          ← 태그 없음 = 암묵적 latest (더 흔하고 더 위험)
Grep  "image:\s*\S+@sha256:"          ← 가장 강한 고정
Grep  "image:\s*\S+:v?[0-9]"          ← 버전 태그

# 의존 순서
Grep  "depends_on:" → 하위에 "condition: service_healthy" 존재 여부

# 마이그레이션
Glob  **/migrations/**  prisma/migrations/**  **/db/migrate/**  **/flyway/**
Grep  "DROP COLUMN|DROP TABLE|ALTER COLUMN .* TYPE|RENAME COLUMN"  ← 비가역 후보
Glob  **/down.sql  **/*_down.*                                     ← 되돌림 스크립트

# 배포 전 검증 — 세 가지를 순서대로 확인한다
1) 배포 잡 식별      rg -n 'jobs:|^\s{2}\w+:' .github/workflows/*deploy*  로 잡 이름 목록화
2) 의존 그래프       rg -U -n 'needs:\s*(\[[^\]]*\]|(\s*-\s*\S+)+)' .github/workflows/
                     → deploy 잡의 needs 목록을 얻고 그 잡들의 needs 를 **재귀로** 따라가
                       테스트 잡에 도달하는지 본다. `deploy → build → test` 전이 의존이 흔하므로
                       1홉만 보고 확정하지 않는다
                     0건이어도 워크플로 파일을 열어 확인한다 — **0건 자체는 Critical 근거가 아니다**
3) 무력화 설정       rg -n 'continue-on-error:\s*true|if:\s*always\(\)' .github/workflows/
Justfile 배포라면    rg -n '^deploy' -A 5 justfile  로 test 호출이 선행하는지 확인
```

## Grep Patterns

```
# 다운타임 유발 배포 순서 — -U 필수 (배포 스크립트는 여러 줄이다)
rg -U '(docker compose|docker-compose)\s+down[\s\S]{0,200}(up|start)'
rg -U 'kubectl delete[\s\S]{0,200}kubectl apply'

# 볼륨 삭제를 동반한 재기동
(docker compose|docker-compose)\s+down\s+(-v|--volumes)

# 마이그레이션이 앱 기동과 한 명령에 묶임
(migrate|migration).*(&&|;).*(start|serve|up)
command:.*migrate.*&&

# 헬스체크 부재 확인 (compose에 services는 있는데 healthcheck 0건)
services: 블록 수  vs  healthcheck: 출현 수

# 환경 분리
Glob  compose.override.y*ml  compose.prod.y*ml  .env.production
```

## 판정

등급은 INSTRUCTIONS의 **등급 산출 규칙**이 정한다. 여기서는 이 축에만 걸리는 예외를 정의한다.

| 상황 | 처리 |
|------|------|
| 배포 설정이 저장소 외부 (PaaS·별도 인프라 저장소) | **확정 Check가 0개일 때만** 축 `판정 보류`. 마이그레이션·이미지 태그처럼 저장소 안에서 확정된 Critical이 있으면 그것으로 등급을 매긴다 |
| 롤백 grep이 히트 (`rollback`·`revert`·`previous`) | 문서의 `git revert` 설명이나 변수명일 수 있다. 매칭 위치가 **실행 가능한 배포 롤백 경로**인지 확인한 것만 확정 |
| 롤백이 존재하나 문서 서술뿐 | Critical → **High로 하향**. 경로는 있으나 장애 중에 해석이 필요하다 |
| 태그·릴리스 관행이 없어 DORA 지표 산출 불가 | 지표를 `확인 필요`로 두고, **"배포 이력 추적 불가"(Medium) Check를 확정**한다 — 라벨과 Check를 혼동하지 않는다 |

## 제안 매핑

| 발견 | 제안 | 담당 |
|------|------|------|
| 롤백 경로 없음 | 이전 태그로 되돌리는 명령을 `just rollback`으로 고정 — 장애 중에 절차를 찾지 않게 | `sre` → `/devops` (ci-cd) |
| `:latest` | 커밋 SHA 또는 semver 태그로 고정 | `/devops` (docker) |
| 헬스체크 없음 | compose `healthcheck` + `depends_on: condition: service_healthy` | `/devops` (docker) |
| 비가역 마이그레이션 | **확장 → 배포 → 수축** 순서로 분리. 컬럼 추가 후 배포, 이전 버전이 사라진 뒤 제거 | `sre` |
| 배포 전 검증 없음 | test job을 deploy의 `needs:`로 연결 | `/devops` (github-action) |
| 다운타임 배포 순서 | `up -d --no-deps --build <svc>` 방식 또는 rolling 전략 | `/devops` (docker) |
| 마이그레이션 비멱등 | 재실행 안전성 확보 — `/principles check IDEMPOTENCY` | `/principles` |
| terraform 리소스 교체 위험 | lifecycle·prevent_destroy | `/terraform` |

## DORA 4 지표 — git 이력으로 근사 측정

배포 안전성은 설정 유무뿐 아니라 **실제 배포 습관**으로 드러난다. 저장소 이력만으로 네 지표를 근사할 수 있다. 정밀한 값이 아니라 **자릿수**를 본다.

| 지표 | 정의 | 저장소 근사 |
|------|------|-------------|
| 배포 빈도 | 프로덕션에 얼마나 자주 내보내는가 | 배포 태그·릴리스 간격, 또는 배포 브랜치 머지 간격 — `git log --tags --simplify-by-decoration --date=short --pretty='%ad %d'` |
| 리드 타임 | 코드 변경이 운영에 닿기까지 | `git log -n 50 --pretty='%H %aI'` → 각 커밋에 `git describe --contains <sha>`로 포함 태그를 찾고, 태그 커밋 시각(`git log -1 --format=%cI <tag>`)과의 차이 |
| 변경 실패율 | 장애·롤백을 유발한 변경의 비율 | `git log --oneline -n 200 -i --grep='revert\|hotfix\|rollback' \| wc -l` ÷ 같은 구간 전체 커밋 수 |
| 실패 배포 복구 시간 | 나쁜 배포에서 정상으로 돌아가는 데 걸린 시간 | revert 커밋 본문의 `This reverts commit <sha>`에서 원본 SHA 추출 → 두 커밋의 committer 시각 차이 |

읽는 법:

- **배포 빈도가 낮고 변경 실패율이 높으면** 배치가 크다는 신호다 → Medium Check "DORA 지표 치우침" 확정. 처방(배치 축소·파이프라인 단축)은 `/devops` (ci-cd)로 넘긴다
- **배포 빈도만 높고 롤백 경로가 없으면** 빠르게 잘못 배포하는 상태다. 등급을 임의로 올리지 않고, 이미 Critical인 "롤백 경로 없음"을 **다음 단계 1순위**로 배치하는 근거로 쓴다
- 자동 배포가 없는 저장소에서 배포 빈도는 측정 불가다 → `확인 필요`

정확한 값은 배포 시스템에만 있으므로 **저장소 근사임을 리포트에 명시한다.** 태그·릴리스 관행이 없으면 이 지표 전체가 `확인 필요`다 — 그 자체가 "배포 이력 추적 불가"(Medium)의 근거가 된다.

## 확장 → 배포 → 수축 (비가역 마이그레이션 분리)

제안 시 이 순서를 함께 제시한다.

```
1. 확장  새 컬럼 추가 (nullable), 이전 코드가 계속 동작
2. 배포  새 코드가 양쪽 컬럼을 읽고 새 컬럼에 씀
3. 백필  기존 행 이관
4. 배포  새 코드가 새 컬럼만 사용
5. 수축  이전 컬럼 제거 — 롤백 대상 버전이 모두 사라진 뒤
```

각 단계 사이에 롤백 가능 지점이 있다. 1~5를 한 배포에 넣으면 그 지점이 사라진다.

## 주의

- 롤백 "가능성"과 "검증"은 다르다. 저장소로 확인할 수 있는 것은 **경로의 존재**까지이므로, 실제로 롤백해본 적이 있는지는 판정하지 않는다. 다만 롤백이 **실행 가능한 명령**(`just rollback`·스크립트)인지 **문서 서술**인지는 구분한다 — 후자는 장애 중에 해석이 필요해 WARN이다
- PaaS는 플랫폼이 롤백을 제공하는 경우가 많다. 인벤토리에서 PaaS가 감지되면 플랫폼 기능 확인 후 판정
- 운영 성격에 따른 심각도 조정은 INSTRUCTIONS의 **심각도 기준선**이 단일 정의다 — 여기서 따로 정하지 않는다
