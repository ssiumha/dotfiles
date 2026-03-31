# GRAPH_DATA JSON Schema

vis-graph의 모든 모드는 이 JSON 포맷을 공유한다.
**추출(extract) → GRAPH_DATA JSON → 렌더링(render)** 파이프라인의 인터페이스.

## 공통 구조

```jsonc
{
  "nodes": [Node],        // 필수
  "edges": [Edge],        // 필수
  "groups": Groups,       // 필수 — 노드 그룹별 색상
  "stats": Stats,         // 필수 — 요약 통계
  "groupBy": string       // 선택 — 색상 모드 힌트
}
```

### Node (공통 필드)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `id` | string | Y | 고유 식별자 |
| `label` | string | Y | 표시 이름 |
| `group` | string | Y | 그룹 키 (groups에 대응) |
| `title` | string | N | 툴팁 텍스트 (줄바꿈 허용) |
| `size` | number | N | 노드 크기 (fan-in 기반) |

### Edge (공통 필드)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `from` | string | Y | 소스 노드 id |
| `to` | string | Y | 타겟 노드 id |
| `label` | string | N | 에지 라벨 |
| `title` | string | N | 에지 툴팁 |
| `arrows` | string | N | 화살표 방향 (기본: `"to"`) |

### Groups

```jsonc
{
  "<group-key>": { "color": "<hex>" }
}
```

### Stats

모드별로 다름. 최소 필드 없음 — 렌더러는 stats를 그대로 사이드바에 표시.

---

## 모드별 확장

### dep (파일 의존성)

**추가 Node 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | string | 파일 역할 (controller, service, repository, ...) |

**추가 최상위 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `roles` | object | 역할별 색상 `{ "controller": { "color": "#..." } }` |

**Stats 필드:**
`totalFiles`, `totalEdges`, `avgDeps`, `maxFanOut`, `maxFanIn`, `circular` (배열), `externalDeps` (배열)

---

### schema (DB ERD)

**추가 Node 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | string | 테이블 유형 (junction, auth, audit, config, enum, dimension, fact) |
| `columns` | [Column] | 컬럼 목록 |

**Column:**
```jsonc
{ "name": string, "type": string, "pk": bool, "indexed": bool, "nullable": bool }
```

**추가 Edge 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `implicit` | bool | 네이밍 컨벤션 추론 FK (점선 표시) |

**추가 최상위 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `types` | object | 테이블 유형별 색상 `{ "fact": { "color": "#..." } }` |

**Stats 필드:**
`totalTables`, `totalFKs`, `implicitFKs`, `orphanTables`, `avgColumns`, `totalIndexes`, `maxReferenced` (`{ table, count }`), `schemas` (배열)

---

### logseq (지식 그래프)

**추가 Node 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `phantom` | bool | 페이지 파일 없이 참조만 되는 노드 |
| `aliases` | [string] | 페이지 별칭 |

**Groups 키**: `namespaces` (최상위 필드명도 `namespaces`로 대체)

```jsonc
{
  "nodes": [...],
  "edges": [...],
  "namespaces": { "<ns>": { "color": "#..." } },  // groups 대신 사용
  "stats": { ... }
}
```

**Stats 필드:**
`totalPages`, `totalLinks`, `avgLinks`, `orphanPages`, `phantomPages`, `mostLinked` (`{ page, count }`), `mostLinking` (`{ page, count }`)

---

## 파이프라인 사용법

```bash
# 추출만 (JSON stdout)
mise run vis:graph schema --conn postgresql://... --json > schema.json

# 렌더링만 (JSON stdin → HTML)
mise run vis:graph render --type schema < schema.json

# 원스텝 (기존 동작 유지)
mise run vis:graph schema --conn postgresql://... --output schema.html

# 외부 도구 연동
ruby db-irb-schema-export.rb | mise run vis:graph render --type schema --output erd.html
```
