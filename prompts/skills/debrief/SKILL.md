---
name: debrief
description: 코드 작업 완료 후 변경 내러티브 문서 생성. 변경 요약, 설계 판단 근거, 학습 포인트를 vault에 기록. Vault 위치/매핑은 `documentation` skill, 형식은 `obsidian-write` 참조. Use when completing code work, after PR creation, reviewing what was done, or wanting to document changes for learning. /debrief, 작업 정리, 변경 기록, 회고.
user-invocable: true
argument-hint: "[branch-or-pr]"
---

# Debrief — 변경 내러티브 문서 생성

코드 작업 완료 후 **왜 이렇게 했는지**, **전체 그림**, **학습 포인트**를 구조화하여 vault에 기록한다.
diff만으로는 파악하기 어려운 설계 판단과 맥락을 문서화하는 것이 목적.

## Phase 1: 변경 분석

### 대상 결정

- `$ARGUMENTS`가 있으면 해당 branch 또는 PR을 대상으로 분석
  - PR 번호: `gh pr view {number} --json headRefName` → branch 추출
  - branch 이름: 그대로 사용
- `$ARGUMENTS`가 없으면 현재 branch의 `main..HEAD` 분석

### 데이터 수집

다음을 병렬로 수집:

```bash
# 커밋 히스토리
git log {base}..HEAD --oneline --no-decorate

# 변경 파일 요약
git diff {base}..HEAD --stat

# 실제 변경 내용
git diff {base}..HEAD

# PR 정보 (있으면)
gh pr view --json title,body,url,number
```

### 추가 컨텍스트

- `.claude/plans/` 에 plan 파일이 있으면 읽어서 설계 의도 파악
- `.claude/designs/` 에 설계 문서가 있으면 참조
- 현재 세션의 대화 히스토리에서 논의/판단 맥락 추출

## Phase 2: 문서 생성

수집한 데이터를 기반으로 Obsidian 페이지 내용을 구성한다.

### 페이지 구조

파일명: `know/pj-{name}___debrief___{제목}.md`

```
project:: [[pj-{name}]]
date:: [[YYYY-MM-DD]]
status:: done
branch:: {branch-name}
pr:: PR {number}

- # Summary
  - {2-3줄 변경 요약 — 무엇을 왜}
- # Changes
  - {파일/모듈별 변경 그룹핑}
    - {각 변경의 의도 설명}
- # Decisions
  - {설계 판단과 트레이드오프}
    - 왜 이 방식을 선택했는지, 대안은 무엇이었는지
- # Learned
  - {사용된 패턴, 라이브러리, 기법 중 학습 가치 있는 것}
- # Related
  - {PR 링크, 관련 이슈, 참고 자료를 [[링크]]로}
```

### 작성 원칙

- **Changes**: 파일 나열이 아닌 모듈/기능 단위로 그룹핑. 각 그룹에 "왜 이 변경이 필요했는지" 한 줄 설명
- **Decisions**: diff에서 드러나지 않는 판단을 기록. "A 대신 B를 선택한 이유" 형식
- **Learned**: 범용적으로 재사용 가능한 지식만. 프로젝트 특수한 내용은 Changes에
- **Related**: 관련 Obsidian 페이지를 `ir search`로 찾아 `[[링크]]`로 연결
- pr 프로퍼티: PR이 없으면 생략
- Logseq outliner 형식 준수 (`- ` prefix)
- `#태그` 대신 `[[링크]]` 사용

## Phase 2.5: Issue 교차 참조

debrief 내용 생성 후, 관련 open issue 페이지를 탐색:

1. `ir search --mode bm25 "{branch name 또는 PR title}" -n 5 --files`
   - 매칭이 적으면 프로젝트명 + 핵심 키워드로 재검색: `ir search --mode bm25 "pj-{name} {키워드}" -n 5 --files`
2. 결과에서 `issue___` namespace + status:: open/in-progress/waiting 페이지 필터
3. 매칭된 issue 페이지가 있으면:
   - "진행 상황" 섹션에 날짜 + debrief 링크 추가
   - `last-verified::` 오늘 날짜로 갱신
   - 작업이 이슈를 해결했으면 status 변경 제안
4. 매칭 없으면 스킵 (모든 작업이 issue와 관련되는 것은 아님)

## Phase 3: 저장

### Obsidian 페이지 생성

`/obsidian-write` skill의 규격을 따라 페이지를 생성한다:

1. `~/Documents/obsidian/know/pj-{name}___debrief___{제목}.md` 에 페이지 작성 (프로젝트 하위 namespace)
2. 당일 저널에 링크 추가:
   ```
   - DONE {작업 요약} #pj-{project}
     - -> [[pj-{name}/debrief/{제목}]]
   ```
3. `ir search`로 관련 기존 페이지를 찾아 Related 섹션에 `[[링크]]` 연결

### 인덱스 갱신

```bash
ir update
```

```bash
ir embed
```

## 중요 원칙

1. **diff 너머의 맥락**: 코드만 보면 알 수 없는 "왜"를 기록한다. 변경 자체가 아닌 변경의 이유가 핵심
2. **학습 자산화**: Learned 섹션은 미래의 나를 위한 것 — 범용적이고 재사용 가능한 지식만 포함
3. **연결 우선**: 고립된 문서가 아닌 vault의 일부로 — 관련 페이지와 반드시 `[[링크]]` 연결
4. **간결함**: 각 섹션은 핵심만. 장황한 설명보다 "A 대신 B, 이유: C" 형식이 효과적

## Examples

### 현재 branch 작업 정리
```
User: "/debrief"
→ Phase 1: git log main..HEAD, git diff 분석
→ Phase 2: 변경 내러티브 구성
→ Phase 3: Logseq debrief/ 페이지 생성 + 저널 링크
```

### PR 기반 debrief
```
User: "/debrief 42"
→ Phase 1: gh pr view 42 → branch 추출 → diff 분석
→ Phase 2: PR description + diff 기반 내러티브 구성
→ Phase 3: Logseq debrief/ 페이지 생성 (pr:: PR 42 포함)
```

### branch 지정 debrief
```
User: "/debrief feature/add-eval-patterns"
→ Phase 1: git log main..feature/add-eval-patterns 분석
→ Phase 2: 변경 내러티브 구성
→ Phase 3: Logseq debrief/ 페이지 생성
```
