---
name: skill-creator
description: Creates and manages Claude Code skills. Use when creating new skills, updating existing skills, or converting repeated prompts into reusable skill packages.
---

# Skill Creator

Skill을 생성, 수정, 갱신하고 best practices를 검증합니다.

## Description 작성법 (핵심)

Description은 Claude가 skill 활성화를 결정하는 **유일한 기준**입니다.

**필수 포함 요소**:
1. **무엇을 하는지** (What): 구체적 기능
2. **언제 사용하는지** (When): 트리거 조건

**좋은 예시**:
```yaml
# 명확한 기능 + 트리거 조건
description: Generates commit messages from git diffs. Use when writing commits or reviewing staged changes.

# 구체적 키워드 + 네거티브 트리거
description: Creates Docker configurations. Use when containerizing apps, writing compose.yaml, or building multi-stage images. Do NOT use for Kubernetes manifests or Helm charts (use deployment instead).

# 범용 skill에 오버트리거 방지
description: Manages project knowledge base. Use when recording decisions, creating TODOs, or updating knowledge docs. Do NOT use for one-off documentation or simple README edits.
```

**나쁜 예시**:
```yaml
# 너무 모호함
description: Helps with documents.

# 트리거 조건 없음
description: Code review tool.

# 네거티브 트리거 없이 너무 넓은 범위
description: Manages all project documentation and notes.
```

**네거티브 트리거 (Do NOT use when)**:
- 범용성이 높은 skill에 필수 — 오버트리거 방지
- 유사 skill이 있을 때 경계 명확화
- 형식: `Do NOT use for {제외 케이스} (use {대안 skill} instead).`

## Progressive Disclosure (토큰 효율)

Skill은 **3단계로 점진적 로딩**됩니다. 이 원칙을 이해하고 설계하십시오:

| 단계 | 로딩 시점 | 내용 | 토큰 |
|------|----------|------|------|
| 1. 메타데이터 | 항상 | frontmatter (name, description) | ~100 |
| 2. SKILL.md | 트리거 시 | 핵심 워크플로우 | <5K |
| 3. 리소스 | 필요 시 | resources/, templates/ | 필요량 |

**설계 원칙**:
- SKILL.md는 **절차적 지식만** (무엇을, 언제, 어떻게)
- 상세 정보는 리소스로 분리 → 필요 시 Read
- 10K+ 워드 리소스는 grep 패턴 포함

## 자동 트리거

이 skill은 다음 조건에서 **proactively** 작동합니다:

| 조건 | 예시 |
|------|------|
| "skill" + 작업 동사 | "skill 만들어줘", "skill 수정해줘" |
| skill 이름 언급 + 작업 | "ldoc 확장해줘" |
| prompts/skills/ 파일 작업 | SKILL.md 수정 요청 |

**핵심 철학**:
- 작업 컨텍스트 자동 분석 (대화, 파일 변경)
- Best practices 자동 적용 (기존 skills 패턴)
- 토큰 효율 최적화 (리소스 분리, 템플릿 위임)
- 검증 자동화 (필수 섹션, 분량, 파일명)

## Instructions

### 워크플로우 0: Understanding (사용 예시 수집)

Skill 생성 전 **구체적 사용 예시**를 수집하십시오. 예시가 많을수록 좋은 skill이 됩니다.

1. **기존 대화에서 추출**
   - "이 작업을 다시 하려면 어떻게?"
   - 반복된 요청 패턴

2. **사용자에게 질문**
   - "이 skill을 언제 사용하시겠어요?"
   - "어떤 입력을 주고 어떤 결과를 원하세요?"

3. **최소 3개 예시** 확보 후 다음 단계로

### 워크플로우 1: 작업 컨텍스트 분석

사용자가 "여태까지 작업을 skill에 반영해줘" 또는 "skill로 만들어줘" 요청 시:

1. **대화 히스토리 분석**
   - 최근 작업 내용 파악
   - 반복된 패턴 식별
   - 사용된 도구/명령어 추출

2. **파일 변경 확인**
   ```bash
   git status
   git diff --cached
   ```
   - 새로 생성된 파일
   - 수정된 파일
   - 파일 변경 패턴

