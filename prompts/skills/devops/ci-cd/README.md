# CI/CD Domain

로컬 개발 환경과 원격 CI/CD 파이프라인을 통합 구성합니다.

## 핵심 철학

- Justfile로 로컬 자동화 통합
- 로컬과 CI 환경 동일하게 (justfile 재사용)
- E2E 테스트: 실제 DB 컨테이너 사용
- 언어별 최신 도구 (TypeScript: Biome)
- pre-commit hooks로 품질 게이트

## 리소스 선택

| 키워드 | 리소스 |
|--------|--------|
| lint, formatter, biome, test, E2E | 01-local-ci.md |
| justfile, task runner, pre-commit | 01-local-ci.md |
| CI/CD, 파이프라인, GitLab CI | 02-ci-cd-pipelines.md |
| 캐싱, cache | 02-ci-cd-pipelines.md |
| TypeScript + lint/test | languages/typescript.md |

## Workflow

1. 프로젝트 언어/프레임워크 확인
2. 키워드 매칭으로 필요 리소스 Read
3. justfile, lint config, CI config 생성
4. `just lint`, `just test` 실행 확인

## 산출물

- justfile (lint, test, format 타스크)
- 언어별 lint config (biome.json 등)
- E2E용 compose.yaml
- .gitlab-ci.yml (GitLab 사용 시)
