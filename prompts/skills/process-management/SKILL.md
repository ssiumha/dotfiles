---
name: process-management
description: Manages long-running processes via overmind/Procfile. Use when starting servers, daemons, workers, or managing Procfile configuration.
---

# 프로세스 관리

**모든 서버/데몬 프로세스는 overmind를 통해 관리한다.**

## 원칙

> Procfile에 정의 → overmind로 실행. 이것이 유일한 경로.

- 서버, 데몬, 워커 등 지속 실행 프로세스 → `Procfile` 정의 + `overmind start`
- 직접 백그라운드 실행(`&`, `nohup`, `Bash(run_in_background=true)`) 사용하지 않는다
- 프로세스 직접 종료(`pkill`, `kill`, `killall`) 대신 `overmind stop/restart`
- `sleep` 대신 도구의 timeout 옵션 사용

## Procfile 작성

```procfile
# mise x -- 로 실행이 기본
api: mise x -- pnpm dev
web: mise x -- pnpm dev
worker: mise x -- pnpm start

# 디렉토리 이동
api: cd api && mise x -- pnpm dev

# 인라인 환경변수
api: TYPEORM_HOST=localhost mise x -- pnpm dev
```

## overmind 명령어

| 작업 | 명령어 |
|------|--------|
| 전체 시작 | `overmind start` |
| 데몬 시작 | `overmind start -D` |
| 전체 종료 | `overmind stop` |
| 특정 재시작 | `overmind restart api` |
| 로그 연결 | `overmind connect api` |
| 상태 확인 | `overmind status` |
| 소켓 정리 | `overmind kill` |

## 서버 실행 워크플로우

1. Procfile 확인 (없으면 작성)
2. `overmind status` (이미 실행 중인지)
3. `overmind start`
4. 종료 시 `overmind stop`

## 직접 실행 허용 대상

일회성 스크립트, 테스트, 빌드, REPL, DB 마이그레이션은 직접 실행 가능.

## 포트 충돌

`overmind stop` → `overmind kill` → `overmind start` 순서로 정리.
외부 프로세스가 점유 중이면 사용자에게 수동 종료 요청.
