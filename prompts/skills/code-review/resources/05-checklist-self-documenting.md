# Self-Documenting / Executable Docs Checklist

코드가 스스로 문서 역할을 하는지, 그리고 남은 문서가 실행되는 형태인지 검증하는 언어 무관 체크리스트.

원칙 근거: `principles` 스킬의 `SELF-DOCUMENTING-CODE`(이름·구조), `PARSE-DONT-VALIDATE`(타입), `EXECUTABLE-DOCUMENTATION`(문서·구조 규칙).

판정 기준 한 줄: **"이 지식이 틀렸을 때 무엇이 깨지는가?"** — 아무것도 안 깨지면 결함이다.

## Checks

### Critical

- **문서·주석에만 존재하는 계약**: "null이면 안 됨", "양수만", "호출 전 init 필요"가 주석/README에만 있고 타입·파싱·검증 어디에도 없음. 컴파일러도 CI도 이 제약을 모르므로 위반이 조용히 통과됨 → 타입으로 이동
- **수기 편집된 생성물**: `openapi.yaml`, `schema.json`, ERD 등 코드에서 생성되어야 할 산출물이 손으로 커밋됨. 코드와 명세가 각각 진실 원천이 되어 드리프트 확정 (SSoT 위반)
- **검증 결과가 타입에 남지 않음**: `validateX(input): void\|boolean` 통과 후 동일 조건을 하류에서 재검사하거나 non-null 단언으로 덮음. 검사했다는 지식이 증발

### High

- **문서 코드블록이 테스트에 미포함**: README/docstring 예제가 어떤 테스트 명령으로도 실행되지 않음. 지금 동작하는지 아무도 모름
- **구조 규칙이 문서·다이어그램에만**: 계층·의존 방향·모듈 경계 규칙이 산문이나 그림으로만 존재하고 아키텍처 테스트가 없음 → 위반이 리뷰어 눈에만 의존
- **도메인 식별자가 원시 타입**: `userId: string`, `orderId: str` 등. 인자 순서를 바꿔도 컴파일되어 런타임에야 드러남
- **불법 상태가 타입상 표현 가능**: boolean 플래그 조합·전부 옵셔널인 필드로 상태를 표현. 존재해선 안 되는 조합이 만들어질 수 있음
- **제네릭 이름의 대형 클래스**: `*Service`, `*Manager`, `*Helper`, `*Util`이면서 public 메서드 다수 — 이름이 책임을 말하지 않아 무한 확장

### Medium

- **WHAT/HOW 설명 주석**: "이 함수는 ~한다" 류. Extract Method + 이름으로 대체 가능
- **단계 구분 주석**: `// 1단계`, `// --- 검증 ---` — 주석이 함수 경계를 대신하는 중
- **주석 처리된 코드 블록**: 실행되지 않는 예제/죽은 코드
- **매직 넘버·문자열**: 이름 없는 상수가 의미를 숨김
- **문서와 코드의 수정 시점 격차**: 같은 모듈의 문서가 코드보다 현저히 오래됨
- **PR 리뷰에서 같은 규약을 반복 지적**: 사람이 lint 역할을 대신하는 중 → 규칙으로 이동

## Detection Patterns

```
# Critical — 문서에만 있는 계약
주석/README에 제약 서술이 있는데 해당 심볼 주변에 타입 제약·guard·스키마가 없음
  예: "must not be empty" 주석 + 시그니처는 list[str]

# Critical — 수기 편집된 생성물
openapi.yaml / schema.json 등이 존재하면서 생성 스크립트(just/npm script/Makefile 타깃)가 없음
또는 생성 스크립트가 있는데 산출물이 직접 수정된 커밋 이력이 있음

# Critical — 정보를 버리는 검증
validateX(...) 반환 타입이 void/boolean
  + 호출부 이후에 같은 조건 재확인(?. / if x is None / !!) 존재

# High — 실행되지 않는 문서 예제
README/docstring에 코드블록 존재
  + 테스트 설정에 doctest 러너 없음
    Python: pyproject/pytest.ini에 --doctest-modules, pytest-codeblocks, mktestdocs 부재
    Rust:   README 예제에 대한 skeptic 설정 부재 (모듈 doctest는 cargo test 기본 포함)
    Go:     Example 함수 부재

# High — 구조 규칙 미강제
ARCHITECTURE.md/README에 계층·의존 규칙 서술 존재
  + 아키텍처 테스트 부재 (감지 절차는 harness-engineering resources/06-arch-test-tools.md)

# High — 원시 타입 식별자 / 불법 상태
시그니처의 *Id 인자 타입이 string/str/Long
동일 타입 인자 2개 이상이 연속 (transfer(from, to) 둘 다 string)
전부 옵셔널인 필드 3개 이상으로 상태 표현
```

## Grep Patterns

```
# 문서에만 있는 제약 (주석 안의 계약 서술)
(?i)(must not|should not|반드시|하면 안|필수|null이면|비어있으면)

# 정보를 버리는 검증 함수
(function|def|fun|func)\s+(validate|check|assert|ensure)\w*

# 검사 결과 소실 흔적
!\.|\bas\s+\w+|!!|\.unwrap\(\)|cast\(

# 원시 타입 도메인 식별자
\w*[Ii]d\s*:\s*(string|str)\b|\w*_id\s*:\s*str\b

# 제네릭 이름 클래스
(class|interface|type)\s+\w*(Service|Manager|Helper|Util|Data|Processor)\b

# WHAT/HOW 주석 · 단계 구분 주석
^\s*(//|#)\s*\d+\s*(단계|step)|^\s*(//|#)\s*-{2,}

# 주석 처리된 코드
^\s*(//|#)\s*\w+\s*[({=]

# 생성물이어야 할 명세
openapi\.(ya?ml|json)|swagger\.(ya?ml|json)|schema\.json

# doctest 러너 설정 여부
--doctest-modules|pytest-codeblocks|mktestdocs|phmdoctest|skeptic
```

## 심각도 조정

- 내부 전용 스크립트·일회성 도구는 한 단계 낮춘다
- 공개 API·모듈 경계·외부 입력 처리 경로는 한 단계 올린다
- 레거시 영역은 "이번 변경이 만진 범위"로 한정한다 — 전체 강제는 잘못된 타입/테스트만 양산

## Output 연계

발견 항목은 `INSTRUCTIONS.md`의 Output Format을 그대로 따르되, 각 항목에 **어느 층위로 내려보낼 수 있는지**를 함께 제시한다:

```
타입 → 테스트·예제 → fitness function → 생성 명세 → (남으면) 수기 문서
```

예: `[Critical] src/user.ts:42 - "빈 배열 금지"가 주석에만 존재 → NonEmptyList 타입으로 이동 (PARSE-DONT-VALIDATE)`
