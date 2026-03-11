# Security Tool Integration

외부 보안 도구를 활용한 자동화된 취약점 탐지.

## Static Analysis (SAST)

### Semgrep (Recommended)

다중 언어 지원, 커스텀 룰 작성 용이.

```bash
# Install
pip install semgrep
# or
brew install semgrep

# Quick scan with OWASP rules
semgrep --config=p/owasp-top-ten .

# Security audit
semgrep --config=p/security-audit .

# Language specific
semgrep --config=p/python .
semgrep --config=p/javascript .
semgrep --config=p/golang .

# Multiple rulesets
semgrep --config=p/owasp-top-ten --config=p/secrets .

# Output formats
semgrep --config=p/security-audit --json -o results.json .
semgrep --config=p/security-audit --sarif -o results.sarif .
```

**Custom Rule Example:**
```yaml
# .semgrep/custom-rules.yml
rules:
  - id: hardcoded-api-key
    pattern: |
      $X = "$API_KEY"
    message: "Hardcoded API key detected"
    severity: ERROR
    languages: [python, javascript]
```

---

### CodeQL (GitHub)

GitHub 저장소에 통합, 심층 데이터 흐름 분석.

```yaml
# .github/workflows/codeql.yml
name: CodeQL Analysis

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'  # Weekly

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write

    strategy:
      matrix:
        language: ['javascript', 'python']

    steps:
      - uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: +security-extended,security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform Analysis
        uses: github/codeql-action/analyze@v3
```

---

### Language-Specific Tools

#### Python: Bandit

```bash
# Install
pip install bandit

# Scan
bandit -r src/ -f json -o bandit-report.json

# Exclude tests
bandit -r src/ --exclude tests/

# Specific checks
bandit -r src/ -s B101,B102  # Skip specific checks

# CI integration
bandit -r src/ -f json -o bandit.json --exit-zero
```

#### JavaScript: ESLint Security

```bash
# Install
npm install --save-dev eslint-plugin-security

# .eslintrc.js
module.exports = {
  plugins: ['security'],
  extends: ['plugin:security/recommended'],
  rules: {
    'security/detect-object-injection': 'warn',
    'security/detect-non-literal-regexp': 'warn',
    'security/detect-unsafe-regex': 'error'
  }
}
```

#### Go: gosec

```bash
# Install
go install github.com/securego/gosec/v2/cmd/gosec@latest

# Scan
gosec ./...

# Output formats
gosec -fmt=json -out=results.json ./...
gosec -fmt=sarif -out=results.sarif ./...
```

#### Rust: cargo-audit

```bash
# Install
cargo install cargo-audit

# Scan
cargo audit

# Auto-fix
cargo audit fix
```

---

## Secret Scanning

### Gitleaks

```bash
# Install
brew install gitleaks
# or
go install github.com/gitleaks/gitleaks/v8@latest

# Scan repo
gitleaks detect --source . -v

# Scan git history
gitleaks detect --source . --log-opts="--all"

# Pre-commit hook
gitleaks protect --staged

# CI integration (GitHub Actions)
# See .github/workflows/ example below
```

### TruffleHog

```bash
# Install
pip install trufflehog

# Scan
trufflehog git file://. --only-verified

# Scan GitHub
trufflehog github --repo https://github.com/org/repo
```

---

## Dependency Scanning

### npm/Node.js

```bash
# Built-in
npm audit
npm audit fix

# Snyk (more comprehensive)
npx snyk test
npx snyk monitor
```

### Python

```bash
# pip-audit
pip install pip-audit
pip-audit

# Safety
pip install safety
safety check

# Snyk
snyk test --file=requirements.txt
```

### Go

```bash
# govulncheck (official)
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Nancy
go list -json -deps ./... | nancy sleuth
```

---

## CI/CD Integration

### GitHub Actions Complete Example

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/security-audit
            p/secrets
          generateSarif: "1"
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: semgrep.sarif

  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  dependency-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm audit --audit-level=high
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: ['-r', 'src/']

  - repo: https://github.com/returntocorp/semgrep
    rev: v1.50.0
    hooks:
      - id: semgrep
        args: ['--config', 'p/python', '--error']
```

---

## Tool Selection Guide

| Need | Tool | When to Use |
|------|------|-------------|
| Quick scan | Semgrep | Daily/PR checks |
| Deep analysis | CodeQL | Weekly, main branches |
| Secrets | Gitleaks | Every commit |
| Dependencies | npm audit, pip-audit | CI/CD pipeline |
| Python specific | Bandit | Python projects |
| JavaScript | ESLint Security | JS/TS projects |
| Multi-language | Semgrep, Snyk | Mixed codebases |

## Output Integration

대부분의 도구가 SARIF 출력을 지원하여 GitHub Security 탭과 통합 가능:

```bash
# Semgrep SARIF
semgrep --config=p/security-audit --sarif -o results.sarif .

# Upload to GitHub
gh api -X POST /repos/{owner}/{repo}/code-scanning/sarifs \
  -f commit_sha=$(git rev-parse HEAD) \
  -f ref=refs/heads/main \
  -F sarif=@results.sarif
```
