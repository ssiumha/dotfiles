---
name: wt-next
description: 같은 git worktree에서 다음 task로 전환하며 컨텍스트를 자동 복원. Use when 다음 task, 이어서, /clear 후 같은 worktree 계속, next task in same worktree. Do NOT use for worktree 생성/삭제 (use git-worktree instead).
argument-hint: "[--save] <instructions>"
---

# wt-next

같은 worktree에서 task 전환 시 컨텍스트를 자동 복원한다.

## Quick Reference

```
/wt-next --save                    # /clear 전 핸드오프 저장
/wt-next <instructions>            # 컨텍스트 복원 + 계획 수립 (plan mode)
```

## 핵심 철학

1. **Git이 진실의 원천** — handoff보다 git log/status/diff 우선
2. **비파괴적** — 기존 파일을 변경하지 않음
3. **최소 입력, 최대 복원** — task 설명만 주면 나머지 자동
4. **복원 → 계획 제시** — 컨텍스트 복원 후 $ARGUMENTS 기반 실행 계획을 수립하여 보여줌. 승인 후 실행
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

## Phase 3: 컨텍스트 요약

수집한 정보를 한줄 컨텍스트로 압축하여 출력한다. 사용자가 즉시 작업에 들어갈 수 있도록 최소한의 정보만 제공.

### 출력 형식

```markdown
## Context Restored
> {branch} ({stack}) | 최근: "{last commit message}" ({time ago}) | dirty: {N files}

## 미완료 (있으면만)
- {항목}
```

- 미완료 사항이 없으면 "미완료" 섹션 자체를 생략
- handoff가 있었으면 핵심 결정사항을 1-2줄로 추가 가능

---

## Phase 4: 계획 수립

`$ARGUMENTS`와 복원된 컨텍스트를 종합하여 **실행 계획을 수립**하고 plan mode로 제시한다. 실행은 사용자 승인 후.

### 4-1. 계획 수립 원칙

- `$ARGUMENTS`는 **실행할 작업 지시**이다. 라벨이 아님
- 복원된 컨텍스트(이전 작업, 기술 스택, dirty state, 미완료 사항)를 반영하여 계획 수립
- **항상 plan mode** — EnterPlanMode로 전환하여 계획을 작성하고 ExitPlanMode로 승인 요청
- 미완료 사항과 `$ARGUMENTS`가 충돌하면 계획에 충돌 사항을 명시

### 4-2. 계획 포함 사항

- 수정 대상 파일과 변경 내용
- 의존 관계와 실행 순서
- 미완료 사항 중 관련 있는 항목 반영 여부
- 검증 방법 (테스트, 빌드 등)

---

## 중요 원칙

1. **handoff ≠ 필수**: handoff 없어도 git log/status만으로 복원 가능해야 한다
2. **wip/ 미삭제**: wt-next는 wip 파일을 읽기만 한다. 삭제는 세션 시작 프로토콜의 책임
3. **비간섭**: 기존 `.claude/` 구조를 변경하지 않는다. handoff.md만 관리
4. **연동 파이프라인 존중**: plan-creator → plan-review → 실행 흐름을 강제하지 않음. 필요 시 사용자가 별도 호출

---

## 연동

```
wt-next --save (핸드오프 저장)
  → /clear
    → wt-next <instructions> (컨텍스트 복원 + 계획 제시)
      → wt-next --save (반복)
```

복잡한 작업이 필요하면 사용자가 `/plan-creator`를 별도 호출.

| Skill | 관계 | 설명 |
|-------|------|------|
| `git-worktree` | 선행 | worktree 생성/삭제는 git-worktree 담당 |
| `plan-creator` | 별도 | 복잡한 task 시 사용자가 직접 호출 |
| `reflect` | 보완 | 세션 회고. wt-next --save 전에 실행 가능 |

---

## Examples

### 핸드오프 저장 후 전환

```
User: /wt-next --save
→ Phase S: .claude/handoff.md 저장
→ "handoff 저장 완료. /clear 후 /wt-next <instructions>로 이어서 시작하세요."

User: /clear
User: /wt-next API 인증 미들웨어 추가
→ Phase 1: worktree 감지 (fix/login, Node.js)
→ Phase 2: handoff.md + git log 복원
→ Phase 3: > fix/login (Node.js) | 최근: "add auth middleware" (2h ago) | dirty: 0 files
→ Phase 4: EnterPlanMode → 미들웨어 구현 계획 제시 → 승인 대기
```

### handoff 없이 복원 + 계획 제시

```
User: /wt-next 테스트 커버리지 80% 달성
→ Phase 1: worktree 감지 (feature/auth, Spring Boot)
→ Phase 2: handoff 없음 → git log + diff stat으로 복원
→ Phase 3: > feature/auth (Spring Boot) | 최근: "add user entity" (1d ago) | dirty: 2 files
→ Phase 4: EnterPlanMode → 커버리지 분석 + 테스트 작성 계획 제시 → 승인 대기
```

### 상세 지시로 계획 수립

```
User: /wt-next UserService에 캐싱 추가. Redis 사용하고 TTL 5분. 기존 테스트 깨지지 않게.
→ Phase 1-2: 환경 감지 + 복원
→ Phase 3: > feature/user (Node.js) | 최근: "refactor UserService" (3h ago) | dirty: 0 files
→ Phase 4: EnterPlanMode → Redis 캐싱 구현 계획 제시 → 승인 후 실행
```
