# Language-Specific Security Patterns

## Python

### Critical

#### Dangerous Deserialization
```python
# Bad
import pickle
data = pickle.loads(user_input)  # RCE

import yaml
data = yaml.load(user_input)  # Deprecated, unsafe

# Good
import json
data = json.loads(user_input)

import yaml
data = yaml.safe_load(user_input)
```

#### Code Injection
```python
# Bad
eval(user_input)
exec(user_input)
compile(user_input, '<string>', 'exec')

# If absolutely necessary, use AST
import ast
try:
    tree = ast.parse(user_input, mode='eval')
    # Whitelist allowed node types
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Expression, ast.Num, ast.BinOp, ...)):
            raise ValueError("Disallowed")
    result = eval(compile(tree, '<string>', 'eval'))
except:
    raise ValueError("Invalid expression")
```

#### Command Injection
```python
# Bad
import os
os.system(f"ls {user_path}")  # Shell injection

import subprocess
subprocess.run(cmd, shell=True)  # Shell injection

# Good
import subprocess
subprocess.run(['ls', user_path], check=True)  # List args, no shell
```

#### SQL Injection
```python
# Bad
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# Good - parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# Good - ORM
User.objects.get(id=user_id)
```

### High

#### Path Traversal
```python
# Bad
with open(os.path.join('/uploads', user_filename)) as f:
    return f.read()

# Good
import os
from pathlib import Path

base_dir = Path('/uploads').resolve()
file_path = (base_dir / user_filename).resolve()

if not str(file_path).startswith(str(base_dir)):
    raise ValueError("Path traversal detected")
```

#### XML External Entity (XXE)
```python
# Bad
from xml.etree.ElementTree import parse
tree = parse(user_file)

# Good
import defusedxml.ElementTree as ET
tree = ET.parse(user_file)
```

---

## JavaScript / TypeScript

### Critical

#### Prototype Pollution
```javascript
// Bad
function merge(target, source) {
  for (const key in source) {
    target[key] = source[key]  // __proto__ pollution
  }
}

// Good
function safeMerge(target, source) {
  const blacklist = ['__proto__', 'constructor', 'prototype']
  for (const key of Object.keys(source)) {
    if (blacklist.includes(key)) continue
    target[key] = source[key]
  }
}

// Or use Object.create(null)
const obj = Object.create(null)
```

#### XSS via innerHTML
```javascript
// Bad
element.innerHTML = userContent
document.write(userContent)

// Good
element.textContent = userContent

// If HTML needed, sanitize
import DOMPurify from 'dompurify'
element.innerHTML = DOMPurify.sanitize(userContent)
```

#### eval and Function constructor
```javascript
// Bad
eval(userInput)
new Function(userInput)()
setTimeout(userInput, 0)  // If string

// Good - use JSON for data
const data = JSON.parse(userInput)
```

### High

#### RegExp DoS (ReDoS)
```javascript
// Bad - catastrophic backtracking
const regex = /^(a+)+$/
regex.test(userInput)  // "aaaaaaaaaaaaaaaaaaaaaaaaaaaa!" causes hang

// Good - use safe patterns or timeout
const safeRegex = /^a+$/

// Or use safe-regex library
const safeRegex = require('safe-regex')
if (!safeRegex(pattern)) {
  throw new Error('Unsafe regex')
}
```

#### Insecure Randomness
```javascript
// Bad - predictable
const token = Math.random().toString(36)

// Good - cryptographically secure
const crypto = require('crypto')
const token = crypto.randomBytes(32).toString('hex')

// Browser
const token = crypto.getRandomValues(new Uint8Array(32))
```

---

## Go

### Critical

#### SQL Injection
```go
// Bad
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Query(query)

// Good
db.Query("SELECT * FROM users WHERE id = $1", userID)

// Or with sqlx
db.Get(&user, "SELECT * FROM users WHERE id = ?", userID)
```

#### Command Injection
```go
// Bad
cmd := exec.Command("sh", "-c", "ls " + userPath)

// Good
cmd := exec.Command("ls", userPath)  // Separate args
```

#### Template Injection
```go
// Bad - text/template doesn't escape
import "text/template"
tmpl.Execute(w, userContent)  // XSS if HTML output

// Good - html/template auto-escapes
import "html/template"
tmpl.Execute(w, userContent)  // Safe for HTML
```

### High

#### Unsafe Pointer
```go
// Review carefully
import "unsafe"
ptr := unsafe.Pointer(&data)  // Can bypass type safety
```

#### Race Conditions
```go
// Bad - race condition
var counter int
func increment() {
    counter++  // Not atomic
}

// Good - use sync or atomic
var counter int64
func increment() {
    atomic.AddInt64(&counter, 1)
}

// Or mutex
var mu sync.Mutex
var counter int
func increment() {
    mu.Lock()
    counter++
    mu.Unlock()
}
```

---

## Rust

### Security Considerations

Rust's ownership system prevents many vulnerabilities, but watch for:

#### Unsafe Blocks
```rust
// Review carefully - bypasses safety guarantees
unsafe {
    // Raw pointer dereference
    let val = *raw_ptr;

    // FFI calls
    external_c_function();
}
```

#### Unwrap in Production
```rust
// Bad - panics on error
let value = result.unwrap();
let item = option.unwrap();

// Good - handle errors
let value = result?;  // Propagate error
let value = result.unwrap_or_default();
let value = result.map_err(|e| CustomError::from(e))?;
```

#### SQL (with sqlx)
```rust
// Bad
let query = format!("SELECT * FROM users WHERE id = {}", user_id);
sqlx::query(&query).fetch_one(&pool).await?;

// Good
sqlx::query("SELECT * FROM users WHERE id = $1")
    .bind(user_id)
    .fetch_one(&pool)
    .await?;
```

#### Regex DoS
```rust
// Set limits
use regex::Regex;
let re = Regex::new(r"^(a+)+$").unwrap();
// Consider using regex with size limits
```

---

## Java

### Critical

#### Deserialization
```java
// Bad
ObjectInputStream ois = new ObjectInputStream(userInput);
Object obj = ois.readObject();  // RCE possible

// Good - use JSON
ObjectMapper mapper = new ObjectMapper();
mapper.readValue(userInput, SafeClass.class);
```

#### SQL Injection
```java
// Bad
String query = "SELECT * FROM users WHERE id = " + userId;
statement.executeQuery(query);

// Good
PreparedStatement ps = conn.prepareStatement(
    "SELECT * FROM users WHERE id = ?"
);
ps.setInt(1, userId);
ResultSet rs = ps.executeQuery();
```

#### XXE
```java
// Bad
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
DocumentBuilder db = dbf.newDocumentBuilder();
Document doc = db.parse(userInput);

// Good
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
```

---

## Summary Table

| Language | Top Risks | Key Tools |
|----------|-----------|-----------|
| Python | pickle, eval, shell=True | Bandit, Semgrep |
| JavaScript | XSS, prototype pollution | ESLint Security, Semgrep |
| Go | text/template, SQL concat | gosec, Semgrep |
| Rust | unsafe blocks, unwrap | cargo-audit, clippy |
| Java | deserialization, XXE | SpotBugs, CodeQL |
