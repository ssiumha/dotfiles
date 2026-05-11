---
name: BC
full_name: Bounded Context
category: architecture
origin: Eric Evans, "Domain-Driven Design" (2003)
one_liner: "같은 단어도 맥락이 다르면 다른 모델이다. 경계를 명확히 긋는다"
---

# BC — Bounded Context

## 정의

> "Explicitly define the context within which a model applies. Explicitly set boundaries in terms of team organization, usage within specific parts of the application, and physical manifestations such as code bases and database schemas."

하나의 큰 시스템을 단일 모델로 통일하려 하면 모델이 비대해지고 모순이 생긴다. 대신 **각 맥락(Context)마다 별도의 모델**을 두고, 경계(Boundary)를 명확히 정의한다. 경계를 넘는 통신은 명시적 변환을 거친다.

## 핵심 판단

- **"이 모델이 시스템 전체에서 하나인가, 맥락마다 다른가?"** — 하나로 강제하면 BC 위반
- **"같은 이름의 엔티티가 다른 속성/행동을 가지는 곳이 있는가?"** — 있으면 분리 필요
- **"이 모듈을 변경할 때 다른 팀/서비스도 바꿔야 하는가?"** — 그렇다면 경계가 잘못됨

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| God Model (속성 30개+ 엔티티) | 엔티티 필드 수 카운트 |
| 하나의 테이블/클래스가 여러 팀이 수정 | git blame으로 변경자 다양도 확인 |
| 모듈 간 순환 의존 | import 순환 검출 |
| 같은 이름의 클래스가 여러 모듈에 존재하나 속성이 다름 | 동명 클래스 비교 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "User 테이블에 뭐가 이렇게 많아" | 여러 컨텍스트의 관심사가 한 모델에 혼재 |
| 한 엔티티 변경이 관련 없는 기능을 깨뜨림 | 컨텍스트 경계 없이 공유 |
| 팀 간 "이 필드 누가 소유?" 논쟁 | 소유권 불명확 = 경계 부재 |
| API 변경이 모든 소비자에게 영향 | 경계 없는 공유 모델 |
| 모놀리스에서 특정 영역만 빈번하게 변경 | 분리해야 할 컨텍스트 후보 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 컨텍스트별 모델 분리, 경계 넘는 통신은 명시적 변환, 팀-컨텍스트 정렬 |
| **WARN** | 일부 God Model 존재하나 핵심 도메인은 분리됨 |
| **FAIL** | 단일 God Model이 전체 시스템 관통 OR 모듈 간 순환 의존 OR 변경 연쇄 반응 |

## Context Mapping 패턴

Bounded Context 간 관계를 정의하는 패턴:

| 패턴 | 관계 | 언제 사용 |
|------|------|-----------|
| **Shared Kernel** | 공유 모델 (양쪽이 합의하에 공동 소유) | 밀접한 팀, 작은 공유 영역 |
| **Customer-Supplier** | 하류(Customer)가 상류(Supplier)에 요구 | 팀 간 협력 가능할 때 |
| **Conformist** | 하류가 상류 모델을 그대로 수용 | 외부 API, 변경 불가한 시스템 |
| **Anti-Corruption Layer** | 변환 계층으로 외부 모델 격리 | 레거시 통합, 모델 오염 방지 |
| **Open Host Service** | 공개 프로토콜 제공 | 다수 소비자에게 서비스 제공 |
| **Published Language** | 표준 교환 포맷 (JSON Schema 등) | 컨텍스트 간 데이터 교환 |
| **Separate Ways** | 통합하지 않음 | 통합 비용 > 가치일 때 |

## 경계를 긋는 기준

```
같은 BC에 있어야 하는 것:
  - 같은 트랜잭션 안에서 일관성이 필요한 것
  - 같은 UL을 쓰는 것
  - 같은 팀이 소유하는 것

다른 BC로 분리해야 하는 것:
  - 같은 이름이지만 다른 의미/속성을 가진 것
  - 독립적으로 변경/배포하고 싶은 것
  - 다른 팀이 소유하는 것
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| God Model (User가 50개 필드) | **컨텍스트별 모델 분리** — AuthUser, MemberProfile, BillingAccount |
| 모듈 간 직접 참조 | **ID 참조** — 객체 참조 대신 ID로 느슨한 연결 |
| 외부 시스템 모델이 내부를 오염 | **Anti-Corruption Layer** — 변환 계층 도입 |
| 모놀리스에서 특정 영역 분리 | **Module 경계 먼저** — 마이크로서비스 전에 모듈 경계부터 정리 |
| 팀 간 모델 충돌 | **Context Map 작성** — 관계를 명시적으로 정의하고 합의 |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| UL | BC 안에서 UL이 통용됨. BC가 UL의 유효 범위 |
| SoC | BC는 SoC의 시스템 레벨 적용 |
| COHESION-COUPLING | BC 내부는 높은 응집, BC 간은 낮은 결합 |
| DIP | BC 경계에서 의존 방향 관리 |
| POSTELS-LAW | BC 간 통신에서 Postel's Law 적용 |

## 주의

- BC ≠ 마이크로서비스. BC는 **논리적 경계**이고 배포 단위와는 별개. 모놀리스 안에서도 BC를 가질 수 있다
- 경계를 너무 잘게 나누면 통합 비용이 폭증. **Conway's Law** — 팀 구조에 맞추는 것이 현실적
- 처음부터 완벽한 경계를 찾으려 하지 말 것. 도메인 이해가 깊어지면서 경계가 조정된다
- 공유 데이터베이스는 BC 분리를 무효화한다. DB도 논리적/물리적으로 분리하는 것이 이상적이지만, 현실에서는 뷰/스키마 분리부터 시작
- 모든 시스템에 DDD가 필요한 건 아니다. CRUD 중심 간단한 앱에는 과도한 설계
