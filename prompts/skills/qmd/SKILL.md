---
name: qmd
description: Searches local markdown notes and documents using ir CLI. Use when searching notes, querying documents, managing collections, or retrieving document content.
allowed-tools: Bash(ir:*)
---

# ir - Local Markdown Search

로컬 마크다운 문서를 인덱싱하고 검색하는 CLI 도구.

## Status

!`ir status 2>/dev/null || echo "ir not available"`

## CLI

```bash
ir search "question"                    # Hybrid (기본, 최고 품질)
ir search --mode bm25 "keywords"        # BM25 only (빠름, no LLM)
ir search --mode vector "question"      # Vector only
ir get "#abc123"                        # By docid
ir get notes/meeting.md:50 -l 100      # 특정 라인부터
```

## Search Options

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

## Collection Management

```bash
ir collection list                          # 목록
ir collection add ~/notes --name notes      # 추가
ir collection remove <name>                 # 삭제
ir update --pull                            # git pull 후 재인덱싱
ir embed                                    # 벡터 임베딩 생성
ir status                                   # 인덱스 상태
```

## Examples

### 노트에서 정보 검색
```
User: "배포 관련 노트 찾아줘"
→ ir search "배포 방법 deploy" -n 10
→ 결과 요약 제공
→ 필요 시 ir get "#docid"로 상세 조회
```

### BM25 키워드 검색
```
User: "vault 설정 찾아줘"
→ ir search --mode bm25 "vault config" -n 5
```

### 특정 컬렉션에서 검색
```
User: "회의록에서 프로젝트 타임라인 찾아줘"
→ ir search "프로젝트 일정과 마일스톤" -c meetings -n 10
```

## 중요 원칙

1. **검색 모드**: 빠른 키워드 → `--mode bm25`, 최고 품질 → 기본 hybrid
2. **점수 해석**: 0.8+ 매우 관련, 0.5-0.8 적당, 0.5 미만 약함
3. **컬렉션 스코핑**: `-c` 옵션으로 범위를 좁히면 노이즈 감소
4. **파이프라인**: `--json`/`--files` 출력으로 후처리 연결
