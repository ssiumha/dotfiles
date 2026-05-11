---
name: COLLECTIVE-OWNERSHIP
full_name: Collective Code Ownership
category: process
origin: Kent Beck "Extreme Programming Explained" (1999) — XP 12 practices 중 하나
one_liner: "단 한 명만 만질 수 있는 코드는 부채다. 모든 코드는 모두가 고칠 수 있어야 한다"
---

# COLLECTIVE-OWNERSHIP — 집단 코드 소유

## 정의

> "Collective ownership encourages everyone to contribute new ideas to all segments of the project. Any developer can change any line of code to add functionality, fix bugs, improve designs, or refactor." — Kent Beck, *XP Explained*

코드의 어느 부분이라도 팀 누구나 고칠 수 있어야 한다. "이 모듈은 X만 만진다"는 패턴은 단기 효율은 높이지만 **암묵지 사일로**, **버스 팩터 1**, **변경 병목**을 만든다. 한 사람이 휴가를 가거나 회사를 떠나면 그 영역의 지식이 사라지고, 남은 사람들은 추측에 의존하게 된다.

## 핵심 판단

- **"이 파일/모듈을 고칠 수 있는 사람이 한 명뿐인가?"** — 그렇다면 사일로
- **"X가 내일 회사를 떠나면 이 영역에 무슨 일이 생기는가?"** — 추측만 남는다면 위험
- **"새 입사자가 이 영역을 안전하게 만지려면 며칠 걸리는가?"** — 며칠+면 진입 장벽

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 단독 commit 비율이 높은 파일 | `git log --format='%an' file \| sort -u \| wc -l` (1-2명) |
| Bus Factor 측정 (Avelino et al. 2016 알고리즘) | 핵심 작성자 제거 시 커버리지 손실 |
| Code Review 승인자가 항상 같은 사람 | PR reviewer 분포 |
| 특정 디렉토리의 PR 작성자가 1-2명 | git log + 디렉토리별 작성자 분포 |
| 테스트 부재 영역 (안전한 변경 불가) | 커버리지 0인 핫스팟 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "X에게 물어봐" 패턴이 잦음 | 지식이 사람에 묶임 |
| 특정 영역 PR이 항상 같은 사람에게 할당 | 명시적/암묵적 사일로 |
| 휴가 중 그 사람의 영역은 동결됨 | Bus Factor = 1 |
| 신규 입사자에게 "이 영역은 X가 전담" 인계 | 사일로 재생산 |
| 문서 없이 구두 전수가 주된 학습 경로 | 암묵지 사일로 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 핵심 모듈마다 작성자 3+명, 테스트로 보호되어 안전한 변경 가능, README/ADR로 진입 장벽 낮음 |
| **WARN** | 일부 영역이 1-2명에 집중되나 의식적 페어링/문서화 진행 중 |
| **FAIL** | Bus Factor = 1인 핵심 모듈 존재 OR "X에게 물어봐"가 표준 OR 테스트 부재로 다른 사람이 못 만짐 |

## 사일로가 만들어지는 메커니즘

```
초기: X가 어떤 모듈을 처음 만듦
  ↓
"X가 잘 아니까 X에게 맡기자" — 효율 우선
  ↓
다른 사람들은 그 영역에 손대지 않음 — 학습 기회 상실
  ↓
X만 자신 있게 변경 가능 — 사일로 형성
  ↓
X가 휴가/이직 → 추측, 두려움, 동결
  ↓
새로 학습하는 사람은 시행착오 — 같은 사일로 재형성
```

## 사일로를 막는 시스템

개인의 의지가 아니라 시스템으로 강제한다 ([[BROKEN-WINDOWS]] 적용):

| 수단 | 효과 |
|------|------|
| **Pair / Mob Programming** | 코드 작성 중 지식 자동 전수 |
| **Code Review 의무 + 라운드로빈 reviewer** | 모든 사람이 모든 영역을 읽음 |
| **테스트로 보호** | 다른 사람이 안전하게 변경 가능 → [[SELF-TESTING-CODE]] |
| **Bus Factor 측정 정기화** | 지표로 가시화, 분기별 리뷰 |
| **Knowledge Sharing Session** | 각 영역의 설계 의도를 공유 |
| **README / ADR / [[COMMENT-WHY]]** | 진입 장벽 낮춤 |
| **CODEOWNERS는 의무가 아닌 알림** | 승인 강제가 아니라 정보 전달 용도 |

## Strong vs Weak vs Collective Ownership

| 모델 | 설명 | 위험 |
|------|------|------|
| **Strong** | 한 사람만 자기 영역 변경 가능 | Bus Factor 1, 변경 병목 |
| **Weak** | 자기 영역에 우선권, 타인도 변경 가능 | 정치적 마찰, 일관성 저하 |
| **Collective (XP)** | 모두가 모든 영역 변경 가능 + 책임 공유 | 컨벤션 부재 시 혼란 — **테스트와 코드 표준이 전제** |

Collective Ownership은 진공에서 작동하지 않는다. **자동화된 테스트, 코드 표준, CI**가 없으면 혼란만 가중된다. XP는 이 셋을 묶어서 함께 도입한다.

## 개선 패턴

| 상황 | 적용 |
|------|------|
| Bus Factor 1인 핵심 모듈 | **즉시 페어링** — 두 번째 사람이 같이 작업하며 학습 |
| 사일로 영역에 테스트 부재 | **테스트 먼저 추가** — 다른 사람이 만질 수 있게 |
| "X에게 물어봐" 빈발 | **답을 문서/주석으로 옮김** — 같은 질문 두 번 받으면 기록 |
| 신규 입사자 진입 어려움 | **Onboarding doc + Pair on first PR** |
| Reviewer가 항상 같은 사람 | **라운드로빈 reviewer** — 매번 다른 사람이 읽음 |
| 코드 표준 부재로 다른 사람이 못 만짐 | **lint/formatter 자동화** — 합의된 기준을 시스템에 |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[CONWAYS-LAW]] | 조직 구조가 사일로를 만든다 — Conway가 사일로의 원인 분석, Collective Ownership이 처방 |
| [[BROKEN-WINDOWS]] | 사일로 방지는 시스템(페어링, 리뷰 라운드로빈, 테스트)으로 강제 |
| Bus Factor (지표) | Bus Factor가 측정값(Avelino et al. 2016 알고리즘), Collective Ownership이 처방 |
| [[COMMENT-WHY]] | WHY 주석은 사일로의 자연스러운 해독제 — 다음 사람이 의도를 알 수 있게 |
| [[BOY-SCOUT]] | 다른 사람의 영역을 만질 때 깨끗하게 남기는 실천 |

## 주의

- Collective Ownership ≠ "전문성 부정". 누군가는 특정 영역에 더 깊을 수 있다. 하지만 **유일한 사람이어선 안 된다**
- 보안/규제/인프라처럼 변경 권한 자체가 제한되어야 하는 영역은 예외 — 단 그 안에서도 Bus Factor 2+ 유지
- "모두가 모든 코드를 만질 수 있다" ≠ "모두가 마구 만진다". 테스트와 리뷰가 가드레일
- 원격/비동기 팀에서는 페어 프로그래밍이 어려움 — 동기 페어 대신 **Async Code Review + Mob Refactoring Session**으로 보완
- 사일로 해체에는 시간이 든다. 측정 → 가시화 → 점진적 페어링 → 분기별 재측정의 사이클로
