# code-review-graph

Tree-sitter 기반 지식 그래프로 코드 리뷰 토큰을 대폭 절감하는 스킬.
변경 파일의 blast radius(영향 범위)만 추출하여 최소 컨텍스트로 리뷰한다.

## 사전 조건

- `code-review-graph` CLI 설치 필요 (`mise` 또는 `pip install code-review-graph`)
- Python 3.10+, uv 필요

## Workflow Selection

| 인자 | 워크플로우 |
|------|-----------|
| `setup` 또는 인자 없음 + `.mcp.json` 없음 | Setup |
| `review-delta` 또는 인자 없음 + 그래프 존재 | Review Delta |
| `review-pr [PR번호/브랜치]` | Review PR |

## Workflow 1: Setup

프로젝트에 code-review-graph를 설치하고 초기 빌드한다.

### Steps

1. **MCP 서버 등록**
   ```bash
   code-review-graph install
   ```
   - `.mcp.json` 생성됨. `.gitignore`에 추가 여부 확인

2. **초기 빌드** — `build_or_update_graph_tool(full_rebuild=True)` 또는 CLI:
   ```bash
   code-review-graph build
   ```
   - `.code-review-graph/graph.db` 생성 (SQLite)
   - ~500 파일 기준 약 10초

3. **상태 확인** — `list_graph_stats_tool()` 호출 또는 CLI:
   ```bash
   code-review-graph status
   ```

4. **.gitignore 확인** — `.code-review-graph/` 포함 여부. 없으면 추가 제안

5. **결과 보고** — 파싱된 파일 수, 노드/엣지 수, 감지된 언어

### 자동 갱신 훅 (선택)

사용자에게 훅 설정 여부를 물어본다. Write/Edit/Bash 후 그래프 자동 갱신:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "code-review-graph update 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### 추가 설정 (선택)

- **`.code-review-graphignore`** — 그래프에서 제외할 파일 패턴 (node_modules, .venv 등은 기본 제외)
- **`code-review-graph watch`** — 파일 저장 시 자동 증분 업데이트 (watchdog 기반)
- **`code-review-graph visualize`** — D3.js 인터랙티브 그래프 HTML 생성

## Workflow 2: Review Delta

마지막 커밋 이후 변경된 코드만 blast radius 기반으로 리뷰한다.
목표: 전체 파일 대신 **<800 tokens의 구조적 요약**으로 리뷰.

### Steps

1. **토큰 최적화 가이드 로드** — `get_docs_section_tool(section_name="review-delta")` 호출

2. **그래프 갱신** — `build_or_update_graph_tool()` (증분)

3. **영향 범위 파악** — `get_impact_radius_tool()` 호출
   - 변경 파일 자동 감지 (git diff/status)
   - 양방향 BFS로 2-hop 이내 영향 노드 추출

4. **리뷰 컨텍스트 수집** — `get_review_context_tool()` 호출
   - impacted nodes/files
   - 변경 영역 소스 스니펫 (전체 파일이 아닌 변경 노드의 라인 범위만)
   - 리뷰 가이던스 (테스트 갭, 넓은 영향 경고)

5. **blast radius 분석**
   - 호출자가 변경된 함수 → 시그니처/동작 검증
   - 상속 변경 → LSP 위반 우려
   - 의존자가 많은 파일 → 고위험

6. **심층 리뷰** — 각 변경 파일:
   - 소스 스니펫 기반 정확성, 스타일, 버그 검토 (full file 포함 금지 — 명시적 요청 시에만)
   - `query_graph_tool(pattern="callers_of", target=<func>)` 로 호출자 확인
   - `query_graph_tool(pattern="tests_for", target=<func>)` 로 테스트 커버리지 확인
   - 미테스트 함수 플래그

7. **리포트 출력**

```markdown
## Delta Review

### Summary
변경 내용 1-2줄 요약

### Risk: Low / Medium / High
- Blast radius: X files, Y functions
- Test coverage: N/M functions covered

### Findings
**[Critical]** `파일:라인` - 문제 → 수정 제안
**[High]** `파일:라인` - 문제 → 수정 제안

### Untested Changes
- `function_name` in `file` - 테스트 없음

### Recommendations
1. ...
```

## Workflow 3: Review PR

PR 또는 브랜치 diff 전체를 그래프 기반으로 리뷰한다.
full file은 명시적 요청이 없는 한 포함하지 않는다.

