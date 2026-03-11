# AI-Generated Code Security

AI 코드 어시스턴트(GitHub Copilot, ChatGPT, Claude 등)가 생성하는 코드의 보안 취약점 패턴.

## Common Vulnerability Patterns

### 1. Insecure Defaults

AI가 "작동하는" 코드를 우선시하여 보안 설정이 느슨한 경우.

**Pattern:**
```javascript
// AI generated - empty catch block
try {
  await riskyOperation()
} catch (e) {
  // Silently ignore
}

// AI generated - overly permissive regex
const emailRegex = /.*@.*/  // Accepts anything with @
```

**Fix:**
```javascript
try {
  await riskyOperation()
} catch (e) {
  logger.error('Operation failed:', e)
  throw new AppError('Operation failed', { cause: e })
}

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
```

---

### 2. Missing Input Validation

AI가 "사용자 입력은 올바르다"고 가정하는 경향.

**Pattern:**
```python
# AI generated - trusts user input
def process_user(user_id):
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
    return user
```

**Fix:**
```python
def process_user(user_id: int):
    if not isinstance(user_id, int) or user_id <= 0:
        raise ValueError("Invalid user ID")
    user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    return user
```

---

### 3. Hardcoded Configuration

AI가 예시 값을 하드코딩하고 "나중에 변경" 주석을 다는 패턴.

**Pattern:**
```javascript
// AI generated
const config = {
  apiKey: "sk-example-key",  // TODO: Replace with env var
  timeout: 30000,  // 30 seconds
  maxRetries: 3
}
```

**Fix:**
```javascript
const config = {
  apiKey: process.env.API_KEY || (() => { throw new Error('API_KEY required') })(),
  timeout: parseInt(process.env.TIMEOUT, 10) || 30000,
  maxRetries: parseInt(process.env.MAX_RETRIES, 10) || 3
}
```

---

### 4. Incomplete Error Handling

예외 처리가 있지만 불완전한 경우.

**Pattern:**
```python
# AI generated - catches but exposes
def login(username, password):
    try:
        user = authenticate(username, password)
        return {"success": True, "user": user}
    except Exception as e:
        return {"success": False, "error": str(e)}  # May leak info
```

**Fix:**
```python
def login(username, password):
    try:
        user = authenticate(username, password)
        return {"success": True, "user": user}
    except AuthenticationError:
        return {"success": False, "error": "Invalid credentials"}
    except Exception as e:
        logger.exception("Login error")
        return {"success": False, "error": "Login failed"}
```

---

### 5. Deprecated/Insecure APIs

AI가 학습 데이터의 오래된 패턴을 사용.

**Pattern:**
```python
# AI generated - old Python pattern
import md5
hash = md5.new(password).hexdigest()

# AI generated - deprecated
import cgi
cgi.escape(user_input)
```

**Fix:**
```python
import hashlib
hash = hashlib.sha256(password.encode()).hexdigest()

# For password hashing
import bcrypt
hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt())

# For HTML escaping
from html import escape
escaped = escape(user_input)
```

---

### 6. Race Conditions

비동기 코드에서 경쟁 조건 미고려.

**Pattern:**
```javascript
// AI generated - TOCTOU vulnerability
async function withdrawMoney(userId, amount) {
  const balance = await getBalance(userId)
  if (balance >= amount) {  // Check
    await updateBalance(userId, balance - amount)  // Use - race!
  }
}
```

**Fix:**
```javascript
async function withdrawMoney(userId, amount) {
  await db.transaction(async (tx) => {
    const result = await tx.execute(
      'UPDATE accounts SET balance = balance - ? WHERE user_id = ? AND balance >= ?',
      [amount, userId, amount]
    )
    if (result.affectedRows === 0) {
      throw new Error('Insufficient balance')
    }
  })
}
```

---

### 7. Prototype Pollution (JavaScript)

객체 병합 시 `__proto__` 오염 미방지.

**Pattern:**
```javascript
// AI generated - vulnerable
function mergeConfig(defaults, userConfig) {
  return { ...defaults, ...userConfig }  // Can pollute if userConfig has __proto__
}

// Or worse
function deepMerge(target, source) {
  for (const key in source) {
    target[key] = source[key]  // __proto__ pollution
  }
}
```

**Fix:**
```javascript
function safemerge(defaults, userConfig) {
  const safe = Object.create(null)
  for (const key of Object.keys(defaults)) {
    safe[key] = defaults[key]
  }
  for (const key of Object.keys(userConfig)) {
    if (key === '__proto__' || key === 'constructor' || key === 'prototype') {
      continue  // Skip dangerous keys
    }
    safe[key] = userConfig[key]
  }
  return safe
}
```

---

## AI Code Review Checklist

AI가 생성한 코드를 리뷰할 때:

### Must Check

- [ ] **Input validation** - 모든 외부 입력이 검증되는가?
- [ ] **Error handling** - catch 블록이 비어있거나 정보를 노출하지 않는가?
- [ ] **Hardcoded values** - API 키, 비밀번호, URL이 하드코딩되지 않았는가?
- [ ] **Deprecated APIs** - 사용된 라이브러리/함수가 현재 권장되는 것인가?
- [ ] **SQL/Command injection** - 문자열 연결 대신 파라미터화 쿼리를 사용하는가?

### Should Check

- [ ] **Race conditions** - 동시성 문제가 있는가?
- [ ] **Resource cleanup** - 파일/연결이 제대로 닫히는가?
- [ ] **Timeout settings** - 네트워크 요청에 타임아웃이 있는가?
- [ ] **Type safety** - 타입 체크가 적절한가?

### Context-Dependent

- [ ] **Authentication** - 필요한 곳에 인증이 있는가?
- [ ] **Authorization** - 권한 체크가 있는가?
- [ ] **Logging** - 민감 정보가 로깅되지 않는가?

---

## References

### OpenSSF Guidelines

[OpenSSF Security-Focused Guide for AI Code Assistants](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions):

1. **Never trust AI-generated code blindly**
2. **Review all security-sensitive operations**
3. **Verify cryptographic implementations**
4. **Check for input validation**
5. **Ensure proper error handling**
6. **Use latest stable library versions**
7. **Run security scanners on generated code**

### OWASP AI Exchange

[OWASP AI Security Overview](https://owaspai.org/docs/ai_security_overview/) - AI 시스템 보안 가이드 (2025 Flagship Project)
