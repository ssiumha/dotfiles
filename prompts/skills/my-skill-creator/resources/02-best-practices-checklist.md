# Best Practices 체크리스트

Skill 생성 또는 갱신 후 다음 체크리스트로 품질을 검증하세요.

## 1. SKILL.md 작성

### 필수 섹션
- [ ] Frontmatter (name, description)
- [ ] 1-2문장 개요
- [ ] Instructions (워크플로우/Phase/키워드 매칭)
- [ ] Examples (2-3개)
- [ ] Technical Details

### 선택 섹션
- [ ] 핵심 철학 (여러 방법 중 선택하는 skill인 경우)
- [ ] 중요 원칙 (3-7개 권장)
- [ ] 안티패턴 (❌/✅ 형식)

### Frontmatter 품질
- [ ] name: kebab-case 준수
- [ ] description: **What + When 패턴** (Anthropic 권장)
- [ ] description: 구체적 키워드 포함
- [ ] description: 2문장 이내

**Description 패턴** (영어 권장):
```yaml
# 패턴: {What}. Use when {When}.

# ✅ 좋은 예시
description: Generates commit messages from git diffs. Use when writing commits or reviewing staged changes.
description: Resolves Git rebase conflicts. Use when encountering merge conflicts during rebase operations.
description: Creates Docker configurations. Use when containerizing apps, writing compose.yaml, or building multi-stage images.

# ❌ 나쁜 예시
description: Helps with documents.  # 너무 모호
description: Code review tool.      # When 없음
description: "보안 리뷰해줘" 요청 시 사용  # 키워드 나열
```

**한국어 대안** (필요 시):
```yaml
# ✅ 맥락 설명
description: 인증/인가 구현, API 추가, 배포 전 검토 시 proactively 사용. OWASP Top 10을 점검합니다.
```

### Instructions 품질
- [ ] 명확한 번호 매김 (워크플로우 1, 2, 3... 또는 Phase 1, 2, 3...)
- [ ] 각 단계별 입출력 명시
- [ ] 사용자 확인 지점 명시
- [ ] Bash 명령어 구체적 (예시 포함)

### Examples 품질 (Context Engineering)
- [ ] Examples 2-3개 필수 (패턴 전달에 가장 효과적)
- [ ] 실제 사용 시나리오 기반
- [ ] User 입력 → Flow → 결과 형식
- [ ] 긴 설명보다 구체적 예시 우선

---

## 2. 디렉토리 구조

### 필수 파일
- [ ] SKILL.md 존재

### 선택 파일 (필요 시)
- [ ] REFERENCE.md (리소스 5개 이상 또는 복잡한 경우)
- [ ] templates/ (파일 생성 skill)
- [ ] resources/ (지식 분리 시)

### 파일명 규칙
- [ ] SKILL.md, REFERENCE.md (대문자)
- [ ] templates/, resources/ (소문자)
- [ ] 리소스 파일: 번호 매김 (01-05) 또는 주제별
- [ ] 템플릿 파일: 의미 있는 이름

---

## 3. 토큰 효율

### SKILL.md 분량
- [ ] 100-500줄 범위 (유형별 권장 범위)
- [ ] 워크플로우 기반: 200-450줄
- [ ] 리소스 로딩 기반: 140-160줄
- [ ] Phase 기반: 200-250줄
- [ ] 가이드/리뷰: 280-520줄
- [ ] 도구 실행: 90-100줄

### 리소스 분리
- [ ] 상세 내용은 REFERENCE.md로 분리
- [ ] 리소스 로딩 기반: 키워드 매칭으로 선택적 로드
- [ ] 템플릿 위임: SKILL.md에는 간단 설명, 상세는 templates/

### 중복 제거
- [ ] 프로젝트 특정 정보 없음 (placeholder 사용)
- [ ] 다른 skill과 중복 내용 참조로 대체
- [ ] 글로벌 규칙 (commit.md 등) 재작성 안 함

---

## 4. 사용자 경험

### 명확성
- [ ] 워크플로우/Phase 번호 명확
- [ ] 각 단계별 목적 명시
- [ ] 전환 조건 명확 (Phase → Phase, 워크플로우 → 워크플로우)

### 대화형
- [ ] 사용자 확인 지점 명시 ("사용자에게 질문", "사용자 선택")
- [ ] AskUserQuestion 사용 지점 표시
- [ ] 선택지 구체적 ([1] ... [2] ...)

