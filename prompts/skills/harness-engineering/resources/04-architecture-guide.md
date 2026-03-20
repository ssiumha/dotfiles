# ARCHITECTURE.md 작성 가이드

## 왜 필요한가

> "The biggest difference between an occasional contributor and a core developer lies in the knowledge about the physical architecture of the project."
> — matklad

낯선 코드베이스에서 패치 작성은 2배 오래 걸리지만, **어디를 수정할지 파악하는 데 10배** 시간이 소요된다. 경험 많은 개발자는 "정신적 코드 지도"를 보유하지만, 에이전트는 매 세션 빈손으로 시작한다.

ARCHITECTURE.md는 이 정신적 코드 지도를 문서화하여 **매 세션 Glob/Grep 10회+를 1회 Read로 대체**한다.

## 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **나라 지도, 아틀라스 아님** | 모듈 간 관계와 경계를 보여주는 조감도. 각 모듈의 상세 동작은 별도 문서 |
| **짧게 유지** | 모든 기여자(에이전트 포함)가 읽어야 한다. 길면 안 읽힌다 |
| **검색 가능한 심볼** | 직접 링크(`src/foo/bar.rs:42`) 대신 검색 가능한 이름(`FooProcessor`) 사용. 코드가 변해도 이름은 유지 |
| **low-effort, high-leverage** | 연 수회 검토로 충분. 완벽한 동기화를 추구하지 않는다 |

## 필수 섹션

### 1. Bird's Eye View (조감도)

프로젝트가 해결하는 문제를 1-2문단으로 설명한다. 사용자 관점에서의 핵심 기능.

```markdown
## Bird's Eye View

foo-server는 실시간 이벤트 스트림을 수집, 변환, 라우팅하는 데이터 파이프라인이다.
프로듀서(외부 서비스)가 HTTP/gRPC로 이벤트를 전송하면, 변환 레이어를 거쳐
다수의 컨슈머(분석 DB, 알림 서비스, 아카이브)로 팬아웃한다.
```

### 2. Codemap (코드 지도) — 핵심 섹션

"X를 하는 것은 어디에?" 질문에 답하는 지도. **디렉토리 트리 나열이 아닌, 모듈 간 관계와 역할 중심**.

각 주요 모듈/패키지에 대해:
- **이름** (코드에서 grep 가능한 심볼)
- **1-2줄 역할 설명**
- **다른 모듈과의 관계** (의존 방향)

```markdown
## Codemap

`ingestion/` — HTTP/gRPC 엔드포인트. 외부 이벤트를 `RawEvent`로 파싱.
  → `transform/`에 의존

`transform/` — `RawEvent`를 `ProcessedEvent`로 변환. 변환 규칙은 `TransformPipeline`에 등록.
  → `routing/`에 의존, `ingestion/`에서 호출됨

`routing/` — `ProcessedEvent`를 대상 컨슈머에 팬아웃. `Router` trait이 핵심 추상화.

`storage/` — 이벤트 아카이브. `routing/`의 컨슈머 중 하나.

`config/` — 전체 설정. `AppConfig`가 진입점. 다른 모든 모듈이 의존.
```

작성 요령:
- BE↔FE 매핑이 있다면 명시 (e.g., "api/users/ ↔ components/UserForm")
- 핵심 타입/파일을 이름으로 언급하여 검색 가능하게
- 의존 방향을 화살표로 표시

### 3. Invariants (아키텍처 불변식)

아키텍처에서 **"존재하지 않는 것"**으로 표현되는 제약. 코드를 읽어서는 발견하기 어렵지만, 위반하면 아키텍처가 무너지는 규칙들.

**왜 불변식을 명시해야 하는가:**

의존성은 변경이 전파되는 방향이다. A가 B에 의존하면, B의 변경이 A에 영향을 준다. 의존 방향을 제어하지 않으면 한 모듈의 변경이 예측 불가능하게 시스템 전체로 퍼진다.

> "Source code dependencies can only point inwards." — Clean Architecture

