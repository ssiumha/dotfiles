---
name: PROGRESSIVE-DISCLOSURE
full_name: "Progressive Disclosure"
category: tooling
origin: Jakob Nielsen (UX, 1994). 소프트웨어 맥락에서는 Larry Wall의 "Easy things easy, hard things possible" (Perl)
one_liner: "초보에겐 단순하게, 전문가에겐 강력하게 — 복잡도는 필요한 사람에게만 노출한다"
---

# PROGRESSIVE-DISCLOSURE — 점진적 공개

## 정의

> "Easy things should be easy, and hard things should be possible." — Larry Wall

모든 사용자가 동시에 모든 기능을 볼 필요는 없다. 기본 경로는 **간단하게**, 고급 기능은 **발견 가능하되 기본에서 숨김**. 사용자가 성장하면서 더 깊이 들어갈 수 있게 한다.

## 핵심 판단

- **"첫 실행의 인지 부하는?"** — 초보가 바로 쓸 수 있는가
- **"전문가에게 천장이 있는가?"** — 깊이 들어가면 제어할 수 있는가
- **"중급 기능의 발견 경로는?"** — 숨겨졌어도 찾을 수 있는가

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| `--help` 가 200줄+ | wc -l 로 검사 |
| 플래그 30개+ 평면 나열 | 그룹핑·계층 없음 |
| 단축 옵션 없음 | `-v` 없이 `--verbose` 만 강제 |
| 긴 옵션 없음 | `-v` 만 있고 의미 추론 불가 |
| 핵심 기능 플래그에 depth | 가장 흔한 것이 `--experimental-mode-2-enable` |

### 판단 필요

| 신호 | 설명 |
|------|------|
| "튜토리얼 읽어야 첫 실행" | 기본 경로가 너무 비쌈 |
| "이 기능 있는지 몰랐어" | 발견 경로 부재 |
| 전문가가 스크립트로 우회 | 고급 경로 차단됨 |
| 문서가 초보/전문가 구분 없음 | 한 화면에 다 쏟아냄 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 기본 경로 <3단계, `--help`는 핵심만, 고급 기능은 서브커맨드/플래그로 깊이 있게 접근 |
| **WARN** | 도움말 일부가 과다 노출 OR 단축/긴 옵션 중 하나만 있음 |
| **FAIL** | 초보가 첫 실행 불가 OR 전문가가 스크립트/포크로 우회 |

## 설계 패턴

### 1. 계층적 `--help`

```
$ mytool --help          # 핵심 5-10개만. "자세히: mytool help <subcmd>"
$ mytool help build      # build 관련 옵션만
$ mytool --help-all      # 전체 (거의 볼 일 없음)
```

### 2. 단축 + 긴 옵션 둘 다

```
-v, --verbose            # 단축: 전문가 빠른 타이핑
                         # 긴 옵션: 초보 의미 이해
```

모든 주요 옵션에 둘 다. 단축만 있으면 초보가 모름, 긴 옵션만 있으면 전문가가 답답함.

### 3. 서브커맨드로 기능 계층화

```
mytool                   # 최상위
├── build               # 흔함
├── test                # 흔함
├── deploy              # 흔함
└── advanced            # 고급 기능 모음
    ├── profile
    └── inspect
```

`git`이 좋은 예 — `git commit`은 일상이지만 `git rev-parse`는 내부/스크립팅용.

### 4. 기본값이 이미 작동 → 플래그는 튜닝

```
mytool run                        # 기본값으로 작동
mytool run --workers 8            # 전문가가 튜닝
mytool run --advanced-scheduler   # 고급 경로
```

### 5. 숨김 플래그 / 실험 기능

```
mytool --help              # 안정 기능만 표시
mytool --help-experimental  # 실험 기능 노출
```

또는:

```
mytool build --experimental-incremental  # 이름 자체가 "여기는 불안정" 신호
```

### 6. 에러 메시지가 다음 단계 안내

```
❌ Error: command not found

✅ Error: 'buil' is not a command. Did you mean 'build'?
   Run 'mytool --help' to see available commands.
```

### 7. `init` 커맨드로 첫 경험 부드럽게

```
$ mytool init
→ "프로젝트 이름? [my-project]"
→ "언어? [python]"
→ "완료! mytool build 로 빌드해 보세요."
```

초보에게만 물어보고, 이후는 관례·설정으로 자동 진행.

## 문서에도 적용

```
README
  ├── Quick Start       # 초보 — 30초 안에 작동
  ├── Common Use Cases  # 일반 사용자
  └── Advanced Topics   # 전문가 — 깊은 동작 원리
```

첫 화면에 "설치 한 줄 + 실행 한 줄"이 보여야 한다.

## 안티패턴

### "전부 노출" 병

```
$ mytool --help
Usage: mytool [OPTIONS] COMMAND [ARGS]...

Options:
  --verbose / --no-verbose
  --color / --no-color
  --format [json|yaml|toml|...]
  --config-file PATH
  --log-level [DEBUG|INFO|...]
  ... (40줄 더)
```

### "문서 없이 찾아라" 병

고급 기능이 있지만 `--help`에도, 문서에도 없음. 소스 읽어야 발견.

### "초보 모드/전문가 모드" 토글

현대 CLI는 모드 토글보다 **자연스러운 깊이**를 선호. 모드는 상태 관리 비용.

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| CONVENTION-OVER-CONFIG | 기본값 = 초보 기본 경로, 설정 = 전문가 오버라이드 |
| POLA | 초보의 "예상"과 전문가의 "예상"이 다를 수 있음. 둘 다 최소 놀람 |
| UNIX-PHILOSOPHY | 단일 목적을 유지하면서도 고급 기능 노출하는 방법 |
| KISS | 첫 접촉 경로는 단순하게 |
| YAGNI | 고급 기능을 미리 만들지 말 것. 진짜 필요 시 Progressive Disclosure로 추가 |
| HYRUMS-LAW | 숨김 플래그도 사용되기 시작하면 API가 됨. "experimental" 표식 명확히 |

## 주의

- **발견 가능성**과 **숨김**의 균형: 숨겼지만 찾을 수는 있어야
- 모든 도구에 필요하지 않음: `cat`, `ls` 같은 단일 목적 도구는 평면 옵션이 맞음
- "초보를 너무 배려"가 전문가를 방해할 수 있다. 단축키·스크립팅 경로 유지 필수
- "모드" 기반 공개(어린이 모드/프로 모드)는 관리 비용이 커 일반적으로 피함
- GUI 원칙에서 온 개념이지만 CLI·API·라이브러리 모두에 유효
