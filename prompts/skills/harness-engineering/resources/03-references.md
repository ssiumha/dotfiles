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
