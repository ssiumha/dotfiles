# 메타 하네스 — 스킬 자기 갱신 프로토콜

이 스킬 자체가 하네스다. 프로젝트 하네스에 Gardening이 필요하듯, 이 스킬도 정기적으로 점검하고 갱신한다.

## 진화 체인

하네스 엔지니어링은 4년간 단계적으로 진화했다. 각 단계는 이전을 대체하지 않고 **통합**한다.

```
2022  Prompt Engineering     — 단일 프롬프트 최적화
2024  Context Engineering    — 선택·압축·배치·격리·형식
2025  Harness Engineering    — 환경 자체를 설계 (rules, hooks, agents)
2026  Meta-Harness           — 에이전트가 하네스를 자기 생성·수정
```

### Universal Agent → HyperAgent

| 단계 | 에이전트의 위상 | 하네스와의 관계 |
|------|----------------|----------------|
| **Universal Agent** | 인프라의 소비자 | 하네스 안에서 실행, 사람이 설계 |
| **HyperAgent** | 인프라의 생산자 | 하네스를 스스로 엔지니어링 |

Meta의 HyperAgents(2026) 연구에서 에이전트가 자기 개선을 반복하면 **개발자가 수작업으로 만들던 하네스 구성요소를 자동으로 재발명**하는 현상이 관측되었다:

| 자기생성 구성요소 | 하네스 대응물 | 설명 |
|-------------------|-------------|------|
| 영속 메모리 | MEMORY.md + memory files | 과거 결과 기억, 인과 가설 저장, 성공 전략 조합 |
| 성능 추적 | Audit 점수 + gardening | 이동 평균, 세대별 통계, 도메인별 이력 |
| 다단계 평가 파이프라인 | Enforcement hooks + linters | 체크리스트, 의사결정 규칙, 명확한 기준 |
| 임계값 의사결정 프로토콜 | Rules + pre-commit gates | 수락/거부 비율, 점수 임계값, 신뢰도 수준 |
| 도메인 지식 베이스 | docs/ + ARCHITECTURE.md | 환경 제약, 유효 상태 변수, 휴리스틱 |
| 재시도 자기교정 | Feedback loop + reflect | 회귀 진단, 교정 루프 |

### 설계 원칙: 초기 조건의 설계

```
기존: 개발자가 하네스를 직접 구축
전환: 에이전트가 효과적 하네스를 진화시킬 수 있는 "초기 조건"을 설계
```

개발자의 역할은 사라지지 않고 **전환**된다:
- ~~구체적 구현~~ → **설계 영역** (어떤 메트릭을 추적할지, 어떤 불변식을 강제할지)
- 에이전트의 자기 개선 제안을 **검토·승인**하는 감독자 역할

### 실천 적용

이 스킬에서 메타-하네스를 실천하는 방법:

1. **자기 생성 관찰** — 워크플로우 실행 중 에이전트가 명시되지 않은 패턴을 발명하면 기록
2. **피드백 환류** — 에이전트의 개선 제안 → 사용자 검토 → 스킬/리소스 갱신
3. **수렴 검증** — 에이전트가 독립적으로 도달한 구조가 기존 하네스와 일치하면, 해당 구성요소의 필연성 신호
4. **"남의 harness 복사 말고 자기 상황에 체화"** — 외부 스킬/패턴은 참조하되, 에이전트와 대화하며 프로젝트 맥락에 맞게 재구성

## 소스 카탈로그

마지막 확인: 2026-04-13

### Tier 1: Anthropic 공식 (월 1회 확인)

| 소스 | URL | 영향 리소스 |
|------|-----|-------------|
| Subagents docs | https://code.claude.com/docs/en/sub-agents | 09 (스키마) |
| Agent Teams docs | https://code.claude.com/docs/en/agent-teams | 08 (팀 패턴) |
| Hooks docs | https://docs.anthropic.com/en/docs/claude-code/hooks | SKILL.md (Enforcement) |
| Effective Harnesses | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents | 02 (context eng) |
| Context Engineering | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | 02 |
| Harness Design Apps | https://www.anthropic.com/engineering/harness-design-long-running-apps | 08 (GAN-style) |
| Subagents Blog | https://claude.com/blog/subagents-in-claude-code | 08, 09 |

### Tier 2: 커뮤니티 (분기 1회 확인)

