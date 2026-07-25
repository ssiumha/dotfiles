---
name: diagram
description: "복잡도에 따라 ASCII art 또는 Mermaid 다이어그램을 선택하여 생성. Use when visualizing architecture, drawing diagrams, explaining structure visually, or 도식화/다이어그램 요청 시. 중간 복잡도는 ASCII art 우선."
---

# Diagram

다이어그램 생성 시 복잡도를 판단하여 적절한 형식을 선택합니다.

**핵심 원칙**: 중간 복잡도 이하는 ASCII art 우선. Mermaid는 고복잡도 전용.

## 형식 선택 기준

**기본값은 ASCII**. Mermaid는 ASCII로 표현이 어려울 때만 사용.

```
ASCII (기본)                         Mermaid (전환)
  선형, 트리, 단순 분기                  교차선 3개 이상
  80자 이내로 표현 가능                  80자 초과 불가피
  노드 간 연결이 이웃끼리                순환 참조 + 복잡한 교차
                                       ER, Gantt, 클래스 다이어그램
```

### Mermaid 전환 신호

다음 중 **2개 이상** 해당하면 Mermaid로 전환:

1. **교차선 불가피**: 선이 3회 이상 겹쳐야 표현 가능
2. **80자 초과**: 가로 배치로도 80자를 넘김
3. **자동 레이아웃 필요**: 수동 정렬이 비현실적
4. **Mermaid 전용 유형**: ER, Gantt, 클래스 다이어그램, 파이 차트

### ASCII가 잘 맞는 구조

| 구조 | 노드 수 제한 | 이유 |
|------|:----------:|------|
| 선형 파이프라인 | 제한 없음 | 가로/세로 일직선 |
| 트리/계층 | 제한 없음 | 들여쓰기로 자연 표현 |
| 시퀀스 (액터 3-4) | 스텝 제한 없음 | 세로로 확장 |
| 분기 흐름 | ~15 노드 | 2-3 레벨 분기까지 깔끔 |
| 격자/매트릭스 | 80자 이내 | 행 추가는 자유 |

## Instructions

### 워크플로우: 다이어그램 요청 처리

1. **복잡도 판단**: 노드 수, 관계 유형, 출력 환경 확인
2. **형식 선택**: 위 기준 적용
3. **스타일 선택**: 아래 5가지 중 적합한 것
4. **생성**: 가이드라인 준수하여 작성

### 스타일 1: Box-and-Arrow (아키텍처, 흐름)

가장 범용. 컴포넌트 간 관계 표현에 적합.

```
+----------+     +----------+
|  Client  |---->|  Server  |
+----------+     +----------+
                      |
                 +----v-----+
                 | Database |
                 +----------+
```

레이블 포함:
```
+--------+  HTTP   +--------+  SQL   +------+
| Client |-------->|  API   |------->|  DB  |
+--------+         +--------+        +------+
                       |
                  Redis |
                       v
                   +-------+
                   | Cache |
                   +-------+
```

### 스타일 2: Tree (계층, 디렉토리)

`tree` 명령어 출력과 동일한 형태. 계층 표현에 최적.

```
src/
├── components/
│   ├── Header.tsx
│   └── Footer.tsx
├── hooks/
│   └── useAuth.ts
└── index.ts
```

### 스타일 3: Sequence (시간순 상호작용)

메시지 흐름, API 호출 순서 표현.

```
Client          Server          DB
  |               |              |
  |-- request --->|              |
  |               |-- query ---->|
  |               |<-- result ---|
  |<-- response --|              |
  |               |              |
```

### 스타일 4: Flowchart (분기, 의사결정)

조건 분기와 상태 전이 표현.

```
        +-------+
        | Start |
        +---+---+
            |
        +---v---+
        | Check |
        +---+---+
           / \
      yes /   \ no
         /     \
   +----v-+  +-v------+
   | Pass |  | Retry  |
   +------+  +---+----+
                 |
             +---v---+
             | Fail  |
             +-------+
```

### 스타일 5: Table/Matrix (비교, 매핑)

2차원 비교에 적합. 마크다운 테이블과 병행 가능.

```
          Read  Write  Admin
User       x      -      -
Editor     x      x      -
Admin      x      x      x
```

## 작성 가이드라인

### 문자 세트

