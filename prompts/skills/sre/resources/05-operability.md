# L5 — 운영 준비도

판정 질문: **"장애가 났을 때 대응할 수 있는가, 그리고 잃은 것을 되찾을 수 있는가?"**

## Checks

### Critical

- **백업 없음, 또는 복구 절차 없음**: 백업만 있고 되돌리는 절차가 저장소 어디에도 없으면 백업이 아니다
- **복구 검증이 자동화되지 않음**: 복구 절차는 있으나 실행·검증하는 잡이 없음. 저장소로 확인 가능한 것은 **검증 잡의 존재**까지이고(실제 성공 여부는 `확인 필요`), 잡 자체가 없으면 그것은 확정된 결함이다 (`SELF-TESTING-CODE`의 논리를 백업에 적용)
- **에러 응답에 내부 세부 노출**: 스택트레이스·SQL·파일 경로·내부 호스트명이 클라이언트로 나감. 공격 표면이자 [RFC 9457 §5](https://www.rfc-editor.org/rfc/rfc9457.html)가 명시적으로 금지하는 것

### High

- **런북 부재**: 배포·롤백·인시던트 대응 절차가 사람 머릿속에만 있음. 그 사람이 없는 시간에 장애가 난다
- **외부 의존성 장애 시 동작 미정의**: HTTP 클라이언트에 타임아웃이 없어 한 의존성의 지연이 전체로 번진다. 재시도가 무한이거나 백오프가 없어 장애를 증폭시킨다
- **우아한 저하 경로 없음**: 의존성이 죽으면 기능 하나가 아니라 페이지 전체가 죽는다. 부가 기능(추천·배지·환율)이 핵심 흐름(로그인·결제)을 함께 무너뜨리는 구조인지 본다 — 폴백·기본값·기능 비활성 경로가 있어야 한다
- **부하 차단(load shedding) 없음**: 과부하 시 큐가 무한히 자라 전체가 타임아웃으로 죽는다. 상한을 두고 초과분을 **빠르게 거절**(429 + `Retry-After`)하는 편이 전부 느려지는 것보다 낫다
- **시크릿 회전 경로 없음**: 유출 시 무엇을 어떤 순서로 바꿔야 하는지 없음. 시크릿이 코드·환경변수·CI에 흩어져 목록조차 불명확
- **에러 표면이 비일관**: 엔드포인트마다 에러 형식이 달라 클라이언트가 분기할 수 없다. 상관 ID가 응답에 없어 사용자 신고를 로그와 연결할 수 없다

### Medium

- **postmortem 관행 없음, 또는 blameless가 아님**: 같은 장애가 반복돼도 학습이 축적되지 않음. 기록이 있어도 **사람을 지목하는 서술**("A가 실수로", "확인하지 않아서")이면 다음부터 사실이 안 올라온다 — 원인은 사람이 아니라 그런 실수가 가능했던 시스템에 있다
- **toil이 자동화되지 않음**: 아래 "Toil 판별" 참조
- **온보딩·셋업 문서가 실제와 불일치**: 문서대로 하면 안 되는 단계가 있음 (`EXECUTABLE-DOCUMENTATION` — 셋업은 스크립트로)
- **problem type이 문서화되지 않음**: 에러 `type` URI가 있으나 그것이 무엇을 의미하는지 정의가 없음
- **의존성 상태 확인 수단 없음**: 외부 API·DB 상태를 헬스체크가 반영하지 않음

## 에러 표면 계약 (RFC 9457)

운영 관점에서 에러 응답은 **장애를 진단 가능하게 만드는 인터페이스**다. 세 가지를 본다.

| 관점 | 확인할 것 |
|------|----------|
| **추적 가능성** | 응답에 상관 ID가 실려 있는가 — 사용자가 캡처해 보낸 화면 하나로 로그·트레이스를 찾을 수 있어야 한다. RFC 9457의 `instance`(발생 식별 URI) 또는 확장 멤버(`traceId`)가 그 자리 |
| **기계 판독성** | `type`이 안정적인 URI로 문제 유형을 식별하는가 — 클라이언트가 문구(`title`)가 아니라 `type`으로 분기하고 재시도 여부를 판단할 수 있어야 한다 |
| **정보 위생** | `detail`에 내부 구현이 새지 않는가 — 스택·SQL·경로는 로그로, 응답에는 사용자가 취할 행동만 |

표준 멤버 (전부 선택):

| 멤버 | 정의 | 절 |
|------|------|----|
| `type` | 문제 유형 식별 URI. 없으면 `about:blank`로 간주 | §3.1.1 |
| `title` | "a short, human-readable summary of the problem type" — 발생마다 바뀌지 않는다 | §3.1.3 |
| `status` | HTTP 상태 코드 (정보용, 실제 응답 코드와 일치해야 함) | §3.1.2 |
| `detail` | 이번 발생에 고유한 설명 | §3.1.4 |
| `instance` | "a URI reference that identifies the specific occurrence of the problem" | §3.1.5 |

**`type` 없이 `title`로만 분기하면 문구를 바꾸는 순간 클라이언트가 깨진다.** 확장 멤버 이름 규칙(문자 시작, ALPHA·DIGIT·언더스코어, 3자 이상)은 §4.12.

미디어 타입은 `application/problem+json`. RFC 9457은 RFC 7807을 대체하며, 공통 문제 유형 URI 레지스트리와 역참조 불가 URI(tag 스킴 등) 사용 지침이 추가됐다. 서로 다른 유형의 문제가 동시에 발생하면 "가장 관련성 높거나 긴급한 문제"를 응답에 표현하도록 권고한다(§3).

보안: §5는 "the information included must be carefully vetted"와 함께 **"avoid making implementation details such as a stack dump available"**를 명시한다. 스택 노출이 Critical인 근거가 여기다.

### 재시도 신호

429·503으로 거절할 때 `Retry-After`([RFC 9110 §10.2.3](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.3))가 함께 나가는지 본다. 없으면 클라이언트가 즉시 재시도해 장애를 증폭시킨다 — 아래 "재시도 상한 없음" 항목의 서버 쪽 짝이다.

이 계약이 코드로 강제되는지도 함께 본다 — 에러 스키마가 타입·핸들러로 표현되어 있으면 `PARSE-DONT-VALIDATE`·`EXECUTABLE-DOCUMENTATION`의 적용 사례이고, 문서에만 있으면 드리프트한다.

## Toil 판별

Google SRE는 toil을 "하기 싫은 일"이 아니라 **다음 여섯 특성을 가진 운영 작업**으로 정의한다.

| 특성 | 뜻 |
|------|-----|
| 수동적 | 사람이 손으로 실행한다 |
| 반복적 | 같은 일이 계속 돌아온다 |
| 자동화 가능 | 기계가 같은 수준으로 할 수 있다 |
| 대응형 | 인터럽트 중심이고 반응적이다 — 전략적이지 않다 |
| 지속 가치 없음 | 끝나도 서비스 상태가 그대로다 |
| **서비스 성장에 O(n)** | 규모가 커지면 일도 선형으로 늘어난다 |

마지막 특성이 핵심 판별자다. 규모와 함께 늘어나는 수작업은 반드시 언젠가 사람을 다 태운다. Google SRE는 SRE 시간의 **50% 미만**을 toil 상한으로 권고한다.

저장소에서 보이는 toil의 흔적:

```
# 런북 안의 수동 반복 절차
rg -i '매주|매일|매월|주기적으로|정기적으로|수동으로|manually|every (day|week|month)' docs/ *.md

# 사람이 실행하는 것으로만 존재하는 운영 스크립트 — 2단계로 센다
1) 후보 목록화   ls scripts/ bin/ 에서 운영성 이름만
                 (backup|restore|cleanup|sync|migrate|rotate|reindex|report|purge|refresh)
2) 호출부 역검색  각 파일명을 .github/workflows/ · justfile · Makefile · crontab 에서 grep
                 → 히트 0 = 사람이 기억해서 돌리는 작업 (toil 후보)

# 스케줄러 부재
Glob  **/*.cron  **/crontab  .github/workflows/*schedule*
Grep  "schedule:|cron:" .github/workflows/ compose*.y*ml
  → 런북에 "주기적으로"가 있는데 스케줄러가 없으면 그 주기는 사람이 채우고 있다
```

**판정은 보수적으로.** 저장소는 "얼마나 자주 하는지"를 모른다. 확정할 수 있는 것은 *반복 절차가 문서로 지시되어 있는데 자동 실행 경로가 없다*는 구조적 사실까지다. 시간 비율은 `확인 필요`.

## Detection Patterns

```
# 백업·복구
Glob  **/backup*.sh  **/restore*.sh  **/*dump*.sh  **/cron*  **/*.cron
Grep  "pg_dump|mysqldump|mongodump|restic|borg|rsync.*backup"
Grep  "restore|복구|pg_restore" 스크립트·문서   ← 복구 절차 존재 여부
Grep  "restore" CI workflow                      ← 복구 검증 자동화 여부 (핵심)

# 런북
Glob  docs/runbooks/**  docs/runbook*  RUNBOOK*  docs/ops/**
Grep  "롤백|rollback|장애|incident|대응 절차" docs/

# 에러 표면
Grep  "application/problem\+json"
Grep  "ProblemDetail|ProblemDetails|problem_detail"     ← Spring 6+ 내장 타입 등
Glob  **/error-handler*  **/exception*  **/*ExceptionHandler*  **/errors.{ts,py,go,kt}
Grep  "@ControllerAdvice|@ExceptionHandler|errorHandler|app\.use\(.*err"
Next.js  app/**/error.tsx, app/api/**/route.ts의 에러 반환부

# 의존성 장애 대응
Grep  "timeout|Timeout|connectTimeout|readTimeout|AbortSignal\.timeout"
Grep  "retry|Retry|backoff|circuit|CircuitBreaker|resilience4j|opossum|p-retry"
Grep  "Retry-After|retry_after"        ← 429·503 응답 측에서 내보내는지

# 우아한 저하 — 서킷 브레이커는 한 수단일 뿐이다. 폴백 경로를 직접 찾는다
Grep  "fallback|Fallback|onErrorResume|catchError|getOrElse|orElseGet"
Grep  "allSettled|SupervisorJob|CompletableFuture.*exceptionally"   ← 부분 실패 허용
Grep  "featureFlag|feature_flag|unleash|launchdarkly|ff\.|isEnabled\(" ← 기능 비활성 경로
  → 전부 0건이면 의존성 하나가 죽을 때 페이지 전체가 죽는 구조일 가능성

# 부하 차단 — Retry-After 는 응답 신호일 뿐 차단이 아니다
Grep  "rate.?limit|rateLimit|throttl|bucket4j|express-rate-limit|slowDown"
Grep  "bulkhead|semaphore|maxConcurren|max_concurrent|queue.*(limit|capacity|maxSize)"
Grep  "429|TOO_MANY_REQUESTS|TooManyRequests"

# 시크릿
Glob  .env.example  .env.sample  **/secrets*.y*ml  **/sops*  **/*.enc
Grep  "vault|sops|age|SecretsManager|ssm|1password|op read"

# postmortem
Glob  docs/postmortems/**  **/postmortem*  **/incident-*.md
```

## Grep Patterns

```
# 스택·내부 세부 노출
res\.(json|send)\([^)]*\b(stack|sqlMessage|query)\b
NextResponse\.json\(\s*\{[^}]*\b(stack|cause)\b
rg -U 'printStackTrace\(\)[\s\S]{0,120}(response|write|body)'    ← -U 필수
"error"\s*:\s*(e|err|error)(\.toString\(\))?\s*[,}]      ← 예외 객체 통째 직렬화

# 상관 ID가 응답에 실리는가
(traceId|trace_id|requestId|request_id|correlationId|instance)\s*[:=]

# 타임아웃 없는 외부 호출 — "근처에 부재"는 단일 정규식으로 못 쓴다. 두 번 세어 차집합
1) 외부 호출 지점 수   rg -c '(fetch|axios\.(get|post)|httpClient|WebClient|RestTemplate)\('
2) 타임아웃 설정 수    rg -c '(timeout|Timeout).*[:=]|AbortSignal\.timeout'  (같은 파일 범위)
   → 1이 2보다 현저히 크면 누락 후보. 파일을 열어 확인한 것만 확정

# 무한·무백오프 재시도
rg -U 'while\s*\(true\)[\s\S]{0,200}(retry|fetch|request)'   ← -U 필수
retry\s*[:=]\s*(Infinity|-1|true)\s*[,}]                     ← 상한 없음

# 하드코딩 시크릿 흔적 (상세 판정은 /security로 위임)
(api[_-]?key|secret|token|password)\s*[:=]\s*["'][A-Za-z0-9/+_-]{16,}["']
```

## 판정

등급은 INSTRUCTIONS의 **등급 산출 규칙**이 정한다. 여기서는 이 축에만 걸리는 예외를 정의한다.

| 상황 | 처리 |
|------|------|
| 복구·롤백·런북 grep이 히트 | `restore`는 `actions/cache`의 **`restore-keys:`** 에 거의 항상 걸린다. `롤백`은 CHANGELOG 한 줄에도 걸린다. 매칭 위치를 열어 **복구 절차·검증 잡의 실체**인지 확인한 것만 확정 — 확인 못 하면 `확인 필요` |
| 타임아웃·재시도 grep이 히트 | `testTimeout`·`timeout-minutes`·`terminationGracePeriodSeconds`·패키지명이 전부 걸린다. **외부 호출 클라이언트 설정**임을 확인한 것만 센다 |
| HTTP API가 없는 저장소 (라이브러리·배치) | 에러 표면 계약 항목 전체를 검사 대상에서 제외한다. `확인 필요`가 아니라 **해당 없음** |
| 백업 대상 데이터가 없는 저장소 | 백업 항목 제외. 위와 동일 |

## 제안 매핑

| 발견 | 제안 | 담당 |
|------|------|------|
| 복구 검증 없음 | 복구를 CI 잡으로 — 백업본을 임시 DB에 복원하고 행 수·핵심 쿼리 검증. **백업 성공이 아니라 복구 성공을 측정** | `sre` → `/devops` (ci-cd) |
| 런북 없음 | 롤백·배포·최근 장애 3건부터. 알림 annotation에서 링크되게 (L3와 연결) | `sre` |
| 에러 표면 비일관 | `application/problem+json` 채택, 에러 핸들러 1곳으로 집약, `type` URI 목록을 코드에 열거형으로 정의 | `sre` |
| 상관 ID 미노출 | 에러 응답에 `instance` 또는 `traceId` 확장 멤버 추가 — L1의 상관 ID와 같은 값이어야 의미가 있다 | `sre` |
| 스택 노출 | 스택은 로그로, 응답에는 `type`·`title`·`detail`만. 환경별 분기로 처리하지 말고 항상 동일하게 | `/security` |
| 타임아웃 없음 | 모든 외부 호출에 연결·읽기 타임아웃. 기본값에 의존하지 않는다 (`FAIL-FAST`) | `sre` |
| 재시도 상한 없음 | 지수 백오프 + 상한 + 지터. 재시도가 장애를 증폭시키지 않게 | `sre` |
| 우아한 저하 없음 | 부가 기능에 폴백·기본값을 두어 핵심 흐름과 분리. 실패한 의존성이 페이지 전체를 죽이지 않게 | `sre` |
| 부하 차단 없음 | 동시성 상한 + 초과분 429. 전부 느려지는 것보다 일부를 빠르게 거절하는 편이 낫다 | `sre` |
| toil 자동화 안 됨 | 반복 절차를 스케줄러에 올린다 — cron·GHA `schedule:`·Justfile 태스크. 사람이 기억해서 도는 일을 없앤다 | `/devops` (ci-cd·github-action) |
| postmortem이 blameless 아님 | 서술을 "누가"에서 "무엇이 그것을 가능하게 했는가"로 전환 | `sre` |
| 429·503에 `Retry-After` 없음 | 거절 응답에 대기 시간을 실어 클라이언트가 즉시 재시도하지 않게 | `sre` |
| 에러 계약이 문서에만 | 타입·핸들러로 이동 | `/code-review` Workflow 5 |
| 시크릿 하드코딩 | 상세 진단 위임 | `/security` |

## 주의

- 백업 존재를 PASS 근거로 쓰지 않는다 — **복구 절차와 검증 잡까지 확인해야 한다.** 저장소로 확정할 수 있는 것은 그 둘의 **존재**이고(없으면 확정된 결함), 실제 복구 성공 여부는 `확인 필요`
- 타임아웃·재시도는 **grep 히트를 존재 증거로 쓰지 않는다.** `testTimeout`·`timeout-minutes`·`terminationGracePeriodSeconds`·패키지 이름이 전부 걸린다. 매칭된 위치가 **외부 호출 클라이언트 설정**인지 확인한 것만 센다 — 이 방향의 오탐은 없는 안전장치를 있다고 보고하므로 더 위험하다
- 시크릿 후보 grep(`password`·`token` 등)은 **변수 이름만** 본다. 확정이 아니라 후보이므로, 실제 값이 리터럴로 박혀 있는지 확인한 것만 결함으로 올린다
- 에러 응답 형식 전환은 클라이언트를 깨뜨린다. 새 엔드포인트부터 적용하고 기존은 점진 전환하도록 제안
- `type` URI는 역참조 가능할 필요는 없다 — 안정적으로 유일하면 된다. 문서 URL을 강제하지 않는다
- 운영 성격에 따른 심각도 조정은 INSTRUCTIONS의 **심각도 기준선**이 단일 정의다 — 여기서 따로 정하지 않는다
