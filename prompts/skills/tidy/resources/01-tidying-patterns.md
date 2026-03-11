---
name: tidying-patterns
description: 15 tidying patterns from Kent Beck's "Tidy First?"
---

# Tidying Patterns

Kent Beck의 "Tidy First?"에서 소개된 15가지 tidying 패턴입니다.

## 1. Guard Clause

깊은 중첩을 early return으로 변환.

**Before**:
```typescript
function process(user) {
  if (user) {
    if (user.isActive) {
      if (user.hasPermission) {
        // 실제 로직
      }
    }
  }
}
```

**After**:
```typescript
function process(user) {
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission) return;

  // 실제 로직
}
```

**감지**: 중첩 깊이 3 이상, if-else 체인
**주의**: guard clause가 7-8개 이상이면 역효과 — 함수 분리를 고려할 것

## 2. Dead Code

사용하지 않는 코드 제거.

**대상**:
- 호출되지 않는 함수
- 사용되지 않는 변수
- 주석 처리된 코드 블록
- 도달 불가능한 코드

**Before**:
```typescript
function processOrder(order: Order) {
  // const tax = calculateTax(order);
  // const shipping = getShipping(order);
  // const total = order.amount + tax + shipping;

  const total = order.amount;
  return total;
}
```

**After**:
```typescript
function processOrder(order: Order) {
  const total = order.amount;
  return total;
}
```

**주의**: git history에 남으므로 과감히 삭제. 필요 시 `git log -p`로 복구 가능.

## 3. Normalize Symmetries

비슷한 로직의 일관성 확보.

**Before**:
```typescript
// 혼재된 스타일
const a = items.filter(x => x.active);
const b = items.filter(function(x) { return x.enabled; });
```

**After**:
```typescript
// 일관된 스타일
const a = items.filter(x => x.active);
const b = items.filter(x => x.enabled);
```

> "차이가 있으면 독자는 의미 있는 차이라고 기대한다" — 불필요한 차이를 제거하여 진짜 차이에 집중하게 한다.

**⚠️ 우연한 유사성 vs 진짜 중복**

| 구분 | 진짜 중복 | 우연한 유사성 |
|------|----------|--------------|
| 정의 | 동일 비즈니스 로직 | 구현 유사, 도메인 상이 |
| 예시 | `validateEmail()` 중복 호출 | Song.audioAsset vs Match.mrAsset |
| 특징 | 변경 시 함께 바뀜 | 독립적 진화 가능 |
| 행동 | 통합 | 유지 |

**통합 금지 신호**:
- 서로 다른 엔티티/도메인
- 제네릭/동적 접근 필요 (타입 불일치)
- 통합 시 조건문 증가
- 향후 독립 변경 가능성

## 4. New Interface, Old Implementation

새 인터페이스로 감싸서 점진적 개선.

**Before**:
```typescript
// 레거시 API
legacyDb.query("SELECT * FROM users WHERE id = " + id);
```

**After**:
```typescript
// 새 인터페이스
function findUserById(id: string): User {
  return legacyDb.query("SELECT * FROM users WHERE id = " + id);
}
```

**용도**: 레거시 코드를 점진적으로 개선할 때

> "SW 설계의 미시적 본질" — 원하는 인터페이스를 먼저 만들고, 내부는 기존 구현을 호출. 호출자를 점진적으로 새 인터페이스로 전환한 뒤 내부 구현을 교체.

## 5. Reading Order

코드를 읽기 쉬운 순서로 재배치.

**원칙**:
- 호출하는 함수가 위, 호출되는 함수가 아래
- public 메서드 → private 메서드
- 높은 추상화 → 낮은 추상화

## 6. Cohesion Order

관련 코드를 가깝게 배치.

**Before**:
```typescript
const name = user.name;
const email = user.email;
// ... 100줄의 다른 코드 ...
validateName(name);
validateEmail(email);
```

**After**:
```typescript
const name = user.name;
validateName(name);

const email = user.email;
validateEmail(email);
```

## 7. Move Declaration and Initialization Together

선언과 초기화를 가깝게.

**Before**:
```typescript
let result;
// ... 여러 줄 ...
result = calculate();
```

**After**:
```typescript
// ... 여러 줄 ...
const result = calculate();
```

