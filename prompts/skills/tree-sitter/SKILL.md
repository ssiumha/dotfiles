---
name: tree-sitter
description: AST parsing, S-expression queries, tag extraction via tree-sitter CLI. Use when parsing code into AST, extracting tags, visualizing syntax trees, or performing structural analysis beyond ast-grep.
---

# tree-sitter CLI

tree-sitter CLI로 AST 덤프, S-expression 쿼리, 태그 추출을 수행합니다.

**핵심 철학**:
- ast-grep 우선: 검색/대체는 ast-grep, tree-sitter는 분석/이해 목적
- AST 시각화: 코드 구조를 트리로 확인하여 정확한 노드 타입 파악
- S-expression 쿼리: predicates로 정밀한 구조적 검색 (neovim query와 동일 문법)
- 태그 추출: 정의/참조를 구조적으로 추출 (ctags 대체)

## Prerequisites

```bash
tree-sitter dump-languages  # 사용 가능한 파서 목록
```

"not configured" 경고 시 → 워크플로우 1 실행.

## Instructions

### 워크플로우 1: Setup (on-demand 파서 설치)

`dump-languages` 출력에 언어가 없으면 grammar을 설치한다.

```bash
# 초기 설정 (1회)
tree-sitter init-config  # parser-directories: ["~/.local/share/tree-sitter/grammars"]

# 언어별 설치 (필요 시)
cd ~/.local/share/tree-sitter/grammars
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-<언어>
# 일부 언어는 tree-sitter-grammars org: https://github.com/tree-sitter-grammars/tree-sitter-<언어>
```

### 워크플로우 2: Parse (AST 덤프)

쿼리 작성 전 노드 타입 파악에 필수.

```bash
tree-sitter parse --no-ranges file.py   # 간결한 AST
tree-sitter parse --cst file.py         # 정렬된 트리
tree-sitter parse --xml file.py         # XML 출력
tree-sitter parse --scope source.python file.txt  # 언어 지정
```

**출력 예시**:
```
(function_definition
  name: (identifier)
  parameters: (parameters (identifier) (identifier))
  body: (block (return_statement)))
```

노드 타입(`function_definition`)과 필드명(`name:`, `body:`)을 확인하여 query 패턴 작성에 사용.

### 워크플로우 3: Query (S-expression 쿼리)

S-expression 패턴으로 코드를 검색한다. `.scm` 파일에 작성 후 실행.

```scheme
;; queries/find-functions.scm
(function_definition
  name: (identifier) @func.name)
```

```bash
tree-sitter query queries/find-functions.scm file.py
tree-sitter query queries/find-functions.scm src/      # 디렉토리 전체
tree-sitter query --captures queries/q.scm file.py     # 캡처 순서 출력
tree-sitter query --row-range 10-50 queries/q.scm file.py  # 행 범위 제한
```

S-expression 쿼리 문법은 `resources/01-query-syntax.md` 참조.

### 워크플로우 4: Tags (태그 추출)

코드에서 정의(definition)와 참조(reference)를 추출한다.

```bash
tree-sitter tags file.py
tree-sitter tags src/     # 디렉토리 전체
```

## 중요 원칙

1. **Parse 먼저**: 쿼리 작성 전 반드시 `parse`로 노드 타입 확인
2. **쿼리 파일 사용**: `.scm` 파일 작성 (재사용, 가독성)
3. **언어별 노드 차이**: 같은 개념이라도 언어마다 노드 타입이 다름

## Examples

### AST 구조 파악
```
User: "이 Python 파일의 AST 구조 보여줘"
→ tree-sitter parse --no-ranges file.py → 노드 타입과 필드 구조 보고
```

### 복잡한 쿼리
```
User: "데코레이터가 붙은 async 함수만 찾아줘"
→ parse로 노드 타입 확인 → .scm 쿼리 작성 → tree-sitter query query.scm src/
```

## References

- S-expression 쿼리 문법: `resources/01-query-syntax.md`
- 공식 문서: https://tree-sitter.github.io/tree-sitter/
- Grammar 목록: https://github.com/tree-sitter
- 설정 파일: `~/.config/tree-sitter/config.json`
- Grammar 경로: `~/.local/share/tree-sitter/grammars/`
