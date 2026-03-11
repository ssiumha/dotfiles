# Docker Domain

Docker 기반 개발 환경 및 컨테이너 이미지를 구성합니다.

## 핵심 철학

- compose.yaml (docker compose v2 표준)
- 멀티스테이지 빌드로 이미지 최적화
- .dockerignore로 빌드 컨텍스트 최소화
- 개발/운영 환경 분리

## 리소스

| 키워드 | 리소스 |
|--------|--------|
| Dockerfile, 이미지 빌드, 멀티스테이지 | 01-docker.md |
| compose, compose.yaml, 서비스 | 01-docker.md |
| 컨테이너, .dockerignore | 01-docker.md |

## Workflow

1. 프로젝트 언어/프레임워크 확인
2. Read `01-docker.md`
3. Dockerfile + compose.yaml + .dockerignore 생성
4. `docker compose build && docker compose up` 확인
