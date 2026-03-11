
# Claude Guide

Claude Code 설정 구조를 안내하고, 프로젝트별 CLAUDE.md를 리뷰합니다.

## 설정 유형 선택 가이드

Claude Code는 다양한 설정 방식을 제공합니다. **컨텍스트 소비 최소화**를 위해 적절한 유형을 선택하세요.

| 유형 | 로드 시점 | 용도 |
|------|----------|------|
| CLAUDE.md | 항상 | 핵심 규칙, 필수 설정 |
| rules/ | 자동 로드 (paths 지정 시 해당 경로만) | 상세 규칙 분리 (20줄+ 시) |
| hooks/ | 이벤트 시 | 도구 호출 전후 자동 실행 |
| commands/ | 호출 시만 | 반복 작업 템플릿 (/docs, /self-review) |
| skills/ | 필요 시만 | 전문 지식 패키지 (plan-review) |
| agents/ | 위임 시만 | 독립 컨텍스트 작업 (code-review) |

### 어디에 넣을까?

**CLAUDE.md**: 커밋 규칙, 테스트 정책, 금지 사항 (항상 적용되어야 할 것)
**rules/**: 상세 규칙 (20줄+), 영역별 분리 (frontend/, backend/)
**hooks/**: 도구 호출 전후 자동화 (pre-Bash, post-Edit 등)
**commands/**: 반복 워크플로우 (/review, /deploy, /docs)
**skills/**: 특정 주제 전문 지식 (항상 필요하지 않은 것)
**agents/**: 독립 컨텍스트 필요한 작업 (코드 리뷰, 탐색)

### Skill Frontmatter 레퍼런스

`skills/{name}/SKILL.md`의 YAML frontmatter 공식 필드 (name, description, argument-hint, disable-model-invocation, user-invocable, allowed-tools, model, context/agent, hooks, 동적 컨텍스트).

상세 필드 설명 및 조합 효과: `resources/05-skill-frontmatter.md` 참조.

---

## Memory 계층 구조

Claude Code는 여러 위치에서 메모리를 로드합니다. **위에서 아래로 우선순위**가 높습니다.

| 우선순위 | 유형 | 위치 | 공유 범위 |
|:---:|------|------|----------|
| 1 | Enterprise policy | OS별 시스템 경로 | 조직 전체 |
| 2 | User memory | `~/.claude/CLAUDE.md` | 개인 (모든 프로젝트) |
| 3 | Project memory | `./CLAUDE.md` 또는 `./.claude/CLAUDE.md` | 팀 (소스 컨트롤) |
| 4 | Project rules | `./.claude/rules/*.md` | 팀 (소스 컨트롤) |
| 5 | Project local | `./CLAUDE.local.md` | 개인 (현재 프로젝트만) |

**동작 방식**: cwd에서 루트까지 재귀적으로 탐색하며 모든 `CLAUDE.md`, `CLAUDE.local.md` 로드

> `CLAUDE.local.md`는 자동으로 `.gitignore`에 추가됨

### @ Import 문법

다른 파일을 import할 수 있습니다:

```markdown
See @README for project overview and @package.json for available npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
- 개인 설정 @~/.claude/my-project-instructions.md
```

- 상대/절대 경로 모두 지원
- 최대 5단계 재귀 import
- 코드 블록 내에서는 평가되지 않음

### Path-Specific Rules

`.claude/rules/` 내 파일에 YAML frontmatter로 특정 경로에만 적용:

```markdown
---
paths: src/api/**/*.ts
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
```

**Glob 패턴 예시**:
- `**/*.ts`: 모든 TypeScript 파일
- `src/**/*`: src/ 하위 모든 파일
- `src/components/*.tsx`: 특정 디렉토리만
- `{src,lib}/**/*.ts`: 여러 디렉토리

### Memory 명령어

```bash
/init    # CLAUDE.md 생성
/memory  # 로드된 memory 파일 확인
```

> 공식 문서: https://code.claude.com/docs/en/memory

---

## CLAUDE.md 리뷰

프로젝트별 CLAUDE.md를 리뷰하고 정리합니다.

**핵심 목표**:
- 프로젝트 고유 정보만 간결하게 유지 (토큰 효율성 우선)
- 범용 패턴은 Skills로 분리
- 필수 항목 누락 방지
- 정해진 형식 없음, 간결하고 읽기 쉽게
- 실제 문제 해결 중심

## Instructions

### 워크플로우: 기존 claude.md 리뷰

#### 1. 파일 확인

```bash
# 현재 디렉토리 확인
pwd

