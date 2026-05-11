---
name: ISP
full_name: Interface Segregation Principle
category: contract
origin: Robert C. Martin (SOLID)
one_liner: "클라이언트가 사용하지 않는 메서드에 의존하지 않아야 한다"
---

# ISP — Interface Segregation Principle

## 정의

> "No client should be forced to depend on methods it does not use."

하나의 거대한 인터페이스보다 용도별로 작게 쪼갠 인터페이스가 낫다. 클라이언트는 자기가 실제로 사용하는 메서드만 포함된 인터페이스에 의존해야 한다.

## 핵심 판단

- **"이 인터페이스의 모든 메서드를 사용하는 클라이언트가 있는가?"** — 없으면 분리 대상
- **"인터페이스에 메서드 추가 시 관계없는 구현체도 변경해야 하는가?"** — 그렇다면 위반
- **"빈 구현 / NotImplementedError가 있는가?"** — ISP 위반의 대표 증상

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 인터페이스/추상클래스의 메서드 수 과다 | 메서드 수 카운트 (>7이면 검토) |
| 빈 구현 / throw NotImplementedError | grep `NotImplementedError\|not.implemented\|pass$\|\{\s*\}` |
| 구현체가 일부 메서드만 실제 구현 | 구현체별 실제 로직 있는 메서드 비율 |
| God Interface (모든 것을 담은 인터페이스) | 단일 인터페이스에 대한 implements 수 + 메서드 수 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "이 기능에는 저 메서드 필요 없는데…" | 불필요한 의존 |
| 인터페이스 변경 시 무관한 모듈이 영향받음 | 결합도 과다 |
| 하나의 역할에 여러 관심사 혼재 | SoC + ISP 동시 위반 |
| 모든 구현체가 공통으로 사용하는 메서드가 절반 이하 | 분리 필요 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 인터페이스가 역할별로 분리, 빈 구현 0, 클라이언트가 의존 메서드 전부 사용 |
| **WARN** | 인터페이스 메서드 7-10개 OR 빈 구현 1-2개 |
| **FAIL** | 인터페이스 메서드 10개+ OR 빈 구현 3개+ OR God Interface |

## Fat Interface → 분리 예시

```
// 위반: Fat Interface
interface MultiFunctionDevice {
  print(doc)
  scan(doc)
  fax(doc)
  staple(doc)
}
// SimplePrinter는 print만 필요한데 scan, fax, staple도 구현해야 함

// 개선: 역할별 분리
interface Printer  { print(doc) }
interface Scanner  { scan(doc) }
interface Faxer    { fax(doc) }

// 필요한 것만 구현
class SimplePrinter implements Printer { ... }
class AllInOne implements Printer, Scanner, Faxer { ... }
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| God Interface | **Role Interface 분리** — 클라이언트 역할별로 인터페이스 분리 |
| 빈 구현이 반복 | **인터페이스 분리 + Optional 메서드 제거** |
| 단일 클래스가 너무 많은 인터페이스 구현 | **SRP 검토** — 클래스 자체가 너무 많은 역할 |
| API 응답이 항상 전체 필드 반환 | **필요한 필드만 반환** — GraphQL 패턴 또는 DTO 분리 |

## 주의

- 인터페이스를 너무 잘게 쪼개면 관리 비용 증가. 1메서드 인터페이스가 20개면 그것도 문제
- ISP는 인터페이스 설계 원칙이지 구현 분리 원칙이 아니다. 하나의 클래스가 여러 작은 인터페이스를 구현하는 것은 정상
- TypeScript에서는 `Pick<T, K>` / `Omit<T, K>`로 기존 타입에서 필요한 부분만 추출할 수 있다
- REST API 설계에서도 적용: 클라이언트가 불필요한 필드까지 처리하게 강제하지 않는다
