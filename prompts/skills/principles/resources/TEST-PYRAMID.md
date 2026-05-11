---
name: TEST-PYRAMID
full_name: "Test Pyramid"
category: testing
origin: Mike Cohn *Succeeding with Agile* (2009), 확장은 Martin Fowler. 변형: Kent C. Dodds *Testing Trophy* (2018)
one_liner: "단위 테스트 많이, 통합 테스트 적당히, E2E는 소수 — 아이스크림 콘 역피라미드를 피하라"
---

# TEST-PYRAMID — 테스트 레벨 경제학

## 정의

```
         /\
        /  \      E2E       (소수, 느림, 비쌈, 플레이키)
       /----\
      /      \    Integration  (적당, 중간)
     /--------\
    /          \  Unit          (다수, 빠름, 싸고, 안정적)
   /____________\
```

테스트는 **낮은 레벨일수록** 빠르고, 싸고, 결정적이다. 높은 레벨일수록 느리고, 비싸고, 플레이키하다. 같은 행위를 검증할 수 있다면 **가장 낮은 레벨에서** 테스트한다.

## 핵심 판단

- **"이 테스트를 한 단계 낮은 레벨에서 쓸 수 있는가?"** → 가능한데 굳이 높은 레벨이면 위반
- **"E2E가 단위 테스트보다 많은가?"** → 아이스크림 콘 역피라미드
- **"피드백 루프가 얼마나 걸리는가?"** → E2E만 있으면 분 단위, 단위면 초 단위

## 테스트 레벨 판별

### 단위 테스트 (Unit)
- 단일 함수/클래스 대상
- 외부 의존성 없음 (또는 Fake/Stub로 격리)
- ms 단위 실행

### 통합 테스트 (Integration)

아래 중 2개 이상이면 통합 테스트:
- 실제 DB 연결 (SQLite in-memory 포함)
- HTTP 요청 (supertest, TestClient, MockMvc)
- 여러 모듈/서비스 간 상호작용
- 메시지 큐, 캐시 등 인프라 컴포넌트 사용

### E2E 테스트
- Playwright, Cypress, Selenium 등 브라우저 자동화
- 전체 앱 서버 기동 후 테스트
- 실제 외부 API 호출 (또는 API mock 서버)

## 위반 신호

### 기계적 검증

| 신호 | 검증 방법 |
|------|-----------|
| E2E 테스트 수 > 단위 테스트 수 | 디렉토리 파일 수 비교 |
| E2E 스위트 런타임 > 전체의 60% | 프레임워크 리포트 |
| 통합 테스트에서 내부 SQL 직접 검증 | grep `SELECT.*FROM`, 컬럼 인덱스 접근 |
| E2E에서 단순 기능 검증 | "로그인 버튼 클릭하면 홈으로 이동" 류 반복 |

### 판단 필요

| 신호 | 설명 |
|------|------|
| "단위 테스트 쓸 수 있는데 통합 테스트로 썼다" | 경로 탐색으로 해결 가능한 것을 DB 연결로 검증 |
| "CI가 30분 걸려요" | 피드백 루프 붕괴 |
| "가끔 E2E가 깨지는데 재시도하면 됨" | 플레이키 E2E 남용 |
| 피라미드 없이 E2E만 있음 | "UI로 다 테스트되니까 됐다" |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | Unit ≫ Integration ≫ E2E. 단위 비율 70%+, E2E <10%. 피드백 루프 <1분 |
| **WARN** | 균형 붕괴 조짐 (E2E 비율 20%+ OR 통합이 단위를 초과) |
| **FAIL** | 역피라미드 (E2E > Integration > Unit) OR E2E만 존재 OR CI 런타임의 대부분이 E2E |

## 추상화 레벨 (통합/E2E 전용)

통합 테스트는 **컴포넌트 간 계약**을 검증해야 한다. 구현 상세(SQL, 로그 포맷)를 직접 보면 안 된다.

```python
# ❌ 과도한 상세 — SQL 직접 검증
def test_create_user(client, db):
    client.post("/users", json={"name": "Alice"})
    result = db.execute("SELECT * FROM users WHERE name = 'Alice'")
    assert result.fetchone()[2] == "Alice"    # 컬럼 인덱스 결합

# ✅ 계약 기반 — API 응답 검증
def test_create_user(client):
    response = client.post("/users", json={"name": "Alice"})
    assert response.status_code == 201
    assert response.json()["name"] == "Alice"
```

반대로 너무 높은 추상화도 문제:
- ❌ "페이지가 에러 없이 로드됨" — 실제 기능 미검증
- ✅ "사용자가 주문을 완료하면 확인 이메일이 발송됨"

## Testing Trophy (변형)

Kent C. Dodds는 현대 프론트엔드 맥락에서 **통합 테스트 비중 확대**를 주장한다:

```
       ___
      /   \    E2E
     /-----\
    /       \  Integration  ← 가장 두꺼움
   /---------\
  /           \  Unit
 /_____________\
        |
    Static (type check, lint)
```

근거: 단위 테스트가 Mock 과다로 fragile해지기 쉬움. 통합 레벨에서 검증하면 리팩토링 안정성 + 확신 둘 다 얻는다.

**Pyramid vs Trophy 선택**:
- 순수 로직(계산, 변환, 도메인 규칙) 많음 → Pyramid
- I/O 바운드 / 프레임워크 의존 많음 (React, FastAPI route) → Trophy 스타일

## 설계 시 체크리스트

- [ ] 이 기능의 **핵심 로직을 단위 테스트**로 뽑아낼 수 있는가? → 가능하면 단위에서 검증
- [ ] 이 통합 테스트가 **계약 검증**인가, 구현 검증인가?
- [ ] E2E로 검증할 가치가 있는가? → "실제 사용자 여정"이면 OK, 단순 기능이면 단위/통합으로
- [ ] E2E 개수가 피드백 루프를 망치는가? → 선별 필요

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[SELF-TESTING-CODE]] | Pyramid는 비율, Self-Testing은 빌드 결합 — Pyramid가 잘 잡혀도 빌드와 분리되면 무용. 함께 충족해야 |
| [[KISS]] | 낮은 레벨 테스트가 단순하다 |
| [[FIRST]] | 단위 테스트가 FIRST 만족하기 쉽다 (통합/E2E는 Fast가 완화됨) |
| [[GOODHARTS-LAW]] | "E2E 커버리지 X%" 목표화 시 역피라미드 발생 |
| [[TEST-BEHAVIOR]] | 어느 레벨에서든 "행위 검증"이 우선 — 레벨 선택과 별개의 축 |
| [[BEYONCE-RULE]] | 중요한 여정은 E2E로 보호. 단, 단위/통합으로 대체 가능한 건 아래로 |

## 주의

- 피라미드 비율은 프로젝트 성격에 따라 다르다. "7:2:1" 같은 숫자 맹신 금지
- 통합 테스트 1건이 단위 테스트 여러 건을 대체할 수 있으면 오히려 효율적 (Trophy 철학)
- E2E를 제거하라는 원칙이 아니다. **적정 수**를 유지하라는 것
- 역피라미드는 대개 "단위 테스트 쓰기 어려운 설계" 신호 — 설계를 보라