### Steps

1. **토큰 최적화 가이드 로드** — `get_docs_section_tool(section_name="review-pr")` 호출

2. **변경 파악**
   - PR 번호 → `gh pr diff <number>`
   - 브랜치명 → `git diff main...<branch>`
   - 없음 → 현재 브랜치 vs main 자동 감지

3. **그래프 갱신** — `build_or_update_graph_tool(base="main")`
   - `base="main"` 으로 PR 전체 diff 기준 갱신 (기본값 HEAD~1과 다름)

4. **리뷰 컨텍스트** — `get_review_context_tool(base="main")` 호출

5. **영향 분석** — `get_impact_radius_tool(base="main")` 호출
   - 전체 PR의 blast radius 파악
   - 광범위 의존 코드 식별

6. **파일별 심층 리뷰**
   - 고위험 함수는 `query_graph_tool(pattern="callers_of")` 로 호출자 확인
   - `tests_for` 로 테스트 커버리지 확인
   - `semantic_search_nodes_tool` 로 PR이 놓친 관련 코드 탐색
   - 리네임/이동된 함수의 호출자 전부 갱신되었는지 확인
   - 공개 API 변경 시 breaking change 확인

7. **리포트 출력**

```markdown
## PR Review: <title>

### Summary
1-3줄 요약

### Risk Assessment
- Overall: Low / Medium / High
- Blast radius: X files, Y functions
- Test coverage: N/M changed functions covered

### File-by-File
#### <file_path>
- Changes: 설명
- Impact: 의존자 목록
- Issues: 버그, 스타일, 우려

### Missing Tests
- `function_name` in `file`

### Recommendations
1. ...
```

## Examples

### 새 프로젝트에 setup
```
User: "/code-review-graph setup"
→ install → build_or_update_graph_tool(full_rebuild=True) → list_graph_stats_tool()
→ .gitignore 확인 → 훅 설정 제안
→ "324 files, 2,847 nodes, 4,102 edges parsed (Python, TypeScript)"
```

### 커밋 전 delta 리뷰
```
User: "/code-review-graph review-delta"
→ get_docs_section_tool("review-delta") → build_or_update_graph_tool()
→ get_impact_radius_tool() → get_review_context_tool()
→ blast radius: 3 files, 12 functions
→ "auth_handler 변경 → 5개 호출자 영향, login_test 커버리지 확인됨"
```

### PR 리뷰
```
User: "/code-review-graph review-pr 42"
→ get_docs_section_tool("review-pr") → gh pr diff 42
→ build_or_update_graph_tool(base="main") → get_review_context_tool(base="main")
→ "Risk: Medium, 8 files impacted, 2 untested functions"
```

## MCP 도구 참조

그래프가 빌드되면 다음 MCP 도구를 사용할 수 있다:

| 도구 | 용도 |
|------|------|
| `build_or_update_graph_tool` | 빌드/증분 업데이트. `base` 파라미터로 diff 기준 변경 |
| `get_impact_radius_tool` | 변경 파일 blast radius (양방향 BFS, depth=2) |
| `get_review_context_tool` | 토큰 최적화된 리뷰 컨텍스트 + 소스 스니펫 |
| `get_docs_section_tool` | 토큰 효율적 문서 섹션 로드 (review-delta, review-pr) |
| `query_graph_tool` | 그래프 질의. 패턴: callers_of, callees_of, imports_of, importers_of, children_of, tests_for, inheritors_of, file_summary |
| `semantic_search_nodes_tool` | 이름/키워드 검색 (벡터 임베딩 fallback) |
| `find_large_functions_tool` | 과대 함수/클래스 탐지 (분해 대상) |
| `embed_graph_tool` | 시맨틱 검색용 벡터 임베딩 생성 |
| `list_graph_stats_tool` | 그래프 통계 (파일 수, 노드/엣지, 언어) |

## 지원 언어

Python, TypeScript, JavaScript, Vue, Go, Rust, Java, C#, Ruby, Kotlin, Swift, PHP, Solidity, C/C++ (14개)

## Related Skills

| 스킬 | 관계 |
|------|------|
| `/code-review` | 전통적 체크리스트 기반 리뷰. 그래프 없이 동작 |
| `/security` | 보안 취약점 전문 리뷰 |
