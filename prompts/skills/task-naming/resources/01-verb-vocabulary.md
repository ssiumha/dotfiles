# Standard Verb Vocabulary

추천 목록이지 제한이 아님. 의미가 명확한 동사는 목록 밖이어도 사용 가능.

## Service Lifecycle

| Verb | Meaning | Target | Opposite |
|------|---------|--------|----------|
| `run` | Start single process | Service | - |
| `up` | Start all (docker compose etc.) | Infrastructure | `down` |
| `down` | Stop all | Infrastructure | `up` |

## Build / Deploy

| Verb | Meaning | Target | Opposite |
|------|---------|--------|----------|
| `build` | Build binary or image | Service/Image | - |
| `deploy` | Deploy to remote env | Service | `rollback` |

## Code Quality

| Verb | Meaning | Target | Opposite |
|------|---------|--------|----------|
| `check` | lint + typecheck combined | Code | - |
| `test` | Run tests | Code | - |
| `fmt` | Format code | Code | - |

## Database

| Verb | Meaning | Target | Opposite |
|------|---------|--------|----------|
| `migrate` | Run migrations | DB | `rollback` |
| `rollback` | Revert migrations | DB | `migrate` |
| `seed` | Insert initial data | DB | - |

## Observe

| Verb | Meaning | Target | Opposite |
|------|---------|--------|----------|
| `list` | List items | Resources | - |
| `status` | Check status | Service/Resource | - |
| `log` | View logs | Service | - |

## Environment

| Verb | Meaning | Target | Opposite |
|------|---------|--------|----------|
| `init` | One-time initialization | Project | - |
| `setup` | Post-init configuration | Environment | - |
| `clean` | Remove temp files | Cache/Build | - |
| `reset` | clean + rebuild | Everything | - |
| `create` | Create new resource | Resource | - |

## Verb Selection Guide

같은 행위에 여러 동사 후보가 있을 때:

- Start service: `run` (single process), `up` (all/compose). NOT `start`, `serve`
- Stop: `down` (opposite of `up`). NOT `stop`, `halt`
- Clean: `clean` (partial), `reset` (full rebuild). NOT `purge`, `remove`
- Inspect: `check` (code quality), `status` (service state), `list` (enumerate). NOT `show`, `get`
