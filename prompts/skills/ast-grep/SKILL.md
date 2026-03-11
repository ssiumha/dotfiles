---
name: ast-grep
description: Creates ast-grep patterns for structural code search. Use when finding functions/classes by structure, refactoring code, or when grep returns too many false positives.
---

# ast-grep Patterns

AST 기반 구조적 코드 검색을 지원합니다. 텍스트 매칭이 아닌 코드 구조로 정밀 검색.

**핵심 철학**:
- 구조적 검색: 코드의 의미 단위로 검색 (변수명, 함수 시그니처 등)
- 노이즈 제거: 주석, 공백, 포맷 차이 무시
- 언어 인식: 각 언어의 AST 구조에 맞는 패턴
- Grep 대체: 복잡한 정규식 대신 직관적 패턴

## Instructions

### 워크플로우 1: 패턴 작성

사용자 요청에서 파악:
1. **언어**: TypeScript, Python, Go, Rust 등
2. **대상**: 함수, 클래스, import, 변수 등
3. **조건**: 특정 이름, 패턴, 구조

기본 명령:
```bash
ast-grep --lang <language> -p '<pattern>'
```

### 워크플로우 2: 메타변수 활용

| 메타변수 | 의미 | 예시 |
|----------|------|------|
| `$NAME` | 단일 노드 캡처 | `function $NAME()` |
| `$_` | 단일 노드 (무시) | `import { $_ } from "react"` |
| `$$$` | 0개 이상 노드 | `function $NAME($$$) { $$$ }` |
| `$$ARGS` | 이름 붙인 다중 캡처 | `console.log($$ARGS)` |

### 워크플로우 3: 언어별 패턴

요청 언어에 따라 적절한 패턴 제공:

| 언어 | 확장자 | --lang 값 |
|------|--------|-----------|
| TypeScript | .ts, .tsx | typescript, tsx |
| JavaScript | .js, .jsx | javascript, jsx |
| Python | .py | python |
| Go | .go | go |
| Rust | .rs | rust |
| Java | .java | java |

## Quick Reference

### 필수 옵션

```bash
--lang <lang>       # 언어 지정 (필수)
-p '<pattern>'      # 패턴 (필수)
--json              # JSON 출력
-r '<replacement>'  # 대체 문자열
--rewrite           # 실제 파일 수정
-i                  # 대화형 모드
```

### 자주 쓰는 패턴

```bash
# 함수 정의
ast-grep --lang typescript -p 'function $NAME($$$) { $$$ }'

# 화살표 함수
ast-grep --lang typescript -p 'const $NAME = ($$$) => $$$'

# React 컴포넌트
ast-grep --lang tsx -p 'function $NAME($$$): JSX.Element { $$$ }'

# 특정 import
ast-grep --lang typescript -p 'import { $_ } from "react"'

# 클래스 정의
ast-grep --lang typescript -p 'class $NAME { $$$ }'

# console.log 찾기
ast-grep --lang javascript -p 'console.log($$$)'
```

## Examples

### 함수 찾기

**요청**: "fetchUser 함수 정의 위치"

```bash
ast-grep --lang typescript -p 'function fetchUser($$$) { $$$ }'
# 또는 화살표 함수도 포함
ast-grep --lang typescript -p 'const fetchUser = $$$'
```

### React Hook 사용 찾기

**요청**: "useState 사용하는 곳"

```bash
ast-grep --lang tsx -p 'const [$_, $_] = useState($$$)'
```

### API 엔드포인트 찾기

**요청**: "Express 라우트 핸들러"

```bash
ast-grep --lang typescript -p 'app.$METHOD($$$)'
# 또는 특정 메서드
ast-grep --lang typescript -p 'app.get($$$)'
```

### Python 데코레이터

**요청**: "@property 사용하는 메서드"

```bash
ast-grep --lang python -p '
@property
def $NAME(self):
    $$$
'
```

### Go 구조체

**요청**: "Error 인터페이스 구현"

```bash
ast-grep --lang go -p 'func ($_ $_) Error() string { $$$ }'
```

### 리팩토링 (대체)

**요청**: "console.log를 logger.debug로 변경"

```bash
ast-grep --lang typescript -p 'console.log($$$ARGS)' -r 'logger.debug($$$ARGS)'
# 미리보기 후 적용
ast-grep --lang typescript -p 'console.log($$$ARGS)' -r 'logger.debug($$$ARGS)' --rewrite
```

## vs Grep

| 상황 | Grep | ast-grep | 이유 |
|------|------|----------|------|
| 단순 텍스트 | ✅ 빠름 | 불필요 | 구조 분석 오버헤드 |
| 함수 정의 | ❌ 노이즈 | ✅ 정확 | 주석/문자열 내 false positive 제거 |
| 변수 추적 | ❌ 혼동 | ✅ 인식 | AST로 스코프 구분 |
| 리팩토링 | ❌ 불가 | ✅ `-r` | 구조 보존 대체 |

**선택 기준**: 구조가 중요하면 ast-grep, 텍스트만 찾으면 Grep

## Technical Details

- **공식 문서**: https://ast-grep.github.io/
- **지원 언어**: TypeScript, JavaScript, Python, Go, Rust, Java, C, C++, Kotlin 등
- **설치**: `brew install ast-grep` 또는 `cargo install ast-grep`

**skill 호출 vs 직접 사용**:
- 직접 사용: 단일 메타변수, 표준 함수/클래스 검색
- skill 호출: 리팩토링 (-r), 언어별 특수 구문, 조건부 매칭

### 고급 기능 리소스
- `resources/advanced-rules.md`: YAML 룰 시스템, Relational Rules(inside/has/follows), 보안 스캐닝 룰, CI 통합
