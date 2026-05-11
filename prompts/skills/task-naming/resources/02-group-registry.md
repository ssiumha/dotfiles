# Group Name Guide

## Noun Groups (Service / Infrastructure Domain)

Noun groups use `group-action[-target]` order.

| Group | Description | Example Commands |
|-------|-------------|-----------------|
| `api` | API service | `api-run`, `api-check`, `api-log ENV` |
| `web` | Web frontend | `web-run`, `web-check`, `web-build` |
| `mobile` | Mobile app | `mobile-build-android`, `mobile-build-ios` |
| `docker` | Container infra | `docker-up`, `docker-down`, `docker-build-api` |
| `db` | Database | `db-migrate ENV`, `db-rollback ENV`, `db-seed ENV` |
| `aws` | AWS resources | `aws-list-ecr`, `aws-login` |

## Verb Groups (Cross-service Actions)

Verb groups use `group-target[-variant]` order.
Use verb groups only when the action spans multiple services.

| Group | Description | Example Commands |
|-------|-------------|-----------------|
| `deploy` | Deploy (multi-service) | `deploy-api ENV`, `deploy-web ENV`, `deploy-all ENV` |
| `build` | Build (multi-target) | `build-android`, `build-ios` |
| `test` | Test (multi-type) | `test-unit`, `test-e2e` |
| `setup` | Environment setup | `setup-hook`, `setup-env`, `setup-docker` |

## Verb Group vs Noun Group Decision

Question: "Does this action span multiple services?"

- YES -> Verb group: `deploy-api`, `deploy-web`, `deploy-all`
- NO -> Noun group action: `api-check` (check that only applies to api)

Examples:
- deploy applies to api, web, mobile -> `[deploy]` group
- typecheck only applies to api -> `[api]` group's `api-check`

## Group Quality Rules

1. **3+ predictable**: seeing the group name, you should be able to guess 3+ member commands
2. **No junk drawers**: `misc`, `tool`, `util`, `magic`, `helper` are forbidden
3. **3-7 per group**: split into sub-groups if exceeded
4. **5-8 groups total**: entire structure should fit one screen in `just --list`
