# Skill 유형별 템플릿

## 분량 가이드

| 유형 | SKILL.md 총량 | 세부 가이드 |
|------|---------------|-------------|
| 워크플로우 기반 | 200-450줄 | 워크플로우당 15-30줄, 원칙 5-7개, Examples 2-3개 |
| 리소스 로딩 기반 | 140-160줄 | 키워드 매칭 30-50줄, 로딩 전략 20-30줄 |
| Phase 기반 | 200-250줄 | Phase당 30-50줄, Red Flags Phase별 2-4개, 총 3-5 Phase |
| 가이드/리뷰 기반 | 280-520줄 | 체크리스트 50-100줄, 포함/제외 기준 30-50줄 |
| 도구 실행 기반 | 90-100줄 | 워크플로우 30-50줄, 도구 설명은 REFERENCE.md로 위임 |

※ 실제 skill 분석 기반 권장 분량 (dots/prompts/skills/ 내 30+ skill 평균)

---

## Frontmatter 스키마

모든 skill의 SKILL.md는 YAML frontmatter로 시작합니다.

```yaml
---
name: {skill-name}           # 필수. 케밥케이스
description: {설명}          # 필수. Available skills에 표시
context: fork                # 선택. 격리된 sub-agent에서 실행
---
```

### context: fork

격리된 sub-agent 컨텍스트에서 skill 실행. 메인 대화에는 완료 메시지만 반환.

**적합한 경우**:
- 탐색/리서치 skill (긴 분석이 메인 컨텍스트 오염 방지)
- 세션 요약 skill
- 복잡한 다단계 작업

**예시**:
```yaml
---
name: deep-research
description: Codebase deep analysis. Use when exploring architecture or complex topics.
context: fork
---
```

---

## 1. 워크플로우 기반 (200-450줄)

**적합한 경우**:
- 단계별 작업이 명확
- 여러 사용 사례 (워크플로우 3개 이상)
- 사용자와 대화하며 진행

**구조**:
```markdown
---
name: {skill-name}
description: {언제 사용}. {키워드}.
---

# {Skill Name}

{1-2문장 개요}

## Instructions

### 워크플로우 1: {제목}

1. **{단계명}**
   - {설명}

2. **{단계명}**
   - {설명}

### 워크플로우 2: {제목}

...

## 중요 원칙

1. **원칙명**: 설명
2. **원칙명**: 설명

## Examples

### {시나리오}
User: "{요청}" → 워크플로우 N → {결과}

## Technical Details

상세한 내용은 `REFERENCE.md`를 참조하세요.
```

**대표 예시**: ldoc, test-guidelines

---

## 2. 리소스 로딩 기반 (140-160줄)

**적합한 경우**:
- 상세 지식이 많음 (리소스 5개 이상)
- 토큰 효율 중요
- 키워드로 리소스 선택 가능

**구조**:
```markdown
---
name: {skill-name}
description: {언제 사용}. {키워드}.
---

# {Skill Name}

{1-2문장 개요}

**핵심 철학**:
- 원칙 1
- 원칙 2

## Instructions

### 워크플로우: 요청 분석 및 리소스 선택

#### 1. 키워드 매칭

**{리소스명}** (`resources/01-{name}.md`)
- "키워드1", "키워드2"

**{리소스명}** (`resources/02-{name}.md`)
- "키워드3", "키워드4"

#### 2. 리소스 로딩 전략

**단일 키워드**:
- User: "{요청}"
- → Read resources/01-{name}.md

**복합 요청**:
- User: "{요청}"
- → Read resources/01-{name}.md
- → Read resources/02-{name}.md

#### 3. 리소스 적용

1. 현재 프로젝트 구조 파악
2. 리소스 Read
3. 패턴 적용
4. 검증

## 중요 원칙

1. **토큰 효율**: 필요한 리소스만 Read
2. **패턴 우선**: 프로젝트 특정 내용 없음

## Examples

### {시나리오}
User: "{요청}" → 키워드 매칭 → Read 리소스 → 적용

## Technical Details

상세한 설정은 각 리소스 참조:
- `resources/01-{name}.md`: {설명}
- `resources/02-{name}.md`: {설명}
```