| 소스 | URL | 관심 포인트 |
|------|-----|-------------|
| revfactory/harness | https://github.com/revfactory/harness | 메타에이전트 파이프라인 변경 |
| Citadel | https://github.com/SethGammon/Citadel | 라우팅, campaign persistence |
| AGENTS.md spec | https://agents.md/ | 크로스도구 표준 변경 |
| HumanLayer blog | https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents | 실전 패턴 |
| Addy Osmani agent-skills | https://github.com/addyosmani/agent-skills | 20개 구조화 스킬, 개발 생명주기 커버 |
| Addy Osmani — Code Agent Orchestra | https://addyosmani.com/blog/code-agent-orchestra/ | 병목이 생성→검증으로 이동, 비동기 멀티에이전트 |

### Tier 3: 학술/심층 (분기 1회)

| 소스 | URL | 관심 포인트 |
|------|-----|-------------|
| Codified Context | https://arxiv.org/html/2602.20478v1 | 에이전트 인프라 이론 |
| Multi-Agent Context Eng | https://arxiv.org/html/2508.08322v1 | 멀티에이전트 컨텍스트 |
| Meta HyperAgents (DGM-H) | https://arxiv.org/abs/2603.19461 | 자기참조적 에이전트, 하네스 자기생성, 수렴적 아키텍처 |

## 리소스별 신선도 검증 기준

| 리소스 | 검증 방법 | 드리프트 신호 |
|--------|-----------|--------------|
| 01 (audit checklist) | 감사 실행 시 누락 차원 발견 | 새 하네스 구성 요소가 체크리스트에 없음 |
| 02 (context eng) | Anthropic 공식 블로그 대조 | 새 컨텍스트 패턴, 용어 변경 |
| 03 (references) | URL 접근 가능성 + 내용 변경 | 404, 내용 대폭 변경 |
| 04 (architecture guide) | 실전 적용 피드백 | 가이드대로 했는데 부족한 부분 |
| 05 (doc gardening template) | 프로젝트 gardening 실행 피드백 | 점검 항목 누락 |
| 06 (arch test tools) | 도구 생태계 변경 | 새 도구 등장, 기존 도구 deprecated |
| 07 (invariant taxonomy) | 실전 불변식 발견 | 분류에 없는 유형 발견 |
| 08 (agent team patterns) | Agent Teams 실험 상태 변경 | GA 전환, 새 기능, API 변경 |
| 09 (agent template schema) | 공식 docs frontmatter 필드 대조 | 새 필드 추가, 기존 필드 변경 |
| 10 (meta-harness) | 소스 카탈로그 URL 접근 + 변경 이력 갱신 주기 | 마지막 확인 30일+ 경과, 소스 404, 새 Tier 1 소스 미등록 |

## 갱신 프로토콜

### 1. 정기 점검 (트리거: 사용자 요청 또는 월 1회)

```
1. Tier 1 소스 WebFetch → 변경 감지
2. 변경 있으면:
   a. /tmp/harness-research/ 에 새 버전 저장
   b. 기존 리소스와 diff
   c. 영향받는 리소스 갱신
   d. SKILL.md cross-reference 확인
3. 변경 이력 기록 (아래 섹션)
```

### 2. 실전 피드백 환류 (트리거: 하네스 구축/감사 완료 후)

```
1. 워크플로우 1-6 실행 중 발견한 것:
   - 워크플로우가 모호했던 부분 → SKILL.md 보강
   - 리소스에 없는 패턴 → 해당 리소스 추가
   - 안 먹히는 패턴 → 안티패턴으로 승격
2. 사용자에게 "스킬에 반영할까요?" 확인
3. 반영 후 변경 이력 기록
```

### 3. 웹서치 갱신 (트리거: 주요 기능 변경 감지 또는 분기 1회)

검색 쿼리 세트:
```
"Claude Code" harness engineering 2026
"Claude Code" agents subagents new features
site:docs.anthropic.com claude code changelog
site:anthropic.com/engineering harness OR agent
"CLAUDE.md" best practices new
```

절차:
```
1. Agent로 웹서치 실행 (읽기 전용)
2. 새 소스 발견 → 소스 카탈로그에 추가
3. 기존 소스 내용 변경 → 영향 리소스 갱신
4. /tmp/harness-research/ 에 저장 (다음 갱신 시 diff 기준)
```

## 변경 이력

| 날짜 | 트리거 | 변경 내용 |
|------|--------|-----------|
| 2026-04-09 | 초기 구축 | 웹서치 10개 소스 → 09 신규, 08 업데이트, SKILL.md 워크플로우 6 추가 |
| 2026-04-13 | GeekNews Weekly #353 + HyperAgents | 진화 체인 프레임워크 추가, HyperAgents 자기생성 6요소 매핑, 소스 카탈로그에 4개 추가, 08에 Advisor 패턴 추가, GAN-style 업데이트 |
