# Table Type Color Theory

DB 테이블 아키타입별 색상 배정 이론. dep-graph의 아키텍처 레이어 색상 체계를 DB 도메인에 매핑.

## 원칙

1. **의미론적 매핑**: 색상이 테이블의 역할을 직관적으로 전달
2. **구분 가능성**: 인접 유형 간 충분한 색상 차이
3. **접근성**: 색맹/색약 사용자를 위해 밝기 차이 확보
4. **다크/라이트 호환**: 두 테마 모두에서 가시성 유지

## 유형별 색상

| 유형 | 색상 | Hex | 근거 |
|------|------|-----|------|
| **junction** | Purple | `#7B1FA2` | 연결/교차의 시각적 메타포. 두 테이블 사이의 다리 역할 |
| **auth** | Red | `#C62828` | 보안/경고의 보편적 색상. 민감한 데이터 강조 |
| **audit** | Orange | `#E65100` | 주의/기록의 의미. Red(보안)과 구별되면서 주의 환기 |
| **config** | Brown | `#5D4037` | 토대/설정의 안정감. 인프라 성격 |
| **enum** | Teal | `#00695C` | 작고 고정된 값의 차분함. 참조 전용 테이블 |
| **dimension** | Blue | `#1E88E5` | 분석/분류의 명료함. 많은 테이블이 참조하는 핵심 엔티티 |
| **fact** | Deep Blue | `#1565C0` | 기본/핵심 데이터. 가장 보편적이므로 중립적 톤 |

## dep-graph 레이어 매핑

| dep-graph Role | schema-graph Type | 공통점 |
|----------------|-------------------|--------|
| entity/model (Blue) | dimension/fact (Blue) | 핵심 데이터 구조 |
| controller/api (Purple) | junction (Purple) | 연결/인터페이스 역할 |
| exception (Red) | auth (Red) | 주의가 필요한 영역 |
| repository (Orange) | audit (Orange) | 데이터 접근/기록 |
| config (Brown) | config (Brown) | 설정/인프라 (동일) |
| hook (Teal) | enum (Teal) | 보조적/고정적 역할 |

## 스키마별 색상 (그룹 모드)

스키마/네임스페이스별 색상은 dep-graph과 동일한 12색 팔레트를 순환 배정:

```
#4FC3F7, #81C784, #FFB74D, #E57373,
#BA68C8, #4DD0E1, #FFD54F, #A1887F,
#90A4AE, #F06292, #AED581, #7986CB
```

등장 순서대로 배정. 12개 초과 시 순환.
