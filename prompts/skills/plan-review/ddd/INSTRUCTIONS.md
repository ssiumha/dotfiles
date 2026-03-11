# DDD Design Docs

DDD(Domain-Driven Design) 4계층 아키텍처 기반의 설계 문서 템플릿과 구조 가이드입니다.

## 언제 사용하나요?

- 새 도메인 설계 문서 작성 시
- DDD 4계층 패키지 구조 설정 시
- 테스트 디렉토리 구조 설정 시
- 기존 프로젝트 DDD 구조로 리팩토링 시

## Instructions

### 워크플로우 1: 설계 문서 작성

새 도메인 설계 문서 작성 요청 시:

1. **도메인 정보 수집**
   - "어떤 도메인인가요?" (예: 사용자 관리, 주문, 결제)
   - "주요 기능은 무엇인가요?"
   - "관련된 외부 시스템이 있나요?"

2. **템플릿 기반 문서 생성**
   - `templates/domain-design.md` 참조
   - 10개 섹션 구조로 작성
   - ERD, Entity, API 명세 포함

3. **사용자 검토**
   - 각 섹션 확인
   - 누락된 요구사항 추가

### 워크플로우 2: 패키지 구조 설정

새 프로젝트 또는 리팩토링 시:

1. **현재 구조 확인**
   ```bash
   tree src/main/java -d -L 3
   ```

2. **4계층 구조 제안**
   - Domain, Application, Infrastructure, Presentation
   - 계층별 역할 설명

3. **마이그레이션 계획** (기존 프로젝트)
   - 단계별 이동 계획
   - 의존성 방향 검증

### 워크플로우 3: 테스트 구조 설정

1. **현재 테스트 구조 확인**
   ```bash
   tree src/test/java -d -L 3
   ```

2. **4계층 테스트 디렉토리 제안**
   - 계층별 테스트 특성 설명
   - Mock 사용 기준 안내

---

## 4계층 DDD 구조

### 계층 의존성

```
┌─────────────────────────────────────┐
│         Presentation                │  ← HTTP 요청/응답
│         (Controller)                │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│         Application                 │  ← 유스케이스 조합
│         (Service, DTO)              │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│           Domain                    │  ← 핵심 비즈니스
│   (Entity, VO, Repository 인터페이스) │
└─────────────────────────────────────┘
                 ↑
┌─────────────────────────────────────┐
│        Infrastructure               │  ← 어댑터 구현
│   (Repository 구현, 외부 API)        │
└─────────────────────────────────────┘

의존성 방향: Presentation → Application → Domain ← Infrastructure
```

### 패키지 구조

```
src/main/java/com/company/project/
├── domain/                      # Domain Layer (핵심 비즈니스)
│   ├── model/                   # Aggregate Root, Entity, Value Object
│   ├── repository/              # Repository 인터페이스 (포트)
│   ├── service/                 # Domain Service
│   └── event/                   # Domain Event
│
├── application/                 # Application Layer (유스케이스)
│   ├── dto/                     # Request/Response DTO
│   │   ├── request/
│   │   └── response/
│   ├── service/                 # Application Service
│   └── mapper/                  # Entity ↔ DTO 변환
│
├── infrastructure/              # Infrastructure Layer (어댑터)
│   ├── persistence/             # Repository 구현체, JPA Entity
│   ├── external/                # 외부 API 클라이언트
│   └── messaging/               # 메시지 큐 (Kafka 등)
│
└── presentation/                # Presentation Layer (API)
    ├── controller/              # REST Controller
    ├── advice/                  # Exception Handler
    └── config/                  # Web Config
```

### 계층별 역할

| 계층 | 역할 | 포함 | 의존성 |
|-----|------|-----|-------|
| Domain | 핵심 비즈니스 로직 | Entity, VO, Repository 인터페이스 | 없음 (순수) |
| Application | 유스케이스 조합 | Application Service, DTO | Domain |
| Infrastructure | 어댑터 구현 | Repository 구현, 외부 API | Domain |
| Presentation | HTTP 처리 | Controller, Exception Handler | Application |

### 계층 규칙

**Domain Layer**:
- 외부 의존성 없음 (순수 비즈니스 로직)
- 프레임워크 의존 최소화
- Repository는 인터페이스만 정의

