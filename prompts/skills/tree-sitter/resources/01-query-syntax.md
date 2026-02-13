# S-expression Query 문법

tree-sitter query에서 사용하는 S-expression 패턴 문법.
neovim의 treesitter query와 동일.

## 기본 구조

```scheme
;; 노드 타입 매칭
(function_definition)

;; 필드 지정
(function_definition
  name: (identifier))

;; 캡처 (@name)
(function_definition
  name: (identifier) @func.name)
```

## 캡처 (Captures)

`@name`으로 매칭된 노드를 캡처. 결과 출력에 사용.

```scheme
;; 단일 캡처
(identifier) @name

;; 다중 캡처
(function_definition
  name: (identifier) @func.name
  parameters: (parameters) @func.params)
```

## 와일드카드

```scheme
;; 임의의 노드 (타입 무관)
(_)

;; 임의의 이름 노드
(_ name: (identifier) @name)
```

## Predicates (#으로 시작)

### #eq? — 정확히 일치

```scheme
;; 이름이 "main"인 함수
(function_definition
  name: (identifier) @name
  (#eq? @name "main"))

;; 두 캡처가 같은 값
(assignment
  left: (identifier) @a
  right: (identifier) @b
  (#eq? @a @b))
```

### #not-eq? — 불일치

```scheme
(identifier) @name
(#not-eq? @name "self")
```

### #match? — 정규식 매칭

```scheme
;; test_로 시작하는 함수
(function_definition
  name: (identifier) @name
  (#match? @name "^test_"))
```

### #not-match? — 정규식 불일치

```scheme
(identifier) @name
(#not-match? @name "^_")
```

### #any-of? — 여러 값 중 하나

```scheme
(identifier) @builtin
(#any-of? @builtin "print" "len" "range" "type")
```

## 양화사 (Quantifiers)

```scheme
;; 선택적 (0 또는 1)
(function_definition
  (decorator)? @dec
  name: (identifier) @name)

;; 반복 (0 이상)
(class_definition
  body: (block
    (function_definition)* @methods))

;; 반복 (1 이상)
(block
  (expression_statement)+ @stmts)
```

## 앵커

```scheme
;; 첫 번째 자식만
(block . (expression_statement) @first)

;; 마지막 자식만
(block (expression_statement) @last .)

;; 연속된 형제
(block
  (expression_statement) @a
  . (expression_statement) @b)
```

## 대안 (Alternation)

```scheme
;; 여러 타입 중 하나
[
  (function_definition)
  (class_definition)
] @definition
```

## 부정 (Negation)

```scheme
;; 데코레이터가 없는 함수
(function_definition
  !decorator
  name: (identifier) @name)
```

## 노드 타입 확인

언어별 노드 타입은 `tree-sitter parse --no-ranges <파일>`로 확인한다.

## 실전 쿼리 예시

### 모든 함수 정의와 호출

```scheme
;; Python
(function_definition name: (identifier) @def.name)
(call function: (identifier) @call.name)

;; TypeScript
(function_declaration name: (identifier) @def.name)
(call_expression function: (identifier) @call.name)
```

### 에러 핸들링 패턴

```scheme
;; Python: try-except
(try_statement
  body: (block) @try.body
  (except_clause
    (identifier) @exception.type) @except)

;; Go: if err != nil
(if_statement
  condition: (binary_expression
    left: (identifier) @err
    (#eq? @err "err")
    operator: "!="))
```

### 테스트 함수

```scheme
;; Python: test_ 접두사
(function_definition
  name: (identifier) @test.name
  (#match? @test.name "^test_"))

;; Go: Test 접두사
(function_declaration
  name: (identifier) @test.name
  (#match? @test.name "^Test"))

;; TypeScript: describe/it 블록
(call_expression
  function: (identifier) @func
  (#any-of? @func "describe" "it" "test")
  arguments: (arguments
    (string) @test.name))
```

### 미사용 import 후보

```scheme
;; Python
(import_from_statement
  name: (dotted_name) @module
  (import_prefix)
  name: (dotted_name (identifier) @imported))

;; TypeScript
(import_statement
  (import_clause
    (named_imports
      (import_specifier
        name: (identifier) @imported))))
```
