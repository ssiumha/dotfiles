---
name: team-setup
description: Sets up Claude Code agent teams with role-based composition. Use when creating dev teams, defining team roles, or organizing multi-agent collaboration. Do NOT use for single sub-agent creation (use agent-creator instead).
---

# Team Setup

분할정복 원칙에 따라 팀을 구성하고 운영한다.

## 핵심 철학

- **이해 → 계획 → 분할 → 정복**: CLAUDE.md 대원칙을 팀 단위로 확장
- **TaskList가 source of truth**: 빌트인 TaskCreate/TaskList/TaskUpdate로 관리
- **기존 agents 활용**: code-explorer, code-reviewer 등 이미 정의된 agent 우선 사용
- **필요한 만큼만**: 팀원 수 = 토큰 비용. 필요할 때만 스폰

## 팀 구조

```
Lead (나)
├── 기존 agents (subagent로 활용)
│   ├── code-explorer — 탐색, 구조 분석
│   ├── code-reviewer — 코드 리뷰
│   ├── spec-validator — 요구사항 검증
│   ├── test-verifier — 테스트 품질 검증
│   ├── tidy-commit — 커밋 정리
│   └── skill-suggester — 패턴 감지
│
└── 팀원 (team member로 스폰)
    └── 태스크에 따라 필요한 역할만
```

**기존 agents는 subagent로** — 결과만 필요한 단발 작업.
**팀원은 team member로** — 독립적 구현이 필요한 복합 작업.

## Instructions

### 워크플로우 1: 팀 생성

#### 1. 이해

- 프로젝트 CLAUDE.md, 기술 스택, 디렉토리 구조 파악
- 사용자 요구사항의 범위와 복잡도 판단

#### 2. 계획

작업을 분석하고 **TaskCreate로 계획을 수립**한다:

```
TaskCreate: "API 인증 모듈 구현"
TaskCreate: "프론트엔드 로그인 폼 구현"
TaskCreate: "통합 테스트 작성"
```

각 task에 의존성을 설정한다 (TaskUpdate의 addBlockedBy).

#### 3. 팀 생성 및 할당

```
TeamCreate:
  team_name: {project}-dev
  description: {프로젝트명} 개발

Task(subagent_type={role}, name={role}, team_name={project}-dev):
  prompt: "담당 태스크: #{ID} {제목}.
           작업 범위: {파일/모듈}.
           완료 기준: {검증 방법}.
           TaskList를 확인하고 작업을 시작하세요."
```

**스폰 기준**: TaskList에 해당 역할의 태스크가 있을 때만.

#### 4. 진행 관리

- 팀원은 작업 시작 시 `TaskUpdate(status: in_progress)`
- 완료 시 `TaskUpdate(status: completed)` 후 TaskList에서 다음 작업 확인
- Lead는 TaskList로 전체 진행 상황 파악

### 워크플로우 2: 태스크 위임

팀원에게 태스크를 넘길 때:

1. **탐색**: code-explorer subagent로 관련 코드 사전 조사
2. **범위 명시**: 대상 파일, 완료 기준을 구체적으로 전달
3. **스폰**: 팀원에게 태스크 + 범위 + 완료 기준 전달

```
# 사전 조사
Task(subagent_type=code-explorer):
  prompt: "{모듈} 관련 파일과 의존성 분석. 파일경로:라인 형식으로 요약."

# 팀원 스폰
Task(subagent_type={role}, name={name}, team_name={project}-dev):
  prompt: "태스크: {제목}
           대상: {파일 목록}
           완료 기준: {구체적 조건}
           TaskList를 확인하고 시작하세요."
```

### 워크플로우 3: 팀 종료

1. TaskList에서 모든 태스크 completed 확인
2. code-reviewer subagent로 최종 리뷰
3. 각 팀원에게 shutdown_request
4. TeamDelete

## 에이전트 정의 패턴

팀원용 agent가 필요하면 `.claude/agents/{role}.md`에 정의:

```yaml
---
name: {role}
description: {역할 설명}
model: sonnet
memory: local
---

{역할의 핵심 책임과 작업 방식}
```

## 중요 원칙

1. **계획 먼저**: TaskCreate로 계획을 세운 뒤 팀원 스폰
2. **기존 agents 우선**: 탐색/리뷰/검증은 이미 있는 subagent 활용
3. **SRP/OCP로 조합**: 팀원 하나에 책임 하나. 새 능력이 필요하면 새 agent를 만들어 조합한다 (상세: /agent-creator)
4. **독립적 작업**: 팀원 간 파일 충돌 방지. 각자 다른 파일/모듈 담당
5. **비용 의식**: 필요한 만큼만 스폰, idle 팀원은 shutdown
