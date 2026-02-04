# Skill Creator - Reference

skill-creator의 상세 리소스 가이드입니다.

## 리소스 개요

| 파일 | 용도 | 언제 읽기 |
|------|------|----------|
| `resources/01-type-templates.md` | 5가지 skill 유형별 템플릿 | 신규 skill 생성 시 (워크플로우 3B) |
| `resources/02-best-practices-checklist.md` | 품질 검증 체크리스트 | 생성/갱신 후 검증 시 |
| `resources/03-update-patterns.md` | 기존 skill 갱신 패턴 | 기존 skill 갱신 시 (워크플로우 3A) |
| `templates/SKILL-template.md` | 기본 SKILL.md 뼈대 | 신규 skill 생성 시 참조 |

## 권장 학습 순서

### 1단계: Skill 유형 이해
**Read**: `resources/01-type-templates.md`

5가지 유형을 이해하고 작업에 맞는 유형 선택:
- 워크플로우 기반 (200-450줄)
- 리소스 로딩 기반 (140-160줄)
- Phase 기반 (200-250줄)
- 가이드/리뷰 기반 (280-520줄)
- 도구 실행 기반 (90-100줄)

### 2단계: Best Practices 숙지
**Read**: `resources/02-best-practices-checklist.md`

다음 항목 확인:
- SKILL.md 작성 규칙
- 디렉토리 구조
- 토큰 효율
- 사용자 경험
- 유지보수성

### 3단계A: 신규 생성 (워크플로우 3B)
**Read**: `templates/SKILL-template.md`

기본 뼈대를 참조하여 SKILL.md 작성:
1. Frontmatter
2. 핵심 철학 (선택)
3. Instructions (워크플로우/Phase)
4. 중요 원칙
5. Examples
6. Technical Details

### 3단계B: 기존 갱신 (워크플로우 3A)
**Read**: `resources/03-update-patterns.md`

갱신 유형별 패턴 적용:
- 워크플로우 추가
- 리소스 추가
- 예시 추가
- 원칙 추가/수정
- 안티패턴 추가

## 빠른 참조

### 신규 Skill 생성

```bash
# 1. 디렉토리 생성
mkdir -p ~/dots/prompts/skills/{skill-name}/resources
mkdir -p ~/dots/prompts/skills/{skill-name}/templates

# 2. 유형 선택
# Read resources/01-type-templates.md

# 3. SKILL.md 작성
# Read templates/SKILL-template.md

# 4. 검증
wc -l ~/dots/prompts/skills/{skill-name}/SKILL.md
# Read resources/02-best-practices-checklist.md

# 5. 커밋
cd ~/dots/prompts/skills/{skill-name}
git add .
git commit -m "[skill] add {skill-name}"
```

### 기존 Skill 갱신

```bash
# 1. 갱신 유형 결정
# Read resources/03-update-patterns.md

# 2. 현재 분량 확인
wc -l ~/dots/prompts/skills/{skill-name}/SKILL.md

# 3. 갱신 실행 (예: 워크플로우 추가)
# Edit ~/dots/prompts/skills/{skill-name}/SKILL.md

# 4. 검증
wc -l ~/dots/prompts/skills/{skill-name}/SKILL.md
# < 600줄 확인
# Read resources/02-best-practices-checklist.md

# 5. 커밋
cd ~/dots/prompts/skills/{skill-name}
git add .
git commit -m "[skill] update {skill-name} - {변경 요약}"
```

## 유형별 권장 분량

| 유형 | 최소 | 적정 | 최대 |
|------|------|------|------|
| 워크플로우 기반 | 200줄 | 300줄 | 450줄 |
| 리소스 로딩 기반 | 140줄 | 150줄 | 160줄 |
| Phase 기반 | 200줄 | 225줄 | 250줄 |
| 가이드/리뷰 기반 | 280줄 | 400줄 | 520줄 |
| 도구 실행 기반 | 90줄 | 95줄 | 100줄 |

