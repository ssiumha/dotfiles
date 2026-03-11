# SPEC.md Template Guide

이 문서는 6개 핵심 영역의 상세 작성 가이드입니다.

## Overview

좋은 스펙은 다음 질문에 답합니다:
- **Commands**: "어떻게 실행하나요?"
- **Testing**: "어떻게 검증하나요?"
- **Project Structure**: "어디에 코드를 작성하나요?"
- **Code Style**: "어떻게 작성하나요?"
- **Git Workflow**: "어떻게 협업하나요?"
- **Boundaries**: "무엇을 하면/하지 말아야 하나요?"

---

## 1. Commands 영역

### 목적
AI와 개발자가 즉시 실행할 수 명령어 제공

### 필수 포함 항목
1. 개발 서버 실행
2. 빌드 명령어
3. 테스트 실행
4. 린트/포맷 체크

### 작성 패턴

```markdown
## Commands

### Development
- `npm run dev` - Start dev server at http://localhost:3000
- `npm run dev:api` - Start API server at http://localhost:8000

### Build
- `npm run build` - Production build (output: dist/)
- `npm run build:analyze` - Build with bundle size analysis

### Testing
- `npm test` - Run all tests
- `npm run test:unit` - Unit tests only
- `npm run test:e2e` - E2E tests (requires dev server running)
- `npm run test:coverage` - Coverage report (threshold: 80%)

### Code Quality
- `npm run lint` - ESLint check (auto-fix: `npm run lint:fix`)
- `npm run format` - Prettier check (auto-fix: `npm run format:fix`)
- `npm run typecheck` - TypeScript compilation check

### Database
- `npm run db:migrate` - Run pending migrations
- `npm run db:seed` - Seed development data
- `npm run db:reset` - Reset database (⚠️ destructive)
```

### 좋은 예시 vs 나쁜 예시

```markdown
# ✅ Good: 명확한 설명 + 결과/경로
- `npm run build` - Production build (output: dist/)
- `npm test` - Run all tests (coverage threshold: 80%)
- `npm run dev` - Start dev server at http://localhost:3000

# ❌ Bad: 설명 없음
- `npm run build`
- `npm test`
- `npm run dev`

# ❌ Bad: 모호한 설명
- `npm run build` - 빌드 실행
- `npm test` - 테스트
```

### 언어별 패턴

**Python (Poetry/pip)**
```markdown
### Development
- `poetry run dev` - Start FastAPI server (reload enabled)
- `poetry install` - Install dependencies

### Testing
- `poetry run pytest` - Run all tests
- `poetry run pytest --cov` - With coverage (min 90%)
```

**Go**
```markdown
### Development
- `go run main.go` - Start server
- `make dev` - Start with hot reload (air)

### Testing
- `go test ./...` - Run all tests
- `go test -v -race ./...` - With race detector
```

**Rust**
```markdown
### Development
- `cargo run` - Run in debug mode
- `cargo run --release` - Run optimized build

### Testing
- `cargo test` - Run all tests
- `cargo test --doc` - Run doc tests
```

---

## 2. Testing 영역

### 목적
테스트 전략과 기대 수준 명시

### 필수 포함 항목
1. 테스트 프레임워크
2. 파일 위치 패턴
3. 커버리지 요구사항
4. 명명 규칙

### 작성 패턴

```markdown
## Testing

### Framework & Tools
- **Unit/Integration**: Vitest 1.x
- **E2E**: Playwright
- **Mocking**: MSW (Mock Service Worker)
- **Coverage**: c8

### Test Structure
```
src/
├── components/
│   └── Button.test.tsx        # Component tests
├── hooks/
│   └── useAuth.test.ts        # Hook tests
└── utils/
    └── formatDate.test.ts     # Utility tests

tests/
├── integration/
│   └── api.test.ts            # API integration tests
└── e2e/
    └── checkout.spec.ts       # E2E scenarios
