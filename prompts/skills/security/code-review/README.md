# Security Code Review

코드 변경사항을 보안 관점에서 체크하는 리뷰 스킬.

## Workflows

### 1. 변경된 파일 리뷰 (기본)

1. `git diff --name-only HEAD`로 변경 파일 확인
2. 코드 파일 필터링 → 각 파일 Read → 보안 체크리스트 적용
3. 심각도별 리포트 생성

### 2. 특정 파일/디렉토리 리뷰

사용자 지정 경로를 Glob으로 확인 → Read → 체크리스트 적용 → 리포트

### 3. 전체 프로젝트 스캔

우선순위: `auth/`, `api/`, `config/` → 순차 리뷰 → 종합 리포트

## Resource Files

| File | Content |
|------|---------|
| `./01-critical-patterns.md` | Hardcoded Credentials, SQL Injection, XSS, SSRF, Command Injection, Path Traversal |
| `./02-high-patterns.md` | CSRF, File Upload, Deserialization, Weak Crypto, JWT, Mass Assignment, Open Redirect |
| `./03-medium-low-patterns.md` | HTTPS, Error Exposure, Rate Limiting, Cookie, Input Validation, XXE, CORS, Headers |
| `./04-secret-patterns.md` | AWS, GitHub, OpenAI, Anthropic, Stripe 등 서비스별 API 키 정규식 패턴 |
| `./05-ai-code-security.md` | AI 생성 코드 주의점: 빈 catch, 입력 검증 누락, 하드코딩, 오래된 API |
| `./06-tool-integration.md` | Semgrep, gitleaks, npm audit, pip-audit 등 외부 도구 연동 |
| `./07-language-specific.md` | Python/JS/Go/Rust/Java 언어별 특화 보안 패턴 |

## Report Format

```markdown
# Security Review Report

**Date:** YYYY-MM-DD | **Files:** N | **Issues:** X Critical, Y High, Z Medium, W Low

## Critical Issues

### 1. [Issue Title]
**File:** `path/file.ts:42`
**Description:** ...
**Fix:** ...
**Reference:** [OWASP Link]

## Summary
- Good practices: [list]
- Areas needing attention: [list]
```

## Principles

1. **False Positive 최소화** — 확실한 이슈만 보고
2. **Context 고려** — 테스트 코드는 완화된 기준
3. **구체적 제안** — "어떻게 고치는지" 제시
4. **OWASP 참조** — 공식 문서 링크 제공
5. **긍정적 피드백** — 잘한 부분도 언급

## OWASP Top 10 (2021)

1. Broken Access Control
2. Cryptographic Failures
3. Injection
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable Components
7. Authentication Failures
8. Data Integrity Failures
9. Logging Failures
10. Server-Side Request Forgery (SSRF)

## Example

```
/security code-review
→ git diff 기반 변경 파일 자동 탐지 → 체크리스트 적용 → 심각도별 리포트
```
