---
name: codemap
description: Generates project codemap for context efficiency. Use when starting sessions, after major refactoring, or when project structure is unclear.
---

# Codemap

프로젝트 코드맵을 생성/갱신하여 컨텍스트 비용을 절감합니다.

## Instructions

### 워크플로우 1: 코드맵 생성

$ARGUMENTS: `quick` | `full` | (없음 = 기본)

1. **모드 결정**

   | 인자 | 모드 | 포함 내용 |
   |------|------|----------|
   | (없음) | 기본 | 구조 + 핵심 파일 목록 + 의존성 |
   | `quick` | 빠름 | 디렉토리 구조만 |
   | `full` | 상세 | 구조 + 파일 요약 + 주요 함수/클래스 |

2. **프로젝트 분석**

   ```bash
   # 디렉토리 구조 파악
   Glob **/*

   # 의존성 파일 확인
   Read package.json  # 또는 pyproject.toml, go.mod, Cargo.toml

   # 주요 진입점 파악
   # src/index.ts, src/main.ts, app.py, main.go 등
   ```

3. **코드맵 작성**

   `.codemap.md` 파일 생성:

   ```markdown
   # Project Codemap

   > Generated: {날짜}
   > Mode: {모드}

   ## 디렉토리 구조
   {tree 형태}

   ## 핵심 파일
   {파일 목록 + 역할}

   ## 의존성 요약
   {주요 의존성}

   ## 진입점
   {실행 명령어 → 진입 파일}
   ```

4. **완료 안내**

   ```
   ✅ 코드맵 생성: .codemap.md

   CLAUDE.md에 추가하면 자동 로드:
     프로젝트 코드맵: @.codemap.md
   ```

### 워크플로우 2: 코드맵 갱신

기존 `.codemap.md` 파일이 있을 때:

1. **기존 파일 확인**
   ```bash
   Read .codemap.md
   ```

2. **변경 사항 파악**
   - 새 디렉토리/파일 추가 여부
   - 삭제된 파일 여부
   - 구조 변경 여부

3. **갱신 또는 재생성**
   - 소규모 변경: Edit으로 부분 수정
   - 대규모 변경: 워크플로우 1로 재생성

## 중요 원칙

1. **간결함 유지**: 핵심 구조만, 모든 파일 나열 금지
2. **역할 명시**: 디렉토리/파일마다 한 줄 설명
3. **갱신 시점**: 새 모듈 추가, 리팩토링 후, 세션 시작 시

## Examples

### 기본 모드
User: `/codemap` → 워크플로우 1 → `.codemap.md` 생성 (구조 + 핵심 파일 + 의존성)

### Quick 모드
User: `/codemap quick` → 워크플로우 1 → `.codemap.md` 생성 (디렉토리 구조만)

### 갱신
User: "새 모듈 추가했어, 코드맵 갱신해줘" → 워크플로우 2 → 기존 파일 Edit

## Technical Details

### 출력 파일 위치
- 프로젝트 루트: `.codemap.md`

### CLAUDE.md 연동
```markdown
프로젝트 코드맵: @.codemap.md
```

### .gitignore 권장
```
.codemap.md
```
자동 생성 파일이므로 커밋 제외 권장. 팀 공유 시에는 커밋 가능.

### 갱신 시점 권장
- 새 모듈/디렉토리 추가 후
- 주요 리팩토링 후
- 세션 시작 시 (오래된 경우)
