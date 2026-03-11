# Secret Detection Patterns

## Quick Reference

| Service | Pattern | Example |
|---------|---------|---------|
| AWS Access Key | `AKIA[0-9A-Z]{16}` | `AKIAIOSFODNN7EXAMPLE` |
| AWS Secret Key | `[0-9a-zA-Z/+]{40}` | (40 char base64) |
| GitHub PAT | `ghp_[A-Za-z0-9]{36}` | `ghp_xxxxxxxxxxxx...` |
| GitHub OAuth | `gho_[A-Za-z0-9]{36}` | `gho_xxxxxxxxxxxx...` |
| GitHub App | `ghu_[A-Za-z0-9]{36}` | `ghu_xxxxxxxxxxxx...` |
| GitHub Refresh | `ghr_[A-Za-z0-9]{36}` | `ghr_xxxxxxxxxxxx...` |
| GitLab PAT | `glpat-[A-Za-z0-9\-]{20}` | `glpat-xxxxxxxxxxxx...` |
| Slack Bot | `xoxb-[0-9a-zA-Z-]+` | `xoxb-123-456-abc...` |
| Slack User | `xoxp-[0-9a-zA-Z-]+` | `xoxp-123-456-abc...` |
| Slack App | `xoxa-[0-9a-zA-Z-]+` | `xoxa-123-456-abc...` |
| Google API | `AIza[0-9A-Za-z-_]{35}` | `AIzaSyC-xxxxx...` |
| Google OAuth | `[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com` | |
| Stripe Live | `sk_live_[0-9a-zA-Z]{24,}` | `sk_live_xxxxx...` |
| Stripe Test | `sk_test_[0-9a-zA-Z]{24,}` | `sk_test_xxxxx...` |
| OpenAI | `sk-[A-Za-z0-9]{48}` | `sk-xxxxx...` |
| OpenAI Proj | `sk-proj-[A-Za-z0-9-_]{48,}` | `sk-proj-xxxxx...` |
| Anthropic | `sk-ant-[A-Za-z0-9-_]{95}` | `sk-ant-xxxxx...` |
| Twilio | `SK[0-9a-fA-F]{32}` | `SKxxxxx...` |
| SendGrid | `SG\.[A-Za-z0-9-_]{22}\.[A-Za-z0-9-_]{43}` | `SG.xxxxx.xxxxx` |
| Mailchimp | `[0-9a-f]{32}-us[0-9]{1,2}` | `abc123...-us14` |
| Firebase | `AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}` | |
| npm Token | `npm_[A-Za-z0-9]{36}` | `npm_xxxxx...` |
| PyPI Token | `pypi-[A-Za-z0-9]{32,}` | `pypi-xxxxx...` |
| Heroku | `[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}` | UUID format |
| DigitalOcean | `dop_v1_[a-f0-9]{64}` | `dop_v1_xxxxx...` |
| Datadog | `[a-f0-9]{32}` | 32 hex chars |
| New Relic | `NRAK-[A-Z0-9]{27}` | `NRAK-xxxxx...` |
| Cloudflare | `[A-Za-z0-9_-]{37}` | 37 chars |

## Grep Patterns for Scanning

### High Confidence (Low False Positive)

```bash
# AWS
grep -rE "AKIA[0-9A-Z]{16}" .
grep -rE "aws_secret_access_key\s*=\s*['\"][A-Za-z0-9/+=]{40}" .

# GitHub
grep -rE "gh[pousr]_[A-Za-z0-9]{36}" .

# Slack
grep -rE "xox[bpars]-[0-9a-zA-Z-]+" .

# Google
grep -rE "AIza[0-9A-Za-z_-]{35}" .

# Stripe
grep -rE "sk_(live|test)_[0-9a-zA-Z]{24,}" .

# OpenAI/Anthropic
grep -rE "sk-[A-Za-z0-9]{48}" .
grep -rE "sk-ant-[A-Za-z0-9_-]{90,}" .
```

### Medium Confidence (May Have False Positives)

```bash
# Generic API keys
grep -rE "(api[_-]?key|apikey)\s*[:=]\s*['\"][A-Za-z0-9_-]{20,}['\"]" .

# Generic secrets
grep -rE "(secret|password|passwd|pwd)\s*[:=]\s*['\"][^'\"]{8,}['\"]" .

# Private keys
grep -rE "-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----" .

# JWT tokens (for review, not necessarily leaked)
grep -rE "eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*" .
```

## Files to Scan

**High Priority:**
- `.env`, `.env.*`
- `config.*`, `settings.*`
- `*.yml`, `*.yaml` (CI configs)
- `docker-compose*.yml`
- `Dockerfile`
- `*.json` (package.json, tsconfig.json 등)

**Check Exclusions:**
- `.gitignore` - `.env` 포함 여부
- Test files may have fake credentials (acceptable)

## Response Actions

### If Secret Found in Code

1. **Immediate**: Rotate the credential
2. **Remove** from code, use env vars
3. **Check** git history for exposure
4. **Audit** access logs for misuse

### Git History Cleanup (if committed)

```bash
# BFG Repo-Cleaner (recommended)
bfg --replace-text passwords.txt repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Or git-filter-repo
git filter-repo --invert-paths --path sensitive-file.txt
```

**Note:** After cleaning history, all contributors must re-clone.

## Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## Environment Variable Naming

**Recommended Pattern:**
```
{SERVICE}_{TYPE}_{ENV}

Examples:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
STRIPE_SECRET_KEY_PROD
DATABASE_URL_STAGING
```

**Anti-patterns:**
```
# Don't commit these values
PASSWORD=abc123
SECRET=mysecret
API_KEY=sk-xxx
```
