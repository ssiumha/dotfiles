# Rules Reference

Claude Code용 rules 파일을 생성하고 관리합니다. Rules는 CLAUDE.md와 동일한 우선순위로 로드되며, `paths`로 조건부 적용이 가능합니다.

## 파일 위치

| 위치 | 경로 | 용도 |
|------|------|------|
| 프로젝트 | `.claude/rules/{name}.md` | 현재 프로젝트에서만 |
| 사용자 | `~/.claude/rules/{name}.md` | 모든 프로젝트에서 |

## Frontmatter

| 필드 | 필수 | 설명 |
|------|:----:|------|
| `paths` | X | 조건부 적용 glob 패턴 |

`paths`가 없으면 모든 파일에 적용됩니다.

**참고**: 현재는 `paths`가 지정되어 있어도 모든 rules가 로드됩니다. 향후 버전에서 조건부 로딩으로 개선 예정입니다.

## CLAUDE.md vs Rules 선택 기준

| 상황 | 권장 |
|------|------|
| 모든 상황에 적용 | CLAUDE.md |
| 특정 파일/폴더에만 적용 | rules/ + paths |
| 규칙이 많아 모듈화 필요 | rules/ (주제별 분리) |
| 팀에서 특정 규칙만 공유 | rules/ (개별 파일) |

## Creation Process

### 1. 기존 규칙 확인

```bash
Glob ~/.claude/rules/*.md
Glob .claude/rules/*.md
```

### 2. 용도 확인

AskUserQuestion으로 확인:
- **적용 범위**: 모든 파일? 특정 파일만?
- **위치**: 프로젝트? 사용자 레벨?

### 3. CLAUDE.md vs Rules 결정

```
모든 상황에 적용?
  → YES: CLAUDE.md에 추가 권장
  → NO: rules/ 생성 (paths 지정)
```

### 4. 파일 생성

**조건부 규칙 (paths 지정)**:
```markdown
---
paths: src/api/**/*.ts
---
# API Development Rules
- 모든 엔드포인트에 입력 검증 필수
- 표준 에러 응답 형식 사용
```

**전역 규칙 (paths 없음)**:
```markdown
# Testing Rules
- 모든 새 기능에 테스트 필수
- 커버리지 80% 이상 유지
```

## Glob 패턴 상세

### 기본 패턴

| 패턴 | 매칭 대상 | 설명 |
|------|----------|------|
| `**/*.ts` | 모든 TypeScript | 재귀적 매칭 |
| `*.md` | 루트 Markdown만 | 현재 디렉토리만 |
| `src/**/*` | src/ 하위 전체 | 디렉토리 포함 |
| `src/components/*.tsx` | 직접 자식만 | 중첩 제외 |

### 확장자 조합

| 패턴 | 매칭 대상 |
|------|----------|
| `**/*.{ts,tsx}` | TS와 TSX 모두 |
| `**/*.{js,jsx,ts,tsx}` | 모든 JS/TS |
| `**/*.{css,scss,less}` | 모든 스타일 |

### 디렉토리 조합

| 패턴 | 매칭 대상 |
|------|----------|
| `{src,lib}/**/*.ts` | src/와 lib/ 하위 |
| `{app,pages}/**/*.tsx` | Next.js 라우트 |
| `{tests,__tests__}/**/*` | 테스트 디렉토리들 |

### 복합 패턴

```yaml
# 여러 패턴 조합
paths: src/**/*.{ts,tsx}, lib/**/*.ts, tests/**/*.test.ts

# 보안 민감 영역
paths: src/auth/**/*.*, src/payments/**/*.*, src/crypto/**/*.*
```

**YAML 문법 주의**:
- `{`로 시작하는 패턴은 반드시 따옴표로 감싸야 합니다: `"{src,lib}/**/*.ts"`
- `*`로 시작하는 패턴도 따옴표 필수: `"**/*.md"`
- 안전하게 모든 paths 값을 따옴표로 감싸는 것을 권장합니다