**보너스**: `let` → `const` 변환 가능해짐

## 8. Explaining Variable

복잡한 표현식에 의도를 담은 이름 부여.

**Before**:
```typescript
if (user.age >= 18 && user.country === 'KR' && !user.isBanned) {
  // ...
}
```

**After**:
```typescript
const isEligibleKoreanAdult = user.age >= 18 && user.country === 'KR' && !user.isBanned;
if (isEligibleKoreanAdult) {
  // ...
}
```

## 9. Explaining Constant

매직 넘버/문자열에 이름 부여.

**Before**:
```typescript
if (retryCount > 3) { ... }
setTimeout(fn, 86400000);
```

**After**:
```typescript
const MAX_RETRIES = 3;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;

if (retryCount > MAX_RETRIES) { ... }
setTimeout(fn, ONE_DAY_MS);
```

## 10. Explicit Parameters

암묵적 의존성을 명시적 파라미터로.

**Before**:
```typescript
function processOrder() {
  const user = getCurrentUser(); // 전역/컨텍스트 의존
  // ...
}
```

**After**:
```typescript
function processOrder(user: User) {
  // ...
}
```

## 11. Chunk Statements

관련 문장들을 빈 줄로 그룹화.

**Before**:
```typescript
const user = getUser();
const orders = getOrders(user.id);
const total = calculateTotal(orders);
sendEmail(user.email, total);
logActivity(user.id, 'order_summary');
```

**After**:
```typescript
const user = getUser();
const orders = getOrders(user.id);
const total = calculateTotal(orders);

sendEmail(user.email, total);
logActivity(user.id, 'order_summary');
```

## 12. Extract Helper

반복되는 코드 패턴 추출.

**조건**: 3회 이상 반복될 때만 (premature abstraction 주의)

> "추상적으로 생각할 준비가 되면 새 인터페이스가 등장한다" — 패턴이 보이기 전에 추출하지 말 것.

**Before**:
```typescript
const userJson = JSON.stringify(user);
localStorage.setItem('user', userJson);

const settingsJson = JSON.stringify(settings);
localStorage.setItem('settings', settingsJson);
```

**After**:
```typescript
function saveToStorage(key: string, value: unknown) {
  localStorage.setItem(key, JSON.stringify(value));
}

saveToStorage('user', user);
saveToStorage('settings', settings);
```

**⚠️ 추출 전 확인**: "Normalize Symmetries"의 "우연한 유사성 vs 진짜 중복" 참조.
타입 안전성 저하 또는 조건문 증가 시 유지.

## 13. One Pile

흩어진 코드를 일단 한 곳에 모으기.

**용도**: 리팩토링 전 단계로, 전체 그림 파악

> 인라인 후 재구성이 분산 상태에서 이해하는 것보다 유리할 수 있다. 흩어진 조각을 한 곳에 모아야 전체 패턴이 보인다.

**주의**: 이후 다시 분리 필요

## 14. Delete Redundant Comments

코드와 중복되는 주석 제거.

**Before**:
```typescript
// 사용자 이름을 가져온다
const userName = user.name;

// i를 1 증가시킨다
i++;
```

**After**:
```typescript
const userName = user.name;
i++;
```

**유지할 주석**: "왜(why)"를 설명하는 주석

## 15. Expand Abbreviations

약어를 의미 있는 전체 이름으로 확장.

**Before**:
```typescript
const d = new Date() - startTime;
function proc(x) { ... }
const cfg = loadConfig();
```

**After**:
```typescript
const elapsedMs = new Date() - startTime;
function processUserRequest(request) { ... }
const config = loadConfig();
```

> 약어는 작성자에겐 자명하지만 독자에겐 해독 비용. 이름을 풀어쓰면 코드가 산문처럼 읽힌다. 단, 널리 통용되는 약어(id, url, http 등)는 유지.

---

## 패턴 선택 가이드

| 상황 | 추천 패턴 |
|------|----------|
| 코드 이해가 어려움 | Explaining Variable, Expand Abbreviations, Reading Order |
| 중첩이 깊음 | Guard Clause |
| 일관성 없음 | Normalize Symmetries |
| 레거시 개선 | New Interface Old Implementation |
| 정리 시작점 모름 | One Pile → 분리 |
