---
name: ir
description: Local markdown search engine CLI. Use when searching notes, querying documents, managing collections, indexing, embedding, or retrieving document content. Also use when ir search, ir update, ir embed, ir collection, ir status, ir daemon, ir get.
allowed-tools: Bash(ir:*)
---

# ir - Local Markdown Search Engine

로컬 마크다운 문서를 인덱싱하고 검색하는 CLI 도구. Collection 기반 관리, BM25/Vector/Hybrid 검색 지원.

## Status

!`ir status 2>/dev/null || echo "ir not available"`

## CLI Quick Reference

### Search

```bash
ir search "question"                    # Hybrid (기본, 최고 품질)
ir search --mode bm25 "keywords"        # BM25 only (빠름, no LLM)
ir search --mode vector "question"      # Vector only
```

### Search Options

```bash
--mode <MODE>         # bm25 | vector | hybrid [default: hybrid]
-n <num>              # 결과 개수 (기본 10)
--min-score <num>     # 점수 임계값
-c, --collection <name>  # 특정 컬렉션만 검색
--full                # 전체 문서 내용
--files               # docid,score,filepath,context 출력
--json                # JSON 출력
--md                  # Markdown 출력
--csv                 # CSV 출력
--all                 # 전체 결과 (최대 4096)
-v, --verbose         # 파이프라인 결정 및 타이밍
```

### Document Retrieval

```bash
ir get "#abc123"                        # By docid
ir get notes/meeting.md:50 -l 100      # 특정 라인부터
```

### Collection Management

```bash
ir collection list                          # 목록
ir collection add ~/notes --name notes      # 추가
ir collection remove <name>                 # 삭제
ir collection rename <old> <new>            # 이름 변경
ir collection set-path <name> <path>        # 경로 변경
```

### Indexing & Embedding

```bash
ir update                              # 전체 재인덱싱
ir update <collection>                 # 특정 컬렉션만
ir update --pull                       # git pull 후 재인덱싱
ir embed                               # 벡터 임베딩 생성
ir embed <collection>                  # 특정 컬렉션만
```

### Daemon & MCP

```bash
ir daemon start                        # 검색 데몬 시작 (모델 warm)
ir daemon stop                         # 데몬 중지
ir daemon status                       # 데몬 상태
ir mcp                                 # MCP 서버 시작
ir mcp --http <PORT>                   # HTTP MCP 서버
```

## Examples

### 노트에서 정보 검색
```
User: "배포 관련 노트 찾아줘"
-> ir search "배포 방법 deploy" -n 10
-> 결과 요약 -> 필요 시 ir get "#docid"로 상세 조회
```

### 컬렉션 추가 후 인덱싱
```
User: "이 프로젝트 문서도 검색되게 해줘"
-> ir collection add ~/pj-foo/docs --name pj-foo
-> ir update pj-foo && ir embed pj-foo
-> ir status 로 확인
```

### 특정 컬렉션 스코프 검색
```
User: "회의록에서 프로젝트 타임라인 찾아줘"
-> ir search "프로젝트 일정과 마일스톤" -c meetings -n 10
```

## Principles

1. **검색 모드**: 빠른 키워드 -> `--mode bm25`, 최고 품질 -> 기본 hybrid
2. **점수 해석**: 0.8+ 매우 관련, 0.5-0.8 적당, 0.5 미만 약함
3. **컬렉션 스코핑**: `-c` 옵션으로 범위를 좁히면 노이즈 감소
4. **인덱스 갱신**: 문서 추가/수정 후 `ir update && ir embed` 실행
5. **파이프라인**: `--json`/`--files` 출력으로 후처리 연결
