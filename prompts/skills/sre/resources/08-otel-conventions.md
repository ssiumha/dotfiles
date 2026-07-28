# OpenTelemetry 규약 점검

L1·L2·L6에서 공통으로 참조한다. OTel을 **도입했는지**가 아니라 **규약대로 썼는지**를 본다.

판정 질문: **"이 신호가 어느 서비스·어느 환경에서 왔는지 알 수 있고, 로그·트레이스·메트릭이 서로 이어지는가?"**

계측을 켜도 속성 이름이 어긋나면 대시보드·알림·쿼리가 도구 간에 맞지 않고, 백엔드를 바꿀 때 전부 다시 짜야 한다. 규약은 이식성의 문제다.

## 1. Resource 속성 — 누가 보낸 신호인가

| 속성 | 요구 수준 | 안정성 | 없으면 |
|------|----------|--------|--------|
| `service.name` | **Required** (SDK가 제공해야 함) | Stable | 신호가 `unknown_service` 류로 뭉개져 서비스 구분이 안 된다 |
| `service.version` | Recommended | Stable | 어느 버전이 회귀를 냈는지 대조 불가 |
| `service.namespace` | Recommended | Stable | 동명 서비스가 여러 팀에 있으면 충돌 |
| `service.instance.id` | Recommended | Stable | 인스턴스별 이상(한 파드만 느림)을 못 가른다 |
| `deployment.environment.name` | Recommended | Stable | **스테이징 장애가 프로덕션 알림을 울린다.** 권장 값: `development` · `staging` · `production` · `test` |

`service.name` 하나만 있고 `deployment.environment.name`이 없는 구성이 흔하다. L3 알림에서 환경 필터를 못 걸게 되므로 High로 본다.

```
# 확인
Grep  "OTEL_SERVICE_NAME|OTEL_RESOURCE_ATTRIBUTES|service\.name"
Grep  "deployment\.environment"           ← 구 이름 사용 여부도 함께 확인
Glob  **/instrumentation.{ts,js}  **/otel*.{ts,js,py,go}   ← Resource 생성 지점
```

## 2. 신호 상관 — 셋이 이어지는가

트레이스·메트릭·로그는 **같은 resource + trace context**로 묶인다. 이게 끊기면 세 개의 별도 도구를 쓰는 것과 같다.

