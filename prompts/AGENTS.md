# FIRST: 세션 시작 프로토콜

**첫 메시지 응답 전 반드시 실행. 예외 없음.**

1. **MEMORY.md 읽기** — 프로젝트 컨텍스트, 이전 학습 복원
2. **이전 작업 확인** — `/recall`로 최근 작업 컨텍스트 복원
3. **TaskList 확인** — 진행 중/미완료 task 파악
4. **git status** — 현재 작업 디렉토리에서 실행
5. **사용자에게 상태 요약** — 한 문단 보고 후, 이어서 할지 새로 시작할지 질문

---

# 대원칙

- **이해 → 계획 → 해결**. 단순한 해법부터. 3개 이상이면 TaskCreate로 목록화
- **작업 단위 완료 시 즉시 커밋**. `git commit --amend` 금지 — 항상 새 커밋
- **scope creep 금지** — 계획에 없는 개선은 TODO로만 기록
- **날짜 변경 감지** — 시스템 주입 `currentDate`가 이전 응답과 다른 날짜면, 응답 첫 줄에 `📅 {날짜} {요일}` 표시. 장시간 공백(1일+)이면 `date` 명령으로 정확한 시간도 확인

---

# Delegation

메인 컨텍스트 = 오케스트레이터. 계획 → 위임 → 추적 → 요약.

| 조건 | 방식 |
|------|------|
| 1-2줄 수정, git ops | **직접** |
| 명세 확정, 독립 작업 | **Agent** |
| 판단·반복 수정 필요 | **직접** (현재 branch에서) |
| 다단계 순차 | **Relay** (phase별 subagent) |

## Agent 규칙

- **일회성**: 완료 → 결과 반환 → 종료. **완료된 Agent에 SendMessage 금지**
- `mode: "auto"` + `name` 필수 (kebab-case)
- **isolation: 기본은 사용하지 않음** — 현재 디렉토리에서 실행
  - 병렬 Agent 2개 이상이 같은 파일을 수정할 가능성이 있을 때만 `isolation: "worktree"`
- **리뷰는 메인에서, 수정만 Agent로 위임**. 리뷰+수정을 하나의 Agent에 묶지 않는다
- **push / PR 생성·수정은 Agent에 위임하지 않는다** — 메인에서 직접
- 새 Agent 스폰 시 기존 branch name + PR 번호 + 이전 작업 요약 전달 필수
- **cherry-pick 금지** — 같은 branch에서 이어 작업
- **Agent는 반드시 커밋 완료 후 종료** — 미커밋 작업은 cleanup으로 유실됨

---

# Bash

- **셸 연산자 금지**: `|` `&&` `;` 사용하지 않는다. 독립 명령은 별도 Bash 호출로 병렬
- **`git -C` 금지**: 해당 디렉토리에서 직접 실행
- 파일 분석은 CLI 우선 (`jq`, `xmlstarlet`, `awk`, `sed`). Python은 복잡한 변환/시각화에만

---

# Agent Browser

- 스크린샷: `.claude/screenshots/<worktree명>/` (없으면 `main/`)

---

# Memory

| 계층 | 대상 | 수명 |
|------|------|------|
| MEMORY.md | 확정 패턴, 사용자 선호 | 영속 (200줄 이내) |
| topic file | 상세 참조 | 영속 (on-demand Read) |

---

# Compaction

preserve: **TaskList 상태, 현재 task ID, 수정한 파일 목록**.

압축 후: `/recall` → TaskList 확인 → 다음 미완료 task 재개
