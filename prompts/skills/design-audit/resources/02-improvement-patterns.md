# Improvement Patterns

AI 심미적 패턴 탈피를 위한 카테고리별 개선 전략. 점수 2+ 카테고리에 해당 섹션을 적용한다.

---

## 1. Color Palette

### 이론 기반 개선 Framework

**60-30-10 Rule 적용**:
- **60% Dominant**: 배경, 넓은 면적. 중립적이거나 브랜드의 base tone
- **30% Secondary**: 카드, 섹션 배경, 보조 요소. Dominant과 조화되는 색
- **10% Accent**: CTA, 강조, 상태 표시. 시선을 끄는 대비색
- AI gradient가 전면을 덮으면 이 구조가 무너짐 → solid dominant + 절제된 accent로 재구성

**Color Harmony 선택**:
- Analogous(유사색)에서 탈피 → 브랜드에 맞는 harmony 선택:
  - **Complementary(보색)**: 강한 대비, 에너지 (예: blue + orange)
  - **Split-complementary(분할보색)**: 보색보다 유연, 초보에게 안전 (예: blue + yellow-orange + red-orange)
  - **Triadic(삼색)**: 균형 + 활기 (예: blue + red + yellow, 채도 조절 필수)
- 색상환에서 hue 간격이 60° 이상 벌어지면 AI analogous 패턴 탈피

**Temperature Balance**:
- Cool-only에서 탈피: warm accent 최소 1개 도입 (amber, coral, terracotta)
- 또는 warm-dominant를 선택 (AI가 거의 하지 않는 선택이므로 차별화 효과 큼)

**Semantic Color 설계**:
- 장식이 아닌 의미를 담도록: success(green), warning(amber), error(red), info(blue)
- 카테고리/태그에 색상 코드 부여 → 색이 정보를 전달
- Interactive state(hover, active, focus)별 색상 변주

### Quick Wins
- Tailwind config에 custom color 정의 — 기본 palette 대체
  ```js
  // tailwind.config.js
  colors: {
    brand: { primary: '#...', secondary: '#...', accent: '#...' }
  }
  ```
- `bg-indigo-*` / `bg-violet-*` → semantic token (`bg-brand-primary`)으로 교체
- Warm tone 도입 (amber, terracotta, olive, sage) — AI-cool 스펙트럼 탈피
- Gradient endpoint를 brand color로 교체하거나, gradient 자체를 solid color로 단순화
- 60-30-10 비중 확인: dominant이 gradient 하나에 의존하면 solid로 분리

### Advanced
- 브랜드 사진/물리적 소재에서 컬러 추출 (Coolors, Adobe Color의 이미지 추출 기능)
- Complementary/split-complementary 배색으로 교체 — analogous purple-blue 탈피
- 섹션별 컬러 변주 도입 (한 gradient가 전체를 지배하지 않도록)
- Muted/desaturated 변형 사용 — full-saturation default 회피
- Semantic color system 구축: status + category + interaction state별 색상 정의

---

## 2. Typography

### Quick Wins
- Display/heading 용 개성 있는 서체 1개 추가 (serif, slab-serif, 또는 display sans)
- Body와 heading의 font-weight 대비 강화 (예: heading 700 + body 400)
- Letter-spacing 미세 조정: heading은 `tracking-tight`, body는 기본
- Font-size 계층 명확화: 최소 3단계 이상의 시각적 크기 차이

### Advanced
- Custom typeface 라이선스 또는 가변 폰트(variable font) 도입
- Serif + sans-serif 조합으로 시각적 긴장감
- 대형 타이포그래피를 히어로 요소로 활용 (이미지 의존도 감소)
- 행간(line-height)을 콘텐츠 밀도에 따라 차등 적용

---

## 3. Surface Treatment

### Quick Wins
- SVG noise overlay 추가:
  ```css
  .textured {
    background-image: url("data:image/svg+xml,..."); /* noise pattern */
    opacity: 0.03;
  }
  ```
- Shadow에 color 추가 — 순수 black 대신 brand color 기반 shadow
  ```css
  box-shadow: 0 4px 14px rgba(59, 130, 246, 0.08); /* blue-tinted */
  ```
- Border-radius 변주: 모든 카드 동일 → 요소별 차등 (버튼 pill, 카드 sm, 이미지 lg)
- 미묘한 border 추가 (shadow만 의존 → border + shadow 조합)

### Advanced
- 스캔한 종이/패브릭 텍스처를 low-opacity 배경으로
- Refractive glass effect 대신 실제 물리적 질감 참조한 surface
- Section별 배경 변화 (solid → textured → image → solid)
- CSS `background-blend-mode` 활용한 복합 surface

---

## 4. Imagery

