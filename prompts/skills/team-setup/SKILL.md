---
name: team-setup
description: Sets up Claude Code agent teams with role-based composition and PM task management. Use when creating dev teams, defining team roles, setting up task tracking with backlog.md, or organizing multi-agent collaboration. Do NOT use for single sub-agent creation (use agent-creator instead).
---

# Team Setup

Claude Code Agent Teams를 활용한 개발팀 구성과 PM 기반 태스크 관리 체계.

## 핵심 철학

- **점진적 구성**: 코어 팀(Lead + PM) 먼저 → 태스크에 따라 확장
- **PM 태스크 소유**: PM이 backlog.md로 태스크를 단일 관리 (외부 도구 불필요)
- **역할 분리**: Lead는 기술 판단, PM은 진행 관리, 나머지는 실행
- **세션 간 연속성**: `memory: local`로 에이전트 컨텍스트 자동 유지

## Agent Teams vs Subagents

| | Subagents | Agent Teams |
|---|---|---|
| 컨텍스트 | 결과만 반환 | 독립 세션, 상호 메시징 |
| 조율 | 메인이 전부 관리 | 공유 태스크 리스트로 자기 조율 |
| 적합 | 탐색, 검증 등 단발 작업 | 협업이 필요한 복합 작업 |
| 토큰 | 낮음 | 높음 (팀원별 별도 세션) |

**기준**: 팀원 간 소통이 필요하면 Agent Teams, 결과만 필요하면 Subagents.

## 사전 조건

이 skill의 `subagent_type` 값(`lead`, `pm`, `backend-dev` 등)은 **예시**입니다.
실제 사용 시 `.claude/agents/{role}.md` 파일을 먼저 정의해야 합니다 (하단 "에이전트 정의 패턴" 참조).

## Instructions

### 워크플로우 1: 팀 생성 (초기 구성)

프로젝트에 개발팀이 필요할 때 실행.

#### 1. 프로젝트 분석

- CLAUDE.md 확인 (기술 스택, 디렉토리 구조)
- 현재 백로그/태스크 파악
- 기존 에이전트 정의 확인 (`.claude/agents/`)

#### 2. 코어 팀 생성

**항상 코어 팀부터 시작**. 전체 팀을 한 번에 스폰하지 않는다.

```
TeamCreate:
  team_name: {project}-dev
  description: {프로젝트명} 개발
  agent_type: lead
```

코어 팀원 (병렬 스폰):

| 역할 | subagent_type | 책임 |
|------|---------------|------|
| **lead** | `lead` | 기술 의사결정, 아키텍처, 코드 리뷰 |
| **pm** | `pm` | 태스크 관리, 진행 추적, 우선순위 |

```
Task(subagent_type=lead, name=lead, team_name={project}-dev):
  prompt: "팀에 합류합니다. 메모리를 확인하고 보고하세요."

Task(subagent_type=pm, name=pm, team_name={project}-dev):
  prompt: "팀에 합류합니다. 메모리를 확인하고 보고하세요."
```

#### 3. PM에게 태스크 관리 위임

PM 합류 후 태스크 관리 체계를 확인:
- backlog.md가 있으면 → 현황 보고 요청
- backlog.md가 없으면 → 프로젝트 분석 후 초기 백로그 작성 요청

#### 4. 필요 시 확장

PM의 백로그 분석 결과에 따라 추가 팀원 스폰:

| 태스크 유형 | 스폰 역할 |
|------------|----------|
| 백엔드 API 구현 | `backend-dev` |
| 프론트엔드 UI | `frontend-dev` |
| 테스트 커버리지 | `test-engineer` |
| 인프라/배포 | `devops-engineer` |
| PR 리뷰 대기 | `pr-reviewer` |
| 보안 점검 | `security-engineer` |

**스폰 기준**: 백로그에 해당 유형 태스크가 존재할 때만. 미리 스폰하지 않는다.

### 워크플로우 2: PM 태스크 관리 체계

PM이 태스크의 단일 소유자. 외부 도구(orch 등) 없이 backlog.md로 관리.
**PM만 backlog.md를 편집**할 수 있다. 다른 에이전트/사용자는 PM에게 메시지로 요청만 가능.

#### 태스크 저장소

PM 메모리 디렉토리: `.claude/agent-memory-local/pm/`

