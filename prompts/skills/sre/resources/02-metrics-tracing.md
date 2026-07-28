# L2 — 메트릭·트레이싱

판정 질문: **"장애를 로그를 뒤지기 전에 그래프로 먼저 알 수 있는가?"**

로그는 개별 사건, 메트릭은 추세, 트레이스는 경로다. 셋 중 메트릭이 없으면 "느려졌다"를 감지할 수단이 없다.

## Checks

### Critical

- **메트릭 노출 없음**: exporter도 엔드포인트도 없음. 요청량·에러율·지연을 아무도 모른다
- **다중 서비스인데 트레이싱이 없거나 컨텍스트가 끊김**: 서비스 A→B 호출에서 `traceparent`가 전파되지 않아 트레이스가 서비스마다 끊기거나, 애초에 트레이싱을 켜지 않음. **끊긴 것과 없는 것은 진단 능력 면에서 같다** — 요청이 어느 서비스에서 느려졌는지 알 방법이 없다

### High

- **Four Golden Signals 중 결손**: Google SRE가 규정하는 네 가지 — **Latency**("요청을 처리하는 데 걸린 시간"), **Traffic**("시스템에 가해지는 수요의 크기"), **Errors**("실패한 요청의 비율 — 명시적 5xx, 암묵적, 정책상 실패 모두"), **Saturation**("서비스가 얼마나 '차' 있는가 — 가장 제약된 리소스의 사용률")
  - **Latency는 성공 요청과 실패 요청을 분리해 재야 한다.** 빠르게 실패한 500이 지연 평균을 끌어내려 장애를 숨긴다
  - **Saturation이 가장 자주 빠진다.** Rate·Errors·Duration(RED)만 재면 "아직 안 터졌지만 곧 터진다"를 못 본다 — 큐 깊이·커넥션 풀 점유·디스크 여유가 그 자리다
- **USE 미수집** (인프라 계층이 저장소 관리 범위일 때): Utilization·Saturation·Errors. 컨테이너 CPU·메모리·큐 깊이
- **카디널리티 폭발 위험**: 라벨에 user_id·이메일·raw path·UUID가 들어감. 시계열이 무한 증식해 백엔드 비용과 쿼리 성능이 무너진다
- **샘플링 정책 부재**: 트레이싱을 100%로 켜두고 방치 — L6 비용으로 직결

### Medium

- **비즈니스 메트릭 부재**: 기술 지표만 있고 도메인 지표(주문 성공률·결제 실패)가 없어 "시스템은 정상인데 매출이 0"을 감지 못함
- **메트릭 이름 규약 없음**: 단위·접두사가 제각각이라 대시보드에서 조합 불가
- **헬스 엔드포인트와 메트릭 엔드포인트 혼용**: 헬스체크가 무거운 메트릭 수집을 유발

## Detection Patterns

```
# 계측 라이브러리 (L0 의존성 목록에서)
JVM     micrometer-core / micrometer-registry-prometheus / spring-boot-starter-actuator
Node    prom-client / @opentelemetry/{api,sdk-node,sdk-logs,api-logs,exporter-*}
        @opentelemetry/auto-instrumentations-node / @vercel/otel
Python  opentelemetry-sdk / prometheus-client
Go      go.opentelemetry.io/otel / prometheus/client_golang

# 프레임워크 계측 관례 (의존성 목록에 안 나타나는 경로)
Next.js   instrumentation.ts / src/instrumentation.ts  ← register() 훅
JVM       배포 설정의 -javaagent:opentelemetry-javaagent.jar + OTEL_* 환경변수
          ↑ pom.xml·build.gradle 에 나타나지 않는다. compose·k8s·배포 스크립트를 봐야 한다

# 노출 지점
Grep  "/metrics|/actuator/prometheus|/actuator/metrics" 라우트·설정
Grep  "OTEL_EXPORTER_OTLP_ENDPOINT|OTEL_SERVICE_NAME|OTEL_TRACES_" .env* compose*.y*ml

# collector 파이프라인 (L0에서 확보한 config)
receivers:  otlp / prometheus / hostmetrics
processors: batch / memory_limiter / tail_sampling / probabilistic_sampler
exporters:  백엔드

# 트레이스 전파
Grep  "traceparent|tracestate|b3|x-b3-" HTTP 클라이언트·미들웨어
Grep  "propagat" 설정

# OTel 스택이면 규약 점검을 병행 → 08-otel-conventions.md
service.name(Required) / deployment.environment.name / http.route 저카디널리티 /
구·신 semconv 혼재 / collector 파이프라인 등록 여부
```

## Grep Patterns

