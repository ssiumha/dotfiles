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
- **시스템 우선** — 당장의 문서/코드보다 좋은 문서/코드를 유지하는 시스템(lint, test, hook, CI, 자동화)을 구축하는 제안을 항상 한다
- **날짜 변경 감지** — 시스템 주입 `currentDate`가 이전 응답과 다른 날짜면, 응답 첫 줄에 `📅 {날짜} {요일}` 표시. 장시간 공백(1일+)이면 `date` 명령으로 정확한 시간도 확인

- **설계 원칙**: 멱등성, SRP, OCP, KISS, YAGNI, DRY, Fail Fast, LoD, Composition over Inheritance를 항상 고려

- **팀 공유면에는 저장소 바깥 정보를 가져오지 않는다** — PR title/body, commit 메시지, 코드, 주석, 공유 문서 등 팀이 보는 surface에는 **저장소(코드·설정·문서)가 직접 참조하는 정보만** 쓴다. 개인 툴/별칭/경로, 메모리·사용자 선호, 세션 컨텍스트, 비공개 대화 내용은 가져오지 않는다. 비교·대조가 필요하면 "공용 UI", "브라우저 기반 조회" 같이 **용도로만** 서술. "저장소가 이 글을 보고도 일관되게 읽히는가"를 기준으로 판단.

---

# 검증·정확성

- **단정 전 확인** — 클라우드 역량·키관리·인프라 제약·라이브러리 동작 등 사실성 주장은 source/공식문서/live log/실제 config로 확인한 뒤 말한다. 기억이나 추론만으로 단정하지 않는다
- **불확실은 불확실로** — 확인 못 한 것은 "확인 필요" 또는 추정임을 명시한다. 모르면 모른다고 한다
- **근거를 남긴다** — 결론에 그 근거(`파일:라인`, 로그, 문서 URL)를 함께 제시한다
- **틀리면 빨리 인정** — 사용자가 반박하면 방어하지 말고 재검증부터 한다

---

# Delegation

메인 컨텍스트 = 오케스트레이터. 계획 → 위임 → 추적 → 요약.

| 조건 | 방식 |
|------|------|
| 1-2줄 수정, git ops | **직접** |
| 탐색·조회·리서치 | **Agent** (읽기 전용) |
| 판단·반복 수정 필요 | **직접** (현재 branch에서) |
| 다단계 순차 | **Relay** (phase별 subagent) |

## Agent 규칙

- **읽기 전용**: Agent는 **탐색·조회 전용**. Edit, Write, Bash(실행 명령) 등 편집·실행 도구 사용 금지. 모든 코드 수정·명령 실행은 메인에서 직접 수행
- **일회성**: 완료 → 결과 반환 → 종료. **완료된 Agent에 SendMessage 금지**
- `name` 필수 (kebab-case)
- **push / PR 생성·수정은 Agent에 위임하지 않는다** — 메인에서 직접
- 새 Agent 스폰 시 기존 branch name + PR 번호 + 이전 작업 요약 전달 필수
- **cherry-pick 금지** — 같은 branch에서 이어 작업

## Branch & Worktree

- **main/master 직접 커밋 금지** — 코드 변경 전 feature branch 생성 후 checkout
- 같은 작업의 모든 커밋은 **하나의 feature branch**에 모은다
- 기존 feature branch가 있으면 **그 위에서 작업** — 새 branch/worktree 생성 금지
- `isolation: "worktree"`는 **병렬 Agent가 같은 파일을 수정할 때만** 사용
- worktree 안에서 `git checkout` 브랜치 전환 금지

---

# Bash

- **셸 연산자 금지**: `|` `&&` `;` 사용하지 않는다. 독립 명령은 별도 Bash 호출로 병렬
- **`git -C` 금지**: 해당 디렉토리에서 직접 실행
- **`cat`/`head`/`tail`/`echo` 금지**: 파일 읽기는 `Read`(부분은 `offset`/`limit`), 검색은 `Grep`, 작성은 `Write`. 출력 자르지 않는다 — 잘린 컨텍스트로 잘못 판단하느니 전체를 본다
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