| 파일 | 용도 |
|------|------|
| `MEMORY.md` | 현재 상태 요약 (시스템 프롬프트에 자동 주입, 200줄 이내) |
| `backlog.md` | 전체 태스크 목록 (유일한 소스 오브 트루스) |
| `milestones.md` | 마일스톤 및 일정 |
| `risks.md` | 리스크 레지스터 |
| `team-health.md` | 팀원 평가, 프로세스 개선 이력 |
| `archive/{YYYY-MM}.md` | 완료 태스크 아카이브 |

#### backlog.md 형식

```markdown
# Project Backlog

## P0 (긴급)
- [ ] #{PREFIX}-{순번} {제목} - 담당: {역할}, 상태: BACKLOG
  - 설명: {한 줄 설명}
  - 생성: {날짜}, 완료: -

## P1 (높음)
- [~] #{PREFIX}-{순번} {제목} - 담당: {역할}, 상태: IN_PROGRESS
  - 설명: {한 줄 설명}
  - 생성: {날짜}, 완료: -

## P2 (보통)
- [ ] #{PREFIX}-{순번} {제목}

## 완료
- [x] #{PREFIX}-{순번} {제목} - 완료: {날짜}
```

#### 태스크 상태

`BACKLOG` → `IN_PROGRESS` → `IN_REVIEW` → `DONE`

| 마커 | 상태 |
|------|------|
| `[ ]` | BACKLOG |
| `[~]` | IN_PROGRESS / IN_REVIEW |
| `[x]` | DONE |

#### ID 채번

`{PREFIX}-{순번}` 형식. PREFIX는 프로젝트별 약어 (예: SPH, MK).
순번은 backlog.md 내 최대 번호 + 1.

#### 아카이브 정리

| 트리거 | 동작 |
|--------|------|
| DONE 항목 10개 이상 | `archive/{YYYY-MM}.md`로 이동 |
| 세션 시작 시 | DONE 확인 → 필요 시 아카이브 |
| 마일스톤 완료 시 | 해당 태스크 일괄 아카이브 |

**backlog.md 크기 목표**: 완료 섹션 제외 50항목 이내.

### 워크플로우 3: 스코프 확정 → 위임

팀원의 발산적 작업을 방지하기 위한 핵심 워크플로우.

#### 흐름

```
태스크 도착
  → Lead: Explore 서브에이전트로 사전 조사
  → Lead: 스코프 문서 작성 (대상 파일, 금지 영역, 완료 기준)
  → PM: 팀원에게 스코프 포함하여 할당
  → 팀원: plan-mode로 계획 수립 (읽기만 가능)
  → Lead: 계획 검토 → 스코프 준수 시 승인 / 위반 시 거절+피드백
  → 팀원: 승인된 계획 범위 내에서 구현
```

#### Explore 서브에이전트 조사

Lead가 태스크를 받으면, 직접 코드를 분석하지 않고 **Explore 서브에이전트에 위임**한다.

```
Task(subagent_type=Explore, thoroughness=medium):
  prompt: "{대상 모듈} 관련 파일 분석.
           파일 목록, 핵심 클래스/메서드, import 의존성 정리.
           파일경로:라인 형식으로 요약."
```

조사 결과로 다음을 파악:
- 영향 받는 파일/모듈 목록
- 의존성 관계 (수정 시 파급 효과)
- 기존 패턴과 컨벤션
- 관련 테스트 존재 여부

#### 스코프 문서

Lead가 조사 결과를 기반으로 작성:

```markdown
## 태스크 스코프: #{ID} {제목}

### 대상 파일 (수정 허용)
- `path/to/file1.java`
- `path/to/file2.java`

### 금지 영역 (수정 불가)
- `src/auth/` — 이유: {근거}

### 완료 기준
- [ ] 기존 테스트 통과
- [ ] {구체적 검증 조건}

### 제약 조건
- {제약 1}
- {제약 2}
```

#### 팀원 스폰 (plan-mode 필수)

```
Task(subagent_type={role}, name={role}, team_name={project}-dev, mode=plan):
  prompt: "태스크 #{ID}: {제목}

           [스코프 문서 전문]

           plan-mode입니다. 스코프 범위 내에서 구현 계획을 수립하세요.
           계획이 준비되면 ExitPlanMode로 Lead의 승인을 받으세요."
```

#### Lead의 계획 승인 기준

