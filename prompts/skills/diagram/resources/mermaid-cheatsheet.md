# Mermaid Cheatsheet

실무에서 자주 쓰는 Mermaid 다이어그램 문법 요약.

---

## Flowchart

```mermaid
graph TD
    A[Start] --> B{Condition}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E
```

노드 형태:
- `A[text]` 사각형
- `A(text)` 둥근 사각형
- `A{text}` 다이아몬드
- `A([text])` 스타디움
- `A[[text]]` 서브루틴
- `A[(text)]` 실린더 (DB)

방향: `TD` (위→아래), `LR` (왼→오), `BT`, `RL`

링크:
- `-->` 화살표
- `---` 선
- `-->|label|` 라벨 화살표
- `-.->` 점선 화살표
- `==>` 굵은 화살표

서브그래프:
```mermaid
graph TD
    subgraph Backend
        A[API] --> B[DB]
    end
    subgraph Frontend
        C[React] --> A
    end
```

---

## Sequence Diagram

```mermaid
sequenceDiagram
    actor U as User
    participant A as API
    participant D as DB

    U->>A: POST /login
    activate A
    A->>D: SELECT user
    D-->>A: user record
    A-->>U: 200 OK + token
    deactivate A
```

메시지 유형:
- `->>` 실선 화살표
- `-->>` 점선 화살표
- `-x` 실선 + X (실패)
- `-)` 비동기 (열린 화살표)

기능:
- `activate`/`deactivate` 또는 `+`/`-` (활성 박스)
- `Note over A,B: text` 노트
- `loop`/`alt`/`opt`/`par`/`critical` 블록
- `autonumber` 자동 번호

```mermaid
sequenceDiagram
    autonumber
    A->>B: Request
    alt Success
        B-->>A: 200 OK
    else Failure
        B-->>A: 500 Error
    end
```

---

## C4 Diagram

```mermaid
C4Context
    title System Context
    Person(user, "User", "Uses the system")
    System(sys, "Our System", "Main application")
    System_Ext(ext, "External API", "Third-party")

    Rel(user, sys, "Uses", "HTTPS")
    Rel(sys, ext, "Calls", "REST")
```

```mermaid
C4Container
    title Container Diagram
    Person(user, "User")

    Container_Boundary(sys, "System") {
        Container(web, "Web App", "React", "Frontend")
        Container(api, "API", "Node.js", "Backend")
        ContainerDb(db, "Database", "PostgreSQL", "Storage")
    }

    Rel(user, web, "Uses")
    Rel(web, api, "Calls")
    Rel(api, db, "Reads/Writes")
```

레벨: `C4Context` → `C4Container` → `C4Component` → `C4Dynamic`

---

## ER Diagram

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
    PRODUCT ||--o{ LINE_ITEM : "is in"

    USER {
        int id PK
        string name
        string email UK
    }
    ORDER {
        int id PK
        int user_id FK
        date created_at
    }
```

카디널리티:
- `||--||` one to one
- `||--o{` one to zero or more
- `||--|{` one to one or more
- `o{--o{` zero or more to zero or more

---

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Review : submit
    Review --> Approved : approve
    Review --> Draft : reject
    Approved --> Published : publish
    Published --> [*]

    state Review {
        [*] --> Pending
        Pending --> InReview : assign
        InReview --> Done : complete
    }
```

기능:
- `[*]` 시작/종료 상태
- `state Name { }` 복합 상태
- `<<choice>>` 분기점
- `<<fork>>` / `<<join>>` 병렬

---

## Gantt Chart

```mermaid
gantt
    title Sprint 1
    dateFormat YYYY-MM-DD
    excludes weekends

    section Backend
    API Design     :a1, 2025-01-06, 3d
    Implementation :a2, after a1, 5d
    Testing        :a3, after a2, 2d

    section Frontend
    UI Design      :b1, 2025-01-06, 4d
    Integration    :b2, after a2, 3d
```

태스크 상태:
- `done` 완료
- `active` 진행 중
- `crit` 크리티컬 패스
- `milestone` 마일스톤 (0d)

---

## Class Diagram

```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound() void
    }
    class Dog {
        +fetch() void
    }
    Animal <|-- Dog

    class Repository {
        <<interface>>
        +findById(id) Entity
        +save(entity) void
    }
```

관계:
- `<|--` 상속
- `*--` 컴포지션
- `o--` 집합
- `-->` 연관
- `..>` 의존
- `..|>` 구현

---

## 기타 유용한 유형

### Pie Chart
```mermaid
pie title Language Distribution
    "TypeScript" : 45
    "Python" : 30
    "Go" : 15
    "Other" : 10
```

### Git Graph
```mermaid
gitGraph
    commit
    branch feature
    commit
    commit
    checkout main
    merge feature
    commit
```

### Mindmap
```mermaid
mindmap
    root((Project))
        Backend
            API
            Database
        Frontend
            React
            CSS
        DevOps
            CI/CD
            Monitoring
```
