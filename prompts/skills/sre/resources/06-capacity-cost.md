# L6 — 용량·비용

판정 질문: **"이 시스템이 조용히 자원을 갉아먹거나, 한 컨테이너가 호스트를 죽일 수 있는가?"**

**선행 조건은 항목 단위다.** L1·L2의 수집량이 관측 비용을 만들므로, 수집 경로가 없으면 *관측 데이터 보존·샘플링 항목만* 빠진다. 리소스 제한·로그 회전·볼륨 증가는 관측 스택과 무관하므로 항상 판정한다.

## Checks

### Critical

- **리소스 제한이 하나도 없는 단일 호스트 배포**: 한 서비스의 메모리 누수가 호스트 전체를 OOM으로 끌고 간다. compose로 여러 서비스를 한 호스트에 올리면서 제한이 0개면 장애가 시간 문제다
- **로그·데이터 증가에 상한이 전혀 없음**: 로그 회전도 보존 정책도 볼륨 정리도 없음 — 디스크 고갈로 전체 서비스가 멈춘다

### High

- **컨테이너 리소스 제한 일부 누락**: 제한이 있는 서비스와 없는 서비스가 섞여 있음. 없는 쪽이 사고 지점이 된다
- **로그 드라이버 회전 설정 없음**: 컨테이너 로그가 무한 증가해 디스크를 채운다. Docker 기본 `json-file`은 회전이 꺼져 있다
- **관측 데이터 보존 정책 없음**: 로그·메트릭·트레이스가 무기한 쌓임. 비용이 선형 증가하고, 오래된 데이터가 쿼리를 느리게 만든다
- **볼륨 증가 관리 없음**: DB·업로드·캐시 볼륨의 상한과 정리 주기가 정의되지 않음

### Medium

- *(샘플링 정책 부재는 **L2가 소유**한다 — 같은 관측 사실로 두 축이 갈리지 않게 여기서 중복 계상하지 않는다. 비용 관점의 처방만 아래 제안 매핑에 둔다)*
- **이미지 크기 과다**: 빌드 도구가 최종 이미지에 남아 있음. 전송·기동 시간과 공격 표면 모두에 영향
- **불필요한 상시 실행**: 배치·개발용 서비스가 프로덕션 compose에 함께 떠 있음
- **캐시 계층 부재**: 같은 외부 호출·쿼리가 반복되어 비용과 지연을 동시에 만듦

## Detection Patterns

```
# 리소스 제한
compose  deploy.resources.limits.{cpus,memory}  /  mem_limit  cpus  (v2 문법)
k8s      resources.{requests,limits}
Grep     "mem_limit|memswap_limit|cpus:|resources:"

# 로그 회전
compose  logging.driver / logging.options.{max-size,max-file}
Grep     "max-size|max-file|logging:"
daemon.json의 log-opts는 저장소 밖 → "확인 필요"

# 관측 보존
Grep  "retention|ttl|TTL|RETENTION_PERIOD|--storage.tsdb.retention"
otel collector·prometheus·SigNoz·Loki 설정에서 보존 기간

# 샘플링 (L2와 공유)
Grep  "tail_sampling|probabilistic_sampler|OTEL_TRACES_SAMPLER|sampling_ratio"

# collector 자원 방어 (OTel 스택이면 08-otel-conventions.md 병행)
Grep  "memory_limiter|batch:"   ← 없으면 수집기가 자원을 무제한 쓸 수 있다
파이프라인에 등록되지 않은 컴포넌트는 동작하지 않는다 — 설정 존재 ≠ 적용

# 볼륨
compose  volumes: 블록 → named volume 목록
Grep     "prune|cleanup|vacuum|VACUUM|OPTIMIZE TABLE" 스크립트·cron

# 이미지 크기 — 신호만 잡고 판별은 /devops (docker) 로 넘긴다
단일 스테이지 Dockerfile 에 빌드 도구(gradle|maven|npm ci|pip install)가 남아 있는가
  → 있으면 "빌드 도구 잔존" 신호 1건. 베이스 이미지 선택·레이어 정리 판별은 이 스킬이 하지 않는다

# 상시 실행 서비스
compose  services 목록 vs profiles 사용 여부
Grep     "profiles:"   ← 개발 전용 서비스 분리 여부
```

## Grep Patterns

