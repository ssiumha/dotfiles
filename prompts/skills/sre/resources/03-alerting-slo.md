# L3 — 알림·SLO

판정 질문: **"장애를 사용자보다 먼저 아는가, 그리고 그 알림이 행동으로 이어지는가?"**

수집(L1·L2)은 사후 조사를 가능하게 하고, 알림은 사전 인지를 가능하게 한다. 대시보드는 누군가 보고 있을 때만 작동한다.

**선행 조건**: L1 또는 L2에 최소 하나의 수집 경로가 있어야 한다. 둘 다 없으면 이 축은 판정하지 않고 "선행 조건 미충족"으로 표시한다.

## Checks

### Critical

- **알림 규칙 없음**: 감지 수단이 대시보드뿐. 장애를 사용자 문의로 알게 된다
- **알림 수신처 없음**: 규칙은 있는데 나가는 곳(receiver·webhook·notification policy)이 설정에 없다. *채널을 실제로 보는지는 조직 사실이라 판정하지 않는다*

### High

- **SLI/SLO 정의 없음**: "느리다"의 기준이 없어 알림 임계값이 감(感)으로 정해진다. 임계값 근거를 물으면 답이 없다
- **원인 기반 알림**: CPU 80%·메모리 90% 같은 원인 지표로 알림. 사용자에게 영향이 없는데도 울리고(피로), 영향이 있는데도 안 울린다(누락). 증상(에러율·지연·가용성) 기반이 원칙
- **알림 피로 구조**: 같은 사건에 여러 알림이 동시에 울리는데 억제(inhibit)·묶음(group) 규칙이 없음. *임계값의 적정성은 실측이 필요하므로 판정하지 않는다 — 규칙 파일에서 확인 가능한 것은 억제·묶음의 유무다*
- **알림 필수 조건 미충족**: Google SRE는 알림이 **긴급하고, 실행 가능하며, 인간의 판단을 요구해야** 한다고 규정한다. 기계가 대응할 수 있는 알림은 알림이 아니라 자동화 대상이다
  - 판별: 알림 하나를 골라 "이걸 받은 사람이 지금 당장 할 수 있는 행동이 있는가?"를 묻는다. 없으면 대시보드로 내려야 할 항목이다
- **on-call·에스컬레이션 미정의**: 알림이 울린 뒤 누가 받는지, 안 받으면 어디로 가는지 없음
- **error budget policy 부재**: SLO는 있는데 **소진했을 때 무엇을 할지**가 문서에 없음. Google SRE가 예시로 드는 행동 — 지난 4주 신뢰성 버그를 최우선으로 / SLO 복귀까지 신뢰성 작업에만 집중 / 예산이 회복될 때까지 변경을 멈추는 프로덕션 프리즈. 정책이 없으면 SLO는 관측 지표일 뿐 의사결정을 바꾸지 못한다

### Medium

- **error budget 없음**: SLO는 있으나 소진율을 추적하지 않아 "얼마나 더 실패해도 되는지" 판단 불가
- **알림에 런북 링크 없음**: 받은 사람이 무엇을 해야 하는지 알림 본문에 없음. 런북 자체의 유무는 L5가 판정한다 — 이 축은 **링크 유무만** 본다
- **알림 규칙이 코드 밖에 있음**: UI에서만 관리되어 버전 관리·리뷰·재현이 안 됨
- **심각도 구분 없음**: 깨워야 하는 것과 아침에 봐도 되는 것이 같은 채널로 감

## Detection Patterns

```
# 알림 규칙 파일
Glob  **/alert*.y*ml  **/rules/**/*.y*ml  **/alertmanager*.y*ml
Glob  **/prometheus/rules/**  **/grafana/provisioning/alerting/**
Glob  **/signoz/**  **/*alert*.json

# SLO 문서·정의
Glob  **/SLO*.md  **/slo*.y*ml  docs/slo*  **/sli*.y*ml
rg --case-sensitive 'SLO|SLI' docs/ README*     ← 경계(\b) 없이, 대소문자만 구분
rg -i 'error budget|가용성 목표|99\.[0-9]+%' docs/ README*
      ※ -i 로 SLO 를 찾으면 isLoading·slot·slow·AccessLogFilter 가 걸리고(실측 44건 중 35건 오탐),
        \b 를 걸면 한국어 `SLO를`·`SLO는` 을 놓친다. 대소문자 구분만이 양쪽을 만족한다

# 수신처
Grep  "slack|pagerduty|opsgenie|webhook_url|SLACK_WEBHOOK|email_configs" 설정·.env*

# 억제·묶음 규칙 (alertmanager 계열)
Grep  "inhibit_rules|group_by|group_wait|repeat_interval"

# on-call
Glob  **/oncall*  docs/oncall*  **/escalation*
Grep  "on-call|온콜|당직|escalation" docs/ README*
```

## Grep Patterns

```
# 원인 기반 알림 (증상 기반이어야 함)
#   경계(\b) 금지 — 메트릭 이름은 스네이크/카멜 합성어라 \b 를 걸면 0건이 된다
#   (실측: \b(cpu|memory)\b 는 container_memory_usage_bytes 에 매칭 안 됨)
expr:.*(cpu|memory|mem_used|disk_usage|load_average|node_filesystem)
alert:.*(?i)(cpu|memory|disk)(high|usage|load)

# 증상 기반 알림 (있어야 하는 것)
expr:.*(http_requests_total|error_rate|request_duration|probe_success|absent\()
expr:.*\bup\b                        ← up{job="api"} == 0 형태가 대부분이라 비교 연산자를 붙이지 않는다
alert:.*(?i)(errorrate|latency|availability|down|slo|budget)

# 심각도 라벨 · 런북 링크  ← -U (멀티라인) 필수. 없으면 항상 0건
rg -U 'labels:[\s\S]{0,200}severity:\s*(critical|warning|info|page)'
rg -U 'annotations:[\s\S]{0,300}(runbook|runbook_url|playbook)'

# error budget policy (소진 시 행동을 적어둔 문서)
rg -i 'error budget|예산 소진|버짓|프로덕션 프리즈|production freeze|release freeze|배포 중단'
```

