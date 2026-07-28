# L0 — 인벤토리

이후 모든 축이 **무엇을 검사할지 고르는 전제**. 여기서 틀리면 이후 판정이 전부 틀린다.

판정하지 않는다 — 감지만 한다. PASS/WARN/FAIL 없음.

## 감지 절차

### 1. 스택

```
Glob  package.json  pyproject.toml  build.gradle*  pom.xml  go.mod  Cargo.toml  Gemfile
```

| 파일 | 스택 | 이후 축에서 쓰는 정보 |
|------|------|----------------------|
| `package.json` | Node/TS | 로깅 라이브러리, OTel SDK, 프레임워크(next·express·nest) |
| `build.gradle*` / `pom.xml` | JVM | logback, micrometer, spring-boot-actuator |
| `pyproject.toml` | Python | structlog·loguru, opentelemetry-* |
| `go.mod` | Go | zap·zerolog, otel-go |

의존성 목록을 그대로 읽어둔다 — L1·L2가 이 목록으로 판정한다.

### 2. 런타임·오케스트레이션

```
Glob  Dockerfile*  compose*.y*ml  docker-compose*.y*ml
Glob  k8s/**/*.y*ml  manifests/**/*.y*ml  chart/**  helmfile*
Glob  Procfile  fly.toml  vercel.json  netlify.toml
```

**애플리케이션 서비스 수를 여기서 확정한다.** 이 저장소가 **직접 빌드·배포하는 자체 서비스만** 센다 — DB·캐시·메시지 브로커·collector·리버스 프록시처럼 기성 이미지를 그대로 쓰는 컨테이너는 제외한다. 판별 기준: `build:` 지시가 있거나 이미지가 이 저장소의 산출물인가.

이 값이 두 축의 입력이다 — **L2의 다중 서비스 판정**(2 이상이면 다중 → 트레이싱 부재가 Critical)과 **L6 리소스 제한의 분모**. 여기서 틀리면 두 축의 등급이 함께 틀린다.

```
# compose 의 서비스 키만 (volumes·networks 의 자식 키가 섞이지 않게)
yq -r '.services | keys[]' compose.yaml          ← yq 가 있으면 이것이 가장 정확
# yq 가 없으면 services: 블록만 잘라서
awk '/^services:/{f=1;next} /^[a-zA-Z]/{f=0} f && /^  [a-zA-Z0-9_-]+:$/{print}' compose.yaml
```

그중 `build:`를 가진 것 = 애플리케이션 서비스. 나머지는 기성 컨테이너다.

| 감지 | 배포 단위 | L4에서 검사할 것 |
|------|-----------|-----------------|
| compose | 컨테이너(단일 호스트) | `healthcheck`, `restart`, 이미지 태그, `depends_on` |
| k8s/helm | 파드 | readiness/liveness probe, rollout 전략, resource requests |
| PaaS (vercel·fly) | 플랫폼 관리 | 플랫폼 기본값 확인 필요 → 판정 보류 |
| 없음 | 미상 | "배포 단위 확인 필요"로 기록 |

### 3. 관측 스택

```
Glob  **/otel*.y*ml  **/otelcol*.y*ml  **/collector*.y*ml
Glob  **/prometheus*.y*ml  **/alertmanager*.y*ml  **/grafana/**
Grep  "signoz|jaeger|tempo|loki|datadog|sentry|new relic|elastic" -i (compose·설정 파일)
```

| 감지 | 의미 |
|------|------|
| otel collector config | 수집 파이프라인 존재 → L1·L2가 receivers/processors/exporters를 읽어 경로 추적 |
| SigNoz·Grafana·Datadog 등 | 백엔드 존재 → L3 알림 규칙 위치 후보 |
| Sentry만 | 에러 추적만 있고 메트릭·트레이싱은 별개 → L2에서 구분 |
| 없음 | L1·L2가 "수집 경로 없음" 판정의 근거 |

### 4. 배포 경로

```
Glob  .github/workflows/*.y*ml  .gitlab-ci.yml  Justfile  justfile  Makefile
Glob  deploy*.sh  scripts/deploy*  ansible/**
```

CI가 배포까지 하는지, 배포가 수동 스크립트인지 구분한다 — L4의 롤백 경로 검사가 여기에 걸린다.

### 5. 리버스 프록시·엣지

```
Glob  Caddyfile  **/nginx*.conf  **/traefik*.y*ml
```

접근 로그가 여기서 나오는 경우가 많다. L1의 수집 경로 이중화 판정에 필요하다.

### 6. 데이터 계층

```
Glob  **/migrations/**  prisma/schema.prisma  **/db/migrate/**  alembic.ini  **/flyway*
Grep  "postgres|mysql|mongo|redis|clickhouse" -i (compose·설정)
```

L4의 마이그레이션 안전성, L5의 백업 검사 대상이 된다.

## 출력

감지 결과를 표 하나로 사용자에게 제시하고 진행한다.

```markdown
### 인벤토리

| 항목 | 감지 결과 |
|------|----------|
| 스택 | TypeScript (Next.js 15, Prisma) |
| 배포 단위 | compose (compose.yaml, 서비스 4개) |
| 관측 스택 | OTel collector → SigNoz |
| 배포 경로 | Justfile `deploy` → 수동 실행 |
| 엣지 | Caddy (Caddyfile) |
| 데이터 | PostgreSQL, Prisma migrations 23개 |
| 미감지 | k8s 없음, alertmanager 없음 |
```

**미감지 항목을 반드시 적는다** — 이후 축에서 "없음"을 판정 근거로 쓰기 때문에, 무엇을 찾다가 못 찾았는지가 기록되어야 한다.

## 감지 실패 시

| 상황 | 처리 |
|------|------|
| 모노레포라 스택이 여러 개 | 워크스페이스별로 인벤토리를 나누고, 축 진단도 워크스페이스 단위로 |
| 배포 설정이 저장소 밖 | "배포 설정 저장소 외부 — L4 판정 보류"로 기록 |
| 인프라 저장소가 분리됨 | 이 저장소 범위만 판정하고 리포트에 명시 |
