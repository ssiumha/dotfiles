# Claude 글로벌 설정

프로세스 관리: @rules/process-management.md

---

# 멀티에이전트 3계층 시스템

```
Human <-> Supervisor (유일한 인터페이스)
              |
          Manager (작업 분해, 워커 분배)
              |
          Worker x N (병렬 실행)
```

통신: Task tool (subagent) 기반.

---

# Compaction 실행 후 (필수)

compaction 실행이 끝난 후, 작업전에 반드시 이하를 실행

1. 자신의 기존 instructions 이름을 확인
2. 대응하는 instructions을 읽는다
  - supervisor -> instructions/supervisor.md
  - manager -> instructions/manager.md
  - worker -> instructions/worker.md
3. 금지사항을 확인 후, 작업을 개시한다

summary의 다음 단계를 읽고 바로 작업해선 안된다.
반드시 자신의 instructions을 확인해야한다.

# Context 관리

## Context Window 보호

**200k 토큰 한계 인식**:
- MCP 과다 등록 시 → 실사용 **70k까지 감소**
- 프로젝트당 MCP **5-6개만 활성화**
- 활성 도구 **80개 미만** 유지
- 불필요 MCP → `settings.local.json`에서 비활성화

## Subagent 결과 압축

| subagent | 반환 형식 |
|----------|----------|
| Explore | 파일 경로 + 핵심 의존성 (1-3개) |
| Plan | 구현 순서 + 트레이드오프 |
| Bash | 성공/실패 + 에러 상위 3개 |
| code-reviewer | Summary + Critical/High만 |

**압축 원칙**:
- 상세 정보 → **파일 저장 후 경로만 전달**
- 대용량 출력 → 요약 후 보고
- 전체 코드 복사 금지 → **파일 경로:라인 번호** 형식

---

# Skill 우선 활용 (Skill-First)

**적합한 Skill 있으면 사용**. 미사용은 예외.

- 대부분의 작업에 적합한 skill 존재. 없다면 생성을 제안
- 예시: 테스트 먼저 → tdd-practices, 계획 수립 → plan-creator