### 구체성
- [ ] 파일 경로 예시 포함
- [ ] Bash 명령어 실행 가능
- [ ] 플레이스홀더 사용 ({project}, {category}, {topic})

### 경고 및 금지
- [ ] 중요 경고: ⚠️ 사용
- [ ] 절대 금지: ❌ 사용
- [ ] 권장 사항: ✅ 사용
- [ ] Red Flags: 🚨 사용 (tdd 스타일)

---

## 5. 유지보수성

### 일관성
- [ ] 섹션 구조 일관 (기존 skills 패턴 준수)
- [ ] 번호 매김 일관 (워크플로우 1, 2, 3...)
- [ ] 용어 일관 (워크플로우 vs Workflow)

### 관계 명시
- [ ] 다른 skill 참조 명확 (예: ldoc와 통합)
- [ ] 글로벌 규칙 참조 (commit.md, python.md)
- [ ] REFERENCE.md 참조 (상세 내용)

### Git 커밋
- [ ] 커밋 메시지 포맷 준수
  - `[skill] add {skill-name}`
  - `[skill] update {skill-name} - {설명}`
- [ ] 변경 사항 명확

---

## 6. 분량 가이드 (상세)

### 워크플로우 기반 (200-450줄)

**최소** (200줄):
- 워크플로우 3개 x 30줄 = 90줄
- 중요 원칙: 30줄
- Examples: 40줄
- 나머지: 40줄

**적정** (300줄):
- 워크플로우 5개 x 40줄 = 200줄
- 중요 원칙: 40줄
- Examples: 40줄
- 나머지: 20줄

**최대** (450줄):
- 워크플로우 8-10개 x 40줄 = 320줄
- 중요 원칙 + 안티패턴: 80줄
- Examples: 50줄

### 리소스 로딩 기반 (140-160줄)

**구조**:
- 핵심 철학: 10줄
- 키워드 매칭 테이블: 40줄
- 리소스 로딩 전략: 30줄
- 예시: 30줄
- 중요 원칙: 20줄
- Technical Details: 10줄

### Phase 기반 (200-250줄)

**구조**:
- Phase 5개 x 40줄 = 200줄
- 중요 원칙: 30줄
- Examples: 20줄

### 가이드/리뷰 기반 (280-520줄)

**체크리스트 많음**:
- 워크플로우: 80줄
- 체크리스트: 100-200줄
- 포함/제외 기준: 50줄
- Examples: 50줄

### 도구 실행 기반 (90-100줄)

**구조**:
- 워크플로우: 40줄
- 중요 원칙: 20줄
- Examples: 20줄
- Technical Details: 10줄

---

## 7. 검증 절차

### 자동 검증

1. **파일 존재 확인**
   ```bash
   ls ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```

2. **분량 확인**
   ```bash
   wc -l ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   - 유형별 권장 범위 확인

3. **Frontmatter 검증**
   ```bash
   head -5 ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   - name, description 존재 확인

4. **섹션 구조 확인**
   ```bash
   grep "^##" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   - Instructions, Examples 존재 확인

### 수동 검증

5. **프로젝트 정보 제거**
   - 구체적 프로젝트명, IP, 리전, 파일명 등 없는지
   - placeholder 사용 확인

6. **일관성 확인**
   - 기존 skills 패턴과 비교
   - 용어, 구조, 번호 매김 일관성

7. **사용성 확인**
   - 실제 사용 시나리오 시뮬레이션
   - 명령어 실행 가능성
   - 사용자 확인 지점 적절성

---

## 8. 체크리스트 요약

**생성 전**:
- [ ] Skill 유형 결정
- [ ] 이름 결정 (kebab-case)
- [ ] 기존 skill 중복 확인

**작성 중**:
- [ ] Frontmatter 작성
- [ ] 핵심 철학 (선택)
- [ ] Instructions (워크플로우/Phase/키워드)
- [ ] 중요 원칙 (3-7개)
- [ ] Examples (2-3개)
- [ ] Technical Details

**작성 후**:
- [ ] 분량 검증 (유형별 범위)
- [ ] 필수 섹션 확인
- [ ] 파일명 규칙 확인
- [ ] 프로젝트 정보 제거
- [ ] Git 커밋

**갱신 시**:
- [ ] 기존 구조 유지
- [ ] 일관성 확인
- [ ] 분량 확인 (< 600줄)
