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

- **계획 먼저**: 무엇을, 어떤 순서로, 직접/subagent/team 중 어떤 방식으로
- **병렬화**: 의존성 없는 태스크는 subagent/team으로 동시 실행
- **검증**: 각 단위를 어떻게 검증할지 미리 정한다
- 3개 이상이면 TaskCreate로 목록화
- 독립 태스크는 병렬, 의존성 태스크만 순차 (완료 → 산출물 리뷰 → 다음)
- **순차 전환 시 산출물 리뷰**: 다음 phase로 넘어가기 전에 이전 산출물을 직접 확인한다 (Read, 실행 결과 확인 등). 이상 있으면 멈추고 보고.
- **작업 단위 완료 시 즉시 커밋**: 질문 없이 바로 커밋
- **`git commit --amend` 금지**: 항상 새 커밋을 생성한다. 이전 커밋을 수정하지 않는다

## Delegation Framework

메인 컨텍스트 = 경량 오케스트레이터. 계획 → 위임 → 추적 → 요약.

| 조건 | 방식 |
|------|------|
| 1-2줄 단순 수정, git ops | **직접** |
| 단일 작업, 독립적 | **Subagent** |
| 다단계, 순차 | **Relay** (phase별 subagent + TaskCreate) |
| 크로스레이어, 계약 미확정 | **Team** |

- **worktree 우선**: 기능 작업 시 worktree 생성이 최우선. 코드 분석은 worktree 안에서
- subagent는 `isolation: worktree`로 스폰하되, 반드시 `name` 파라미터에 작업 의도를 담은 이름을 지정한다 (예: `balance-initial-price`). 랜덤 해시 이름 금지
- `EnterWorktree` 사용 시에도 반드시 `name` 파라미터 지정 (영문 kebab-case, 3단어 이내)
- **메인 워킹 디렉토리에서 `git checkout -b` 금지** — branch 생성은 worktree를 통해서만
- Relay handoff = branch name + 1-3줄 요약 + 파일 경로 (내용 전달 금지)
- 반복 패턴 3회+ → `.claude/agents/`에 특화 에이전트로 승격

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
