---
name: qmd
description: Searches local markdown notes and documents using qmd CLI. Use when searching notes, querying documents, managing collections, or retrieving document content.
allowed-tools: Bash(qmd:*)
---

# QMD - Quick Markdown Search

로컬 마크다운 문서를 인덱싱하고 검색하는 CLI 도구.

## Status

!`qmd status 2>/dev/null || echo "qmd not available"`

## CLI

```bash
qmd query "question"              # Auto-expand + rerank (최고 품질)
qmd query $'lex: X\nvec: Y'       # Structured query
qmd query $'expand: question'     # Explicit expand
qmd search "keywords"             # BM25 only (빠름, no LLM)
qmd get "#abc123"                 # By docid
qmd get notes/meeting.md:50 -l 100  # 특정 라인부터
qmd multi-get "journals/2026-*.md" -l 40  # Glob으로 배치 조회
qmd multi-get notes/foo.md,notes/bar.md   # 콤마 구분, 순서 보존
```

## Query Types (Structured)

`qmd query`에 structured query를 넘길 때 사용하는 타입:

| Type | Method | Input |
|------|--------|-------|
| `lex` | BM25 | Keywords — exact terms, names, code |
| `vec` | Vector | Question — natural language |
| `hyde` | Vector | Answer — hypothetical result (50-100 words) |

### Writing Good Queries

**lex (keyword)**: 2-5 terms, no filler. Exact phrase: `"connection pool"`. Exclude: `performance -sports`. Code identifiers OK.

**vec (semantic)**: Full natural language question. Be specific, include context.

**hyde (hypothetical document)**: Write 50-100 words of what the *answer* looks like. Use expected vocabulary.

**expand (auto-expand)**: Single-line query or `expand: question`. Local LLM이 lex/vec/hyde 변형 자동 생성. 다른 타입과 혼용 불가.

### Combining Types

| Goal | Approach |
|------|----------|
| 정확한 키워드 아는 경우 | `lex` only |
| 어휘를 모르는 경우 | single-line query (implicit `expand`) or `vec` |
| 최대 재현율 | `lex` + `vec` |
| 복잡한 주제 | `lex` + `vec` + `hyde` |

First query gets 2x weight in fusion — best guess를 첫 번째에 배치.

### Lex Query Syntax

| Syntax | Meaning | Example |
|--------|---------|---------|
| `term` | Prefix match | `perf` → "performance" |
| `"phrase"` | Exact phrase | `"rate limiter"` |
| `-term` | Exclude | `performance -sports` |

`-term`은 lex에서만 동작.

## Search Options

```bash
-n <num>          # 결과 개수 (기본 5, --files는 20)
-c <collection>   # 특정 컬렉션만 검색
--min-score <num> # 점수 임계값
--full            # 전체 문서 내용
--line-numbers    # 라인 번호 포함
--files           # docid,score,filepath,context 출력
--json            # JSON 출력
--md              # Markdown 출력
```

## Collection Management

```bash
qmd collection list                          # 목록
qmd collection add ~/notes --name notes      # 추가
qmd collection remove <name>                 # 삭제
qmd context add qmd://notes "개인 노트"      # 컨텍스트 추가
qmd ls [collection[/path]]                   # 파일 탐색
qmd update --pull                            # git pull 후 재인덱싱
qmd embed                                    # 벡터 임베딩 생성
```

## Examples

### 노트에서 정보 검색
```
User: "배포 관련 노트 찾아줘"
→ qmd query "배포 방법 deploy" -n 10
→ 결과 요약 제공
→ 필요 시 qmd get "#docid"로 상세 조회
```

### 특정 컬렉션에서 구조화 검색
```
User: "회의록에서 프로젝트 타임라인 찾아줘"
→ qmd query $'lex: 프로젝트 타임라인\nvec: 프로젝트 일정과 마일스톤' -c meetings
→ 결과 제공
```

### 여러 문서 일괄 조회
```
User: "이번 달 저널 모아줘"
→ qmd multi-get "journals/2026-03-*.md" -l 40
→ 내용 종합 정리
```

## 중요 원칙

1. **검색 모드**: 빠른 키워드 → `search`, 최고 품질 → `query`
2. **점수 해석**: 0.8+ 매우 관련, 0.5-0.8 적당, 0.5 미만 약함
3. **컬렉션 스코핑**: `-c` 옵션으로 범위를 좁히면 노이즈 감소
4. **파이프라인**: `--json`/`--files` 출력으로 후처리 연결
