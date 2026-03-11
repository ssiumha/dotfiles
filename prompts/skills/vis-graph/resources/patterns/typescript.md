# TypeScript/JavaScript Import Patterns

ast-grep 및 grep 패턴으로 TS/JS 파일의 import문을 추출합니다.

## ast-grep Patterns

### ES6 import

```yaml
# Named import: import { foo } from 'bar'
rule:
  kind: import_statement
```

```bash
# 단일 패턴으로 모든 import_statement 캡처
ast-grep --pattern 'import $$$ARGS from "$SOURCE"' --json <file>
```

### Dynamic import

```bash
ast-grep --pattern 'import($SOURCE)' --json <file>
```

### Require (CommonJS)

```bash
ast-grep --pattern 'require($SOURCE)' --json <file>
```

### Export from (re-export)

```bash
ast-grep --pattern 'export $$$ARGS from "$SOURCE"' --json <file>
```

## grep Fallback Patterns

ast-grep 미설치 시 아래 정규식 사용:

```bash
# ES6 import (모든 변형)
grep -oP "(?:import|export)\s+.*?from\s+['\"]([^'\"]+)['\"]" <file>

# require()
grep -oP "require\(['\"]([^'\"]+)['\"]\)" <file>

# Dynamic import
grep -oP "import\(['\"]([^'\"]+)['\"]\)" <file>
```

**캡처 그룹 1**이 import 경로.

## 경로 해석 (Path Resolution)

### 상대 경로 (`./`, `../`)

현재 파일 위치 기준으로 resolve. 확장자 탐색 순서:

```
1. 정확한 경로 (확장자 포함)
2. .ts → .tsx → .js → .jsx → .mjs → .cjs
3. /index.ts → /index.tsx → /index.js → /index.jsx
```

### 별칭 (Alias)

tsconfig.json의 `compilerOptions.paths` 확인:

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"]
    }
  }
}
```

**매핑 절차**:
1. tsconfig.json (또는 jsconfig.json) 읽기
2. `paths` 키에서 패턴 매칭
3. `baseUrl` 기준으로 실제 경로 계산

### 패키지 (External)

`node_modules/`에 존재하는 패키지 → `external` 그룹으로 분류:

- 판별: `./`, `../`, `@/` 등 alias로 시작하지 않는 import
- 예: `react`, `lodash`, `@nestjs/common`
- 노드 생성: `{ id: "ext:react", label: "react", group: "external", external: true }`

### 배럴 패턴 (Barrel/Index)

디렉토리를 직접 import하는 경우:

```typescript
import { Foo } from './components';  // → ./components/index.ts
```

해당 디렉토리 내 `index.*` 파일 탐색.

## 제외 패턴

기본적으로 의존성 추출에서 제외:

```
- Type-only import → 옵션에 따라 포함/제외
- Side-effect import (import './polyfill') → 엣지 생성하되 표시 구분
- CSS/JSON/이미지 import → 무시
```

파일 확장자로 판별:
```
무시: .css, .scss, .less, .json, .png, .jpg, .svg, .gif, .woff, .ttf
```