**대표 예시**: deployment, ci-cd

---

## 3. Phase 기반 (200-250줄)

**적합한 경우**:
- 선형 워크플로우 (단계 순서 고정)
- 각 Phase별 입출력 명확
- 전환 조건 명시 필요

**구조**:
```markdown
---
name: {skill-name}
description: {언제 사용}. {키워드}.
---

# {Skill Name}

## Phase 1: {제목}

{Phase 목적}

1. **{단계}**
   - {설명}

2. **{단계}**
   - {설명}

3. **Phase 2로 진행**

---

## Phase 2: {제목}

{Phase 목적}

1. **{단계}**
   - {설명}

### Phase 2의 Red Flags 🚨

- 🚨 **{안티패턴}**
- 🚨 **{안티패턴}**

---

## Phase 3: {제목}

...

## 중요 원칙

1. **원칙명**: 설명

## Examples

### {시나리오}
Phase 1 → Phase 2 → Phase 3 → 완료
```

**대표 예시**: tdd-practices

---

## 4. 가이드/리뷰 기반 (280-520줄)

**적합한 경우**:
- 기존 파일/코드 분석
- 체크리스트 검증
- 리포트 생성

**구조**:
```markdown
---
name: {skill-name}
description: {언제 사용}. {키워드}.
---

# {Skill Name}

{1-2문장 개요}

## Instructions

### 워크플로우: {리뷰/분석} 프로세스

1. **파일 확인**
   - {대상 파일}

2. **분석**
   - {체크 항목 1}
   - {체크 항목 2}

3. **리포트 생성**
   ```markdown
   ## {리포트 제목}

   **{섹션}**:
   - ✅ {항목}
   - ❌ {항목}
   ```

4. **사용자 확인**
   - [1] {선택지}
   - [2] {선택지}

5. **개선 실행**
   - {수정 내용}

6. **검증**
   - {확인 사항}

## 체크리스트

### 필수 항목

- [ ] {항목 1}
- [ ] {항목 2}

### 권장 항목

- [ ] {항목 1}
- [ ] {항목 2}

## 포함/제외 기준

**✅ 포함**:
- {기준 1}
- {기준 2}

**❌ 제외**:
- {기준 1}
- {기준 2}

## Examples

### {시나리오}
분석 → 리포트 → 사용자 선택 → 개선 → 검증
```

**대표 예시**: claude-guide, review-security

---

## 5. 도구 실행 기반 (90-100줄)

**적합한 경우**:
- 외부 CLI/Python 도구 래퍼
- 단순한 워크플로우 (변환 → 검증)
- REFERENCE.md에 도구 사용법

**구조**:
```markdown
---
name: {skill-name}
description: {언제 사용}. {키워드}.
---

# {Skill Name}

{1-2문장 개요}

## Instructions

### 워크플로우: {도구명} 실행

1. **{준비}**
   - {설명}

2. **도구 실행**
   ```bash
   {command}
   ```

3. **검증**
   - {확인 사항}

4. **정리**
   - {후처리}

## 중요 원칙

1. **원칙명**: 설명

## Examples

### {시나리오}
User: "{요청}" → 도구 실행 → 검증 → 정리

## Technical Details

도구 사용법은 `REFERENCE.md` 참조.
```

**대표 예시**: qmd, ast-grep

---

## 유형 선택 가이드

| 질문 | Yes → 유형 |
|------|-----------|
| 단계별 작업이 3개 이상? | 워크플로우 기반 |
| 상세 지식이 많고 토큰 효율 중요? | 리소스 로딩 기반 |
| 순서가 고정되고 선형 진행? | Phase 기반 |
| 기존 파일 분석/리뷰? | 가이드/리뷰 기반 |
| 외부 도구 래퍼? | 도구 실행 기반 |
