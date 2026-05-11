# Design Audit — Detailed Procedures

## Phase 1: Capture

입력 타입을 감지하고 시각/구조 데이터를 수집한다.

### 1A. URL Target

HTTP/HTTPS URL이 제공된 경우:

1. `agent-browser open <url>` — 페이지 탐색
2. `agent-browser screenshot ~/.claude/screenshots/design-audit.png --full` — 전체 페이지 캡처
3. Read screenshot image — 멀티모달 시각 분석
4. `agent-browser snapshot -i` — accessibility tree로 구조 파악 (heading 계층, 컴포넌트 패턴, 텍스트 콘텐츠)
5. 페이지 소스에서 CSS/스타일 정보 추출 시도:
   - Snapshot에서 `<link rel="stylesheet">` 또는 inline style 확인
   - 가능하면 CSS 파일 URL을 식별하여 `agent-browser open`으로 접근
   - Tailwind 사용 여부: `class` 속성에서 `bg-`, `text-`, `font-` 패턴 확인

### 1B. .pen File Target

`.pen` 확장자 파일이 제공된 경우:

1. `mcp__pencil__get_editor_state()` — 현재 에디터 상태 확인
2. `mcp__pencil__open_document(filePath)` — 파일이 열려있지 않으면 열기
3. `mcp__pencil__batch_get(patterns: ["*"])` — 최상위 노드 구조 파악
4. `mcp__pencil__get_screenshot` — 현재 캔버스 시각 캡처
5. `mcp__pencil__search_all_unique_properties` — 디자인 토큰 인벤토리 추출:
   - `fillColor`, `textColor`, `strokeColor` → Color Palette 분석
   - `fontFamily`, `fontWeight`, `fontSize` → Typography 분석
   - `cornerRadius`, `gap`, `padding` → Layout/Surface 분석
6. 주요 프레임/화면별로 `batch_get`으로 세부 노드 탐색

### 1C. Image/Screenshot Target

이미지 파일 (.png, .jpg, .webp 등)이 제공된 경우:

1. Read image file — 멀티모달 직접 분석
2. 구조적 데이터 없음 — 순수 시각 분석만 수행
3. 리포트에 "Visual-only audit (no structural data)" 명시

### 1D. CSS/Tailwind Target

CSS 파일 경로 또는 glob 패턴이 제공된 경우:

1. Glob으로 대상 파일 탐색:
   - `**/*.css`, `**/*.scss`, `**/*.less`
   - `**/tailwind.config.*`, `**/theme.ts`, `**/theme.js`
   - `**/*.tsx`, `**/*.jsx` (인라인 클래스에서 패턴 추출)
2. Color 분석:
   - Grep: `bg-indigo`, `bg-violet`, `bg-purple`, `from-`, `to-`, `via-`
   - Grep: `#[0-9a-fA-F]{6}`, `rgb(`, `hsl(` — 사용된 컬러 수집
   - Tailwind config에서 custom colors 정의 여부 확인
3. Typography 분석:
   - Grep: `font-family`, `fontFamily`, `@import.*fonts`
   - Grep: `font-sans`, `font-serif`, `font-mono` — 사용 패턴
4. Effects 분석:
   - Grep: `backdrop-blur`, `backdrop-filter`, `blur-`
   - Grep: `shadow-`, `box-shadow`, glow 패턴
   - Grep: `bg-opacity`, `bg-white/`, `/[0-9]+` (반투명 패턴)
5. Layout 분석:
   - Grep: `grid-cols-`, `flex`, `gap-`, `py-`, `px-`
   - 반복 패턴 빈도 확인

### 1E. No Input

입력이 없는 경우:

1. 대화 맥락에서 대상 추론 시도 (현재 작업 중인 프로젝트, 최근 언급된 URL 등)
2. 추론 불가 시 AskUserQuestion으로 확인:
   > 점검 대상을 알려주세요: URL, .pen 파일 경로, 스크린샷 경로, 또는 CSS 파일 경로

### 1F. Mixed Input

여러 소스가 동시에 제공된 경우 (예: URL + CSS 파일):

1. 모든 소스에서 데이터 수집
2. 소스 간 교차 검증 (예: Tailwind config에 custom color가 있으나 배포 사이트는 기본 indigo 사용 → config 미적용 가능성)

---

## Phase 2: Audit

`resources/01-ai-aesthetic-checklist.md`를 로드하여 8개 카테고리별 채점을 수행한다.

### 채점 프로세스

각 카테고리에 대해:

1. **Evidence 수집** — Phase 1에서 확보한 데이터에서 해당 카테고리의 AI 패턴 매칭
2. **구체적 근거 기록** — hex 코드, 클래스명, 스크린샷 영역, 노드 ID 등
3. **점수 부여** — 0-3점 기준표에 따라 채점
4. **Severity 분류** — 점수에 따른 우선순위:
   - 3점: Critical
   - 2점: High
   - 1점: Low (리포트에 포함하되 개선 계획에서는 선택적)
   - 0점: Clear (리포트에서 생략 가능)

### 채점 원칙

- **Evidence-based**: 주관적 "느낌"이 아닌 구체적 요소를 근거로 채점
- **Context-aware**: 브랜드/업종 맥락 고려 (예: 보안 기업의 blue 사용은 AI가 아닌 업종 관행일 수 있음)
- **Non-dogmatic**: 일부 AI 패턴은 맥락에 따라 의도적일 수 있음 — flag하되 condemn하지 않음
- **Holistic**: 개별 요소보다 전체적 인상을 우선 판단 후 세부 채점

### Overall Grade 산출

총점 = 8개 카테고리 점수 합산 (최대 24점)

| 총점 | 등급 |
|------|------|
| 0–4 | Authentic |
| 5–10 | Mixed |
| 11–17 | AI-Adjacent |
| 18–24 | AI-Saturated |

---

## Phase 3: Report

### Report 구조

```markdown
# Design Audit Report

**Target**: [대상 URL / 파일 경로 / 설명]
**Audit Type**: [Visual + Structural | Visual-only | Structural-only]
**Date**: [YYYY-MM-DD]
**Overall Grade**: [등급] (총점/21)

## Summary

[2-3문장으로 전체 인상 요약. 가장 심각한 문제와 긍정적 측면 모두 언급]

## Scores

| Category | Score | Assessment |
|----------|-------|------------|
| Color Palette | n/3 | [한줄 요약] |
| Typography | n/3 | [한줄 요약] |
| Surface Treatment | n/3 | [한줄 요약] |
| Imagery | n/3 | [한줄 요약] |
| Layout Regularity | n/3 | [한줄 요약] |
| Visual Effects | n/3 | [한줄 요약] |
| Brand Identity | n/3 | [한줄 요약] |
| **Total** | **n/21** | **[등급]** |

## Findings (우선순위 순)

[점수 2+ 카테고리만 — 높은 점수부터]

### [Critical/High] 카테고리명 — Score n/3

**Evidence**: [구체적 요소 — hex 코드, 클래스명, 스크린샷 위치, 노드]
**Pattern**: [매칭된 AI 패턴 이름과 설명]
**Improvement**:
- [Quick Win 1]
- [Quick Win 2]
- [Advanced option — 시간 여유 시]

## Improvement Plan

[개선 항목을 시간/노력 순으로 정리]

### Phase 1: Quick Wins (1-2h)
- [ ] [가장 높은 ROI 개선 항목]
- [ ] [두 번째]

### Phase 2: Structure & Typography (2-4h)
- [ ] [중간 규모 개선]

### Phase 3: Identity & Polish (4-8h)
- [ ] [근본적 개선]
```

### Report 작성 원칙

1. **Actionable first** — 모든 finding에 구체적 수정 방안 포함
2. **Prioritized** — Critical → High 순서, 가장 큰 영향의 개선부터
3. **Respectful** — "나쁜 디자인"이 아닌 "AI 패턴 탐지" 프레이밍
4. **Balanced** — 긍정적 측면(점수 0-1 카테고리)도 Summary에서 인정
5. **Practical** — Quick Wins를 항상 먼저 제시, Advanced는 선택적

### 개선 패턴 로드

점수 2+ 카테고리에 대해 `resources/02-improvement-patterns.md`에서 해당 섹션을 로드하여 구체적 개선 전략을 리포트에 반영한다.

---

## Edge Cases

### 다중 페이지/프레임
- 대표 페이지(hero/landing)를 우선 점검
- 사용자가 특정 페이지를 지정하면 해당 페이지만
- .pen 파일의 다중 프레임은 프레임 목록을 보여주고 선택 요청

### 리디자인 맥락
- 사용자가 "리디자인 중"이라고 했을 때 → 현재 상태 점검보다 개선 계획에 중점
- 기존 디자인 점수 + 목표 점수 비교 프레이밍

### 부분 데이터
- CSS만 있고 시각 없음 → "Structural-only audit" 명시, 시각 카테고리(Imagery, Surface)는 채점 불가 표기
- 스크린샷만 있고 코드 없음 → "Visual-only audit" 명시, 코드 기반 Detection 생략

### 의도적 AI 스타일
- 사용자가 "의도적으로 이 스타일을 선택했다"고 하면 → 해당 카테고리를 "Intentional" 표기, 점수에서 제외하고 나머지만 채점