```
# 메트릭 등록 흔적
(Counter|Gauge|Histogram|Summary|Timer)\.(builder|build|new)
meterRegistry\.|metrics\.(counter|gauge|histogram)
new (Counter|Histogram|Gauge)\(

# Golden Signals 개별 확인 — auto-instrumentation 이 있으면 Latency·Traffic·Errors 는
#   충족으로 보고, Saturation 만 별도로 확인한다 (auto 계측은 보통 여기까지 안 온다)

## Saturation — "가장 제약된 리소스"가 무엇인지부터 찾고 그 지표를 본다
커넥션 풀   (pool|hikari|pgbouncer|datasource).*(active|idle|pending|wait|usage)
큐 깊이     (queue|backlog|lag).*(depth|size|length|messages|consumer_lag)
스레드·동시성  (thread|worker|executor).*(active|pool|queue|busy)
메모리·디스크  (jvm_memory_used|process_resident_memory|container_memory_usage|disk_free|filesystem_avail)
레이트리밋   (rate.?limit|throttle|semaphore|bulkhead|max.?concurren)
  ※ 경계(\b) 걸지 말 것 — 전부 스네이크·카멜 합성어다

## Errors — 성공/실패가 분리되어 있는가
(status|outcome|code|result|success)\s*[:=]      ← 지연 히스토그램에 결과 차원이 붙었는지
http_server_requests|http_request_duration        ← 이 지표에 status 라벨이 함께 있는지 확인
  실패 요청이 별도 차원 없이 같은 히스토그램에 섞여 있으면 "성공/실패 지연 미분리"

## Traffic — 요청 수 계열이 있는가
(requests?_total|_count$|throughput|rps|qps)

# 카디널리티 위험 라벨 — 경계(\b) 금지. sessionIdHash·orderUuid 같은 합성명을 놓친다
(label|tag|attribute)s?\s*[:=][^)\n]*(userId|user_id|email|uuid|sessionId|requestId|traceId)
\.tag\(\s*"(userId|user_id|email|uuid|sessionId)

# raw path가 라벨로 들어감 (경로 파라미터 미치환)
(route|path|uri)\s*[:=]\s*(req\.url|request\.path|ctx\.path)\b

# 샘플링 설정
Grep  "sampler|sampling|OTEL_TRACES_SAMPLER|probabilistic"

# 수동 계측이 전무한지
위 패턴 0건 + auto-instrumentation 의존성도 0건 → 메트릭 노출 없음
```

## 판정

등급은 INSTRUCTIONS의 **등급 산출 규칙**이 정한다. 여기서는 이 축에만 걸리는 예외를 정의한다.

| 상황 | 처리 |
|------|------|
| **단일 서비스 모놀리스**에서 트레이싱 부재 | Critical → **High로 하향**. 서비스 경계가 없으면 분산 트레이싱의 값이 작다.<br>판단 근거는 **L0가 확정한 애플리케이션 서비스 수** — 2 이상이면 다중이다. DB·캐시·프록시 컨테이너는 서비스로 세지 않는다 (앱 1 + postgres + redis = **단일**) |
| 계측 경로(의존성·설정·배포경로) 중 **일부**가 저장소 밖 | 그 항목만 `확인 필요`. 나머지로 축 판정 |
| 계측 경로가 **전부** 저장소 밖 (인프라 저장소 분리·PaaS) | **확정 Check가 0개일 때만** 축 `판정 보류`. 확정된 것이 있으면 그 최고 심각도로 등급을 매긴다 |
| Saturation 지표를 탐지 패턴으로 확인 불가 | 그 항목만 `확인 필요`. 인상으로 결함을 만들지 않는다 |

`requestId`는 문맥에 따라 의미가 반대다 — **메트릭 라벨**에 있으면 카디널리티 위험(감점), **에러 응답 바디**에 있으면 상관 ID(가점, L5). 문자열만으로는 구분되지 않으므로 매칭된 위치가 계측 코드인지 응답 직렬화 코드인지 반드시 확인한다.

## 제안 매핑

| 발견 | 제안 | 담당 |
|------|------|------|
| 메트릭 노출 없음 | auto-instrumentation 먼저(코드 변경 0) → 필요 시 수동 계측 추가 | `sre` |
| RED 누락 | HTTP 서버 미들웨어 계층에서 3지표를 한 번에 확보 | `sre` |
| 트레이스 단절 | 전파 헤더 확인 → HTTP 클라이언트에 propagator 주입 | `sre` |
| 카디널리티 위험 | 라벨에서 고유값 제거, 경로는 템플릿(`/user/:id`)으로 치환 | `sre` |
| 샘플링 미설정 | tail sampling 또는 확률 샘플링 도입 → L6 비용과 함께 판단 | `sre` |
| 비즈니스 메트릭 부재 | 도메인 이벤트에 카운터 추가 | `sre` |
| collector 리소스 설정 | compose resources·batch 크기 | `/devops` (docker) |

## 계측이 저장소에서 안 보일 때

**의존성 파일에 계측 라이브러리가 없다고 곧바로 FAIL로 판정하지 않는다.** 계측이 저장소 밖에 있는 경로가 흔하다. 라벨은 위 "판정" 표를 따른다 — **일부**가 밖이면 그 항목만 `확인 필요`, **전부**가 밖이면 축 `판정 보류`다.

| 경로 | 어디에 있나 | 확인 방법 |
|------|------------|----------|
| JVM 에이전트 | 배포 시 `-javaagent` 주입 + `OTEL_*` 환경변수 | 배포 설정이 저장소에 있으면 거기, 없으면 **확인 필요** |
| 사이드카 수집 | 컨테이너 옆 collector·vector가 파일·stdout tail | compose에 사이드카 서비스 존재 여부 |
| PaaS 자동 계측 | 플랫폼이 주입 | 인벤토리에서 PaaS 감지 시 확인 필요 |
| 인프라 저장소 분리 | collector 설정이 다른 저장소 | 이 저장소 범위임을 리포트에 명시 |

의존성·설정·배포경로 **셋 다** 확인하고도 계측 흔적이 0이면 그때 FAIL이다. 셋 중 하나라도 저장소 밖이면 "확인 필요"로 두고 사용자에게 묻는다.

## 주의

- auto-instrumentation을 켜는 것만으로 RED가 대부분 채워진다. 수동 계측부터 제안하지 않는다
- 카디널리티는 저장소 코드만으로 확정할 수 없다 — 위험 라벨의 존재까지가 정적 판정 범위이고, 실제 시계열 수는 "확인 필요"
- 메트릭 백엔드가 없는데 exporter만 설정된 경우가 있다. exporter 대상이 실재하는지 compose·설정에서 확인