```

### Coverage Requirements
- **Global minimum**: 80% (lines, branches, functions)
- **Critical paths**: 100% (auth, payment, data validation)
- **Exclusions**: `*.config.js`, `*.d.ts`, `__mocks__/`

### Test Naming Convention
```typescript
describe('ComponentName', () => {
  it('should [expected behavior] when [condition]', () => {
    // Test implementation
  });
});
```

**Examples**:
- ✅ `it('should display error message when email is invalid', () => {})`
- ✅ `it('should call onSubmit with form data when form is valid', () => {})`
- ❌ `it('works', () => {})`
- ❌ `it('test email validation', () => {})`

### Test Organization
- **Arrange-Act-Assert** pattern
- One assertion concept per test
- Mock external dependencies (API calls, timers)

### Running Tests
```bash
# Before commit (always)
npm test

# During development
npm run test:watch

# Before push (CI simulation)
npm run test:coverage && npm run test:e2e
```
```

### 프레임워크별 예시

**Python (pytest)**
```markdown
### Framework & Tools
- **Unit/Integration**: pytest 7.x
- **Fixtures**: pytest-fixtures
- **Coverage**: pytest-cov

### Test Structure
```
tests/
├── unit/
│   └── test_services.py
├── integration/
│   └── test_api.py
└── conftest.py              # Shared fixtures
```

### Test Naming
```python
def test_should_return_user_when_id_exists():
    pass

def test_should_raise_not_found_when_id_invalid():
    pass
```
```

**Go (testing)**
```markdown
### Framework & Tools
- Standard `testing` package
- **Assertions**: testify/assert
- **Mocking**: gomock

### Test Structure
- Unit tests: `*_test.go` (same package)
- Integration tests: `tests/integration/`

### Test Naming
```go
func TestUserService_Create_ShouldReturnError_WhenEmailInvalid(t *testing.T) {
    // Test implementation
}
```
```

---

## 3. Project Structure 영역

### 목적
코드 작성 위치를 명확히 정의

### 필수 포함 항목
1. 주요 디렉토리 역할
2. 파일 명명 규칙
3. 자동 생성 폴더 표시

### 작성 패턴

```markdown
## Project Structure

```
project-root/
├── src/
│   ├── components/           # React components (PascalCase.tsx)
│   ├── hooks/                # Custom React hooks (use*.ts)
│   ├── pages/                # Next.js pages (kebab-case.tsx)
│   ├── services/             # API services (camelCase.ts)
│   ├── utils/                # Pure utility functions
│   ├── types/                # TypeScript type definitions
│   └── __tests__/            # Co-located unit tests
│
├── tests/
│   ├── integration/          # Cross-module tests
│   └── e2e/                  # End-to-end tests (*.spec.ts)
│
├── public/                   # Static assets (served as-is)
│   ├── images/
│   └── fonts/
│
├── docs/                     # Auto-generated documentation
│   ├── api/                  # API docs (TypeDoc)
│   └── coverage/             # Test coverage reports
│
├── scripts/                  # Build/deployment scripts
└── config/                   # Configuration files
```

### File Naming Rules
- **Components**: PascalCase (Button.tsx, UserProfile.tsx)
- **Hooks**: camelCase with 'use' prefix (useAuth.ts, useFetch.ts)
- **Utils**: camelCase (formatDate.ts, validateEmail.ts)
- **Tests**: Same name + .test or .spec (Button.test.tsx, api.spec.ts)
- **Pages**: kebab-case (user-profile.tsx, checkout-success.tsx)

### Auto-generated Folders (Do not edit!)
- `dist/` - Build output
- `node_modules/` - Dependencies
- `coverage/` - Test coverage reports
- `docs/api/` - Generated API documentation
```

### 아키텍처별 패턴

**Clean Architecture**
```markdown
```
src/
├── domain/                   # Business logic (entities, use cases)
│   ├── entities/
│   └── usecases/
├── application/              # Application services
│   └── services/
├── infrastructure/           # External dependencies
│   ├── database/
│   └── api/
└── presentation/             # UI layer
    ├── controllers/
    └── views/
```
```

**Feature-based Structure**
```markdown
```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   └── types/
│   ├── dashboard/
│   └── settings/
└── shared/                   # Shared across features
    ├── components/
    └── utils/
