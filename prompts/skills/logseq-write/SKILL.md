---
name: logseq-write
description: Writes Logseq pages following conventions. Use when creating namespace pages (troubleshoot, decision, qa, spec, incident), writing journal entries, promoting journal to pages, or editing existing Logseq pages. Do NOT use for reading/searching (use qmd directly).
---

## Atomic Notes 원칙

- 하나의 개념 = 하나의 페이지. 프로젝트에 종속되지 않는 범용 개념으로 작성
- 프로젝트 특이사항은 같은 페이지에 `#pj-{name}` 태그와 함께 한 줄로 기술
- 구현 디테일(코드 위치, 엔티티, API)은 개념 페이지가 아닌 프로젝트 도메인 페이지에 작성
- 본문에 등장하는 도메인 용어는 `[[링크]]`로 연결 — 페이지가 없으면 생성 검토
- 편집 중 개념 페이지에 구현 디테일이 섞여 있으면 분리 제안

## 기존 패턴 (건드리지 않는다)

- 개념 페이지: `alias::` + `description::` 최상단, 내용은 outliner
- 본문에서 개념화된 용어는 `[[링크]]`로 그래프 연결 — `#태그`는 저널 TODO 행에서만 사용
- alias 값에 띄어쓰기 포함 시 `[[]]`로 감싼다 (예: `alias:: [[Single Page Application]]`)
- block reference: `((block-uuid))` — 원본 블록 인라인 참조
- block embed: `{{embed ((block-uuid))}}` — 원본 + 하위 자식 펼침
- 블록에 `id::` 프로퍼티(UUID v4) 부여하면 참조 대상
- 중복 내용 발견 시 block ref/embed 전환 제안
- 저널: `- TODO/DONE {설명} #pj-{프로젝트}`, 회의 메모
- 프로젝트 허브: `pj-{name}.md`에 `{{query}}`로 TODO 집계

## 연결 원칙

- **모든 문서는 최소 하나의 다른 문서와 연결**되어야 한다
- namespace 페이지 작성 시 `qmd search`로 관련 기존 페이지를 찾아 `[[링크]]`로 연결
- **namespace 페이지 생성 시 반드시 당일 저널에 링크 남기기**
  - 관련 저널 TODO가 있으면 DONE으로 변경하고 하위에 `-> [[{type}/{제목}]]` 링크 추가
  - 관련 TODO가 없으면 새 항목: `- DONE {설명} #pj-{project}` + `-> [[링크]]`
- namespace 페이지 간에도 관련 있으면 서로 링크
- `project::`, `date::` 프로퍼티 자체가 프로젝트 허브와 저널로의 연결
- 프로퍼티 값은 `[[link]]` 형태로 — plain text는 그래프 엣지를 만들지 않는다

## TODO 관리

### 라이프사이클

`TODO` → `DOING` → `DONE`

- 우선순위: `[#A]` / `[#B]` / `[#C]` (예: `TODO [#A] 긴급 수정`)
- 스케줄링: `SCHEDULED: <YYYY-MM-DD>` / `DEADLINE: <YYYY-MM-DD>`
- DOING 전환 — 저널 하단 NOW 쿼리에 자동 노출
- 취소: `DONE (취소: {사유})`

### `{{query}}` 문법

Simple query (Logseq 내장). Datalog 기반 advanced query와 별개.

```clojure
{{query (and (task TODO DOING) [[pj-{name}]])}}
```

**논리 연산자**: `and`, `or`, `not` — 중첩 가능

**필터**:
- `(task TODO DOING DONE)` — 태스크 상태 (공백 구분, 쉼표 아님)
- `(priority A B)` — 우선순위
- `(page <이름>)` — 특정 페이지 내 블록
- `(namespace <이름>)` — 네임스페이스 하위 페이지
- `(property <키> <값>)` — 프로퍼티 필터
- `(between <시작> <끝>)` — 날짜 범위 (저널 기준)
- `[[페이지]]` — 백링크/태그 필터 (쿼리 내에서는 `[[]]`만 사용)

**자주 쓰는 패턴**:

```clojure
;; 프로젝트 TODO 집계
{{query (and (task TODO DOING) [[pj-{name}]])}}

;; 우선순위별
{{query (and (task TODO DOING) (priority A) [[pj-{name}]])}}

;; 네임스페이스 하위 전체
{{query (namespace foo)}}

;; 프로퍼티 필터
{{query (and (property status draft) [[pj-{name}]])}}

;; 최근 7일 저널
{{query (between -7d today)}}
```

