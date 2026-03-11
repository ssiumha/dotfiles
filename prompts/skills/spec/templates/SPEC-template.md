# SPEC.md

Version: 1.0.0
Last Updated: YYYY-MM-DD

## Commands

### Development
- `[command]` - [Description with port/path]

### Build
- `[command]` - [Description with output location]

### Testing
- `[command]` - Run all tests
- `[command]` - Watch mode
- `[command]` - Coverage report (minimum: X%)

### Code Quality
- `[command]` - Linter
- `[command]` - Formatter
- `[command]` - Type check

---

## Testing

### Framework & Tools
- **Unit/Integration**: [Framework name]
- **E2E**: [Framework name]
- **Coverage**: [Tool name]

### Test Structure
```
src/
├── [dir]/
│   └── [file].test.ts    # [Description]
tests/
├── integration/          # [Description]
└── e2e/                  # [Description]
```

### Coverage Requirements
- **Global minimum**: X% (lines, branches, functions)
- **Critical paths**: 100% ([list modules])

### Test Naming Convention
```typescript
describe('[ComponentName]', () => {
  it('should [expected behavior] when [condition]', () => {
    // Test implementation
  });
});
```

---

## Project Structure

```
project-root/
├── src/
│   ├── [dir]/            # [Description]
│   └── [dir]/            # [Description]
├── tests/                # [Description]
├── public/               # Static assets
└── docs/                 # Documentation
```

### File Naming Rules
- **[Type]**: [Convention] ([Example])

### Auto-generated Folders (Do not edit!)
- `[dir]/` - [Description]

---

## Code Style

### [Category 1]

```[lang]
// ✅ Good: [Why this is good]
[code example]

// ❌ Bad: [Why this is bad]
[code example]
```

### [Category 2]

```[lang]
// ✅ Good: [Why this is good]
[code example]

// ❌ Bad: [Why this is bad]
[code example]
```

---

## Git Workflow

### Branch Naming

**Format**: `type/short-description`

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature | `feat/oauth-login` |
| `fix` | Bug fix | `fix/header-alignment` |
| `refactor` | Code refactoring | `refactor/api-client` |
| `docs` | Documentation | `docs/update-readme` |

### Commit Message Format

**Convention**: [Convention name]

```
type(scope): subject

[optional body]
```

**Examples**:
```
feat(auth): add OAuth login
fix(api): handle 404 errors
```

### Pull Request Requirements

**Before Opening PR**:
1. ✅ All tests passing
2. ✅ Linter/formatter passing
3. ✅ Branch up-to-date with main

**Review Requirements**:
- [Number] approval(s) required
- CI passing

**Merge Strategy**:
- [Squash/Merge/Rebase] and merge

---

## Boundaries

### ✅ Always (항상 실행, 질문 불필요)

**Testing**
- Run `[test command]` before every commit
- Ensure coverage ≥ X% for new code
- Update tests when changing implementation

**Code Quality**
- Follow linter/formatter rules
- Fix type errors
- [Add specific practices]

**Documentation**
- Update comments for public APIs
- [Add specific practices]

**Git**
- Write descriptive commit messages
- [Add specific practices]

---

### ⚠️ Ask First (승인 필요, 자동 진행 금지)

**Dependencies**
- Adding new packages
- Upgrading major versions
- Removing dependencies

**Database**
- Creating/modifying schema
- Adding indexes

**API Changes**
- Modifying public API contracts
- Adding new endpoints

**Configuration**
- Updating runtime versions
- Changing build config

**Architecture**
- Introducing new design patterns
- Changing folder structure

---

### 🚫 Never (절대 금지, 즉시 중단)

**Security**
- ❌ Commit `.env` or any secrets
- ❌ Hardcode API keys, passwords, tokens
- ❌ Disable security linters

**Version Control**
- ❌ `git push --force` on `main` or `develop`
- ❌ Commit directly to `main` (always use PR)

**Generated/External Code**
- ❌ Edit files in `node_modules/`
- ❌ Modify files in `dist/`, `build/`
- ❌ Edit auto-generated files

**Code Quality**
- ❌ Use `@ts-ignore` or `any` type without justification
- ❌ Disable linter rules inline without reason
- ❌ Skip pre-commit hooks

**Testing**
- ❌ Skip test writing for new features
- ❌ Commit with failing tests
- ❌ Lower coverage threshold to pass CI

---

## Changelog

### 1.0.0 (YYYY-MM-DD)
- Initial specification
