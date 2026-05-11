---
name: documentation
description: 개인 지식 vault(Obsidian) 위치와 "어떤 작업을 어디에 기록하는가"의 단일 진실 소스. 다른 스킬(recall, debrief, intake, paper, standup, wakeup, vis-graph 등)이 vault 경로/매핑을 hardcoding하지 않도록 이 스킬을 참조한다. 형식 규약(frontmatter, checkbox, 링크, namespace 폴더화)은 obsidian-write 참조. Use when 다른 스킬에서 vault 위치 또는 namespace 매핑을 결정해야 할 때, 또는 vault 구조 자체를 점검·변경할 때.
---

## Vault 위치 (SoT)

- **Vault root**: `~/Documents/obsidian`
- 형식: Obsidian 호환 (frontmatter + folder-based namespace + wikilink)
- 검색 인덱스: `ir` CLI (BM25 + hybrid)
- 마이그레이션 이력: 2026-04-29 Logseq → Obsidian (`~/Documents/obsidian` → `~/Documents/obsidian`). 마이그레이션 도구는 `~/Documents/obsidian/scripts/migrate-to-obsidian.rb`

## 폴더 구조

```
~/Documents/obsidian/
├── journals/{YYYY-MM-DD}.md            일별 저널
├── session/{date} {slug} {sid}.md      Claude 세션 자동 sync (recall hook)
├── debrief/{제목}.md                    작업 회고 (debrief skill)
├── intake/{제목}.md                     외부 기사 검증 (intake skill)
├── paper/{단계}/{제목}.md               논문 연구 (paper skill)
├── troubleshoot/{제목}.md               범용 트러블슈팅
├── decision/{제목}.md                   범용 결정
├── qa/{제목}.md                         범용 QA
├── spec/{제목}.md                       범용 스펙
├── incident/{제목}.md                   범용 인시던트
├── issue/{제목}.md                      범용 장기 이슈
├── reference/{제목}.md                  참고 문서
├── guide/{제목}.md                      가이드
├── meetings/{제목}.md                   회의록
├── BCP/{제목}.md                        업무 연속성 계획
├── know/{개념}.md                       원자적 개념 페이지
├── concept/{개념}.md                    레거시 (know로 통합 권장)
├── projects/{name}/                     프로젝트 폴더 (active / 본업 / 자체 도구)
│   ├── pj-{name}.md                     프로젝트 허브 (각 폴더 내부)
│   ├── troubleshoot/{제목}.md
│   ├── decision/{제목}.md
│   ├── qa/{제목}.md
│   ├── spec/{제목}.md
│   ├── incident/{제목}.md
│   ├── issue/{제목}.md
│   ├── debrief/{제목}.md
│   ├── meeting/{제목}.md
│   └── investigation/{제목}.md
├── archive/{name}/                      비활성/완료 프로젝트 (동일 구조)
├── assets/                               첨부 (이미지·PDF·DOCX·XLSX)
└── scripts/                              vault 운영 Ruby 스크립트
    ├── doc-health.rb
    ├── doc-review.rb
    ├── migrate-to-obsidian.rb
    └── logseq/                           legacy (logseq 형식 시절)
```

## 작업별 기록 매핑

`pj-{name}`은 **태그 / wikilink 이름**(예: `#pj-sona`, `[[pj-sona]]`)으로만 사용하고, **폴더 경로는 `projects/{name}/`** 이다. wikilink는 basename match로 동작하므로 `[[pj-{name}]]`만 써도 자동 해석된다.

| 작업 | 위치 | 트리거 스킬 |
|------|------|-------------|
| 트러블슈팅 결과 | `projects/{name}/troubleshoot/{제목}.md` 또는 `troubleshoot/{제목}.md` | obsidian-write |
| 결정 기록 | `projects/{name}/decision/{제목}.md` 또는 `decision/{제목}.md` | obsidian-write |
| QA 체크리스트·결과 | `projects/{name}/qa/{제목}.md` | qa + obsidian-write |
| 스펙 정리 | `projects/{name}/spec/{제목}.md` | obsidian-write |
| 인시던트 | `projects/{name}/incident/{제목}.md` | obsidian-write |
| 장기 이슈 | `projects/{name}/issue/{제목}.md` | obsidian-write |
| 외부 기사 검증 | `intake/{제목}.md` | intake |
| 논문 연구 | `paper/{단계}/{제목}.md` | paper |
| 작업 회고 | `debrief/{제목}.md` 또는 `projects/{name}/debrief/{제목}.md` | debrief |
| 세션 자동 동기 | `session/{date} {slug} {sid}.md` | recall (hook) |
| 일별 저널 (TODO·메모) | `journals/YYYY-MM-DD.md` | wakeup, standup, recall |
| 개념 페이지 | `know/{개념명}.md` | obsidian-write |
| 프로젝트 허브 | `projects/{name}/pj-{name}.md` (또는 `archive/{name}/pj-{name}.md`) | obsidian-write |

## 형식 규약

페이지 형식(YAML frontmatter, checkbox `- [ ]/[x]/[/]/[-]`, wikilink `[[]]`, embed `![[]]`, block reference `^id`, outliner `- `)은 **obsidian-write** 스킬 참조.

## 점검 스크립트

- `ruby ~/Documents/obsidian/scripts/doc-health.rb --all` — 문서 건강 점검
- `ruby ~/Documents/obsidian/scripts/doc-review.rb` — 주간 리뷰
- 인덱스: `ir update`, `ir embed`

## 변경 정책

- **vault 위치 변경 시 이 문서만 갱신**한다. 다른 스킬은 이 문서를 참조하므로 자동 따라옴
- 새 폴더/namespace 추가 시 위 표 갱신
- legacy `logseq-write`는 deprecated, `obsidian-write` 사용

## 다른 스킬에서 참조하는 방법

스크립트(Ruby): `~/Documents/obsidian` 절대경로 직접 사용 (DI 대신 단일 path 합의). 변경 시 grep + 일괄 수정.

skill prompt: 본문에서 `documentation` skill을 referencing 한다.

```
vault 위치 / namespace 매핑 / 점검 스크립트는 `documentation` skill 참조.
페이지 형식은 `obsidian-write` skill 참조.
```
