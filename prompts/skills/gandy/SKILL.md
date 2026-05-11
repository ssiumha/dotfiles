---
name: gandy
description: DB 조회/분석 지원. gandy 쿼리, .gandy 설정, 데이터 수집/분석 워크플로우. Use when querying databases, writing gandy queries, setting up .gandy project config, collecting or analyzing DB data, exploring table structure, or any situation involving gandy, pj:db. Also use when user needs data from postgres or sqlite for investigation, reporting, or debugging. Do NOT use for SQL migration, schema design, or ORM framework setup (use devops instead).
---

# gandy Query & Analysis Assistant

gandy — Interactive Ruby Database Console. Sequel 기반이지만 AR 스타일 API를 제공하여 ActiveRecord처럼 사용 가능. PostgreSQL, SQLite 지원.

**핵심 철학**:
- 스크립트(run_script) 전에 interactive/`-e`로 해결 시도
- 반복 패턴은 `.gandy`에 헬퍼로 승격
- Raw SQL 금지. `DB["..."]`는 차단됨
- Sandbox: 모든 변경은 트랜잭션 안에서 실행, 명시적 commit! 전까지 미확정

## When to Use

- 사용자가 DB 데이터 조회/분석 요청 시
- `-e` 모드 명령 구성 시
- `.gandy` 프로젝트 설정 작성 시
- 데이터 수집/분석 워크플로우 설계 시

## Instructions

### 워크플로우 1: 쿼리 생성

사용자가 "~~ 조회해줘", "~~ 데이터 뽑아줘" 요청 시:

1. **대상 파악**: 어떤 테이블/모델, 어떤 조건
2. **쿼리 구성** (우선순위):
   - (1) Model API: `Model.where(col: val).all`
   - (2) Association: `record.assoc`, `Model.joins(:assoc)`
   - (3) Auto-join where: `Model.where(other_table: { col: val })`
   - (4) Raw Dataset: `DB[:table].join(:other, fk: :id).select_all(:table)`

3. **출력 형식 제안**:
   - 확인용: interactive (직접 `.all`)
   - 파이프: `dataset >> :csv`, `dataset >> :json`, `dataset >> "file.csv"`
   - 클립보드: `dataset >> :clip`
   - 보고서: `to_report hash, "path"`

### 워크플로우 2: .gandy 설정 생성

프로젝트의 `.gandy` 작성 요청 시:

1. **DB 스키마 파악** (사용자에게 실행 요청):
   ```
   gandy <url> -e 'tables'
   gandy <url> -e 'schema :table_name'
   ```

2. **설정 구성**:
   ```ruby
   # FK alias (비표준 FK명 매핑)
   fk_alias creator: :member, singer: :member

   # Soft delete (deleted_at 자동 필터)
   enable_soft_delete              # 전체
   enable_soft_delete Match, Song  # 특정 모델만

   # Model DSL
   Users.description "사용자 마스터"
   Users.enum :role, %w[admin member guest]
   Users.enum :role, admin: '관리자', member: '회원'  # 한글 레이블
   Users.comment :email, "로그인 이메일"
   Users.label_column :nickname, :phone
   Users.normalizes :email, with: ->(v) { v&.strip&.downcase }

   # ref_label (FK에 참조 레코드 정보 표시)
   Orders.ref_label user: :name
   Orders.ref_label user: [:name, :email]
   Orders.ref_label user: ->(u) { "#{u.name} (#{u.email})" }

   # 커스텀 pipe 타겟
   pipe_to(:slack) { |data| ... }

   # 도메인 헬퍼
   def active_members
     Member.where(active: true).where { last_login > Date.today - 30 }
   end
   ```

3. **헬퍼 승격 기준**: 동일 패턴 2회+ 반복 시 헬퍼로 추출 제안

### 워크플로우 3: 데이터 수집/분석

복잡한 다단계 데이터 수집 요청 시:

1. **interactive로 가능한지 먼저 판단**:
   - 단일 쿼리 → `-e` 모드
   - 2-3단계 → interactive 세션 (변수 재사용)
   - 4단계+ 또는 재현성 필요 → `.gandy` 헬퍼 또는 run_script

2. **수집 전략**:
   - 메타데이터 → 상세 데이터 순서 (좁은 → 넓은)
   - 중간 결과는 변수에, 최종만 export
   - subquery 활용: `where(col: Model.where(...).select(:id))`

3. **스크립트가 필요한 경우에도**:
   - `.gandy` 헬퍼 함수로 작성 (재사용 가능)
   - run_script은 일회성 분석에만

## Quick Reference

### CLI 사용법
```bash
gandy <db-url>                     # 로컬 직접 연결
gandy <ssh-host> <db-url>          # SSH 터널 경유
gandy - <db-url>                   # 로컬 직접 연결 (명시적)
gandy <db-url> -e '<code>'         # 코드 실행 후 종료
gandy <db-url> --write             # 쓰기 허용 (prod)
```

