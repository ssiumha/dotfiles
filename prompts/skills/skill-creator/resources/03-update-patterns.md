# Skill 갱신 패턴 가이드

기존 skill을 갱신할 때 사용하는 패턴 모음입니다.

## 1. 워크플로우 추가

**언제 사용**:
- 새로운 사용 사례 발견
- 기존 워크플로우와 유사하지만 목적이 다름

**절차**:

1. **기존 워크플로우 번호 확인**
   ```bash
   grep "^### 워크플로우" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```

2. **마지막 번호 + 1로 추가**
   ```markdown
   ### 워크플로우 N: {새로운 사용 사례}

   1. **{단계명}**
      - {설명}

   2. **{단계명}**
      - {설명}
   ```

3. **간결성 유지** (15-30줄)
   - 핵심 단계만 포함
   - 상세 내용은 resources/로 분리

4. **Examples 섹션에 추가**
   ```markdown
   ### {시나리오}
   User: "{요청}" → 워크플로우 N → {결과}
   ```

**검증**:
- [ ] 기존 워크플로우와 번호 중복 없음
- [ ] 새 워크플로우 15-30줄
- [ ] Examples에 추가됨
- [ ] 총 분량 < 600줄

---

## 2. 리소스 추가

**언제 사용**:
- 상세 지식 확장
- 워크플로우가 너무 길어짐 (50줄 이상)

**절차**:

1. **resources/ 디렉토리 확인**
   ```bash
   ls ~/dots/prompts/skills/{skill-name}/resources/
   ```

2. **마지막 번호 + 1로 생성**
   ```bash
   # 예: 01-foo.md, 02-bar.md → 03-new.md
   Write ~/dots/prompts/skills/{skill-name}/resources/03-{topic}.md
   ```

3. **SKILL.md에서 참조 추가**

   **리소스 로딩 기반 skill**: 키워드 매칭 테이블에 추가
   ```markdown
   **{리소스명}** (`resources/03-{topic}.md`)
   - "키워드1", "키워드2"
   ```

   **워크플로우 기반 skill**: Technical Details에 추가
   ```markdown
   ## Technical Details

   상세한 내용은 다음을 참조하세요:
   - `resources/03-{topic}.md`: {설명}
   ```

4. **SKILL.md에서 상세 내용 제거**
   - 분리된 내용은 SKILL.md에서 삭제
   - 간단한 설명 + 참조만 남김

**검증**:
- [ ] 리소스 파일 번호 순차적
- [ ] SKILL.md에서 참조 추가
- [ ] SKILL.md 분량 감소
- [ ] 총 분량 < 600줄

---

## 3. 예시 추가

**언제 사용**:
- 새로운 시나리오 발견
- 기존 예시가 불충분

**절차**:

1. **기존 예시 형식 확인**
   ```bash
   grep -A5 "^### " ~/dots/prompts/skills/{skill-name}/SKILL.md | grep -A5 "^## Examples"
   ```

2. **플로우 차트식으로 추가**
   ```markdown
   ### {시나리오명}
   User: "{요청}" → 워크플로우 N → {결과}
   ```

3. **대화식 형식 사용 금지** (토큰 낭비)
   ❌ 나쁜 예:
   ```markdown
   User: "배포 자동화 해줘"
   Assistant: "먼저 현재 배포 방식을 확인하겠습니다."
   Assistant: "다음 명령어를 실행합니다: ls deploy/"
   ```

   ✅ 좋은 예:
   ```markdown
   User: "배포 자동화 해줘" → 워크플로우 3 → playbook 생성 → 검증 → 커밋
   ```

4. **Placeholder 사용**
   - 구체적 프로젝트명/IP/파일명 사용 금지
   - `{project}`, `{category}`, `{topic}`, `{old-value}`, `{new-value}` 사용

**검증**:
- [ ] 플로우 차트식 (간결)
- [ ] Placeholder 사용
- [ ] 예시 5줄 이하
- [ ] 총 예시 2-3개

---

## 4. 원칙 추가/수정

**언제 사용**:
- Best practice 발견
- 기존 원칙 개선 필요

**절차**:

1. **기존 원칙 개수 확인**
   ```bash
   grep "^[0-9]\+\. \*\*" ~/dots/prompts/skills/{skill-name}/SKILL.md | grep -A1 "^## 중요 원칙"
   ```

2. **추가 또는 수정**

   **추가** (7개 미만인 경우):
   ```markdown
   ## 중요 원칙

   1. **기존 원칙**: 설명
   2. **기존 원칙**: 설명
   3. **새 원칙**: 설명
   ```

   **수정** (이미 7개인 경우):
   - 기존 원칙 중 하나 개선
   - 또는 덜 중요한 원칙 제거 후 추가

3. **간결성 유지** (1-2문장)

**검증**:
- [ ] 총 원칙 3-7개
- [ ] 각 원칙 1-2문장
- [ ] 중복 없음

---

## 5. 안티패턴 추가

**언제 사용**:
- 자주 하는 실수 발견
- 주의사항 명시 필요

**절차**:

1. **안티패턴 섹션 존재 확인**
   ```bash
   grep "^## 문서 작성 안티패턴" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```