**갱신 시**: < 600줄 (초과 시 리소스 분리)

## 필수 섹션

### SKILL.md
1. **Frontmatter** (필수)
   - `name`: kebab-case
   - `description`: 언제 사용 + 키워드

2. **핵심 철학** (선택)
   - 여러 방법 중 선택하는 skill인 경우
   - 4-6개 bullet

3. **Instructions** (필수)
   - 워크플로우 기반: ### 워크플로우 1, 2, 3...
   - Phase 기반: ## Phase 1, 2, 3...
   - 리소스 로딩: 키워드 매칭 + 리소스 로딩 전략

4. **중요 원칙** (필수)
   - 3-7개
   - 각 1-2문장

5. **Examples** (필수)
   - 2-3개
   - 플로우 차트식 (간결)

6. **Technical Details** (필수)
   - 리소스 참조

### 디렉토리 구조
```
skills/{skill-name}/
├── SKILL.md (필수)
├── REFERENCE.md (선택, 리소스 5개 이상 시)
├── resources/ (선택)
│   ├── 01-{topic}.md
│   ├── 02-{topic}.md
│   └── ...
└── templates/ (선택, 파일 생성 skill)
    ├── {template-name}.md
    └── ...
```

## 체크리스트 간단 버전

**생성 전**:
- [ ] Skill 유형 결정
- [ ] 이름 결정 (kebab-case)
- [ ] 기존 skill 중복 확인

**작성 후**:
- [ ] Frontmatter (name, description)
- [ ] Instructions
- [ ] 중요 원칙 (3-7개)
- [ ] Examples (2-3개)
- [ ] 분량 검증 (유형별 범위)

**갱신 후**:
- [ ] 기존 구조 유지
- [ ] 일관성 확인
- [ ] 분량 < 600줄
- [ ] Placeholder 사용

## 트러블슈팅

### 분량이 너무 많음 (> 600줄)

**해결**:
1. 가장 긴 워크플로우 확인:
   ```bash
   grep -n "^### 워크플로우" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```

2. 50줄 이상 워크플로우를 resources/로 분리

3. SKILL.md에는 간단 설명 + 참조만 남김

### 프로젝트 정보가 포함됨

**확인**:
```bash
grep -E "(198\.51\.|192\.168\.|10\.|IDC-[0-9])" ~/dots/prompts/skills/{skill-name}/SKILL.md
```

**해결**: Placeholder로 교체
- IP: `{old-value}` → `{new-value}`
- 프로젝트명: `{project}`
- 리전명: `{대안명}`
- 파일명: `{descriptive-topic}.md`

### 예시가 너무 김 (대화식)

**나쁜 예**:
```markdown
User: "배포 자동화 해줘"
Assistant: "먼저 현재 배포 방식을 확인하겠습니다."
Assistant: "다음 명령어를 실행합니다..."
```

**해결**: 플로우 차트식으로 간결화
```markdown
User: "배포 자동화 해줘" → 워크플로우 3 → playbook 생성 → 검증 → 커밋
```

### 일관성 문제 (번호, 용어)

**확인**:
```bash
grep "^### 워크플로우" ~/dots/prompts/skills/{skill-name}/SKILL.md
```

**해결**: 번호 순차적 확인, 용어 통일
- "워크플로우" vs "Workflow" → "워크플로우" 통일
- Phase 1, 2, 3... (연속)

## 참고 자료

**대표 skills**:
- 워크플로우 기반: `ldoc`, `test-guidelines`
- 리소스 로딩 기반: `deployment`, `ci-cd`
- Phase 기반: `tdd-practices`
- 가이드/리뷰 기반: `claude-guide`, `review-security`
- 도구 실행 기반: `qmd`

**글로벌 규칙**:
- `~/dots/prompts/rules/commit.md`: Git 커밋 규칙
- `~/dots/prompts/rules/documentation.md`: 문서 작성 규칙
- `~/dots/prompts/rules/implementation_test.md`: 테스트 규칙