# claude.md 찾기
ls claude.md 2>/dev/null || ls CLAUDE.md 2>/dev/null
```

**있으면**: 리뷰 시작
**없으면**: 생성 제안 (templates/ 참조)

#### 2. Read 및 분석

```
Read claude.md (또는 CLAUDE.md)
```

**분석 항목**:

1. **컨텍스트 효율성 체크**
   - 간결하고 핵심만: ✅ 적절
   - 다소 장황함: ⚠️ 약간 김
   - 범용 내용 많음: ❌ Skills 분리 필요

2. **Skills로 분리할 내용 감지**

   키워드 패턴으로 감지:
   - "TypeScript", "타입", "컨벤션", "린팅" → patterns-typescript
   - "React", "컴포넌트", "hooks", "상태 관리" → patterns-react
   - "API 설계", "엔드포인트", "RESTful" → patterns-api
   - "테스트", "유닛", "E2E", "mocking" → code-review (Test Review)
   - "에러 핸들링", "try-catch", "로깅" → patterns-error-handling

   **판단 기준**:
   - 해당 섹션이 20줄 이상
   - 프로젝트 독립적인 범용 내용
   - 다른 프로젝트에도 적용 가능

3. **필수 항목 체크**

   - [ ] 프로젝트 개요 (1-2줄 설명)
   - [ ] 퀵 커맨드 (build, test, dev, deploy 등)
   - [ ] 서비스 엔드포인트/포트
   - [ ] 환경변수 필수 항목
   - [ ] 프로젝트 특이사항/주의사항

#### 3. 리포트 생성

사용자에게 분석 결과 요약 (전체 현황, 줄 수, Skills 분리 권장 목록, 필수 항목 누락, 적절한 내용 체크).

#### 4. 사용자 확인

개선 방향 선택지 제시:

**[1] Skills 분리 + 정리**
- 범용 내용을 skills로 분리
- 프로젝트 고유 정보만 남김
- 누락된 필수 항목 추가

**[2] 정리만 (분리 없이)**
- 현재 구조 유지
- 포맷만 정리

**[3] 새로 작성**
- 프로젝트 유형에 맞는 `templates/` 선택 (minimal, web-app, api-server, monorepo, enterprise)
- 사용자와 대화하며 커스터마이징

#### 5. 개선 실행

**[1] Skills 분리 선택 시**:
- 각 분리 대상마다 사용자 확인 → Yes: 새 skill 생성, No: claude.md에 유지
- claude.md에서 해당 섹션 제거 + skill 참조 추가

**[2] 정리만 선택 시**:
- 포맷 정리, 섹션 재배치, 필수 항목 추가

**[3] 새로 작성 선택 시**:
- 적절한 `templates/` 선택 → 사용자와 대화하며 커스터마이징 → claude.md 생성

#### 6. 검증

정리 후 재확인:

- 간결한가?
- 필수 항목 모두 포함?
- Skills 참조 명확?

## 포함/제외 기준

### ✅ claude.md에 포함할 것

**프로젝트 고유 정보:**
- 프로젝트 개요 및 목적
- 빌드/테스트/배포 명령어
- 서비스 엔드포인트 및 포트
- 환경변수 필수 항목
- 인증/테스팅 워크플로우 (프로젝트 특화)
- 프로젝트별 quirks 및 주의사항
- 특정 서비스 설정 (Redis, DB 등)
- 프로젝트 특화 트러블슈팅

**예시**: `resources/06-enterprise-claudemd.md` 하단 참조.

### ❌ Skills로 분리할 것

**범용 패턴 및 가이드:**
- 언어별 컨벤션 (TypeScript, Python 등)
- 프레임워크 패턴 (React, Vue, Express 등)
- API 설계 원칙 (RESTful, GraphQL)
- 테스트 작성 가이드
- 에러 핸들링 패턴
- 데이터베이스 설계 원칙
- 성능 최적화 기법

**분리 대상 skill 매핑:**
- TypeScript 컨벤션 → `patterns-typescript`
- React 패턴 → `patterns-react`
- Backend 아키텍처 → `patterns-backend`
- API 설계 → `patterns-api`
- 테스트 가이드 → `code-review` (Test Review)
- 에러 핸들링 → `patterns-error-handling`
- 보안 → `security`

---

## 대규모 프로젝트 CLAUDE.md

200줄+ CLAUDE.md가 필요한 경우 (DDD, 규제 준수, 복잡한 체크리스트 등)의 권장 구조, 코드 예시 패턴 (올바름/잘못됨), 체크리스트 패턴.

상세 가이드 및 템플릿: `resources/06-enterprise-claudemd.md` 참조.

## 체크리스트

### 필수 항목
- [ ] 프로젝트 개요 (1-2줄)
- [ ] 퀵 커맨드 (build, test, dev)
- [ ] 서비스 엔드포인트/포트
- [ ] 환경변수 필수 항목

### 품질
- [ ] 간결하게 유지
- [ ] Skills 참조 명확
- [ ] 프로젝트 고유 정보만
- [ ] 섹션 구조 명확

### Skills 분리
- [ ] 코딩 컨벤션 (> 20줄) 분리
- [ ] 프레임워크 패턴 분리
- [ ] 범용 가이드 분리

## 예시

### 예시 1: 리뷰 후 Skills 분리

User: "claude.md 리뷰해줘"
Assistant:
1. Read claude.md (250줄)
2. 분석:
   - TypeScript 컨벤션 (60줄) → patterns-typescript
   - React 패턴 (70줄) → patterns-react
   - 퀵 커맨드 누락
3. 리포트 제시
4. 사용자 승인
5. 실행:
   - skills/patterns-typescript/ 생성
   - skills/patterns-react/ 생성
   - claude.md에서 해당 섹션 제거
   - 퀵 커맨드 추가
6. 결과: 80줄의 깔끔한 claude.md

### 예시 2: 새로 작성

User: "claude.md 만들어줘"
Assistant:
1. 프로젝트 유형 확인
2. templates/web-app.md 선택
3. 커스터마이징
4. claude.md 생성

---

## Workflow: 커맨드 생성

요구사항 파악 → 유형 선택 (batch-processor / pipeline / interactive / simple) → 위치 결정 (프로젝트 `.claude/commands/` vs 전역 `~/.claude/commands/`) → 기존 확인 → 생성.

상세 절차 및 유형별 키워드: `resources/01-commands-reference.md` 참조.

---

## Workflow: Rules 생성

기존 rules 확인 → 스코프 결정 → CLAUDE.md vs rules/ 판단 (항상 적용 → CLAUDE.md, 특정 경로 → rules/) → paths frontmatter 설정 → 생성.

상세 절차 및 판단 기준: `resources/02-rules-reference.md` 참조.

---

## Workflow: Hooks 설정

프로젝트 분석 (언어/프레임워크 감지) → 적합한 레시피 선택 → settings.json 생성 → `/hooks`에서 리뷰 안내.

설정 위치: 글로벌 `~/.claude/settings.json` / 프로젝트 `.claude/settings.json` / 로컬 `.claude/settings.local.json`.

상세 레퍼런스: `resources/03-hooks-reference.md`, 레시피: `resources/04-hooks-recipes.md` 참조.

---

## Technical Details

CLAUDE.md 템플릿은 `templates/` 디렉토리 참조:
- minimal.md: 최소 구성
- web-app.md: 웹앱 프로젝트
- api-server.md: API 서버
- monorepo.md: 모노레포
- enterprise.md: 엔터프라이즈 프로젝트 (DDD, 규제 준수)

Command 템플릿은 `templates/commands/` 디렉토리 참조:
- simple.md, batch-processor.md, interactive.md, pipeline.md

Hook 템플릿은 `templates/hooks/` 디렉토리 참조:
- post-edit.sh, recipe-template.yaml

Hook 레시피는 `recipes/` 디렉토리 참조:
- auto-save-state.yaml, post-edit-lint.yaml, post-edit-test.yaml, pre-bash-guard.yaml, on-complete-log.yaml

---

## Workflow: 운용 최적화

위임 판단, 백그라운드 실행, 컨텍스트 관리, 블로킹 최소화 패턴.

상세 가이드: `resources/07-operations-guide.md` 참조.

---

## Workflow: Skill 설치/관리

외부 skill 탐색, 설치, 업데이트, 제거. `npx add-skill` 기반.

설치 절차: `resources/08-skill-installer.md`, 추천 저장소: `resources/09-registries.md` 참조.
