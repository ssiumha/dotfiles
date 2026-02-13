---
name: dep-graph
description: Analyzes file-level import dependencies and generates interactive vis-network HTML report. Use when visualizing dependency graphs, analyzing import structure, checking circular dependencies, or understanding module relationships.
argument-hint: "[--scope=<path>] [--depth=<N>] [--exclude=<glob>]"
---

# Dependency Graph

프로젝트 내 파일 간 import 의존성을 분석하여 vis-network 기반 인터랙티브 HTML 보고서를 생성합니다.

**핵심 원칙**:
- 노드 단위: 파일 (범용적, 구현 단순)
- 추출: Python 스크립트 우선, 수동 분석 폴백
- 시각화: vis-network CDN (단일 파일, 물리 내장)
- 색상: 최상위 디렉토리 기반 자동 배정 (12색 팔레트)

## Quick Reference

```bash
/dep-graph                          # 현재 디렉토리 전체
/dep-graph --scope=src/             # 특정 디렉토리만
/dep-graph --depth=2                # import 깊이 제한
/dep-graph --exclude="**/*.test.*"  # 테스트 파일 제외
```

## Instructions

### Phase 0: 스크립트 실행 (권장)

Python3가 설치되어 있으면 스크립트로 전체 파이프라인을 실행한다.

```bash
python3 {SKILL_DIR}/scripts/build-graph.py \
  --root {PROJECT_ROOT} \
  --template {SKILL_DIR}/templates/report.html \
  --output dep-graph.html \
  [--scope {scope}] [--depth {depth}] [--exclude {pattern}]
```

- `{SKILL_DIR}`: 이 스킬의 디렉토리 경로 (SKILL.md가 있는 곳)
- `{PROJECT_ROOT}`: 분석 대상 프로젝트 루트
- 인자는 사용자 입력(`--scope`, `--depth`, `--exclude`)이 있으면 전달

스크립트가 성공하면 **Phase 4-4 결과 보고**로 바로 이동.
실패 시 Phase 1부터 수동 진행.

---

### Phase 1: 스코프 및 언어 감지 (수동 폴백)

**1-1. 대상 파일 수집**

```bash
# scope 인자 해석
--scope=<path>  → 해당 경로 하위
(없으면)        → 현재 작업 디렉토리 전체
```

Glob으로 소스 파일 수집:
```
**/*.{ts,tsx,js,jsx,mjs,cjs}   → TypeScript/JavaScript
**/*.java                       → Java
**/*.py                         → Python
**/*.go                         → Go
**/*.rs                         → Rust
```

`--exclude` 인자가 있으면 해당 패턴 제외. 기본 제외:
- `node_modules/`, `vendor/`, `build/`, `dist/`, `.git/`
- `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`

**1-2. 언어 판별**

확장자 빈도 기준 주 언어 결정. 혼합 프로젝트는 모든 언어 처리.

**1-3. depth 제한**

`--depth=N` 지정 시, 스코프 루트로부터 N단계까지만 따라감. 기본값: 무제한.

---

### Phase 2: 의존성 추출

언어별 패턴 파일 참조하여 import문 추출.

**2-1. ast-grep 시도 (우선)**

ast-grep이 설치되어 있으면 (`which ast-grep`) 정확한 AST 기반 추출:

```bash
# ast-grep으로 import문 검색
ast-grep --pattern '<PATTERN>' --json <file>
```

언어별 패턴은 resources/patterns/ 참조:
- TypeScript/JavaScript → `resources/patterns/typescript.md`
- Java → `resources/patterns/java.md`

**2-2. grep 폴백**

ast-grep 미설치 시 정규식 기반 추출:

```bash
# TypeScript/JavaScript
grep -nE "^import .+ from ['\"]|require\(['\"]" <file>

# Java
grep -nE "^import (static )?[a-zA-Z]" <file>

# Python
grep -nE "^(from .+ import|import )" <file>

# Go
grep -nE "\"[a-zA-Z0-9_/.-]+\"" <file>  # import block 내부
```

**2-3. 경로 해석**

추출된 import 경로를 실제 파일 경로로 매핑:

| 유형 | 처리 |
|------|------|
| 상대 경로 (`./`, `../`) | 현재 파일 기준 resolve, 확장자 탐색 |
| 별칭 (alias) | tsconfig.json `paths`, webpack alias 등 읽어서 매핑 |
| 패키지/외부 | `external` 노드로 그룹화 (선택 표시) |
| 배럴 (`index.ts`) | 디렉토리 import 시 `index.*` 자동 탐색 |

