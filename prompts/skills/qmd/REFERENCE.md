# QMD Reference

## 설치

```bash
bun install -g https://github.com/tobi/qmd
```

## 하이브리드 검색 파이프라인 (query)

`qmd query`는 다단계 파이프라인으로 동작:

1. **쿼리 확장**: 원본 쿼리 + LLM이 생성한 변형 2개
2. **병렬 검색**: 각 쿼리마다 FTS(BM25) + 벡터 인덱스 검색
3. **RRF 융합**: k=60, 원본 쿼리 가중치 2배
4. **상위순위 보너스**: 1순위 +0.05, 2-3순위 +0.02
5. **LLM 재순위**: 상위 30개 후보를 yes/no 판정
6. **위치 인식 블렌딩**: 순위별로 검색 vs 재순위 비율 조정

## 로컬 모델 (자동 다운로드)

| 용도 | 모델 | 크기 |
|------|------|------|
| 임베딩 | embedding-gemma-300M | ~300MB |
| 재순위 | qwen3-reranker-0.6b | ~640MB |
| 쿼리 확장 | Qwen3-1.7B | ~2.2GB |

## MCP 서버 연동

Claude Code에서 qmd를 MCP 서버로 사용:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

제공 도구: `qmd_search`, `qmd_vsearch`, `qmd_query`, `qmd_get`, `qmd_multi_get`, `qmd_status`

## 데이터 저장소

인덱스: `~/.cache/qmd/index.sqlite`

주요 테이블:
- `collections`, `path_contexts`: 메타데이터
- `documents`, `documents_fts`: 마크다운 콘텐츠
- `content_vectors`, `vectors_vec`: 임베딩 청크
- `llm_cache`: LLM 응답 캐시

## 전체 CLI 옵션

### 검색 공통
- `-n <수>`: 결과 개수 (기본 5)
- `-c, --collection <이름>`: 특정 컬렉션 제한
- `--all`: 모든 매치 반환
- `--min-score <값>`: 점수 임계값

### 출력 형식
- `--json`: JSON
- `--csv`: CSV
- `--md`: Markdown
- `--xml`: XML
- `--files`: 파일 경로 + 점수
- `--full`: 전체 문서 내용