3. **패턴 추출**
   - 워크플로우 (단계별 작업)
   - 반복 작업 (동일 명령 여러 번)
   - 도구 사용 (특정 CLI, 스크립트)
   - 파일 생성 (템플릿 기반)

4. **워크플로우 2로 진행**

### 워크플로우 2: 기존 Skill 연관성 확인

1. **skills 디렉토리 검색**
   ```bash
   Glob ~/dots/prompts/skills/*/SKILL.md
   ```

2. **키워드 매칭**
   - 작업 내용에서 핵심 키워드 추출
   - 각 skill의 description과 비교
   - Grep으로 skill 내용 검색

3. **연관성 판단**
   - **높은 연관성** (80%+ 일치):
     - 같은 도메인 (예: 문서화, 배포, 테스트)
     - 같은 도구 사용
     - 같은 워크플로우 패턴
     → **워크플로우 3A (갱신)로 진행**

   - **낮은 연관성** (20% 미만):
     - 새로운 도메인
     - 다른 도구/패턴
     → **워크플로우 3B (신규)로 진행**

   - **중간 연관성** (20-80%):
     - 사용자에게 질문: "기존 {skill-name}에 추가 vs 새 skill 생성?"
     - 사용자 선택에 따라 3A 또는 3B

4. **사용자 확인**
   - 발견된 관련 skill 목록 제시
   - 갱신 vs 신규 최종 확인

### 워크플로우 3A: 기존 Skill 갱신

기존 skill에 새로운 내용을 추가할 때:

1. **갱신 유형 결정**

   AskUserQuestion으로 확인:
   - [1] 워크플로우 추가 (새로운 사용 사례)
   - [2] 리소스 추가 (상세 지식 확장)
   - [3] 예시 추가 (새로운 시나리오)
   - [4] 원칙 추가/수정 (best practice)
   - [5] 안티패턴 추가 (주의사항)

2. **갱신 실행**

   **옵션 1: 워크플로우 추가**
   - 기존 SKILL.md Read
   - 마지막 워크플로우 번호 확인
   - 새 워크플로우 추가 (번호 증가)
   - 간결성 유지 (15-30줄)

   **옵션 2: 리소스 추가**
   - resources/ 디렉토리 확인
   - 새 리소스 파일 생성 (번호 매김)
   - SKILL.md에서 참조 추가

   **옵션 3: 예시 추가**
   - Examples 섹션에 추가
   - 플로우 차트식 (간결)

   **옵션 4: 원칙 추가/수정**
   - 중요 원칙 섹션 수정
   - 기존 원칙 개선

   **옵션 5: 안티패턴 추가**
   - 문서 작성 안티패턴 섹션 추가/수정
   - ❌/✅ 형식

3. **검증**
   - 분량 확인 (기존 + 신규 < 600줄)
   - 일관성 확인 (기존 구조 유지)
   - Best practices 체크리스트

4. **Git 커밋**
   ```bash
   cd ~/dots/prompts/skills/{skill-name}
   git add .
   git commit -m "[skill] update {skill-name} - {변경 요약}"
   ```

### 워크플로우 3B: 신규 Skill 생성

새로운 skill을 만들 때:

1. **Skill 이름 결정**
   - kebab-case
   - 2-3 단어 권장
   - 도메인 명확 (예: doc-optimization, deployment-automation)

2. **Skill 카테고리 및 유형 선택**

   **카테고리** (Anthropic 공식 분류):
   | 카테고리 | 설명 | 예시 |
   |---------|------|------|
   | **Document/Asset 생성** | 파일, 문서, 다이어그램 등 산출물 생성 | literate-docs, good-spec |
   | **Workflow 자동화** | 다단계 프로세스를 정형화하여 실행 | tdd-practices, git-worktree, plan-creator |
   | **MCP 강화** | 외부 도구/서비스 조합을 전문화 | agent-browser, tmux-agent |

   **구현 패턴** (AskUserQuestion으로 확인):
   - [1] 워크플로우 기반 (단계별 작업, 200-450줄)
   - [2] 리소스 로딩 기반 (키워드 매칭, 140-160줄)
   - [3] Phase 기반 (선형 진행, 200-250줄)
   - [4] 가이드/리뷰 기반 (체크리스트, 280-520줄)
   - [5] 도구 실행 기반 (CLI 래퍼, 90-100줄)

   **상세 템플릿**: `resources/01-type-templates.md` 참조

