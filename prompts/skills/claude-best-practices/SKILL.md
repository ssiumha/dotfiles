---
name: claude-best-practices
description: Claude Code 운용 베스트 프랙티스. 위임 판단, 백그라운드 실행, 컨텍스트 관리, 블로킹 최소화 패턴. Use when optimizing Claude Code workflows, deciding delegation strategy, or managing context window. Do NOT use for Claude Code setup/configuration (use claude-guide instead).
---

# Claude Code Best Practices

Claude Code **운용 패턴** 가이드. 설정/구조는 `claude-guide` skill 참조.

**핵심 철학**:
- 컨텍스트는 유한한 자원이다 — 필요한 것만, 필요할 때
- 사용자 블로킹을 최소화한다 — 백그라운드 위임, 구체적 지시
- 위임 판단은 비용 대비 이득으로 한다 — 오버헤드 vs 격리 이점

## Instructions

### 워크플로우 1: CLAUDE.md 간결성 점검

CLAUDE.md는 **매 대화마다 컨텍스트에 로드**된다. 1줄 = 매번 소비되는 토큰.

**간결성 테스트** — 각 항목에 "No"이면 분리:

| 질문 | No → |
|------|------|
| 이 정보가 매 대화에 필요한가? | skills/ 또는 rules/로 분리 |
| 20줄 이상의 상세 규칙인가? | rules/{topic}.md로 분리 |
| 범용 패턴인가? (프로젝트 무관) | skills/로 분리 |
| 특정 파일에만 적용되는가? | rules/ + paths frontmatter |

**포함할 것**: 빌드/테스트/실행 명령어, 서비스 엔드포인트/포트, 필수 환경변수, 프로젝트 고유 제약, 디렉토리 구조 개요

**제외할 것**: 범용 코딩 컨벤션, 프레임워크 패턴, Claude가 이미 아는 것, 코드에서 직접 확인 가능한 것

**✅/❌ 패턴**: Claude가 따라야 할 패턴은 올바른/잘못된 예시를 대비하면 효과적:
```markdown
// ✅ ApiResult 래퍼 사용
return ResponseEntity.ok(ApiResult.success(data));
// ❌ 직접 반환
return ResponseEntity.ok(data);
```

### 워크플로우 2: 위임 판단

작업을 받으면 아래 매트릭스로 실행 방식을 결정:

| 조건 | 방식 | 이유 |
|------|------|------|
| 1-2줄 수정, 단일 파일 | **직접** | 오버헤드 > 이득 |
| 파일 탐색, 코드베이스 조사 | **subagent (Explore)** | 메인 컨텍스트 보호 |
| 독립적 구현 태스크 1개 | **subagent (Task)** | 격리 + 백그라운드 가능 |
| 독립적 태스크 2개+ | **subagent 병렬** | 단일 메시지에 여러 Task 호출 |
| 역할 분리 필요 (FE+BE+QA) | **team** | 각자 독립 컨텍스트, 조율 가능 |

**subagent 원칙**:
- 위임했으면 중복 작업하지 않는다
- 충분한 컨텍스트를 전달한다 (파일 경로, 기대 결과, 제약 조건)
- 결과만 받아서 사용자에게 요약한다

### 워크플로우 3: 백그라운드 실행

사용자를 블로킹하지 않으면서 오래 걸리는 작업을 처리:

```
Task(subagent_type="general-purpose", run_in_background=true, prompt="...")
→ output_file 경로 반환
→ Read로 결과 확인 또는 tail로 진행 상황 모니터링
```

```
Bash(command="mvn test", run_in_background=true)
→ 즉시 반환, 완료 시 알림
```

**적합**: 빌드, 테스트 실행, 대규모 리팩터, 코드 생성
**부적합**: 사용자 질문 답변, 즉각 피드백 필요한 작업

**병렬 조합**: 독립적인 빌드+테스트를 동시에 `run_in_background=true`로 실행

### 워크플로우 4: 컨텍스트 관리

**/clear 타이밍**:

| 시점 | 이유 |
|------|------|
| 작업 주제 전환 시 | 이전 컨텍스트가 새 작업에 간섭 |
| 대규모 탐색 후 구현 시작 시 | 탐색 결과로 컨텍스트 포화 |
| Spec 작성 완료 후 구현 시작 시 | Spec만 읽고 클린 컨텍스트로 구현 |
| compaction 경고 발생 시 | 수동 /clear가 compaction보다 예측 가능 |

**Progressive Disclosure** — 필요할 때만 로드:
```
1단계: CLAUDE.md (항상 로드, 핵심만)
2단계: rules/ (관련 파일 편집 시 자동 로드)
3단계: skills/ (slash command 호출 시만 로드)
4단계: 코드 파일 (Read로 필요 시 로드)
```

**subagent로 컨텍스트 격리**: 100개 파일 검색 → Explore, 외부 문서 조사 → researcher, 코드 리뷰 → code-reviewer. 메인 컨텍스트를 오염시키지 않는다.

**Compaction 대비** — 보존할 것: TaskList 상태, 수정한 파일 목록, 핵심 결정사항, 테스트/검증 명령어.

### 워크플로우 5: 사용자 블로킹 최소화

**구체적 지시 = 빠른 실행**: 모호한 지시는 확인 질문을 유발한다.

| 모호한 지시 | 구체적 지시 |
|------------|-----------|
| "테스트 추가해줘" | "WalletService.transfer()에 잔액 부족 케이스 단위 테스트 추가" |
| "이거 고쳐줘" | "UserController:45의 NPE를 Optional로 수정" |
| "성능 개선해줘" | "getWallets() N+1 쿼리를 fetch join으로 변경" |

**검증 기준 선제공**: Claude가 "이게 맞나요?" 질문을 하지 않도록 성공 기준을 미리 제공:
```
"WalletService에 transfer() 메서드 추가.
- 잔액 부족 시 InsufficientBalanceException
- 성공 시 TransferHistory 생성
- 검증: WalletServiceTest에서 성공/실패 2케이스 통과"
```

**큰 작업**: 인터뷰(AskUserQuestion) → Spec(.plan/) → /clear → 구현. 사용자는 Spec 승인 1회만 개입.

## 중요 원칙

1. **컨텍스트는 유한 자원**: CLAUDE.md에 넣을 때마다 "매번 로드할 가치가 있는가?" 자문
2. **오버헤드 vs 이득**: subagent 스폰 비용(~3초) vs 컨텍스트 격리 이점을 비교
3. **위임 후 방치 금지**: subagent 결과를 반드시 확인하고 사용자에게 요약
4. **Progressive Disclosure**: 미리 다 읽지 말고, 필요할 때 읽는다
5. **블로킹 = 낭비**: 사용자가 기다리는 시간을 줄이는 방향으로 설계

## Examples

### CLAUDE.md 비대화 감지
```
User: "CLAUDE.md 정리해줘"
→ 워크플로우 1: 간결성 테스트
→ 범용 React 패턴 80줄 발견 → skills/ 분리 권장
→ 결과: 250줄 → 90줄
```

### 복합 태스크 위임
```
User: "프론트엔드 리팩터 + 백엔드 API 추가 + 테스트"
→ 워크플로우 2: 3개 독립 태스크 → subagent 병렬
→ 워크플로우 3: 3개 모두 run_in_background
→ 완료 시 결과 요약 보고
```

### 컨텍스트 절약
```
User: "이 코드베이스 분석해줘"
→ 워크플로우 4: Explore subagent에 위임 (메인 컨텍스트 보호)
→ subagent가 요약 반환, 메인에는 요약만 남음
```
