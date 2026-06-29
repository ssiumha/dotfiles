---
name: obsidian-write
description: Writes Obsidian pages (frontmatter, checkbox, folder-based namespace, wikilink) following conventions. Use when creating namespace pages (troubleshoot, decision, qa, spec, incident, issue), writing journal entries, promoting journal to pages, or editing existing pages. Vault 위치/namespace 매핑은 `documentation` skill 참조. Do NOT use for reading/searching (use ir directly).
---

## Atomic Notes 원칙

- 하나의 개념 = 하나의 페이지. 프로젝트에 종속되지 않는 범용 개념으로 작성
- 프로젝트 특이사항은 같은 페이지에 `#pj-{name}` 태그와 함께 한 줄로 기술
- 구현 디테일(코드 위치, 엔티티, API)은 개념 페이지가 아닌 프로젝트 도메인 페이지에 작성
- 본문에 등장하는 도메인 용어는 `[[링크]]`로 연결 — 페이지가 없으면 생성 검토
- 편집 중 개념 페이지에 구현 디테일이 섞여 있으면 분리 제안

## 기존 패턴 (건드리지 않는다)

- 모든 페이지: 최상단 YAML frontmatter (`---\nkey: value\n---`)
- 본문에서 개념화된 용어는 `[[링크]]`로 연결 — `#태그`는 저널 TODO 행에서만 사용
- aliases는 `aliases: [Name1, Name2]` 형태 (문자열 배열)
- block reference: 블록 끝 `^anchor` 마커, 참조는 `[[Page#^anchor]]`
- block embed: `![[Page#^anchor]]` 또는 `![[Page]]` (전체 임베드)
- 저널: `- [ ] {설명} #pj-{프로젝트}` / `- [x] {설명}` / `- [/] {설명}` (DOING)
- 프로젝트 허브: `projects/{name}/pj-{name}.md` (또는 비활성은 `archive/{name}/pj-{name}.md`). `pj-{name}`은 **wikilink 이름·태그**로만 사용 — 폴더 경로는 `projects/{name}/`이다. wikilink basename match로 `[[pj-{name}]]`이 자동 해석됨. 하위 집계는 Obsidian Bases 또는 Dataview 사용
- `#thought` 태그: 사람 전용. AI는 이 태그를 사용하지 않으며, `#thought`가 붙은 블록을 편집하지 않는다

## 연결 원칙

- **모든 문서는 최소 하나의 다른 문서와 연결**되어야 한다
- namespace 페이지 작성 시 `ir search`로 관련 기존 페이지를 찾아 `[[링크]]`로 연결
- **namespace 페이지 생성 시 반드시 당일 저널에 링크 남기기**
  - 관련 저널 TODO가 있으면 `[x]`로 변경하고 하위에 `-> [[{type}/{제목}]]` 링크 추가
  - 관련 TODO가 없으면 새 항목: `- [x] {설명} #pj-{project}` + `-> [[링크]]`
- namespace 페이지 간에도 관련 있으면 서로 링크
- frontmatter `project`, `date` 자체가 프로젝트 허브와 저널로의 연결
- 본문 내 `[[link]]` 형태로 — plain text는 그래프 엣지를 만들지 않는다

## TODO 관리

### 라이프사이클

`- [ ]` → `- [/]` (DOING) → `- [x]` (DONE)
취소: `- [-]`

### Obsidian Tasks 호환 형식

- 우선순위: `🔼 (high)`, `🔽 (low)`, `🔺 (highest)` 또는 본문 prefix `[#A]/[#B]/[#C]`
- 스케줄: `📅 YYYY-MM-DD` (due), `⏳ YYYY-MM-DD` (scheduled), `🛫 YYYY-MM-DD` (start)
- 완료일: `✅ YYYY-MM-DD`

기본은 단순 checkbox + 한국어 작성. priority/scheduled가 필요할 때만 위 마커 사용.

### 집계 (Bases / Dataview)

Obsidian Bases (1.7+) 또는 Dataview 플러그인 사용. 기존 logseq `{{query}}` 매크로는 마이그레이션 시 `<!-- {{query ...}} -->` 형태로 주석 처리되어 있으니 케이스별로 정리.

```dataview
;; 프로젝트 TODO 집계 (Dataview)
TASK
FROM "projects/{name}"
WHERE !completed
```

```yaml
# Bases 예시 (.base 파일)
filters:
  and:
    - file.folder.startsWith("projects/{name}")
    - status == "draft"
```

## 기록 규칙

### 언제, 어디에

