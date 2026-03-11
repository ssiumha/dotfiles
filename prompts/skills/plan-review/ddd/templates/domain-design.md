# [도메인명] 설계 문서

## 1. 개요

### 1.1 목적

[이 도메인의 목적을 1-2문장으로 설명]

### 1.2 범위

- [기능 1]
- [기능 2]
- [기능 3]

### 1.3 용어 정의

| 용어 | 정의 |
|-----|------|
| [용어1] | [정의] |
| [용어2] | [정의] |

---

## 2. 요구사항 분석

### 2.1 기능적 요구사항

#### 2.1.1 [기능 그룹 1]

- [요구사항 1]
- [요구사항 2]

### 2.2 비기능적 요구사항

#### 2.2.1 성능

- [성능 요구사항]

#### 2.2.2 보안

- **CRITICAL**: [보안 요구사항]

#### 2.2.3 확장성

- [확장성 요구사항]

---

## 3. 시스템 아키텍처

### 3.1 기술 스택

| 구분 | 기술 |
|-----|------|
| Language | [언어/버전] |
| Framework | [프레임워크/버전] |
| Database | [DB/버전] |
| Cache | [캐시] |

### 3.2 레이어 구조

```
┌─────────────────────────────────────┐
│         Presentation                │
│         (Controller)                │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│         Application                 │
│         (Service, DTO)              │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│           Domain                    │
│   (Entity, VO, Repository 인터페이스) │
└─────────────────────────────────────┘
                 ↑
┌─────────────────────────────────────┐
│        Infrastructure               │
│   (Repository 구현, 외부 API)        │
└─────────────────────────────────────┘
```

### 3.3 패키지 구조

```
com.company.project.[도메인]
├── domain/
│   ├── model/
│   │   └── [Entity].java
│   └── repository/
│       └── [Entity]Repository.java
├── application/
│   ├── dto/
│   │   ├── request/
│   │   └── response/
│   └── service/
│       └── [Entity]Service.java
├── infrastructure/
│   └── persistence/
│       └── [Entity]RepositoryImpl.java
└── presentation/
    └── controller/
        └── [Entity]Controller.java
```

---

## 4. 데이터베이스 설계

### 4.1 ERD

```
┌──────────────────────────────┐
│          [TABLE_NAME]        │
├──────────────────────────────┤
│ id (PK)         BIGINT       │
│ name            VARCHAR(100) │
│ status          VARCHAR(20)  │  ← Enum
│ created_at      TIMESTAMP    │
│ created_by      VARCHAR(50)  │
│ updated_at      TIMESTAMP    │
│ updated_by      VARCHAR(50)  │
└──────────────────────────────┘
         │
         │ 1:N
         ↓
┌──────────────────────────────┐
│       [CHILD_TABLE]          │
├──────────────────────────────┤
│ id (PK)         BIGINT       │
│ parent_id (FK)  BIGINT       │
│ ...                          │
└──────────────────────────────┘
```

### 4.2 테이블 상세 설계

#### [TABLE_NAME]

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| id | BIGINT | NOT NULL | AUTO_INCREMENT | PK |
| name | VARCHAR(100) | NOT NULL | - | 이름 |
| status | VARCHAR(20) | NOT NULL | 'ACTIVE' | 상태 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 생성일시 |
| created_by | VARCHAR(50) | NOT NULL | - | 생성자 |
| updated_at | TIMESTAMP | NULL | - | 수정일시 |
| updated_by | VARCHAR(50) | NULL | - | 수정자 |

**제약조건:**
- PK: id
- UNIQUE: [유니크 컬럼]
- CHECK: status IN ('ACTIVE', 'INACTIVE')

**인덱스:**
- PK: id
- INDEX: status

---

## 5. 도메인 모델 설계

### 5.1 Entity 설계

#### [Entity]

