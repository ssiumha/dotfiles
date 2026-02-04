---
name: project-context
description: Generates project context (code structure + architecture intent). Use when starting sessions, after major refactoring, or when delegating complex work to agents.
---

# Project Context

프로젝트의 코드 구조(사실)와 아키텍처 의도(WHY)를 문서화하여 컨텍스트 효율을 극대화합니다.

## Instructions

### 워크플로우 1: Codemap 생성

**목적**: 코드 구조 사실 기록 → `.codemap.md`

$ARGUMENTS: `quick` | `full` | (없음 = 기본)

| 인자 | 모드 | 포함 내용 |
|------|------|----------|
| (없음) | 기본 | 구조 + 핵심 파일 목록 + 의존성 |
| `quick` | 빠름 | 디렉토리 구조만 |
| `full` | 상세 | 구조 + 파일 요약 + 주요 함수/클래스 |

**프로세스**:
1. 프로젝트 분석 (Glob, 의존성 파일 읽기)
2. `.codemap.md` 생성:
   ```markdown
   # Project Codemap
   > Generated: {날짜} | Mode: {모드}

   ## 디렉토리 구조
   {tree 형태}

   ## 핵심 파일
   {파일 목록 + 역할}

   ## 의존성 요약
   {주요 의존성}

   ## 진입점
   {실행 명령어 → 진입 파일}
   ```

### 워크플로우 2: Architecture 문서화

**목적**: 아키텍처 의도 기록 → `ARCHITECTURE.md`

**생성 (ARCHITECTURE.md가 없을 때)**:
1. 코드베이스 분석 (디렉토리, 설정, 진입점)
2. **사용자에게 의도 질문**:
   - "이 프로젝트에서 가장 중요한 제약은?"
   - "앞으로 확장할 계획이 있는 부분은?"
   - "이 구조를 선택한 이유는?"
3. `ARCHITECTURE.md` 초안 생성 (템플릿: `templates/ARCHITECTURE.md`)
4. 반복 협의 → 사용자 승인 시 완료

**갱신 (ARCHITECTURE.md가 있을 때)**:
1. 현재 문서 읽기
2. 사용자 요청 반영 (섹션 추가/수정/삭제)
3. 변경 사항 요약

**ARCHITECTURE.md 구조**:

| 섹션 | 내용 | 핵심 질문 |
|------|------|----------|
| **Overview** | 한 줄 요약 + 기술 스택 | 이 프로젝트는 무엇인가? |
| **Structure** | 모듈/디렉토리별 책임 | 어디에 무엇이 있는가? |
| **Constraints** | 깨지면 안 되는 규칙 | 무엇을 지켜야 하는가? |
| **Data Flow** | 주요 데이터 흐름 경로 | 데이터가 어떻게 흐르는가? |
| **Extension Points** | 확장 예정/허용 지점 | 앞으로 어떻게 변할 것인가? |
| **Decisions** | 핵심 결정 + WHY | 왜 이렇게 했는가? |

### 워크플로우 3: Full Context

**목적**: 코드 구조 + 아키텍처 의도 모두 생성

$ARGUMENTS: `full-context`

1. 워크플로우 1 실행 → `.codemap.md`
2. 워크플로우 2 실행 → `ARCHITECTURE.md`
3. 완료 안내:
   ```
   ✅ 프로젝트 컨텍스트 생성 완료
   - .codemap.md (코드 구조)
   - ARCHITECTURE.md (아키텍처 의도)

   CLAUDE.md 연동:
     프로젝트 코드맵: @.codemap.md
     프로젝트 아키텍처: @ARCHITECTURE.md
   ```

## 중요 원칙

1. **Codemap = 사실**: 코드에서 읽을 수 있는 구조 (간결하게, 핵심만)
2. **Architecture = 의도**: 코드에 없는 WHY (제약, 결정 이유, 확장 방향)
3. **간결함**: Codemap은 핵심 구조만, Architecture는 각 섹션 10-20줄 이내
4. **살아있는 문서**: 구조/아키텍처 변경 시 반드시 갱신
5. **git 관리**: ARCHITECTURE.md는 커밋 필수, .codemap.md는 선택적

## Examples

**Codemap 빠른 생성**:
```
User: "/project-context quick" → .codemap.md 생성 (구조만)
```

**Architecture 정리**:
```
User: "/project-context" (ARCHITECTURE.md 없음)
→ 코드베이스 분석 → 사용자에게 의도 질문 → ARCHITECTURE.md 생성
```

**Full context**:
```
User: "/project-context full-context"
→ .codemap.md + ARCHITECTURE.md 모두 생성
```

**위임 시 활용**:
```
User: "인증 모듈 리팩토링해줘"
→ orchestrator가 ARCHITECTURE.md 확인
→ Constraints 섹션에서 "auth → 외부 의존 허용, 외부 → auth 금지"
→ 위임 프롬프트에 제약 첨부
```

## 연동

| 도구 | 대상 | project-context와의 차이 |
|------|------|------------------------|
| `project-context` codemap | 코드 구조 (.codemap.md) | 파일/함수/클래스 사실 |
| `project-context` arch | 아키텍처 (ARCHITECTURE.md) | 의도/제약/WHY |
| `ldoc` ADR | 개별 결정 기록 | arch는 전체 그림, ADR은 상세 |
| `orchestrator` | 위임 시 참조 | Constraints/Structure를 프롬프트에 첨부 |

**언제 뭘 쓰는가**:

| 요청 | 사용 | 이유 |
|------|------|------|
| "AuthService는 어디 있어?" | codemap | 파일 위치 탐색 |
| "왜 Redis를 선택했어?" | ldoc ADR | 개별 결정 상세 |
| "이 프로젝트 전체 구조는?" | arch | 전체 아키텍처 맥락 |
| "인증 모듈 리팩토링 제약은?" | arch Constraints | 위임 시 제약 확인 |
| "세션 시작, 컨텍스트 필요" | full-context | 코드맵 + 아키텍처 |
