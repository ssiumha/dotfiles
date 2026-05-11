# Knowledge Base Taxonomy — 문서 유형 레지스트리

문서를 작성하는 것이 아니라, 문서를 작성하는 **시스템**을 구성한다.
네임스페이스 규격의 이름만 봐도 유형이 유추 가능해야 하고, 탐색 비용이 낮아야 한다.

> 모든 유형을 미리 만들지 않는다. 필요할 때 등록하고, 사용 패턴에 따라 스킬을 개선한다.

## 두 저장소 모델

| 저장소 | 용도 | 탐색 | 수명 |
|--------|------|------|------|
| **Logseq** (`~/Documents/obsidian/`) | 개인 지식 — 이벤트 기록, 의사결정, 트러블슈팅, 학습 | `ir search` (BM25/hybrid) | 영속 |
| **Repo docs/** (프로젝트 `.docs/` 또는 `docs/`) | 프로젝트 지식 — 에이전트가 직접 참조하는 기록 시스템 | Glob, Grep, Read | 프로젝트 수명 |

### 경계 원칙

| 질문 | Logseq | Repo docs/ |
|------|--------|-----------|
| 이 프로젝트가 삭제되어도 가치가 있는가? | Yes → Logseq | No → Repo |
| 에이전트가 매 세션 참조해야 하는가? | No → Logseq | Yes → Repo |
| 커뮤니케이션 이력이 포함되는가? | Yes → Logseq | No → Repo |
| 코드와 함께 버전 관리되어야 하는가? | No → Logseq | Yes → Repo |

**양쪽에 걸치는 경우**: Repo에 정규 문서, vault에서 `[[링크]]`로 참조.
예: ADR은 Repo에, 그 ADR을 만든 맥락/회의록은 Logseq `decision/`에.

---

## 의존 그래프 — 문서를 코드처럼 다루기

문서도 코드다. 네임스페이스가 있고, 위계와 의존 관계가 있으며, 방향성이 있다.
이 구조 없이는 문서가 늘어날수록 탐색 비용만 커진다.

**적용 원칙** (Robert C. Martin, Package Principles):

| 원칙 | 코드 | 문서 |
|------|------|------|
| **ADP** (Acyclic Dependencies) | 패키지 간 순환 의존 금지 | L 역방향 참조 금지. 순환 발견 시 안정한 쪽으로 지식 승격 |
| **SDP** (Stable Dependencies) | 안정한 쪽으로 의존 | L3→L2→L1→L0 방향. 불안정한 문서가 안정한 문서에 의존 |
| **SAP** (Stable Abstractions) | 안정한 것일수록 추상적 | L0(개념)이 가장 추상적, L3(세션)이 가장 구체적 |

**새 문서 유형 등록 시 체크**: 이 유형은 어느 L에 속하는가? 의존 방향이 ADP/SDP를 위반하지 않는가?

### 안정도 계층 (Stability Layers)

안정도가 높을수록 변경이 적고, 다른 문서가 더 많이 의존한다.

| 계층 | 안정도 | 내용 | Logseq 예시 | Repo 예시 |
|------|--------|------|-------------|-----------|
| **L0** | 최고 | 개념·용어·도메인 모델 | `스테이블코인`, `온오프램프` | ARCHITECTURE.md |
| **L1** | 높음 | 결정·스펙·계약 | `decision/`, `spec/` | `docs/decisions/ADR-*` |
| **L2** | 중간 | 이벤트·기록 | `troubleshoot/`, `incident/`, `qa/`, `debrief/` | `docs/runbooks/` |
| **L3** | 낮음 | 임시·세션·저널 | 저널, `session/` | `.claude/plans/` |

### 의존 방향 규칙

**의존은 항상 안정한 쪽을 향한다** — L3 → L2 → L1 → L0

| 참조 방향 | 허용 | 예시 |
|-----------|------|------|
| L3 → L2 | OK | 저널에서 troubleshoot 링크 |
| L3 → L1 | OK | 세션에서 decision 참조 |
| L2 → L1 | OK | incident에서 ADR 참조 |
| L2 → L0 | OK | qa에서 도메인 개념 참조 |
| L1 → L0 | OK | ADR에서 ARCHITECTURE.md 참조 |
| L1 → L2 | **NG** | decision이 특정 incident에 의존 |
| L0 → L2 | **NG** | 도메인 개념이 session에 의존 |
| 같은 계층 | OK | decision ↔ decision, ADR ↔ ADR |

위반 시: 참조가 필요하면 **안정한 쪽으로 지식을 승격**한다.
예: incident에서 발견한 패턴이 반복 → decision으로 승격 → incident은 decision을 참조.

### 네임스페이스 = 패키지

| 코드 | 문서 |
|------|------|
| `import` | `[[링크]]` 또는 파일 경로 참조 |
| package/module | namespace (`troubleshoot/`, `decision/`, `docs/decisions/`) |
| 순환 의존 금지 | L 역방향 참조 금지 |
| public API | 문서 제목 + 프로퍼티 (검색 가능한 표면) |
| internal | 문서 본문 (탐색 비용 높음) |

### 저장소 간 참조

| 방향 | 허용 | 방법 |
|------|------|------|
| Logseq → Repo | OK | 파일 경로 텍스트로 참조 |
| Repo → Logseq | **NG** | Repo는 vault에 의존하지 않는다 (에이전트가 Repo만으로 동작 가능해야) |
| Logseq ↔ Logseq | OK | `[[링크]]` |
| Repo ↔ Repo | OK | 상대 경로 참조 |

---

## Logseq 문서 유형 (등록됨)

`/obsidian-write` 스킬이 관리. 상세 템플릿은 logseq-write SKILL.md 참조.

| 유형 | 네이밍 | 트리거 | 스킬 | 안정도 |
|------|--------|--------|------|--------|
| troubleshoot | `pj-{name}/troubleshoot/{제목}` | 조사→해결 완료 | logseq-write | L2 (이벤트) |
| decision | `pj-{name}/decision/{제목}` | 결정 확정 | logseq-write | L1 (결정) |
| qa | `pj-{name}/qa/{제목}` | QA 완료 | logseq-write | L2 |
| spec | `pj-{name}/spec/{제목}` | 스펙 도출 | logseq-write | L1 |
| incident | `pj-{name}/incident/{제목}` | 배포 실패/인프라 이슈 | logseq-write | L2 |
| issue | `pj-{name}/issue/{제목}` | 장기 추적 이슈 | logseq-write | L2 |
| debrief | `pj-{name}/debrief/{제목}` | 코드 작업 완료 | debrief | L2 |
| session | `session/{slug} {sid}` | 세션 종료 | recall (자동) | L3 (저널) |
| 개념 | `{개념명}` (루트) | 도메인 용어 | logseq-write | L0 (개념) |

범용(프로젝트 무관): `{type}/{제목}` — `pj-` prefix 없이.

---

## Repo 문서 유형 (등록됨)

프로젝트 내 `docs/` 에 저장. harness-engineering Setup Phase 4에서 구성.

| 유형 | 네이밍 | 트리거 | 스킬 | 비고 |
|------|--------|--------|------|------|
| architecture | `ARCHITECTURE.md` (루트) | 프로젝트 초기 + 구조 변경 | harness-engineering | Codemap, Invariants 포함 |
| adr | `docs/decisions/ADR-{NNN}-{slug}.md` | 아키텍처 결정 시 | (점진적 추가) | Context→Decision→Consequences |
| runbook | `docs/runbooks/{slug}.md` | 운영 프로세스 정리 시 | (점진적 추가) | 배포, 롤백, 인시던트 대응 |

### 미등록 — 필요 시 추가

아래는 아직 등록하지 않은 유형. 프로젝트에서 필요가 발생하면 등록한다.

| 후보 | 네이밍 (안) | 트리거 (안) |
|------|------------|------------|
| exec-plan | `docs/plans/{slug}.md` | 실행 계획 확정 시 |
| api-spec | `docs/api/{slug}.md` | API 설계 확정 시 |
| onboarding | `docs/onboarding.md` | 팀원 합류 시 |
| postmortem | `docs/postmortems/{date}-{slug}.md` | 인시던트 사후 분석 |

---

## 네이밍 원칙

1. **이름만 보고 유형 유추** — 디렉토리가 유형, 파일명이 내용
   - `docs/decisions/ADR-003-auth-strategy.md` → ADR인 것이 자명
   - `pj-foo/troubleshoot/redis-timeout` → troubleshoot인 것이 자명

2. **깊이 제한** — 최대 2단
   - Logseq: `pj-{name}/{type}/{제목}` (3 segment)
   - Repo: `docs/{type}/{파일명}` (3 segment)
   - 4단 이상 금지

3. **slug 규칙**
   - Logseq: 한국어 설명적 제목 (`redis-timeout-해결`)
   - Repo: 영문 kebab-case (`auth-strategy`)

4. **번호 매기기** — ADR만 순차 번호. 나머지는 번호 없이 slug만.

---

## 레지스트리 운용

### 새 유형 등록 절차

1. 같은 유형의 문서가 **2회 이상** 작성되었을 때 등록 검토
2. **안정도 계층 결정** — 이 유형은 L0/L1/L2/L3 중 어디에 속하는가?
3. **ADP/SDP 검증** — 이 유형이 참조할 기존 유형, 이 유형을 참조할 기존 유형을 확인. 역방향 의존이 생기지 않는가?
4. 네이밍 규칙 확정 (디렉토리 + 파일명 패턴)
5. 이 파일의 해당 테이블에 행 추가 (안정도 컬럼 필수)
6. 템플릿이 필요하면 해당 스킬에 추가 (logseq-write 또는 별도 스킬)
7. 스킬 description에 트리거 키워드 추가

### 유형 폐기

- 3개월 이상 사용되지 않은 유형 → "미등록"으로 이동
- 기존 문서는 삭제하지 않음 (역사적 맥락 보존)

### 스킬 연동

| 동작 | 담당 스킬 |
|------|-----------|
| Logseq 문서 작성 | logseq-write |
| Repo docs/ 구조 설계 | harness-engineering (Setup Phase 4) |
| 문서 신선도 점검 | harness-engineering (Gardening) |
| 새 유형 등록 | meta-prompt (신호 → 흡수) |
| 스킬 생성/개선 | my-skill-creator |

---

## Setup 가이드 (harness-engineering Phase 4에서 참조)

### 프로젝트 규모별 권장

| 규모 | docs/ 구조 | 문서 유형 |
|------|-----------|-----------|
| 소규모 (1인, 단기) | ARCHITECTURE.md만 | - |
| 중규모 (팀, 3개월+) | + `docs/decisions/` | ADR 추가 |
| 대규모 (다팀, 장기) | + `docs/runbooks/`, `docs/api/` | ADR + Runbook + API spec |

### 구성 절차

1. ARCHITECTURE.md 존재 확인 (없으면 생성 — harness-engineering Phase 1)
2. 프로젝트 규모 판단
3. 해당 규모의 `docs/` 디렉토리 생성
4. CLAUDE.md에 `docs/` 참조 추가 (목차 역할)
5. 기존 외부 문서(Slack, Google Docs)를 해당 유형으로 인코딩