### Quick Wins
- AI/stock 이미지를 실제 제품/팀 사진으로 교체 (폰 사진이라도)
- Glowing orb/blob 장식 → SVG 패턴, 손그림 요소, 또는 제거
- 일러스트 스타일 통일 — 하나의 커스텀 스타일로 일관성 확보
- 아이콘을 Heroicons/Lucide 기본값에서 벗어나 커스텀 또는 특색 있는 세트로

### Advanced
- 커스텀 일러스트레이션 커미션 또는 자체 제작
- 사진에 의도적 grain 추가 (ISO 800+ 느낌, Lightroom grain 기능)
- Editorial/magazine 스타일 이미지 레이아웃 (full-bleed, asymmetric crop)
- 브랜드 스토리를 담은 이미지 시퀀스 (generic → narrative)

---

## 5. Layout

### Quick Wins
- 3-column feature grid → 비대칭 레이아웃 (2+1, 1+2, full-width 교차)
- 섹션 간 padding 변주 — 균일 `py-20` 대신 밀도 변화
- 한 섹션을 full-width 또는 narrow-width로 차별화
- 카드 크기 변주 (featured card를 크게, 나머지를 작게)

### Advanced
- Editorial grid 도입: 12-column grid에서 비균등 span
- Broken grid / overlap 요소로 시각적 깊이
- Whitespace를 디자인 요소로 활용 (의도적 비움)
- 스크롤 기반 레이아웃 전환 (stack → horizontal → grid)

---

## 6. Visual Effects

### Quick Wins
- Glassmorphism 사용 빈도 제한 — 전체 중 1-2개 요소에만
- Glow/bloom 제거하거나 극도로 절제 (spread < 10px, opacity < 0.1)
- Float animation 제거 — 정적이거나 hover 시에만 미세 이동
- Blur blob 장식 → solid shape 또는 제거

### Advanced
- 효과를 기능적 목적에 한정 (focus indicator, hover feedback, status signal)
- Micro-interaction에 커스텀 easing curve (cubic-bezier) 적용
- Scroll-triggered animation을 content reveal에만 절제적 사용
- Transition 타이밍을 요소별 차등 (staggered, not uniform)

---

## 7. Brand Identity

### Quick Wins
- Hero 카피를 구체적 가치 제안으로 교체 ("Supercharge your workflow" → 실제 해결 문제)
- 로고 없이도 인식 가능한 시각 요소 1개 도입 (컬러, 패턴, 마스코트, 서체)
- 업종/문화적 맥락을 반영한 이미지/톤 선택
- CTA 문구를 generic에서 specific으로 ("Get Started" → "Start your free trial")

### Advanced
- 브랜드 디자인 시스템 구축 (토큰, 컴포넌트, 패턴 문서화)
- Voice & Tone 가이드라인 수립 — 카피 전반에 적용
- 경쟁사 디자인 벤치마킹 → 차별화 포인트 도출
- 브랜드 모션 랭귀지 정의 (애니메이션의 성격/속도/리듬 통일)

---

## 8. Copy & Content

### Quick Wins
- Hero 카피: 과장 동사(revolutionize, transform) → 제품이 실제로 하는 일을 구체적으로
- CTA를 specific하게: "Get Started" → "Try the editor free" / "See pricing"
- Feature 카드: benefit-only → 실제 기능 + benefit 조합
- 3초 테스트: 로고를 가리고 hero만 봤을 때, 무엇을 하는 서비스인지 알 수 있는가?

### Advanced
- Voice & Tone 가이드 수립 → 전체 카피에 일관된 브랜드 성격 적용
- Empty state/에러 상태/로딩 상태 디자인 추가 — 실제 사용 경험 고려
- Pricing 구조를 제품에 맞게 재설계 (무조건 3열이 아닌, 실제 가격 모델 반영)
- Micro-copy(tooltip, placeholder, error message)에 personality 부여

---

## General: Intentional Imperfection Techniques

AI의 "normalized perfection"에 대한 의도적 반발 전략:

- **Hand-drawn SVG**: 테두리, 밑줄, 아이콘을 손그림 스타일로
- **Scanned texture overlay**: 종이/패브릭 스캔 → opacity 3-8% 오버레이
- **Asymmetric spacing**: Hero/CTA에서 의도적 비대칭 배치
- **Photography grain**: ISO 800+ 느낌의 film grain 추가
- **Handwritten accent**: 강조 텍스트에 손글씨 서체 (Caveat, Indie Flower 등)
- **Imperfect shapes**: 완벽한 원/사각형 대신 organic blob (hand-traced SVG)
- **Cultural/local elements**: 지역적/문화적 맥락을 반영한 비주얼
- **Micro-copy personality**: 에러 메시지, tooltip, 빈 상태에 브랜드 voice 반영