**주의**: 텍스트 검색은 대소문자 구분

## 기록 규칙

### 언제, 어디에

| 상황 | 위치 |
|------|------|
| TODO, 간단한 메모, 회의 메모 | 당일 저널 |
| 트러블슈팅 완료 (조사+결론 있음) | `pages/pj-{name}___troubleshoot___{제목}.md` |
| 중요 결정 확정 | `pages/pj-{name}___decision___{제목}.md` |
| QA 체크리스트/결과 | `pages/pj-{name}___qa___{제목}.md` |
| 기능 스펙/요구사항 정리 | `pages/pj-{name}___spec___{제목}.md` |
| 배포 실패/인프라 이슈 | `pages/pj-{name}___incident___{제목}.md` |
| 새 도메인 개념 | `pages/{개념명}.md` (기존 방식) |
| 기타 필요 시 | 새 namespace 자유 생성 |

### 저널 → 페이지 승격

저널에서 시작한 이슈가 깊어지면 별도 페이지로 승격하고 저널에서 링크:
```
- DONE {설명} #pj-{project}
	- -> [[{type}/{제목}]]
```

승격 시 기존 TODO를 DONE으로 변경한다.

### 회의/슬랙 대화 → 문서화

회의록이나 슬랙 대화가 붙여넣어지면:
1. 당일 저널에 원문 기록
2. 요구사항이 포함되면 `spec/`으로 승격
3. 결정사항이 포함되면 `decision/`으로 승격

## namespace 페이지 작성 규격

### namespace 소속 판단

| 기준 | namespace | 예시 |
|------|-----------|------|
| 특정 프로젝트에 종속 | `pj-{name}/{type}/{제목}` | `pj-foo/decision/배포 전략` |
| 프로젝트 무관 범용 | `{type}/{제목}` | `decision/Git worktree 운용 원칙` |
| 순수 개념 | 루트 `{개념명}` | `스테이블코인`, `온오프램프` |

**판단 기준**: 이 문서가 특정 프로젝트 없이 의미가 있는가?
- No → `pj-{name}/{type}/{제목}` (대부분의 decision, troubleshoot, debrief, qa, spec, incident)
- Yes → `{type}/{제목}` (루트)

### 문서 간 의존 방향

안정도: 개념(L0) > 결정/스펙(L1) > 이벤트(L2) > 저널/세션(L3)

- **의존은 항상 안정한 쪽을 향한다** — L3→L2→L1→L0
- 저널/세션이 decision이나 concept을 `[[링크]]`로 참조 → OK
- concept이 session을 참조 → NG
- 같은 계층 간 참조 → OK (decision ↔ decision)

### 깊이 제한

- 최대 2단: `pj-{name}/{type}/{제목}` (3 segment)
- `pj-{name}/{type}/{sub-type}/{제목}` 같은 4단 이상 금지
- 프로젝트 허브 페이지 `pj-{name}.md`는 `{{query (namespace pj-{name})}}` 로 하위 집계

### 파일 네이밍

- 프로젝트 종속: `pages/pj-{name}___{type}___{제목}.md` → Logseq에서 `pj-{name}/{type}/{제목}`로 표시
- 프로젝트 무관: `pages/{type}___{제목}.md` → Logseq에서 `{type}/{제목}`로 표시
- 제목: 한국어 설명적 제목, 간결하게
- 모든 콘텐츠는 outliner 형식 (`- ` prefix) 으로 작성
- 체크리스트는 `TODO`/`DONE` 키워드 사용. `[ ]`/`[x]` 마크다운 체크박스 사용 금지 (Logseq TODO 시스템과 통합되지 않음)

### 필수 프로퍼티

페이지 최상단에 Logseq 네이티브 문법:
```
project:: [[pj-{name}]]
date:: [[YYYY-MM-DD]]
status:: {상태}
```

- `type`은 namespace로 이미 구분되므로 별도 프로퍼티 불필요
- `date`가 저널 링크 역할을 겸함 — 본문에서 저널 중복 참조하지 않는다

### 카테고리별 템플릿

**헤딩 규칙**: `- # 섹션명` 은 최상위 구분에만 사용. 하위 그룹핑은 평문 라벨 + 들여쓰기. `##` 이상의 중첩 헤딩, 볼드 라벨 등 불필요한 마크업은 쓰지 않는다.

#### troubleshoot

status: open / investigating / resolved / wontfix