**교차 확인 필수**: 원인 기반·증상 기반 둘 다 0건이면 알림 규칙이 없는 게 아니라 패턴이 안 먹은 것일 수 있다. 규칙 파일에 `alert:` 또는 `- alert` 가 몇 건인지 먼저 세고, 그 수와 분류 합계가 맞는지 대조한다.

## 판정

등급은 INSTRUCTIONS의 **등급 산출 규칙**이 정한다. 여기서는 이 축에만 걸리는 예외를 정의한다.

| 상황 | 처리 |
|------|------|
| L1·L2 모두 수집 경로 없음 | 축 `선행 조건 미충족` — 알림을 걸 대상이 없다. L1/L2 해결 후 재평가 |
| **L1·L2가 모두 미판정**(둘 다 `판정 보류`) | 선행 조건을 확인할 수 없다 → 축도 `판정 보류` |
| 관측 백엔드가 SaaS(Datadog·Sentry 등)이고 알림 규칙이 UI에만 존재 | **확정 Check가 0개일 때만** 축 `판정 보류`. FAIL로 찍지 않고 "규칙을 코드로 관리(provisioning·IaC)"를 제안한다 |
| 알림 수신처 grep이 히트 | `@slack/web-api` 같은 무관한 의존성일 수 있다. 매칭 위치가 **알림 라우팅 설정**인지 확인한 것만 확정 |
| 원인 기반·증상 기반 분류 결과가 둘 다 0건 | 패턴 미탐을 의심한다. `alert:`·`- alert` 총 개수와 분류 합계를 대조해 맞지 않으면 `확인 필요` — **0건을 근거로 "원인 기반 다수"를 판정하지 않는다** |

## 제안 매핑

| 발견 | 제안 | 담당 |
|------|------|------|
| 알림 규칙 0건 | **증상 3개부터** — 가용성(up/probe), 에러율, p95 지연. 이 셋이 대부분의 사용자 영향 장애를 덮는다 | `sre` |
| SLO 없음 | 사용자 여정 1개를 골라 SLI 정의 → 현재 값 측정 → 그보다 약간 낮게 SLO 설정. 처음부터 99.9%를 쓰지 않는다 | `sre` |
| 원인 기반 알림 다수 | 증상 기반으로 교체, 원인 지표는 대시보드로 이동(알림 아님) | `sre` |
| 알림 피로 | 묶음·억제 규칙 + 심각도 2단계(즉시 대응 / 업무시간 확인) | `sre` |
| 규칙이 UI에만 존재 | provisioning 파일로 내보내 저장소에 커밋 — 알림 규칙도 코드다 | `sre` |
| 런북 링크 없음 | 알림 annotation에 런북 경로 추가 (L5와 함께) | `sre` |
| on-call 미정의 | 수신 채널 + 미응답 시 에스컬레이션 1단계부터 | `sre` |

## SLO를 처음 도입할 때

제안할 때 이 순서를 지킨다 — 한 번에 전체 SLO 체계를 만들라는 제안은 실행되지 않는다.

```
1. 유형을 5개 이하로          Google SRE 권고: "가장 중요한 기능을 대표하는 SLI 유형을 5개 이하로"
2. SLI 명세 (사용자 관점)      "홈 요청 중 100ms 미만으로 로드된 비율"
                              ← 어떻게 재는지와 분리해서, 사용자에게 무엇이 중요한지로 쓴다
3. 측정 방법 선택              같은 명세라도 로그·로드밸런서·블랙박스·클라이언트로 잴 수 있다
                              정확도 / 적용범위 / 비용 3축으로 비교하고,
                              첫 SLI는 "엔지니어링 노력이 가장 적게 드는 것"으로 시작
4. 현재 값 측정                실측 (수집 경로가 있어야 가능 → L1·L2 선행)
5. SLO는 실측을 내림한 값으로   99.53% → 99.5%. Google SRE: "round down to manageable numbers"
6. error budget policy 작성    소진 시 무엇을 멈추고 무엇을 우선할지. 정책 없는 SLO는 지표일 뿐
7. 소진율 알림 1개
```

**2와 3을 분리하는 것이 핵심이다.** 명세를 측정 방법으로 써버리면(예: "nginx 로그의 5xx 비율") 측정 수단을 바꿀 때 SLO가 함께 바뀌어 시계열 비교가 끊긴다.

## 주의

- **알림 개수를 늘리라는 제안을 하지 않는다.** 증상 기반 소수가 원인 기반 다수보다 낫다
- SLO 목표치를 임의로 제시하지 않는다 — 실측 없이 정한 숫자는 근거가 없다. 측정 후 정하도록 안내
- 관측 백엔드가 SaaS(Datadog·Sentry 등)면 규칙이 저장소 밖에 있을 수 있다. 라벨은 위 "판정" 표를 따른다 — FAIL로 찍지 않고, 코드로 관리(IaC·provisioning)할 것을 제안
- 운영 성격에 따른 심각도 조정은 INSTRUCTIONS의 **심각도 기준선**이 단일 정의다 — 여기서 따로 정하지 않는다
