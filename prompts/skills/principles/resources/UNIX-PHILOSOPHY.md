---
name: UNIX-PHILOSOPHY
full_name: "Unix Philosophy"
category: tooling
origin: Doug McIlroy (1978), 정리는 Eric Raymond *The Art of Unix Programming* (2003)
one_liner: "하나만 잘하는 프로그램을 만들고, 조합 가능하도록 설계하고, 텍스트 스트림으로 연결하라"
---

# UNIX-PHILOSOPHY — 유닉스 철학

## 정의

Doug McIlroy의 원전 3계명:

> 1. Write programs that do one thing and do it well.
> 2. Write programs to work together.
> 3. Write programs to handle text streams, because that is a universal interface.

하나의 프로그램이 모든 것을 하려는 대신, **작게 만들고 파이프로 조립**한다. 이것이 40년 넘게 유닉스 도구 생태계를 지탱한 설계 철학이다.

## 핵심 판단

- **"이 도구가 하나의 개념을 하는가?"** — 설명에 "and"가 두 번 이상이면 위반
- **"다른 도구와 파이프로 조합 가능한가?"** — stdin 받고 stdout 내보내는가?
- **"출력이 기계가 파싱할 수 있는가?"** — 색상·이모지·테이블 장식이 파이프를 깨뜨리지 않는가?

## SRP와의 구분

SRP와 비슷해 보이지만 **프레이밍이 다르다**:

| | SRP (design) | Unix Philosophy (tooling) |
|---|---|---|
| 관심사 | 변경 이유 | **조합성** |
| 단위 | 클래스/모듈 | **프로그램/도구** |
| 측정 | 책임 개수 | **파이프 친화성** |
| 실패 형태 | God class | **기능 합체 CLI** ("`tool build deploy rollback`") |

SRP는 "왜 바뀌는가"를 묻고, Unix Philosophy는 "어떻게 조립되는가"를 묻는다.

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| 서브커맨드 20개+ | `tool --help` 라인 수 |
| stdin 미지원 | 파일 인자만 받고 `-` 로 파이프 못 받음 |
| stdout에 색상/장식/프로그레스바 | tty 감지 없이 ANSI 코드 출력 |
| 결과와 로그가 같은 스트림 | stdout/stderr 분리 부재 |
| 구조화 출력 옵션 부재 | `--json`, `--yaml` 없음 |

### 판단 필요

| 신호 | 설명 |
|------|------|
| "이 도구로 다 할 수 있어요" | 기능 범람 |
| `tool a \| tool b` 대신 `tool a-then-b` 신설 | 조합보다 신규 서브커맨드 |
| 대화형 프롬프트가 파이프에서 멈춤 | 비인터랙티브 감지 부재 |
| 진행률이 파이프로 흘러감 | stderr 써야 할 것을 stdout에 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 단일 목적 명확, stdin/stdout 파이프 가능, `--json` 제공, stderr 분리 |
| **WARN** | 일부 서브커맨드가 개념 혼재 OR 파이프 출력에 장식 포함 |
| **FAIL** | 기능 과다 합체 OR stdin 무시 OR stdout 오염 |

## 설계 패턴

### 1. 하나만 한다 — 명확한 동사 하나

```
❌ mytool build-and-deploy --rollback-on-failure
✅ mybuild | mydeploy --rollback

❌ git: 이미 "하나"가 아니지만, 각 서브커맨드는 독립적
✅ jq: JSON 쿼리 하나만. 나머지는 파이프로
```

### 2. 텍스트 스트림 = 범용 인터페이스

```bash
# 좋은 예: 조합 가능
cat access.log | grep ERROR | awk '{print $4}' | sort | uniq -c

# 나쁜 예: 자체 포맷만
mytool analyze --show-errors --group-by-ip --count
# (나중에 다른 관점이 필요하면 옵션 추가해야)
```

### 3. stdout vs stderr 분리

- **stdout**: 결과 (파이프로 흘러갈 것)
- **stderr**: 진행 상황, 로그, 에러 (사람이 보는 것)

```python
# ❌
print(f"Processing... {item}")  # 파이프 오염
print(result)                   # 진짜 결과

# ✅
print(f"Processing... {item}", file=sys.stderr)
print(result)
```

### 4. 구조화 출력 지원

사람이 보기 좋은 표 + 기계가 파싱할 JSON 동시 제공:

```bash
mytool list              # 사람용 — 표, 색상
mytool list --json       # 기계용 — jq 파이프 가능
mytool list --no-color   # tty 아니면 자동 꺼짐
```

### 5. tty 감지

```python
if sys.stdout.isatty():
    # 사람이 보는 중 — 색상, 프로그레스바 OK
else:
    # 파이프 중 — 순수 데이터만
```

## 17계명 요약 (Raymond)

Unix Philosophy는 Raymond가 17 rules로 정리했다. 본 원칙은 핵심 5개를 흡수한 버전:

| Rule | 내용 | 본 카탈로그 매핑 |
|------|------|------------------|
| Modularity | 단순 부품 + 깔끔한 인터페이스 | UNIX-PHILOSOPHY + SoC |
| Clarity | 영리함보다 명확함 | KISS |
| Composition | 조합되도록 설계 | UNIX-PHILOSOPHY |
| Simplicity | 단순하게 | KISS |
| Silence | 놀랄 일 없으면 조용히 | (생략, 원하면 추가) |
| Repair | 실패는 명확히 | FAIL-FAST + Repair 일부 |
| Least Surprise | 놀라게 하지 마라 | POLA |
| Transparency | 관찰 가능하게 | (기본 덕목) |
| Robustness | 강건함은 투명성·단순함의 자식 | POSTELS-LAW + FAIL-FAST |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| SRP | 유닛 레벨에서 같은 방향이나 프레이밍이 다름 (위 비교표) |
| KISS | Simplicity는 Unix Philosophy의 기둥 |
| POLA | Least Surprise = POLA의 CLI 버전 |
| POSTELS-LAW | 입력 관대·출력 엄격은 파이프의 기본 |
| CONVENTION-OVER-CONFIG | 사용자 진입 장벽을 낮추는 상보적 원칙 |
| PROGRESSIVE-DISCLOSURE | 단일 목적 유지하면서 고급 기능 노출 방법 |
| 12FACTOR-CLI | 짝 — UNIX는 조합성/기계 인터페이스, 12FACTOR-CLI는 사용자 인터페이스(help·errors·XDG 등). #4·#6·#8은 두 원칙 모두 다룸 |

## 주의

- "하나만 한다"가 코드 줄 수 제한이 아니다. `git`은 큰 도구지만 각 서브커맨드는 명확히 하나를 한다
- 텍스트 스트림 원칙은 1978년 기준. 현대는 **JSON/구조화 출력도 텍스트 스트림**으로 간주한다
- 대화형 TUI(htop, fzf)는 이 철학의 의도된 예외. 사람-기계 경계 자체가 목적인 도구
- 기능을 쪼개라는 뜻이지, 기능을 줄이라는 뜻이 아니다
