# Claude Code 운용 가이드

Claude Code **운용 패턴** 레퍼런스. 설정/구조는 INSTRUCTIONS.md 본문 참조.

**핵심 철학**:
- 컨텍스트는 유한한 자원이다 — 필요한 것만, 필요할 때
- 사용자 블로킹을 최소화한다 — 백그라운드 위임, 구체적 지시
- 위임 판단은 비용 대비 이득으로 한다 — 오버헤드 vs 격리 이점

---

## 위임 판단 매트릭스

| 조건 | 방식 | 이유 |
|------|------|------|
| 1-2줄 수정, 단일 파일 | **직접** | 오버헤드 > 이득 |
| 파일 탐색, 코드베이스 조사 | **subagent (Explore)** | 메인 컨텍스트 보호 |
| 독립적 구현 태스크 1개 | **subagent (Task)** | 격리 + 백그라운드 가능 |
| 독립적 태스크 2개+ | **subagent 병렬** | 단일 메시지에 여러 Task 호출 |
| 역할 분리 필요 (FE+BE+QA) | **team** | 각자 독립 컨텍스트, 조율 가능 |

**subagent 원칙**: 위임 후 중복 작업 금지. 충분한 컨텍스트 전달 (파일 경로, 기대 결과, 제약). 결과만 받아서 사용자에게 요약.

---

## 백그라운드 실행 패턴

```
# subagent 백그라운드
Agent(subagent_type="general-purpose", run_in_background=true, prompt="...")

# Bash 백그라운드
Bash(command="mvn test", run_in_background=true)
```

**적합**: 빌드, 테스트 실행, 대규모 리팩터, 코드 생성
**부적합**: 사용자 질문 답변, 즉각 피드백 필요한 작업
**병렬 조합**: 독립적인 빌드+테스트를 동시에 `run_in_background=true`로 실행

---

## 컨텍스트 관리

### /clear 타이밍

| 시점 | 이유 |
|------|------|
| 작업 주제 전환 시 | 이전 컨텍스트가 새 작업에 간섭 |
| 대규모 탐색 후 구현 시작 시 | 탐색 결과로 컨텍스트 포화 |
| Spec 작성 완료 후 구현 시작 시 | Spec만 읽고 클린 컨텍스트로 구현 |
| compaction 경고 발생 시 | 수동 /clear가 compaction보다 예측 가능 |

### Progressive Disclosure

```
1단계: CLAUDE.md (항상 로드, 핵심만)
2단계: rules/ (관련 파일 편집 시 자동 로드)
3단계: skills/ (slash command 호출 시만 로드)
4단계: 코드 파일 (Read로 필요 시 로드)
```

**subagent로 컨텍스트 격리**: 100개 파일 검색 → Explore, 외부 문서 조사 → researcher, 코드 리뷰 → code-reviewer.

**Compaction 대비** — 보존할 것: TaskList 상태, 수정한 파일 목록, 핵심 결정사항, 테스트/검증 명령어.

---

## 블로킹 최소화

**구체적 지시 = 빠른 실행**: 모호한 지시는 확인 질문을 유발한다.

| 모호한 지시 | 구체적 지시 |
|------------|-----------|
| "테스트 추가해줘" | "WalletService.transfer()에 잔액 부족 케이스 단위 테스트 추가" |
| "이거 고쳐줘" | "UserController:45의 NPE를 Optional로 수정" |
| "성능 개선해줘" | "getWallets() N+1 쿼리를 fetch join으로 변경" |

**검증 기준 선제공**: 성공 기준을 미리 제공하면 확인 질문 없이 바로 실행.

**큰 작업**: 인터뷰(AskUserQuestion) → Spec → /clear → 구현. 사용자는 Spec 승인 1회만 개입.

---

## 핵심 5원칙

1. **컨텍스트는 유한 자원**: CLAUDE.md에 넣을 때마다 "매번 로드할 가치가 있는가?" 자문
2. **오버헤드 vs 이득**: subagent 스폰 비용(~3초) vs 컨텍스트 격리 이점을 비교
3. **위임 후 방치 금지**: subagent 결과를 반드시 확인하고 사용자에게 요약
4. **Progressive Disclosure**: 미리 다 읽지 말고, 필요할 때 읽는다
5. **블로킹 = 낭비**: 사용자가 기다리는 시간을 줄이는 방향으로 설계
