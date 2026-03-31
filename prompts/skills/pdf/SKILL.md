---
name: pdf
description: >-
  Extracts text, tables, and structure from PDF files using opendataloader-pdf.
  Use when reading PDFs, converting PDF to markdown/JSON/HTML, extracting tables from PDF,
  processing scanned PDFs with OCR, or analyzing PDF content for RAG pipelines.
  Do NOT use for creating/editing PDFs, Word/Excel/PPT files (use xlsx2md for Excel),
  or viewing PDFs (use Read tool for simple PDF viewing).
argument-hint: "<file.pdf> [--format markdown|json|html] [--pages 1,3,5-7]"
user-invocable: true
allowed-tools: Bash(opendataloader-pdf*), Bash(pip*), Bash(python3*), Bash(java*), Read, Grep, Glob
---

# pdf — opendataloader-pdf

PDF를 Markdown, JSON (bounding boxes 포함), HTML로 변환합니다.
벤치마크 #1 (0.90 overall accuracy). Java 11+ 필요.

## Prerequisites

- Java 11+ (`java -version`으로 확인)
- Python 3.10+

```bash
pip install -U opendataloader-pdf
# 복잡한 테이블/OCR/수식이 필요하면:
pip install -U "opendataloader-pdf[hybrid]"
```

## Phase 1: 입력 분석

사용자 요청에서 파악:
1. **PDF 경로** — `$ARGUMENTS`에서 추출 또는 사용자에게 확인
2. **출력 포맷** — markdown (추천), json (좌표 필요 시), html, text (CLI 기본값은 json)
3. **복잡도** — 단순 텍스트 PDF vs 복잡한 테이블/스캔/수식

## Phase 2: 변환 실행

### 기본 변환 (Fast mode)

```bash
opendataloader-pdf <file.pdf> -o <output-dir> -f markdown
```

### Python API

```python
import opendataloader_pdf

opendataloader_pdf.convert(
    input_path=["file.pdf"],
    output_dir="output/",
    format="markdown,json"
)
```

### 주요 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-f, --format` | 출력 포맷 (json, text, html, markdown, markdown-with-html, markdown-with-images) | json |
| `-o, --output-dir` | 출력 디렉토리 | 입력 파일 디렉토리 |
| `--pages` | 추출 페이지 (예: "1,3,5-7") | 전체 |
| `-p, --password` | 암호화된 PDF 비밀번호 | - |
| `--use-struct-tree` | Tagged PDF 구조 트리 사용 | false |
| `--table-method` | 테이블 감지 (default, cluster) | default |
| `--image-output` | 이미지 처리 (off, embedded, external) | external |
| `--image-format` | 이미지 포맷 (png, jpeg) | png |
| `--keep-line-breaks` | 원본 줄바꿈 보존 | false |
| `--sanitize` | 민감 데이터 마스킹 (이메일, 전화번호, IP 등) | false |
| `--include-header-footer` | 머리글/바닥글 포함 | false |
| `--markdown-page-separator` | 페이지 구분자 (%page-number% 사용 가능) | 없음 |

전체 옵션: `resources/options-reference.md`

## Phase 3: Hybrid Mode (복잡한 PDF)

복잡한 테이블, 스캔 PDF, 수식, 차트가 있을 때 사용.
단순 페이지는 로컬(0.05s), 복잡한 페이지만 AI 백엔드로 라우팅.

```bash
# 터미널 1: 백엔드 서버 시작
opendataloader-pdf-hybrid --port 5002

# 터미널 2: 변환
opendataloader-pdf --hybrid docling-fast <file.pdf>
```

| 문서 유형 | 서버 옵션 | 클라이언트 옵션 |
|-----------|-----------|-----------------|
| 복잡한 테이블 | `--port 5002` | `--hybrid docling-fast` |
| 스캔/이미지 PDF | `--port 5002 --force-ocr` | `--hybrid docling-fast` |
| 비영어 스캔 | `--port 5002 --force-ocr --ocr-lang "ko,en"` | `--hybrid docling-fast` |
| 수식 포함 | `--enrich-formula` | `--hybrid docling-fast --hybrid-mode full` |
| 차트 설명 필요 | `--enrich-picture-description` | `--hybrid docling-fast --hybrid-mode full` |

`--enrich-formula`/`--enrich-picture-description` 사용 시 클라이언트에서 반드시 `--hybrid-mode full` 지정.
그렇지 않으면 enrichment가 조용히 무시됨.

## Phase 4: 결과 처리

변환 결과를 사용자 목적에 맞게 가공:

- **RAG 파이프라인** → markdown 포맷, 페이지 구분자 추가 (`--markdown-page-separator "--- page %page-number% ---"`)
- **데이터 추출** → json 포맷 (bounding boxes로 소스 위치 추적)
- **웹 표시** → html 포맷
- **이미지 포함 문서** → markdown-with-images 포맷

## MCP Server

Claude Code에서 MCP 서버로 직접 사용 가능:

```bash
claude mcp add opendataloader-pdf -- uvx opendataloader-pdf-mcp
```

## 중요 원칙

1. **배치 우선**: `convert()` 호출마다 JVM이 생성되므로, 여러 파일은 한 번에 전달
2. **Fast mode 먼저**: 단순 PDF는 hybrid 없이 시도. 테이블이 깨지면 hybrid로 전환
3. **포맷 선택**: 텍스트만 필요 → markdown, 좌표 필요 → json, 웹 표시 → html
4. **Tagged PDF 활용**: 이미 태그된 PDF는 `--use-struct-tree`로 구조 활용
5. **민감 데이터 주의**: 개인정보 포함 PDF는 `--sanitize` 옵션 안내
