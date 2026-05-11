---
name: SSoT
full_name: Single Source of Truth
category: architecture
origin: Information modeling / database design (term popularized in 2000s IT architecture)
one_liner: "모든 사실은 단 하나의 권위 있는 출처를 가진다. 나머지는 모두 파생이다"
---

# SSoT — Single Source of Truth

## 정의

> "Every data element is mastered (or edited) in only one place. All other locations are derived from, or reference, that authoritative source."

어떤 사실(fact, state, configuration)에 대해 **권위 있는 단일 출처**를 명시적으로 정한다.
다른 모든 표현(캐시, 복제본, 뷰, 문서, 별도 시스템)은 그 출처로부터 **파생(derive)**되거나 **참조(reference)**한다.

## DRY와의 차별점

| | DRY | SSoT |
|---|---|---|
| 초점 | **지식의 중복 표현** | **사실/상태의 권위 출처** |
| 레이어 | 주로 코드/문서 | 데이터/시스템/인프라 |
| 질문 | "이 코드/문서가 두 곳에 있나?" | "이 사실의 master는 누구인가?" |
| 해결 | Extract / 공유 모듈 | 출처 지정 + 파생 자동화 |
| 예시 | 두 곳의 검증 함수 | DB와 캐시의 사용자 상태 |

DRY는 "같은 것을 두 번 쓰지 마라", SSoT는 "어디가 진짜인지 정해라". SSoT는 중복 자체보다 **권위(authority)**의 문제다.

## 핵심 판단

- **"이 사실의 master는 어디인가?"** — 답할 수 없으면 SSoT 미정의
- **"여기 값이 틀렸을 때 어디를 봐야 하는가?"** — master를 가리키는가
- **"두 곳을 동시에 갱신해야 하는가?"** — 그렇다면 SSoT 위반 (파생이어야 함)
- **"하나가 다운되면 다른 곳에서 읽을 수 있는가?"** — 그건 read replica이지 두 개의 master가 아니다

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 같은 상수가 코드와 설정 양쪽에 정의 | grep으로 리터럴 추적 |
| 같은 enum/타입이 프론트·백·DB에 별도 정의 | 스키마 비교 |
| README와 코드의 옵션 목록 불일치 | 문서 vs 실제 옵션 diff |
| Terraform과 콘솔 수정이 공존 (drift) | `terraform plan` diff |
| OpenAPI 스펙과 라우트 핸들러 별도 작성 | 스펙 ↔ 라우트 cross-check |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 데이터 불일치 발생 시 "어느 게 맞아?" 질문 반복 | master 미지정 |
| 캐시 무효화 로직이 흩어져 있음 | 파생 관계가 명시되지 않음 |
| Feature flag가 코드, 환경변수, 외부 시스템 모두 존재 | 권위 출처 모호 |
| 권한/역할 정의가 코드 + DB + IAM에 중복 | authority 불명 |
| 문서를 "참고용"이라 하면서 의사결정에 사용 | master가 아닌데 master처럼 쓰임 |
| ETL 파이프라인이 여러 source에서 같은 fact 수집 | upstream master 미합의 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 핵심 사실마다 master 명시 + 파생 관계 자동화(코드/CI) |
| **WARN** | master는 암묵적으로 합의되어 있으나 파생이 수동 + 가끔 drift |
| **FAIL** | master 미정의 OR 두 곳에서 동시에 쓰기(write) 가능 OR 빈번한 데이터 불일치 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 코드 ↔ 인프라 | **IaC를 master**, 콘솔 변경 금지 (drift detection으로 강제) |
| API 스펙 ↔ 핸들러 | **스펙을 master**, 코드 자동 생성 (OpenAPI codegen) OR 코드를 master, 스펙 자동 생성 |
| DB 스키마 ↔ 모델 클래스 | **마이그레이션을 master**, 모델은 introspection 또는 codegen |
| 프론트 ↔ 백 타입 | **공유 스키마(Zod, JSON Schema, protobuf)**가 master |
| DB ↔ 캐시 | **DB가 master**, 캐시는 invalidate-or-refresh 정책 명시 |
| Feature flag | **단일 시스템(LaunchDarkly 등)이 master**, 코드는 read-only |
| 문서 ↔ 코드 | 가능하면 **코드를 master로** 두고 문서 자동 생성 (docstring → API doc) |
| 상수/Enum | **한 곳에 정의 후 import**, 다국어/플랫폼 간에는 codegen |

## Master 지정 체크리스트

새 데이터/상태를 도입할 때:

1. **이 사실의 master는?** — 한 시스템/파일/테이블/서비스를 지목한다
2. **누가 쓰기 권한을 갖는가?** — master만 write 가능, 나머지는 read-only
3. **파생은 어떻게 동기화되는가?** — push (이벤트), pull (refetch), build-time (codegen)
4. **drift는 어떻게 탐지하는가?** — CI 검증, drift detection, 정합성 모니터
5. **master가 다운되면?** — graceful degradation 정책

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[DRY]] | DRY가 코드 레벨이라면 SSoT는 데이터/시스템 레벨. SSoT 확립이 DRY의 전제 |
| [[ENCAPSULATION]] | master가 자신의 상태를 캡슐화하고, 외부는 인터페이스로만 접근 |
| [[DIP]] | 파생 시스템이 master의 추상에 의존 (예: 스키마 인터페이스) |
| [[IDEMPOTENCY]] | 파생 동기화는 멱등해야 한다 — 여러 번 sync해도 같은 상태 |
| [[FAIL-FAST]] | drift 감지 시 즉시 실패시켜야 한다. 조용한 불일치는 더 큰 부채 |
| [[CONVENTION-OVER-CONFIG]] | 합리적 기본 master 위치를 관례로 — "스키마는 항상 X에 있다" |

## 주의

- **모든 것에 master를 정해야 하는 건 아니다** — 휘발성 로컬 상태, 사용자별 UI 토글 등은 SSoT 대상 아님
- **master 자체가 분산되어도 된다** — Cassandra처럼 분산 스토리지가 master일 수 있다. 핵심은 "**논리적으로 단일 권위**"
- **read replica ≠ 두 개의 master** — 읽기 분산은 SSoT를 깨지 않는다. write가 한 곳이면 OK
- **너무 강한 SSoT는 결합을 만든다** — 모든 시스템이 한 DB를 직접 참조하면 변경이 어렵다. master를 service interface로 감싸 둔다
- **수동 동기화는 결국 drift된다** — "조심하면 된다"는 통하지 않는다. 자동화로 강제하라
- **"문서가 master"는 거의 항상 거짓** — 문서는 코드보다 먼저 낡는다. 코드/스키마를 master로