3. **디렉토리 생성**
   ```bash
   mkdir -p ~/dots/prompts/skills/{skill-name}
   mkdir -p ~/dots/prompts/skills/{skill-name}/resources
   mkdir -p ~/dots/prompts/skills/{skill-name}/templates
   ```

4. **SKILL.md 작성**

   **Frontmatter** (Description이 가장 중요):
   ```yaml
   ---
   name: {skill-name}
   description: {구체적 기능}. Use when {트리거 상황}, {사용 맥락}.
   ---
   ```

   **description 예시**:
   - `description: Generates API documentation. Use when documenting endpoints or creating OpenAPI specs.`
   - `description: Resolves Git rebase conflicts. Use when encountering merge conflicts during rebase operations.`

   **선택 필드** — 필요한 경우에만 추가:

   **`argument-hint`** — `/` 자동완성 시 인자 힌트. 본문에서 `$ARGUMENTS` (전체) 또는 `$0`, `$1` (개별)로 참조.
   ```yaml
   argument-hint: "[issue-number]"
   # 본문: Fix GitHub issue $ARGUMENTS following our standards.
   ```

   **`disable-model-invocation: true`** — Claude 자동 호출 차단, 사용자 `/`만 허용. description이 컨텍스트에 로드되지 않음. 배포, 커밋 등 부작용이 큰 작업용.
   ```yaml
   disable-model-invocation: true
   ```

   **`user-invocable: false`** — `/` 메뉴에서 숨김, Claude만 자동 호출. description은 컨텍스트에 로드됨. Claude용 배경 지식/레퍼런스용.
   ```yaml
   user-invocable: false
   ```

   **`allowed-tools`** — skill 실행 중 사용 가능한 도구 제한. 와일드카드 지원.
   ```yaml
   allowed-tools: Read, Grep, Glob              # 읽기 전용
   allowed-tools: Bash(git *), Read, Grep, Glob  # Git만 허용
   ```

   **`model`** — skill 실행 시 모델 오버라이드. 종료 후 원래 모델 복귀.
   ```yaml
   model: claude-haiku-4-5-20251001   # 간단한 작업은 저비용
   model: claude-opus-4-6             # 복잡한 분석은 고성능
   ```

   **`context: fork`** + **`agent`** — 독립 서브에이전트에서 격리 실행. 메인 대화 이력 미접근, 컨텍스트 보호.
   ```yaml
   context: fork
   agent: Explore    # Explore, Plan, general-purpose, 또는 커스텀
   ```

   **`hooks`** — skill 실행 중에만 활성화되는 훅. 종료 시 해제.
   ```yaml
   hooks:
     - matcher: Bash
       hooks:
         - type: command
           command: "~/.claude/hooks/check-secrets.sh"
           timeout: 30
   ```

   **동적 컨텍스트** — 본문에서 `` !`command` `` 으로 셸 명령 전처리 (Claude 이전 실행, 출력 삽입):
   ```markdown
   PR diff: !`gh pr diff`
   ```

   **핵심 철학** (선택, 여러 방법 중 선택 시):
   ```markdown
   **핵심 철학**:
   - 원칙 1
   - 원칙 2
   - 원칙 3
   - 원칙 4
   ```

   **Instructions**:
   - 워크플로우 기반: ### 워크플로우 1, 2, 3...
   - Phase 기반: ## Phase 1, 2, 3...
   - 리소스 로딩: 키워드 매칭 테이블 + 리소스 로딩 전략

   **중요 원칙** (3-7개):
   ```markdown
   ## 중요 원칙

   1. **원칙명**: 설명
   2. **원칙명**: 설명
   ```

   **Examples** (2-3개, 플로우 차트식):
   ```markdown
   ## Examples

   ### {시나리오명}
   User: "{요청}" → 워크플로우 N → {결과}
   ```

   **Technical Details**:
   ```markdown
   ## Technical Details

   상세한 내용은 `REFERENCE.md`를 참조하세요.
   ```