```
# 리소스 제한 부재 판정 (services 수 대비 limits 수)
services:\s*$          블록 내 최상위 서비스 키 개수
(mem_limit|memory:|limits:)   출현 수

# 무한 로그 — 가장 흔한 위반은 "logging: 블록이 아예 없는" 경우다 (Docker 기본이 무회전)
#   존재를 찾지 말고 부재를 세라: 서비스 수 vs max-size 출현 수
rg -c 'max-size' compose*.y*ml            → 0 이면 전 서비스 무회전
rg -U 'logging:[\s\S]{0,200}max-size'     → 명시 설정된 서비스만 (-U 필수)

# 보존 미설정 흔적
retention 관련 키가 0건이면서 관측 백엔드가 compose에 존재
  ※ 'ttl' 은 settle·bottle·little 에 걸린다 — 대소문자 구분 'TTL' 또는 키 형태 'ttl:' 로 좁힌다

# 빌드 도구가 최종 이미지에 남음 — 신호만 잡는다
rg -c '^FROM ' Dockerfile*                                    ← 1이면 단일 스테이지
rg -c 'gradle|maven|npm ci|pip install|go build' Dockerfile*  ← 빌드 도구 존재
  → 단일 스테이지 + 빌드 도구 = "빌드 도구 잔존" 신호. 레이어 정리·베이스 이미지 판별은 /devops (docker)
```

## 판정

등급은 INSTRUCTIONS의 **등급 산출 규칙**이 정한다. 여기서는 이 축에만 걸리는 예외를 정의한다.

| 상황 | 처리 |
|------|------|
| L1·L2에 수집 경로 없음 | *관측 데이터 보존 항목만* `확인 필요`. 리소스 제한·로그 회전·볼륨은 그대로 판정한다 — **컨테이너 OOM은 관측 스택과 무관하게 일어난다** |
| k8s·PaaS 배포 | 플랫폼 기본값이 제한을 거는 경우가 있다. 기본값 확인 후 판정, 확인 불가하면 `확인 필요` |
| 서비스 수를 셀 수 없음 | 아래 "서비스 수 세기" 절차로 산출한다. 그래도 불가하면 "제한 0개"만 확정하고 "일부만 제한"은 `확인 필요` |

### 서비스 수 세기 (Critical 판정의 분모)

**분모는 L0가 이미 확정했다** — `00-inventory.md`의 서비스 목록을 쓴다. 여기서 다시 세지 않는다.

주의: `rg -N '^  \w+:$' compose.yaml`처럼 들여쓰기만으로 세면 **`volumes:`·`networks:`·`secrets:`의 자식 키까지 섞여** 분모가 부풀고, 전 서비스에 제한이 걸려 있는데도 "일부만 제한"(High)으로 뒤집힌다. L0는 `services:` 블록만 잘라 세도록 되어 있다.

```
# 제한이 걸린 서비스 수 (매칭 횟수를 세야 하므로 --count-matches)
rg -U --count-matches 'mem_limit|deploy:[\s\S]{0,200}?limits:' compose.yaml
```

L0의 서비스 수와 비교한다 — 같으면 전부 제한, 0이면 Critical, 그 사이면 High. **분모를 못 구하면 "일부만 제한"을 주장하지 않고 `확인 필요`로 둔다.**

## 제안 매핑

| 발견 | 제안 | 담당 |
|------|------|------|
| 리소스 제한 없음 | 메모리 제한부터 — 실측 사용량의 2배 정도로 시작해 조정 | `/devops` (docker) |
| 로그 회전 없음 | compose `logging.options`에 `max-size`·`max-file` | `/devops` (docker) |
| 보존 정책 없음 | 신호별로 다르게 — 로그는 짧게, 메트릭은 길게, 트레이스는 샘플링 후 중간 | `sre` |
| 전량 트레이싱 | 확률 샘플링 도입, 에러·느린 요청은 tail sampling으로 보존 | `sre` |
| 이미지 과다 | 멀티스테이지 + slim/distroless 베이스 | `/devops` (docker) |
| 개발 서비스 상시 실행 | compose `profiles`로 분리 | `/devops` (docker) |
| 볼륨 무한 증가 | 정리 주기 + 상한 알림 (L3와 연결) | `sre` |

## 보존 기간을 정할 때

숫자를 임의로 제시하지 않는다. 판단 기준만 제시한다.

| 신호 | 판단 기준 |
|------|----------|
| 로그 | 인시던트 조사에 실제로 거슬러 올라가는 기간. 대부분 그보다 훨씬 길게 잡혀 있다 |
| 메트릭 | 용량 계획·계절성 비교에 필요한 기간. 해상도를 낮춰 장기 보관하는 방법이 있다 |
| 트레이스 | 전량 단기 + 에러·느린 요청만 장기 |

## 주의

- 비용 절감을 관측성 축소로 제안하지 않는다 — L1·L2가 FAIL인 상태에서 L6 비용을 이유로 수집을 줄이면 방향이 거꾸로다. **수집을 먼저 세우고, 그다음 샘플링·보존으로 비용을 관리한다**
- 실제 사용량·비용은 저장소에서 알 수 없다. 정적 판정 범위는 "제한·정책의 존재"까지이고 적정성은 "확인 필요"
- 리소스 제한을 너무 낮게 잡으면 OOM kill로 장애를 만든다. 실측 없이 구체적 수치를 제시하지 않는다
