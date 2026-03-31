# opendataloader-pdf 전체 옵션 레퍼런스

소스: https://github.com/opendataloader-project/opendataloader-pdf/blob/main/options.json

## 기본 옵션

| 옵션 | 단축 | 타입 | 기본값 | 설명 |
|------|------|------|--------|------|
| `--output-dir` | `-o` | string | 입력 파일 디렉토리 | 출력 디렉토리 |
| `--password` | `-p` | string | - | 암호화된 PDF 비밀번호 |
| `--format` | `-f` | string | json | 출력 포맷 (json, text, html, pdf, markdown, markdown-with-html, markdown-with-images) |
| `--quiet` | `-q` | boolean | false | 콘솔 로그 숨김 |
| `--pages` | - | string | 전체 | 추출 페이지 (예: "1,3,5-7") |

## 텍스트 처리

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `--keep-line-breaks` | boolean | false | 원본 줄바꿈 보존 |
| `--replace-invalid-chars` | string | " " | 비정상 문자 대체 문자 |
| `--detect-strikethrough` | boolean | false | 취소선 감지 → ~~ 마크다운 (실험적) |

## 구조 분석

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `--use-struct-tree` | boolean | false | Tagged PDF 구조 트리 사용 |
| `--table-method` | string | default | 테이블 감지 (default: 경계선 기반, cluster: 경계선+클러스터) |
| `--reading-order` | string | xycut | 읽기 순서 (off, xycut) |

## 페이지 구분자

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `--markdown-page-separator` | string | 없음 | Markdown 페이지 구분자 (%page-number% 치환) |
| `--text-page-separator` | string | 없음 | 텍스트 페이지 구분자 |
| `--html-page-separator` | string | 없음 | HTML 페이지 구분자 |

## 이미지

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `--image-output` | string | external | 이미지 모드 (off, embedded: Base64, external: 파일 참조) |
| `--image-format` | string | png | 이미지 포맷 (png, jpeg) |
| `--image-dir` | string | - | 이미지 출력 디렉토리 |

## 안전 / 필터링

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `--sanitize` | boolean | false | 민감 데이터 마스킹 (이메일, 전화번호, IP, 카드번호, URL) |
| `--content-safety-off` | string | - | 콘텐츠 안전 필터 비활성화 (all, hidden-text, off-page, tiny, hidden-ocg) |
| `--include-header-footer` | boolean | false | 머리글/바닥글 포함 |

## Hybrid Mode

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `--hybrid` | string | off | AI 백엔드 (off, docling-fast) |
| `--hybrid-mode` | string | auto | 트리아지 모드 (auto: 동적, full: 전체 페이지 백엔드) |
| `--hybrid-url` | string | - | 백엔드 서버 URL 오버라이드 |
| `--hybrid-timeout` | string | 0 | 백엔드 타임아웃 (ms, 0=무제한) |
| `--hybrid-fallback` | boolean | false | 백엔드 오류 시 Java 폴백 |