| 연결 | 확인 |
|------|------|
| 로그 ↔ 트레이스 | 로그 레코드에 `trace_id`·`span_id`가 실리는가 (L1의 상관 ID와 같은 값이어야 한다) |
| 서비스 ↔ 서비스 | `traceparent` 헤더가 HTTP·메시지 경계에서 전파되는가 ([W3C Trace Context](https://www.w3.org/TR/trace-context/)) |
| 신호 ↔ 배포 | 세 신호 모두 같은 `service.version`을 갖는가 |
| 에러 응답 ↔ 로그 | 에러 응답에 실린 식별자가 `trace_id`인가 (L5 에러 표면과 교차) |

JVM은 에이전트가 MDC에 `trace_id`·`span_id`를 넣어 주고, 로깅 설정이 MDC를 출력해야 실제로 실린다. **에이전트만 켜고 인코더가 MDC를 안 내보내면 연결이 끊긴다** — 양쪽을 함께 확인한다.

## 3. HTTP 속성과 카디널리티

| 속성 | 요구 수준 |
|------|----------|
| `http.request.method` | Required |
| `url.path` · `url.scheme` | Required (서버 스팬) |
| `http.route` | Conditionally Required — 라우트 템플릿을 쓸 수 있을 때 |
| `http.response.status_code` | Conditionally Required — 상태 코드 수신 시 |
| `server.address` · `server.port` · `url.full` | Required (클라이언트 스팬) |

**카디널리티의 핵심**: `http.route`는 저카디널리티를 유지하고 정적 세그먼트를 포함해야 한다. **raw URI 경로를 그대로 쓰지 않는다** — 동적 구간은 자리표시자로(`/users/{id}`), 프레임워크의 라우팅 정보를 쓴다.

메트릭 라벨에 `url.path`(raw)를 넣으면 사용자 수만큼 시계열이 생긴다. 이것이 L2의 "카디널리티 폭발" 항목의 구체적 형태다.

## 4. 규약 버전 드리프트

semconv는 계속 안정화·변경된다. **v1.20.0 이전 계측은 구 HTTP 규약을 쓸 수 있고**, 공식 전환 수단은 `OTEL_SEMCONV_STABILITY_OPT_IN` 환경변수다.

```
Grep  "OTEL_SEMCONV_STABILITY_OPT_IN"
Grep  "http\.method|http\.status_code|http\.url"   ← 구 규약 잔재 후보
```

구·신 규약이 섞이면 같은 개념이 두 이름으로 쌓여 대시보드가 절반씩만 맞는다. 어느 쪽이든 **한 규약으로 통일됐는지**를 본다.

라이브러리·에이전트 버전을 확인하고, 도입·업그레이드 시 현재 semconv 안정성 등급을 확인한다(전역 규칙: 버전 인식).

## 5. Collector 파이프라인

구조는 `receivers` → `processors` → `exporters`를 `service.pipelines`가 연결해야 **활성화**된다. 정의만 하고 파이프라인에 안 넣으면 동작하지 않는다 — 흔한 실수다.

> "The order of the processors in a pipeline determines the order of the processing operations that the Collector applies to the signal." — OTel Collector 문서

즉 **processor 순서가 결과를 바꾼다.** 공식 문서는 고정된 권장 순서를 규정하지 않고 각 processor의 README를 참조하도록 안내하므로, 순서에 의도가 있는지(그리고 그 의도가 주석·문서로 남아 있는지)를 확인한다.

```
# 확인 항목
- service.pipelines 에 등록되지 않은 receiver/exporter/processor 가 있는가  ← 죽은 설정
- filter·transform·drop 계열 processor 가 무엇을 버리는가                  ← L1 이중 수집과 직결
- 같은 신호를 두 파이프라인이 처리하며 한쪽이 버리는 구조가 아닌가
- memory_limiter·batch 계열이 있는가 (없으면 L6 자원 폭주 위험)
```

**버리는 processor는 반드시 이유를 확인한다.** 발신자를 정리하면서 필터를 남기면 남은 유일한 발신자를 계속 버려 해당 신호가 통째로 사라진다 — 필터와 잉여 발신자는 함께 정리해야 한다.

## 판정 반영

이 파일은 독립 축이 아니라 L1·L2·L6의 판정에 합류한다.

| 발견 | 반영 축 | 심각도 |
|------|---------|--------|
| `service.name` 없음 | L2 | Critical |
| `deployment.environment.name` 없음 | L2 (L3 알림 필터에 영향) | High |
| 로그에 `trace_id` 미포함 | L1 | High |
| raw path가 라벨·속성에 들어감 | L2 | High |
| 구·신 semconv 혼재 | L2 | Medium |
| 파이프라인 미등록 컴포넌트 | L1·L2 | Medium |
| 필터가 유일 발신자를 버림 | L1 | Critical — 실질적으로 "수집 경로 없음"이다 |
| `memory_limiter`·`batch` 부재 | L6 | High — 수집기가 자원을 무제한 쓴다 |
| 보존·샘플링 설정이 파이프라인에 미등록 | L6 | High — 설정 존재가 곧 적용은 아니다 |

여기의 심각도는 해당 축의 Check로 그대로 올라가고, 축 등급은 INSTRUCTIONS의 **등급 산출 규칙**(Critical→FAIL / High→WARN)으로 결정된다. 별도 판정 경로가 아니다.

## 주의

- OTel 미도입 자체를 결함으로 보지 않는다 — Prometheus·Sentry 등 다른 스택으로 같은 목적을 달성했다면 그 스택의 규약으로 판정한다
- semconv 속성을 전부 채우라고 제안하지 않는다. `service.name` · `deployment.environment.name` · `service.version` 셋이 대부분의 운영 질문에 답한다
- 속성 이름 변경은 기존 대시보드·알림을 깨뜨린다. 전환 시 `OTEL_SEMCONV_STABILITY_OPT_IN`으로 이중 발신 기간을 두도록 안내
