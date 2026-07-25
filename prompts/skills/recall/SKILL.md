---
name: recall
description: >-
  Load context from Obsidian vault (journals, session pages) and JSONL session history.
  Vault 위치/구조는 `documentation` skill 참조. Temporal queries scan JSONL by date, topic queries use ir BM25.
  Use when "recall", "어제 뭐 했지", "what did we work on", "이전 작업", "session history".
argument-hint: "[yesterday|today|last week|TOPIC|index]"
allowed-tools: Bash(ruby:*), Bash(ir:*)
---

# Recall — Session History + Vault Knowledge

세션 이력과 vault 지식을 통합 검색하는 skill.

## Scripts

```
~/dots/prompts/skills/recall/scripts/
├── recall_common.rb         # 공유 유틸리티
├── extract-session.rb       # JSONL → Obsidian 페이지 변환
├── recall-day.rb            # 날짜 기반 세션 조회
├── recall-index.rb          # 배치 인덱싱
├── session-journal.rb       # 당일 저널 세션 stamp (sid당 한 줄, 기간 연장)
├── post-session-hook.rb     # SessionEnd hook (추출 → 저널 stamp → ir update)
└── session-context.rb       # SessionStart hook (세션 index 자동 주입)
```

## Workflows

### 1. Temporal — 날짜로 세션 조회

트리거: `yesterday`, `today`, `last week`, `N days ago`, `YYYY-MM-DD`

```bash
ruby ~/dots/prompts/skills/recall/scripts/recall-day.rb list {date_expr}
```

결과에서 세션 목록 + 저널 내용을 보여준다.
특정 세션을 상세 보려면:

```bash
ruby ~/dots/prompts/skills/recall/scripts/recall-day.rb expand {N} {date_expr}
```

### 2. Topic — 키워드로 통합 검색

트리거: 시간 표현이 아닌 키워드 (예: "bean wiring", "transfer API")

**대체 표현 병렬 검색**: 사용자의 키워드로부터 3-4개의 대체 표현을 생성하고, 병렬로 `ir search --mode bm25`를 실행한다. 사용자의 기억과 실제 저장된 표현이 다를 수 있기 때문.

```bash
# 병렬 실행 (각각 별도 Bash 호출)
ir search --mode bm25 "{원본 키워드}" -n 5
ir search --mode bm25 "{대체 표현 1}" -n 5
ir search --mode bm25 "{대체 표현 2}" -n 5
ir search --mode bm25 "{대체 표현 3}" -n 5
```

결과를 document path 기준으로 dedup하여 상위 10개를 보여준다.
세션 페이지(`session/`)와 기존 vault 지식을 동시에 검색한다.

더 높은 품질이 필요하면 (시맨틱 검색):

```bash
ir search "{question}" -n 10
```

### 3. Index — 배치 추출 + 인덱싱

트리거: `/recall index`

```bash
ruby ~/dots/prompts/skills/recall/scripts/recall-index.rb [--days N] [--force] [--dry-run]
```

미추출 세션을 Obsidian 페이지로 변환하고 `ir update` + `ir embed` 실행.

## One Thing

모든 recall 결과 끝에, 세션 이력과 맥락을 종합하여 **다음으로 해야 할 가장 임팩트 있는 한 가지 행동**을 제안한다.

- 모멘텀, 블로커, 완료도를 고려
- 구체적이고 실행 가능한 제안 (일반적인 조언이 아닌)
- "Based on your sessions, the one thing to focus on: ..."

## Session Sync Hooks

`~/.claude/settings.json`에 등록된 세션 sync:

| Hook | 동작 |
|------|------|
| `SessionStart` | 프로젝트별 최근 세션 index 자동 주입 (compact 이벤트 시 생략 — WIP 복원 훅이 대체) |
| `SessionEnd` | JSONL → 세션 페이지 추출 → 당일 저널 stamp → `ir update` |

SessionStart 자동 주입은 `CLAUDE_RECALL_AUTO_INJECT=0`으로 비활성화 가능.
기존 페이지가 있으면 idempotent하게 업데이트하며, 사용자가 vault에서 추가한 섹션/프로퍼티는 보존된다.

## Session Page Format (Obsidian)

파일 위치: `.session/YYYY-MM/YYYY-MM-DD/YYYY-MM-DD {slug} {sid8}.md`

```markdown
---
project: session-{name}
date: 'YYYY-MM-DD'
status: archived
session-id: {sid8}
messages: '{count}'
exclude-from-graph-view: 'true'
---

# Summary

# Conversation

# Files
```

`status` 프론트매터(active/archived)로 필터. graph view에서는 제외된다.
