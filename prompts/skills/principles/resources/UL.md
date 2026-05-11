---
name: UL
full_name: Ubiquitous Language
category: design
origin: Eric Evans, "Domain-Driven Design" (2003)
one_liner: "도메인 전문가와 개발자가 같은 언어를 쓴다. 코드가 곧 도메인 용어"
---

# UL — Ubiquitous Language

## 정의

> "Use the model as the backbone of a language. Commit the team to exercising that language relentlessly in all communication within the team and in the code."

코드의 클래스, 메서드, 변수 이름이 비즈니스 도메인 용어와 1:1 대응해야 한다. 개발자가 만든 기술 용어가 아니라 현업이 쓰는 단어 그대로. 코드를 읽으면 비즈니스가 읽히고, 비즈니스를 말하면 코드가 보인다.

## 핵심 판단

- **"이 클래스 이름을 현업 담당자에게 말하면 바로 이해하는가?"** — 못하면 UL 위반
- **"같은 개념에 코드와 문서에서 다른 이름을 쓰고 있는가?"** — 다르면 위반
- **"개발자끼리만 통하는 이름이 비즈니스 로직에 있는가?"** — 있으면 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 도메인 클래스에 기술 접미사 (Manager, Handler, Processor, Helper) | grep 도메인 레이어에서 기술 용어 |
| 같은 개념에 여러 이름 사용 (User/Member/Account 혼용) | 동의어 패턴 검출 |
| 약어/축약어 과다 (txn, amt, qty) | 도메인 코드에서 약어 비율 |
| 주석으로 "비즈니스에서는 X라고 부름" | grep `비즈니스\|현업\|업무적으로\|called\|known as` |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 회의에서 쓰는 단어와 코드 용어가 다름 | 번역 비용 발생 |
| 새 팀원이 코드를 읽고 도메인을 이해 못 함 | 언어 불일치 |
| 기획서 용어와 API 필드명 불일치 | 시스템 경계에서 번역 필요 |
| "이 코드에서 X는 사실 Y를 의미해" 설명 필요 | 암묵적 매핑 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 도메인 코드가 비즈니스 용어와 일치, 기술 접미사 없음, 용어집 존재 |
| **WARN** | 일부 불일치 존재하나 핵심 도메인은 용어 통일됨 |
| **FAIL** | 도메인 코드에 기술 용어 범람 OR 같은 개념 다른 이름 3개+ OR 주석으로 번역 필요 |

## 좋은 이름 vs 나쁜 이름

```
// ❌ 기술 용어 / 모호한 이름
class OrderProcessor { process(data) }
class PaymentHandler { handle(info) }
class UserManager { manage(entity) }
const txnAmt = calculateTotal()

// ✅ 도메인 용어 / 의도가 드러나는 이름
class Order { place(), cancel(), refund() }
class Payment { authorize(), capture(), void() }
class Member { register(), deactivate() }
const transactionAmount = calculateTotal()
```

## 용어집 (Glossary) 운용

UL을 유지하려면 **용어집**이 필요하다:

| 항목 | 설명 |
|------|------|
| 도메인 용어 | 비즈니스에서 사용하는 이름 |
| 코드 용어 | 클래스/메서드/필드에 쓰이는 이름 |
| 컨텍스트 | 이 용어가 유효한 Bounded Context |
| 금지 동의어 | 혼동을 유발하므로 사용하지 않는 이름 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 코드 용어와 비즈니스 용어 불일치 | **Rename** — 코드를 비즈니스 용어로 변경. 비즈니스를 코드에 맞추지 않는다 |
| 같은 단어가 맥락에 따라 다른 의미 | **Bounded Context 분리** — 각 컨텍스트에서 별도 모델로 정의 (→ BC 원칙 참조) |
| 용어가 자주 바뀜 | **용어집(Glossary) 문서화** — 코드와 동기화, PR 리뷰에서 확인 |
| API 필드와 내부 모델 용어 불일치 | **DTO/Serializer에서 매핑** — 내부는 UL 유지, 외부 인터페이스에서 변환 |

## Bounded Context와의 관계

UL은 **하나의 Bounded Context 안에서** 통용된다. 다른 컨텍스트에서는 같은 단어가 다른 의미를 가질 수 있다:

- "Account" — 회원 컨텍스트에서는 사용자 계정, 금융 컨텍스트에서는 은행 계좌
- "Order" — 주문 컨텍스트에서는 구매 주문, 물류 컨텍스트에서는 배송 지시

이것은 UL 위반이 아니라 **정상적인 컨텍스트 분리**다.

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[INTENTION-REVEALING-NAMES]] | UL이 어휘 선택(어떤 단어를 쓸 것인가), IRN이 표현력(이름이 의도를 드러내는가). 함께 적용 — UL 단어를 의도가 드러나는 형태로 |
| [[BC]] | UL은 하나의 Bounded Context 안에서 통용. BC가 UL의 적용 경계를 정의 |

## 주의

- UL은 "현업 용어 100% 사용"이 아니다. 현업이 모호하게 쓰는 용어는 **팀이 함께 정제**하여 명확하게 만든다
- 기술 인프라 코드(DB, HTTP, 캐시)에는 기술 용어를 쓰는 것이 맞다. UL은 **도메인 코드**에 적용
- 레거시 시스템의 용어가 현업 용어와 다르면 Anti-Corruption Layer에서 변환한다
- 번역 프로젝트(한/영 혼용)에서는 팀이 합의한 표기 규칙이 필요하다. 코드는 영문, 주석/문서는 혼용 등
