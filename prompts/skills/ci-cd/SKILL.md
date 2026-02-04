---
name: ci-cd
description: Sets up CI/CD workflows both locally (Justfile, lint, test) and remotely (GitHub Actions, GitLab CI). Use for test automation, pre-commit hooks, or deployment pipelines.
---

# CI/CD

로컬 개발 환경과 원격 CI/CD 파이프라인을 통합 구성합니다.

**핵심 철학**:
- Justfile로 로컬 자동화 통합
- 로컬과 CI 환경 동일하게 (justfile 재사용)
- E2E 테스트: 실제 DB 컨테이너 사용
- 언어별 최신 도구 (TypeScript: Biome)
- pre-commit hooks로 품질 게이트
- 캐싱으로 빌드 시간 최적화

## Instructions

### 워크플로우: CI/CD 설정

1. **프로젝트 분석**
   - 언어/프레임워크 확인
   - Git 호스팅 확인 (GitHub/GitLab)
   - 기존 lint/test/CI 설정 확인

2. **리소스 로드**
   - 로컬 CI: Read resources/01-local-ci.md
   - 원격 CI/CD: Read resources/02-ci-cd-pipelines.md
   - 언어별: Read resources/languages/typescript.md (현재 TypeScript만 지원)

3. **설정 생성**
   - justfile 생성/수정
   - 언어별 lint 설정 (biome.json 등)
   - E2E용 compose.yaml
   - .github/workflows/ci.yml 또는 .gitlab-ci.yml
   - 캐싱 및 service container 설정

4. **검증**
   - just lint, just test 실행 확인
   - YAML 문법 검증

## 키워드 매칭

| 키워드 | 리소스 |
|--------|--------|
| lint, formatter, biome | 01-local-ci.md |
| test, E2E, 통합테스트 | 01-local-ci.md |
| justfile, task runner | 01-local-ci.md |
| pre-commit, hooks | 01-local-ci.md |
| CI/CD, 파이프라인 | 02-ci-cd-pipelines.md |
| GitHub Actions | 02-ci-cd-pipelines.md |
| GitLab CI | 02-ci-cd-pipelines.md |
| 캐싱, cache | 02-ci-cd-pipelines.md |
| TypeScript + lint/test | languages/typescript.md |

## Examples

### 로컬 + 원격 CI 통합 설정
User: "TypeScript 프로젝트에 lint, test 자동화하고 GitHub Actions 설정"
→ Read 01-local-ci.md + languages/typescript.md + 02-ci-cd-pipelines.md
→ justfile, biome.json, .github/workflows/ci.yml 생성
→ just lint, just test 확인

### GitHub Actions만 설정
User: "GitHub Actions로 CI/CD 파이프라인 만들어줘"
→ Read 02-ci-cd-pipelines.md
→ .github/workflows/ci.yml 생성
→ 캐싱 + service container 설정

## Technical Details

- `resources/01-local-ci.md`: Justfile 패턴, E2E 테스트
- `resources/02-ci-cd-pipelines.md`: GitHub Actions, GitLab CI 패턴
- `resources/languages/typescript.md`: Biome, Vitest/Jest
