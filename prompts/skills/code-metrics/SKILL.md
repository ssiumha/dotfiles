---
name: code-metrics
description: Measures code structure metrics (coupling, cohesion, complexity, call graph). Use when analyzing code quality quantitatively, checking architectural health, or reviewing structural changes.
argument-hint: "[--scope=changed|staged|all|<path>]"
---

# Code Metrics

코드 구조 메트릭을 정량적으로 측정합니다. ast-grep 기반으로 언어 독립적 분석.

**핵심 철학**:
- 측정 가능한 것만 측정 (추측 X)
- 작업 단위 분석 (전체 스캔 최소화)
- 임계값보다 추세가 중요

## Quick Reference

```bash
/code-metrics                    # 변경 파일 분석 (기본)
/code-metrics --scope=staged     # staged 파일만
/code-metrics --scope=all        # 전체 (주의: 느림)
/code-metrics src/api/           # 특정 디렉토리
```

## 측정 메트릭

| 카테고리 | 메트릭 | 측정 방법 | 의미 |
|---------|--------|----------|------|
| **복잡도** | Cyclomatic (근사) | 분기문 카운트 | 테스트 경로 수 |
| | LOC | 라인 수 | 파일/함수 크기 |
| | Nesting | 들여쓰기 깊이 | 가독성 |
| **결합도** | Efferent (Ce) | import 수 | 외부 의존도 |
| **호출** | Fan-out | 함수 호출 수 | 책임 범위 |
| **응집도** | Method/Field 비율 | 클래스 분석 | 단일 책임 |

## Instructions

### Phase 1: 대상 파일 식별

```bash
# scope에 따라 대상 결정
--scope=changed  → git diff --name-only HEAD
--scope=staged   → git diff --cached --name-only
--scope=all      → 전체 (Glob)
--scope=<path>   → 지정 경로
```

**언어 감지**: 확장자 기반 (`.ts`, `.py`, `.go` 등)

### Phase 2: 메트릭 측정

각 파일에 대해 다음 측정 실행:

#### 2.1 복잡도 (Complexity)

```bash
# LOC
wc -l <file>

# Cyclomatic (분기점 카운트) - ast-grep
ast-grep --lang typescript -p 'if ($COND) { $$$ }' <file> --json | jq length
ast-grep --lang typescript -p 'for ($INIT; $COND; $UPDATE) { $$$ }' <file> --json | jq length
ast-grep --lang typescript -p 'while ($COND) { $$$ }' <file> --json | jq length
ast-grep --lang typescript -p '$EXPR ? $THEN : $ELSE' <file> --json | jq length
ast-grep --lang typescript -p 'case $VAL:' <file> --json | jq length
ast-grep --lang typescript -p 'catch ($ERR) { $$$ }' <file> --json | jq length
# Cyclomatic = 1 + (if + for + while + ternary + case + catch)

# Nesting depth - 들여쓰기 분석 (동적 감지)
awk '{match($0, /^[ \t]*/); print RLENGTH}' <file> | sort -rn | head -1
```

**정확도**: 근사치 (±20%). Arrow function, IIFE, nested ternary 누락 가능.

#### 2.2 결합도 (Coupling)

```bash
# Efferent Coupling (Ce) - import 수
# TypeScript
ast-grep --lang typescript -p 'import $_ from "$MOD"' <file> --json | jq length
ast-grep --lang typescript -p 'import { $$$ } from "$MOD"' <file> --json | jq length

# Python
ast-grep --lang python -p 'import $MOD' <file> --json | jq length
ast-grep --lang python -p 'from $MOD import $$$' <file> --json | jq length
```

#### 2.3 호출 관계 (Call Graph)

```bash
# Fan-out - 함수 호출 수
# TypeScript
ast-grep --lang typescript -p '$FN($$$)' <file> --json | jq length

# Python
ast-grep --lang python -p '$FN($$$)' <file> --json | jq length
```

#### 2.4 응집도 (Cohesion) - 클래스 파일만

```bash
# 메서드 수
ast-grep --lang typescript -p 'class $NAME { $$$ $METHOD($$$) { $$$ } $$$ }' <file> --json

# 필드 수
ast-grep --lang typescript -p 'class $NAME { $$$ $FIELD: $TYPE $$$ }' <file> --json

# 비율 = methods / fields (높을수록 행위 중심)
```

### Phase 3: 리포트 출력

```
Code Metrics Report
═══════════════════════════════════════════════════════

Scope: changed (5 files)

┌─────────────────────────────┬──────┬────┬───────┬────┬─────┐
│ File                        │ LOC  │ CC │ Nest  │ Ce │ Fan │
├─────────────────────────────┼──────┼────┼───────┼────┼─────┤
│ src/api/client.ts           │ 220  │ 12 │ 4     │ 8  │ 24  │
│ src/utils/parser.ts         │ 85   │ 6  │ 3     │ 3  │ 10  │
│ src/models/user.py          │ 45   │ 2  │ 2     │ 2  │ 5   │
└─────────────────────────────┴──────┴────┴───────┴────┴─────┘

Summary:
  Total LOC: 350
  Avg Cyclomatic: 6.7
  Max Nesting: 4 (src/api/client.ts)
  Avg Ce: 4.3

Notes:
  - CC/Ce 수치는 근사치 (±20%)
  - 추세 비교용이며 절대 기준 아님
```

**컬럼 설명**:
- LOC: Lines of Code
- CC: Cyclomatic Complexity (근사)
- Nest: 최대 중첩 깊이
- Ce: Efferent Coupling (import 수)
- Fan: Fan-out (함수 호출 수)

## 중요 원칙

1. **근사치 인정**: ast-grep 기반 측정은 ±20% 오차 가능. 추세 비교용이며 절대값 비교 부적합
2. **작업 단위 우선**: `--scope=all`은 큰 프로젝트에서 느림. 변경 파일 위주
3. **언어별 패턴**: `resources/patterns/`에 언어별 ast-grep 패턴 정의
4. **임계값 없음**: 숫자만 제시, 판단은 사용자가

## Examples

### 변경 파일 분석

```
User: "/code-metrics"
→ Phase 1: git diff → 3 files
→ Phase 2: 각 파일 메트릭 측정
→ Phase 3: 테이블 리포트
```

### 특정 디렉토리 분석

```
User: "/code-metrics src/api/"
→ Phase 1: Glob src/api/**/*.{ts,py}
→ Phase 2: 메트릭 측정
→ Phase 3: 리포트 + Hotspot 식별
```

## Anti-Patterns

| 문제 | 해결 |
|-----|------|
| 전체 스캔 남발 | `--scope=changed` 기본 사용 |
| 절대 임계값 적용 | 추세/비교로 판단 |
| 단일 메트릭 의존 | 여러 메트릭 종합 |

## Technical Details

**언어별 패턴**: `resources/patterns/{lang}.md`
**스크립트**: `scripts/measure.sh` (선택)

**지원 언어**:
- TypeScript/JavaScript
- Python
- Go (확장 예정)

**연동 skill**:
- **ast-grep**: 복잡한 패턴 작성 시
- **quality-audit**: lint/타입 체크와 조합
