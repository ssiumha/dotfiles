# FIRST: 세션 시작 프로토콜

**사용자의 첫 번째 메시지에 응답하기 전에, 반드시 아래를 실행한다. 예외 없음.**

1. **MEMORY.md 읽기** — 프로젝트 컨텍스트, 이전 학습 복원
2. **이전 작업 확인** — `/recall`로 최근 작업 컨텍스트 복원
3. **TaskList 확인** — 진행 중/미완료 task 파악
4. **git status** — 현재 작업 디렉토리에서 실행
5. **사용자에게 상태 요약** — 위 결과를 한 문단으로 보고 후, 이어서 할지 새로 시작할지 질문

---

# 대원칙: 쪼개서 해결한다

## 1. 이해한다 → 2. 계획한다 → 3. 해결한다

- **단순한 해법부터**: 크로스 도메인/레이어 변경 시, 패턴 도입 전에 의존성 사이클 존재 여부를 먼저 확인한다. 사이클이 없으면 직접 참조가 가장 단순한 해법이다
- **계획 먼저**: 무엇을, 어떤 순서로, 직접/subagent/team 중 어떤 방식으로
- **병렬화**: 의존성 없는 태스크는 subagent/team으로 동시 실행
- **검증**: 각 단위를 어떻게 검증할지 미리 정한다
- 3개 이상이면 TaskCreate로 목록화
- 독립 태스크는 병렬, 의존성 태스크만 순차 (완료 → 산출물 리뷰 → 다음)
- **순차 전환 시 산출물 리뷰**: 다음 phase로 넘어가기 전에 이전 산출물을 직접 확인한다 (Read, 실행 결과 확인 등). 이상 있으면 멈추고 보고.
- **작업 단위 완료 시 즉시 커밋**: 질문 없이 바로 커밋
- **`git commit --amend` 금지**: 항상 새 커밋을 생성한다. 이전 커밋을 수정하지 않는다
- **scope creep 금지**: 계획에 없는 추가 개선을 발견하면, 직접 수행하지 않고 TODO로 기록만 한다. 사용자가 요청하기 전까지는 계획 범위만 실행

## Delegation Framework

메인 컨텍스트 = 경량 오케스트레이터. 계획 → 위임 → 추적 → 요약.

| 조건 | 방식 |
|------|------|
| 1-2줄 단순 수정, git ops | **직접** |
| 단일 작업, 명세 확정, 판단 불필요 | **Subagent** (worktree) |
| 대화·판단·반복 수정이 필요한 코드 변경 | **EnterWorktree** (메인 컨텍스트 유지) |
| 다단계, 순차 | **Relay** (phase별 subagent + TaskCreate) |
| 크로스레이어, 계약 미확정 | **Team** |

### worktree 규칙

- **worktree 우선**: 코드 변경은 반드시 worktree에서. main 직접 수정 금지
- **메인 워킹 디렉토리에서 `git checkout -b` 금지** — branch 생성은 worktree를 통해서만
- `name` 파라미터 필수 (영문 kebab-case, 3단어 이내). 랜덤 해시 이름 금지

### Agent vs EnterWorktree 선택 기준

| 판단 기준 | Agent (worktree) | EnterWorktree |
|----------|-----------------|---------------|
| 명세 확정 여부 | 입출력이 명확 | 탐색·판단 필요 |
| 작업 크기 | 1 commit 분량 | 복수 commit 가능 |
| interrupt 내성 | 중단 시 컨텍스트 유실 | 메인 컨텍스트 유지 |
| 사용 예 | "이 파일에서 A를 B로 변경" | "리뷰 후 수정", "원인 분석 후 fix" |

- **리뷰+수정을 하나의 Agent에 묶지 않는다** — 리뷰는 메인에서, 수정만 Agent로 위임
- Agent는 `isolation: "worktree"` + `mode: "acceptEdits"` 고정
- Relay handoff = branch name + 1-3줄 요약 + 파일 경로 (내용 전달 금지)
- 반복 패턴 3회+ → `.claude/agents/`에 특화 에이전트로 승격

### Agent 생명주기 규칙

- **Agent는 일회성**: 작업 완료 → 결과 반환 → 프로세스 종료. 완료된 Agent에 SendMessage 금지
- **추가 작업 = 새 Agent 스폰** 또는 **EnterWorktree로 직접 수행**. 절대로 죽은 Agent에 메시지 보내며 기다리지 않는다
- **기존 컨텍스트 계승 필수**: 새 Agent 스폰 시 반드시 현재 상태를 전달한다:
  - 기존 branch name (있으면)
  - 열린 PR 번호 (있으면)
  - 이전 Agent가 수행한 작업 요약
- **Agent에게 git push / PR 생성·수정·삭제를 위임하지 않는다** — 이런 작업은 메인 컨텍스트에서 직접 수행

### Team 권한 주의사항

- teammate의 permission은 lead 세션의 allowlist를 상속 — **스폰 전에 필요한 permission을 settings allowlist에 등록**
- `mode: "bypassPermissions"` 금지. `mode: "acceptEdits"` 사용
- permission prompt가 병렬 이점을 상쇄하면 Team 대신 Relay(순차 subagent)로 전환

---

## Bash

- **셸 연산자 금지**: `|` 파이프, `&&` 체이닝, `;` 연결 사용하지 않는다
- **`git -C` 절대 금지**: worktree든 메인이든, 현재 working directory에서 `git` 명령을 바로 실행한다. `git -C <path>` 형태는 어떤 상황에서도 사용하지 않는다. worktree에 있으면 이미 그 디렉토리이므로 `-C`가 불필요하다
- 독립 명령 → 별도 Bash 호출로 병렬 실행
- 순차 의존 → 별도 Bash 호출로 순차 실행
- 리다이렉션(`>`, `>>`, `2>/dev/null`)은 허용
- 반복 명령(typecheck, lint, test, build 등)은 프로젝트 태스크 러너(`justfile`, `mise.toml`, `Makefile`, `package.json` scripts 등)를 우선 사용. 없으면 추가 제안

## 파일 분석/파싱

- **CLI 도구 우선**: `jq`, `xmlstarlet`, `xq`(yq), `awk`, `sed`, `cut`, `sort`, `uniq`, `wc`, `grep` 등으로 해결한다
- **Python 스크립트 작성 금지** — 단, 다음 경우에만 폴백 허용:
  - 멀티패스 집계, 복잡한 조인/피벗 등 CLI 한 줄로 불가능한 변환
  - 차트/시각화 생성
- XML(JaCoCo, pom.xml 등) → `xmlstarlet sel` 또는 `xq`
- JSON → `jq`
- CSV/TSV → `awk`, `cut`, `sort`
- 로그/텍스트 → `grep`, `awk`, `sed`

---

## Agent Browser

- 스크린샷 저장 경로: `.claude/screenshots/<worktree명>/`
- worktree 없으면 `.claude/screenshots/main/`

---

## Memory

built-in auto memory 규칙 + 추가:

| 계층 | 대상 | 수명 |
|------|------|------|
| MEMORY.md | 확정 패턴, 아키텍처, 사용자 선호 | 영속 (200줄 이내) |
| topic file | 상세 참조 (debugging.md 등) | 영속 (on-demand Read) |

---

## Compaction

preserve: **TaskList 상태, 현재 진행 중인 task ID, 수정한 파일 목록**.

압축 후:
1. `/recall`로 이전 작업 컨텍스트 복원
2. TaskList 확인 → 진행 상황 파악
3. 다음 미완료 task부터 재개
