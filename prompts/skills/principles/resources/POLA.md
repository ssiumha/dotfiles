---
name: POLA
full_name: Principle of Least Astonishment
category: design
origin: IBM Systems Journal, 1984
one_liner: "사용자(개발자)가 예상하는 대로 동작해야 한다"
---

# POLA — Principle of Least Astonishment

## 정의

> "이름을 보고 예상한 동작과 실제 동작이 일치해야 한다."

"놀라움"이 있다면 설계가 잘못된 것이다. API, 함수, 변수, 설정 — 모든 인터페이스에 적용.

## 핵심 판단

- **"이 이름만 보고 동작을 정확히 예측할 수 있는가?"** — 못 하면 위반
- **"이 함수를 호출한 뒤 예상치 못한 일이 일어나는가?"** — 일어나면 위반
- **"이 값의 단위/형식/범위가 이름에서 드러나는가?"** — 안 드러나면 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| `get*` 메서드에 부수효과 (쓰기, 삭제, 네트워크) | ast-grep: get 함수 내 write/delete/fetch 호출 탐지 |
| `is*`/`has*`가 boolean 외 반환 | ast-grep: 반환 타입 체크 |
| 함수명에 없는 부수효과 | `save_user`가 이메일도 보냄 → grep side effect 패턴 |
| 매개변수 순서 불일치 | 같은 개념의 함수들 간 파라미터 순서 비교 |
| boolean 파라미터 (동작 분기) | grep `def.*bool\|: boolean` — "무엇을 하느냐"가 호출자에게 불투명 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 이름과 동작 불일치 | `calculatePrice`가 DB에 저장도 함 |
| 암묵적 부수효과 | 읽기 함수가 캐시를 변경, 로그를 남김 |
| 비관습적 반환값 | 에러 시 -1 반환 (예외/null이 관례인 언어에서) |
| 설정의 비직관적 기본값 | `verbose=true`가 기본, `safe_mode=false`가 기본 |
| 같은 패턴의 다른 동작 | A 모듈의 `create`는 생성만, B 모듈의 `create`는 생성+저장 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 이름-동작 일치, 부수효과 명시적, 반환값 예측 가능 |
| **WARN** | get에 경미한 부수효과 (캐싱) OR boolean 파라미터 1-2개 |
| **FAIL** | 이름-동작 불일치 OR 숨겨진 부수효과 OR 비관습적 반환값 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| get에 부수효과 | **Command-Query Separation** — 조회와 변경을 분리 |
| 이름이 동작을 안 담음 | **더 정확한 이름** — `getUser` → `fetchAndCacheUser` |
| boolean 파라미터 | **별도 메서드** — `render(compact=true)` → `renderCompact()` |
| 숨겨진 부수효과 | **명시적 반환/이벤트** — 부수효과를 호출자가 알 수 있게 |
| 비일관적 패턴 | **네이밍 컨벤션** — create/find/update/delete 의미 통일 |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[INTENTION-REVEALING-NAMES]] | 의도를 드러내는 이름이 놀라움을 줄이는 첫 단계 — POLA의 전제 |
| [[CQS]] | get에 부수효과는 POLA 위반 — 조회와 변경 분리가 처방 |
| [[CONVENTION-OVER-CONFIG]] | 관례를 따르면 놀라움이 줄어듦 — POLA의 시스템 차원 적용 |

## 주의

- POLA는 "누구에게" 놀랍지 않아야 하는가가 중요하다. 대상은 "이 코드를 사용하는 개발자"
- 도메인 관례를 따르는 것이 일반 관례보다 우선할 수 있다 (금융에서 T+2는 놀랍지 않다)
- 성능 최적화로 인한 놀라운 동작은 문서화로 보완
