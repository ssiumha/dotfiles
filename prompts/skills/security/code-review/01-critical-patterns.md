# Critical Vulnerabilities (Immediate Action Required)

## 1. Hardcoded Credentials

**Regex:**
```regex
(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key)\s*=\s*['"]\w+['"]
```

**Bad:**
```javascript
const API_KEY = "sk-1234567890abcdef"
const password = "admin123"
```

**Good:**
```javascript
const API_KEY = process.env.API_KEY
```

**Fix:**
- Use environment variables (`.env` + `.gitignore`)
- Use secrets manager (AWS Secrets Manager, HashiCorp Vault)

---

## 2. SQL Injection

**Regex:**
```regex
(execute|query|exec)\s*\([^)]*\+[^)]*\)
(execute|query|exec)\s*\([^)]*\$\{[^}]*\}[^)]*\)
```

**Bad:**
```javascript
db.query("SELECT * FROM users WHERE id = " + userId)
db.query(`SELECT * FROM users WHERE name = '${userName}'`)
```

**Good:**
```javascript
db.query("SELECT * FROM users WHERE id = ?", [userId])
db.query("SELECT * FROM users WHERE name = $1", [userName])
```

**Fix:**
- Parameterized queries / Prepared statements
- ORM (Sequelize, TypeORM, Prisma, SQLAlchemy)

---

## 3. XSS (Cross-Site Scripting)

**Regex:**
```regex
innerHTML\s*=
dangerouslySetInnerHTML
eval\(
\.html\([^)]*\+
```

**Bad:**
```javascript
element.innerHTML = userInput
element.innerHTML = `<div>${data}</div>`
```

**Good:**
```javascript
element.textContent = userInput
// React auto-escapes
<div>{data}</div>
```

**Fix:**
- Use `textContent` for non-HTML
- Framework auto-escaping
- DOMPurify for required HTML

---

## 4. Sensitive Data Logging

**Regex:**
```regex
(console\.log|logger\.|print|echo)\s*\([^)]*\b(password|token|secret|key|credential)\b
```

**Bad:**
```javascript
console.log("User login:", { username, password })
logger.info("API Token:", apiToken)
```

**Good:**
```javascript
console.log("User login:", { username })
logger.info("API Token:", "[REDACTED]")
```

**Fix:**
- Exclude sensitive data from logs
- Mask when necessary (`***`, `[REDACTED]`)

---

## 5. Missing Authentication/Authorization

**Regex:**
```regex
(app\.|router\.|@)(get|post|put|delete|patch)\s*\(['"]/
```

**Checklist:**
- Is this a public endpoint?
- Is auth middleware present? (`auth`, `authenticate`, `requireAuth`)
- Is permission check present? (`authorize`, `can`, `checkPermission`)

**Bad:**
```javascript
app.get('/api/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id)
  res.json(user)
})
```

**Good:**
```javascript
app.get('/api/users/:id', authenticateJWT, async (req, res) => {
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' })
  }
  const user = await User.findById(req.params.id)
  res.json(user)
})
```

---

## 6. Path Traversal

**Regex:**
```regex
(readFile|writeFile|open|fs\.)\s*\([^)]*\+
path\.join\([^)]*req\.(query|params|body)
```

**Bad:**
```javascript
const filePath = path.join(__dirname, req.query.file)
fs.readFile(filePath)  // ../../../etc/passwd
```

**Good:**
```javascript
const fileName = path.basename(req.query.file)
const filePath = path.join(__dirname, 'uploads', fileName)
if (!filePath.startsWith(path.join(__dirname, 'uploads'))) {
  throw new Error('Invalid path')
}
```

---

## 7. Server-Side Request Forgery (SSRF)

**Regex:**
```regex
(fetch|axios|request|http\.get|urllib)\s*\([^)]*req\.(query|params|body)
urllib\.request\.urlopen\([^)]*\+
requests\.get\([^)]*\+
```

**Bad:**
```python
# Python
url = request.args.get('url')
response = requests.get(url)  # Can access internal services
```
```javascript
// JavaScript
const url = req.query.url
const response = await fetch(url)  // http://169.254.169.254/metadata
```

**Good:**
```javascript
// JavaScript
const ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com']

const url = new URL(req.query.url)

// Validate scheme
if (!['http:', 'https:'].includes(url.protocol)) {
  return res.status(400).json({ error: 'Invalid scheme' })
}

// Validate host
if (!ALLOWED_HOSTS.includes(url.hostname)) {
  return res.status(400).json({ error: 'Host not allowed' })
}

// Timeout with AbortController
const controller = new AbortController()
const timeoutId = setTimeout(() => controller.abort(), 10000)
try {
  const response = await fetch(url.toString(), { signal: controller.signal })
} finally {
  clearTimeout(timeoutId)
}
```

```python
# Python
from urllib.parse import urlparse

ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com']

url = request.args.get('url')
parsed = urlparse(url)

# Validate scheme
if parsed.scheme not in ('http', 'https'):
    abort(400, 'Invalid scheme')

# Validate host
if parsed.hostname not in ALLOWED_HOSTS:
    abort(400, 'Host not allowed')

# Block internal IPs
import ipaddress
try:
    ip = ipaddress.ip_address(parsed.hostname)
    if ip.is_private or ip.is_loopback:
        abort(400, 'Internal IP not allowed')
except ValueError:
    pass  # Not an IP, hostname is OK

response = requests.get(url, timeout=10)
```

**SSRF Targets to Block:**
- `169.254.169.254` - AWS/GCP metadata
- `127.0.0.1`, `localhost` - Loopback
- `10.x.x.x`, `172.16-31.x.x`, `192.168.x.x` - Private ranges
- `0.0.0.0` - All interfaces
- Internal service URLs

**Fix:**
- Whitelist allowed domains
- Block private IP ranges
- Validate URL scheme (http/https only)
- Use allowlist, not blocklist
- Set request timeouts

---

## 8. Command Injection

**Regex:**
```regex
(exec|spawn|system|popen|subprocess)\s*\([^)]*\+
shell\s*=\s*True
os\.system\([^)]*\+
```

**Bad:**
```python
import os
filename = request.args.get('file')
os.system(f"cat {filename}")  # ; rm -rf /
```
```javascript
const { exec } = require('child_process')
exec(`ls ${userInput}`)  // ; rm -rf /
```

**Good:**
```python
import subprocess
filename = request.args.get('file')
# Use list args, not shell string
subprocess.run(['cat', filename], check=True)
```
```javascript
const { execFile } = require('child_process')
execFile('ls', [userInput])  // Args are escaped
```

**Fix:**
- Never use shell=True with user input
- Use execFile/spawn with array arguments
- Whitelist allowed commands
- Validate/sanitize all inputs
