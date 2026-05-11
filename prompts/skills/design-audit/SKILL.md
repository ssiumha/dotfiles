---
disable-model-invocation: true
name: design-audit
description: >-
  Audits visual design for AI-generated aesthetic patterns and produces improvement plans.
  Use when reviewing UI design, checking if a website looks "AI-generated",
  auditing .pen files for generic aesthetics, or improving visual identity.
  Also use when "AI purple", "looks generic", "soulless design", "design review",
  "AI스러운", "디자인 점검", "디자인 감사", or "escape AI aesthetic".
  Do NOT use for code review (use code-review) or accessibility audit.
argument-hint: "[url | .pen-path | screenshot-path | css-glob]"
---

# Design Audit

디자인의 "AI스러움"을 8개 카테고리로 정량 점검하고, 개선 계획을 생성한다.

상세 절차는 INSTRUCTIONS.md를 참조하세요.

## Input Detection

`$ARGUMENTS` 또는 대화 맥락에서 대상을 감지한다.

| Input | Detection | Capture Tool |
|-------|-----------|--------------|
| URL (`http://`, `https://`) | regex | `agent-browser open` + `screenshot` + `snapshot -i` |
| .pen file | extension `.pen` | `mcp__pencil__get_screenshot` + `batch_get` + `search_all_unique_properties` |
| Image (.png/.jpg/.webp) | extension | Read (멀티모달 직접 분석) |
| CSS/Tailwind files | glob pattern | Grep (color, font, effect 패턴) |
| No input | — | AskUserQuestion으로 대상 확인 |

복수 소스 제공 시 모든 소스에서 수집 후 교차 검증한다.

## Workflow

### Phase 1: Capture

입력 타입에 따라 시각 + 구조 데이터를 수집한다.

- **URL**: agent-browser로 full-page screenshot + accessibility snapshot + CSS 패턴 grep
- **.pen**: pencil MCP로 screenshot + 디자인 토큰 인벤토리 (색상, 폰트, 간격, 라운딩)
- **Image**: Read로 직접 시각 분석 (구조 데이터 없음 → "Visual-only audit")
- **CSS**: Grep으로 color/font/effect/layout 패턴 추출

### Phase 2: Audit

`resources/01-ai-aesthetic-checklist.md`를 로드하여 8개 카테고리별 0-3점 채점:

1. **Color Palette** — AI Purple Problem, gradient 남용, neon accent
2. **Typography** — 제네릭 폰트(Inter/Roboto), 계층 부재
3. **Surface Treatment** — 과도한 smoothness, 질감 부재
4. **Imagery** — Glowing orb, chrome 3D, 스톡 느낌
5. **Layout Regularity** — 완벽한 대칭, 3-column grid 반복
6. **Visual Effects** — Glassmorphism/glow/blur 과잉
7. **Brand Identity** — Generic SaaS template 느낌
8. **Copy & Content** — AI slop copy, generic CTA, empty state 부재

총점/24 → 등급:

| 총점 | 등급 | 의미 |
|------|------|------|
| 0–4 | **Authentic** | AI 패턴 최소, 고유 아이덴티티 |
| 5–10 | **Mixed** | 일부 패턴 존재, 부분 개선 권장 |
| 11–17 | **AI-Adjacent** | 상당한 AI 영향, 우선 개선 필요 |
| 18–24 | **AI-Saturated** | 강한 AI 생성 느낌, 전면 재검토 |

**정량 분석 핵심**: 값의 통일이 문제가 아니라 "Custom vs Default" 구분이 핵심. Tailwind/프레임워크 default에 수렴했는가, 의도적 디자인 시스템인가.

### Phase 3: Report

점수 2+ 카테고리에 대해 `resources/02-improvement-patterns.md`를 로드하여 구체적 개선안을 포함한 리포트를 생성한다.

리포트 구조:
1. **Summary** — 전체 인상 2-3문장
2. **Scores** — 8개 카테고리 점수 테이블
3. **Findings** — 우선순위 순, Evidence + Pattern + Improvement
4. **Improvement Plan** — Quick Wins (1-2h) → Structure (2-4h) → Identity (4-8h)

## Core Principles

1. **Evidence-based** — 구체적 요소(hex, 클래스명, 스크린샷 영역)를 근거로 채점. 주관적 느낌 배제
2. **Severity-ranked** — 3점 Critical → 2점 High → 1점 Low. 가장 큰 영향부터
3. **Actionable** — 모든 finding에 구체적 수정 방안 포함
4. **Non-dogmatic** — 맥락에 따라 AI 패턴이 의도적일 수 있음. Flag하되 condemn하지 않음
5. **Brand-aware** — 기존 브랜드 의도를 파악한 후 제안. 브랜드 파괴적 제안 금지

## Examples

### URL 점검
User: `/design-audit https://example-saas.com`
→ Phase 1: agent-browser screenshot + snapshot → Phase 2: 7-category scoring → Phase 3: report with findings

### .pen 파일 점검
User: `/design-audit ~/Documents/project.pen`
→ Phase 1: pencil screenshot + search_all_unique_properties → Phase 2: scoring → Phase 3: report

### 자연어 트리거
User: "이 사이트 너무 AI스러운데 어떻게 고칠 수 있을까?"
→ URL 또는 대상 확인 → full audit workflow
