# FIRST: 세션 시작 프로토콜

**사용자의 첫 번째 메시지에 응답하기 전에, 반드시 아래를 실행한다.**
첫 번째 응답의 첫 번째 행동이 이 프로토콜이어야 한다. 예외 없음.

1. **MEMORY.md 읽기** — 프로젝트 컨텍스트, 이전 학습 복원 (시스템 프롬프트에 이미 포함되어 있으면 생략)
2. **WIP 확인** — `memory/wip/` 디렉토리의 파일 목록 확인. 있으면 읽어서 진행 중 작업 복원. `cwd` 항목 기준으로 작업 디렉토리 설정
3. **TaskList 확인** — 진행 중/미완료 task 파악
4. **git status** — wip의 `cwd` 또는 현재 작업 디렉토리에서 실행
5. **사용자에게 상태 요약** — 위 결과를 한 문단으로 보고 후, 이어서 할지 새로 시작할지 질문

**이 프로토콜을 건너뛰고 사용자 요청에 바로 답하지 않는다.**

---

# 대원칙: 쪼개서 해결한다

**문제를 정의하고, 쪼개고, 해결한다.**

## 1. 이해한다

- 무엇을 해결해야 하는지 파악한다
- 모호하면 질문한다
- 코드를 읽어 현재 상태를 파악한 뒤 작업한다

## 2. 계획한다

- **작업 계획을 먼저 정리**한다 — 무엇을, 어떤 순서로, 어떤 방식으로
- **방식**: 직접 할지, subagent에 맡길지, 팀을 꾸릴지, skill을 쓸지
- **Skill 매핑**: system-reminder의 available skills 목록을 확인하고, 각 task에 적용할 skill을 선정하여 계획에 `/skill-name` 형태로 명시한다
- **병렬화**: 의존성 없는 태스크를 식별하고 subagent/team으로 동시 실행한다
- **블로킹 최소화**: 구현 작업(파일 생성/수정/빌드/테스트)은 백그라운드 subagent 위임을 고려한다
- **검증**: 각 단위를 어떻게 검증할지 미리 정한다 (테스트, 스크린샷, 예상 출력)
- 3개 이상이면 TaskCreate로 목록화한다
- 계획 없이 코드부터 작성하지 않는다

## 3. 해결한다

- 독립 태스크는 **병렬로** 실행한다
- 의존성 태스크만 순서대로 완료 → 검증 → 다음
- 막히면 근본 원인을 추적한다
- **작업 단위 완료 시 즉시 커밋**: 질문 없이 바로 커밋한다

## Delegation Framework

메인 컨텍스트 = 경량 오케스트레이터. 계획 → 위임 → 추적 → 요약.

### 판단 기준

| 조건 | 방식 | 예시 |
|------|------|------|
| 1회 수정, 단순 | **직접** | 오타 수정, config 값 변경 |
| 단일 작업, 독립적 | **Subagent** | 버그 1건 수정, 테스트 추가 |
| 다단계, 순차 | **Relay** (phase별 subagent) | API 추가 → 마이그레이션 → 테스트 |
| 크로스레이어 + 계약 미확정 | **Team** | BE API + FE 페이지 (인터페이스가 작업 중 변경 가능) |

### Relay 패턴 (순차 다단계)

1. 전체 phase 계획, TaskCreate로 목록화
2. Phase별: subagent 스폰 (focused brief + 이전 phase handoff)
3. Handoff = branch name + 1-3줄 요약 + 파일 경로 (내용 전달 금지)
4. TaskUpdate 기록, 다음 phase 스폰
5. 전체 결과 사용자에게 요약

### Subagent Brief 템플릿

```
목표: [한 문장]
수정 대상: [파일 경로 목록]
참고 파일: [읽어야 할 파일 경로]
검증: [실행할 명령]
보고: [branch name, commit summary, test result]
```

### Worktree 격리

- subagent는 `isolation: worktree`로 스폰한다 (빌트인 `.claude/worktrees/` 사용)
- worktree 작업 지시 시 Team으로 구성하여 실행한다
- 구현 위임은 빌트인 general-purpose agent를 사용한다 (별도 워커 에이전트 불필요)
- 반복 패턴 3회+ 확인 시 특화 에이전트로 승격 (`.claude/agents/`)

### 메인 컨텍스트 실행 제한

- 2개 이상 파일 수정이 필요한 작업은 subagent에 위임한다
- 대량 탐색/검증은 subagent에 위임하여 메인 컨텍스트를 보호한다
- 단순 수정(오타, 버전, 1-2줄), git commit/push는 직접 허용

---

## Bash

- 독립 명령은 병렬 호출로 분리, `&&`/`|` 체이닝 금지

---

## Memory

built-in auto memory 규칙을 따르되, 추가 규칙:

| 계층 | 대상 | 수명 |
|------|------|------|
| MEMORY.md | 확정 패턴, 아키텍처, 사용자 선호 | 영속 (200줄 이내) |
| topic file | 상세 참조 (debugging.md 등) | 영속 (on-demand Read) |
| wip/{name}.md | 컨텍스트 보존용 작업 상태 (worktree별 격리) | 휘발 (작업 완료 시 삭제) |

- `wip/{name}.md`는 compaction 대비 전용. `{name}`은 worktree 이름 또는 작업 식별자. 작업 완료 시 즉시 삭제한다
- 검증된 학습은 MEMORY.md 또는 topic file에 직접 기록 (wip.md 경유 불필요)

---

## Compaction

When compacting, always preserve: **TaskList 상태, 현재 진행 중인 task ID, 수정한 파일 목록**.

**Flush** (`/compact` 전에 가능하면 실행): WIP 상태를 `memory/wip/{name}.md`에 기록한다.
- **{name}**: worktree 이름 또는 작업 식별자 (예: `cov-service`, `fix-daily-pr-review`)
- **cwd**: 현재 작업 디렉토리 (절대 경로)
- 현재 작업 컨텍스트, 미완료 사항, 핵심 결정사항

> PreCompact 훅이 auto-compaction 시 `cwd`를 자동 저장하지만,
> `cwd`가 실제 작업 worktree와 다를 수 있으므로 수동 flush가 더 정확하다.

컨텍스트 압축 후:

1. **wip/ 디렉토리 확인** — 활성 wip 파일에서 이전 작업 상태 복원
2. **TaskList 확인** — 어디까지 했는지 파악
3. **적합한 Skill 호출** — 작업에 필요한 컨텍스트를 skill이 복원
4. **이어서 해결** — 다음 미완료 task부터 재개
