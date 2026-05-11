---
name: SoC
full_name: Separation of Concerns
category: architecture
origin: Edsger W. Dijkstra, 1974
one_liner: "서로 다른 관심사를 섞지 않는다"
---

# SoC — Separation of Concerns

## 정의

> "각 부분이 하나의 관심사만 다루고, 다른 관심사를 모른다."

SRP가 모듈 내부의 원칙이라면, SoC는 계층/레이어/시스템 수준의 분리 원칙이다.

## 핵심 판단

- **"이 계층이 다른 계층의 세부사항을 알고 있는가?"** — 알면 SoC 위반
- **"이 코드를 바꾸려면 어떤 관심사를 이해해야 하는가?"** — 2개 이상이면 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| Controller/Handler에 SQL/ORM 쿼리 | grep SQL 키워드 in controller 디렉토리 |
| 비즈니스 로직에 HTTP 상태코드/요청 객체 | grep `request\|response\|status_code` in domain/service |
| 템플릿/뷰에 비즈니스 로직 | 템플릿 파일에서 조건 분기 복잡도 측정 |
| 인프라 코드에서 도메인 모델 import | import 방향 분석 |
| 테스트에 프로덕션 부수효과 (메일 발송, 외부 API) | grep 외부 호출 in test 디렉토리 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "이 파일을 이해하려면 DB 스키마도 알아야 해" | 관심사가 뒤엉킴 |
| UI 변경이 비즈니스 로직 변경을 유발 | 표현과 도메인이 결합 |
| 로깅/인증/캐싱이 비즈니스 로직에 산재 | 횡단 관심사 미분리 |
| 한 파일에 import가 모든 계층을 참조 | 계층 경계 무시 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 계층 간 관심사 혼재 0, import 방향 일관 |
| **WARN** | 관심사 혼재 1-2곳 OR 횡단 관심사 미분리 |
| **FAIL** | Controller에 SQL, 도메인에 HTTP, 또는 계층 경계 무시 반복 |

## 관심사 분리 수준

| 수준 | 분리 대상 | 예시 |
|------|-----------|------|
| 코드 내 | 로직 vs 부수효과 | 순수 함수 + IO 분리 |
| 모듈 간 | 도메인 vs 인프라 | Hexagonal Architecture |
| 계층 간 | 표현 vs 비즈니스 vs 데이터 | Layered Architecture |
| 시스템 간 | 서비스 A vs 서비스 B | Bounded Context |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| Controller에 비즈니스 로직 | **Service 계층 추출** |
| 비즈니스에 인프라 세부사항 | **Repository 패턴** — 인터페이스로 격리 |
| 횡단 관심사 산재 | **Middleware/Decorator/AOP** — 로깅, 인증, 캐싱 분리 |
| UI와 도메인 결합 | **DTO/ViewModel** — 표현용 모델 분리 |

## 주의

- SoC는 물리적 분리(파일/서비스)가 아니라 논리적 분리가 핵심. 같은 파일이어도 관심사가 명확히 분리되어 있으면 괜찮다
- 과도한 분리 → 간접 참조 폭발 → KISS 위반. 실용적 판단 필요
- SRP를 지키면 SoC가 자연스럽게 따라오는 경우가 많다
