# DevOps Hub

DevOps 파이프라인 전문가. CI/CD, Docker, GitHub Actions를 단일 진입점에서 처리합니다.

## Domain Routing

사용자 요청의 키워드를 분석하여 도메인을 선택합니다.

### ci-cd
**시그널**: Justfile, lint, test, pre-commit, hooks, GitLab CI, 로컬 CI, 파이프라인, task runner, E2E
**로드**: `ci-cd/README.md` → 필요 리소스

### docker
**시그널**: Dockerfile, compose, compose.yaml, 컨테이너, container, 이미지, image, 멀티스테이지, multi-stage, .dockerignore
**로드**: `docker/README.md` → 필요 리소스

### github-action
**시그널**: GitHub Actions, workflow, action, trigger, push, pull_request, schedule, dispatch, release, deploy, OIDC, reusable, composite, action.yml, matrix, artifacts
**로드**: `github-action/README.md` → 필요 리소스

### 모호성 해소
- "CI/CD" 단독 → ci-cd (로컬 우선)
- "CI/CD + GitHub" or "GitHub에서 CI" → github-action
- "Docker + GitHub Actions" → 양쪽 모두 로드
- "컨테이너 배포 자동화" → docker + github-action

Read `resources/routing-guide.md` for detailed keyword→domain mapping.

## Shared Principles

1. **캐싱**: 빌드/의존성 캐시 항상 설정 (npm, pip, docker layer)
2. **보안**: 최소 권한, secrets는 환경변수, 하드코딩 금지
3. **멱등성**: 동일 입력 → 동일 결과, side-effect 최소화
4. **환경 분리**: dev/staging/prod 설정 분리, 환경별 변수 관리
5. **재현성**: 버전 고정 (도구, 이미지 태그, action SHA)

## Workflow

1. **도메인 선택**: 키워드 분석 → 1~2개 도메인 결정
2. **README 로드**: 선택된 도메인의 `README.md` Read
3. **리소스 로드**: README 내 키워드 매칭으로 필요 리소스만 Read
4. **프로젝트 분석**: 기존 설정 파일 확인
5. **설정 생성**: 도메인별 산출물 작성
6. **검증**: 문법 검증, 로컬 실행 확인

## Output Format

| 도메인 | 산출물 |
|--------|--------|
| ci-cd | justfile, lint config, .gitlab-ci.yml, pre-commit config |
| docker | Dockerfile, compose.yaml, .dockerignore |
| github-action | .github/workflows/*.yml, action.yml |

## Related Skills

- **mise-config**: 프로젝트 도구 버전/환경변수 관리 → `/mise-config`
- **security**: 보안 리뷰/취약점 점검 → `/security`
