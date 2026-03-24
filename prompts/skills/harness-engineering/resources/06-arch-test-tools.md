# 아키텍처 테스트 가이드

아키텍처 불변식(의존 방향, 레이어 경계)을 CI에서 기계적으로 검증하기 위한 가이드.
의존 방향을 왜 강제해야 하는지의 원칙은 `resources/04-architecture-guide.md`의 Invariants 섹션 참조.

## 효과적인 아키텍처 테스트 규칙 유형

아키텍처 테스트가 검증해야 할 것은 **모듈 간 관계(경계)**이지, 모듈 내부 구현이 아니다.

| 규칙 유형 | 설명 | 예시 |
|-----------|------|------|
| **계층 규칙 (Layers)** | 상위→하위만 허용, 역방향 금지 | Controller → Service → Repository (역방향 금지) |
| **독립성 규칙 (Independence)** | 같은 레벨의 모듈끼리 서로 의존 금지 | Feature A ↛ Feature B (각자 독립) |
| **금지 규칙 (Forbidden)** | 특정 모듈이 특정 모듈을 절대 참조하지 못하게 차단 | UI 레이어 → Entity 직접 참조 금지 |
| **순환 의존 금지** | 패키지/모듈 간 순환 참조 차단 | A → B → C → A 금지 |

## 도메인 모델 가드레일 (Domain Model Guards)

모듈 간 경계 외에, **도메인 모델 자체의 일관성**을 강제하는 규칙. 도메인 모델이 아직 없는 초기 단계에서 가드레일을 세우면 향후 코드가 자연스럽게 규칙을 따른다.

### 규칙 카테고리

| 카테고리 | 무엇을 강제하는가 | 위반 시 문제 | 예시 |
|----------|-------------------|-------------|------|
| **공통 베이스 상속** | 도메인 모델이 공통 상위 타입을 상속 | 감사 필드(id, createdAt, updatedAt) 누락·불일치 | JPA: `@Entity` → `BaseEntity` 상속 |
| **테이블/컬렉션 이름 명시** | ORM의 자동 이름 생성에 의존하지 않음 | 프레임워크/언어 버전에 따라 이름이 달라짐 | JPA: `@Table(name=...)` 필수, Django: `class Meta: db_table` |
| **시간 타입 통일** | 타임존 인식 타입만 허용 | 앱/DB 서버 타임존에 따라 해석이 달라짐 | Java: `Instant` only (`LocalDateTime` 금지), Python: `datetime(tzinfo=...)` |
| **Enum 직렬화 방식** | 문자열 기반 직렬화 강제 | 순서 기반(ordinal)은 enum 재정렬 시 기존 데이터 불일치 | JPA: `EnumType.STRING`, Django: `CharField(choices=...)` |
| **도메인 모델 위치** | 도메인 모델은 지정된 패키지/모듈에만 | 위치 산재 → 찾기 어려움, 의존 방향 혼란 | `domain/` 또는 `models/` 패키지에만 배치 |
| **도메인 → DTO 참조 금지** | 도메인이 전송 객체에 의존하지 않음 | 도메인 순수성 파괴, API 변경이 도메인에 전파 | domain 패키지에서 dto 패키지 import 금지 |
| **Repository는 인터페이스** | 데이터 접근 계층은 추상화(인터페이스)로 정의 | 구현체 직접 작성 → ORM 교체·테스트 어려움 | JPA: `JpaRepository` 상속, Spring Data 패턴 |

### 선적용 (Pre-seeding) 패턴

도메인 모델이 아직 없는 초기 프로젝트에서도 규칙을 미리 등록할 수 있다. 검증 대상이 0개일 때 테스트가 실패하지 않도록 "빈 결과 허용" 옵션을 사용한다. 모델이 추가되는 순간부터 규칙이 자동 적용되므로, 초기에 가드레일을 세우는 데 유용하다.

| 도구 | 빈 결과 허용 방법 |
|------|-------------------|
| ArchUnit (Java) | `.allowEmptyShould(true)` |
| import-linter (Python) | 기본적으로 빈 결과 통과 |
| eslint-plugin-boundaries (JS/TS) | 규칙 자체가 import 발생 시에만 동작 |

### 경계 규칙과의 구분

위 규칙은 **모듈 내부 구조**가 아닌 **도메인 모델 경계의 일관성**을 강제한다. "테스트하면 안 되는 것"의 안티패턴("모듈 내부 구조 검증")과 혼동하지 않을 것:

- 경계 규칙 (OK): "도메인 모델은 반드시 공통 베이스를 상속" — 감사 필드 일관성이라는 불변식
- 내부 구조 (NO): "모델의 필드 순서는 id → name → ..." — 스타일 취향

## 테스트하면 안 되는 것

| 안티패턴 | 이유 |
|----------|------|
| **모듈 내부 구조 검증** | 클래스 배치, 메서드 호출 순서를 강제하면 리팩토링마다 테스트가 깨진다. 경계만 검증 |
| **비즈니스와 무관한 코딩 스타일** | "모든 클래스는 인터페이스를 가져야 한다"는 불변식이 아니라 취향. 린터로 충분 |
| **과도한 세밀함** | 너무 엄격하면 유연성이 급감하여 확장성과 창의성이 제한된다 |
| **커버리지 목표를 위한 테스트** | 아키텍처 테스트의 목적은 커버리지가 아니라 구조적 불변식의 자동 검증 |

## 하네스와의 관계

```
ARCHITECTURE.md 불변식  →  rules/*.md (작성 가이드)  →  아키텍처 테스트 (CI 강제)
       정의                     에이전트 가이드                 기계적 검증
```

- 하네스(Rules) = 작성 시점 가이드 — Claude가 처음부터 올바른 코드를 생성
- 아키텍처 테스트 = CI 최종 게이트 — 위반이 머지되기 전에 차단
- 둘 다 같은 불변식을 참조해야 드리프트 방지

## 언어별 도구 감지 (감사 시 참조)

| Stack | Tool | 감지 방법 |
|-------|------|-----------|
| Java/Kotlin | ArchUnit | `build.gradle`/`pom.xml`에서 `archunit` 의존성 + `*ArchTest*.java` |
| TypeScript/JS | eslint-plugin-boundaries | `.eslintrc*` 또는 `eslint.config.*`에서 `boundaries` 설정 |
| Python | import-linter | `.importlinter` 파일 또는 `pyproject.toml [tool.importlinter]` |
| Go | depguard | `.golangci.yml`에서 `depguard` 설정 |
| .NET | NetArchTest | `*.csproj`에서 `NetArchTest` 참조 + `*ArchTest*.cs` |
| Ruby | packwerk | `package.yml` 파일 존재 |

### 감사 시 감지 절차

1. **스택 식별** — 빌드 파일/패키지 매니저로 판단
2. **도구 감지** — 위 테이블의 감지 방법으로 구성 여부 확인
3. **CI 확인** — CI 설정에서 해당 테스트가 실행되는지 확인
4. **불변식 대조** — ARCHITECTURE.md Invariants와 테스트가 커버하는 규칙을 대조