```
```

---

## 4. Code Style 영역

### 목적
코드 작성 방식을 예시로 명확히 전달

### 핵심 원칙
**설명 3단락 < 예시 1개**

### 작성 패턴

```markdown
## Code Style

### General Principles
- **TypeScript strict mode** enabled
- **Pure functions** preferred over stateful logic
- **Named exports** over default exports
- **Explicit typing** (no implicit any)

### Function Style

```typescript
// ✅ Good: Pure, typed, single responsibility
export function calculateDiscount(
  price: number,
  discountRate: number
): number {
  if (price < 0 || discountRate < 0 || discountRate > 1) {
    throw new Error('Invalid input');
  }
  return price * (1 - discountRate);
}

// ❌ Bad: Implicit any, mutation, multiple responsibilities
function calc(p, d) {
  let result = p;
  result = result - (result * d);
  console.log(result); // Side effect
  return result;
}
```

### Component Style (React)

```tsx
// ✅ Good: Typed props, named export, composition
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <Card>
      <CardHeader>{user.name}</CardHeader>
      <CardBody>{user.email}</CardBody>
      <CardFooter>
        <Button onClick={() => onEdit(user.id)}>Edit</Button>
      </CardFooter>
    </Card>
  );
}

// ❌ Bad: No types, default export, inline styles
export default function Card(props) {
  return (
    <div style={{ padding: '10px' }}>
      <h2>{props.user.name}</h2>
      <p>{props.user.email}</p>
      <button onClick={() => props.onEdit(props.user.id)}>Edit</button>
    </div>
  );
}
```

### Error Handling

```typescript
// ✅ Good: Custom error types, explicit handling
export class ValidationError extends Error {
  constructor(public field: string, message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export function validateUser(data: unknown): User {
  if (!isObject(data)) {
    throw new ValidationError('data', 'Must be an object');
  }
  // Validation logic
  return data as User;
}

// ❌ Bad: Generic errors, swallowed errors
function validateUser(data) {
  try {
    // Validation logic
  } catch (e) {
    console.log(e); // Error swallowed
  }
}
```

### Async/Await

```typescript
// ✅ Good: Explicit error handling, typed
export async function fetchUser(id: string): Promise<User> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    throw new Error(`Failed to fetch user: ${error.message}`);
  }
}

// ❌ Bad: No error handling, promise chain
export function fetchUser(id) {
  return fetch(`/api/users/${id}`)
    .then(res => res.json())
    .then(data => data);
}
```
```

### 언어별 예시

**Python**
```markdown
### Function Style

```python
# ✅ Good: Type hints, docstring, pure
def calculate_discount(price: float, rate: float) -> float:
    """Calculate discounted price.

    Args:
        price: Original price (must be positive)
        rate: Discount rate (0.0 to 1.0)

    Returns:
        Discounted price

    Raises:
        ValueError: If inputs are invalid
    """
    if price < 0 or not 0 <= rate <= 1:
        raise ValueError("Invalid input")
    return price * (1 - rate)

# ❌ Bad: No types, no validation
def calc(p, r):
    return p * (1 - r)
```
```

**Go**
```markdown
### Function Style

```go
// ✅ Good: Error handling, documented
// CalculateDiscount returns the discounted price.
// Returns an error if inputs are invalid.
func CalculateDiscount(price, rate float64) (float64, error) {
    if price < 0 || rate < 0 || rate > 1 {
        return 0, fmt.Errorf("invalid input: price=%f, rate=%f", price, rate)
    }
    return price * (1 - rate), nil
}

// ❌ Bad: Panic on error, no docs
func calc(p, r float64) float64 {
    if p < 0 {
        panic("invalid price")
    }
    return p * (1 - r)
}
```
```

---

## 5. Git Workflow 영역

### 목적
협업 규칙과 커밋 컨벤션 정의

### 필수 포함 항목
1. 브랜치 명명 규칙
2. 커밋 메시지 형식
3. PR 요구사항

### 작성 패턴

