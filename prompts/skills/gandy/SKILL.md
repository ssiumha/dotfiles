---
name: gandy
description: DB 조회/분석 지원. gandy 쿼리, .gandy 설정, 데이터 수집/분석 워크플로우. Use when querying databases, writing gandy queries, setting up .gandy project config, collecting or analyzing DB data, exploring table structure, or any situation involving gandy, pj:db. Also use when user needs data from postgres or sqlite for investigation, reporting, or debugging. Do NOT use for SQL migration, schema design, or ORM framework setup (use devops instead).
---

# gandy Query & Analysis Assistant

gandy — Interactive Ruby Database Console (Sequel 기반, AR 스타일 API). PostgreSQL·SQLite.

**CLI 문법·헬퍼 상세의 SoT는 도구 내장 help**: `gandy --help`, 세션 내 `help` / `help :topic`.
이 스킬은 판단 기준·함정·`.gandy` 설정 작성만 담는다.

핵심 철학:
- 스크립트(run_script) 전에 interactive/`-e`로 해결 시도. run_script는 일회성 분석 최후 수단
- 반복 패턴(2회+)은 `.gandy` 헬퍼로 승격 제안
- **Raw SQL 금지** — `DB["..."]`는 차단됨. gandy API 사용
- Sandbox: 모든 변경은 트랜잭션 안 — `commit!` 전 미확정, `rollback!`로 되돌림, exit 시 자동 rollback, dirty 상태면 프롬프트에 `*`
- prod는 기본 read-only — 변경은 `--write` 필요
- export는 pipe 우선: `>> :csv` / `>> :json` / `>> :clip` / `>> "file.ext"` (체인 가능)

## 규모별 실행 판단

| 규모 | 방식 |
|------|------|
| 단일 쿼리 | `gandy <url> -e '<code>'` (SSH 터널: `gandy <ssh-host> <db-url>`) |
| 2-3단계 | interactive 세션 (변수 재사용) |
| 4단계+ / 재현성 필요 | `.gandy` 헬퍼로 작성 |

수집 전략: 메타데이터 → 상세 순서(좁은 → 넓은), 중간 결과는 변수에, 최종만 export. subquery 활용: `where(col: Model.where(...).select(:id))`.

## 함정 (help에 묻히기 쉬운 것)

- **Model 네이밍은 Rails inflector가 아님**: `split('_').map(&:capitalize).join` — `order_items` → `OrderItems` (OrderItem 아님), `statuses` → `Statuses`
- `.all`은 100건 초과 시 자동 PagedResult (`_.next` / `_.page(3)`) — 전체 반환은 `.all!`
- 비표준 FK는 raw join 대신 `.gandy`의 `fk_alias creator: :member`
- 탐색 시작점: `tables(/keyword/)`, `overview :users`, 클래스명만 입력하면 컬럼/관계/인덱스/최근 5건 상세

## .gandy 설정 작성

1. 스키마 파악: `gandy <url> -e 'tables'`, `gandy <url> -e 'schema :table_name'`
2. 설정 구성:

```ruby
# FK alias (비표준 FK명 매핑)
fk_alias creator: :member, singer: :member

# Soft delete (deleted_at 자동 필터. bypass는 Model.unfiltered)
enable_soft_delete              # 전체
enable_soft_delete Match, Song  # 특정 모델만

# Model DSL
Users.description "사용자 마스터"
Users.enum :role, admin: '관리자', member: '회원'  # scope + predicate + 레이블
Users.comment :email, "로그인 이메일"
Users.label_column :nickname, :phone               # inspect 대표 컬럼
Users.normalizes :email, with: ->(v) { v&.strip&.downcase }

# ref_label (FK에 참조 레코드 정보 표시)
Orders.ref_label user: [:name, :email]

# 커스텀 pipe 타겟
pipe_to(:slack) { |data| ... }

# 도메인 헬퍼
def active_members
  Member.where(active: true).where { last_login > Date.today - 30 }
end
```

3. 헬퍼 승격 기준: 동일 패턴 2회+ 반복 시 추출 제안

## Examples

```
User: "활성 레코드 수 알려줘"
→ gandy <url> -e 'Model.where(active: true).count'
```

```
User: "프로젝트 gandy 설정 만들어줘"
→ 스키마 확인 → fk_alias/soft_delete/enum/comment/label_column/도메인 헬퍼 구성
```

## Technical Details

- 도구 내장 help: `gandy --help`, 세션 내 `help` / `help :topic`
- 프로젝트 설정: `$PWD/.gandy` (자동 로드, `reload!`), 히스토리: `$PWD/.gandy_history`
- 환경 감지: SSH host 기반 PROD/STAG/DEV/LOCAL 자동 표시
- 지원 DB: PostgreSQL (`postgres://`), SQLite (`sqlite://`), 요구사항: Ruby 3.1+