```java
/**
 * [Entity 설명]
 */
@Entity
@Table(name = "[table_name]")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class [Entity] {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status = Status.ACTIVE;

    // Audit 필드
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false, updatable = false, length = 50)
    private String createdBy;

    private LocalDateTime updatedAt;

    @Column(length = 50)
    private String updatedBy;

    @Builder
    public [Entity](String name, String createdBy) {
        this.name = name;
        this.createdBy = createdBy;
        this.createdAt = LocalDateTime.now();
    }

    // 도메인 메서드
    public void update(String name, String updatedBy) {
        this.name = name;
        this.updatedBy = updatedBy;
        this.updatedAt = LocalDateTime.now();
    }

    public void activate(String updatedBy) {
        this.status = Status.ACTIVE;
        this.updatedBy = updatedBy;
        this.updatedAt = LocalDateTime.now();
    }

    public void deactivate(String updatedBy) {
        this.status = Status.INACTIVE;
        this.updatedBy = updatedBy;
        this.updatedAt = LocalDateTime.now();
    }

    public boolean isActive() {
        return this.status == Status.ACTIVE;
    }
}
```

#### Status Enum

```java
/**
 * 상태
 */
public enum Status {
    /** 활성 */
    ACTIVE,
    /** 비활성 */
    INACTIVE
}
```

### 5.2 DTO 설계

#### Request DTO

```java
@Getter
@NoArgsConstructor
public class [Entity]CreateRequest {

    @NotBlank(message = "이름은 필수입니다")
    @Size(max = 100, message = "이름은 100자 이하여야 합니다")
    private String name;
}
```

#### Response DTO

```java
@Getter
@Builder
public class [Entity]Response {
    private Long id;
    private String name;
    private String status;
    private LocalDateTime createdAt;

    public static [Entity]Response from([Entity] entity) {
        return [Entity]Response.builder()
            .id(entity.getId())
            .name(entity.getName())
            .status(entity.getStatus().name())
            .createdAt(entity.getCreatedAt())
            .build();
    }
}
```

---

## 6. API 설계

### 6.1 엔드포인트 목록

| Method | URL | 설명 |
|--------|-----|------|
| POST | /api/v1/[entities] | 생성 |
| GET | /api/v1/[entities] | 목록 조회 |
| GET | /api/v1/[entities]/{id} | 단건 조회 |
| PUT | /api/v1/[entities]/{id} | 수정 |
| DELETE | /api/v1/[entities]/{id} | 삭제 |

### 6.2 상세 API 명세

#### 생성

```
POST /api/v1/[entities]
```

**Request Body:**
```json
{
  "name": "예시"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "예시",
    "status": "ACTIVE",
    "createdAt": "[ISO-8601 datetime]"
  },
  "message": "생성되었습니다"
}
```

#### 목록 조회

```
GET /api/v1/[entities]?status=ACTIVE&page=0&size=20
```

**Query Parameters:**
- `status` (optional): 상태 필터
- `page` (optional): 페이지 번호 (default: 0)
- `size` (optional): 페이지 크기 (default: 20)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [...],
    "totalElements": 100,
    "totalPages": 5
  }
}
```

---

## 7. 서비스 로직

### 7.1 주요 비즈니스 로직

#### 생성

1. 입력 검증
2. 중복 확인 (필요시)
3. Entity 생성
4. 저장
5. Response 반환

#### 수정

1. 존재 확인
2. 권한 확인 (필요시)
3. 수정
4. Response 반환

---

## 8. 테스트 전략

### 8.1 단위 테스트

**Domain Layer:**
- Entity 생성 테스트
- 도메인 메서드 테스트
- 상태 전이 테스트

**Application Layer:**
- Service 유스케이스 테스트
- Repository Mock 사용

### 8.2 통합 테스트

**Infrastructure Layer:**
- Repository 테스트 (Testcontainers)
- 실제 DB 쿼리 검증

**Presentation Layer:**
- Controller 테스트 (MockMvc)
- 요청/응답 검증

---

## 9. 보안 고려사항

- [ ] 인증/인가 적용
- [ ] 입력 검증 (XSS, SQL Injection 방지)
- [ ] 민감 정보 암호화
- [ ] 감사 로그 기록

---

## 10. 향후 확장 계획

- [확장 계획 1]
- [확장 계획 2]