| 상황 | 위치 |
|------|------|
| TODO, 간단한 메모, 회의 메모 | 당일 저널 `journals/YYYY-MM-DD.md` |
| 트러블슈팅 완료 (조사+결론 있음) | `projects/{name}/troubleshoot/{제목}.md` |
| 중요 결정 확정 | `projects/{name}/decision/{제목}.md` |
| QA 체크리스트/결과 | `projects/{name}/qa/{제목}.md` |
| 기능 스펙/요구사항 정리 | `projects/{name}/spec/{제목}.md` |
| 배포 실패/인프라 이슈 | `projects/{name}/incident/{제목}.md` |
| 장기 추적 이슈 | `projects/{name}/issue/{제목}.md` |
| 새 도메인 개념 | `know/{개념명}.md` |
| 기타 필요 시 | 새 폴더 자유 생성 |

### 저널 → 페이지 승격

저널에서 시작한 이슈가 깊어지면 별도 페이지로 승격하고 저널에서 링크:

```
- [x] {설명} #pj-{project}
	- -> [[{type}/{제목}]]
```

승격 시 기존 `[ ]`를 `[x]`로 변경한다.

### 회의/슬랙 대화 → 문서화

회의록이나 슬랙 대화가 붙여넣어지거나 Slack 채널을 조회한 결과를 기록할 때:

**저널에 남기는 것** (휘발적, 1줄 요약 + 링크):
- 단순 행정 (도메인 후보, 일정 조율, 확인 요청)
- 이미 namespace 페이지가 있는 주제의 상태 업데이트

**namespace 페이지로 승격하는 것** (구조화된 지식):
- 아키텍처/설계 흐름이 정리된 내용 → `spec/`
- 결정사항이 포함된 내용 → `decision/`
- 새로운 기술적 제안/비교 → `reference/` 또는 `spec/`

**판단 기준**: 이 내용이 1주일 뒤에도 다시 참조될 가능성이 있는가?
- Yes → namespace 페이지로 승격. 저널에는 `[x]` + `-> [[링크]]`만 남긴다
- No → 저널에 1줄 요약 + Slack 딥링크

## namespace 페이지 작성 규격

### namespace 소속 판단

| 기준 | 위치 | 예시 |
|------|------|------|
| 특정 프로젝트에 종속 | `projects/{name}/{type}/{제목}.md` | `projects/foo/decision/배포 전략.md` |
| 프로젝트 무관 범용 | `{type}/{제목}.md` | `decision/Git worktree 운용 원칙.md` |
| 순수 개념 | `know/{개념명}.md` | `know/스테이블코인.md`, `know/온오프램프.md` |

**판단 기준**: 이 문서가 특정 프로젝트 없이 의미가 있는가?
- No → `projects/{name}/{type}/{제목}.md` (대부분의 decision, troubleshoot, debrief, qa, spec, incident)
- Yes → `{type}/{제목}.md`

### 문서 간 의존 방향

안정도: 개념(L0) > 결정/스펙(L1) > 이벤트(L2) > 저널/세션(L3)

- **의존은 항상 안정한 쪽을 향한다** — L3→L2→L1→L0
- 저널/세션이 decision이나 concept을 `[[링크]]`로 참조 → OK
- concept이 session을 참조 → NG
- 같은 계층 간 참조 → OK (decision ↔ decision)

### 깊이 제한

- 최대 3 segment: `projects/{name}/{type}/{제목}.md`
- 4단 이상 금지
- 프로젝트 허브 페이지 `projects/{name}/pj-{name}.md`에서 Bases/Dataview로 하위 집계

### 파일 네이밍

- 프로젝트 종속: `projects/{name}/{type}/{제목}.md` (비활성 프로젝트는 `archive/{name}/{type}/{제목}.md`)
- 프로젝트 무관: `{type}/{제목}.md`
- 개념: `know/{제목}.md`
- 저널: `journals/YYYY-MM-DD.md`
- 제목: 한국어 설명적 제목, 간결하게
- **표준 markdown 형식** — heading은 `#`/`##`/`###` 그대로 사용. body의 list/checklist만 `- ` 사용. **`- # 헤딩`, `- ## 하위`처럼 bullet과 heading 결합은 logseq outliner 잔재 — 금지** (vault의 `~/Documents/obsidian/CLAUDE.md` 규약 + `scripts/migrate-outliner-to-markdown.rb`로 마이그레이션 진행 중)
- 체크리스트는 `- [ ]/[x]/[/]/[-]` (Obsidian Tasks 호환). `TODO`/`DONE` 키워드 금지

### 필수 frontmatter

```yaml
---
project: pj-{name}
date: YYYY-MM-DD
status: {상태}
---
```

- `type`은 폴더로 이미 구분되므로 별도 frontmatter key 불필요
- `date`가 저널 링크 역할을 겸함 — 본문에서 저널 중복 참조하지 않는다
- `project` value는 plain string (마이그레이션 시 `[[]]` 제거됨)