불변식은 코드를 읽어선 발견할 수 없다 — "하지 않는 것"은 코드에 존재하지 않기 때문이다. 따라서 명시적 문서화가 필수이며, `resources/06-arch-test-tools.md`의 아키텍처 테스트로 기계적 검증까지 연결하면 드리프트를 방지할 수 있다.

**불변식 판단 기준:** "이 규칙이 깨지면 시스템에 실질적 문제가 생기는가?" — Yes면 불변식으로 명시, No면 불필요.

```markdown
## Invariants

- `transform/`은 I/O를 하지 않는다 — 순수 변환만. I/O는 `ingestion/`과 `routing/`의 책임
- `storage/`는 `ingestion/`에 직접 의존하지 않는다 — 반드시 `routing/`을 통해서만 이벤트를 받음
- 모든 외부 데이터는 `ingestion/` 경계에서 `RawEvent`로 파싱 — 하류 모듈은 raw 데이터를 직접 처리하지 않음
```

### 4. Cross-Cutting Concerns (횡단 관심사)

여러 모듈에 걸쳐 적용되는 패턴. 프로젝트에 해당하는 것만 포함.

```markdown
## Cross-Cutting Concerns

**에러 처리**: `AppError` enum으로 통합. `ingestion/`에서만 외부 에러를 HTTP 응답으로 변환.
**로깅**: `tracing` crate 사용. 모든 public 함수에 `#[instrument]` 적용.
**테스트**: `transform/`은 단위 테스트, `ingestion/`과 `routing/`은 통합 테스트.
```

## 포함/제외 가이드

| 포함 | 제외 |
|------|------|
| 모듈 이름과 역할 (1-2줄) | 각 모듈의 상세 동작 원리 |
| 모듈 간 관계/의존 방향 | 구현 세부사항 (알고리즘, 자료구조) |
| 아키텍처 불변식 (absences) | 직접 링크 (검색 가능한 이름으로 대체) |
| 계층/시스템 경계 | 자주 변경되는 세부사항 |
| 핵심 타입/파일 이름 (grep 가능) | 파일별 라인 수준 설명 |
| 횡단 관심사 패턴 | 코드 스니펫 |

## `rules/architecture.md`와의 관계

| 파일 | 역할 | 로딩 시점 |
|------|------|-----------|
| `ARCHITECTURE.md` | 전체 코드 지도 | 세션 시작 시 1회 Read |
| `.claude/rules/architecture.md` | 핵심 요약 (5-10항목) | 매 세션 자동 로드 |

`rules/architecture.md`는 ARCHITECTURE.md에서 가장 자주 참조되는 항목만 추출:
- "X 기능은 Y 디렉토리"
- "핵심 타입: Z"
- "불변식: A는 B에 의존하지 않는다"

## 작성 절차 (Setup Phase 1)

1. 프로젝트 루트에서 디렉토리 구조 스캔
2. 주요 설정 파일 확인 (package.json, build.gradle, Cargo.toml 등)
3. 엔트리포인트 추적하여 주요 흐름 파악
4. 4개 섹션 순서대로 작성: Bird's Eye View → Codemap → Invariants → Cross-Cutting
5. 검증: **"에이전트가 이것만 읽고 수정 위치를 찾을 수 있는가?"**

## 갱신 트리거

| 트리거 | 갱신 대상 |
|--------|-----------|
| 새 패키지/모듈 추가 | Codemap에 항목 추가 |
| 기존 모듈 삭제/병합 | Codemap에서 제거/갱신 |
| 의존 방향 변경 | Codemap 관계 갱신 |
| 새 불변식 도입/폐기 | Invariants 섹션 갱신 |
| 횡단 관심사 패턴 변경 | Cross-Cutting 섹션 갱신 |

갱신 빈도: 연 수회 검토로 충분. 완벽한 코드 동기화를 추구하지 않는다.

## 참고

- 원문: [matklad — ARCHITECTURE.md](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html)
- 모범 사례: [rust-analyzer architecture.md](https://github.com/rust-lang/rust-analyzer/blob/master/docs/dev/architecture.md)
