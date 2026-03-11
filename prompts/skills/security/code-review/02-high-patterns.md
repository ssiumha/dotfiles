# High Severity Vulnerabilities (Fix Promptly)

## 1. CSRF Protection Missing

**Checklist:**
- POST/PUT/DELETE requests have CSRF token validation?
- SameSite cookie setting?

**Good:**
```javascript
// Express with csurf
app.use(csrf())
app.post('/api/transfer', csrfProtection, handler)

// Cookie settings
res.cookie('token', value, {
  httpOnly: true,
  sameSite: 'strict',
  secure: true
})
```

```python
# Django (enabled by default)
MIDDLEWARE = [
    'django.middleware.csrf.CsrfViewMiddleware',
]

# Flask-WTF
from flask_wtf.csrf import CSRFProtect
csrf = CSRFProtect(app)
```

---

## 2. File Upload Validation Missing

**Regex:**
```regex
(multer|upload|file)\s*\(
req\.(file|files)
request\.files
```

**Checklist:**
- File type validation (whitelist)
- File size limit
- Filename sanitization
- Content-type verification (not just extension)

**Bad:**
```javascript
app.post('/upload', upload.single('file'), (req, res) => {
  fs.writeFile(req.file.originalname, req.file.buffer)
})
```

**Good:**
```javascript
const upload = multer({
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf']
    if (!allowedTypes.includes(file.mimetype)) {
      return cb(new Error('Invalid file type'))
    }
    cb(null, true)
  }
})

// Use random filename, not user-provided
const filename = `${crypto.randomUUID()}.${ext}`
```

---

## 3. Insecure Deserialization

**Regex:**
```regex
pickle\.loads
yaml\.load\s*\((?!.*Loader=yaml\.SafeLoader)
yaml\.unsafe_load
unserialize
Marshal\.load
ObjectInputStream
```

**Bad:**
```python
import pickle
data = pickle.loads(user_input)  # RCE possible
```
```python
import yaml
data = yaml.load(user_input)  # Deprecated, unsafe
```

**Good:**
```python
import json
data = json.loads(user_input)  # JSON only, safe

import yaml
data = yaml.safe_load(user_input)  # SafeLoader
```

---

## 4. Weak Cryptography

**Regex:**
```regex
\b(md5|sha1|des|rc4)\b
createHash\s*\(\s*['"]md5['"]
createHash\s*\(\s*['"]sha1['"]
```

**Bad:**
```javascript
const hash = crypto.createHash('md5').update(password).digest('hex')
const hash = crypto.createHash('sha1').update(password).digest('hex')
```

**Good:**
```javascript
// Password hashing
const hash = await bcrypt.hash(password, 12)

// Or Argon2 (recommended)
const hash = await argon2.hash(password)

// General hashing (not for passwords)
const hash = crypto.createHash('sha256').update(data).digest('hex')

// Key derivation
const key = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512')
```

**Algorithm Guide:**
| Use Case | Recommended | Avoid |
|----------|-------------|-------|
| Password storage | bcrypt, Argon2, scrypt | MD5, SHA1, plain SHA256 |
| Data integrity | SHA-256, SHA-3 | MD5, SHA1 |
| Encryption | AES-256-GCM | DES, 3DES, RC4 |
| Key derivation | PBKDF2, Argon2 | Single-pass hash |

---

## 5. Debug Mode in Production

**Regex:**
```regex
DEBUG\s*=\s*(true|1|True|"true")
app\.set\(['"]env['"],\s*['"]development['"]
FLASK_DEBUG\s*=\s*1
```

**Checklist:**
- Controlled by environment variable?
- Default is production/false?
- Stack traces hidden from users?

**Bad:**
```python
# settings.py
DEBUG = True

# Flask
app.run(debug=True)
```

**Good:**
```python
# settings.py
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

# Flask
app.run(debug=os.environ.get('FLASK_DEBUG', False))
```

---

## 6. JWT Vulnerabilities

**Regex:**
```regex
algorithm\s*=\s*['"]none['"]
verify\s*=\s*False
algorithms\s*=\s*\[.*none
expiresIn.*[0-9]{3,}[dw]
```

**Checklist:**
- Algorithm explicitly specified?
- `none` algorithm rejected?
- Signature verified?
- Reasonable expiration time?

**Bad:**
```python
# No algorithm verification
jwt.decode(token, options={"verify_signature": False})

# Accepts 'none' algorithm
jwt.decode(token, algorithms=["HS256", "none"])

# Too long expiration
jwt.encode({"sub": user_id, "exp": datetime.utcnow() + timedelta(days=365)}, key, algorithm="HS256")
```

**Good:**
```python
import jwt

# Explicit algorithm, always verify
payload = jwt.decode(
    token,
    key=SECRET_KEY,
    algorithms=["HS256"],  # Explicit, no 'none'
)

# Short-lived tokens
access_token = jwt.encode(
    {"sub": user_id, "exp": datetime.utcnow() + timedelta(hours=1)},
    SECRET_KEY,
    algorithm="HS256"
)
```

---

## 7. Mass Assignment

**Regex:**
```regex
\.create\(req\.body\)
\.update\(req\.body\)
Object\.assign\([^,]+,\s*req\.body
\*\*request\.(data|json|form)
```

**Bad:**
```javascript
// User can set isAdmin: true
User.create(req.body)
```
```python
# User can set is_admin=True
User.objects.create(**request.data)
```

**Good:**
```javascript
// Whitelist allowed fields
const { name, email } = req.body
User.create({ name, email })
```
```python
# Explicit fields only
User.objects.create(
    name=request.data.get('name'),
    email=request.data.get('email')
)
```

---

## 8. Open Redirect

**Regex:**
```regex
redirect\s*\(\s*req\.(query|params|body)
res\.redirect\([^)]*\+
Location.*req\.(query|params)
```

**Bad:**
```javascript
const returnUrl = req.query.returnUrl
res.redirect(returnUrl)  // Could redirect to evil.com
```

**Good:**
```javascript
const returnUrl = req.query.returnUrl
const url = new URL(returnUrl, 'https://mysite.com')

// Only allow same-origin redirects
if (url.origin !== 'https://mysite.com') {
  return res.redirect('/')
}
res.redirect(url.pathname)
```
