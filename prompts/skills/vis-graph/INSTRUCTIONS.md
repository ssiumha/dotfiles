# vis-graph

파일 의존성 그래프(dep), DB 스키마 ERD(schema), Logseq 지식 그래프(logseq)를 vis-network 기반 인터랙티브 HTML로 시각화합니다.

## Mode Routing

| 인자 패턴 | 모드 | 상세 |
|-----------|------|------|
| `schema <conn-string>` | **Schema** | `modes/schema.md` 참조 |
| `logseq [install <dir>]` | **Logseq** | `modes/logseq.md` 참조 |
| 그 외 (기본) | **Dep** | `modes/dep.md` 참조 |

첫 번째 인자가 `schema`이면 Schema 모드, `logseq`이면 Logseq 모드, 아니면 Dep 모드로 진입한다.
**해당 모드의 `modes/*.md` 파일을 Read하여 지침을 따른다.**

---

## Install Mode (모든 모드 공통)

`/vis-graph <mode> install <target-dir>`

스크립트 + 템플릿을 대상 디렉토리에 복사하여 독립 실행 가능하게 한다.
설치 후에는 대상 디렉토리에서 `python <script>` 만으로 HTML이 갱신된다.

| 모드 | 복사 파일 | 기본 대상 |
|------|-----------|-----------|
| logseq | `vis_graph_common.py` + `logseq-graph.py` + `logseq.html` | `~/Documents/logseq/` |
| dep | `vis_graph_common.py` + `build-graph.py` + `dep.html` | 프로젝트 루트 |
| schema | `vis_graph_common.py` + `extract-schema.py` + `schema.html` | 프로젝트 루트 |

**설치 절차**:
1. `{SKILL_DIR}/scripts/<script>`를 `<target-dir>/`에 복사
2. `{SKILL_DIR}/templates/<template>`를 `<target-dir>/`에 복사
3. 사용자에게 실행 방법 안내

---

## 공통 패턴

### Phase 0: 스크립트 실행 우선

모든 모드는 Python 3.10+ 스크립트를 우선 실행한다.
스크립트 성공 시 결과 보고로 이동, 실패 시 수동 폴백 (Phase 1~).

### 데이터 주입

모든 템플릿은 `{{GRAPH_DATA}}` 플레이스홀더를 사용한다.
JSON 치환 시 반드시 `<`/`>` 이스케이프:

```python
js = json.dumps(graph_data, ensure_ascii=False)
js = js.replace("<", "\\u003c").replace(">", "\\u003e")
html = template.replace("{{GRAPH_DATA}}", js)
```

### 출력

단일 HTML 파일. vis-network CDN 사용, 외부 의존성 없음.
`prefers-color-scheme` 반응형 dark/light 테마.
