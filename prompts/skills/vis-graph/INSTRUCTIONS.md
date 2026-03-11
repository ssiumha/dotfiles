# vis-graph

파일 의존성 그래프(dep 모드) 또는 DB 스키마 ERD(schema 모드)를 vis-network 기반 인터랙티브 HTML로 시각화합니다.

## Mode Routing

| 인자 패턴 | 모드 | 예시 |
|-----------|------|------|
| `schema <conn-string>` | **Schema** | `/vis-graph schema postgresql://localhost/mydb` |
| 그 외 (기본) | **Dep** | `/vis-graph`, `/vis-graph --scope=src/` |

첫 번째 인자가 `schema`이면 Schema 모드, 아니면 Dep 모드로 진입한다.

---

# Dep Mode — Dependency Graph

프로젝트 내 파일 간 import 의존성을 분석하여 vis-network 기반 인터랙티브 HTML 보고서를 생성합니다.

**핵심 원칙**:
- 노드 단위: 파일 (범용적, 구현 단순)
- 추출: Python 스크립트 우선, 수동 분석 폴백
- 시각화: vis-network CDN (단일 파일, 물리 내장)
- 색상: 최상위 디렉토리 기반 자동 배정 (12색 팔레트)

## Quick Reference

```bash
/vis-graph                          # 현재 디렉토리 전체
/vis-graph --scope=src/             # 특정 디렉토리만
/vis-graph --depth=2                # import 깊이 제한
/vis-graph --exclude="**/*.test.*"  # 테스트 파일 제외
```

## Instructions

### Phase 0: 스크립트 실행 (권장)

Python3가 설치되어 있으면 스크립트로 전체 파이프라인을 실행한다.

```bash
python3 {SKILL_DIR}/scripts/build-graph.py \
  --root {PROJECT_ROOT} \
  --template {SKILL_DIR}/templates/dep.html \
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

`templates/dep.html` 파일을 Read로 읽는다.

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

## Dep Output Format

단일 HTML 파일 (`dep-graph.html`). 브라우저에서 열면:

- **사이드바**: 검색, 디렉토리 필터, 통계, 노드 상세
- **툴바**: Reset / Physics 토글 / External 토글 / Circular 하이라이트
- **인터랙션**: 클릭→연결 하이라이트, 더블클릭→포커스, 드래그 이동
- **테마**: `prefers-color-scheme` 자동 (dark/light)

## Dep Technical Details

**스크립트**: `scripts/build-graph.py`
- Python 3.10+ 필요 (표준 라이브러리만 사용, 외부 의존성 없음)
- 지원 언어: Java, TypeScript/JavaScript, Python
- Java source root 자동 탐색 (`**/src/main/java`)
- Java 내부 패키지 자동 판별 (source root의 top-level 패키지 수집)
- Java 같은 패키지 내 `extends`/`implements` 관계 자동 감지 (import 없이도 edge 추가)
- tsconfig.json `compilerOptions.paths` alias 자동 읽기 (JSONC 지원)
- 순환 참조 탐지 (iterative DFS, 대규모 프로젝트 안전)
- `--json` 플래그로 stats JSON 출력 (스크립트 체이닝용)
- 파일 읽기 실패 시 skip + stderr 경고

---

# Schema Mode — Schema Graph (ERD)

DB 접속 정보를 받아 스키마를 분석하고, vis-network 기반 인터랙티브 HTML ERD를 생성합니다.

**핵심 원칙**:
- 추출: Python 스크립트 우선, 수동 분석 폴백
- 시각화: vis-network CDN (단일 파일, 물리 내장)
- 색상: 듀얼 모드 — 스키마/네임스페이스 vs 테이블 유형
- DB 지원: PostgreSQL + SQLite

## Quick Reference

```bash
/vis-graph schema postgresql://user:pass@localhost/mydb
/vis-graph schema sqlite:///path/to/db.sqlite
/vis-graph schema postgresql://localhost/mydb --schema=public
/vis-graph schema sqlite:///app.db --exclude="migration_*"
```

## Instructions

### Phase 0: 스크립트 실행 (권장)

Python3가 설치되어 있으면 스크립트로 전체 파이프라인을 실행한다.

```bash
python3 {SKILL_DIR}/scripts/extract-schema.py \
  --conn "<connection-string>" \
  --template {SKILL_DIR}/templates/schema.html \
  --output schema-graph.html \
  [--schema <name>] [--exclude <pattern>] [--group-by type]
```

- `{SKILL_DIR}`: 이 스킬의 디렉토리 경로 (SKILL.md가 있는 곳)
- `--conn`: DB 접속 URL (필수). `postgresql://user:pass@host/db` 또는 `sqlite:///path`
- `--schema`: 특정 스키마 필터 (PG용. 기본: 시스템 스키마 제외 전체)
- `--exclude`: 테이블 제외 glob (반복 가능)
- `--group-by`: `schema` (기본) 또는 `type`

스크립트가 성공하면 **Phase 4-4 결과 보고**로 바로 이동.
실패 시 Phase 1부터 수동 진행.

---

### Phase 1: 접속 및 DB 유형 감지 (수동 폴백)

**1-1. 접속 URL 파싱**