```markdown
## Git Workflow

### Branch Naming

**Format**: `type/short-description`

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature | `feat/oauth-login` |
| `fix` | Bug fix | `fix/header-alignment` |
| `refactor` | Code refactoring | `refactor/api-client` |
| `docs` | Documentation | `docs/update-readme` |
| `test` | Add/update tests | `test/user-service` |
| `chore` | Maintenance | `chore/upgrade-deps` |

### Commit Message Format

**Convention**: Conventional Commits

```
type(scope): subject

[optional body]

[optional footer]
```

**Examples**:
```
feat(auth): add OAuth 2.0 login

Implemented Google and GitHub OAuth providers
using Passport.js strategy.

Closes #123
```

```
fix(api): handle 404 errors in user endpoint

Previously, 404s were returning 500. Now properly
returns 404 with error message.
```

```
refactor(utils): simplify date formatting

Replaced moment.js with native Intl.DateTimeFormat
to reduce bundle size by 50KB.
```

**Rules**:
- Type: feat, fix, refactor, docs, test, chore
- Scope: Module/component name (optional)
- Subject: Imperative mood, lowercase, no period
- Body: Explain WHY, not WHAT (optional)
- Footer: Issue references, breaking changes

### Pull Request Requirements

**Before Opening PR**:
1. ✅ All tests passing locally
2. ✅ Linter/formatter passing
3. ✅ Branch up-to-date with main
4. ✅ Descriptive PR title (same format as commits)

**PR Template**:
```markdown
## Summary
[What changed and why]

## Changes
- Added X
- Modified Y
- Removed Z

## Testing
- [ ] Unit tests added/updated
- [ ] E2E tests passing
- [ ] Manually tested in browser

## Screenshots (if UI changes)
[Attach screenshots]

## Checklist
- [ ] Code follows style guide
- [ ] Tests added/updated
- [ ] Documentation updated
```

**Review Requirements**:
- 1 approval required
- No unresolved comments
- CI passing (all checks green)

**Merge Strategy**:
- Squash and merge (keep history clean)
- Delete branch after merge
```

### 팀 규모별 패턴

