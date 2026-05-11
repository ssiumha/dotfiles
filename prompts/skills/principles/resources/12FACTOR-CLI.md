---
name: 12FACTOR-CLI
full_name: "12 Factor CLI Apps"
category: tooling
origin: Jeff Dickey (heroku/oclif), 2018, "12 Factor CLI Apps". POSIX·GNU CLI 관습 + clig.dev의 모던 정리
one_liner: "현대 CLI는 12개 factor를 패키지로 만족해야 — help, flags, version, streams, errors, fancy, prompts, tables, speed, contrib, subcommands, XDG"
---

# 12FACTOR-CLI — 모던 CLI 12계명

## 정의

> "Everyone needs to use the command line at some point... Make sure to write your CLI well." — Jeff Dickey

12 Factor CLI Apps는 **현대적 CLI 도구 사용자 경험**을 위한 12개 설계 원칙이다. 12 Factor App(SaaS 배포 원칙, 2011)에서 영감을 받아 CLI 도구 설계에 같은 형식을 적용한 것.

핵심 주장: **CLI는 GUI보다 발견성이 낮다.** GUI는 메뉴/버튼이 보이지만 CLI는 안 보인다. 그래서 도움말·관습·에러 메시지·구조화 출력 같은 **affordance**가 GUI보다 더 중요하다.

12개는 패키지로 의미를 가진다. 부분 적용은 점수 절반.

## 12 Factor

### 1. Great Help

CLI는 도움말이 살길이다. GUI 사용자는 메뉴에서 옵션을 발견하지만 CLI 사용자는 도움말이 부실하면 도구 자체를 못 쓴다.

- `mycli`, `mycli --help`, `mycli help`, `mycli -h` 모두 도움말 출력
- `-h, --help`는 **도움말 전용** — 다른 용도 금지
- 명령 설명, argument/flag 설명, **사용 예제** 포함
- 셸 자동완성 제공 (bash/zsh/fish completion)
- man page에만 의존 금지 (Windows 미지원, 신규 개발자 발견성 낮음)

### 2. Prefer Flags to Arguments

여러 종류의 입력이 있으면 위치 인자보다 플래그가 명확하다.

```
❌ heroku fork FROMAPP --app TOAPP    # 두 종류 인자 혼재
✅ heroku fork --from FROMAPP --to TOAPP
```

- 같은 종류의 다중 인자는 위치 인자 OK (`rm file1 file2`)
- 서로 다른 2종류 이상이면 플래그
- 3종류 이상은 거의 항상 실패
- `--`로 파싱 종료 + 나머지를 하위 도구에 위임 지원
- 자동완성은 플래그 기반이 훨씬 쉬움

### 3. What Version Am I On?

`mycli version`, `mycli --version`, `mycli -V` 모두 버전 출력.

- 단일 명령 CLI에서 `-v`가 verbose가 아니라면 version 용도로
- 버전 번호 외 **추가 디버그 메타데이터** 포함 (OS, runtime 버전, 빌드 해시 등)
- HTTP 요청을 보내는 CLI는 User-Agent에 버전 포함 (서버측 디버깅)

### 4. Mind the Streams

> "stdout is for output, stderr is for messaging."

- **stdout**: 데이터/결과 (파이프로 흘러갈 것)
- **stderr**: 경고, 진행 상황, 진단 메시지

```bash
myapp > foo.txt        # 결과만 파일로
                       # 진행률·경고는 화면에 그대로
```

서브프로세스의 stderr는 사용자 화면에 그대로 통과시킨다.

### 5. Handle Things Going Wrong

CLI에선 에러가 일상이다. 에러 메시지를 **5요소**로 만든다:

1. **에러 코드** (e.g. `EPERM`)
2. **에러 제목** (한 줄 요약)
3. **상세 설명** (선택)
4. **고치는 방법** (구체적 명령)
5. **참고 URL**

```
Error: EPERM Invalid permissions on myfile.out

Cannot write to myfile.out — file owned by root.

Fix with: chmod +w myfile.out
More: https://example.com/docs/eperm
```

- `DEBUG=*` 같은 환경변수로 풀 traceback 토글
- 컴포넌트별 verbose 로깅 (npm `debug` 모듈 패턴)
- 에러 로그에 timestamp + 주기적 truncate + ANSI 코드 strip

### 6. Be Fancy!

색상·spinner·progress bar는 **TTY일 때만**.

- `stdout.isatty()` 체크 → 파이프면 ANSI 끔
- `TERM=dumb`, `NO_COLOR` 환경변수, `--no-color` 플래그 존중
- 앱 전용 환경변수도 (`MYAPP_NOCOLOR=1`)
- 매우 긴 작업은 OS 알림(notification) 고려

ANSI 코드를 파일로 흘리는 건 즉시 FAIL.

### 7. Prompt If You Can

인터랙티브 환경이면 프롬프트로 입력받되, **강제하지 않는다**.

- `stdin.isatty()` 체크 → 파이프/CI에선 프롬프트 안 함
- 모든 프롬프트는 **플래그로 우회 가능** (자동화 호환)
- 파괴적 작업은 확인 (`type the app name to confirm deletion`)
- 시각적 선택(checkbox/radio) UI 활용