**Application Layer**:
- 트랜잭션 경계 설정
- 여러 도메인 서비스 조합
- DTO ↔ Entity 변환

**Infrastructure Layer**:
- Domain의 Repository 인터페이스 구현
- 외부 시스템 연동 구현
- 프레임워크 의존 코드 (JPA 등)

**Presentation Layer**:
- HTTP 요청/응답 처리
- 입력 검증
- 예외 처리

---

## 테스트 구조

### 4계층 테스트 디렉토리

```
src/test/java/com/company/project/
├── domain/                      # Domain Layer 테스트
│   ├── model/                   # Entity, VO 테스트
│   └── service/                 # Domain Service 테스트
│
├── application/                 # Application Layer 테스트
│   └── service/                 # 유스케이스 테스트
│
├── infrastructure/              # Infrastructure Layer 테스트
│   ├── persistence/             # Repository 테스트
│   └── external/                # 외부 API 테스트
│
└── presentation/                # Presentation Layer 테스트
    └── controller/              # Controller 테스트
```

### 계층별 테스트 특성

| 계층 | 테스트 방식 | Mock 사용 | 속도 |
|-----|-----------|----------|------|
| Domain | 순수 단위 테스트 | 최소화 | 빠름 |
| Application | 유스케이스 테스트 | Repository Mock | 빠름 |
| Infrastructure | 통합 테스트 | 실제 DB (Testcontainers) | 중간 |
| Presentation | API 테스트 | MockMvc | 빠름 |

### 테스트 피라미드

```
      /\
     /  \     E2E (10%)
    /----\    - Cucumber, 전체 플로우
   /      \
  /--------\  통합 (20%)
 /          \ - Testcontainers, Repository
/------------\  단위 (70%)
              - Domain, Application
```

### Mock 사용 기준

**Mock 최소화 (Domain)**:
- 순수 비즈니스 로직 검증
- 실제 객체 사용 권장
- 외부 의존 없음

**Mock 사용 (Application)**:
- Repository Mock으로 유스케이스 검증
- 외부 API Mock

**실제 인프라 (Infrastructure)**:
- Testcontainers로 실제 DB 사용
- WireMock으로 외부 API Mock

---

## 설계 문서 구조

### 표준 10개 섹션

```markdown
# [도메인명] 설계 문서

## 1. 개요
### 1.1 목적
### 1.2 범위
### 1.3 용어 정의

## 2. 요구사항 분석
### 2.1 기능적 요구사항
### 2.2 비기능적 요구사항

## 3. 시스템 아키텍처
### 3.1 기술 스택
### 3.2 레이어 구조
### 3.3 패키지 구조

## 4. 데이터베이스 설계
### 4.1 ERD
### 4.2 테이블 상세 설계

## 5. 도메인 모델 설계
### 5.1 Entity 설계
### 5.2 DTO 설계

## 6. API 설계
### 6.1 엔드포인트 목록
### 6.2 상세 API 명세

## 7. 서비스 로직
### 7.1 주요 비즈니스 로직

## 8. 테스트 전략
### 8.1 단위 테스트
### 8.2 통합 테스트

## 9. 보안 고려사항

## 10. 향후 확장 계획
```

상세 템플릿: `templates/domain-design.md`

---

## 예시

### 예시 1: 새 도메인 설계 문서

User: "사용자 관리 도메인 설계 문서 작성해줘"

1. 도메인 정보 수집
2. templates/domain-design.md 기반 작성
3. Entity, DTO, API 명세 포함
4. ERD ASCII 다이어그램 포함

### 예시 2: 패키지 구조 설정

User: "이 프로젝트 DDD 구조로 정리해줘"

1. 현재 구조 분석
2. 4계층 구조 제안
3. 파일 이동 계획 수립
4. 의존성 방향 검증

### 예시 3: 테스트 구조 설정

User: "테스트 디렉토리 구조 어떻게 해야 해?"

1. 4계층 테스트 디렉토리 제안
2. 계층별 테스트 특성 설명
3. Mock 사용 기준 안내

## Technical Details

설계 문서 템플릿: `templates/domain-design.md`
