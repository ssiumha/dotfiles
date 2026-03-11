# Composable Skills

모듈식 skill 설계 패턴입니다.

## 핵심 원칙

**단일 책임**: 하나의 skill = 하나의 역할

```
❌ all-in-one-content-skill (500줄)
✅ brand-voice + content-structure + platform-rules (각 150줄)
```

## 조합 패턴

### Layer 구조

```
project-context (기반)
    ↓
brand-voice (스타일)
    ↓
content-formatter (출력)
```

각 layer가 독립적이지만 조합 가능.

### 예시: 콘텐츠 생성

| Skill | 역할 | 크기 |
|-------|------|------|
| `project-context` | 프로젝트 배경, 용어 | ~100줄 |
| `brand-voice` | 톤, 금지 표현, 스타일 | ~80줄 |
| `research-workflow` | 정보 수집 방법 | ~120줄 |
| `x-content` | X/Twitter 포맷 규칙 | ~100줄 |

요청: "X 스레드 작성해줘"
→ 4개 skill 동시 로드
→ 컨텍스트 + 톤 + 리서치 + 포맷 적용

### 예시: 코드 리뷰

| Skill | 역할 |
|-------|------|
| `code-quality` | 가독성, 복잡도 |
| `security-check` | OWASP, 인증/인가 |
| `performance-review` | 알고리즘, 쿼리 |
| `literate-docs` | 문서화 표준 |

Agent에서 조합:
```yaml
# code-reviewer agent
skills: code-quality, security-check, literate-docs
```

## 설계 가이드

### 분리 기준

다음 질문에 "예"면 분리 고려:
- 이 부분만 단독으로 사용되는 경우가 있나?
- 다른 skill과 조합될 가능성이 있나?
- 100줄 이상인가?

### 인터페이스 설계

Skill 간 참조 방식:

```markdown
## 관련 Skills

이 skill과 함께 사용 권장:
- `brand-voice`: 톤/스타일 적용 시
- `research-workflow`: 정보 수집 필요 시

SEE: `literate-docs` (문서화 표준)
```

### 네이밍 컨벤션

| 패턴 | 예시 | 용도 |
|------|------|------|
| `{domain}-{action}` | `code-review`, `content-generate` | 동작 중심 |
| `{domain}-{type}` | `brand-voice`, `project-context` | 지식 중심 |
| `{platform}-{format}` | `x-thread`, `linkedin-post` | 플랫폼 특화 |

## Agent에서 Skill 조합

```yaml
# .claude/agents/content-creator.md
---
name: content-creator
skills: project-context, brand-voice, research-workflow
---

콘텐츠 생성 전문 에이전트.
로드된 skills를 활용하여 일관된 브랜드 톤으로 콘텐츠 생성.
```

## 안티패턴

| ❌ 문제 | ✅ 해결 |
|--------|--------|
| 하나의 거대 skill | 역할별 분리 |
| skill 간 순환 참조 | 계층 구조로 정리 |
| 중복 내용 | 공통 skill 추출 |
| 모호한 경계 | 단일 책임 원칙 적용 |

## 실전 팁

1. **작게 시작**: 처음엔 하나로 만들고, 커지면 분리
2. **사용 패턴 관찰**: 어떤 부분이 자주 조합되는지 확인
3. **독립성 테스트**: 각 skill이 단독으로 의미있는지 검증
4. **문서화**: 조합 권장사항 명시
