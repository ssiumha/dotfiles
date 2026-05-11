---
name: recall
description: >-
  Load context from Obsidian vault (journals, session pages) and JSONL session history.
  Vault 위치/구조는 `documentation` skill 참조. Temporal queries scan JSONL by date, topic queries use ir BM25.
  Use when "recall", "어제 뭐 했지", "what did we work on", "이전 작업", "session history".
argument-hint: "[yesterday|today|last week|TOPIC|index]"
allowed-tools: Bash(ruby:*), Bash(ir:*)
---

# Recall — Session History + Logseq Knowledge

세션 이력과 vault 지식을 통합 검색하는 skill.

## Scripts

```
~/dots/prompts/skills/recall/scripts/
├── recall_common.rb         # 공유 유틸리티
├── extract-session.rb       # JSONL → Obsidian 페이지 변환
├── recall-day.rb            # 날짜 기반 세션 조회
├── recall-index.rb          # 배치 인덱싱
├── post-session-hook.sh     # Stop hook (자동 추출)
└── session-context.sh       # SessionStart hook (세션 요약 자동 주입)
```

## Workflows

### 1. Temporal — 날짜로 세션 조회

트리거: `yesterday`, `today`, `last week`, `N days ago`, `YYYY-MM-DD`

```bash
ruby ~/dots/prompts/skills/recall/scripts/recall-day.rb list {date_expr}
```

결과에서 세션 목록 + Logseq 저널 내용을 보여준다.
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

매 턴마다 점진적으로 세션을 vault에 sync하고, 세션 종료 시 상태를 마무리한다.
`~/.claude/settings.json`에 3개 hook 등록:

| Hook | 동작 | status |
|------|------|--------|
| `SessionStart` | 프로젝트별 최근 3개 세션 Summary 자동 주입 | — |
| `UserPromptSubmit` | 매 사용자 입력 시 sync | `active` |
| `Stop` | 응답 완료 시 sync | `active` |
| `SessionEnd` | 세션 종료 시 최종 sync | `archived` |

SessionStart 자동 주입은 `CLAUDE_RECALL_AUTO_INJECT=0`으로 비활성화 가능.
compact 이벤트 시에는 건너뜀 (WIP 복원 훅이 더 구체적).

기존 페이지가 있으면 idempotent하게 업데이트하며, 사용자가 vault에서 추가한 섹션/프로퍼티는 보존된다.

## Session Page Format (Logseq)

파일명: `session___YYYY-MM-DD {slug} {session-id-8자}.md`

```
project:: [[session-{name}]]
date:: YYYY-MM-DD
status:: archived
session-id:: {uuid-short}
messages:: {count}

- # Summary
- # Conversation
- # Files
```

`session/` namespace로 vault에 통합.
`(property status archived)` 쿼리로 필터 가능.
