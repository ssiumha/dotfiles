---
name: POSTELS-LAW
full_name: "Postel's Law (Robustness Principle)"
category: contract
origin: Jon Postel, RFC 761 (1980)
one_liner: "보낼 때는 엄격하게, 받을 때는 관대하게"
---

# POSTELS-LAW — Postel's Law (Robustness Principle)

## 정의

> "Be conservative in what you send, be liberal in what you accept."

TCP 설계자 Jon Postel이 제안한 프로토콜 설계 원칙. 송신(send)은 스펙에 정확히 맞추고, 수신(accept)은 약간의 변형을 허용하면 시스템 간 연동이 견고해진다.

### 요청/응답 관점

| 내 역할 | 보낼 때 (송신) | 받을 때 (수신) |
|---------|---------------|---------------|
| **클라이언트** | 요청을 스펙에 정확히 맞춰 보낸다 | 응답에 예상 밖의 필드가 있어도 무시하고 처리 |
| **서버** | 응답을 스펙에 정확히 맞춰 보낸다 | 요청에 추가 필드, 대소문자 차이 등을 허용 |

## 핵심 판단

- **"알 수 없는 필드를 받으면 에러를 내는가?"** — strict parsing = 취약한 연동
- **"보내는 데이터가 스펙에 정확히 부합하는가?"** — 느슨한 송신 = 상대에게 부담 전가
- **"버전 차이에 의한 필드 추가/제거를 견디는가?"** — 견디면 robust

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| JSON 파싱 시 additionalProperties: false (수신 측) | OpenAPI/JSON Schema에서 수신 스키마 확인 |
| 알 수 없는 필드에 에러 반환 | 요청 처리 코드에서 unknown field rejection 확인 |
| 응답에 스펙 외 필드 포함 (송신 측 느슨) | 응답 직렬화에서 필터링 없이 전체 dump |
| 대소문자/공백에 민감한 파싱 | string comparison에서 trim/lowercase 부재 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| API 버전 올리면 클라이언트가 깨짐 | 수신 측이 너무 strict |
| "이 필드 없으면 500 에러" (optional이어야 할 것이 required) | precondition이 과도하게 강함 |
| 느슨한 응답 포맷으로 클라이언트가 고생 | 송신 측이 스펙을 안 지킴 |
| 한쪽 시스템 변경이 연쇄 장애 유발 | 양쪽 모두 경직 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 송신은 스펙 준수, 수신은 unknown field 허용, 버전 차이 견딤 |
| **WARN** | 일부 엔드포인트에서 strict parsing OR 응답에 비표준 필드 혼재 |
| **FAIL** | 수신 측이 모든 unknown field 거부 OR 송신이 스펙 무시 OR 버전 변경 시 연쇄 장애 |

## 적용 영역

```
시스템 경계에서 적용:
  API (REST, GraphQL, gRPC)
  메시지 큐 (이벤트 스키마)
  파일 포맷 (CSV, JSON, XML 파싱)
  설정 파일 (unknown key 처리)
  
내부 코드에서는 오히려 strict가 맞다:
  함수 시그니처 — 타입 시스템으로 엄격히 (DbC)
  내부 데이터 구조 — 정확한 타입 사용
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| API 버전업 시 클라이언트 대량 장애 | **Forward Compatibility** — unknown field 무시, optional 필드 기본값 |
| 수신 데이터 파싱이 너무 strict | **Tolerant Reader 패턴** — 필요한 필드만 추출, 나머지 무시 |
| 응답 포맷이 일관성 없음 | **Response DTO / Serializer** — 스펙에 맞는 필드만 명시적 반환 |
| 이벤트 스키마 변경이 소비자를 깨뜨림 | **Schema Evolution** — 필드 추가는 허용, 삭제/변경은 버전 관리 |

## 주의

- Postel's Law는 **시스템 경계**에 적용하는 것. 내부 코드에서 "관대하게 받기"는 버그를 숨길 수 있다
- 보안 컨텍스트에서는 "관대한 수신"이 위험할 수 있다. 입력 검증/새니타이징은 별개 문제
- 과도한 관대함은 "Garbage In, Garbage Out" — 받아들이되, 받아들일 수 있는 범위는 정의해야
- 최근에는 "Postel's Law가 프로토콜 발전을 방해한다"는 비판도 있다 (엄격한 파싱이 호환성 문제를 빨리 드러냄)
