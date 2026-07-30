# PostgreSQL Schema Extraction Queries

수동 폴백 시 사용하는 PostgreSQL 스키마 추출 SQL 쿼리 레퍼런스.

## 접속

```bash
# 비밀번호는 PGPASSWORD 환경변수로 전달
PGPASSWORD=mypass psql -h localhost -p 5432 -U myuser -d mydb -Atc "QUERY"

# -A: 정렬 없는 출력
# -t: 튜플만 (헤더/푸터 없음)
# -c: 단일 쿼리 실행
# 출력: 파이프(|) 구분
```

## 테이블 목록

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;
```

특정 스키마만:
```sql
-- AND table_schema = 'public'
-- AND table_schema IN ('public', 'auth')
```

## 컬럼 + PK

```sql
SELECT
  c.table_schema,
  c.table_name,
  c.column_name,
  c.data_type,
  c.is_nullable,
  c.column_default,
  CASE WHEN pk.column_name IS NOT NULL THEN 'YES' ELSE 'NO' END AS is_pk
FROM information_schema.columns c
LEFT JOIN (
  SELECT ku.table_schema, ku.table_name, ku.column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage ku
    ON tc.constraint_name = ku.constraint_name
    AND tc.table_schema = ku.table_schema
  WHERE tc.constraint_type = 'PRIMARY KEY'
) pk
  ON c.table_schema = pk.table_schema
  AND c.table_name = pk.table_name
  AND c.column_name = pk.column_name
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY c.table_schema, c.table_name, c.ordinal_position;
```

출력 예시:
```
public|users|id|integer|NO||YES
public|users|email|character varying|NO||NO
public|users|name|character varying|YES||NO
```

## FK (외래 키)

```sql
SELECT
  tc.table_schema,
  tc.table_name,
  kcu.column_name,
  ccu.table_schema AS ref_schema,
  ccu.table_name AS ref_table,
  ccu.column_name AS ref_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
  AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_schema, tc.table_name;
```

출력 예시:
```
public|orders|user_id|public|users|id
public|order_items|order_id|public|orders|id
public|order_items|product_id|public|products|id
```

## 인덱스

```sql
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;
```

## 파싱 패턴

```python
# psql -Atc 출력 파싱
output = subprocess.run(
    ["psql", "-h", host, "-p", port, "-U", user, "-d", db, "-Atc", query],
    capture_output=True, text=True, timeout=30,
    env={**os.environ, "PGPASSWORD": password}
).stdout

for line in output.strip().splitlines():
    fields = line.split("|")
    # fields[0] = table_schema, fields[1] = table_name, ...
```

## 주의사항

- `information_schema.constraint_column_usage`는 PG 전용 (MySQL에는 없음)
- 복합 FK (multi-column FK)는 같은 constraint_name으로 여러 행이 나옴
- 파티션 테이블은 부모/자식 모두 `information_schema.tables`에 나타남
- 뷰는 `table_type = 'VIEW'`로 필터 가능 (현재는 BASE TABLE만)
