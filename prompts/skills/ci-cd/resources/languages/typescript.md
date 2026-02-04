# TypeScript: Biome + Vitest

TypeScript 프로젝트의 lint, format, test 도구 설정입니다.

**핵심 도구**:
- **Biome**: ESLint + Prettier 대체 (빠르고 간단)
- **Vitest** 또는 **Jest**: 테스트 프레임워크
- **tsc**: 타입 체크

## Biome

### 설치

```bash
npm install --save-dev @biomejs/biome
```

### biome.json

```json
{
  "$schema": "https://biomejs.dev/schemas/1.4.1/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "suspicious": {
        "noExplicitAny": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "trailingComma": "es5",
      "semicolons": "asNeeded"
    }
  }
}
```

### package.json

```json
{
  "scripts": {
    "lint": "biome check .",
    "lint:fix": "biome check --apply .",
    "format": "biome format --write ."
  }
}
```

## Vitest

### 설치

```bash
npm install --save-dev vitest @vitest/ui
```

### vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config'
import path from 'path'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'tests/', '**/*.d.ts'],
    },
    include: ['tests/**/*.test.ts'],
    exclude: ['tests/e2e/**'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

### package.json

```json
{
  "scripts": {
    "test": "vitest",
    "test:unit": "vitest run tests/unit",
    "test:e2e": "vitest run tests/e2e",
    "test:coverage": "vitest run --coverage"
  }
}
```

## E2E 테스트

### DB 테스트

```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

describe('User E2E', () => {
  beforeEach(async () => {
    await prisma.user.deleteMany()
  })

  it('should create and find user', async () => {
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test',
      },
    })

    const found = await prisma.user.findUnique({
      where: { id: user.id },
    })

    expect(found).toEqual(user)
  })
})
```

## 타입 체크

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "outDir": "./dist",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### package.json

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "tsc"
  }
}
```

## Pre-commit Hooks

### Husky

```json
{
  "devDependencies": {
    "husky": "^8.0.0",
    "lint-staged": "^14.0.0"
  }
}
```

**.husky/pre-commit**
```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
```

**package.json**
```json
{
  "lint-staged": {
    "*.{js,ts}": ["biome check --apply", "vitest related --run"],
    "*.{json,md}": ["biome format --write"]
  }
}
```

## Justfile (참고: 01-local-ci.md)

```justfile
# Lint
lint:
    npx biome check .

lint-fix:
    npx biome check --apply .

# 타입 체크
typecheck:
    npx tsc --noEmit

# 유닛 테스트
test-unit:
    npx vitest run tests/unit

# E2E 테스트
test-e2e: db-test-up
    DATABASE_URL=postgres://test_user:test_pass@localhost:5433/test_db \
    npx vitest run tests/e2e
    just db-test-down

# 전체 CI
ci: lint typecheck test-unit test-e2e
    @echo "✓ All checks passed!"
```

## 베스트 프랙티스

### 빠른 피드백
- Biome은 ESLint보다 10-100배 빠름
- Vitest는 빠른 HMR 지원

### 타입 안전성
```typescript
// noUncheckedIndexedAccess
const item = array[0] // item: T | undefined

// strictNullChecks
function greet(name?: string) {
  console.log(name?.toUpperCase()) // OK
}
```

### 테스트 격리
```typescript
beforeEach(async () => {
  await prisma.$executeRaw`TRUNCATE TABLE users CASCADE`
})
```

## 트러블슈팅

### ESLint → Biome 마이그레이션
```bash
npx @biomejs/biome migrate eslint --write
```

### Path alias 인식 안됨
```typescript
// vitest.config.ts
export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

## 참고

- Biome: https://biomejs.dev/
- Vitest: https://vitest.dev/
- TypeScript: https://www.typescriptlang.org/docs/
