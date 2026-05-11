# vis-graph

파일 의존성 그래프(dep), DB 스키마 ERD(schema), vault 지식 그래프(logseq)를 vis-network 기반 인터랙티브 HTML로 시각화합니다.

**실행 방식**: mise task (`mise run vis:graph <command>`)로 동작. 이 skill은 래퍼.

## Mode Routing

| 인자 패턴 | 모드 | 상세 |
|-----------|------|------|
| `schema <conn-string>` | **Schema** | `modes/schema.md` 참조 |
| `logseq [install <dir>]` | **Logseq** | `modes/logseq.md` 참조 |
| 그 외 (기본) | **Dep** | `modes/dep.md` 참조 |

첫 번째 인자가 `schema`이면 Schema 모드, `logseq`이면 Logseq 모드, 아니면 Dep 모드로 진입한다.
**해당 모드의 `modes/*.md` 파일을 Read하여 지침을 따른다.**

---

## 공통 패턴

### Phase 0: mise task 실행 우선

모든 모드는 `mise run vis:graph <command>` 를 우선 실행한다.
성공 시 결과 보고로 이동, 실패 시 수동 폴백 (Phase 1~).

스크립트와 템플릿은 `config/mise/tasks/vis-graph/`에 위치:
- `scripts/` — Python 스크립트
- `templates/dist/` — 플래트닝된 단일 HTML 템플릿
- `resources/` — 참조 문서 (SQL 쿼리, 패턴 등)

### 외부 도구 연동 (render 서브커맨드)

GRAPH_DATA JSON을 stdin으로 받아 HTML을 렌더링할 수 있다:

```bash
echo '{"nodes":...}' | mise run vis:graph render --type schema --output out.html
```

### 출력

단일 HTML 파일. vis-network CDN 사용, 외부 의존성 없음.
`prefers-color-scheme` 반응형 dark/light 테마.
