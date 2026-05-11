# Harness Engineering 참고 자료

조사 출처와 핵심 인사이트 정리.

## OpenAI

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Harness Engineering: Leveraging Codex in an Agent-First World](https://openai.com/index/harness-engineering/) | 5개월간 수작업 코드 0줄로 제품 출시. AGENTS.md는 목차(~100줄), docs/가 기록 시스템. 린트 에러 = 에이전트 수정 지침. 가비지 컬렉션 패턴으로 엔트로피 관리. "에이전트가 접근 못 하면 없는 것" |

### 에이전트 런타임 환경 (감사/제안 대상)

하네스 감사 시 다음 영역도 점검하고 개선을 제안할 수 있다:

| 영역 | 감사 질문 | 개선 제안 |
|------|-----------|-----------|
| **worktree별 앱 실행** | 에이전트가 변경사항을 격리된 환경에서 직접 실행/검증할 수 있는가? | worktree별 앱 부팅 스크립트, 랜덤 포트 격리 |
| **UI 검증** | 에이전트가 UI 변경을 직접 확인할 수 있는가? | Chrome DevTools Protocol 연결, DOM 스냅샷/스크린샷 skill |
| **관측 가능성** | 에이전트가 로그/메트릭/트레이스를 쿼리할 수 있는가? | worktree별 관측 스택, LogQL/PromQL 접근 |
| **에이전트 간 리뷰** | PR 리뷰가 사람 병목인가? | 에이전트 리뷰어 설정, 피드백 루프 자동화 |
| **취향 불변성** | 팀의 코딩 취향이 기계적으로 강제되는가? | 커스텀 린트로 네이밍/로깅/파일 크기 등 정적 적용 |
| **경계 파싱** | 데이터를 추측하여 처리하는 코드가 있는가? | 경계에서 스키마/SDK로 파싱. YOLO style 방지 |

## Anthropic 공식

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Initializer + Coding Agent 2단계 아키텍처. JSON feature list가 Markdown보다 모델의 부적절한 수정에 강함 |
| [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices) | CLAUDE.md에 에이전트가 추측 불가한 것만 포함. 코드에서 유추 가능한 것은 제외 |
| [Automate Workflows with Hooks](https://code.claude.com/docs/en/hooks-guide) | Exit 0=침묵, Exit 2=에러만 표면화. Stop hook으로 빌드 검증 |
| [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | 실패 사례 20-50개로 eval set. 결과 기준 채점, 솔루션 경로가 아닌 |

## 외부 엔지니어링 블로그

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Martin Fowler — Context Engineering for Coding Agents](https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html) | 자기 개선 루프: 에이전트가 하네스 개선을 추천하고 사람이 검토 |
| [Phil Schmid — Agent Harness 2026](https://www.philschmid.de/agent-harness-2026) | Model=CPU, Context=RAM, Harness=OS 비유. 동일 모델이 하네스에 따라 78% vs 42% |
| [LangChain — Improving Deep Agents with Harness Engineering](https://blog.langchain.com/improving-deep-agents-with-harness-engineering) | 하네스만 변경하여 52.8%→66.5% 성능 향상 (Terminal Bench 2.0) |
| [HumanLayer — Skill Issue: Harness Engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | 60줄 미만 CLAUDE.md. MCP 서버를 CLI로 래핑하여 토큰 절약 |
| [HumanLayer — Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) | "제거해도 실수 안 하면 삭제". /init 자동생성은 20%+ 토큰 낭비 |
| [Spotify — Context Engineering: Background Coding Agents Part 2](https://engineering.atspotify.com/2025/11/context-engineering-background-coding-agents-part-2) | 도구를 확장하는 대신 전략적으로 제한. push 금지, allowlist 기반 Bash |
| [MIT Missing Semester 2026 — Agentic Coding](https://missing.csail.mit.edu/2026/agentic-coding/) | Level 1/2/3 하네스 성숙도 모델. 실패 기반 반복적 구축 |

## 안티패턴 관련

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Lint Against the Machine — AI Coding Agent Anti-Patterns](https://medium.com/@montes.makes/lint-against-the-machine-a-field-guide-to-catching-ai-coding-agent-anti-patterns-3c4ef7baeb9e) | AI 생성 코드의 copy/paste 8.3%→12.3% 증가, 리팩토링 25%→10% 감소 |
| [NxCode — Harness Engineering Complete Guide](https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026) | Kitchen Sink 세션, 사전 최적화, 기능적 서브에이전트 분리는 작동하지 않음 |
| [revfactory/harness — Claude Code Agent Team Plugin](https://github.com/revfactory/harness) | 6개 에이전트 팀 아키텍처 패턴(Pipeline, Fan-out, Expert Pool, Producer-Reviewer, Supervisor, Hierarchical). Skill = "How to do" vs Agent = "Who does" 구분. 트리거 검증 + 드라이런 방법론 |

## 메타 하네스 / 에이전트 진화

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Meta — HyperAgents (arXiv 2603.19461)](https://arxiv.org/abs/2603.19461) | 자기참조적 에이전트(DGM-H): Task Agent + Meta Agent가 단일 편집 가능 프로그램. 자기 개선 반복 시 영속 메모리, 성능 추적, 검증 파이프라인 등 하네스 구성요소를 **자동 재발명**. "하네스는 수렴적 아키텍처" |
| [Addy Osmani — The Code Agent Orchestra](https://addyosmani.com/blog/code-agent-orchestra/) | 동기식 단일→비동기 다중 에이전트 전환. 병목이 코드 생성→**검증(Verification)**으로 이동. 3 focused agents > 1 generalist 3x longer |
| [Addy Osmani — agent-skills](https://github.com/addyosmani/agent-skills) | 20개 구조화 스킬. `/spec→/plan→/build→/test→/review→/ship` 생명주기. "AI 에이전트는 최단 경로를 택한다 — 스펙·테스트·보안 리뷰를 건너뛰지 못하게 구조화" |
| [Sebastian Raschka — Components of A Coding Agent](https://magazine.sebastianraschka.com/p/components-of-a-coding-agent) | 코딩 에이전트 6대 구성요소: 리포 컨텍스트, 프롬프트 캐시, 도구 접근, 세션 메모리, 서브에이전트 위임, 장기 세션 연속성 |
| [Anthropic — Advisor Strategy](https://docs.anthropic.com/en/docs/build-with-claude/advisor-strategy) | Opus=조언자, Sonnet=실행자. 비용 85%↓ 성능 2x+. 공식 도입 패턴 |

## 아키텍처 테스트 / 의존 방향

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) | Dependency Rule의 원전. "소스 코드 의존성은 안쪽으로만" |
| [DIP in the Wild (Martin Fowler)](https://martinfowler.com/articles/dipInTheWild.html) | "인터페이스 = 추상화"가 아닌 이유. 도메인 관점의 추상화로 의존 방향 조정 |
| [ArchUnit — Why test your architecture?](https://www.archunit.org/motivation) | "모든 것이 모든 것에 의존하게 되는" 문제를 자동화로 방지 |
| [import-linter Contract Types](https://import-linter.readthedocs.io/en/stable/contract_types.html) | layers/independence/forbidden 3가지 계약 유형 |
| [eslint-plugin-boundaries](https://github.com/javierbrea/eslint-plugin-boundaries) | JS/TS 요소 타입 정의 + 의존 규칙 설정 |
| [6 ways to improve architecture with import-linter](https://www.piglei.com/articles/en-6-ways-to-improve-the-arch-of-you-py-project/) | Python 프로젝트에서 import-linter로 아키텍처 개선하는 실전 가이드 |

## ARCHITECTURE.md 작성론

| 출처 | 핵심 인사이트 |
|------|---------------|
| [matklad — ARCHITECTURE.md](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html) | "어디를 수정할지 = 10배 비용". Codemap = 나라 지도, 아틀라스가 아님. 불변식은 absences로 표현. 검색 가능한 심볼 이름으로 참조. rust-analyzer architecture.md가 모범 사례 |

## 에이전트 / 서브에이전트 (2026-04-09 추가)

| 출처 | 핵심 인사이트 |
|------|---------------|
| [Anthropic — Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) | GAN 영감 3에이전트(Planner/Generator/Evaluator). 자기 평가 편향 → 생성자/평가자 분리 필수. Context anxiety(컨텍스트 한계 근접 시 조기 종료). "모델이 좋아져도 하네스 복잡성은 줄지 않고 이동한다" |
| [Anthropic — Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | "Right altitude" 원칙 — 시스템 프롬프트는 너무 구체적이지도 모호하지도 않게. Context rot(토큰↑ → recall↓). Sub-agent → condensed summary 반환 |
| [Claude Code Subagents Docs](https://code.claude.com/docs/en/sub-agents) | 14개 frontmatter 필드. Scope 5단계(Managed > CLI > Project > User > Plugin). Memory 3단계. Agent(child) 스폰 제한 |
| [Claude Code Agent Teams Docs](https://code.claude.com/docs/en/agent-teams) | 실험적. Mailbox(peer-to-peer + broadcast). TeammateIdle/TaskCreated/TaskCompleted Hook. 서브에이전트 정의를 teammate로 재사용 가능(단, skills/mcpServers 무시) |
| [Anthropic Blog — Subagents in Claude Code](https://claude.com/blog/subagents-in-claude-code) | "10+ 파일 또는 3+ 독립 조각" → 서브에이전트 위임 기준선. 서브에이전트 부적합: 순차 의존, 같은 파일 수정, 에이전트 간 협업 필요 |
| [Citadel — Agent Orchestration Harness](https://github.com/SethGammon/Citadel) | 4-tier 라우팅(Pattern match → Session → Keyword → LLM). Campaign persistence. Circuit breaker. "CLAUDE.md는 문서, 하네스는 인프라" |
| [AGENTS.md spec](https://agents.md/) | 크로스 도구 에이전트 지시 포맷. 6만+ 리포 채택. Linux Foundation |
| [ETH Zurich — Agentfiles study (via HumanLayer)](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | LLM 자동생성 CLAUDE.md는 20%+ 토큰 추가 소비, 성능 향상 없음. 수작업 ~4% 향상 |
| [revfactory/harness-100](https://github.com/revfactory/harness-100) | 10 도메인 100 하네스. A/B 테스트: 하네스 +60% 품질, 100% 승률. 복잡할수록 효과 큼(Basic +23.8, Advanced +29.6, Expert +36.2) |
