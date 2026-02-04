# Database 개발 환경

개발용 Database 설정 및 튜닝 도구 가이드입니다.

> **주의**: 이 설정들은 개발/스테이징 환경 전용입니다. 프로덕션에서는 성능 오버헤드가 발생할 수 있으므로 비활성화하거나 선별적으로 사용하세요.

## PostgreSQL 개발 환경

### 성능 분석 익스텐션

| 익스텐션 | 용도 | 패키지 (PG16) |
|----------|------|---------------|
| pg_stat_statements | 쿼리 통계 (기본 포함) | contrib |
| pg_hint_plan | 쿼리 힌트로 실행 계획 제어 | postgresql-16-pg-hint-plan |
| pg_qualstats | WHERE 조건 통계 수집 | postgresql-16-pg-qualstats |
| pg_stat_kcache | CPU/메모리 사용량 통계 | postgresql-16-pg-stat-kcache |
| pg_wait_sampling | 대기 이벤트 샘플링 | postgresql-16-pg-wait-sampling |
| pg_show_plans | 실행 중인 쿼리 플랜 조회 | postgresql-16-show-plans |
| hypopg | 가상 인덱스로 성능 테스트 | postgresql-16-hypopg |

### Ubuntu/Debian 패키지 설치

```bash
# PostgreSQL 버전에 맞게 수정 (예: 16)
PG_VERSION=16

apt-get install -y \
  postgresql-${PG_VERSION}-pg-hint-plan \
  postgresql-${PG_VERSION}-pg-qualstats \
  postgresql-${PG_VERSION}-pg-stat-kcache \
  postgresql-${PG_VERSION}-pg-wait-sampling \
  postgresql-${PG_VERSION}-show-plans \
  postgresql-${PG_VERSION}-hypopg
```

### Dockerfile (개발용)

```dockerfile
FROM postgres:16

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-16-pg-hint-plan \
    postgresql-16-pg-qualstats \
    postgresql-16-pg-stat-kcache \
    postgresql-16-pg-wait-sampling \
    postgresql-16-show-plans \
    postgresql-16-hypopg \
  && rm -rf /var/lib/apt/lists/*

COPY init.sql /docker-entrypoint-initdb.d/
```

### postgresql.conf 설정

compose.yaml의 command로 설정하거나, 별도 conf 파일 마운트:

```yaml
# compose.yaml
services:
  db:
    command:
      - postgres
      - -c
      - shared_preload_libraries=pg_stat_statements,pg_hint_plan,pg_qualstats,pg_stat_kcache,pg_wait_sampling,pg_show_plans
      - -c
      - pg_stat_statements.track=all
      - -c
      - log_statement=all
      - -c
      - log_min_duration_statement=100
```

또는 conf 파일 마운트:

```yaml
volumes:
  - ./postgresql.conf:/etc/postgresql/postgresql.conf
command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

```ini
# postgresql.conf
shared_preload_libraries = 'pg_stat_statements,pg_hint_plan,pg_qualstats,pg_stat_kcache,pg_wait_sampling,pg_show_plans'

# pg_stat_statements
pg_stat_statements.track = all
pg_stat_statements.max = 10000

# pg_qualstats
pg_qualstats.enabled = on
pg_qualstats.track_constants = on

# pg_wait_sampling
pg_wait_sampling.history_size = 1000
pg_wait_sampling.profile_period = 10
pg_wait_sampling.profile_queries = on

# 쿼리 로깅 (개발용)
log_statement = 'all'
log_duration = on
log_min_duration_statement = 100
```

### init.sql (익스텐션 활성화)

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_hint_plan;
CREATE EXTENSION IF NOT EXISTS pg_qualstats;
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
CREATE EXTENSION IF NOT EXISTS pg_show_plans;
CREATE EXTENSION IF NOT EXISTS hypopg;
```

### compose.yaml (전체 예시)

```yaml
services:
  db:
    build:
      context: ./docker/postgres
      dockerfile: Dockerfile
    environment:
      POSTGRES_DB: app_dev
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    command:
      - postgres
      - -c
      - shared_preload_libraries=pg_stat_statements,pg_hint_plan,pg_qualstats,pg_stat_kcache,pg_wait_sampling,pg_show_plans
      - -c
      - log_min_duration_statement=100
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db_data:
```

### 유용한 쿼리

```sql
-- 느린 쿼리 조회 (pg_stat_statements)
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 대기 이벤트 조회 (pg_wait_sampling)
SELECT event_type, event, count
FROM pg_wait_sampling_profile
ORDER BY count DESC;

-- 가상 인덱스 테스트 (hypopg)
SELECT hypopg_create_index('CREATE INDEX ON users(email)');
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
SELECT hypopg_drop_index(indexrelid) FROM hypopg_list_indexes();

-- 쿼리 힌트 사용 (pg_hint_plan)
/*+ SeqScan(users) */ SELECT * FROM users WHERE id = 1;
/*+ IndexScan(users users_pkey) */ SELECT * FROM users WHERE id = 1;
```

## MySQL 개발 환경

### 성능 스키마 활성화

```ini
# my.cnf
[mysqld]
performance_schema = ON
slow_query_log = ON
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 0.1
```

### compose.yaml

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: app_dev
      MYSQL_USER: user
      MYSQL_PASSWORD: pass
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./my.cnf:/etc/mysql/conf.d/my.cnf
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  mysql_data:
```

## 참고

- pg_hint_plan: https://pg-hint-plan.readthedocs.io/
- pg_qualstats: https://github.com/powa-team/pg_qualstats
- hypopg: https://hypopg.readthedocs.io/
- PoWA (PostgreSQL Workload Analyzer): https://powa.readthedocs.io/
