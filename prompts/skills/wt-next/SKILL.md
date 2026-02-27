---
name: wt-next
description: 같은 git worktree에서 다음 task로 전환하며 컨텍스트를 자동 복원. Use when 다음 task, 이어서, /clear 후 같은 worktree 계속, next task in same worktree. Do NOT use for worktree 생성/삭제 (use git-worktree instead).
argument-hint: "<task-description> [--save]"
---

# wt-next

같은 worktree에서 task 전환 시 컨텍스트를 자동 복원한다.

## Quick Reference

```
/wt-next --save                    # /clear 전 핸드오프 저장
/wt-next <task-description>        # 컨텍스트 복원 + 다음 task 시작
/wt-next <task-description> --plan # 복원 후 plan-creator 연동
```

## 핵심 철학

1. **Git이 진실의 원천** — handoff보다 git log/status/diff 우선
2. **비파괴적** — 기존 파일을 변경하지 않음
3. **최소 입력, 최대 복원** — task 설명만 주면 나머지 자동
4. **계획 위임** — 컨텍스트 수집만 담당, 계획은 plan-creator 책임
5. **점진적 복원** — handoff 없어도 git만으로 충분히 복원

---

## Phase S: 핸드오프 저장 (`--save`)

`/clear` 전에 실행. 현재 컨텍스트를 worktree 내 `.claude/handoff.md`에 저장한다.

### S-1. 저장 경로 결정

```
WORKTREE_ROOT=$(git rev-parse --show-toplevel)
HANDOFF="${WORKTREE_ROOT}/.claude/handoff.md"
mkdir -p "${WORKTREE_ROOT}/.claude"
```

### S-2. 수집 항목

| 항목 | 소스 | 필수 |
|------|------|------|
| 완료한 작업 | 대화 히스토리 요약 | O |
| 미완료/보류 | 대화 히스토리에서 추출 | O |
| 핵심 결정사항 | 대화 중 합의된 설계/방향 | O |
| 수정한 파일 목록 | `git diff --name-only HEAD~3..HEAD` (최근 3커밋) | O |
| 다음 task 힌트 | 사용자 언급 또는 추론 | - |

### S-3. handoff.md 형식

```markdown
# Handoff: {branch-name}
> saved: {timestamp}

## 완료
- {완료 항목 1}
- {완료 항목 2}

## 미완료/보류
- {미완료 항목}

## 핵심 결정
- {결정 사항}

## 수정 파일
- {file1}
- {file2}

## 다음 task 힌트
- {힌트}
```

### S-4. 저장 후 안내

```
handoff 저장: .claude/handoff.md
/clear 후 `/wt-next <다음 task>` 로 이어서 시작하세요.
```

**주의**: handoff.md는 자동 삭제하지 않는다. `--save`로만 갱신된다.

---

## Phase 1: 환경 감지

worktree 환경과 기술 스택을 자동 감지한다.

### 1-1. Git worktree 확인

```bash
git rev-parse --show-toplevel        # worktree root
git branch --show-current            # 현재 branch
git rev-parse --is-inside-work-tree  # worktree 여부
```

worktree가 아니면 안내 후 중단: "worktree 환경이 아닙니다. `/git-worktree add`로 먼저 생성하세요."

### 1-2. .worktree.json 확인

worktree root에 `.worktree.json`이 있으면 읽어서 feature명, 포트, 스크립트 정보를 수집한다.

### 1-3. 기술 스택 감지

`package.json`, `pom.xml`, `pyproject.toml`, `go.mod`, `Gemfile` 등의 존재 여부로 기술 스택을 판단한다. 빌드/테스트 명령어를 추출한다.

---

## Phase 2: 히스토리 복원

아래 순서로 읽되, 각 소스는 **보충 관계**이다. 앞 단계가 충분하면 뒤를 생략할 수 있다.

### 2-1. handoff.md (있으면)

```
WORKTREE_ROOT=$(git rev-parse --show-toplevel)
cat "${WORKTREE_ROOT}/.claude/handoff.md"
```

가장 풍부한 컨텍스트. 완료/미완료/결정사항이 구조화되어 있다.

### 2-2. git log + diff

**항상 실행** — handoff 유무와 관계없이 Git이 진실의 원천.

```bash
git log --oneline -10                          # 최근 커밋 히스토리
git log --oneline --since="3 days ago"         # 최근 3일 작업
git diff --stat HEAD~5..HEAD                   # 최근 5커밋 변경 통계
git status --short                             # 현재 dirty state
```

### 2-3. wip/ 파일 (있으면)

