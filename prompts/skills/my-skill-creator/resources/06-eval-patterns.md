# Eval Patterns — 실행 검증 및 Description 최적화

워크플로우 7 (Skill 실행 검증)과 워크플로우 8 (Description 최적화)의 상세 가이드입니다.

---

## 1. 좋은 테스트 프롬프트 작성법

### 원칙

- **Realistic**: 실제 사용자가 입력할 법한 자연스러운 표현
- **다양성**: 명시적 호출, 암시적 호출, edge case 포함
- **구체적 컨텍스트**: 단순 키워드가 아닌 실제 작업 맥락 포함

### 좋은 예시

```
# tdd skill 테스트 프롬프트
1. "이 함수에 테스트 추가해줘" (직접적)
2. "UserService 리팩토링할 건데 먼저 안전장치 깔아줘" (암시적)
3. "이 버그 수정하려는데 재현부터 하자" (edge case — bug reproduction)
```

### 나쁜 예시

```
# 너무 단순 — 실제 사용 패턴과 거리가 멂
1. "테스트" (키워드만)
2. "tdd 실행해줘" (명시적 호출만 테스트)
```

---

## 2. Assertion 작성법 (선택적)

정성 비교만으로 충분하지만, 반복 검증 시 assertion이 유용합니다.

### 체크 유형

| 유형 | 예시 | 적합한 상황 |
|------|------|------------|
| 키워드 포함 | 출력에 `describe(` 포함 | 코드 생성 skill |
| 구조 확인 | `## Phase 1` 섹션 존재 | 문서 생성 skill |
| 파일 생성 | `*.test.ts` 파일 생성됨 | 파일 생성 skill |
| 명령 실행 | `git commit` 호출됨 | 워크플로우 skill |

### 예시

```bash
# 간단한 assertion: 출력에 특정 패턴이 포함되는지 확인
claude -p "테스트 프롬프트" 2>&1 | grep -q "expected_pattern"
```

---

## 3. should_trigger / should_not_trigger 작성 가이드

### should_trigger 작성법

- **직접적 요청**: "skill 만들어줘", "PR 리뷰해줘"
- **암시적 요청**: 키워드가 자연스럽게 포함된 작업 요청
- **변형 표현**: 같은 의도의 다른 표현 (한국어/영어 혼용 포함)
- **컨텍스트 의존**: 파일 작업 중 자연스럽게 트리거되는 상황

```yaml
should_trigger:
  - "skill 만들어줘"                    # 직접적
  - "이 작업 패턴을 재사용하고 싶어"       # 암시적
  - "create a new skill for deployment" # 영어
  - "SKILL.md 수정해줘"                 # 파일 기반
  - "이 프롬프트를 skill로 변환해"        # 워크플로우 5
```

### should_not_trigger 작성법 (near-miss 중심)

- **키워드 겹침**: skill 관련 키워드가 있지만 다른 skill이 적합
- **유사 도메인**: 같은 분야지만 다른 작업
- **일반 작업**: skill 시스템과 무관한 일반 요청

```yaml
should_not_trigger:
  - "CLAUDE.md에 규칙 추가해줘"          # claude-guide가 적합
  - "이 코드 리뷰해줘"                   # code-review가 적합
  - "skill이라는 변수명 바꿔줘"           # 일반 코딩 작업
  - "스킬 트리 구현해줘" (게임 개발)       # 키워드 겹침, 다른 도메인
```

---

## 4. 스크립트 번들링 패턴

워크플로우 7 반복 실행 중 subagent가 동일한 검증 스크립트를 반복 작성하면, `scripts/`로 번들합니다.

### 발견 신호

- 2회 이상 동일한 bash 스크립트 패턴 등장
- subagent가 매번 같은 setup/teardown 수행
- assertion 체크 로직이 반복

### 번들 예시

```bash
# scripts/eval-trigger.sh — description 트리거 테스트 자동화
#!/bin/bash
SKILL_NAME=$1
EVAL_FILE=$2  # should_trigger/should_not_trigger YAML

# 각 query에 대해 트리거 여부 확인
while IFS= read -r query; do
  result=$(claude -p "$query" --allowedTools "" 2>&1)
  # 트리거 여부 판단 로직
done < "$EVAL_FILE"
```

---

## 5. with-skill vs without-skill 비교 실행

### Subagent 구성

```
# with-skill (skill 적용)
Agent(isolation: worktree):
  목표: "{test_prompt}" 실행
  조건: skill이 로드된 환경에서 실행
  보고: 출력 결과 + 사용한 도구 목록

# without-skill (baseline)
Agent(isolation: worktree):
  목표: 동일한 "{test_prompt}" 실행
  조건: 해당 skill 없이 실행
  보고: 출력 결과 + 사용한 도구 목록
```

### 비교 관점

| 관점 | 질문 |
|------|------|
| 구조 | skill 적용 시 출력이 더 체계적인가? |
| 완성도 | 빠뜨린 단계가 없는가? |
| 정확성 | 잘못된 정보/명령이 없는가? |
| 효율 | 불필요한 단계가 추가되지 않았는가? |

---

## 6. 참고: Anthropic eval 인프라

본 가이드는 Anthropic `anthropics/skills` repo의 eval 시스템을 경량화한 것입니다.
전체 자동화가 필요하면 다음을 참조하세요:

- `scripts/run_loop.py`: train/test split 기반 자동 반복 최적화
- `scripts/test_skill_triggers.py`: description 트리거 자동 테스트
- `scripts/run_eval.py`: skill 실행 결과 자동 평가

이 스크립트들은 `anthropics/skills` repo에서 확인할 수 있습니다.