**확장자 탐색 순서** (TypeScript):
`.ts` → `.tsx` → `.js` → `.jsx` → `/index.ts` → `/index.tsx` → `/index.js`

---

### Phase 3: 그래프 데이터 구성

**3-1. 데이터 구조 생성**

```javascript
const GRAPH_DATA = {
  nodes: [
    { id: "src/api/user.ts", label: "user.ts", group: "api", title: "src/api/user.ts\nImports: 3\nImported by: 5" }
  ],
  edges: [
    { from: "src/api/user.ts", to: "src/models/User.ts", arrows: "to" }
  ],
  groups: {
    "api": { color: "#4FC3F7" },
    "models": { color: "#81C784" }
  },
  stats: {
    totalFiles: 42,
    totalEdges: 87,
    avgDependencies: 2.07,
    maxFanOut: { file: "src/index.ts", count: 12 },
    maxFanIn: { file: "src/utils/helpers.ts", count: 15 },
    circular: [["src/a.ts", "src/b.ts", "src/a.ts"]],
    externalDeps: ["react", "lodash"]
  }
};
```

**3-2. 노드 속성**

- `id`: 스코프 루트 상대 경로
- `label`: 파일명만 (디렉토리 없이)
- `group`: 최상위 디렉토리명 (색상 그룹)
- `title`: 호버 시 표시할 상세 정보
- `size`: fan-in 비례 (참조 많을수록 큼)

**3-3. 색상 팔레트 (12색 순환)**

```javascript
const PALETTE = [
  "#4FC3F7", "#81C784", "#FFB74D", "#E57373",
  "#BA68C8", "#4DD0E1", "#FFD54F", "#A1887F",
  "#90A4AE", "#F06292", "#AED581", "#7986CB"
];
```

최상위 디렉토리 등장 순서대로 배정.

**3-4. 순환 참조 탐지**

DFS로 사이클 탐지. 발견된 사이클은 `stats.circular`에 기록.

---

### Phase 4: HTML 리포트 생성

**4-1. 템플릿 로딩**

`templates/report.html` 파일을 Read로 읽는다.

**4-2. 데이터 주입**

템플릿 내 `{{GRAPH_DATA}}` 플레이스홀더를 Phase 3에서 구성한 JSON으로 교체.

`</script>` 문자열이 포함되면 HTML 파싱이 깨지므로 반드시 이스케이프:

```javascript
const jsonStr = JSON.stringify(GRAPH_DATA)
  .replace(/</g, '\\u003c')
  .replace(/>/g, '\\u003e');
template.replace('{{GRAPH_DATA}}', jsonStr);
```

**4-3. 파일 출력**

```
dep-graph.html    # 프로젝트 루트에 생성
```

**4-4. 결과 보고**

생성 완료 후 사용자에게 보고:

```
## Dependency Graph Report

- 파일: `dep-graph.html`
- 노드: {totalFiles}개 파일
- 엣지: {totalEdges}개 의존성
- 평균 의존성: {avgDependencies}
- 최대 Fan-out: {maxFanOut.file} ({maxFanOut.count})
- 최대 Fan-in: {maxFanIn.file} ({maxFanIn.count})
- 순환 참조: {circular.length}개 발견
- 외부 패키지: {externalDeps.length}개

브라우저에서 `dep-graph.html`을 열어 확인하세요.
```

순환 참조가 있으면 경고와 함께 사이클 경로 표시.

## Output Format

단일 HTML 파일 (`dep-graph.html`). 브라우저에서 열면:

- **사이드바**: 검색, 디렉토리 필터, 통계, 노드 상세
- **툴바**: Reset / Physics 토글 / External 토글 / Circular 하이라이트
- **인터랙션**: 클릭→연결 하이라이트, 더블클릭→포커스, 드래그 이동
- **테마**: `prefers-color-scheme` 자동 (dark/light)

## Technical Details

**스크립트**: `scripts/build-graph.py`
- Python 3.10+ 필요 (표준 라이브러리만 사용, 외부 의존성 없음)
- 지원 언어: Java, TypeScript/JavaScript, Python
- Java source root 자동 탐색 (`**/src/main/java`)
- Java 내부 패키지 자동 판별 (source root의 top-level 패키지 수집)
- tsconfig.json `compilerOptions.paths` alias 자동 읽기 (JSONC 지원)
- 순환 참조 탐지 (iterative DFS, 대규모 프로젝트 안전)
- `--json` 플래그로 stats JSON 출력 (스크립트 체이닝용)
- 파일 읽기 실패 시 skip + stderr 경고
