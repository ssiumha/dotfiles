---
name: 12FACTOR-APP
full_name: "The Twelve-Factor App"
category: architecture
origin: Adam Wiggins (Heroku), 2011, "The Twelve-Factor App". https://12factor.net
one_liner: "확장 가능하고 이식 가능한 SaaS를 위한 12개 패키지 — 코드베이스/의존성/설정/백킹서비스/빌드릴리즈런/프로세스/포트/동시성/Disposability/Dev-prod parity/로그/admin"
---

# 12FACTOR-APP — 클라우드 네이티브 12계명

## 정의

> "The twelve-factor app is a methodology for building software-as-a-service apps that... can scale up without significant changes to tooling, architecture, or development practices." — Adam Wiggins

12 Factor App은 **이식 가능하고 확장 가능한 SaaS**를 만들기 위한 12개 원칙. Heroku 엔지니어들이 수백 개 앱을 운영하며 정리한 패턴이며, 현대 cloud-native·containerized 시스템 설계의 기준이 되었다.

핵심 가치:
- **선언적 자동화** — 신규 개발자가 바로 합류 가능
- **OS 독립성** — 환경 간 이동 자유
- **클라우드 배포 적합** — 수동 설정 최소화
- **dev/prod 차이 최소** — 지속 배포 가능
- **수평 확장 가능** — 도구·아키텍처 큰 변경 없이

12개는 패키지로 의미 — 부분 적용은 부분 효과.

## 12 Factor

### I. Codebase — 단일 코드베이스, 다중 배포

> "One codebase tracked in revision control, many deploys."

- 한 앱 = 한 저장소 (git)
- 여러 배포(dev/staging/prod)가 같은 저장소를 공유
- 다중 앱이 한 저장소에 있으면 → 분리 (모노레포는 별 이야기)
- 공유 코드는 라이브러리로 추출, 의존성으로 가져옴

**위반 신호:** 같은 코드가 두 저장소에 fork되어 있음, 환경별 별도 브랜치를 영구 유지.

### II. Dependencies — 명시적 선언과 격리

- 시스템에 깔린 도구 가정 금지 (`curl`/`gcc` 의존 X)
- **Dependency manifest** 명시 (`package.json`, `requirements.txt`, `Gemfile`, `go.mod`)
- **격리 도구** 사용 (`venv`, `bundler`, `node_modules`)
- 새 개발자가 만든 빌드/실행 환경이 동일 결과를 내야

**위반 신호:** README에 "먼저 brew로 X 깔아주세요" 무더기, lock 파일 없음.

### III. Config — 환경에 저장

- **환경별로 바뀌는 모든 것**은 환경변수로
- DB 자격증명, API 키, 서비스 호스트, 기능 플래그
- 코드와 설정의 **엄격한 분리** — "이 코드를 지금 오픈소스로 풀어도 비밀이 안 새는가?"
- 그룹화된 config 파일(`config/dev.yml`)도 안 좋음 — 환경 추가 시 폭증

**예외:** 빌드시 이미 하드코딩된 설정(번역 파일, 라우팅) — 환경별로 안 바뀜.

**위반 신호:** `if env == "production":` 분기, `.env` 파일 git 커밋, 코드에 하드코딩된 키.

### IV. Backing Services — 첨부된 리소스로 취급

- DB, 큐, SMTP, 캐시 = **외부에서 첨부되는 리소스**
- URL/자격증명을 환경변수로 주입
- 로컬 SQLite든 RDS든 같은 인터페이스로 접근
- DB를 "다른 인스턴스로 교체"가 코드 변경 없이 config만으로 가능해야

**위반 신호:** 코드에 `localhost:5432` 하드코딩되어 있음, prod DB 연결 정보가 코드에.

### V. Build, Release, Run — 엄격히 분리

세 단계의 명확한 구분:

```
build (코드 + 의존성 → 실행 가능 패키지)
  └─ release (빌드 + config → 배포 단위, 고유 ID)
       └─ run (release를 실행 환경에서 launch)
```

- 각 release는 immutable, 고유 ID
- 운영 중 코드 직접 수정 금지 (변경은 새 release)
- rollback = 이전 release ID로 복귀

**위반 신호:** 운영 서버에서 직접 코드 수정, "hotfix 직접 적용", build 단계 없이 prod에서 컴파일.

### VI. Processes — 무상태 프로세스

- 앱은 하나 이상의 **stateless** 프로세스로 실행
- **공유 상태 = backing service** (DB, Redis, S3)
- 프로세스 메모리/디스크는 **trustless** — 언제든 사라질 수 있음
- "sticky session"은 안티패턴 (특정 프로세스에 묶이는 세션) — Redis 같은 공유 저장소로

**위반 신호:** 로컬 디스크에 업로드 파일 저장, in-memory 세션 캐시, 로컬 임시파일에 의존.

### VII. Port Binding — 포트로 export