```bash
mycli delete myapp                  # 인터랙티브: 확인 프롬프트
mycli delete myapp --confirm        # 자동: 즉시 실행
```

### 8. Use Tables

표 형태 출력은 **파이프 친화적**으로.

- 한 행 = 한 데이터, 테두리 없음 (noisy)
- `wc -l`로 카운트, `grep`으로 필터 가능해야
- 기본은 핵심 컬럼만, `--columns x,y,z`로 커스텀
- 화면 폭 초과는 truncate, `--no-truncate`로 해제
- `--no-headers`, `--filter`, `--sort`, `--csv`, `--json` 지원
- 다중 컬럼 sort, 역순 sort

`--json`은 jq 파이프를 위해 표와 동시 제공.

### 9. Be Speedy

CLI 시작 시간은 사용자 경험을 직격한다.

| 시작 시간 | 평가 |
|-----------|------|
| <100ms | 매우 빠름 (스크립트 언어로 어려움) |
| 100-500ms | **목표 범위** |
| 500ms-2s | 받아들일 만하나 인상적이지 않음 |
| 2s+ | 사용자가 회피하기 시작 |

- `time mycli` 벤치마크
- 긴 작업엔 spinner/progress bar로 **체감 속도** 개선
- 명령 모듈 lazy-load (전체 코드 로드 금지)
- spinner 자체가 perceived speed를 높임

이건 PREMATURE-OPTIMIZATION의 예외 — 시작 속도는 직접 측정·최적화 대상이다.

### 10. Encourage Contributions

오픈소스로 공개하면 커뮤니티와 조직 평판 모두 강화된다.