```
- # 상황
- # 조사
- # 근본 원인
- # 결정
- # 관련 자료
```

#### decision

status: proposed / accepted / rejected / superseded

```
- # 맥락
- # 선택지
- # 결정
- # 근거
```

#### qa

status: draft / in-progress / done

```
- # 대상
- # 체크리스트
	- 그룹명
		- TODO 항목
- # 결과
```

#### spec

status: draft / agreed / implemented / deprecated

```
- # 배경
- # 요구사항
- # 범위
```

#### incident

status: open / resolved / recurring

```
- # 상황
- # 타임라인
- # 원인
- # 대응
- # 재발 방지
```

#### 새 카테고리

템플릿 없이 namespace만 만들어도 됨. 공통 프로퍼티 + 자유 형식.

## 작업 산출물 저장

- raw 데이터 (JSON, 스크린샷, 로그 등) → Logseq `assets/` 디렉토리에 저장
- namespace 페이지에서 `![](../assets/{파일명})` 또는 경로 텍스트로 참조

## 작성 후 필수 작업

페이지 작성이 완료되면 아래 3단계를 순서대로 수행한다.

**예외**: 자동화 hook(session sync 등)에서 호출되는 경우 Step 1, 2는 생략하고 Step 3만 실행한다. 사용자가 직접 `/logseq-write`를 호출하거나 `/debrief` 등 사용자 initiated skill에서 호출할 때만 Step 1, 2를 수행한다.

### Step 1: 미생성 키워드 제안

작성한 페이지에서 `[[링크]]`로 감싼 키워드를 모두 추출하고, 실제 Logseq 페이지가 없는 것을 식별한다.

**추출 대상에서 제외:**
- 프로퍼티 값: `project::`, `date::` 등의 값으로 쓰인 링크
- 저널 날짜: `[[YYYY-MM-DD]]` 패턴
- 프로젝트 태그: `[[pj-*]]` 패턴
- namespace 자기 참조: 작성 중인 페이지 자신

**페이지 존재 확인:**

```bash
# 일반 페이지
test -f ~/Documents/logseq/pages/{키워드}.md

# namespace 페이지 (슬래시 → 트리플 언더스코어)
# [[pj-{name}/troubleshoot/제목]] → pages/pj-{name}___troubleshoot___제목.md
test -f ~/Documents/logseq/pages/{type}___{제목}.md
```

**미생성 키워드가 있으면** 사용자에게 목록을 보여주고 확인을 요청한다:

```
다음 키워드가 아직 Logseq 페이지로 존재하지 않습니다:
- [[키워드A]] — 본문에서 {사용 맥락 한 줄}
- [[키워드B]] — 본문에서 {사용 맥락 한 줄}

생성할 키워드를 선택해주세요 (전체/일부/스킵).
```

사용자가 선택하면 개념 페이지를 Atomic Notes 원칙에 따라 생성한다:

```markdown
alias:: {영문 또는 대체 표현이 있으면}
description:: {한 줄 설명 — 작성한 페이지의 맥락에서 추론}

- {원래 페이지에서의 사용 맥락을 기반으로 1-2줄 기본 내용}
- 관련: [[원래 작성한 페이지]]
```

### Step 2: 관련 개념 능동 탐색

작성된 페이지의 핵심 키워드 3-5개를 추출하여 `qmd search`로 관련 기존 페이지를 탐색한다.

**키워드 추출 기준:**
- 페이지 제목의 핵심어
- 본문에서 반복 등장하는 도메인 용어
- 이미 `[[링크]]`로 연결한 것은 **제외** (이미 연결됨)

**탐색 실행:**

```bash
qmd search "{키워드}" -n 5 --files
```

**결과 필터링:**
- 이미 본문에서 `[[링크]]`로 연결한 페이지는 제외
- 자기 자신, 저널 페이지(`journals/`) 제외

**관련 페이지가 있으면** 사용자에게 연결을 제안한다:

```
작성한 내용과 관련될 수 있는 기존 페이지:
- [[페이지A]] — {페이지 설명 또는 첫 줄}
- [[페이지B]] — {페이지 설명 또는 첫 줄}

본문에 연결을 추가할까요?
```

사용자가 선택하면 작성한 페이지의 적절한 위치에 `[[링크]]`를 추가한다.

### Step 3: 인덱스 갱신

```bash
qmd update
```

```bash
qmd embed
```

Step 1에서 새 페이지가 생성되었을 수 있으므로, 반드시 모든 작업 완료 후 마지막에 실행한다.
