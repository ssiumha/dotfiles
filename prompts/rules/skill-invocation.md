# Skill 호출 규칙 (Default Skill-First)

**기본 동작: 적합한 Skill이 있으면 사용**. Skill 미사용은 예외.

> 대부분의 작업에 적합한 skill이 존재.

## 호출 원칙

1. **Skill 이름 언급 → 90% 호출** (기본값: YES)
2. **작업에 적합한 skill 탐색 → 있으면 사용**
3. **애매하면 호출** (실패해도 손실 적음)

## 호출 트리거 (적극적)

| 패턴 | 예시 | 동작 |
|------|------|------|
| `{skill} + 동사` | "tdd-practices 실행" | 호출 |
| `{skill} 단독` | "ldoc" | 호출 |
| `{skill} + 조사형` | "ldoc으로 할까?" | 호출 후 결과로 판단 |
| `어떤 skill?` | "이 작업에 맞는 skill?" | 적합한 skill 탐색 후 호출 |
| **작업 매칭** | "테스트 먼저 작성" | → tdd-practices |
| **작업 매칭** | "복잡한 계획 세워줘" | → plan-creator |

## 예외 (호출 금지, 최소화)

**오직 3가지만**:
1. **명시적 거부**: "쓰지 마", "필요 없어"
2. **순수 정보 질문**: "{skill}이 뭐야?" (설명만 요청)
3. **파일 직접 수정**: "{skill}/SKILL.md 수정해줘"

## 핵심 Skill 매핑

| 작업 유형 | Skill |
|----------|-------|
| 테스트 먼저 | tdd-practices |
| 복잡한 계획 수립 | plan-creator |
| 코드 구조 검색 | ast-grep |
| 프로젝트 문서화 | ldoc |
| Git 충돌 | git-conflict |
| 보안 리뷰 | review-security |
| Docker 설정 | devops-docker |
| CI/CD 파이프라인 | devops-pipelines |

## Skill vs Subagent

| 조건 | 도구 |
|------|------|
| Skill 워크플로우 적합 | **Skill 우선** |
| 단순 코드 수정 | subagent |
| Skill 내부 작업 | subagent (Skill에서 위임) |
