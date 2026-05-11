---
name: OCP
full_name: Open-Closed Principle
category: design
origin: Bertrand Meyer / Robert C. Martin
one_liner: "확장에 열려 있고 수정에 닫혀 있어야 한다"
---

# OCP — Open-Closed Principle

## 정의

> "Software entities should be open for extension, but closed for modification."

새 기능을 추가할 때 기존 코드를 수정하지 않아도 되는 구조.
핵심은 "변경이 예상되는 축에 확장점을 미리 설계"하는 것.

## 핵심 판단

- **새 타입/케이스 추가 시 기존 코드를 건드려야 하는가?** — 건드려야 하면 OCP 위반
- 단, 모든 곳에 적용하면 과설계. 실제 변경이 2회+ 발생한 축에만 적용

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 임계값 | 검증 방법 |
|------|--------|-----------|
| switch/case 분기 수 | > 5개 | ast-grep `switch { $$$CASES }` |
| if-else if 체인 | > 4단 | ast-grep |
| isinstance/typeof 체크 후 분기 | 2개+ | grep `isinstance\|typeof\|is_a?` |
| 같은 enum/type 기준 switch가 여러 파일에 | 2곳+ | grep으로 동일 조건 패턴 탐색 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "새 결제 수단 추가하려면 3곳을 수정해야 해" | 확장점 부재 |
| 코드 리뷰에서 "여기도 추가해야 합니다" 반복 | 분산된 조건 분기 |
| 새 기능 추가 PR이 기존 파일을 광범위하게 수정 | 기존 코드가 닫혀있지 않음 |
| 테스트 추가 없이 기존 테스트만 수정해야 하는 변경 | 수정이 확장이 아닌 변경으로 구현됨 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 기계적 위반 0개, 새 기능이 기존 코드 무변경으로 추가 가능 |
| **WARN** | switch/if-else 체인 존재하나 변경 빈도 낮음 OR 1곳만 수정 필요 |
| **FAIL** | 같은 조건 분기가 3곳+에 산재 OR 새 기능마다 기존 코드 대량 수정 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 타입별 switch/if-else | **Strategy 패턴** — 각 타입을 별도 클래스로, 인터페이스 통일 |
| 기능을 동적으로 추가/조합 | **Decorator 패턴** — 기존 객체를 감싸서 확장 |
| 알고리즘 뼈대는 같고 단계만 다름 | **Template Method** — 추상 메서드로 확장점 |
| 외부 기능을 끼워넣을 수 있어야 함 | **Plugin / Hook 구조** — 등록 기반 확장 |
| 설정에 따라 동작이 달라짐 | **Configuration / Policy Object** — 조건 분기 대신 설정 주입 |

## 주의

- OCP를 모든 변경에 적용하면 과설계가 된다. "세 번째 변경"에서 추상화하라 (Rule of Three)
- 처음부터 완벽한 확장점을 설계하려 하지 말 것. 첫 번째 변경은 직접 수정, 패턴이 보이면 그때 리팩토링
- SRP를 먼저 지키면 OCP가 자연스럽게 따라오는 경우가 많다 — 책임이 분리되면 확장점이 명확해진다
- OCP는 "수정 금지"가 아니라 "수정 없이도 확장 가능한 구조"를 뜻한다
