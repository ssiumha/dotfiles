# Medium & Low Severity Vulnerabilities

## Medium (Review Required)

### 1. HTTPS Not Enforced

**Regex:**
```regex
http\.createServer
app\.listen\s*\(\s*\d+\s*\)
```

**Checklist:**
- HTTPS in production?
- Behind reverse proxy (nginx, ALB)?
- HSTS header set?

**Good:**
```javascript
// Force HTTPS in production
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (req.headers['x-forwarded-proto'] !== 'https') {
      return res.redirect(`https://${req.hostname}${req.url}`)
    }
    next()
  })
}

// HSTS header
app.use(helmet.hsts({
  maxAge: 31536000,
  includeSubDomains: true
}))
```

---

### 2. Detailed Error Exposure

**Regex:**
```regex
catch.*console\.log\(.*error
res\.(json|send)\(.*error\.(stack|message)
traceback\.format_exc
```

**Bad:**
```javascript
catch (error) {
  res.status(500).json({ error: error.stack })
}
```

**Good:**
```javascript
catch (error) {
  logger.error(error)  // Server logs only
  res.status(500).json({ error: 'Internal server error' })
}
```

---

### 3. Rate Limiting Missing

**Checklist:**
- API endpoints rate limited?
- Login/signup protected?
- Password reset protected?

**Good:**
```javascript
const rateLimit = require('express-rate-limit')

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests'
})

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,  // Stricter for auth
  message: 'Too many login attempts'
})

app.use('/api/', apiLimiter)
app.use('/auth/', authLimiter)
```

---

### 4. Insecure Cookie Settings

**Regex:**
```regex
cookie\s*\([^)]*\)(?!.*httpOnly)
Set-Cookie(?!.*HttpOnly)
```

**Checklist:**
- `httpOnly: true` (prevent XSS access)
- `secure: true` (HTTPS only)
- `sameSite: 'strict'` or `'lax'`
- Appropriate `maxAge`

**Good:**
```javascript
res.cookie('session', token, {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 3600000  // 1 hour
})
```

---

### 5. Missing Input Validation

**Checklist:**
- Request body validated?
- Query params validated?
- Type checking?
- Length limits?

**Good:**
```javascript
// Using Joi
const schema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).max(100).required(),
  age: Joi.number().integer().min(0).max(150)
})

const { error, value } = schema.validate(req.body)
if (error) {
  return res.status(400).json({ error: error.details[0].message })
}
```

```python
# Using Pydantic
from pydantic import BaseModel, EmailStr, constr

class UserCreate(BaseModel):
    email: EmailStr
    password: constr(min_length=8, max_length=100)
    age: int = Field(ge=0, le=150)
```

---

### 6. XML External Entity (XXE)

**Regex:**
```regex
parseString|parse\s*\(.*xml
etree\.parse
DocumentBuilder
XMLReader
```

**Bad:**
```python
from xml.etree.ElementTree import parse
tree = parse(user_file)  # XXE possible
```

**Good:**
```python
import defusedxml.ElementTree as ET
tree = ET.parse(user_file)  # Safe
```

```java
// Java
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
```

---

## Low (Recommended Improvements)

### 1. CORS Misconfiguration

**Regex:**
```regex
Access-Control-Allow-Origin.*\*
cors\(\s*\)
origin:\s*true
```

**Checklist:**
- `Access-Control-Allow-Origin: *` in use?
- Can restrict to specific origins?
- Credentials exposed?

**Good:**
```javascript
const corsOptions = {
  origin: ['https://mysite.com', 'https://admin.mysite.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}
app.use(cors(corsOptions))
```

---

### 2. Security Headers Missing

**Checklist:**
- Content-Security-Policy
- X-Frame-Options
- X-Content-Type-Options
- Referrer-Policy
- Permissions-Policy

**Good:**
```javascript
// Using Helmet.js
const helmet = require('helmet')
app.use(helmet())

// Or manually
app.use((req, res, next) => {
  res.setHeader('X-Frame-Options', 'DENY')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-XSS-Protection', '1; mode=block')
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
  res.setHeader('Content-Security-Policy', "default-src 'self'")
  next()
})
```

---

### 3. Verbose Server Banner

**Regex:**
```regex
X-Powered-By
Server:.*Express
Server:.*nginx
```

**Good:**
```javascript
// Express
app.disable('x-powered-by')

// Or with Helmet
app.use(helmet.hidePoweredBy())
```

---

### 4. Deprecated Dependencies

**Checklist:**
- Run `npm audit` / `pip-audit` / `cargo audit`
- Check for known CVEs
- Update outdated packages

**Commands:**
```bash
# JavaScript
npm audit
npm audit fix

# Python
pip-audit
safety check

# Go
go list -m -u all
govulncheck ./...

# Rust
cargo audit
```

---

### 5. Logging Sensitive URLs

**Regex:**
```regex
(access|request).*log.*(token|key|password|secret)
```

**Checklist:**
- Query string tokens logged?
- Auth headers logged?
- Request bodies logged?

**Good:**
```javascript
// Mask sensitive query params in logs
const sanitizeUrl = (url) => {
  return url.replace(/([?&])(token|key|password)=[^&]*/gi, '$1$2=[REDACTED]')
}
```
