---
name: db-irb
description: DB 조회/분석 지원. Sequel DSL 쿼리, .db-irb.rb 설정, 데이터 수집/분석 워크플로우. Use when querying databases, writing Sequel queries, setting up .db-irb.rb project config, collecting or analyzing DB data, exploring table structure, or any situation involving db-irb, db:irb, pj:db. Also use when user needs data from postgres for investigation, reporting, or debugging. Do NOT use for SQL migration, schema design, or ORM framework setup (use devops instead).
---

# db-irb Query & Analysis Assistant

db-irb (mise run db:irb) 세션에서의 데이터 조회/분석을 지원합니다.

**핵심 철학**:
- 스크립트(run_script) 전에 interactive/`-e`로 해결 시도
- 반복 패턴은 `.db-irb.rb`에 헬퍼로 승격
- Sequel DSL 우선, raw SQL은 복잡한 서브쿼리/CTE 등 DSL로 표현 불가능한 경우만

## When to Use

- 사용자가 DB 데이터 조회/분석 요청 시
- `-e` 모드 명령 구성 시
- `.db-irb.rb` 프로젝트 설정 작성 시
- 복잡한 Sequel 쿼리 작성 시
- 데이터 수집/분석 워크플로우 설계 시

## Instructions

### 워크플로우 1: 쿼리 생성

사용자가 "~~ 조회해줘", "~~ 데이터 뽑아줘" 요청 시:

1. **대상 파악**: 어떤 테이블/모델, 어떤 조건
2. **쿼리 구성** (우선순위):
   - (1) Model DSL: `Model.where(col: val).all`
   - (2) Association: `record.assoc`, `Model.joins(:assoc)`
   - (3) Auto-join where: `Model.where(other_table: { col: val })`
   - (4) Raw Dataset: `DB[:table].join(:other, fk: :id).select_all(:table)`
   - (5) Raw SQL: `DB[%(SELECT ...), params]` — 최후 수단

3. **출력 형식 제안**:
   - 확인용: interactive (직접 `.all`)
   - 파일 저장: `to_json dataset, "path"` / `to_csv dataset, "path"`
   - 클립보드: `to_clip dataset`
   - 보고서: `to_report hash, "path"`

### 워크플로우 2: .db-irb.rb 설정 생성

프로젝트의 `.db-irb.rb` 작성 요청 시:

1. **DB 스키마 파악** (사용자에게 실행 요청):
   ```
   mise run db:irb <args> -e 'tables'
   mise run db:irb <args> -e 'schema :table_name'
   ```

2. **설정 구성**:
   ```ruby
   # FK alias (비표준 FK명 매핑)
   fk_alias author: :user, reviewer: :user

   # Soft delete (deleted_at 자동 필터)
   enable_soft_delete

   # Scope (자주 쓰는 필터)
   Model.scope :active, -> { where(active: true) }

   # 도메인 헬퍼
   def helper_name(args)
     # Sequel DSL 쿼리
   end
   ```

3. **헬퍼 승격 기준**: 동일 패턴 2회+ 반복 시 헬퍼로 추출 제안

### 워크플로우 3: 데이터 수집/분석

복잡한 다단계 데이터 수집 요청 시:

1. **interactive로 가능한지 먼저 판단**:
   - 단일 쿼리 → `-e` 모드
   - 2-3단계 → interactive 세션 (변수 재사용)
   - 4단계+ 또는 재현성 필요 → `.db-irb.rb` 헬퍼 또는 run_script

2. **수집 전략**:
   - 메타데이터 → 상세 데이터 순서 (좁은 → 넓은)
   - 중간 결과는 변수에, 최종만 export
   - subquery 활용: `where(col: Model.where(...).select(:id))`

3. **스크립트가 필요한 경우에도**:
   - `.db-irb.rb` 헬퍼 함수로 작성 (재사용 가능)
   - run_script은 일회성 분석에만

## Quick Reference

### Model 규칙
```
테이블 → 클래스: split('_').map(&:capitalize).join
  order_items → OrderItems (NOT OrderItem)
  ※ Rails inflector 아님
```

### Association
```ruby
# FK 기반 자동 설정 + _id 추론
record.assoc                    # has_many / belongs_to
record.assoc_dataset.where(..)  # lazy chain

# 비표준 FK: .db-irb.rb에서 fk_alias
fk_alias author: :user          # author_id → users 테이블
post.author                     # → User 인스턴스
```

### Join 패턴
```ruby
# INNER JOIN (association 기반)
Model.joins(:assoc)
Model.joins(:assoc1, :assoc2)

# LEFT JOIN (optional 관계)
Model.left_joins(:assoc)

# Auto-join (nested hash where)
Model.where(other_table: { col: val })

# Raw join (association 없을 때)
DB[:a].join(:b, id: :b_id).select_all(:a).select_append(Sequel[:b][:col])
```

### Soft Delete
```ruby
enable_soft_delete              # .db-irb.rb에서 호출
# → WHERE deleted_at IS NULL 자동
Model.unfiltered.where(...)     # bypass
```

### Export
```ruby
to_json dataset, "~/path.json"  # 파일
to_csv  dataset, "~/path.csv"
to_clip dataset                  # clipboard
to_report({ summary: {}, details: data }, "~/report.json")
```

### -e 모드 주의점
```bash
# shell escape 때문에 " 대신 %() 사용
mise run db:irb <args> -e 'DB[%(SELECT * FROM t WHERE id = ?), 1].all'
# 여러 문장은 ; 로 연결
mise run db:irb <args> -e 'x = Model.first; x.assoc.all'
```

### 탐색/분석 헬퍼
```ruby
tables              # 전체 테이블 목록
tables(/keyword/)   # 테이블 검색
overview :table     # count + schema + fk 한번에
sample :table       # limit(3).all
sample Model.where(col: val), 5
```

## 중요 원칙

1. **DSL 우선**: raw SQL은 복잡한 CTE/서브쿼리 등 DSL 한계 시에만. Sequel DSL이 더 안전하고 컬럼 타입 변환을 자동 처리
2. **헬퍼 승격**: 2회 이상 반복되는 쿼리 패턴은 `.db-irb.rb` 헬퍼로 추출 제안
3. **스크립트 최소화**: run_script은 최후 수단. interactive + `.db-irb.rb` 헬퍼 조합으로 대부분 해결 가능
4. **fk_alias 활용**: 비표준 FK명(author_id, reviewer_id 등)은 fk_alias로 해결. raw join 강제 방지
5. **prod 안전**: prod 환경은 기본 read-only. --write 없이 변경 시도하지 않음

## Examples

### 단순 조회
```
User: "활성 레코드 수 알려줘"
→ -e 모드: mise run db:irb <args> -e 'Model.where(active: true).count'
```

### 관계 데이터 수집
```
User: "특정 주문의 전체 결제 데이터 뽑아줘"
→ .db-irb.rb에 fk_alias + enable_soft_delete 설정 후 interactive:
  order = Order.first(external_id: "xxx")
  items = OrderItem.joins(:product).left_joins(:discount).where(order_id: order.id)
  to_json items, "~/data/order_items.json"
```

### .db-irb.rb 생성
```
User: "프로젝트 db-irb 설정 만들어줘"
→ 스키마 확인 → fk_alias/soft_delete/scope/도메인 헬퍼 구성
```

## Technical Details

- 도구 소스: `config/mise/tasks/tool/db-irb` (전체 구현)
- 도구 내장 help: IRB에서 `help` 타이핑
- 프로젝트 설정: `$MISE_PROJECT_ROOT/.db-irb.rb` (자동 로드)