```bash
# memory/wip/{worktree-name}.md 존재 확인
```

compaction으로 생성된 wip 파일이 있으면 읽는다. 보통 handoff보다 정보가 적다.

### 2-4. CLAUDE.md (있으면)

worktree root 또는 프로젝트 root의 `CLAUDE.md`에서 프로젝트 컨텍스트를 확인한다.

---

## Phase 3: 컨텍스트 종합 리포트

수집한 정보를 구조화하여 사용자에게 보고한다.

### 리포트 형식

```markdown
## Worktree Context

| 항목 | 값 |
|------|---|
| Branch | {branch} |
| Feature | {feature from .worktree.json or branch name} |
| 기술 스택 | {detected stack} |
| 마지막 커밋 | {last commit message + time} |
| Dirty state | {clean / N files modified} |

## 이전 작업 요약
{handoff 또는 git log 기반 요약, 3-5줄}

## 미완료/보류 사항
{있으면 나열, 없으면 "없음"}

## 다음 Task
> {$ARGUMENTS에서 받은 task description}
```

---

## Phase 4: 전환

리포트 출력 후, `$ARGUMENTS`로 받은 task description에 따라 작업을 시작한다.

### 4-1. 분기 판단

| 조건 | 행동 |
|------|------|
| `--plan` 플래그 있음 | plan-creator 호출 안내 |
| task가 복잡해 보임 (3+ 파일, 아키텍처 변경) | plan-creator 추천 |
| task가 단순함 | 바로 작업 시작 |

### 4-2. 복잡한 task → plan-creator 연동

```
이 task는 여러 파일에 걸친 변경이 예상됩니다.
`/plan-creator {task-description}` 으로 계획을 먼저 수립하시겠습니까?
계획 수립 후 `/plan-review`로 검증하면 더 안전합니다.
```

### 4-3. 단순한 task → 바로 시작

이전 컨텍스트를 반영하여 task를 바로 시작한다. 미완료 사항이 있으면 충돌 여부를 확인한 후 진행한다.

---

## 중요 원칙

1. **handoff ≠ 필수**: handoff 없어도 git log/status만으로 복원 가능해야 한다
2. **wip/ 미삭제**: wt-next는 wip 파일을 읽기만 한다. 삭제는 세션 시작 프로토콜의 책임
3. **비간섭**: 기존 `.claude/` 구조를 변경하지 않는다. handoff.md만 관리
4. **연동 파이프라인 존중**: plan-creator → plan-review → 실행 흐름을 강제하지 않되, 복잡한 task에는 추천

---

## 연동

```
wt-next --save (핸드오프 저장)
  → /clear
    → wt-next <task> (컨텍스트 복원)
      → plan-creator (계획 수립, 복잡 시)
        → plan-review (계획 검증)
          → 실행
            → wt-next --save (반복)
```

| Skill | 관계 | 설명 |
|-------|------|------|
| `git-worktree` | 선행 | worktree 생성/삭제는 git-worktree 담당 |
| `plan-creator` | 후속 | 복잡한 task의 계획 수립 위임 |
| `plan-review` | 후속 | 계획 검증. plan-creator 후 실행 전 |
| `reflect` | 보완 | 세션 회고. wt-next --save 전에 실행 가능 |

---

## Examples

### 핸드오프 저장 후 전환

```
User: /wt-next --save
→ Phase S: .claude/handoff.md 저장
→ "handoff 저장 완료. /clear 후 /wt-next <다음 task>로 이어서 시작하세요."

User: /clear
User: /wt-next API 인증 미들웨어 추가
→ Phase 1: worktree 감지 (fix/login, Node.js)
→ Phase 2: handoff.md 읽기 + git log 확인
→ Phase 3: 컨텍스트 리포트 출력
→ Phase 4: 단순 task → 바로 시작
```

### handoff 없이 복원

```
User: /wt-next 테스트 커버리지 80% 달성
→ Phase 1: worktree 감지 (feature/auth, Spring Boot)
→ Phase 2: handoff 없음 → git log 10개 + diff stat으로 복원
→ Phase 3: 리포트 출력 (이전 3커밋 요약 + 현재 상태)
→ Phase 4: 복잡 task → "/plan-creator로 계획 수립 추천"
```

### 지시 직접 기술

```
User: /wt-next UserService에 캐싱 추가. Redis 사용하고 TTL 5분. 기존 테스트 깨지지 않게.
→ Phase 1-3: 환경 감지 + 복원 + 리포트
→ Phase 4: task description이 상세하므로 바로 시작
```
