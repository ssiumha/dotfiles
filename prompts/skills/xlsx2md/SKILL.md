---
name: xlsx2md
description: >-
  Converts Excel (.xlsx) files to Markdown tables with merged cell handling.
  Use when reading xlsx files, converting spreadsheets to markdown, or analyzing Excel data.
  Do NOT use for CSV files (read them directly) or creating Excel files.
argument-hint: "<file.xlsx> [--sheet <name>] [--max-rows <N>] [--header-rows <N>]"
user-invocable: true
allowed-tools: Bash(python3:*)
---

# xlsx2md

Excel (.xlsx) 파일을 병합 셀 해제 + 다단계 헤더 평탄화하여 Markdown 테이블로 변환합니다.

## Quick Reference

```bash
# 기본 변환 (전체 시트)
/xlsx2md report.xlsx

# 특정 시트만
/xlsx2md report.xlsx --sheet "Sheet1" --sheet "요약"

# 다단계 헤더 (2행 헤더 → "대분류 > 소분류" 형태)
/xlsx2md checklist.xlsx --header-rows 2

# 행 제한 해제
/xlsx2md large-data.xlsx --no-limit

# 파일로 출력
/xlsx2md report.xlsx -o report.md
```

## Phase 0: 스크립트 실행

```bash
python3 {SKILL_DIR}/scripts/xlsx2md.py <file.xlsx> [options]
```

### 옵션

| 인자 | 설명 | 기본값 |
|------|------|--------|
| `<file.xlsx>` | 파일 경로 (필수) | - |
| `--sheet <name>` | 특정 시트만 (반복 가능) | 전체 |
| `--max-rows <N>` | 시트당 최대 데이터 행 | 500 |
| `--no-limit` | 행 제한 해제 | - |
| `--output <file>` | 파일로 출력 | stdout |
| `--no-header` | 첫 행을 데이터로 취급 | - |
| `--header-rows <N>` | 헤더 행 수 (다단계) | 1 |
| `--header-sep <str>` | 다단계 헤더 구분자 | " > " |

## 다단계 헤더 가이드

ISMS 체크리스트 등 병합 헤더가 있는 경우 `--header-rows N` 사용:

```
원본 Excel:
Row 1: | 인증(병합) |          | 접근통제(병합) |            |
Row 2: | 항목       | 점검결과 | 항목           | 점검결과   |
Row 3: | 비밀번호   | 적합     | IP 제한        | 부적합     |
```

```bash
python3 {SKILL_DIR}/scripts/xlsx2md.py file.xlsx --header-rows 2
```

출력:
```markdown
| 인증 > 항목 | 인증 > 점검결과 | 접근통제 > 항목 | 접근통제 > 점검결과 |
| --- | --- | --- | --- |
| 비밀번호 | 적합 | IP 제한 | 부적합 |
```

연속 동일값은 자동 생략: `"인증 > 인증"` → `"인증"`

## 출력 포맷

- 단일 시트: 테이블만 출력
- 복수 시트: `## Sheet: {name}` 헤더로 구분
- 500행 초과 시: `(... N more rows truncated)` 표시
- 병합 셀: 자동 해제, 좌상단 값을 전체 영역에 복제
- 날짜: ISO 포맷 (`YYYY-MM-DD`)
- 파이프 문자: `\|`로 이스케이프

## Fallback

스크립트 실패 시:

1. `python3 -m pip install --user openpyxl` 수동 실행
2. Python 3.8+ 확인
3. 파일이 암호화된 경우 → 사용자에게 암호 해제 요청
4. `.xls` (구형 포맷) → LibreOffice로 `.xlsx` 변환 필요
