---
name: IDEMPOTENCY
full_name: Idempotency (멱등성)
category: process
origin: 수학 (f(f(x)) = f(x))
one_liner: "같은 작업을 여러 번 수행해도 결과가 동일하다"
---

# IDEMPOTENCY — 멱등성

## 정의

> "같은 연산을 1번 하든 100번 하든 결과가 같다."

네트워크 재시도, 크론 중복 실행, 롤백 후 재배포, 스크립트 재실행 —
멱등성이 없으면 모두 위험하다.

## 핵심 판단

- **"이거 다시 실행해도 돼?"** — "안 돼"면 멱등성 위반
- **"두 번 실행하면 어떻게 돼?"** — 결과가 달라지면 위반

## 적용 범위

| 영역 | 멱등해야 하는 것 | 예시 |
|------|-----------------|------|
| API | PUT, DELETE | `PUT /users/1` 여러 번 = 같은 결과 |
| 스크립트 | 설정, 초기화, 마이그레이션 | `init.sh` 여러 번 실행 가능 |
| 배포 | 배포 파이프라인 전체 | 같은 커밋 재배포 = 같은 상태 |
| DB | 마이그레이션, 시드 | `CREATE IF NOT EXISTS`, `UPSERT` |
| 인프라 | Terraform, Ansible | `terraform apply` 여러 번 = 같은 인프라 |
| 메시지 | 이벤트 처리, 큐 컨슈머 | 같은 메시지 2번 처리해도 안전 |

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| `INSERT` without `ON CONFLICT` / `IF NOT EXISTS` | grep SQL 패턴 |
| `CREATE TABLE` without `IF NOT EXISTS` | grep DDL |
| API POST가 중복 보호 없음 | idempotency key 부재 확인 |
| 카운터 증가 (`+=`, `INCREMENT`) without 중복 체크 | grep 패턴 |
| `append` / `push` without 중복 확인 | 리스트 조작 패턴 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "다시 실행하면 안 돼" 주석/문서 | 멱등성 결여를 인정하는 것 |
| 수동 상태 확인 후 실행 패턴 | "먼저 X인지 확인하고 실행" — 자동화되어야 |
| 부분 실패 시 재시도 불가 | 트랜잭션 중간에 멈추면 복구 불가 |
| 환경에 따라 다른 결과 | 같은 입력인데 타이밍/순서에 따라 달라짐 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 모든 쓰기 작업이 멱등하게 설계됨 |
| **WARN** | 대부분 멱등하나 일부 edge case에서 중복 위험 |
| **FAIL** | 재실행 시 데이터 오염/중복/오류 발생 |

## 멱등성 확보 패턴

| 상황 | 패턴 |
|------|------|
| DB 삽입 | `UPSERT` / `INSERT ... ON CONFLICT DO NOTHING/UPDATE` |
| 리소스 생성 | `CREATE IF NOT EXISTS`, idempotency key |
| API 호출 | 클라이언트가 idempotency key 전송, 서버가 중복 감지 |
| 파일 작성 | 임시 파일 → atomic rename (덮어쓰기 = 멱등) |
| 스크립트 | guard clause: "이미 적용되었으면 skip" |
| 이벤트 처리 | 처리 완료 기록 (processed_events 테이블), 중복 무시 |
| 카운터 | `SET count = X` (절대값) > `INCREMENT` (상대값) |

## 주의

- 멱등성 ≠ 안전성. DELETE는 멱등하지만 안전하지 않다 (부수효과 있음)
- 멱등성의 단위를 명확히: 개별 API 호출? 전체 스크립트? 배포 파이프라인?
- 멱등성 구현 시 성능 trade-off를 고려 (매번 존재 여부 확인 비용)
- 분산 시스템에서는 "정확히 1번(exactly-once)"보다 "최소 1번(at-least-once) + 멱등 처리"가 현실적
