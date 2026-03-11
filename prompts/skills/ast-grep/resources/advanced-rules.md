# ast-grep Advanced Rules

## YAML 룰 시스템

### 프로젝트 설정

```yaml
# sgconfig.yml (프로젝트 루트)
ruleDirs:
  - rules/        # 룰 파일 디렉토리
  - rules/security/
```

### 룰 파일 구조

```yaml
# rules/no-console-log.yml
id: no-console-log
language: typescript
severity: warning
message: "console.log 대신 logger 사용"
rule:
  pattern: console.log($$$ARGS)
fix: "logger.debug($$$ARGS)"
```

### 실행

```bash
sg scan                    # sgconfig.yml 기반 전체 스캔
sg scan --rule rules/      # 특정 디렉토리 룰만
sg scan --json             # JSON 출력 (CI 연동)
sg scan --fix              # 자동 수정 적용 (fix 정의된 룰)
```

---

## Relational Rules

단순 패턴 매칭을 넘어 코드 구조의 관계를 매칭한다.

### inside — 특정 구조 내부에서만 매칭

```yaml
# if 블록 안의 return만 찾기
id: return-in-if
rule:
  pattern: return $VALUE
  inside:
    kind: if_statement
```

### has — 특정 패턴을 포함하는 노드 매칭

```yaml
# async 메서드를 가진 클래스 찾기
id: class-with-async
rule:
  kind: class_declaration
  has:
    pattern: "async $METHOD($$$PARAMS)"
```

### follows / precedes — 순서 기반 매칭

```yaml
# console.log 바로 다음에 오는 문장
id: after-console
rule:
  pattern: $STMT
  follows:
    pattern: console.log($$$)
```

### 복합 룰 (all / any / not)

```yaml
# async 함수이면서 try-catch가 없는 경우
id: async-without-try
rule:
  all:
    - pattern: "async function $NAME($$$) { $$$ }"
    - not:
        has:
          kind: try_statement
```

```yaml
# console.log 또는 console.warn 찾기
id: no-console
rule:
  any:
    - pattern: console.log($$$)
    - pattern: console.warn($$$)
    - pattern: console.error($$$)
```

---

## 보안 스캐닝 룰

### SQL Injection

```yaml
id: sql-injection-template-literal
language: typescript
severity: error
message: "SQL 쿼리에 템플릿 리터럴 사용 금지. 파라미터화된 쿼리 사용"
rule:
  pattern: "query(`$$$`)"
```

### eval() 사용

```yaml
id: no-eval
language: javascript
severity: error
message: "eval() 사용 금지 — 코드 인젝션 위험"
rule:
  any:
    - pattern: eval($CODE)
    - pattern: new Function($$$)
```

### innerHTML XSS

```yaml
id: no-inner-html
language: typescript
severity: warning
message: "innerHTML 대신 textContent 또는 DOM API 사용"
rule:
  pattern: "$EL.innerHTML = $VALUE"
```

### 하드코딩된 시크릿

```yaml
id: no-hardcoded-secret
language: typescript
severity: error
message: "비밀번호/토큰 하드코딩 금지"
rule:
  any:
    - pattern: "password = '$$$'"
    - pattern: "token = '$$$'"
    - pattern: "secret = '$$$'"
    - pattern: "apiKey = '$$$'"
```

### Python os.system

```yaml
id: no-os-system
language: python
severity: error
message: "os.system 대신 subprocess.run 사용 (shell injection 방지)"
rule:
  any:
    - pattern: os.system($CMD)
    - pattern: os.popen($CMD)
```

---

## CI 통합 예시

```yaml
# .github/workflows/ast-grep.yml
- name: AST Security Scan
  run: |
    sg scan --json > sg-report.json
    if jq '.[] | select(.severity == "error")' sg-report.json | grep -q .; then
      echo "Security violations found"
      exit 1
    fi
```