| 스킴 | DB | 도구 |
|------|-----|------|
| `postgresql://`, `postgres://` | PostgreSQL | `psql` CLI |
| `sqlite:///` | SQLite | `sqlite3` CLI 또는 Python |

**1-2. 접속 테스트**

- PostgreSQL: `psql -h host -p port -U user -d db -c "SELECT 1"`
- SQLite: 파일 존재 확인

**1-3. 에러 처리**

- psql 미설치: `"psql is not installed. Install PostgreSQL client: brew install libpq"` 출력 후 중단
- 접속 실패: 30초 타임아웃, 에러 메시지 표시
- 빈 DB: `"No tables found in database."` 출력 후 중단

---

### Phase 2: 스키마 추출 (수동 폴백)

`resources/queries/postgresql.md` 참조하여 SQL로 스키마 정보 추출.

**2-1. SQLite 추출**

```sql
-- 테이블 목록
SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';

-- 컬럼 (각 테이블)
PRAGMA table_info({table});

-- FK (각 테이블)
PRAGMA foreign_key_list({table});

-- 인덱스 (각 테이블)
PRAGMA index_list({table});
PRAGMA index_info({index_name});
```

**2-2. PostgreSQL 추출**

`psql -Atc` 로 파이프 구분 출력을 파싱. `PGPASSWORD` 환경변수로 비밀번호 전달.

```sql
-- 테이블 목록
SELECT table_schema, table_name FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_type = 'BASE TABLE';

-- 컬럼 + PK
-- FK
-- 인덱스
```

상세 쿼리는 `resources/queries/postgresql.md` 참조.

---

### Phase 3: 그래프 데이터 구성 (수동 폴백)

**3-1. 테이블 유형 분류**

| 유형 | 판별 기준 | 색상 |
|------|-----------|------|
| junction | FK 컬럼 >= 2 + PK = FK + 컬럼 수 적음 | Purple |
| auth | 이름에 user/role/permission/session/token | Red |
| audit | 이름에 log/audit/history/event | Orange |
| config | 이름에 config/setting/parameter | Brown |
| enum | 컬럼 <= 3, FK out 없음 | Teal |
| dimension | FK in >= 3, FK out <= 1 | Blue |
| fact | 기본값 | Deep Blue |

색상 이론은 `resources/schema-colors.md` 참조.

**3-2. 암묵적 FK 추론**

실제 FK 제약 없이 네이밍 컨벤션으로 관계 추론:
- `{table}_id` 또는 `{table_singular}_id` 패턴 매칭
- 기존 explicit FK와 중복 시 스킵
- 에지에 `implicit: true` 플래그 → HTML에서 점선 표시

**3-3. GRAPH_DATA 구조**

```javascript
{
  nodes: [{ id, label, group, type, title, size, columns }],
  edges: [{ from, to, label, title, arrows: "to", implicit }],
  groups: { "public": { color: "#..." } },
  types: { "fact": { color: "#..." }, ... },
  stats: { totalTables, totalFKs, implicitFKs, orphanTables, avgColumns, totalIndexes, maxReferenced, schemas },
  groupBy: "schema" | "type"
}
```

---

### Phase 4: HTML 리포트 생성

**4-1. 템플릿 로딩**

`templates/schema.html` 파일을 Read로 읽는다.

**4-2. 데이터 주입**

템플릿 내 `{{GRAPH_DATA}}` 플레이스홀더를 Phase 3에서 구성한 JSON으로 교체.

```python
json_str = json.dumps(graph_data).replace('<', '\\u003c').replace('>', '\\u003e')
template.replace('{{GRAPH_DATA}}', json_str)
```

**4-3. 파일 출력**

```
schema-graph.html    # 현재 디렉토리에 생성
```

**4-4. 결과 보고**

```
## Schema Graph Report

- 파일: `schema-graph.html`
- 테이블: {totalTables}개
- FK 관계: {totalFKs}개 (명시적) + {implicitFKs}개 (암묵적)
- 고아 테이블: {orphanTables}개
- 평균 컬럼 수: {avgColumns}
- 인덱스: {totalIndexes}개
- 최다 참조: {maxReferenced.table} ({maxReferenced.count}회)
- 스키마: {schemas}

브라우저에서 `schema-graph.html`을 열어 확인하세요.
```

## Schema Output Format

단일 HTML 파일 (`schema-graph.html`). 브라우저에서 열면:

- **사이드바**: 검색, 스키마 필터, 테이블 유형 필터, 통계, 노드 상세 (컬럼 테이블)
- **툴바**: Reset / Physics 토글 / Color 토글 / Orphans 하이라이트 / Implicit FK 토글
- **에지**: 실선 = explicit FK, 점선 = implicit FK, 라벨 = FK 컬럼명
- **인터랙션**: 클릭→연결 하이라이트, 더블클릭→포커스, 드래그 이동
- **테마**: `prefers-color-scheme` 자동 (dark/light)

## Schema Technical Details

**스크립트**: `scripts/extract-schema.py`
- Python 3.10+ 필요 (표준 라이브러리만 사용)
- PostgreSQL: `psql` CLI 필요 (접속은 `PGPASSWORD` 환경변수)
- SQLite: `sqlite3` 표준 모듈 사용
- 암묵적 FK 추론 (네이밍 컨벤션 기반)
- `--json` 플래그로 stats JSON 출력
