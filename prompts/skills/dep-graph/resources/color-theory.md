# Role-Based Color Scheme: Design Rationale

dep-graph의 role별 색상 체계의 이론적 근거와 설계 원칙을 정리한다.

## 이론적 배경

### Peter Coad의 Object Modeling in Color (2000)

소프트웨어 객체를 역할별로 4가지 색상 원형(archetype)으로 분류한 모델링 방법론:

| Archetype | 색상 | 의미 |
|-----------|------|------|
| Moment-Interval | Pink | 비즈니스 이벤트, 트랜잭션 |
| Role | Yellow | 역할, 참여자 |
| Description | Blue | 카탈로그, 분류 |
| Party/Place/Thing | Green | 실체, 엔티티 |

이 모델의 핵심 통찰: **객체의 아키텍처 역할에 따라 색상을 배정하면, 다이어그램을 처음 보는 사람도 즉시 구조를 파악할 수 있다.**

### 색상 온도 이론 (Color Temperature)

색상의 심리적 온도감을 아키텍처 레이어의 특성에 매핑:

| 온도 | 색상 계열 | 아키텍처 특성 | 해석 |
|------|----------|-------------|------|
| Cool | Blue | 안정적, 정적 | 데이터를 담는 것 |
| Warm | Green | 활성적, 동적 | 일을 하는 것 |
| Hot | Purple | 외부 노출, 진입점 | 외부에서 들어오는 것 |
| Neutral | Orange/Brown | 보조적, 인프라 | 외부로 나가는 것 |

## 색상 매핑

### Architecture Layer x Color Temperature

```
Architecture Layer     Role              Color         Hex
---------------------------------------------------------------
Data Layer (Cool)      entity            Deep Blue     #1565C0
                       model             Blue          #1E88E5
                       dto               Light Blue    #42A5F5

Logic Layer (Warm)     service           Green         #2E7D32
                       handler           Light Green   #43A047

Interface (Hot)        controller        Purple        #7B1FA2
                       page              Violet        #8E24AA
                       api               Light Purple  #AB47BC

Infra (Neutral)        repository        Orange        #E65100
                       client            Amber         #FF8F00
                       config            Brown         #5D4037

Cross-cutting          exception         Red           #C62828
                       util              Grey          #546E7A
                       hook              Teal          #00695C
                       component         Cyan          #00838F
                       store             Deep Cyan     #006064
                       type              Blue Grey     #455A64
                       other             Light Grey    #90A4AE
```

### 채도 규칙

같은 레이어 내에서 **핵심 역할일수록 진한 색상**(높은 채도, 낮은 명도)을 사용:

- Data: entity(Deep Blue) > model(Blue) > dto(Light Blue)
- Interface: controller(Purple) > page(Violet) > api(Light Purple)

## 사용자 직관 가이드

그래프를 보고 즉시 이해할 수 있는 시각적 규칙:

| 보이는 색상 | 의미 | 예시 |
|-------------|------|------|
| Blue 계열 | 데이터를 담는 것 | Entity, Model, DTO |
| Green 계열 | 일을 하는 것 | Service, Handler |
| Purple 계열 | 외부에서 들어오는 것 | Controller, Page, API endpoint |
| Orange/Brown 계열 | 외부로 나가는 것 | Repository, Client, Config |
| Red | 예외 경로 | Exception |
| Grey/Teal 계열 | 보조 역할 | Util, Type, Hook, Component |

## 언어 간 일관성

같은 역할은 프로그래밍 언어가 달라도 동일한 색상을 사용한다:

| 역할 | Java | TypeScript | Python | 색상 |
|------|------|-----------|--------|------|
| Controller | `@RestController` | - | `_view.py`, `_router.py` | Purple |
| Service | `@Service` | `services/` | `_service.py` | Green |
| Page | - | `page.tsx` | - | Violet |
| Entity | `@Entity` | - | `models.py` | Deep Blue |
| Component | - | `*.tsx` (in `components/`) | - | Cyan |
| Repository | `@Repository` | - | - | Orange |

이를 통해 Java 백엔드 + TypeScript 프론트엔드가 혼합된 프로젝트에서도 **동일한 시각적 언어**로 읽을 수 있다.

## 설계 판단

### Why Purple for Interface (not Red)?

- Red는 "위험/에러" 시맨틱이 보편적 (traffic light, lint errors)
- Controller/Page는 위험하지 않음 — "외부 접점"일 뿐
- Purple은 "특별한/주목해야 할" 느낌을 주되 부정적이지 않음
- Red는 exception 전용으로 남겨 시각적 경고 효과 극대화

### Why Orange for Repository (not Blue)?

- Coad 모델에서 Repository는 "데이터 접근"이지만 entity 자체가 아님
- Repository/Client는 **외부 시스템(DB, API)으로 나가는 경계**
- Orange/Amber의 "나가는 방향" 시맨틱과 매치
- Blue를 데이터 레이어 전용으로 유지하여 의미 충돌 방지

### Why Material Design 색상?

- Google Material Design 2014 color palette 기반
- 접근성: WCAG AA 대비비 고려 (다크/라이트 모드 모두)
- 일관성: 이미 널리 사용되어 시각적 친숙함
- 세분화: 같은 Hue에서 100~900 단계로 채도 조절 가능

## 참고 자료

- Coad, P., Lefebvre, E., De Luca, J. (1999). *Java Modeling in Color with UML*. Prentice Hall.
- Google Material Design Color System: https://m2.material.io/design/color/
- Itten, J. (1961). *The Art of Color* — 색상 온도 이론의 원전
