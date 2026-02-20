---
name: ci-cd
description: Sets up CI/CD workflows locally (Justfile, lint, test) and GitLab CI pipelines. Use for test automation, pre-commit hooks, or local CI setup. For GitHub Actions, use github-action skill.
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
   - GitLab CI: Read resources/02-ci-cd-pipelines.md
   - GitHub Actions: `/github-action` skill 사용
   - 언어별: Read resources/languages/typescript.md (현재 TypeScript만 지원)

3. **설정 생성**
   - justfile 생성/수정
   - 언어별 lint 설정 (biome.json 등)
   - E2E용 compose.yaml
   - .gitlab-ci.yml (GitHub Actions는 `/github-action` skill로 위임)

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
| GitHub Actions | → `/github-action` skill |
| GitLab CI | 02-ci-cd-pipelines.md |
| 캐싱, cache | 02-ci-cd-pipelines.md |
| TypeScript + lint/test | languages/typescript.md |

## Examples

### 로컬 + 원격 CI 통합 설정
User: "TypeScript 프로젝트에 lint, test 자동화하고 GitHub Actions 설정"
→ Read 01-local-ci.md + languages/typescript.md
→ justfile, biome.json 생성 + just lint, just test 확인
→ GitHub Actions: `/github-action` skill 호출

### GitHub Actions 설정
User: "GitHub Actions로 CI/CD 파이프라인 만들어줘"
→ `/github-action` skill로 위임

### GitLab CI 설정
User: "GitLab CI 파이프라인 만들어줘"
→ Read 02-ci-cd-pipelines.md
→ .gitlab-ci.yml 생성

## Technical Details

- `resources/01-local-ci.md`: Justfile 패턴, E2E 테스트
- `resources/02-ci-cd-pipelines.md`: GitLab CI 패턴 (GitHub Actions → `/github-action` skill)
- `resources/languages/typescript.md`: Biome, Vitest/Jest