### 선택 frontmatter (freshness)

```yaml
---
last-verified: YYYY-MM-DD
next-check: YYYY-MM-DD
---
```

- `last-verified`: 이 문서의 내용이 마지막으로 정확하다고 확인된 날짜
- `next-check`: 다음 확인이 필요한 날짜
- 적용 대상: issue, troubleshoot(investigating), incident(open) 등 active 상태 namespace 페이지
- resolved/closed/done이면 불필요
- issue 페이지에서는 `next-check` 기본 7일 후 설정

### 카테고리별 템플릿

**헤딩 규칙**: 표준 markdown `# 섹션명` / `## 하위 섹션` 사용. bullet 결합(`- # ...`, `- ## ...`)은 logseq 잔재이며 금지. body의 list/checklist만 `- ` 사용.

#### troubleshoot

status: open / investigating / resolved / wontfix

```markdown
---
project: pj-{name}
date: YYYY-MM-DD
status: investigating
---
# 상황

# 조사

# 근본 원인

# 결정

# 관련 자료
```

#### decision

status: proposed / accepted / rejected / superseded

```markdown
# 맥락

# 선택지

# 결정

# 근거
```

#### qa

status: draft / in-progress / done

```markdown
# 대상

# 체크리스트

- 그룹명
    - [ ] 항목

# 결과
```

#### spec

status: draft / agreed / implemented / deprecated

```markdown
# 배경

# 요구사항

# 범위
```

#### incident

status: open / resolved / recurring

```markdown
# 상황

# 타임라인

# 원인

# 대응

# 재발 방지
```

#### issue

status: open / in-progress / waiting / blocked / resolved / closed

선택 frontmatter: `owner`, `stakeholders`, `last-verified`, `next-check`

```markdown
# 상황

# 커뮤니케이션 로그

# 진행 상황

# 관련 자료
```

커뮤니케이션 로그 형식:

```markdown
# 커뮤니케이션 로그

- YYYY-MM-DD {채널: slack/email/meeting/call/github} {상대방}
    - 질문/요청 내용
    - 응답/결과
    - → 상태 변화: {이전} → {이후}
```

troubleshoot과의 차이: troubleshoot은 한 번의 조사→해결 사이클. issue는 장기 추적 — 복수 사이클, 커뮤니케이션 축적, 상태 변화 이력.

#### 새 카테고리

템플릿 없이 폴더만 만들어도 됨. 공통 frontmatter + 자유 형식.

## 작업 산출물 저장

- raw 데이터 (JSON, 스크린샷, 로그 등) → `assets/` 디렉토리에 저장
- namespace 페이지에서 `![](assets/{파일명})` 또는 경로 텍스트로 참조

### 바이너리 첨부(PDF·PPTX·이미지) 링크·임베드

외부 산출물(PDF 설계서, PPTX, 이미지)을 vault로 가져올 때:

- **보존**: `projects/{name}/assets/`(필요 시 하위 분류 폴더)에 원본 복사. binary는 `.gitignore` whitelist로 git 제외되지만 디스크 보존 — Obsidian에서 열람·임베드는 가능.
- **클릭 가능한 링크는 wikilink로**: `[[파일명.pdf]]`. 백틱 경로(`` `path/x.pdf` ``)는 **코드 텍스트라 클릭 불가** — 링크는 wikilink로, 경로 안내가 목적일 때만 백틱.
    - PDF → 클릭 시 Obsidian **내장 뷰어로 inline** 열림.
    - PPTX·docx 등 미지원 포맷 → 클릭 시 **시스템 기본 앱**(Keynote/PowerPoint)으로 외부 열림(Obsidian 미리보기 불가).
- **특정 페이지 참조 (PDF)**:
    - 링크(점프): `[[파일.pdf#page=N]]`. **표 셀 안에선 alias 파이프를 escape** → `[[파일.pdf#page=N\|표시텍스트]]` (안 하면 `|`가 열 구분자로 깨짐).
    - 임베드(인라인 렌더): `![[파일.pdf#page=N]]` (`#page=N&height=500` 높이 옵션).
- **임베드 절제 원칙**: 임베드는 **핵심 화면만**. 화면별 상세가 많이 필요하면 요약 문서에 쌓지 말고 **화면 그룹 단위로 별도 문서를 잘라** 임베드한다. 요약·색인 문서는 페이지 **링크**로 가볍게 유지.
- **렌더 한계**: git 제외 binary는 **로컬 Obsidian에서만** 링크·임베드가 렌더링(GitHub·타 머신 X). 텍스트가 어디서나 필요하면 `pdftotext -f N -l N <pdf> <out>`로 해당 페이지 텍스트만 떠서 코드블록으로 박제.
- **페이지→위치 매핑**: 슬라이드 PDF에서 화면 ID별 페이지를 찾을 땐 `pdftotext -layout`로 텍스트를 떠서 화면 ID 라벨을 page와 함께 추출(페이지 많은 PDF를 이미지로 직접 읽는 것보다 저렴).