### Model 규칙
```
테이블 → 클래스: split('_').map(&:capitalize).join
  order_items → OrderItems (NOT OrderItem)
  ※ Rails inflector 아님 (statuses → Statuses)
```

### Select & Filter
```ruby
User.all                             # 100건 초과 시 자동 PagedResult
User.all!                            # limit 없이 전체 반환
User.first / User[1] / User.last(5)
User.where(active: true).all
User.where.not(role: "admin")        # exclude 대안
User.pluck(:name)                    # -> ["foo", "bar"]
User.exclude(active: false)          # where의 반대
User.where(name: 'foo').or(name: 'bar')
User.select(:id, :name).all
User.distinct.select(:role).all

# 비교 연산
User.where(age: 20..)               # age >= 20
User.where(age: 20..30)             # BETWEEN
User.where { created_at > 7.days.ago }

# NULL
User.where(deleted_at: nil)          # IS NULL
User.exclude(deleted_at: nil)        # IS NOT NULL

# 단건
User.find_by(email: "x@y.com")      # nil if not found
User.exists?(email: "x@y.com")      # true/false
User.find_or_create_by(email: "x")  # 있으면 반환, 없으면 생성
```

### Association
```ruby
user.orders                          # has_many
user.orders.where(status: "paid")    # 필터 체인
order.user                           # belongs_to
User.includes(:orders).all           # eager loading

# 비표준 FK: .gandy에서 fk_alias
fk_alias creator: :member            # creator_id → members 매핑
song.creator                         # → Member 인스턴스
```

### Join
```ruby
User.joins(:orders).distinct.select_all(:users).all
User.joins(:orders, :posts)              # 복수 join
User.left_joins(:orders)                 # LEFT JOIN

# Auto-join (nested hash where)
User.where(orders: { status: "paid" }).all
```

### Group & Aggregate
```ruby
Order.group_and_count(:status).all
Order.group(:user_id).select_append { sum(amount).as(total) }.all
User.sum(:age) / .avg(:age) / .min(:age) / .max(:age)
Users.enum_stats(:role)              # => {"admin"=>5, "member"=>20}
```

### Order & Pagination
```ruby
User.order(:created_at).reverse.all
User.order(:created_at).limit(10).offset(20).all
sample :users              # limit(3).all
sample User.where(...), 5

# 자동 페이지네이션 (100건 초과 시)
User.all                   # → PagedResult
_.next / _.prev / _.page(3)
User.all!                  # 전체 반환
```

### CRUD & Dirty Tracking
```ruby
User.create(name: "x")
user.update(name: "y")
user.delete
user.touch                    # updated_at = Time.now
user.touch(:verified_at)      # 특정 컬럼 갱신

# Dirty tracking
user.changed?                 # 변경 여부
user.changes                  # {col: [old, new]}
user.diff                     # 변경 내역 pretty print
```

### Sandbox (트랜잭션)
```ruby
# 모든 변경은 트랜잭션 안에서 실행
user.update(name: "x")    # 실행되지만 미확정
commit!                    # 확정 → 새 트랜잭션 시작
rollback!                  # 되돌리기 → 새 트랜잭션 시작
# exit 시 미확정 변경은 자동 rollback
# 프롬프트에 * 표시 = dirty 상태
```

### >> Pipe (Export)
```ruby
# 포맷 출력
User.all >> :csv              # CSV stdout
User.all >> :json             # JSON stdout
User.all >> :yaml             # YAML stdout
User.all >> :jq               # JSON + jq (pretty/color)
User.all >> :tbl              # 테이블 + pager
User.all >> :vim              # vim -R
User.all >> :clip             # 클립보드

# 파일 저장 (확장자로 포맷 결정)
User.all >> "out.csv"
User.all >> "out.json"
User.all >> "out.md"          # 마크다운 테이블

# 체인
User.all >> :json >> :vim     # JSON → vim
User.all >> :csv >> :clip     # CSV → 클립보드
User.all >> :json >> "a.json" # JSON → 파일
```

### Time 헬퍼
```ruby
1.days.ago / 3.hours.from_now / 2.weeks.ago
yesterday / tomorrow / today
2.days.before(some_time) / 1.hour.after(some_time)

# Range 헬퍼
this_week / this_month
Date.today.all_day / Date.today.all_week / Date.today.all_month
Time.now.beginning_of_day / Time.now.end_of_day
Date.today.beginning_of_week / Date.today.beginning_of_month

# Range 조합
User.where(created_at: 7.days.ago..)     # 7일 이내
User.where(created_at: ..30.days.ago)    # 30일 이전
User.where(created_at: this_week)        # 이번 주
```