## 우선순위

로드 순서 (공식 문서 기준):
1. Enterprise policy (조직 수준)
2. Project memory (`./.claude/CLAUDE.md`)
3. Project rules (`./.claude/rules/`)
4. User memory (`~/.claude/CLAUDE.md`)
5. Project local memory (`./.claude/CLAUDE.local.md`)

**나중에 로드되는 규칙이 더 높은 우선순위를 가집니다.**

**실질적 우선순위 (높음 → 낮음)**:
1. Project local memory - 최우선
2. User memory
3. Project rules
4. Project memory
5. Enterprise policy - 최하위

**충돌 시 동작**: 프로젝트 레벨 규칙이 사용자 레벨보다 우선 적용됩니다.

## 활용 사례별 Rules 템플릿

### API 개발 규칙
```markdown
---
paths: src/api/**/*.ts, src/routes/**/*.ts
---
# API Development Rules
## 입력 검증
- 모든 엔드포인트에 Zod 스키마로 입력 검증
- 검증 실패 시 400 에러와 상세 메시지 반환
## 에러 처리
- 표준 에러 응답 포맷: `{ "error": { "code": "string", "message": "string" } }`
- HTTP 상태 코드 정확히 사용
## 로깅
- correlation ID로 요청 추적
- 민감 데이터 마스킹
```

### 테스트 작성 규칙
```markdown
---
paths: "**/*.test.ts, **/*.test.tsx, **/*.spec.ts"
---
# Test Standards
- 테스트명: "should [action] when [condition]"
- Arrange-Act-Assert 패턴
- 외부 의존성만 Mock, 구현 세부사항 Mock 금지
```

### 보안 민감 코드
```markdown
---
paths: src/auth/**/*.*, src/payments/**/*.*
---
# Security-Critical Rules
- 민감 데이터 로깅 금지
- 함수 경계에서 모든 입력 검증
- parameterized query 필수
```

### React 컴포넌트
```markdown
---
paths: src/components/**/*.tsx, src/hooks/**/*.ts
---
# React Rules
- 함수형 컴포넌트만 사용
- 로직은 custom hook으로 분리
- Props 타입 명시
```

### DB 마이그레이션
```markdown
---
paths: prisma/migrations/**/, db/migrations/**/
---
# Migration Rules
- 롤백 방법 명시 필수
- 프로덕션 데이터 복사본에서 테스트
```

## 디렉토리 조직 패턴

### 주제별 (권장 - 소규모)
```
.claude/rules/
├── code-style.md      # 전역
├── testing.md         # 전역
├── security.md        # 전역
└── api-design.md      # paths: src/api/**/*
```

### 기술 계층별 (중규모)
```
.claude/rules/
├── frontend/
│   ├── react.md        # paths: src/components/**/*
│   └── styles.md       # paths: **/*.css
├── backend/
│   ├── api.md          # paths: src/api/**/*
│   └── database.md     # paths: src/db/**/*
└── general.md          # 전역
```

### 도메인별 (대규모)
```
.claude/rules/
├── user-management/
│   └── auth.md         # paths: src/domains/user/**/*
├── payments/
│   └── security.md     # paths: src/domains/payment/**/*
└── shared.md           # 전역
```

## Symlink 활용

공유 규칙을 여러 프로젝트에서 재사용:
```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

## Anti-Patterns

| 문제 | 해결 |
|------|------|
| 모든 규칙에 paths 추가 | 전역 규칙은 paths 생략 |
| 한 파일에 여러 주제 혼합 | 주제별 파일 분리 |
| CLAUDE.md 내용과 중복 | 한 곳에만 작성, 참조로 대체 |
| 너무 많은 전역 rules/ 파일 | CLAUDE.md 사용 권장 |
| 모호한 파일명 | 명확한 이름 (`api-security.md`) |
