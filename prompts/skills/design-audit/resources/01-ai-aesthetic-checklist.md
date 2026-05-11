# AI Aesthetic Checklist

8개 카테고리로 "AI스러움"을 정량 평가한다. 각 카테고리 0-3점, 총 24점 만점.

## Quantitative Analysis (보조 도구)

시각 판단을 보완하는 정량 분석. URL 또는 CSS 대상에 적용.

**핵심 원칙: "Custom vs Default" 구분**

정량 지표 자체는 좋고 나쁨을 판단하지 않는다. 잘 만든 디자인 시스템(Material Design, Apple HIG 등)도 spacing/radius를 의도적으로 통일한다. **문제는 값의 통일이 아니라, 그 값이 "의도적 선택"인가 "AI/프레임워크 기본값 수렴"인가**이다.

| 측정 항목 | 방법 | AI Default 신호 | 의도적 디자인 시스템과 구분법 |
|-----------|------|----------------|--------------------------|
| Color token | CSS 색상 추출 → hue 분포 | hue 220°-280° (blue-violet)에 70%+ 집중 | Custom palette는 hue 분포가 다양하거나 warm tone 포함 |
| Color source | Tailwind config 확인 | default palette 그대로 (`indigo-500`, `gray-900`) | `tailwind.config`에 custom colors 명시적 정의 |
| Font stack | font-family 추출 | Inter/Roboto/Poppins + 커스텀 폰트 미정의 | custom font import 또는 config에 font 명시 |
| Font-size scale | heading/body 비율 역산 | Tailwind default scale 그대로 사용 | 별도 fontSize config 또는 custom scale |
| Spacing source | padding/margin 값 추출 | Tailwind default spacing (`py-20`, `px-6`) 그대로 | custom spacing scale 정의 또는 의도적 변주 |
| Border-radius | 값 종류 확인 | `rounded-xl` 단일 값 = Tailwind default | 여러 값이더라도 config에 정의 + 요소별 의도 |
| Tech stack | HTML/JS 분석 | Next.js + Tailwind + Shadcn + Lucide + Radix 풀세트 | 같은 스택이라도 커스터마이징 여부가 핵심 |

**판단 흐름**: 값이 통일적 → Tailwind/프레임워크 default와 일치? → Yes면 AI 패턴 의심 / No(custom 정의)면 디자인 시스템으로 인정

정량 지표는 **AI default 의존도**를 측정하는 것이지, 다양성 자체를 측정하는 것이 아니다.

---

## 1. Color Palette

