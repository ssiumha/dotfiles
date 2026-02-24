---
name: skill-optimizer
description: Optimizes skill context by splitting large SKILL.md into INSTRUCTIONS.md. Use when skill count exceeds 10, SKILL.md exceeds 400 lines, or optimizing token efficiency. Do NOT use for skill creation (use skill-creator instead).
---

# Skill Optimizer

대규모 SKILL.md를 INSTRUCTIONS.md로 분할하여 토큰 효율을 최적화합니다.

## 배경

Skill description은 **항상 컨텍스트에 로드**됩니다 (2% of context window, fallback 16,000자).
SKILL.md는 트리거 시 전체 로드되므로, 크기가 클수록 컨텍스트 소비 증가.

**분할 효과** (실측 사례):
- 개별 skill: 37,813B → 314B (99.2% 절감)
- 87 skills 전체: 898KB → 27KB (97% 절감)

**근거**:
- [공식 문서](https://code.claude.com/docs/en/skills): "Keep SKILL.md under 500 lines. Move detailed reference material to separate files."
- [Zenn 분석](https://zenn.dev/kei31ai/articles/20260221-skill-context-optimization): SKILL.md → frontmatter + INSTRUCTIONS.md 분할 패턴

## 분할 기준

| SKILL.md 줄 수 | 권장 |
|---|---|
| < 200줄 | 분할 불필요 |
| 200~400줄 | 선택적 (resources/ 분리 우선) |
| 400줄+ | INSTRUCTIONS.md 분할 권장 |

## Instructions

### 워크플로우 1: 분석 (Audit)

`prompts/skills/*/SKILL.md` 전체를 스캔하여 분할 후보를 식별합니다.

1. **스캔**
   ```bash
   for f in ~/dots/prompts/skills/*/SKILL.md; do
     name=$(basename $(dirname "$f"))
     lines=$(wc -l < "$f")
     bytes=$(wc -c < "$f")
     has_inst=$([ -f "$(dirname "$f")/INSTRUCTIONS.md" ] && echo "Y" || echo "N")
     printf "%-30s %5d줄  %6dB  INST:%s\n" "$name" "$lines" "$bytes" "$has_inst"
   done | sort -t: -k1 -rn | sort -k2 -rn
   ```

2. **리포트 출력**
   ```
   === Skill Size Audit ===
   총 skills: {N}개
   INSTRUCTIONS.md 적용: {N}개
   400줄+ 분할 후보: {N}개

   | Skill | 줄 수 | 바이트 | INST | 권장 |
   |-------|-------|--------|------|------|
   | ... | ... | ... | N | 분할 권장 |
   ```

3. **분할 대상 확인**
   - 400줄+ skill 목록 제시
   - 사용자에게 대상 선택 요청 (AskUserQuestion)

### 워크플로우 2: 분할 (Split)

대상 skill의 SKILL.md body를 INSTRUCTIONS.md로 이동합니다.

1. **대상 읽기**
   - SKILL.md 전체 읽기
   - frontmatter 경계 식별 (첫 `---` ~ 두번째 `---`)

2. **분할 실행**
   - **SKILL.md에 남기는 것**: frontmatter + 참조문 1줄
     ```yaml
     ---
     name: {skill-name}
     description: {원본 유지}
     ---

     상세 절차는 INSTRUCTIONS.md를 참조하세요.
     ```
   - **INSTRUCTIONS.md로 이동**: frontmatter 이후 body 전체
     - 첫 줄에 `# {Skill Name}` 헤딩 추가
     - 내용 변경 없음 (순수 이동)

3. **경로 정합성**
   - body 내 `resources/`, `templates/`, `scripts/` 상대 경로는 그대로 유효 (동일 디렉토리)
   - 절대 경로 참조가 있으면 수정 불필요

**상세 절차**: `resources/01-split-guide.md` 참조

### 워크플로우 3: 검증 (Validate)

분할 결과의 정합성을 검증합니다.

1. **SKILL.md 검증**
   - frontmatter 존재 (name, description)
   - 500바이트 이하
   - body에 INSTRUCTIONS.md 참조문 존재

2. **INSTRUCTIONS.md 검증**
   - 파일 존재
   - 첫 줄에 `#` 헤딩 존재
   - 원본 SKILL.md 대비 내용 누락 없음

3. **참조 정합성**
   - INSTRUCTIONS.md 내 `resources/` 파일 참조 → 실제 파일 존재 확인
   - `templates/`, `scripts/` 참조 → 실제 파일 존재 확인

4. **리포트**
   ```
   === Validation: {skill-name} ===
   SKILL.md: {bytes}B (< 500B ✅)
   INSTRUCTIONS.md: {lines}줄 ✅
   리소스 참조: {N}/{N} ✅
   ```

## 중요 원칙

1. **내용 무변경**: 분할은 SKILL.md body → INSTRUCTIONS.md 이동일 뿐, 내용을 수정하지 않음
2. **frontmatter 유지**: name, description 등 메타데이터는 반드시 SKILL.md에 유지
3. **기존 구조 보존**: resources/, templates/, scripts/는 그대로 유지
4. **점진적 적용**: 전체 일괄 분할보다 큰 skill부터 순차 적용 권장
5. **복원 가능**: INSTRUCTIONS.md → SKILL.md body로 역병합 언제든 가능

## Examples

### 전체 스캔 후 분할
```
User: "skill 최적화해줘" / "토큰 절약해줘"
→ WF1: Audit (전체 스캔, 리포트)
→ WF2: Split (400줄+ 대상 분할)
→ WF3: Validate (검증)
```

### 특정 skill 분할
```
User: "test-guidelines skill 분할해줘"
→ WF2: Split (대상 직접 지정)
→ WF3: Validate
```
