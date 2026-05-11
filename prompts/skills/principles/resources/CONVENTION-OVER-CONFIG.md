---
name: CONVENTION-OVER-CONFIG
full_name: "Convention over Configuration"
category: tooling
origin: David Heinemeier Hansson (Ruby on Rails, 2004). 이전 개념은 Maven (2003)의 "sensible defaults"
one_liner: "합리적 기본값으로 90%를 해결하고, 벗어나는 10%만 설정하게 하라"
---

# CONVENTION-OVER-CONFIG — 관례 우선, 설정은 최소

## 정의

> "You only need to specify unconventional aspects of the application."

사용자가 모든 것을 결정하게 하지 말고, 합리적 기본값으로 대부분의 경우를 자동으로 올바르게 만든다. 관례에서 벗어날 때만 설정으로 오버라이드할 수 있게 한다.

## 핵심 판단

- **"첫 실행에 필요한 입력이 몇 개인가?"** — 많으면 진입 장벽
- **"기본값이 틀렸을 때 얼마나 자주인가?"** — 드물면 관례가 맞다
- **"자주 바뀌는 것이 기본값에 하드코딩되어 있는가?"** — 그렇다면 설정으로 빼야

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| 필수 플래그 5개+ | `tool <subcmd>` 만으로 동작 시도 시 에러 |
| 설정 파일 없으면 죽음 | `.toolrc` 없이 실행 실패 |
| 기본값 없는 옵션 다수 | `--help` 에 `(required)` 다수 |
| 환경변수 하드 의존 | 미설정 시 의미불명 에러 |

### 판단 필요

| 신호 | 설명 |
|------|------|
| "처음 쓰려는데 튜토리얼부터 봐야 해" | 진입 장벽 과다 |
| 모든 프로젝트가 같은 옵션 복붙 | 그게 곧 기본값 |
| `init` 커맨드가 질문 20개 쏟아냄 | 기본값 부족 |
| 문서 1페이지가 옵션 목록 | 관례 부재 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 설정 없이 typical case 동작, 기본값이 문서화, 오버라이드 경로 명확 |
| **WARN** | 일부 흔한 경우에 필수 설정 OR 기본값이 비직관적 |
| **FAIL** | 설정 없으면 아무것도 안 됨 OR 기본값이 대부분 사용자에게 틀림 |

## 설계 패턴

### 1. Zero-config 첫 실행

```
❌ mytool run
   Error: --input required, --output required, --format required

✅ mytool run
   → 현재 디렉토리에서 찾을 수 있는 것 자동 감지
   → stdout으로 기본 포맷 출력
```

### 2. 설정의 점진적 공개 (계층)

우선순위 (위로 갈수록 강함):

```
1. 기본값 (코드 내장)          ← 설정 없이 동작
2. 프로젝트 설정 파일           ← .toolrc, pyproject.toml
3. 환경변수                    ← TOOL_X=Y
4. CLI 플래그                  ← --x Y
```

가장 자주 바뀌는 것을 가장 쓰기 쉬운 층에 둔다.

### 3. 관례를 코드가 아닌 **문서와 경로**로 표현

```
# Rails 예시
app/controllers/users_controller.rb  ← 관례적 경로
  class UsersController             ← 관례적 이름
    def index                       ← /users GET 자동 라우팅
```

설정 없이 경로·이름만으로 연결되게 한다.

### 4. 오버라이드 경로 명시

관례에 맞지 않는 경우를 막지 말고 **쉬운 탈출구**를 제공:

```yaml
# pyproject.toml
[tool.black]
line-length = 120  # 관례(88)에서 벗어남 — 한 줄로 오버라이드
```

### 5. 감지 우선, 설정은 최후

```python
# ❌ 사용자에게 물어봄
language: str = config.get("language")

# ✅ 자동 감지 + 필요 시 오버라이드
language = detect_from_files() or config.get("language") or "python"
```

예: `black`이 `pyproject.toml` 자동 탐색, `cargo`가 `Cargo.toml` 자동 발견, `git` 명령이 `.git` 위치 자동 탐색

## Rails 효과

Rails가 등장하기 전 자바 프레임워크는 XML 설정 파일이 수백 줄이었다. Rails는 "이름 규칙 = 연결 규칙"으로 바꿔 **설정을 거의 없앴다**. 같은 일을 CLI·도구·라이브러리에 적용한다.

## 주의

### 관례가 **틀렸을 때** 비용

관례가 현실과 안 맞으면 오버라이드가 어렵거나 숨겨져 있어 더 나쁠 수 있다. 관례 선택은:
- **80% 이상에게 맞아야** 관례 자격 있음
- **100%가 아니므로** 반드시 오버라이드 경로 존재
- **드물게 바뀌어야** — 관례 변경은 브레이킹 체인지

### YAGNI와의 관계

"지금 필요 없는 옵션은 만들지 마라"는 YAGNI. 본 원칙은 "지금 필요해 보이는 옵션도 **관례로 흡수 가능하면** 만들지 마라". 더 강한 주장.

### 설정 제로가 목표가 아니다

일부 도구는 본질적으로 사용자 의도를 알 수 없다. 그럴 땐 `init` 단계에서 한 번 물어보고 저장한다 (관례를 **생성**).

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| KISS | 기본값 단순화의 한 방식 |
| YAGNI | 옵션을 늘리기 전에 관례로 해결되는지 봄 |
| POLA | 관례가 사용자 기대와 일치해야 POLA 준수 |
| UNIX-PHILOSOPHY | "처음 쓸 때 조합 가능" 위해 진입 장벽 낮춤 |
| PROGRESSIVE-DISCLOSURE | 기본값 = 초보, 오버라이드 = 전문가 |
| GOODHARTS-LAW | "설정 옵션 수" 지표가 목표가 되면 역효과 |

## 주의 2 — 현대적 맥락

- CLI 도구는 `--config-file` 경로까지 관례화 권장 (XDG Base Directory)
- SDK/라이브러리는 기본 인스턴스 + `client = Client()` 로 동작, 고급은 `Client(config=...)`
- 웹 프레임워크는 라우팅·폴더 구조를 관례로 (Next.js의 `pages/`, Rails의 MVC)
