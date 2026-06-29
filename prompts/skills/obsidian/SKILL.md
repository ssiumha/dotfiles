---
name: obsidian
description: Mutate Obsidian vault files through the running Obsidian app via the `obsidian` CLI — move/rename (auto-updates backlinks & [[wikilinks]]), set/read/remove frontmatter properties, toggle task checkboxes, append/prepend, delete, create from template, and graph analysis (backlinks, orphans, unresolved, tags). Use when moving or renaming vault notes, editing frontmatter, toggling tasks, or any change that must keep links intact. Do NOT use for reading/searching content (use `ir`, no app needed) or for composing page bodies/conventions (use `obsidian-write`).
allowed-tools: Bash(obsidian:*)
---

# obsidian — vault file mutation via the running app

`obsidian` CLI는 **실행 중인 Obsidian 앱**에 명령을 전달한다. 디스크를 직접 읽는 `ir`과 달리 앱의 `fileManager`를 경유하므로 `move`/`rename` 시 백링크·`[[wikilink]]`가 자동 갱신된다 — 이것이 `mv`/`Edit` 대비 핵심 가치다.

## Preconditions

- **앱이 실행 중**이어야 한다 (CLI는 앱에 명령을 전달). 미실행 시 명령 실패.
- vault가 여러 개면 `vault=<name>`으로 지정. 기본은 활성 vault.

Status: !`obsidian vaults verbose 2>/dev/null || echo "Obsidian app not running — start it first"`

## 인자 규칙

- `file=<name>` — 이름으로 해석 (wikilink처럼). `path=<folder/note.md>` — 정확한 경로.
- file/path 생략 시 대부분 **활성 파일** 대상.
- 공백 값은 인용: `name="My Note"`. 내용에 `\n` `\t` 사용 가능.

## CLI Quick Reference

### 이동 · 이름변경 (링크 자동 갱신)

```bash
obsidian move file="Old Note" to="archive/2026"      # 폴더로 이동
obsidian move path=inbox/note.md to=projects/foo/note.md  # 경로 변경
obsidian rename file="Old Name" name="New Name"      # 이름만 변경
```

### Frontmatter (properties)

```bash
obsidian property:set name=status value=done file="My Note"
obsidian property:set name=tags value="a,b" type=list path=projects/foo.md
obsidian property:read name=status file="My Note"
obsidian property:remove name=draft file="My Note"
obsidian properties active                           # 활성 파일 속성 목록
```
`type=text|list|number|checkbox|date|datetime`.

### Task 토글

```bash
obsidian task ref=projects/foo.md:42 toggle           # 상태 토글
obsidian task ref=projects/foo.md:42 done             # 완료로
obsidian task ref=projects/foo.md:42 status="/"       # 임의 상태 문자
obsidian tasks todo path=projects/foo.md verbose      # 미완료 목록 (line 번호 포함)
obsidian tasks done active                            # 활성 파일 완료 task
```

### 내용 추가 · 생성 · 삭제

```bash
obsidian append file="My Note" content="- new line"
obsidian prepend path=daily/2026-06-02.md content="..."
obsidian create name="New Note" template=meeting open
obsidian delete file="Scratch"                        # 휴지통
obsidian delete path=tmp/x.md permanent               # 영구 삭제
```

### 그래프 분석 (read-only)

```bash
obsidian backlinks file="My Note" counts              # 들어오는 링크
obsidian links file="My Note"                         # 나가는 링크
obsidian orphans                                      # 들어오는 링크 없는 파일
obsidian unresolved verbose                           # 깨진 wikilink + 출처
obsidian tags counts sort=count                       # 태그 빈도
```

### 데일리 노트

```bash
obsidian daily:append content="- [ ] 할 일 #pj-foo"
obsidian daily:read
obsidian daily:path
```

## Examples

### inbox 노트를 프로젝트로 이동 (링크 유지)
```
User: "이 노트 projects/foo로 옮겨줘"
-> obsidian move file="노트" to=projects/foo
-> 백링크·wikilink 자동 갱신됨 (Edit/mv와 차이)
```

### 저널 task 완료 처리
```
User: "어제 저 작업 done으로 바꿔줘"
-> obsidian tasks todo path=daily/2026-06-01.md verbose   # line 확인
-> obsidian task ref=daily/2026-06-01.md:12 done
```

### frontmatter 상태 갱신
```
User: "이 이슈 페이지 last-verified 오늘로"
-> obsidian property:set name=last-verified value=2026-06-02 type=date file="이슈 제목"
```

## Principles

1. **링크 보존이 목적이면 `obsidian move`/`rename`** — `mv`/`Edit`은 wikilink를 깨뜨린다.
2. **읽기·검색은 `ir`로** — 앱 불필요, 빠름. obsidian CLI는 앱 의존이라 변형 작업에만 쓴다.
3. **페이지 본문 작성 규약(frontmatter/checkbox/namespace)은 `obsidian-write`** 참조 — 이 skill은 명령 실행만.
4. **파괴적 작업 전 대상 확인** — `delete permanent`, 대량 `move`는 먼저 `file`/`backlinks`로 점검.
5. **task 토글 전 line 번호 확인** — `obsidian tasks ... verbose`로 `path:line`을 먼저 얻는다.
6. **`vault=` 명시** — 여러 vault 환경에서 잘못된 vault에 쓰지 않도록.
```