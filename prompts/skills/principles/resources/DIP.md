---
name: DIP
full_name: Dependency Inversion Principle
category: design
origin: Robert C. Martin (SOLID)
one_liner: "고수준이 저수준에 의존하지 않는다. 둘 다 추상에 의존한다"
---

# DIP — Dependency Inversion Principle

## 정의

> "High-level modules should not depend on low-level modules. Both should depend on abstractions."

의존 방향을 뒤집는다. 비즈니스 로직이 DB/HTTP/파일시스템 같은 세부사항에 의존하는 게 아니라, 세부사항이 비즈니스 로직이 정의한 인터페이스에 의존한다.

## 핵심 판단

- **"import 방향이 항상 안정된 쪽을 향하는가?"** — 도메인 ← 인프라
- **"구체 클래스를 직접 생성하고 있는가?"** — new/직접 생성 = 결합
- **"이 모듈을 테스트할 때 외부 시스템이 필요한가?"** — 필요하면 DIP 위반 가능

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 도메인/서비스가 인프라 패키지를 import | import 방향 분석 (domain → infra 방향 존재 여부) |
| 구체 클래스 직접 생성 (new, 직접 import) | grep `new \|import.*Impl\|import.*Concrete` |
| 테스트에서 실제 DB/API 호출 필수 | 테스트 파일에서 외부 의존성 확인 |
| 고수준 모듈의 변경 빈도 > 저수준 | git log 변경 빈도 비교 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "DB를 바꾸면 비즈니스 로직도 바꿔야 해" | 의존 방향 역전 필요 |
| 인터페이스가 저수준 모듈에 정의됨 | 인터페이스는 사용하는 쪽(고수준)이 소유해야 |
| mock 없이는 단위 테스트 불가 | 직접 의존 때문 |
| 프레임워크 변경이 도메인 코드 변경 유발 | 프레임워크에 의존하는 도메인 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | import 방향 일관 (안정→불안정), 도메인이 인프라에 의존하지 않음 |
| **WARN** | 일부 역방향 의존 존재하나 핵심 도메인은 격리 |
| **FAIL** | 도메인이 인프라에 직접 의존 OR import 순환 OR 프레임워크 강결합 |

## 의존 방향 규칙

```
안정 (변경 적음)                    불안정 (변경 많음)
  도메인/모델  ←  서비스  ←  인프라/어댑터  ←  UI/Controller
```

- 화살표 방향 = 의존 방향. 항상 안정된 쪽을 향한다
- 폴더 구조가 이 방향을 반영해야 한다

## Stable Dependencies Principle (SDP)

DIP의 확장 — 불안정한 것이 안정된 것에 의존해야 한다.

**안정성 측정**:
- Instability = Ce / (Ca + Ce)
  - Ca: 들어오는 의존 (Afferent Coupling)
  - Ce: 나가는 의존 (Efferent Coupling)
  - 0 = 완전 안정 (많이 참조됨, 스스로 참조 안 함)
  - 1 = 완전 불안정 (참조 안 됨, 많이 참조함)
- 의존은 항상 Instability가 낮은 쪽을 향해야

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 도메인이 DB에 직접 의존 | **Repository 인터페이스** — 도메인이 정의, 인프라가 구현 |
| 서비스가 외부 API에 직접 의존 | **Port/Adapter** — 서비스가 Port 정의, Adapter가 구현 |
| 구체 클래스 직접 생성 | **의존성 주입 (DI)** — 생성자/팩토리로 주입 |
| 프레임워크 결합 | **Anti-Corruption Layer** — 프레임워크와 도메인 사이 변환 계층 |

## 주의

- 모든 의존성을 역전할 필요 없다. 안정적인 라이브러리(표준 라이브러리, 유틸)에 대한 직접 의존은 괜찮다
- DIP를 위해 모든 곳에 인터페이스를 만들면 YAGNI 위반. 실제 교체/테스트 필요성이 있을 때 적용
- 인터페이스의 소유권이 중요: 인터페이스는 사용하는 쪽(고수준)에 위치해야 한다