- 앱 자체가 HTTP 서버를 **내장** (Apache/Nginx 같은 웹 서버 컨테이너에 의존 X)
- 포트로 listen, 환경에서 라우팅
- 한 앱이 다른 앱의 backing service가 될 수도 있음 (서비스 URL = 환경변수)

**위반 신호:** mod_php·Tomcat·IIS 같은 외부 컨테이너 필수, 포트 하드코딩.

### VIII. Concurrency — 프로세스 모델로 확장

- 프로세스를 **first-class citizen**으로 (Unix 데몬 모델)
- 워크로드 종류별로 프로세스 타입 분리 (web / worker / scheduler)
- **수평 확장 = 프로세스 추가**, 수직 확장(스레드/메모리)은 보조

```
Procfile:
  web: node server.js
  worker: node worker.js
  scheduler: node scheduler.js
```

**위반 신호:** 모든 워크로드가 한 거대한 프로세스 안, daemonize·PID 관리 직접 (OS process manager에 위임해야).

### IX. Disposability — 빠른 시작과 우아한 종료

- **빠른 startup**: 몇 초 이내 — 신속한 deploy/scale 가능
- **우아한 shutdown**: SIGTERM 받으면 새 요청 거부 + 현재 요청 마무리 + 종료
- worker는 작업을 큐로 반환 (재시도 안전)
- **돌발 종료 견뎌야** — crash-only 설계, robust queueing

**위반 신호:** 시작 30초+, SIGTERM 무시 후 SIGKILL 필요, 종료 시 데이터 손실.

### X. Dev/Prod Parity — 환경 격차 최소

격차 3종류를 줄인다:

| 격차 | 전통 | 12 Factor |
|------|------|-----------|
| 시간 | 코드 작성 → 배포 몇 주 | 시간 단위 |
| 인력 | 개발자/운영자 분리 | 개발자가 배포에 관여 |
| 도구 | dev=SQLite, prod=Postgres | dev/prod 동일 backing service |

- 컨테이너/Vagrant로 prod와 동일한 backing service를 dev에서 실행
- "비슷한 것"이 아니라 **같은 것** (Postgres 9 vs Postgres 14는 비슷한 게 아님)

**위반 신호:** dev는 SQLite + prod는 Postgres, dev에서 작동했지만 prod에서만 깨지는 의존성 차이.

### XI. Logs — 이벤트 스트림

- 앱은 stdout으로 **줄 단위 이벤트 stream** 출력만
- 로그 파일 관리/회전/저장은 **앱이 절대 안 함**
- 실행 환경(systemd, docker, kubernetes)이 stream을 수집·라우팅
- 개발: 터미널에서 그대로 봄
- 운영: Splunk/ELK/Datadog 같은 indexed system으로 라우팅

**위반 신호:** 앱 코드 안에 로그 파일 경로·rotation 로직, 로그를 DB에 직접 INSERT.

### XII. Admin Processes — 일회성 관리 작업

- 마이그레이션·콘솔·일회성 스크립트는 **같은 코드베이스 + 같은 release**에서 실행
- prod에서 임시로 다른 코드 돌리지 않는다
- REPL/console도 같은 환경에 attach

```
heroku run rails console        # 같은 release, 같은 env
heroku run python manage.py migrate
```

**위반 신호:** prod 마이그레이션을 로컬에서 직접 실행, admin task만 다른 저장소.

## 핵심 판단

| # | 체크 |
|---|------|
| I | 한 앱 = 한 저장소? |
| II | 의존성 manifest + lock + 격리? |
| III | 환경별 config가 환경변수로? 코드 분리? |
| IV | DB/큐 등이 URL로 첨부? 교체 가능? |
| V | build → release(ID) → run 분리? immutable? |
| VI | 프로세스 무상태? 공유 상태가 backing service? |
| VII | HTTP 서버 내장? 포트 binding? |
| VIII | 워크로드별 프로세스 타입? 수평 확장? |
| IX | 빠른 시작 + SIGTERM graceful? |
| X | dev/prod 동일 backing service + 짧은 deploy 사이클? |
| XI | stdout으로 로그 stream? |
| XII | admin task가 같은 release? |

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| 의존성 lock 부재 | 저장소에 `*.lock` 파일 없음 |
| `.env` 커밋 | `git ls-files \| grep '\.env$'` |
| 코드에 자격증명 | `grep -r 'password.*='` (시크릿 스캔) |
| 로컬 디스크 의존 | 코드에 `/tmp/upload`, `local_cache/` 경로 |
| 시작 30초+ | `time docker run myapp` |
| 로그 파일 직접 작성 | `open(file, 'a')` 로 로그 |

### 판단 필요

| 신호 | 설명 |
|------|------|
| "prod에서 직접 고쳤어" | V·X 위반 — release 개념 부재 |
| "재시작하면 데이터 사라짐" | VI 위반 — 상태가 프로세스 안 |
| "dev에선 됐는데 prod에선 안 됨" | X 위반 — parity 부족 |
| "로그가 어디 있는지 모르겠음" | XI 위반 — 앱이 직접 관리 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 12개 중 10개 이상 충족 |
| **WARN** | 7-9개, 누락이 III·IV·VI 같은 핵심 아닌 항목 |
| **FAIL** | 6개 이하 또는 III(config 분리)·IV(backing service)·VI(stateless) 중 하나 위반 |