2. **없으면 생성, 있으면 추가**
   ```markdown
   ## 문서 작성 안티패턴

   ### ❌ 나쁜 예: {안티패턴명}
   ```{language}
   {나쁜 예시 코드/텍스트}
   ```

   **문제점**: {설명}

   ### ✅ 좋은 예: {개선된 방법}
   ```{language}
   {좋은 예시 코드/텍스트}
   ```

   **이유**: {설명}
   ```

3. **Placeholder 사용**
   - 구체적 프로젝트 정보 없음

**검증**:
- [ ] ❌/✅ 쌍으로 존재
- [ ] Placeholder 사용
- [ ] 각 안티패턴 10-15줄

---

## 6. 핵심 철학 추가

**언제 사용**:
- 여러 방법 중 특정 방법 선택하는 skill
- Skill의 근본 원칙 명시 필요

**절차**:

1. **Frontmatter 직후에 추가**
   ```markdown
   ---
   name: {skill-name}
   description: {설명}
   ---

   # {Skill Name}

   {1-2문장 개요}

   **핵심 철학**:
   - 원칙 1
   - 원칙 2
   - 원칙 3
   - 원칙 4
   ```

2. **간결성 유지** (4-6개 bullet)

**검증**:
- [ ] Frontmatter 직후 위치
- [ ] 4-6개 bullet
- [ ] 각 bullet 1문장

---

## 7. 분량 관리

**원칙**:
- 기존 skill 갱신 시 총 분량 < 600줄
- 신규 생성 시 유형별 권장 범위 준수

**절차**:

1. **현재 분량 확인**
   ```bash
   wc -l ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```

2. **추가 예상 분량 계산**
   - 워크플로우 추가: +15-30줄
   - 리소스 추가: SKILL.md 0줄 (분리), resources/ +N줄
   - 예시 추가: +5줄
   - 원칙 추가: +2줄
   - 안티패턴 추가: +10-15줄

3. **600줄 초과 시 리소스 분리**

   **우선순위**:
   1. 가장 긴 워크플로우 (50줄 이상)
   2. 상세 체크리스트
   3. 긴 예시 (대화식)

4. **분리 절차**
   ```bash
   Write ~/dots/prompts/skills/{skill-name}/resources/{NN}-{topic}.md
   # SKILL.md에서 상세 내용 제거
   # Technical Details에 참조 추가
   ```

**검증**:
- [ ] SKILL.md < 600줄
- [ ] 분리된 리소스 참조 추가
- [ ] 일관성 유지

---

## 8. 일관성 유지

**체크리스트**:

### 번호 매김
- [ ] 워크플로우: 1, 2, 3... (연속)
- [ ] Phase: 1, 2, 3... (연속)
- [ ] 리소스: 01-, 02-, 03-... (연속)

### 용어
- [ ] "워크플로우" vs "Workflow" 통일
- [ ] "리소스" vs "Resource" 통일
- [ ] 기존 skill 용어 준수

### 구조
- [ ] 섹션 순서: Instructions → 중요 원칙 → Examples → Technical Details
- [ ] Frontmatter 필수
- [ ] 헤더 레벨 일관 (##, ###)

### Placeholder
- [ ] `{project}`, `{category}`, `{topic}`
- [ ] `{old-value}`, `{new-value}`
- [ ] `{대안명}`

---

## 9. Git 커밋

**갱신 시 커밋 메시지**:

```bash
cd ~/dots/prompts/skills/{skill-name}
git add .
git commit -m "[skill] update {skill-name} - {변경 요약}"
```

**예시**:
- `[skill] update ldoc - add 간결성 원칙, 안티패턴 섹션`
- `[skill] update deployment - add playbook 검증 워크플로우`
- `[skill] update tdd-practices - add Red Flag (Phase 2)`

**변경 요약 작성 원칙**:
- 1-2개 주요 변경 사항만
- 동사 사용 (add, update, remove, refactor)
- 구체적 섹션명 포함

---

## 10. 검증 절차

**갱신 후 자동 검증**:

1. **분량 확인**
   ```bash
   wc -l ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   → < 600줄 확인

2. **섹션 구조 확인**
   ```bash
   grep "^##" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   → Instructions, 중요 원칙, Examples 존재 확인

3. **Placeholder 확인**
   ```bash
   grep -E "(198\.51\.|192\.168\.|10\.|IDC-[0-9])" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   → 구체적 정보 없음 확인

4. **리소스 참조 확인**
   ```bash
   grep "resources/" ~/dots/prompts/skills/{skill-name}/SKILL.md
   ```
   → 참조된 파일 존재 확인

**수동 검증**:

- [ ] 기존 구조 유지 (섹션 순서)
- [ ] 일관성 (번호, 용어)
- [ ] 간결성 (워크플로우 15-30줄)
- [ ] Placeholder 사용

---

## 패턴 요약

| 갱신 유형 | 추가 분량 | 리소스 분리 필요 | 검증 항목 |
|----------|---------|---------------|----------|
| 워크플로우 추가 | +15-30줄 | 50줄 이상 시 | 번호 중복, 간결성 |
| 리소스 추가 | 0줄 (SKILL.md) | 자동 분리 | 참조 추가, 번호 순차 |
| 예시 추가 | +5줄 | 불필요 | 플로우 차트식, Placeholder |
| 원칙 추가 | +2줄 | 불필요 | 총 3-7개, 간결성 |
| 안티패턴 추가 | +10-15줄 | 불필요 | ❌/✅ 쌍, Placeholder |
