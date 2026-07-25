---
name: debrief
description: 코드 작업 완료 후 변경 내러티브 문서 생성. 변경 요약, 설계 판단 근거, 학습 포인트를 vault에 기록. Vault 위치/매핑은 `documentation` skill, 형식은 `obsidian-write` 참조. Use when completing code work, after PR creation, reviewing what was done, or wanting to document changes for learning. /debrief, 작업 정리, 변경 기록, 회고.
user-invocable: true
argument-hint: "[branch-or-pr]"
---

# Debrief — 변경 내러티브 문서 생성

코드 작업 완료 후 **왜 이렇게 했는지**, **전체 그림**, **학습 포인트**를 구조화하여 vault에 기록한다.
diff만으로는 파악하기 어려운 설계 판단과 맥락의 문서화가 목적. **경량 실행이 원칙** — 부가 파이프라인(미생성 키워드 제안, 관련 개념 탐색, 학습 질문, `ir embed`)은 수행하지 않는다.

## Phase 1: 변경 분석

- 대상: `$ARGUMENTS`가 PR 번호면 `gh pr view {n} --json headRefName`으로 branch 추출, branch명이면 그대로, 없으면 현재 branch의 `main..HEAD`
- 수집 (병렬): `git log {base}..HEAD --oneline --no-decorate`, `git diff {base}..HEAD --stat`, `git diff {base}..HEAD`, PR 있으면 `gh pr view --json title,body,url,number`
- 추가 맥락: `.claude/plans/`·`.claude/designs/` 문서, 현재 세션 대화의 논의/판단

## Phase 2: 문서 생성

파일명: `projects/{name}/debrief/{제목}.md`

```markdown
---
project: pj-{name}
date: YYYY-MM-DD
status: done
branch: {branch-name}
pr: {number}
---
# Summary

{2-3줄 변경 요약 — 무엇을 왜}

# Changes

## {모듈/기능 그룹}

- {각 변경의 의도 설명}

# Decisions

- {설계 판단과 트레이드오프 — "A 대신 B, 이유: C" 형식}

# Learned

- {사용된 패턴, 라이브러리, 기법 중 학습 가치 있는 것}

# Related

- {PR 링크, 관련 이슈, 참고 자료를 [[링크]]로}
```

작성 원칙:
- **Changes**: 파일 나열이 아닌 모듈/기능 단위 그룹핑 + "왜 필요했는지" 한 줄
- **Decisions**: diff에서 드러나지 않는 판단만 — "A 대신 B를 선택한 이유"
- **Learned**: 범용 재사용 가능한 지식만. 프로젝트 특수사항은 Changes로
- 표준 markdown heading (`- #` 결합 금지), `#태그` 대신 `[[링크]]`, pr 프로퍼티는 PR 없으면 생략

## Phase 3: 연결 + 저장

1. **ir search 1회**: `ir search --mode bm25 "{branch 또는 PR title 핵심 키워드}" -n 5 --files` — 결과에서:
   - 관련 페이지 → Related 섹션에 `[[링크]]`
   - open 상태 `issue/` 페이지 → "진행 상황"에 날짜 + debrief 링크 추가, `last-verified` 갱신, 해결됐으면 status 변경 제안
   - 매칭 없으면 스킵
2. 페이지 저장 후 당일 저널에 링크:
   ```
   - [x] {작업 요약} #pj-{project}
       - -> [[{제목}]]
   ```
3. `ir update` (`ir embed`는 생략 — `/recall index` 배치가 수행)

obsidian-write의 "작성 후 필수 작업" 중 Step 1(미생성 키워드)·2(관련 개념 탐색)·4(학습 질문)는 생략한다.

## 중요 원칙

1. **diff 너머의 맥락**: 변경 자체가 아닌 변경의 이유가 핵심
2. **학습 자산화**: Learned는 미래의 나를 위한 범용 지식만
3. **연결 우선**: ir search 1회로 찾은 관련 페이지와 반드시 `[[링크]]`
4. **간결함**: "A 대신 B, 이유: C" 형식. 장황한 설명 금지

## Example

```
User: "/debrief 42"
→ gh pr view 42 → branch 추출 → diff 분석
→ 내러티브 구성 (Summary/Changes/Decisions/Learned)
→ ir search 1회 (Related + issue 교차)
→ 페이지 저장 + 저널 링크 + ir update
```