**소규모 팀 (1-3명)**
```markdown
### Branch Strategy
- `main` - Production
- `feat/*` - Feature branches (merge directly to main)

### Merge
- Direct merge to main (with approval)
- No develop branch needed
```

**중/대규모 팀**
```markdown
### Branch Strategy
- `main` - Production (protected)
- `develop` - Integration branch
- `feat/*` - Feature branches (merge to develop)
- `release/*` - Release candidates

### Merge
- Feature → develop (squash merge)
- develop → main (merge commit, tagged)
```

---

## 6. Boundaries 영역 (가장 중요!)

### 목적
AI와 개발자가 할 수 있는/없는 것을 명확히 정의

### 3단계 시스템

```markdown
## Boundaries

### ✅ Always (항상 실행, 질문 불필요)

**Testing**
- Run `npm test` before every commit
- Ensure coverage ≥ 80% for new code
- Update tests when changing implementation

**Code Quality**
- Follow ESLint/Prettier rules (no warnings)
- Fix TypeScript errors (strict mode)
- Run `npm run lint && npm run typecheck` before push

**Documentation**
- Update JSDoc comments for public APIs
- Add README section for new features
- Update CHANGELOG.md for user-facing changes

**Git**
- Write descriptive commit messages (Conventional Commits)
- Rebase feature branch on latest main before PR
- Delete branch after merge

---

### ⚠️ Ask First (승인 필요, 자동 진행 금지)

**Dependencies**
- Adding new npm packages (check bundle size impact)
- Upgrading major versions (breaking changes possible)
- Removing dependencies (ensure not used transitively)

**Database**
- Creating/modifying schema (migrations required)
- Adding indexes (performance impact)
- Changing constraints (data validation needed)

**API Changes**
- Modifying public API contracts (breaking change)
- Adding new endpoints (security review)
- Changing authentication (impact on clients)

**Configuration**
- Updating Node.js/TypeScript versions
- Changing build/bundler config
- Modifying CI/CD pipeline

**Architecture**
- Introducing new design patterns
- Changing folder structure
- Adding new layers/abstractions

---

### 🚫 Never (절대 금지, 즉시 중단)

**Security**
- ❌ Commit `.env`, `.env.local`, or any secrets
- ❌ Hardcode API keys, passwords, tokens in code
- ❌ Disable security linters (e.g., eslint-plugin-security)
- ❌ Commit SSH keys, certificates, or credentials

**Version Control**
- ❌ `git push --force` on `main` or `develop` branches
- ❌ Commit directly to `main` (always use PR)
- ❌ Modify published git history (no rebase on public branches)
- ❌ Commit large binary files (use Git LFS)

**Generated/External Code**
- ❌ Edit files in `node_modules/`
- ❌ Modify files in `dist/`, `build/`, `.next/`
- ❌ Edit auto-generated files (marked with "DO NOT EDIT")
- ❌ Change vendored dependencies

**Code Quality**
- ❌ Use `@ts-ignore` or `any` type (use proper typing)
- ❌ Disable ESLint rules inline without justification
- ❌ Skip pre-commit hooks (`--no-verify`)
- ❌ Leave `console.log()` in production code

**Testing**
- ❌ Skip test writing for new features
- ❌ Commit with failing tests
- ❌ Lower coverage threshold to pass CI
- ❌ Mock everything (prefer integration tests)

**Performance**
- ❌ Introduce synchronous blocking operations (use async)
- ❌ Add dependencies >100KB without justification
- ❌ Disable caching without performance testing
```

### 프로젝트별 커스터마이징

**보안 중요 프로젝트**
```markdown
### 🚫 Never (Security Focus)
- ❌ Install packages with known vulnerabilities (check `npm audit`)
- ❌ Use `eval()`, `Function()`, or `innerHTML`
- ❌ Accept user input without validation/sanitization
- ❌ Store passwords in plain text (use bcrypt/argon2)
- ❌ Expose internal error details to users
```

**성능 중요 프로젝트**
```markdown
### 🚫 Never (Performance Focus)
- ❌ Block main thread for >16ms (60 FPS target)
- ❌ Make sequential API calls (use Promise.all)
- ❌ Add dependencies without tree-shaking
- ❌ Render large lists without virtualization
```

**팀 협업 중요 프로젝트**
```markdown
### ⚠️ Ask First (Collaboration Focus)
- Renaming public functions/classes (IDE refactor needed)
- Moving files (update imports across team)
- Changing API response format (frontend impact)
```

---

## Validation Checklist

스펙 작성 후 이 체크리스트로 검증하세요:

### Completeness (완전성)
- [ ] 6개 영역 모두 작성됨
- [ ] Commands에 개발/테스트/빌드 포함
- [ ] Testing에 프레임워크 + 커버리지 명시
- [ ] Project Structure에 주요 디렉토리 설명
- [ ] Code Style에 ✅/❌ 예시 포함
- [ ] Git Workflow에 브랜치/커밋/PR 규칙
- [ ] Boundaries에 Always/Ask/Never 3단계 구분

### Executability (실행 가능성)
- [ ] 모든 Commands 실제 실행 가능
- [ ] 파일 경로가 실제 존재
- [ ] 테스트 커버리지 측정 가능
- [ ] Git 브랜치 규칙 적용 가능

### Clarity (명확성)
- [ ] 신규 개발자가 읽고 바로 시작 가능
- [ ] 모호한 표현 없음 ("적절히", "가능하면" 등)
- [ ] Code Style에 충분한 예시 (최소 3개)
- [ ] Boundaries에 구체적 파일/명령어 명시

### Specificity (구체성)
- [ ] "중요한 파일" → 구체적 경로
- [ ] "테스트 작성" → 최소 커버리지 수치
- [ ] "코드 리뷰" → 승인 인원, 조건 명시
- [ ] "린트 통과" → 구체적 명령어

### Maintainability (유지보수성)
- [ ] 버전 명시 (Version, Last Updated)
- [ ] Changelog 섹션 포함
- [ ] 리뷰 주기 명시 (예: 월 1회)
