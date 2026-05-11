---
name: INTENTION-REVEALING-NAMES
full_name: Intention-Revealing Names
category: design
origin: Kent Beck "Smalltalk Best Practice Patterns" (1997) → Eric Evans "Domain-Driven Design" (2003) → Robert C. Martin "Clean Code" (2008) Ch.2 첫 항목
one_liner: "이름은 무엇을 하는지가 아니라 왜 존재하는지를 드러낸다"
---

# INTENTION-REVEALING-NAMES — 의도를 드러내는 이름

## 정의

> "The name of a variable, function, or class, should answer all the big questions. It should tell you why it exists, what it does, and how it is used. If a name requires a comment, then the name does not reveal its intent." — Robert C. Martin, *Clean Code*

이름은 **의도(intent)** 를 담아야 한다. `d`(days)가 아니라 `daysSinceModification`. 이름이 의도를 드러내면 주석이 필요 없고, 코드를 읽는 사람이 머릿속에서 컨텍스트를 재구성할 필요가 없다.

## 핵심 판단

- **"이 이름이 코멘트 없이 무엇을·왜·어떻게 답하는가?"** — 못하면 이름이 의도를 못 드러내는 것
- **"이름을 보고 사용처를 추측할 수 있는가?"** — 추측 못하면 이름이 약함
- **"매직 넘버/문자열에 이름이 붙어 있는가?"** — `< 7`이 아니라 `< MAX_RETRIES`

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 단일 문자 변수 (i, j, k 제외 루프 카운터) | grep `\b[a-z]\b` 도메인 코드 |
| 약어/축약 (mgr, hdlr, cfg, calc) | 도메인 식별자 약어 비율 |
| 의미 없는 접미사 (Data, Info, Object, Manager) | grep 접미사 패턴 |
| 매직 넘버 (이름 없는 숫자 리터럴) | grep 숫자 리터럴 빈도 |
| 함수명이 동사 부재 (process, handle, do) | grep `def (process|handle|do)` |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 이름을 보고 무엇을 하는지 모름 | `getData()`, `processItem()` |
| 같은 개념에 다른 이름 (User/Member/Account) | 일관성 부재 |
| 이름이 거짓말함 (`getUserList`가 Map 반환) | disinformation |
| 발음 불가능한 이름 (`genymdhms`) | 토론 불가능 |
| 검색 불가능한 이름 (1글자, 너무 일반적) | 도구 마찰 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 도메인 식별자에 약어 없음, 매직 넘버 0, 이름이 의도를 드러냄 |
| **WARN** | 일부 약어/모호한 이름이 있으나 핵심 도메인은 명확 |
| **FAIL** | 매직 넘버 다수 OR 단일 문자 식별자 OR `process/handle/do` 류 함수 다수 OR disinformation |

## Clean Code Ch.2의 6가지 규칙

Robert C. Martin의 원전 정리:

1. **Use Intention-Revealing Names** — 이름이 존재 이유를 말해야
2. **Avoid Disinformation** — 이름이 거짓말하지 않아야 (`accountList`가 List가 아니면 안 됨)
3. **Make Meaningful Distinctions** — `a1`, `a2`가 아니라 의미로 구분
4. **Use Pronounceable Names** — 발음 가능해야 토론 가능
5. **Use Searchable Names** — 1글자/매직 넘버는 검색 불가
6. **Avoid Mental Mapping** — `r`을 "URL의 lowercased version"으로 외우지 않게

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 매직 넘버 발견 | **Extract Constant** — 의도가 담긴 이름 부여 |
| 약어/축약 사용 | **Rename** — 풀어쓰기. IDE의 rename refactoring 활용 |
| `process()`, `handle()` 류 모호한 동사 | **구체적 동사로 교체** — `validatePayment`, `dispatchOrder` |
| 같은 개념에 여러 이름 | **용어 통일** — UL과 함께 적용 |
| 이름이 거짓말 | **타입과 일치하는 이름** — `accountList`가 Set이면 `accounts` |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[UL]] | UL은 "도메인 용어와 일치", IRN은 "이름이 의도를 드러내야" — UL이 어휘 선택, IRN이 표현력. 함께 적용 |
| [[POLA]] | 의도를 드러내는 이름은 놀라움을 줄인다 — POLA의 첫 단계 |
| [[COMMENT-WHY]] | 이름이 의도를 드러내면 주석 불필요. 주석이 필요하면 이름을 먼저 의심 |
| [[DRY]] | 같은 개념을 다른 이름으로 부르면 DRY 위반 — 이름의 통일이 지식의 통일 |

## 주의

- 짧은 스코프(루프 인덱스, 람다 변수)에서는 짧은 이름이 적절. `for (i in 0..n)`은 OK
- 너무 긴 이름(`theListOfAllAccountsActiveInLastSevenDays`)도 의도를 흐린다 — `recentlyActiveAccounts` 정도
- 도메인이 아직 굳지 않은 초기에는 이름이 자주 바뀐다. **rename refactoring을 두려워하지 마라**
- 영어가 모국어가 아닌 팀에서는 합의된 용어집이 필요. 한글 주석/영문 코드 혼용 시 동의어 폭증 위험
