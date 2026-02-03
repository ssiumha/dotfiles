---
name: qmd
description: Searches local markdown notes and documents using qmd CLI. Use when searching notes, querying documents, managing collections, or retrieving document content.
---

# QMD

로컬 마크다운 문서를 인덱싱하고 검색하는 CLI 도구(qmd)의 래퍼입니다.

## Instructions

### 워크플로우 1: 검색

사용자가 노트/문서에서 정보를 찾으려 할 때:

1. **검색 모드 선택**

   | 상황 | 명령어 | 특징 |
   |------|--------|------|
   | 키워드 정확 매칭 | `qmd search` | BM25, 빠름 |
   | 의미 유사성 | `qmd vsearch` | 벡터 검색 |
   | 최고 품질 | `qmd query` | 하이브리드 + LLM 재순위 |

2. **검색 실행**
   ```bash
   # 기본 검색
   qmd search "검색어"

   # 의미 기반 검색
   qmd vsearch "검색어"

   # 최고 품질 (쿼리 확장 + 재순위)
   qmd query "검색어"
   ```

3. **유용한 옵션**
   - `-n <수>`: 결과 개수 (기본 5)
   - `-c <컬렉션>`: 특정 컬렉션만
   - `--full`: 전체 문서 내용 표시
   - `--json`: JSON 출력 (파이프라인용)
   - `--md`: Markdown 출력
   - `--files`: 파일 경로 + 점수 출력
   - `--min-score <값>`: 점수 임계값 필터링

### 워크플로우 2: 문서 조회

검색 결과에서 특정 문서를 가져올 때:

1. **단일 문서 조회**
   ```bash
   # 파일 경로로
   qmd get notes/meeting.md

   # docid로
   qmd get "#abc123"

   # 특정 라인부터
   qmd get notes/meeting.md:50 -l 100
   ```

2. **다중 문서 조회**
   ```bash
   qmd multi-get "journals/2025-05*.md"
   qmd multi-get --json "docs/*.md"
   ```

### 워크플로우 3: 컬렉션 관리

새 문서 디렉토리를 추가하거나 인덱스를 관리할 때:

1. **컬렉션 추가**
   ```bash
   qmd collection add ~/notes --name notes
   qmd context add qmd://notes "개인 노트"
   ```

2. **인덱싱**
   ```bash
   qmd embed         # 벡터 임베딩 생성
   qmd update        # 재인덱싱
   qmd update --pull # git pull 후 재인덱싱
   ```

3. **상태 확인**
   ```bash
   qmd status
   qmd cleanup       # 캐시 정리
   ```

## 중요 원칙

1. **검색 모드 선택**: 빠른 키워드 → `search`, 의미 검색 → `vsearch`, 최고 품질 → `query`
2. **점수 해석**: 0.8+ 매우 관련, 0.5-0.8 적당, 0.2-0.5 약간, 0.2 미만 낮음
3. **컬렉션 스코핑**: `-c` 옵션으로 검색 범위를 좁히면 노이즈 감소
4. **JSON 출력**: 파이프라인이나 후처리 시 `--json` 활용

## Examples

### 노트에서 정보 검색
```
User: "배포 관련 노트 찾아줘"
→ qmd query "배포 방법" -n 10
→ 결과 요약 제공
→ 필요 시 qmd get으로 상세 조회
```

### 특정 컬렉션에서 검색
```
User: "회의록에서 프로젝트 타임라인 찾아줘"
→ qmd search "프로젝트 타임라인" -c meetings --full
→ 결과 제공
```

### 새 컬렉션 추가
```
User: "~/Documents/research를 qmd에 추가해줘"
→ qmd collection add ~/Documents/research --name research
→ qmd context add qmd://research "연구 자료"
→ qmd embed
→ qmd status로 확인
```

## Technical Details

상세 아키텍처와 고급 사용법은 `REFERENCE.md`를 참조하세요.