## 설계 패턴

### Procfile + 프로세스 타입

```
# Procfile
web: gunicorn app:app
worker: celery -A app worker
scheduler: celery -A app beat
release: python manage.py migrate
```

`release` phase는 `run` 직전 실행 — 마이그레이션을 매 배포마다 자동.

### 환경변수 계층

```python
# 12 Factor 호환
import os

DATABASE_URL = os.environ["DATABASE_URL"]    # 필수, 없으면 죽음 (fail-fast)
DEBUG = os.environ.get("DEBUG", "0") == "1"  # 선택, 기본값
```

`DATABASE_URL`은 단일 문자열에 host/port/user/pass/db 모두 포함:
```
postgres://user:pass@host:5432/dbname
```

### Stateless 검증

```bash
# 프로세스를 임의로 죽이고 재시작 — 사용자에게 영향 없어야
chaos-monkey --kill-random-instance
```

운영 중 프로세스 교체가 사용자에 보이면 VI 위반.

### Logs as event streams

```python
# ❌ 12 Factor 위반
logging.basicConfig(filename='/var/log/myapp.log', ...)

# ✅
logging.basicConfig(stream=sys.stdout, format='%(asctime)s %(levelname)s %(message)s')
```

### Build → Release → Run

```
$ git push prod main             # build 트리거
$ heroku releases                # release 목록 (각각 immutable ID)
$ heroku rollback v42            # 이전 release로 복귀 (코드 변경 없음)
```

## 클라우드 네이티브와의 관계

12 Factor App은 2011년 Heroku에서 나왔지만, 2020년대 Kubernetes/Docker 시대에 더 강력해졌다:

| 12 Factor | Kubernetes / Docker 매핑 |
|-----------|--------------------------|
| I Codebase | Container image registry |
| II Dependencies | Dockerfile + 멀티스테이지 빌드 |
| III Config | ConfigMap + Secret + 환경변수 |
| IV Backing Services | Service abstractions, External Service |
| V Build/Release/Run | Image build → tag → deploy |
| VI Processes | Stateless Deployment |
| VII Port Binding | Service port + Ingress |
| VIII Concurrency | Replicas + Pod scaling |
| IX Disposability | livenessProbe + terminationGracePeriodSeconds |
| X Dev/Prod Parity | 같은 image를 환경 간 promote |
| XI Logs | stdout → kubectl logs / Fluentd |
| XII Admin | Job / kubectl exec |

12 Factor는 Kubernetes의 사실상의 설계 가정이다.

## 주의

### "Beyond 12 Factor"

Kevin Hoffman의 *Beyond the Twelve-Factor App* (2016)은 3개 추가:
- **API First** — API 설계가 코드보다 먼저
- **Telemetry** — 메트릭·트레이스 수집
- **Authentication and authorization** — 보안은 처음부터

본 카탈로그는 12개로 유지하되, 이 3개는 별도 원칙으로 다룸 (API-FIRST, TELEMETRY, SECURITY-BY-DESIGN — 필요 시 추가).

### 모든 앱이 12 Factor일 필요 없다

- **데스크톱 앱·CLI 도구** — 12 Factor 적용 의미 작음 (CLI는 12FACTOR-CLI)
- **Stateful 시스템** (DB, message broker 자체) — VI(stateless)와 정면 충돌. 그게 본질
- **Edge function·Lambda** — VII(port binding)·VIII(concurrency) 의미가 다름

12 Factor는 **장기 실행 SaaS 백엔드**의 표준이다. 모든 시스템에 적용하려 들면 GOODHARTS-LAW.

### 12FACTOR-CLI와 다름

- 12FACTOR-APP: 서버/SaaS 배포 (이 원칙)
- 12FACTOR-CLI: 명령줄 도구 UX (별도 원칙)

같은 형식·같은 숫자, 내용은 별개.

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| SSoT | III(config) — 환경별 진실은 환경변수 단일 출처 |
| IDEMPOTENCY | IX(disposability) — 재시작·재실행 안전 |
| FAIL-FAST | III·IX — 필수 환경변수 없으면 즉시 죽음 |
| CONWAYS-LAW | XII(admin) — admin task 분리는 조직 분리와 짝 |
| STRANGLER-FIG | 레거시를 12 Factor로 점진적으로 이행할 때 사용 |
| SoC | I·V·VIII — 코드/설정/빌드/실행/워크로드 모두 분리 |
| COHESION-COUPLING | IV — backing service 결합도 낮춤 |
| LEAKY-ABSTRACTION | VI(stateless)에서 로컬 디스크 의존이 새는 추상화 |

## 참고

- 원전: https://12factor.net
- 보강: Kevin Hoffman *Beyond the Twelve-Factor App* (2016)
- 매핑: https://kubernetes.io/docs/concepts/ (12 factor가 K8s 설계 가정)
