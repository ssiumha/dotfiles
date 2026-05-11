---
name: SRP
full_name: Single Responsibility Principle
category: design
origin: Robert C. Martin (Uncle Bob)
one_liner: "클래스(모듈)는 변경의 이유가 하나여야 한다"
---

# SRP — Single Responsibility Principle

## 정의

> "A class should have one, and only one, reason to change."

책임 = 변경의 축(axis of change). 기능이 아니다.
"이 모듈을 변경해야 하는 이유를 2개 이상 댈 수 있으면" SRP 위반.

## 핵심 판단

- **변경의 이유가 하나인가?** — 이것만 자문하면 된다
- 같은 시점에 같은 이유로 바뀌는 코드 → 같은 모듈에
- 다른 시점에 다른 이유로 바뀌는 코드 → 다른 모듈로

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 임계값 | 검증 방법 |
|------|--------|-----------|
| 파일 행 수 | > 300줄 | `wc -l` |
| 클래스 public 메서드 수 | > 7개 | tree-sitter / ast-grep |
| import/require 수 | > 10개 | `grep -c "^import\|^from\|require("` |
| 함수 파라미터 수 | > 5개 | ast-grep |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 이름에 And/Manager/Handler/Processor/Utils | 여러 책임을 암시하는 이름 |
| 메서드 그룹이 서로 다른 필드만 사용 | 클래스 내부에 2개 이상의 응집 그룹 |
| 변경 시 관련 없는 테스트가 깨짐 | 책임이 얽혀 있다는 증거 |
| "이것도 여기 넣자" 패턴 | 편의상 기존 클래스에 추가하는 습관 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 기계적 위반 0개, 판단 위반 0개 |
| **WARN** | 기계적 위반 1-2개 OR 판단 위반 1개 |
| **FAIL** | 기계적 위반 3개+ OR 판단 위반 2개+ |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 클래스가 2가지 일을 함 | Extract Class — 책임별로 분리 |
| 메서드가 다른 객체 데이터를 과도 사용 | Move Method — 데이터가 있는 곳으로 이동 |
| God 파일 (500줄+) | 응집 그룹 식별 → 파일 분리 |
| Utils/Helper 클래스 | 각 함수를 사용하는 도메인 모듈로 이동 |

## 주의

- SRP는 "작게 만들어라"가 아니다. 변경의 축이 하나면 300줄이어도 괜찮다
- 과도한 분리 → 클래스 폭발 → 오히려 이해하기 어려움. 실제 변경이 발생한 축으로만 분리
- 함수 수준 SRP와 모듈 수준 SRP를 구분한다. 모듈 수준이 더 중요하다