### AI Patterns
- **Indigo/Violet gradient convergence** (AI Purple Problem): Tailwind `indigo-500` (#6366f1) ~ `violet-500` (#8b5cf6) 스펙트럼이 LLM 학습 데이터에 과대 표집됨
- Blue-to-purple diagonal/radial gradient가 hero 배경의 기본값으로 수렴
- 과채도 neon accent (bright cyan #06b6d4, magenta #ec4899)
- Monochromatic gray + single vibrant accent (보통 blue/purple)
- Dark mode에서 neon-on-black 조합 남용

### Detection — Color Theory Lens

**60-30-10 Rule 위반 체크**:
- 60% dominant + 30% secondary + 10% accent 비중을 따르는가?
- AI는 비중을 아예 무시하거나(gradient가 전면), 비중은 맞지만 Tailwind default로 채움
- dominant이 gradient 하나에 의존하면 비중 구조 자체가 없는 것

**Color Harmony 분석**:
- AI는 거의 항상 **analogous(유사색: blue-indigo-violet)** 에만 수렴
- Complementary(보색), split-complementary(분할보색), triadic(삼색) 조합을 쓰면 AI 가능성 낮음
- 색상환에서 hue가 60° 이내에 모여있으면 analogous 편향 의심

**Color Temperature**:
- AI = cool tone 편향 (blue-purple-gray). Warm tone(amber, terracotta, coral) 거의 부재
- 의도적 디자인은 warm/cool 밸런스가 있거나, 한쪽을 선택한 맥락적 근거가 있음
- warm/cool 비율 체크: warm hue(0°-60°, 300°-360°) vs cool hue(120°-240°)

**Semantic Color Depth**:
- 색이 **의미**를 담고 있는가? (status, hierarchy, category 구분)
- AI: 색이 순수 장식적(decorative) — 정보를 전달하지 않음
- 좋은 디자인: success/warning/error, 카테고리 구분, 정보 계층에 색이 사용됨

### Detection — Code
- Tailwind: `bg-indigo`, `bg-violet`, `bg-purple`, `from-indigo`, `to-purple`, `from-blue`, `to-violet`
- Hex 범위: #6366f1–#8b5cf6 (indigo-violet), #3b82f6 (blue-500)
- CSS gradient에 indigo/violet/purple endpoint
- **Quantitative**: 사용된 색상의 hue 분포가 220°-280° (blue-violet) 범위에 70%+ 집중

### Detection — Visual
- Hero 섹션에 보라/남색 지배적
- 배경이 blue-to-purple gradient
- Dark 배경 위 neon accent
- 60-30-10 비중이 불명확하거나 gradient가 전면을 덮음

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 브랜드 고유 팔레트, purple/indigo 지배 없음 |
| 1 | 일부 indigo/blue 존재하나 브랜드로 정당화 |
| 2 | 주요 영역에 기본값 느낌의 purple/blue gradient |
| 3 | Indigo-violet gradient가 사실상 시각 아이덴티티 |

---

## 2. Typography

### AI Patterns
- **제네릭 폰트 스택**: Inter, Roboto, Poppins, DM Sans — AI가 수렴하는 "안전한" sans-serif
- 균일한 font-size 계단 (모든 heading이 비슷한 크기)
- Letter-spacing/line-height 조정 없이 기본값 그대로
- Serif/display/handwritten 서체 부재 — 전부 geometric sans
- 텍스트 계층 구조 부재 (모든 텍스트가 비슷한 시각적 무게)

### Detection — Code
- `font-family` 또는 `fontFamily`에 Inter, Roboto, Poppins, DM Sans
- Tailwind: `font-sans` 만 사용, custom font 미정의
- Google Fonts import에 generic 폰트만
- **Quantitative**: font-size 비율이 Major Third(1.25) 또는 Perfect Fourth(1.333)에 정확 매칭 → AI 기본 scale 사용 의심

### Detection — Visual
- 전체 페이지가 하나의 sans-serif로 통일
- Heading과 body의 시각적 차이 미미
- 개성 없는 중립적 서체 느낌

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 브랜드 서체 또는 개성 있는 조합, 명확한 계층 |
| 1 | Generic 폰트이나 weight/size 변주로 계층 확보 |
| 2 | Inter/Roboto 단일 사용, 계층 구조 약함 |
| 3 | 기본 sans-serif, 계층 없음, 서체 선택에 의도 부재 |

---

## 3. Surface Treatment

### AI Patterns
- **과도한 smoothness**: 노이즈/grain/texture 전무한 매끈한 surface
- Chrome-like 3D 오브젝트 (비현실적 반사)
- 순수 white/black drop shadow (컬러 shadow 부재)
- Flat color fill만 사용 — 물리적 질감감 없음
- 카드/컨테이너가 모두 동일한 border-radius + shadow 조합

### Detection — Code
- `background` 속성에 texture/pattern/noise 없음
- 모든 shadow가 `rgba(0,0,0,...)` 형태
- `border-radius` 값이 전부 동일 (보통 `rounded-xl` 또는 `rounded-2xl`)

### Detection — Visual
- 배경이 순수 solid color 또는 smooth gradient만
- 카드/섹션에 물리적 질감 전무
- "플라스틱" 또는 "렌더링" 느낌

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | Texture/grain/패턴 활용, 다양한 surface 처리 |
| 1 | 대부분 flat이나 일부 영역에 질감 존재 |
| 2 | 전체적으로 매끈, texture 거의 없음 |
| 3 | 완전한 smoothness, 물리적 질감감 제로 |

---

## 4. Imagery

### AI Patterns
- **Glowing orb/sphere**: 빛나는 구체가 장식 요소로 등장
- Circuit/network 그래픽, 노드 연결 다이어그램
- Chrome face/hand — 비현실적 메탈릭 인체 표현
- 스톡 사진 느낌: 과도하게 완벽한 조명, 비현실적 피부
- AI 생성 일러스트의 "too perfect" 느낌 (비대칭/imperfection 부재)
- Abstract wave/blob이 유일한 비주얼 요소

### Detection — Visual
- Hero에 glowing orb, abstract mesh, 또는 AI 생성 이미지
- 인물 사진의 비현실적 완벽함
- 아이콘/일러스트가 모두 같은 스타일 라이브러리에서 온 느낌
- 장식 요소가 gradient blob/circle뿐

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 커스텀 사진/일러스트, 브랜드 고유 비주얼 |
| 1 | 일부 generic 요소 있으나 커스텀 콘텐츠가 주도 |
| 2 | 스톡/AI 생성 이미지가 주도, 장식은 blob/gradient |
| 3 | Glowing orb + chrome + abstract mesh 조합, 고유 비주얼 전무 |

---

## 5. Layout Regularity

### AI Patterns
- **Default Layout Syndrome**: 도구 불문 동일 구조 생성 — Hero → 3-column features → testimonials → pricing → CTA. 이 순서 자체가 detection signal
- **완벽한 대칭**: 모든 섹션이 좌우 대칭, 비대칭 레이아웃 부재
- 3-column icon grid 반복 (feature 섹션의 클리셰)
- **Bento grid 남용**: 2024-2025 트렌드였던 bento box가 AI 기본 출력으로 고착화
- 모든 카드가 동일 크기/간격
- **Spacing 기계적 균일성**: 모든 섹션 간 간격이 동일, 카드 내부 padding도 획일적. vertical rhythm이 "너무 완벽"하면 오히려 의심
- **Asymmetric zigzag**: feature 섹션에서 이미지-텍스트 좌우 교대 반복
- Social proof 공식: 로고 배너 → 숫자 통계 3개 → testimonial 카드 3장

### Detection — Code
- `grid-cols-3` 또는 3-column flex가 반복
- 모든 섹션에 동일한 `py-`, `px-` 패딩
- 카드 컴포넌트가 하나의 템플릿으로 N회 반복
- **Quantitative**: unique padding/margin 값이 2-3개뿐 → spacing 단조로움
- **Tech stack signal**: Next.js + Tailwind + Shadcn/ui + Lucide + Radix 풀세트 → AI builder 사용 강력 의심

### Detection — Visual
- 스크롤 시 "같은 구조의 반복" 느낌
- Feature 섹션이 아이콘 + 제목 + 설명 × 3 grid
- 시각적 리듬감 없이 균일한 간격
- 섹션 순서가 "SaaS landing page template"과 정확히 일치

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 의도적 비대칭, 다양한 레이아웃 구조, 리듬감 |
| 1 | 기본 grid이나 섹션별 변화 존재 |
| 2 | 대부분 균일 grid, 변화 적음 |
| 3 | 전체가 동일 패턴 반복, 시각적 단조로움 |

---

## 6. Visual Effects

### AI Patterns
- **Glassmorphism 남용**: `backdrop-blur` + 반투명 배경이 모든 카드에 적용
- Excessive glow/bloom: `shadow-[0_0_30px_rgba(...)]` 스타일의 과한 발광
- Gradient border (border에 gradient 적용)
- Float animation — 의미 없이 떠다니는 장식 요소
- 과도한 `blur-` 배경 효과
- Parallax/scroll animation 과다

### Detection — Code
- `backdrop-blur`, `backdrop-filter: blur`
- `box-shadow`에 큰 spread + 컬러 값 (glow 효과)
- `bg-opacity-`, `bg-white/10` 등 반투명 패턴
- `animate-float`, `animate-bounce` 등 장식 애니메이션

### Detection — Visual
- 카드/모달이 frosted glass 효과
- 요소 주변에 과한 glow/bloom
- 배경 요소가 blur 처리된 gradient blob

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 효과 절제적, 기능적 목적에 한정 |
| 1 | 일부 glassmorphism/glow이나 제한적 사용 |
| 2 | 대부분의 카드/컨테이너에 glass/glow 적용 |
| 3 | Glass + glow + blur + float의 과잉, "SaaS template" 느낌 |

---

## 7. Brand Identity

### AI Patterns
- **Generic "SaaS landing page" 느낌**: 어떤 회사에나 붙일 수 있는 디자인
- 로고/브랜드명만 바꾸면 다른 서비스가 되는 수준
- 문화적/산업적 맥락 반영 없음
- 카피가 generic ("Supercharge your workflow", "Built for teams")
- 차별화 요소 부재 — 경쟁사 사이트와 교환 가능

### Detection — Visual
- "이 사이트가 무엇을 하는 회사인지" 로고 없이 알 수 없음
- 톤/무드가 업종과 무관한 "tech startup" 기본값
- 사진/일러스트에 브랜드 스토리 반영 없음

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 강한 브랜드 아이덴티티, 로고 없이도 인식 가능 |
| 1 | 브랜드 요소 존재하나 generic 기반 위에 얹은 수준 |
| 2 | 로고/브랜드명 외 차별화 요소 약함 |
| 3 | 완전한 generic, 교환 가능한 "SaaS template" |

---

## 8. Copy & Content

### AI Patterns
- **AI slop copy**: "Supercharge your workflow", "Revolutionize your process", "Built for teams that move fast" — AI가 생성하는 과장된 동사와 모호한 타겟팅
- **기능 대신 약속**: 실제 기능 설명 없이 "Save 10x more time" 식의 공허한 benefit 나열
- **CTA 획일화**: "Get Started Free", "Start Your Journey", "Join 10,000+ teams"
- **Hero 공식**: 거대 헤드라인 + 서브텍스트 + 2개 CTA 버튼(primary/ghost)
- **Pricing 페이지 3-column**: Good/Better/Best ("Starter/Pro/Enterprise") 구조의 무비판적 복제
- **Empty state 무시**: "완성된 상태"의 UI만 존재, 빈 상태/에러 상태/로딩 상태 미고려

### Detection — Content
- Hero에 "revolutionize", "transform", "unleash", "supercharge" 등 과장 동사
- 제품이 실제로 무엇을 하는지 3초 내 파악 불가
- 모든 feature 카드 설명이 benefit-only (기능 미설명)
- CTA가 전부 "Get Started" 변형

### Detection — Visual
- Pricing table이 정확히 3열
- Empty state 화면 부재
- 에러/로딩 상태의 디자인이 없거나 기본값

### Scoring
| 점수 | 기준 |
|------|------|
| 0 | 구체적 가치 제안, 브랜드 voice, 실제 기능 설명 |
| 1 | 일부 generic copy이나 제품 설명은 구체적 |
| 2 | 대부분 AI slop copy, CTA 획일적, 기능 모호 |
| 3 | 전체 카피가 교환 가능한 generic, empty state 부재 |

---

## Overall Grade

| 총점 (/ 24) | 등급 | 의미 |
|-------------|------|------|
| 0–4 | **Authentic** | AI 심미적 패턴 최소, 고유한 아이덴티티 |
| 5–10 | **Mixed** | 일부 AI 패턴 존재, 부분 개선 권장 |
| 11–17 | **AI-Adjacent** | 상당한 AI 심미적 영향, 우선 개선 필요 |
| 18–24 | **AI-Saturated** | 강한 AI 생성 느낌, 전면 재검토 권장 |
