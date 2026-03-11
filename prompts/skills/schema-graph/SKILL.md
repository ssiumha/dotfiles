---
name: schema-graph
description: DB 스키마를 분석하여 vis-network 기반 인터랙티브 ERD HTML 리포트 생성. Use when visualizing database structure, understanding table relationships, or onboarding to a database. Do NOT use for query optimization or data migration.
argument-hint: "<connection-string> [--schema=<name>] [--exclude=<pattern>]"
---

# Schema Graph (ERD)

DB 접속 정보를 받아 스키마를 분석하고, vis-network 기반 인터랙티브 HTML ERD를 생성합니다.

**핵심 원칙**:
- 추출: Python 스크립트 우선, 수동 분석 폴백
- 시각화: vis-network CDN (단일 파일, 물리 내장)
- 색상: 듀얼 모드 — 스키마/네임스페이스 vs 테이블 유형
- DB 지원: PostgreSQL + SQLite

## Quick Reference

```bash
/schema-graph postgresql://user:pass@localhost/mydb
/schema-graph sqlite:///path/to/db.sqlite
/schema-graph postgresql://localhost/mydb --schema=public
/schema-graph sqlite:///app.db --exclude="migration_*"
```

## Instructions

### Phase 0: 스크립트 실행 (권장)

Python3가 설치되어 있으면 스크립트로 전체 파이프라인을 실행한다.

```bash
python3 {SKILL_DIR}/scripts/extract-schema.py \
  --conn "<connection-string>" \
  --template {SKILL_DIR}/templates/report.html \
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

색상 이론은 `resources/color-theory.md` 참조.

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

`templates/report.html` 파일을 Read로 읽는다.

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

## Output Format

단일 HTML 파일 (`schema-graph.html`). 브라우저에서 열면:

- **사이드바**: 검색, 스키마 필터, 테이블 유형 필터, 통계, 노드 상세 (컬럼 테이블)
- **툴바**: Reset / Physics 토글 / Color 토글 / Orphans 하이라이트 / Implicit FK 토글
- **에지**: 실선 = explicit FK, 점선 = implicit FK, 라벨 = FK 컬럼명
- **인터랙션**: 클릭→연결 하이라이트, 더블클릭→포커스, 드래그 이동
- **테마**: `prefers-color-scheme` 자동 (dark/light)

## Technical Details

**스크립트**: `scripts/extract-schema.py`
- Python 3.10+ 필요 (표준 라이브러리만 사용)
- PostgreSQL: `psql` CLI 필요 (접속은 `PGPASSWORD` 환경변수)
- SQLite: `sqlite3` 표준 모듈 사용
- 암묵적 FK 추론 (네이밍 컨벤션 기반)
- `--json` 플래그로 stats JSON 출력