- GitHub/GitLab 공개
- LICENSE 명시 (https://choosealicense.com/)
- 로컬 셋업과 테스트 실행 문서화
- Contributing 가이드 (커밋 규칙, 코드 품질, 테스트)
- Code of Conduct (포용성 신호 + 갈등 해소)
- **플러그인 시스템**으로 커뮤니티 확장 허용

### 11. Be Clear About Subcommands

명령 계층 패턴을 일관되게.

- 단순 도구는 단일 명령 (`cp`, `grep`)
- 복잡한 도구는 다중 명령 (`git`, `npm`)
- 인자 없으면: 다중 명령은 서브커맨드 목록, 단일 명령은 도움말
- **콜론 vs 공백**: 토픽-서브커맨드 구분
  - 공백: `git submodule add` (토픽 자체에 인자 못 받음)
  - 콜론: `heroku domains:add` (토픽 인자 가능)

콜론은 "argument 1이 명령"임을 명확히 한다. 공백은 토픽 레벨 인자에서 모호함.

### 12. Follow XDG Spec

설정·데이터·캐시 위치는 플랫폼 표준 따른다.

| 종류 | Unix/Linux | macOS | Windows |
|------|-----------|-------|---------|
| 설정 | `~/.config/myapp` (`$XDG_CONFIG_HOME`) | 같음 | `%APPDATA%\myapp` |
| 데이터 | `~/.local/share/myapp` (`$XDG_DATA_HOME`) | `~/Library/Application Support/myapp` | `%LOCALAPPDATA%\myapp` |
| 캐시 | `~/.cache/myapp` (`$XDG_CACHE_HOME`) | `~/Library/Caches/myapp` | `%LOCALAPPDATA%\myapp\Cache` |

`~/.myapprc` 같은 홈 디렉토리 dotfile은 XDG 등장 이전 패턴 — 신규 도구는 XDG 따른다.

## 핵심 판단

각 factor에 대해 PASS/FAIL 한 줄 체크:

| # | 체크 |
|---|------|
| 1 | `mycli`/`-h`/`help` 모두 도움말 출력? 예제 포함? |
| 2 | 서로 다른 2종 인자가 위치로 전달되지 않는가? |
| 3 | `--version` 동작? 메타데이터 포함? |
| 4 | 결과는 stdout, 진행/에러는 stderr? |
| 5 | 에러에 코드·제목·해결책·URL 모두 있나? |
| 6 | 파이프할 때 ANSI 자동 꺼짐? `NO_COLOR` 존중? |
| 7 | TTY 아니면 프롬프트 생략? 모든 프롬프트가 플래그로 우회 가능? |
| 8 | 표가 `grep`/`wc` 친화적? `--json` 있나? |
| 9 | 시작 시간 500ms 이하? lazy-load? |
| 10 | LICENSE·CONTRIBUTING·플러그인 시스템? |
| 11 | 서브커맨드 패턴(콜론 또는 공백) 일관? |
| 12 | XDG 디렉토리 준수? |

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| help 부재 | `mycli --help` exit code != 0 또는 출력 빈약 |
| 위치 인자 혼재 | `--help`에 위치 인자 2종 이상 |
| version 미지원 | `mycli --version` 동작 안 함 |
| stdout 오염 | `mycli ... > /dev/null` 후에도 진행률 보임 |
| ANSI 누수 | `mycli ... \| cat`에 색상 코드 |
| 시작 속도 | `time mycli --help` >500ms |
| dotfile rc | `~/.myapprc` 사용, XDG 무시 |

### 판단 필요

| 신호 | 설명 |
|------|------|
| 에러 메시지가 한 줄 | code/fix/url 누락 — 사용자 막막 |
| CI에서 멈춤 | 프롬프트가 자동화 차단 |
| 표를 grep 못 함 | 테두리·정렬 공백이 파싱 방해 |
| 서브커맨드가 자동완성 안 됨 | 토픽-명령 모호성 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 12개 중 10개 이상 충족 |
| **WARN** | 7-9개 충족, 누락된 것이 #4·#6·#7 같은 사용자 영향 큰 항목 아님 |
| **FAIL** | 6개 이하 또는 #1·#4·#5 중 하나라도 미충족 (사용자 차단) |

## 설계 패턴

### 단일 명령 CLI 베이스라인

```
mycli [INPUT] [--flag VALUE]

# 도움말
mycli --help, -h, mycli help

# 버전
mycli --version, -V

# 출력
stdout: 결과 (파이프 친화)
stderr: 진행 상황·에러

# 에러
$ mycli broken-input
Error: EVALIDATION Input must be JSON

The provided input is not valid JSON.

Fix with: pipe valid JSON to stdin
More: https://example.com/docs/input-format

# Exit code
0 정상, 1 일반 에러, 2 사용법 에러
```

### 다중 명령 CLI 베이스라인

```
mycli [topic[:subcommand]] [args] [--flags]

# 토픽 목록
mycli                       → 토픽 목록 (도움말이 아님 — 도움말은 --help)

# 토픽 도움말
mycli topic --help          → 해당 토픽의 서브커맨드 목록
mycli topic:sub --help      → 해당 명령의 상세

# Output
mycli list                  → 사람용 표 (TTY)
mycli list --json           → 기계용 (jq 친화)
mycli list | grep foo       → 필터 (ANSI 자동 꺼짐)
```

### XDG 경로 결정

```python
import os, platform

def config_dir(app: str) -> str:
    if platform.system() == "Windows":
        return os.path.join(os.environ["APPDATA"], app)
    return os.path.join(
        os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"),
        app,
    )
```

## UNIX-PHILOSOPHY와의 관계

UNIX-PHILOSOPHY는 **조합성/기계 인터페이스**, 12FACTOR-CLI는 **사용자 인터페이스/관습**. 짝을 이룬다.

| 관점 | UNIX-PHILOSOPHY | 12FACTOR-CLI |
|------|-----------------|--------------|
| 시점 | 1978 (McIlroy) | 2018 (Dickey) |
| 초점 | 도구 간 조립 | 사람-도구 affordance |
| 스트림 | "텍스트 = 범용 인터페이스" | stdout/stderr 분리 + JSON |
| TTY | 감지 = 의무 | NO_COLOR·프롬프트·spinner 분기 |
| 에러 | "Repair" (Raymond) | code/title/fix/url 5요소 |

겹침: #4(streams), #6(tty), #8(json) 세 항목은 두 원칙 모두 다룸. 12FACTOR-CLI가 더 구체적·현대적.

## 주의

### "패키지로 의미"

12개 중 일부만 적용하면 사용자 경험이 일관되지 않다. 예:
- help는 좋은데 stdout/stderr 안 나뉨 → 파이프에서 도움말 깨짐
- json 출력은 있는데 색상이 파이프로 흐름 → jq 파싱 실패
- 빠른 시작인데 에러는 한 줄 → 빠르게 막막해짐

부분 적용은 PASS 점수 절반.

### TUI 도구는 일부 예외

`htop`, `fzf` 같은 풀스크린 TUI는 #4(streams)·#8(table) 의미가 다르다. **사람-기계 경계 자체가 목적**인 도구는 별도 카테고리로 본다.

### 12FACTOR-APP과 다름

12 Factor App (Heroku, 2011)은 SaaS 배포 원칙. 12 Factor CLI는 명령줄 도구 UX 원칙. 영감만 공유, 내용은 별개.

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| UNIX-PHILOSOPHY | 짝 — 조합성(UNIX) + UX(12FACTOR-CLI) |
| CONVENTION-OVER-CONFIG | XDG·기본값·플래그 구조 모두 관례 적용 |
| PROGRESSIVE-DISCLOSURE | help의 점진적 노출, `--columns` 같은 고급 옵션 |
| POLA | 관습(`-h`/`--version`/`-V`)이 곧 POLA |
| FAIL-FAST | 에러 5요소는 fail-fast의 사용자 친화 버전 |
| POSTELS-LAW | 관대한 입력(stdin/파일/플래그) + 엄격한 출력(stdout 순수) |
| KISS | 단일 명령 CLI 우선 — 복잡도가 정당화될 때만 다중 명령 |

## 참고

- 원전: https://jdxcode.medium.com/12-factor-cli-apps-dd3c227a0e46
- 보강: https://clig.dev/ (Command Line Interface Guidelines, 2020)
- 관련 도구: oclif (heroku, ~150ms 시작), Cobra (Go), Click (Python)
