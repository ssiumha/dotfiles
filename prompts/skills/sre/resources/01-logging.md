# L1 — 로깅

판정 질문: **"장애가 났을 때 원인을 로그로 찾을 수 있는가?"**
더 날카롭게: **"장애를 일으킨 그것이 죽은 뒤에도 로그가 남아 있는가?"** — 조사가 가장 필요한 순간에 함께 사라지는 로그는 없는 것과 같다.

## Checks

### Critical

- **수집 경로 없음**: 로그가 stdout으로만 나가고 어디에도 모이지 않음. 컨테이너 재시작·스케일아웃 시 소실. 배포 후 과거 로그를 볼 방법이 없다 (아래 "로그 내구성 사다리" 1단계)
- **구조화되지 않음**: 문자열 결합으로 로그를 만들어 필드 검색·집계가 불가능. `"user " + id + " failed: " + e`는 grep은 되지만 "특정 사용자의 실패율"을 낼 수 없다
- **시크릿·PII 노출**: 토큰·비밀번호·주민번호·카드번호가 로그에 그대로. 로그 저장소는 보통 애플리케이션보다 접근 통제가 느슨하다

### High

- **상관 ID 전파 없음**: trace/request id가 없어 한 요청의 로그를 서비스 경계 너머로 이어붙일 수 없다. 마이크로서비스·비동기 처리에서 치명적
- **수집 경로 이중화**: 같은 로그가 두 경로로 흐르고 한쪽이 dedupe 필터에 버려지는 구조. 필터를 지우면 중복, 발신자를 지우면 전멸 — 어느 쪽이 진실인지 불명확해진다 (`SSoT` 위반)
- **로그가 장애 단위와 함께 죽는 곳에만 쌓임**: 수집은 되는데 저장 위치가 컨테이너 내부 또는 호스트 볼륨뿐이다. 컨테이너 교체·호스트 장애 시 로그가 함께 사라진다 — **호스트가 죽은 장애를 조사할 수단이 그 호스트에 있다** (사다리 2~3단계)
- **로그 레벨 체계 부재**: 전부 `info` 또는 전부 `error`. 레벨로 필터링이 안 되면 노이즈에 묻힌다
- **예외에 스택트레이스 없음**: `catch (e) { log.error(e.message) }` — 발생 위치를 잃는다

### Medium

- **환경별 레벨 분리 없음**: prod에서 debug가 켜져 있거나, dev에서 error만 나옴
- **로그에 컨텍스트 부재**: 어떤 요청·사용자·리소스에 대한 것인지 필드가 없음
- **`console.log` / `println` 직접 사용**: 로깅 파사드를 우회해 레벨·포맷·수집이 적용되지 않음
- **감사 대상 이벤트가 로그에 없음**: 인증 성공·실패, 권한·설정 변경, 자금·자산 상태 변경이 남지 않는다. "누가 언제 무엇을 바꿔서 깨졌나"를 되짚을 수 없다 (아래 "감사 이벤트")

## 로그 내구성 사다리

"수집된다"에는 견디는 정도가 다른 층위가 있다. **무엇이 죽으면 무엇을 잃는가**로 판정한다.

| 단계 | 저장 위치 | 이것이 죽으면 잃는다 | 심각도 |
|------|----------|---------------------|--------|
| 1 | stdout만 (수집 없음) | 컨테이너 재시작 — 배포할 때마다 | **Critical** |
| 2 | 컨테이너 내부 파일 | 컨테이너 교체 — 배포할 때마다. 볼륨이 없으면 1단계와 같다 | **Critical** |
| 3 | 호스트 볼륨·호스트 파일 | 호스트 장애 — **조사가 가장 필요한 그 장애에서** | **High** |
| 4 | 원격 수집기(별도 호스트·SaaS) | 수집기 자체 장애만 | PASS 조건 |

3단계가 가장 자주 놓친다. `logging.driver`가 설정돼 있고 볼륨도 붙어 있어 "수집 경로 있음"으로 보이지만, 호스트가 OOM으로 죽거나 디스크가 찬 장애에서는 로그도 함께 잃는다. **로그는 그것이 관찰하는 대상보다 오래 살아야 한다.**

```
# 원격 전송 경로가 있는가 (4단계 여부)
Grep  "OTEL_EXPORTER_OTLP_ENDPOINT|otlphttp|otlp/|loki|elasticsearch|fluentd|fluent-bit|syslog"
compose logging.driver 가 fluentd·gelf·awslogs·syslog 인가 (json-file 은 로컬)

# 로컬에만 쌓이는가 (2~3단계)
compose 의 로그 볼륨 마운트 + 원격 exporter 부재
Grep  "RollingFileAppender|logging.file.path|filename:" 앱 설정
  → 파일 출력은 있는데 그 파일을 원격으로 보내는 경로가 없으면 3단계
```

**PaaS·k8s에서는 플랫폼이 4단계를 대행하는 경우가 많다.** 인벤토리에서 감지되면 `확인 필요`로 두고 단계를 단정하지 않는다.

## 감사 이벤트

운영 로그와 목적이 다르다 — 운영 로그는 *원인 진단*, 감사 로그는 *사후 책임 규명*이다. 규제 유무와 무관하게, 감사 이벤트가 없으면 "누가 언제 무엇을 바꿔서 깨졌나"를 되짚을 수 없다.

남아야 하는 최소 집합:

| 분류 | 예 |
|------|-----|
| 인증 | 로그인 성공·실패, 토큰 발급·폐기, 세션 만료 |
| 권한·설정 변경 | 역할 부여·회수, 정책·플래그 변경, 키 회전 |
| 상태 변경 | 자금·자산 이동, 주문·결제 확정, 데이터 삭제 |

```
Grep  "login|signin|authenticate|logout|token.*(issue|revoke)"  ← 로깅 호출과 함께 있는지
Grep  "role|permission|grant|revoke|policy.*chang"
Grep  "audit|Audit"                                             ← 전용 로거·appender 존재 여부
```

**운영 로그와 같은 스트림에 섞였는지도 본다.** 섞여 있으면 L6에서 운영 로그 보존을 줄일 때 감사 기록이 함께 잘린다 — 두 종류의 요건이 다르므로 분리가 원칙이다.

이 항목의 심각도는 운영 성격에 따라 크게 달라진다. 기준선은 INSTRUCTIONS의 **심각도 기준선**이 정한다 — 규제 대상이면 상향된다.

**무엇을 남겨야 하는지가 외부 요건으로 정해지는 경우**(금융·의료·개인정보 등)에는 위 최소 집합을 출발점으로만 쓰고, 실제 대상 목록과 보존 요건은 **발행처 원문을 찾아 확인한다**. 이 스킬은 그 목록을 들고 있지 않다 — 규정은 개정되고, 사본은 낡는다. 규정 준수 판정 자체는 `/security`가 소유한다.

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
| 로컬에만 쌓임 (사다리 3단계) | 원격 전송 경로 추가 — 로그가 관찰 대상보다 오래 살게. 컨테이너 로그 드라이버 변경은 `/devops` (docker) | `sre` → `/devops` |
| 감사 이벤트 부재 | 인증·권한변경·상태변경 지점에 전용 로거 추가. 운영 로그와 **다른 스트림**으로 | `sre` |
| 감사·운영 로그가 한 스트림 | 분리 후 각자의 보존 정책 적용 (L6과 함께) | `sre` |
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
