# Logseq Mode — Knowledge Graph

Logseq 페이지 간 `[[wikilink]]`와 `#tag` 연결을 분석하여 vis-network 기반 인터랙티브 지식 그래프를 생성합니다.

**핵심 원칙**:
- 노드 단위: Logseq 페이지
- 엣지: `[[wikilink]]` 및 `#tag` 참조
- 색상: 네임스페이스 기반 (decision=green, troubleshoot=red 등)
- 기본 필터: session/, 날짜 페이지 제외

## Quick Reference

```bash
/vis-graph logseq                                    # 기본: ~/Documents/logseq/pages
/vis-graph logseq --include-session                  # session 포함
/vis-graph logseq --namespace=decision               # 특정 namespace 포커스
/vis-graph logseq --no-orphans --min-links=2         # 최소 연결 2개
/vis-graph logseq install ~/Documents/logseq/        # 독립 실행 스크립트 설치
```

## Instructions

### Phase 0: 스크립트 실행 (권장)

```bash
python3 {SKILL_DIR}/scripts/logseq-graph.py \
  --pages {PAGES_DIR} \
  --template {SKILL_DIR}/templates/logseq.html \
  --output knowledge-graph.html \
  [--include-session] [--include-date] [--no-orphans] \
  [--namespace <name>] [--min-links <N>]
```

- `{SKILL_DIR}`: 이 스킬의 디렉토리 경로
- `{PAGES_DIR}`: Logseq pages 디렉토리 (기본: `~/Documents/logseq/pages`)
- 인자는 사용자 입력이 있으면 전달

스크립트가 성공하면 **결과 보고**로 바로 이동.

### Install 모드

`/vis-graph logseq install <target-dir>` 실행 시:

1. `{SKILL_DIR}/scripts/logseq-graph.py` → `<target-dir>/logseq-graph.py` 복사
2. `{SKILL_DIR}/templates/logseq.html` → `<target-dir>/logseq.html` 복사
3. 안내: `cd <target-dir> && python3 logseq-graph.py`로 실행

### 결과 보고

```
## Knowledge Graph Report

- 파일: `knowledge-graph.html`
- 페이지: {totalPages}개
- 링크: {totalLinks}개
- 평균 링크: {avgLinks}
- 고아 페이지: {orphanPages}개
- 팬텀 페이지: {phantomPages}개
- 최다 참조: {mostLinked.page} ({mostLinked.count}회)
- 네임스페이스: {namespaces}

브라우저에서 `knowledge-graph.html`을 열어 확인하세요.
```

## Output Format

단일 HTML 파일 (`knowledge-graph.html`). 브라우저에서 열면:

- **사이드바**: 검색, 네임스페이스 필터, 통계, 페이지 상세 (aliases, 링크 목록)
- **툴바**: Reset / Physics 토글 / Orphans 토글 / Cluster (네임스페이스별)
- **노드**: dot=일반 페이지, diamond=팬텀 (파일 없음), opacity 30%=고아
- **인터랙션**: 클릭→연결 하이라이트, 더블클릭→포커스+이름 복사
- **테마**: `prefers-color-scheme` 자동 (dark/light)

## Technical Details

**스크립트**: `scripts/logseq-graph.py`
- Python 3.10+ 필요 (표준 라이브러리만 사용)
- 파일명 `___` → `/` 네임스페이스 변환
- `[[wikilink]]` + `#tag` 파싱 (숫자 시작 태그 제외)
- `alias::` property 지원 (alias → canonical 페이지 해소)
- 네임스페이스별 시맨틱 색상 + pj-* 자동 purple 계열
- 기본 제외: session/ 네임스페이스, 날짜 페이지 (YYYY-MM-DD)
- `--json` 플래그로 stats JSON 출력
- 템플릿 자동 탐색: `--template` > 같은 디렉토리 `logseq.html` > 스킬 `templates/`
