### Skill Frontmatter 레퍼런스

`skills/{name}/SKILL.md`의 YAML frontmatter 공식 필드.

#### 기본 필드

**`name`** — 슬래시 커맨드 이름. 소문자+숫자+하이픈, 최대 64자. 생략 시 디렉토리명.
```yaml
name: fix-issue    # → /fix-issue 로 호출
```

**`description`** — Claude가 자동 호출 여부를 판단하는 기준 + `/` 메뉴 설명. What + When 형식 필수. 생략 시 마크다운 첫 문단.
```yaml
description: Resolves Git rebase conflicts. Use when encountering merge conflicts during rebase.
```

**`argument-hint`** — `/` 자동완성 시 표시되는 인자 힌트.
```yaml
argument-hint: "[issue-number]"
# /fix-issue [issue-number] 로 표시
```

스킬 본문에서 `$ARGUMENTS` (전체), `$0`, `$1` (개별)로 참조:
```markdown
Fix GitHub issue $ARGUMENTS following our coding standards.
```

#### 호출 제어

**`disable-model-invocation`** — `true` 설정 시 Claude가 자동으로 호출하지 못함. 사용자만 `/`로 수동 호출. description이 컨텍스트에 로드되지 않아 토큰도 절약.
```yaml
# 배포처럼 부작용이 큰 작업에 적합
disable-model-invocation: true
```

**`user-invocable`** — `false` 설정 시 `/` 메뉴에서 숨김. Claude만 자동 호출. description은 컨텍스트에 로드됨.
```yaml
# Claude용 배경 지식에 적합 (사용자가 직접 호출할 이유 없음)
user-invocable: false
```

**조합 효과**:

| 설정 | 사용자 호출 | Claude 호출 | description 로드 | 용도 |
|------|:---:|:---:|:---:|------|
| (기본값) | O | O | O | 일반 skill |
| `disable-model-invocation: true` | O | X | X | 배포, 커밋 등 수동 제어 |
| `user-invocable: false` | X | O | O | 배경 지식, 레퍼런스 |

#### 도구/모델 제어

**`allowed-tools`** — skill 실행 중 사용 가능한 도구 제한. 와일드카드 지원.
```yaml
# 읽기 전용 skill
allowed-tools: Read, Grep, Glob

# Git 명령만 허용
allowed-tools: Bash(git *), Read, Grep, Glob
```

**`model`** — skill 실행 시 사용할 모델. 종료 후 원래 모델로 복귀.
```yaml
# 간단한 포매팅은 저비용 모델로
model: claude-haiku-4-5-20251001

# 복잡한 분석은 고성능 모델로
model: claude-opus-4-6
```

#### 격리 실행

**`context: fork`** + **`agent`** — 독립 서브에이전트에서 실행. 메인 대화 이력에 접근 불가, 컨텍스트 보호.
```yaml
context: fork
agent: Explore          # Explore, Plan, general-purpose, 또는 커스텀
allowed-tools: Glob, Grep, Read
```

#### Skill-scoped Hooks

**`hooks`** — skill 실행 중에만 활성화되는 훅. 종료 시 해제. 상세는 `resources/03-hooks-reference.md` 참조.

#### 동적 컨텍스트 주입

본문에서 `` !`command` `` 문법으로 셸 명령을 **전처리** (Claude 이전 실행, 출력 삽입):
```markdown
## PR context
- Diff: !`gh pr diff`
- Comments: !`gh pr view --comments`
```
