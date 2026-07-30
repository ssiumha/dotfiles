# vis-graph

파일 의존성 그래프(dep), DB 스키마 ERD(schema), Obsidian vault 지식 그래프(vault)를 vis-network 기반 인터랙티브 HTML로 시각화합니다.

**실행 방식**: `bin/vis-graph` CLI 로 동작. 이 skill은 래퍼.

## Mode Routing

| 인자 패턴 | 모드 | 상세 |
|-----------|------|------|
| `schema <conn-string>` | **Schema** | `modes/schema.md` 참조 |
| `vault` | **Vault** | `modes/vault.md` 참조 |
| 그 외 (기본) | **Dep** | `modes/dep.md` 참조 |

첫 번째 인자가 `schema`이면 Schema 모드, `vault`이면 Vault 모드, 아니면 Dep 모드로 진입한다.
**해당 모드의 `modes/*.md` 파일을 Read하여 지침을 따른다.**

---

## 공통 패턴

### Phase 0: vis-graph 실행 우선

모든 모드는 `vis-graph <command>` 를 우선 실행한다.
성공 시 결과 보고로 이동, 실패 시 수동 폴백 (Phase 1~).

스크립트와 템플릿은 `bin/vis-graph.d/`에 위치:
- `scripts/` — Python 스크립트
- `templates/dist/` — 플래트닝된 단일 HTML 템플릿
- `resources/` — 참조 문서 (SQL 쿼리, 패턴 등)

### 외부 도구 연동 (render 서브커맨드)

GRAPH_DATA JSON을 stdin으로 받아 HTML을 렌더링할 수 있다:

```bash
echo '{"nodes":...}' | vis-graph render --type schema --output out.html
```

### 출력

단일 HTML 파일. vis-network CDN 사용, 외부 의존성 없음.
`prefers-color-scheme` 반응형 dark/light 테마.
