# Commands Reference

Slash command를 생성하고 관리합니다. Command는 반복 작업을 단축키처럼 호출하는 프롬프트 템플릿입니다.

## 파일 위치

| 위치 | 경로 | 용도 |
|------|------|------|
| 프로젝트 | `.claude/commands/{name}.md` | 현재 프로젝트에서만 사용 |
| 전역 | `~/.claude/commands/{name}.md` | 모든 프로젝트에서 사용 |

## Command 유형

| 유형 | 설명 | 템플릿 | 예시 |
|------|------|--------|------|
| simple | 단순 작업 실행 | `templates/commands/simple.md` | `/format`, `/lint` |
| batch-processor | 체크리스트 + 병렬 처리 | `templates/commands/batch-processor.md` | `/img-batch`, `/migrate` |
| interactive | 질문-응답 기반 | `templates/commands/interactive.md` | `/init`, `/setup` |
| pipeline | 순차 단계 처리 | `templates/commands/pipeline.md` | `/deploy`, `/release` |

## Creation Process

### 1. 요구사항 수집

AskUserQuestion으로 확인:

**[필수]**
- **목적**: 이 command가 무엇을 하는가?
- **입력**: `$ARGUMENTS`로 받을 값은?

**[선택]**
- **유형**: 단순 / 배치 / 대화형 / 파이프라인?
- **병렬 처리**: agent 병렬 호출 필요?

### 2. 기존 command 확인

중복 방지를 위해 검색:
```bash
Glob ~/.claude/commands/*.md
Glob .claude/commands/*.md
```

### 3. 유형 선택

| 키워드 | 추천 유형 |
|--------|----------|
| "배치", "병렬", "체크리스트" | batch-processor |
| "단계별", "순차", "파이프라인" | pipeline |
| "질문", "대화", "선택" | interactive |
| 그 외 | simple |

### 4. 위치 선택

- [1] 프로젝트: `.claude/commands/{name}.md`
- [2] 전역: `~/.claude/commands/{name}.md`

### 5. 템플릿 기반 생성

1. `templates/commands/{type}.md` Read
2. 플레이스홀더 치환
3. Write로 파일 생성

## Modification Process

1. **대상 확인**: 기존 command 파일 Read
2. **수정 유형 파악**:
   - 로직 변경 → 본문 수정
   - 인자 추가 → `$ARGUMENTS` 설명 수정
   - 병렬화 추가 → batch-processor 패턴 적용
3. **Edit으로 수정**

## 중요 원칙

1. **$ARGUMENTS 활용**: 사용자 입력은 `$ARGUMENTS`로 받음
2. **명확한 단계**: 번호 매김으로 순서 명시
3. **에러 처리**: 실패 시 동작 정의
4. **상태 관리**: 배치 처리 시 체크리스트 파일 활용

## 유형 상세

### Simple

가장 기본적인 형태. 단일 작업을 수행합니다.

**적합한 경우**: 단일 도구 실행 (lint, format, build), 간단한 조회 (status, info), 파일 생성 (scaffold)

### Batch Processor

체크리스트 기반 병렬 처리. 대량 작업에 적합합니다.

**핵심 요소**: 체크리스트 파일 (YAML/JSON), `done: true/false` 상태 관리, Task tool로 병렬 agent 호출, 배치 크기 제한 (권장: 5-10개)

### Interactive

사용자 입력 기반 동적 실행. 설정/초기화에 적합합니다.

**핵심 요소**: AskUserQuestion 활용, 선택지 제공 ([1], [2], [3]), 조건부 실행

### Pipeline

순차적 단계 실행. 배포/릴리스에 적합합니다.

**핵심 요소**: Stage 1, 2, 3... 순차 진행, 각 Stage 완료 조건 명시, `--stage=N` 재개 옵션

### 유형 선택 가이드

```
작업이 단일인가?
├─ Yes → Simple
└─ No
    ├─ 병렬 처리 가능? → Batch Processor
    ├─ 사용자 입력 필요? → Interactive
    └─ 순서 의존성? → Pipeline
```

### 조합 패턴

유형은 조합 가능:
- **Interactive + Pipeline**: 설정 질문 후 단계별 실행
- **Pipeline + Batch**: 각 Stage에서 배치 처리
- **Interactive + Batch**: 옵션 선택 후 병렬 처리
