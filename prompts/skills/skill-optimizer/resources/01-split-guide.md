# SKILL.md → INSTRUCTIONS.md 분할 가이드

## 개요

이 문서는 SKILL.md를 INSTRUCTIONS.md로 분할하는 상세 절차를 설명합니다.

## 왜 분할하는가?

### Claude Code의 Skill 로딩 메커니즘

Claude Code는 skill을 **점진적으로 로딩**합니다:

```
1. Description (항상)     → 2% of context window (fallback 16,000자)
2. SKILL.md (트리거 시)   → 전체 내용 로드
3. Supporting files       → Read 도구로 필요 시 로드
```

SKILL.md가 크면 트리거 시마다 전체가 컨텍스트에 삽입됩니다.
INSTRUCTIONS.md로 분할하면, SKILL.md는 최소 크기(~300B)로 유지되고
상세 절차는 Claude가 Read로 필요 시에만 로드합니다.

### 공식 근거

**Claude Code 공식 문서** (https://code.claude.com/docs/en/skills):
> "Keep SKILL.md under 500 lines. Move detailed reference material to separate files."

- Skill descriptions budget: 2% of context window (fallback 16,000자)
- 초과 시 일부 skill이 컨텍스트에서 제외됨
- `/context` 명령으로 제외 경고 확인 가능
- `SLASH_COMMAND_TOOL_CHAR_BUDGET` 환경변수로 한도 조정 가능

**실측 데이터** (Zenn 아티클, kei31ai):
- 87 skills 프로젝트에서 전체 SKILL.md 크기: 898KB → 27KB (97% 절감)
- 개별 skill 최대 절감: 37,813B → 314B (99.2%)
- 83/87 skills 분할 성공 (95.4% 적용률)

## 분할 절차

### Step 1: frontmatter 식별

SKILL.md에서 YAML frontmatter 경계를 찾습니다:

```yaml
---                    ← 첫 번째 구분자
name: my-skill
description: ...
---                    ← 두 번째 구분자

# 여기부터 body        ← 이 부분이 INSTRUCTIONS.md로 이동
```

### Step 2: SKILL.md 축소

frontmatter만 남기고 참조문 추가:

```yaml
---
name: my-skill
description: 원본 description 그대로 유지
---

상세 절차는 INSTRUCTIONS.md를 참조하세요.
```

**주의사항**:
- description은 절대 변경하지 않음 (트리거 기준)
- 기타 frontmatter 필드 (allowed-tools, model, hooks 등)도 그대로 유지
- 참조문은 한 줄로 충분

### Step 3: INSTRUCTIONS.md 생성

동일 디렉토리에 INSTRUCTIONS.md 생성:

```markdown
# {Skill Name}

{SKILL.md body 전체 — 변경 없이 그대로 이동}
```

**헤딩 규칙**:
- 첫 줄에 `# {Skill Name}` 추가 (SKILL.md의 name 필드와 일치)
- 원본 body의 첫 헤딩이 `#`이면 그대로 사용 (중복 추가 불필요)

### Step 4: 참조 경로 확인

INSTRUCTIONS.md 내에서 참조하는 파일 경로가 유효한지 확인:

```bash
# resources/ 참조 확인
grep -n 'resources/' INSTRUCTIONS.md | while read line; do
  file=$(echo "$line" | grep -oP 'resources/[^\s\)]+')
  [ -f "$file" ] && echo "✅ $file" || echo "❌ $file (not found)"
done
```

동일 디렉토리이므로 상대 경로는 대부분 유효합니다.

## 분할 전후 비교

### Before

```
my-skill/
├── SKILL.md           (450줄, 15KB)
└── resources/
    └── 01-reference.md
```

### After

```
my-skill/
├── SKILL.md           (7줄, ~300B)  ← frontmatter + 참조문
├── INSTRUCTIONS.md    (445줄, ~15KB) ← body 전체
└── resources/
    └── 01-reference.md              ← 변경 없음
```

## 분할하지 않는 경우

| 조건 | 이유 |
|------|------|
| 200줄 미만 | 분할 오버헤드 > 절감 효과 |
| resources/가 이미 잘 분리됨 | SKILL.md가 이미 가벼움 |
| context: fork 사용 | 서브에이전트에서 전체 로드 필요 |
| disable-model-invocation: true | description이 컨텍스트에 미로드 |

## 역병합 (Unsplit)

분할을 되돌리려면:

1. INSTRUCTIONS.md 내용 읽기
2. SKILL.md의 참조문 삭제
3. frontmatter 아래에 INSTRUCTIONS.md 내용 붙여넣기
4. INSTRUCTIONS.md 삭제

```bash
# 간단 스크립트
cat INSTRUCTIONS.md >> SKILL.md  # 주의: frontmatter 뒤에 삽입 필요
rm INSTRUCTIONS.md
```
