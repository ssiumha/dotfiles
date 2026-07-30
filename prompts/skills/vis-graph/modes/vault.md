# Vault Mode — Obsidian Knowledge Graph

Obsidian vault의 노트 간 `[[wikilink]]`와 `#tag` 연결을 분석하여 vis-network 기반 인터랙티브 지식 그래프를 생성합니다.

**핵심 원칙**:
- 노드 단위: Obsidian 노트 (파일 basename = 링크 해소 단위)
- 엣지: `[[wikilink]]`(`#heading`·`|alias`·`folder/` 형태 정규화) + `#tag` 참조
- 네임스페이스: 노트가 속한 폴더명 (색상 매핑)
- alias: YAML frontmatter `aliases:` → 동일 개념 노트 병합
- 기본 제외: `.session/`, dot-dir(`.obsidian` 등), `node_modules`, 날짜(저널) 페이지

## Quick Reference

```bash
/vis-graph vault                              # 기본: ~/Documents/obsidian 전체
/vis-graph vault --include-session            # .session 페이지 포함
/vis-graph vault --namespace decision         # 특정 폴더 네임스페이스 포커스
/vis-graph vault --no-orphans --min-links 2   # 고립 제외 + 최소 연결 2 (노이즈 감소)
/vis-graph vault --include-date               # 저널/날짜 페이지 포함
```

## Instructions

### Phase 0: vis-graph 실행 (권장)

```bash
vis-graph vault \
  --vault {VAULT_ROOT} \
  --output knowledge-graph.html \
  [--include-session] [--include-date] [--no-orphans] \
  [--namespace <name>] [--min-links <N>]
```

- `{VAULT_ROOT}`: Obsidian vault 루트 (기본 `~/Documents/obsidian` — 위치는 `documentation` skill이 SoT)
- 사용자 입력 인자가 있으면 전달
- 성공 시 결과 보고로 이동

### 결과 보고

```
## Knowledge Graph Report

- 파일: `knowledge-graph.html`
- 페이지: {totalPages}개 / 링크: {totalLinks}개 / 평균: {avgLinks}
- 고아: {orphanPages}개 / 팬텀: {phantomPages}개
- 최다 참조: {mostLinked.page} ({mostLinked.count}회)
- 네임스페이스: {namespaces}

브라우저에서 `knowledge-graph.html`을 열어 확인하세요.
```

큰 vault는 네임스페이스가 많아질 수 있으니, 노이즈가 심하면 `--namespace` 포커스나 `--min-links`를 안내한다.

## Output Format

단일 HTML 파일. 브라우저에서 열면:
- **사이드바**: 검색, 네임스페이스 필터, 통계, 노트 상세 (aliases, 링크 목록)
- **툴바**: Reset / Physics 토글 / Orphans 토글 / Cluster (네임스페이스별)
- **노드**: dot=노트, diamond=팬텀(파일 없음), opacity 30%=고아
- **인터랙션**: 클릭→연결 하이라이트, 더블클릭→포커스+이름 복사
- **테마**: `prefers-color-scheme` 자동 (dark/light)

## Technical Details

**스크립트**: `bin/vis-graph.d/scripts/vault-graph.py` (Python 3.10+, 표준 라이브러리만)
- 재귀 스캔(`rglob`) + 폴더 기반 네임스페이스
- `[[wikilink]]`/`#tag` 파싱, `#heading`·`|alias`·`folder/` 정규화
- frontmatter `aliases:` (inline `[a,b]` / 블록 `- a` / 스칼라) → alias→canonical 병합
- 기본 제외: `.session/`, dot-dir, `node_modules`, 날짜(저널) 페이지
- `--json` 플래그로 stats JSON 출력. 템플릿: `templates/src/vault.html`