| 확인 항목 | 거절 사유 |
|----------|----------|
| 대상 파일이 스코프 내인가 | 스코프 외 파일 수정 시도 |
| 금지 영역을 건드리는가 | 금지된 모듈 변경 |
| 완료 기준 충족 가능한 계획인가 | 검증 방법 누락 |
| 제약 조건 준수하는가 | 위반 사항 존재 |

### 워크플로우 4: 팀원 추가 확장

PM이 필요한 팀원을 Lead에게 요청하는 패턴.

#### 요청 형식 (PM → Lead)

```
팀원 요청: {역할}
이유: {왜 필요한지}
작업: {어떤 태스크를 맡길지}
```

#### Lead의 스폰 판단

1. 현재 활성 팀원 수 확인 (토큰 비용 고려)
2. 태스크 독립성 확인 (파일 충돌 가능성)
3. 필요 시 사용자 확인 후 스폰

#### 스폰 시 컨텍스트 제공

```
Task(subagent_type={role}, name={role}, team_name={project}-dev):
  prompt: "팀에 합류합니다. 담당 태스크: #{ID} {제목}.
           작업 범위: {구체적 파일/모듈}.
           완료 기준: {검증 방법}.
           메모리를 확인하고 작업을 시작하세요."
```

### 워크플로우 5: 팀 종료

작업 완료 후 정리.

1. PM에게 최종 현황 보고 요청 (MEMORY.md 업데이트)
2. Lead에게 기술 결정사항 기록 요청
3. 각 팀원에게 shutdown_request 전송
4. 모든 팀원 종료 확인 후 TeamDelete

## 에이전트 정의 패턴

`.claude/agents/{role}.md` 파일 구조:

```yaml
---
name: {role}
description: {역할 설명}. {자동 스폰 조건}.
model: sonnet
memory: local
---

## 프로젝트
- {프로젝트 설명}
- {기술 스택}

## 역할
- {핵심 책임 1}
- {핵심 책임 2}

## 메모리 관리
세션 시작 시 agent memory 확인. 작업 중 발견한 내용을 지속적으로 기록.

### 메모리 파일 구조
| 파일 | 용도 |
|------|------|
| `MEMORY.md` | 현재 상태 요약 (200줄 이내) |
| {역할별 추가 파일} | {용도} |

## 시작 행동
1. 메모리 확인 → 이전 상태 파악
2. {역할별 초기 행동}
3. 팀 리더에게 보고
```

## 중요 원칙

1. **코어 먼저**: Lead + PM만으로 시작. 태스크가 있을 때만 확장
2. **PM이 소유자**: 태스크 추가/변경/우선순위는 PM을 경유
3. **독립적 작업**: 팀원 간 파일 충돌 방지. 각자 다른 파일/모듈 담당
4. **메모리 활용**: `memory: local`로 세션 간 컨텍스트 유지
5. **비용 의식**: 팀원 수 = 토큰 비용. 필요한 만큼만 스폰
6. **명시적 컨텍스트**: 스폰 시 태스크, 범위, 완료 기준을 구체적으로 전달

## 안티패턴

| 문제 | 해결 |
|------|------|
| 전체 팀 한번에 스폰 | 코어 먼저 → 필요 시 확장 |
| 팀원에게 모호한 지시 | 태스크 ID, 파일 범위, 완료 기준 명시 |
| 같은 파일을 여러 팀원이 수정 | 파일/모듈 단위로 소유권 분리 |
| PM 없이 태스크 관리 | PM이 단일 소유. 직접 backlog 수정 금지 |
| 팀원 방치 | 주기적 진행 확인, idle 팀원 shutdown |
| 외부 도구 의존 | backlog.md가 유일한 소스 오브 트루스 |

## Examples

### 신규 프로젝트 팀 구성
```
User: "개발팀 셋업해줘"
→ 워크플로우 1: 프로젝트 분석
→ TeamCreate → Lead + PM 스폰
→ PM이 백로그 초기화 → 현황 보고
→ 사용자 지시 대기
```

### 태스크 기반 확장
```
PM: "백엔드 태스크 3건 있음. backend-dev 필요"
→ Lead: 사용자 확인 → backend-dev 스폰
→ PM이 태스크 할당 → 작업 시작
```

### 세션 재개
```
User: "/team-start"
→ 기존 팀 확인 → Lead + PM 스폰
→ 각자 MEMORY.md 읽고 이전 상태 복원
→ PM: 백로그 현황 보고 → 이어서 작업
```
