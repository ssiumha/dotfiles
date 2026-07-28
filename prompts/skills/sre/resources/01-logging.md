# L1 — 로깅

판정 질문: **"장애가 났을 때 원인을 로그로 찾을 수 있는가?"**

## Checks

### Critical

- **수집 경로 없음**: 로그가 stdout으로만 나가고 어디에도 모이지 않음. 컨테이너 재시작·스케일아웃 시 소실. 배포 후 과거 로그를 볼 방법이 없다
- **구조화되지 않음**: 문자열 결합으로 로그를 만들어 필드 검색·집계가 불가능. `"user " + id + " failed: " + e`는 grep은 되지만 "특정 사용자의 실패율"을 낼 수 없다
- **시크릿·PII 노출**: 토큰·비밀번호·주민번호·카드번호가 로그에 그대로. 로그 저장소는 보통 애플리케이션보다 접근 통제가 느슨하다

### High

- **상관 ID 전파 없음**: trace/request id가 없어 한 요청의 로그를 서비스 경계 너머로 이어붙일 수 없다. 마이크로서비스·비동기 처리에서 치명적
- **수집 경로 이중화**: 같은 로그가 두 경로로 흐르고 한쪽이 dedupe 필터에 버려지는 구조. 필터를 지우면 중복, 발신자를 지우면 전멸 — 어느 쪽이 진실인지 불명확해진다 (`SSoT` 위반)
- **로그 레벨 체계 부재**: 전부 `info` 또는 전부 `error`. 레벨로 필터링이 안 되면 노이즈에 묻힌다
- **예외에 스택트레이스 없음**: `catch (e) { log.error(e.message) }` — 발생 위치를 잃는다

### Medium

- **환경별 레벨 분리 없음**: prod에서 debug가 켜져 있거나, dev에서 error만 나옴
- **로그에 컨텍스트 부재**: 어떤 요청·사용자·리소스에 대한 것인지 필드가 없음
- **`console.log` / `println` 직접 사용**: 로깅 파사드를 우회해 레벨·포맷·수집이 적용되지 않음

## Detection Patterns

```
# 로깅 라이브러리 존재 여부 (L0 의존성 목록에서)
Node    pino / winston / bunyan / @opentelemetry/api-logs
JVM     logback-classic / log4j2 / slf4j + net.logstash.logback
Python  structlog / loguru / python-json-logger
Go      zap / zerolog / slog

# 설정 파일
Glob  **/logback*.xml  **/log4j2*.xml  **/logging*.y*ml
Glob  **/pino*.{ts,js}  **/logger.{ts,js,py,go,kt,java}

# 구조화 여부 — JSON encoder가 걸려 있는가
Grep  "JsonEncoder|LogstashEncoder|json.*format|pino\(" 설정 파일

# 상관 ID
JVM     MDC / StructuredArguments / traceId
Node    AsyncLocalStorage / cls-hooked / requestId 미들웨어
공통    traceparent / x-request-id 헤더 전파

OTel 스택이면 08-otel-conventions.md 병행 — 에이전트가 MDC에 trace_id 를 넣어도
인코더가 MDC 를 출력하지 않으면 로그↔트레이스 연결이 끊긴다. 양쪽을 함께 확인

# 수집 경로 (L0의 otel collector config에서)
receivers  → filelog / otlp / fluentforward
processors → filter / transform / attributes  ← dedupe·drop 규칙 확인
exporters  → 백엔드 지정 여부

# 이중 수집 신호
같은 소스가 (a) 앱 내 브리지(appender/exporter)와 (b) 사이드카 파일 tail
양쪽에서 나가면서, collector에 한쪽을 버리는 filter가 있음
```

## Grep Patterns

```
# 파사드 우회
console\.(log|error|warn)\(
System\.out\.print|println\(
\bprint\(          # Python

# 문자열 결합 로그
log\w*\.(info|error|warn|debug)\([^,)]*\+
log\w*\.(info|error|warn|debug)\(`[^`]*\$\{

# 스택 소실 — -U 필수, Kotlin `catch (e: Exception)` 과 Java 멀티캐치 `(A | B e)` 를 받는다
rg -U 'catch\s*\([\w\s:.|<>]*\)\s*\{[\s\S]{0,300}?\.(error|warn)\([^)]*\.(message|getMessage\(\))'

# 시크릿·PII 후보가 로그 인자에 들어감
(log|logger)\w*\.\w+\([^)]*(password|passwd|token|secret|authorization|ssn|card|jumin)

# 구조화 로깅 사용 흔적
StructuredArguments\.|kv\(|logger\.(info|error)\(\s*\{
MDC\.(put|setContextMap)

# 환경별 레벨
Grep  "LOG_LEVEL|LOGGING_LEVEL|logging\.level" .env* compose*.y*ml 설정
```

## 판정

등급은 INSTRUCTIONS의 **등급 산출 규칙**이 정한다 — 위 Checks에서 **확정된** 최고 심각도가 곧 축 등급이다. 여기서는 이 축에만 걸리는 예외를 정의한다.

| 상황 | 처리 |
|------|------|
| 시크릿·PII 패턴이 히트 | grep은 **변수 이름**만 본다. 매칭 위치를 열어 실제 값·필드가 로그 인자로 들어가는지 확인한 것만 Critical로 확정한다. 확인 못 하면 `확인 필요` |
| PaaS가 수집을 대행할 가능성 | 인벤토리에서 PaaS 감지 시 수집 경로 항목을 `확인 필요`로 두고 FAIL 판정하지 않는다 |
| 수집·구조화·상관 ID 항목의 과반을 확인 못 함 | **확정 Check가 0개일 때만** 축 `판정 보류` |

## 제안 매핑

| 발견 | 제안 | 담당 |
|------|------|------|
| 수집 경로 없음 | 로깅 라이브러리 + collector receiver 도입. 배포 단위에 맞춰 stdout 수집 또는 OTLP 직송 | `sre` (이 스킬이 소유) |
| 구조화 없음 | JSON encoder 전환 + 필드 규약 정의 | `sre` |
| 상관 ID 없음 | `traceparent` 전파 + MDC/AsyncLocalStorage 바인딩 | `sre` |
| 경로 이중화 | 발신자 하나로 정리 — **필터만 지우면 중복, 발신자만 지우면 전멸**이므로 필터와 잉여 발신자를 함께 제거 | `sre` |
| 시크릿 노출 | 마스킹 규칙 + 로그 인자 검토 | `/security` |
| 파사드 우회 다수 | lint 규칙으로 `console.log` 금지 | `/code-review` → lint |
| 컨테이너 로그 드라이버 미설정 | compose `logging.options` | `/devops` (docker) |

## 주의

- 로그 레벨을 "전부 debug로 켜라"는 제안은 하지 않는다 — L6 비용과 직결된다
- 구조화 전환은 기존 로그 파서·알림을 깨뜨릴 수 있다. 전환 순서를 함께 제시할 것
- PaaS(vercel·fly)는 플랫폼이 수집을 대행하는 경우가 있다. 인벤토리에서 PaaS가 감지되면 "플랫폼 수집 여부 확인 필요"로 두고 FAIL 판정하지 않는다
