
# 통합/E2E 테스트 리뷰 기준

통합 테스트와 E2E 테스트의 품질을 평가하는 기준. 단위 테스트와 다른 관점이 필요하다.

---

## 통합 테스트 판별

아래 특성 중 2개 이상이면 통합 테스트로 분류한다:

- 실제 DB 연결 (SQLite in-memory 포함)
- HTTP 요청 (supertest, TestClient, MockMvc)
- 여러 모듈/서비스 간 상호작용
- 메시지 큐, 캐시 등 인프라 컴포넌트 사용

## E2E 테스트 판별

- Playwright, Cypress, Selenium 등 브라우저 자동화
- 전체 앱 서버 기동 후 테스트
- 실제 외부 API 호출 (또는 API mock 서버)

---

## 리뷰 체크리스트

### 1. 추상화 레벨

| 항목 | 상태 기준 |
|------|----------|
| 적절한 레벨 | ✅ 비즈니스 행위를 테스트 (HTTP 요청 → 응답 검증) |
| 과도한 상세 | ⚠️ 내부 SQL 쿼리, 프레임워크 내부 상태 검증 |
| 너무 높은 추상화 | ⚠️ "페이지가 에러 없이 로드됨" 수준만 검증 |

**원칙**: 통합 테스트는 컴포넌트 간 **계약(contract)**을 검증해야 한다.

```python
# ❌ 과도한 상세 — SQL 직접 검증
def test_create_user(client, db):
    client.post("/users", json={"name": "Alice"})
    result = db.execute("SELECT * FROM users WHERE name = 'Alice'")
    assert result.fetchone()[2] == "Alice"    # 컬럼 인덱스 의존

# ✅ 계약 기반 — API 응답 검증
def test_create_user(client):
    response = client.post("/users", json={"name": "Alice"})
    assert response.status_code == 201
    assert response.json()["name"] == "Alice"
```

### 2. 데이터 격리

| 항목 | PASS | WARN | FAIL |
|------|------|------|------|
| DB 격리 | 트랜잭션 롤백/테스트별 DB | 공유 DB + 순서 의존 | 격리 없음 |
| 파일 격리 | tmp 디렉토리 사용 | 고정 경로 + 정리 | 고정 경로 + 미정리 |
| 네트워크 격리 | Mock 서버 / VCR | 실제 호출 + 재시도 | 실제 호출 + 무격리 |

**감지 패턴**:
```
# DB 격리 미흡
Grep: DROP TABLE|TRUNCATE|DELETE FROM  (setUp/tearDown에서)

# 파일 격리 미흡
Grep: open\(["']/tmp/|open\(["']\./ (하드코딩된 경로)
```

### 3. Flakiness 패턴

비결정적 실패를 유발하는 패턴을 감지한다:

| 패턴 | 심각도 | 설명 |
|------|:---:|------|
| `time.sleep()` / `setTimeout` | Medium | 고정 대기 시간 → 환경에 따라 부족 |
| 타임스탬프 비교 | Medium | 실행 시점에 따라 결과 변동 |
| 랜덤 데이터 (seed 없음) | Medium | 비결정적 입력 |
| 포트 하드코딩 | Medium | 포트 충돌 가능 |
| 공유 상태 의존 | High | 테스트 실행 순서에 따라 결과 변동 |

```python
# ❌ Flaky — 고정 대기
def test_async_processing():
    trigger_job()
    time.sleep(2)                          # 환경에 따라 부족
    assert get_status() == "completed"

# ✅ 폴링/이벤트 기반
def test_async_processing():
    trigger_job()
    wait_until(lambda: get_status() == "completed", timeout=5)
```

### 4. Setup/Teardown 완전성

| 항목 | PASS | FAIL |
|------|------|------|
| Setup | 테스트에 필요한 상태를 명시적으로 구성 | 이전 테스트 결과에 의존 |
| Teardown | 생성한 리소스를 모두 정리 | 리소스 누수 (커넥션, 파일, 프로세스) |
| 에러 시 Teardown | finally/fixture로 에러에도 정리 보장 | try만 있고 finally 없음 |

**감지 패턴**:
```
# Teardown 누락 가능성
Grep: setUp|beforeEach|beforeAll → 대응하는 tearDown|afterEach|afterAll 확인

# 리소스 누수
Grep: open\(|connect\(|create_engine → close/disconnect/dispose 확인
```

### 5. E2E 특화 기준

E2E 테스트에만 적용되는 추가 기준:

| 항목 | PASS | WARN |
|------|------|------|
| 선택자 안정성 | data-testid, role 기반 | CSS 클래스, XPath |
| 대기 전략 | waitFor, 조건부 대기 | sleep, 고정 시간 |
| 테스트 데이터 | seed 스크립트, API 생성 | UI 통해 수동 생성 |
| 스크린샷/비디오 | 실패 시 자동 캡처 | 없음 |

```typescript
// ❌ 불안정한 선택자
await page.click('.btn-primary.submit-form');

// ✅ 안정적 선택자
await page.click('[data-testid="submit-button"]');
await page.getByRole('button', { name: 'Submit' }).click();
```

---

## 심각도 매핑

| 문제 | 심각도 |
|------|:---:|
| 격리 없는 공유 상태 | High |
| Teardown 누락으로 리소스 누수 | High |
| sleep 기반 대기 | Medium |
| 과도한 상세 검증 | Medium |
| 불안정한 CSS 선택자 | Medium |
| Fixture 과대 | Low |
| 스크린샷 미설정 | Low |
