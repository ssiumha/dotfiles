# 프로세스 관리 규칙

**모든 서버/데몬 프로세스는 overmind를 통해 관리**. 직접 실행 금지.

---

## 핵심 원칙

> Procfile에 정의되지 않은 프로세스는 실행할 수 없다.

서버, 데몬, 워커 등 **지속 실행(long-running) 프로세스**는 반드시:
1. `Procfile`에 정의
2. `overmind start`로 실행

**어떤 방법으로든** 직접 백그라운드 프로세스를 띄우는 것을 금지한다.

---

## 금지 행위 (절대 사용 금지)

### 셸 명령

| 명령어 | 이유 |
|--------|------|
| `pkill`, `kill`, `killall` | 프로세스 직접 종료 금지 |
| `pnpm dev &`, `npm start &` | 백그라운드 직접 실행 금지 |
| `nohup`, `disown` | 프로세스 분리 금지 |
| `lsof -i`, `netstat` + kill | 포트 점유 프로세스 강제 종료 금지 |
| `pnpm dev`, `npm start` (포그라운드) | 서버를 직접 실행 금지 (overmind 경유 필수) |
| `sleep` | 대기/폴링 금지. 명령 결과는 즉시 확인하거나 도구의 timeout 옵션 사용 |

### Claude 도구

| 도구/파라미터 | 이유 |
|--------------|------|
| `Bash(run_in_background=true)` + 서버 명령 | 백그라운드 서버 실행 금지 |

---

## 필수 워크플로우

### 1. Procfile 작성

프로젝트 루트에 `Procfile` 생성. **`mise x --`로 실행이 기본**.

```procfile
# 기본 형태 (mise x -- 필수)
api: mise x -- pnpm dev
web: mise x -- pnpm dev
worker: mise x -- pnpm start

# 디렉토리 이동 필요 시
api: cd api && mise x -- pnpm dev

# 인라인 환경변수
api: TYPEORM_HOST=localhost TYPEORM_PORT=5432 mise x -- pnpm dev
web: API_URL=http://localhost:3000 mise x -- pnpm dev
```

### 2. 환경변수 관리

| 방법 | 예시 | 용도 |
|------|------|------|
| 인라인 | `VAR=val pnpm dev` | 명시적, Procfile만으로 파악 |
| .env 자동로드 | Procfile과 같은 위치 | 공통 변수 |
| 실행 시 지정 | `overmind start -e .env.local` | 환경별 분리 |

### 3. overmind 명령어

| 작업 | 명령어 |
|------|--------|
| 전체 시작 | `overmind start` |
| 데몬으로 시작 | `overmind start -D` |
| 전체 종료 | `overmind stop` |
| 특정 재시작 | `overmind restart api` |
| 로그 연결 | `overmind connect api` |
| 상태 확인 | `overmind status` |
| 소켓 정리 | `overmind kill` |

---

## 서버 실행 요청 시 체크리스트

1. **Procfile 확인**: 없으면 먼저 작성
2. **overmind status**: 이미 실행 중인지 확인
3. **overmind start**: 실행
4. **종료 시**: 반드시 `overmind stop`

---

## 예외 (직접 실행 허용)

- 일회성 스크립트: `node script.js`, `python analyze.py`
- 테스트: `pnpm test`, `pytest`
- 빌드: `pnpm build`, `make`
- REPL: `node`, `psql`, `redis-cli`
- DB 마이그레이션: `pnpm migration:run`

---

## 포트 충돌 시

```bash
# 금지: lsof -i :3000 | kill
# 허용: overmind로 관리 중인 프로세스 정리
overmind stop
overmind kill  # 소켓 정리 필요 시
overmind start
```

기존 overmind 외부에서 실행된 프로세스가 포트 점유 시:
→ 사용자에게 수동 종료 요청 (Claude가 직접 kill 금지)