## 작성 후 필수 작업

페이지 작성이 완료되면 아래 3단계를 순서대로 수행한다.

**예외**: 자동화 hook(session sync 등)에서 호출되는 경우 Step 1, 2는 생략하고 Step 3만 실행한다. 사용자가 직접 `/obsidian-write`를 호출하거나 `/debrief` 등 사용자 initiated skill에서 호출할 때만 Step 1, 2를 수행한다.

### Step 1: 미생성 키워드 제안

작성한 페이지에서 `[[링크]]`로 감싼 키워드를 모두 추출하고, 실제 페이지가 없는 것을 식별한다.

**추출 대상에서 제외:**
- frontmatter value: `project`, `date` 등의 값으로 쓰인 링크 (이미 plain string)
- 저널 날짜: `[[YYYY-MM-DD]]` 패턴
- 프로젝트 태그: `[[pj-*]]` 패턴
- namespace 자기 참조: 작성 중인 페이지 자신

**페이지 존재 확인** (Obsidian wikilink는 path-aware):

```bash
# 일반 개념 페이지
test -f ~/Documents/obsidian/know/{키워드}.md

# namespace 페이지 (경로 그대로)
test -f ~/Documents/obsidian/{type}/{제목}.md
test -f ~/Documents/obsidian/projects/{name}/{type}/{제목}.md
```

**미생성 키워드가 있으면** 사용자에게 목록을 보여주고 확인을 요청한다:

```
다음 키워드가 아직 페이지로 존재하지 않습니다:
- [[키워드A]] — 본문에서 {사용 맥락 한 줄}
- [[키워드B]] — 본문에서 {사용 맥락 한 줄}

생성할 키워드를 선택해주세요 (전체/일부/스킵).
```

사용자가 선택하면 개념 페이지를 Atomic Notes 원칙에 따라 `know/`에 생성한다:

```markdown
---
aliases: [{영문 또는 대체 표현}]
description: {한 줄 설명}
---
- {원래 페이지에서의 사용 맥락을 기반으로 1-2줄 기본 내용}
- 관련: [[원래 작성한 페이지]]
```

### Step 2: 관련 개념 능동 탐색

작성된 페이지의 핵심 키워드 3-5개를 추출하여 `ir search`로 관련 기존 페이지를 탐색한다.

**키워드 추출 기준:**
- 페이지 제목의 핵심어
- 본문에서 반복 등장하는 도메인 용어
- 이미 `[[링크]]`로 연결한 것은 **제외**

**탐색 실행:**

```bash
ir search "{키워드}" -n 5 --files
```

**결과 필터링:**
- 이미 본문에서 `[[링크]]`로 연결한 페이지는 제외
- 자기 자신, 저널 페이지(`journals/`) 제외

**관련 페이지가 있으면** 사용자에게 연결을 제안한다.

### Step 3: 인덱스 갱신

```bash
ir update
```

```bash
ir embed
```

Step 1에서 새 페이지가 생성되었을 수 있으므로, 반드시 모든 작업 완료 후 마지막에 실행한다.

### Step 4: 학습 질문 생성

작성한 내용에 도메인 개념이 포함되어 있으면 사용자에게 2-3개의 학습 질문을 제시한다. soul.md의 능동 학습 원칙 실행 단계.

**트리거 조건** (하나 이상 해당):
- 새 도메인 개념이 등장 (미생성 키워드, 또는 기존 개념의 새로운 맥락)
- spec, decision 등 판단이 수반되는 내용
- 외부 산출물(Slack, 문서, 기사)을 정리한 경우

**스킵 조건**:
- 단순 TODO 상태 변경, 저널 행정 기록
- 자동화 hook에서 호출된 경우 (session sync 등)
- 사용자가 "바로 해"라고 지시한 경우

**질문 설계 원칙**:
- 개념 확인: "X가 이 맥락에서 어떤 역할을 하는지 감이 오세요?"
- 연결: "X와 기존에 알던 Y의 관계가 보이시나요?"
- 판단: "이 결정/제안의 trade-off가 뭘까요?"
- 실무 적용: "이게 우리 프로젝트의 Z에 어떻게 영향을 줄까요?"

**형식**: 질문 2-3개를 번호로 제시. 사용자가 답하면 보완/확장하고, 개념 페이지에 사용자의 이해를 반영. "스킵"하면 넘어간다.