5. **추가 파일 생성** (선택)

   **REFERENCE.md** (리소스 5개 이상 시):
   - 리소스 전체 개요
   - 권장 학습 순서
   - 트러블슈팅

   **templates/** (파일 생성 skill):
   - 템플릿 파일들
   - Frontmatter 포함

   **resources/** (지식 분리 시):
   - 번호 매김 (01-05)
   - 주제별 분리
   - 언어별 분리 (languages/)

6. **검증**
   - Best practices 체크리스트 (`resources/02-best-practices-checklist.md`)
   - 분량 검증 (유형별 권장 범위)
   - 필수 섹션 확인

7. **Git 커밋**
   ```bash
   cd ~/dots/prompts/skills/{skill-name}
   git add .
   git commit -m "[skill] add {skill-name}"
   ```

8. **사용법 안내**
   - Skill 호출 방법
   - 키워드 (description에서 추출)
   - 예시 요청 문장

### 워크플로우 4: Iterating (피드백 기반 개선)

Skill 생성/갱신 후 **실제 사용 피드백**을 반영하십시오:

1. **사용 관찰**
   - 실제 트리거 빈도
   - 예상치 못한 사용 패턴
   - 실패하는 케이스

2. **피드백 수집**
   - "이 skill이 도움이 됐나요?"
   - "빠진 기능이 있나요?"

3. **개선 반영**
   - description 키워드 조정 (트리거 개선)
   - 워크플로우 추가/수정
   - 예시 보강

4. **반복**
   - 3회 이상 사용 후 안정화 판단
   - 안정화 전까지 피드백 루프 유지

### 워크플로우 5: Prompt → Skill 변환

기존에 잘 작동하는 프롬프트를 skill로 변환:

1. **프롬프트 분석**
   - 구조 파악 (섹션, 단계)
   - 변수 식별 (사용자 입력)
   - 출력 형식 확인

2. **SKILL.md 생성**
   ```yaml
   ---
   name: your-skill-name
   description: 언제 사용하는지 명시. 키워드 포함.
   ---

   [기존 프롬프트 내용]
   ```

3. **저장 및 등록**
   - `~/.claude/skills/{name}/SKILL.md`로 저장
   - 또는 심볼릭 링크 설정

4. **트리거 테스트**
   - "Use the {name} skill to {action}" 명시적 호출
   - description 키워드로 자동 트리거 확인

### 워크플로우 6: Project Context 생성

프로젝트 문서/코드 분석 → 컨텍스트 skill:

1. **소스 분석**
   - README.md, 문서 파일
   - 코드 구조 (디렉토리, 주요 파일)
   - 기존 CLAUDE.md

2. **컨텍스트 추출**
   - 프로젝트 목적/개요
   - 아키텍처/기술 스택
   - 코딩 컨벤션
   - 주요 용어/개념

3. **Skill 생성**
   ```yaml
   ---
   name: project-context
   description: {프로젝트명} 컨텍스트. 프로젝트 작업 시 자동 로드.
   ---

   ## Project Overview
   [추출된 개요]

   ## Architecture
   [기술 스택, 구조]

   ## Conventions
   [코딩 스타일, 규칙]

   ## Terminology
   [프로젝트 특화 용어]
   ```

4. **활용**
   - 프로젝트 작업 시 컨텍스트 재설명 불필요
   - 다른 skills와 조합 가능

## 대화형 설계 (AskUserQuestion 활용)

Skill 내에서 사용자와 상호작용이 필요한 경우 AskUserQuestion을 적재적소에 활용하세요.

### 언제 사용하는가

| 상황 | 사용 여부 | 이유 |
|------|:--------:|------|
| 여러 옵션 중 선택 필요 | ✅ | 사용자 의도 확인 |
| 되돌리기 어려운 작업 전 | ✅ | 실수 방지 |
| 모호한 요청 명확화 | ✅ | 정확한 결과물 |
| 단순 확인 (Y/N) | ❌ | 흐름 방해 |
| 이미 명확한 지시 | ❌ | 불필요한 지연 |

### 좋은 질문 설계

```markdown
# ✅ 좋은 예: 구체적 옵션 + 설명
"어떤 유형의 skill을 생성할까요?"
- [워크플로우 기반] 단계별 작업, 200-450줄
- [리소스 로딩] 키워드 매칭, 140-160줄
- [Phase 기반] 선형 진행, 200-250줄

# ❌ 나쁜 예: 모호한 질문
"어떻게 할까요?"
"진행할까요?"
```

### 옵션 구성 원칙

1. **2-4개 옵션**: 너무 많으면 선택 피로
2. **권장 옵션 먼저**: 첫 번째에 "(권장)" 표시
3. **각 옵션에 설명**: 선택 결과가 명확하도록
4. **Other 자동 제공**: 예외 케이스 대응

### Skill에서 AskUserQuestion 위치

```
워크플로우 시작
    ↓
[분석/탐색] ← 질문 없이 진행
    ↓
[분기점] ← AskUserQuestion (옵션 제시)
    ↓
[실행] ← 선택에 따라 진행
    ↓
[검증] ← 질문 없이 진행
```

**핵심**: 분석 후, 실행 전에 질문. 매 단계 질문은 피로감 유발.

### 안티패턴

| ❌ 문제 | ✅ 해결 |
|--------|--------|
| 매 단계마다 확인 질문 | 분기점에서만 질문 |
| "진행할까요?" 단순 확인 | 구체적 옵션 제시 |
| 옵션 5개 이상 | 2-4개로 그룹화 |
| 설명 없는 옵션 | 각 옵션에 결과 설명 |

## 중요 원칙 (Anthropic 공식 권장)

1. **평가부터 시작**: Claude의 약점을 관찰 후 그 격차를 메우는 skill 구축
2. **Description이 핵심**: What + When 명시, 구체적 키워드 포함
3. **규모에 맞춘 구조화**: SKILL.md 복잡해지면 별도 파일로 분리
4. **Claude 관점에서 설계**: 실제 사용을 모니터링하며 description 반복 개선
5. **Claude와 협업**: Claude에게 성공/실패 사례를 skill로 문서화 요청
6. **토큰 효율**: Progressive Disclosure 원칙 준수
7. **모듈식 설계**: 단일 책임 원칙, 작은 focused skills → 조합하여 사용

## 안티패턴

| ❌ 문제 | ✅ 해결 |
|--------|--------|
| SKILL.md 500줄 초과 | resources/로 상세 내용 분리 |
| 프로젝트 특정 정보 포함 | placeholder 사용 ({project}, {name}) |
| 다른 skill과 내용 중복 | 참조로 대체 ("tdd-practices 참조") |
| description에 키워드 부족 | 트리거 키워드 명시적 포함 |
| 모놀리식 skill (너무 많은 기능) | 단일 책임으로 분리, 조합하여 사용 |
| 자동 트리거 의존 | 명시적 호출 패턴도 안내 |

## Examples

### 기존 Skill 갱신
```
User: "여태까지 작업을 ldoc에 반영해줘"
→ 워크플로우 1: 작업 분석
→ 워크플로우 2: ldoc 발견 (높은 연관성)
→ 워크플로우 3A: 갱신 실행
→ Git 커밋
```

### 신규 Skill 생성
```
User: "이 작업 패턴을 skill로 만들어줘"
→ 워크플로우 1: 작업 분석
→ 워크플로우 2: 관련 skill 없음
→ 워크플로우 3B: 신규 생성 (유형 선택 → 작성 → 검증)
→ 사용법 안내
```

### Skill 확장/리네임 (proactive 트리거)
```
User: "claude-guide skill 확장해줘" 또는 "ldoc에 워크플로우 추가해줘"
→ 자동 트리거: skill 이름 + 작업 동사 감지
→ 워크플로우 3A: 기존 skill 갱신
→ Best practices 검증
```

## Technical Details

### 스크립트

```bash
# 새 skill 초기화
bash scripts/init-skill.sh <skill-name>

# skill 검증
bash scripts/validate-skill.sh <skill-name>
```

### 리소스

- `REFERENCE.md`: Skill 유형별 상세 설명
- `resources/01-type-templates.md`: 5가지 유형 템플릿
- `resources/02-best-practices-checklist.md`: 검증 체크리스트
- `resources/03-update-patterns.md`: 갱신 패턴 가이드
- `resources/04-interactive-design.md`: 대화형 skill 설계 패턴
- `resources/05-composable-skills.md`: 모듈식 skill 조합 가이드
- `templates/SKILL-template.md`: 기본 뼈대