| 환경 | 문자 세트 | 예시 |
|------|----------|------|
| 코드 주석, 터미널 | 순수 ASCII | `+ - | > / \` |
| 마크다운 문서 | 유니코드 허용 | `─ │ ┌ ┐ └ ┘ ├ ┤ ▼ ▶` |

**한 다이어그램에서 두 세트를 혼용하지 않는다.**

### 핵심 규칙

1. **80자 이내**: 초과 시 Mermaid 전환 검토
2. **코드 펜스 필수**: ` ``` ` 또는 ` ```text `로 감싸기
3. **화살표에 라벨**: `-- label -->` 형태로 의미 전달
4. **박스 내부 패딩**: 텍스트 좌우 최소 1칸 여백
5. **정렬 일관성**: 같은 레벨 노드는 같은 높이/열에 배치
6. **순수 ASCII 우선**: LLM이 `+-|>` 를 유니코드보다 안정적으로 생성
7. **박스 내부는 영어/ASCII 전용**: 한글·전각 문자는 `len() ≠ 렌더 폭`(2칸)이라 우측 테두리가 무너진다. 한국어 설명은 다이어그램 밖 본문·표에

### 피해야 할 패턴

- 교차선 3개 이상을 ASCII로 강제 (스파게티)
- 화살표 라벨 없는 복잡한 연결
- 비정렬 박스 (들쑥날쑥)
- 유니코드와 ASCII 혼용

### 정렬 검증 — 좌표 기반 생성

박스 3개 이상, 또는 세로 파이프가 여러 행을 관통하는 다이어그램(시퀀스·계층 밴드)은 **눈짐작으로 그리지 않는다**. 눈짐작은 연속 오정렬을 낳는다 — 좌표 기반 스크립트로 생성하고 assert를 통과한 출력만 문서에 붙여넣는다.

```python
W = 90                        # 전체 폭
def line(label, subs=None):   # 라이프라인/보더 행
    s = list(label.ljust(11) + "-" * (W - 11))
    for c, t in (subs or {}).items(): s[c:c+len(t)] = list(t)
    return "".join(s).rstrip()
def chan(marks):              # 채널 행 (화살표·번호 라벨)
    s = [" "] * W
    for c, t in marks.items(): s[c:c+len(t)] = list(t)
    return "".join(s).rstrip()
rows = [line("User"), chan({12: "|1", 48: "^"}), ...]
# 검증: 파이프 열 일치·박스 폭 균일을 assert 로 강제
assert all(r[col] in "|^v<->+" for r in rows for col in PIPES if len(r) > col)
```

- 수정 요청이 오면 출력 문자를 직접 고치지 말고 **스크립트를 고쳐 재생성**한다
- 박스 폭은 `{전체폭}` 단일 값으로 assert — 1자 오차도 실패로 처리

## Examples

### 요청 → ASCII (선형 파이프라인, 15 노드)
```
User: "CI/CD 파이프라인 그려줘"
→ 선형 흐름, 교차선 없음
→ ASCII (스타일 1: Box-and-Arrow)

  commit -> lint -> test -> build -> staging -> deploy
```

### 요청 → ASCII (트리, 20+ 노드)
```
User: "프로젝트 구조 보여줘"
→ 계층 구조, 교차선 없음
→ ASCII (스타일 2: Tree)
```

### 요청 → Mermaid (순환 참조 + 교차)
```
User: "마이크로서비스 의존관계 그려줘"
→ 서비스 간 양방향 호출, 교차선 5개 이상
→ Mermaid (자동 레이아웃 필요)
```

### 요청 → 혼합
```
User: "시스템 개요 + 상세 흐름 그려줘"
→ 전체 의존관계: Mermaid (교차 다수)
→ 개별 요청 흐름: ASCII (선형)
```

## Mermaid 함정

- **라벨에 bare URL 금지** — `http://foo-api:8081` 같은 스킴 포함 문자열이 라벨에 있으면 라벨이 markdown으로 파싱되어 "Unsupported markdown: link"로 렌더된다 (Obsidian·GitHub 공통). 스킴을 떼고 `foo-api:8081`로
- **architecture-beta는 저밀도 전용** — 그리드 자동 배치 + rank 제어 부재라 노드 ~8개/저밀도까지만 실용적. 그 이상은 그룹 경계 침범·대각 교차로 붕괴 → flowchart(dagre)로. 그룹은 배치 힌트가 아니라 점선 테두리일 뿐이고, 엣지 라벨도 미지원
- **아키텍처 다이어그램에서 렌더러 버전 의존 문법**(architecture-beta 등)을 쓸 땐 요구 버전을 문서에 부기

## C4 문서 세트

C4 스타일 문서 세트(레벨 시맨틱·방향 컨벤션·deployment vs topology·명명 원칙)는 `resources/c4-guide.md` 참조.

## Mermaid 치트시트

Mermaid 전환 시 `resources/mermaid-cheatsheet.md` 참조. Flowchart, Sequence, C4, ER, State, Gantt 문법 포함.

## 참고

- [ASCIIFlow](https://asciiflow.com/) - 웹 기반 ASCII 다이어그램 에디터
- [Monodraw](https://monodraw.helftone.com/) - macOS ASCII 다이어그램 도구
- [mermaid-ascii](https://github.com/AlexanderGrooff/mermaid-ascii) - Mermaid → ASCII 변환
- [Mermaid Live Editor](https://mermaid.live/) - Mermaid 온라인 에디터