### 탐색 워크플로우
```ruby
tables              # 전체 테이블 목록 (description 포함)
tables(/keyword/)   # 테이블 검색
overview :users     # count + schema + fk 한번에
User                # 클래스명만 입력 → 컬럼/관계/인덱스/최근 5건 상세
relations :users    # 양방향 관계 테이블 리스팅 (rels 별칭)
tree User           # 관계 트리 시각화 (depth: 2)
sample :users       # limit(3).all
User.associations   # 설정된 관계 확인
schema :users       # 컬럼 상세 (타입, PK, nullable)
fk :orders          # 외래키 관계
User.explain        # 쿼리 실행 계획
```

### ERD
```ruby
print_erd                    # Mermaid ERD (전체)
print_erd_d2                 # d2 포맷 ERD (전체)
print_erd_d2 User, depth: 2  # 특정 모델 중심 ERD
open_erd_d2 User             # d2 → SVG → 브라우저
```

### Analysis 헬퍼
```ruby
load_json "~/logs.json"              # 외부 JSON → Ruby
index_by  users, :id                 # 배열 → 해시 (키 기준)
merge_by  db_data, logs, :user_id    # 공통 키로 머지
to_report({ meta: {}, summary: {}, details: data }, "~/report.json")
run_script "~/analysis.rb"           # 외부 Ruby 스크립트 실행
```

### Import
```ruby
from_csv :users, "~/a.csv"              # dry-run
from_csv :users, "~/a.csv", run: true   # 실제 insert (--write 필요)
from_json :users, "~/a.json"            # JSON import
```

### 디버그
```ruby
verbose!            # SQL 쿼리 로깅 ON
quiet!              # SQL 쿼리 로깅 OFF
hist                # fzf로 히스토리 검색/재실행
```

### -e 모드
```bash
gandy <url> -e 'User.count'
gandy <url> -e 'User.where(active: true).limit(5)'
# 여러 문장: -e 'x = User.first; x.orders.all'
```

### Soft Delete
```ruby
enable_soft_delete              # 전체 (deleted_at 컬럼 있는 것만)
enable_soft_delete Match, Song  # 특정 모델만
# → WHERE deleted_at IS NULL 자동
Model.unfiltered.where(...)     # bypass
```

### Model DSL (.gandy)
```ruby
Users.description "사용자 마스터"
Users.enum :role, %w[admin member guest]             # scope + validation
Users.enum :role, admin: '관리자', member: '회원'     # 한글 레이블 → scope + predicate
Users.comment :email, "로그인 이메일"
Users.label_column :nickname                          # inspect 대표 컬럼
Users.ref_label org: :name                            # FK에 참조 정보 표시
Users.normalizes :email, with: ->(v) { v&.strip&.downcase }
Users.enum_stats(:role)                               # => {"admin(관리자)"=>5, "member(회원)"=>20}
user.role_label                                       # => "관리자" (한글 레이블)
user.role_admin?                                      # predicate
Users.role_admin                                      # scope
```

## 중요 원칙

1. **Raw SQL 금지**: `DB["..."]`는 차단됨. gandy API 사용
2. **헬퍼 승격**: 2회 이상 반복되는 쿼리 패턴은 `.gandy` 헬퍼로 추출 제안
3. **스크립트 최소화**: run_script은 최후 수단. interactive + `.gandy` 헬퍼 조합으로 대부분 해결 가능
4. **fk_alias 활용**: 비표준 FK명은 fk_alias로 해결. raw join 강제 방지
5. **prod 안전**: prod 환경은 기본 read-only. `--write` 없이 변경 불가
6. **Sandbox 활용**: 변경 작업은 commit!/rollback! 활용. exit 시 자동 rollback
7. **Pipe 우선**: export는 `>> :format` 또는 `>> "file.ext"` 사용. 체인 가능

## Examples

### 단순 조회
```
User: "활성 레코드 수 알려줘"
→ -e 모드: gandy <url> -e 'Model.where(active: true).count'
```

### 관계 데이터 수집
```
User: "특정 주문의 전체 결제 데이터 뽑아줘"
→ .gandy에 fk_alias + enable_soft_delete 설정 후 interactive:
  order = Order.first(external_id: "xxx")
  items = OrderItem.joins(:product).left_joins(:discount).where(order_id: order.id)
  items >> "~/data/order_items.json"
```

### .gandy 생성
```
User: "프로젝트 gandy 설정 만들어줘"
→ 스키마 확인 → fk_alias/soft_delete/enum/comment/label_column/도메인 헬퍼 구성
```

## Technical Details

- 도구 내장 help: `gandy --help`, 세션 내 `help` / `help :topic`
- 프로젝트 설정: `$PWD/.gandy` (자동 로드, `reload!`로 재로드)
- 히스토리: `$PWD/.gandy_history` (프로젝트별 분리)
- 환경 감지: SSH host 기반 PROD/STAG/DEV/LOCAL 자동 표시
- 지원 DB: PostgreSQL (`postgres://`), SQLite (`sqlite://`)
- 요구사항: Ruby 3.1+
