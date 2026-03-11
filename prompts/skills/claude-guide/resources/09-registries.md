# Skill Registries Guide

이 문서는 Claude Code에서 사용 가능한 Skill 저장소(Registry)의 큐레이션된 목록입니다.

## 주요 저장소 (Primary Registries)

### 1. Vercel Labs - Agent Skills

**저장소**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)

**설명**: React, Next.js, Vercel 플랫폼을 중심으로 한 프론트엔드 개발 Skills

**주요 Skills**:
- React component patterns
- Next.js App Router configuration
- Vercel deployment automation
- Frontend optimization techniques
- TypeScript patterns

**사용 예시**:
```bash
# Vercel registry에서 React skill 설치
claude install skill --registry vercel-labs/agent-skills --skill react-patterns
```

**특징**:
- 최신 React 18+ 및 Next.js 14+ 지원
- TypeScript 기반 타입 안전성
- Production-ready patterns

---

### 2. Anthropic Official Skills (예상)

**저장소**: `anthropic/claude-code-skills` (예상 위치)

**설명**: Anthropic에서 공식적으로 지원하는 Claude Code 기본 Skills

**주요 Skills**:
- Code exploration and refactoring
- Documentation generation
- Test writing and validation
- Git workflow automation
- Security review and compliance

**사용 예시**:
```bash
# Anthropic official registry
claude install skill --registry anthropic --skill code-explorer
```

**특징**:
- 공식 Anthropic 지원
- 모든 프로그래밍 언어 지원
- 최신 Claude 모델과 최적화

---

### 3. Community Skills Registry

**저장소**: [claude-skills-community](https://github.com/claude-skills-community) (가정)

**설명**: 커뮤니티에서 기여한 다양한 Skills 모음

**주요 카테고리**:
- Backend development (Python, Go, Java, Node.js)
- DevOps and infrastructure (Docker, Kubernetes, Terraform)
- Database management (PostgreSQL, MongoDB, DynamoDB)
- API development (REST, GraphQL)
- Testing frameworks (Jest, Pytest, Go test)

**사용 예시**:
```bash
# 커뮤니티 registry에서 Python skill 설치
claude install skill --registry community --skill django-patterns
```

---

### 4. Enterprise Skills Registry

**저장소**: `enterprise/claude-skills` (Private/Enterprise)

**설명**: 엔터프라이즈 환경을 위한 정책 및 보안 중심 Skills

**주요 Skills**:
- SSO and authentication patterns
- Data governance and compliance
- Multi-tenancy architecture
- Audit logging and monitoring
- Enterprise deployment patterns

**사용 예시**:
```bash
# Enterprise registry (자격증명 필요)
claude install skill --registry enterprise --skill sso-patterns --auth token
```

---

## 기술별 추천 Skills

### Frontend Development
```yaml
Registries:
  - vercel-labs/agent-skills
  - anthropic/claude-code-skills

Featured Skills:
  - react-patterns
  - next-app-router
  - tailwind-css
  - typescript-patterns
```

### Backend Development
```yaml
Registries:
  - anthropic/claude-code-skills
  - community

Featured Skills:
  - python-fastapi
  - nodejs-express
  - go-gin
  - rust-actix
```

### DevOps & Infrastructure
```yaml
Registries:
  - community
  - anthropic/claude-code-skills

Featured Skills:
  - docker-patterns
  - kubernetes-manifests
  - terraform-aws
  - github-actions-workflows
```

---

## 커스텀 Registry 추가 방법

### 1. 로컬 Registry 설정

프로젝트의 `claude.yml` 또는 `.claude/config.yml`에 다음을 추가합니다:

```yaml
registries:
  - name: "my-company-skills"
    url: "https://github.com/my-company/claude-skills"
    type: "github"
    branch: "main"

  - name: "local-skills"
    url: "file:///path/to/local/skills"
    type: "local"
```

### 2. GitHub Organization Registry

내 조직의 skill repository를 registry로 등록:

```bash
claude registry add \
  --name "acme-corp-skills" \
  --url "https://github.com/acme-corp/skills" \
  --type github \
  --token $GITHUB_TOKEN
```

### 3. Private Registry (Token 기반)

```bash
claude registry add \
  --name "internal-registry" \
  --url "https://registry.internal.company.com" \
  --type private \
  --auth-header "Authorization: Bearer $INTERNAL_TOKEN"
```

### 4. Git Submodule로 등록

```bash
# 프로젝트에 skills를 submodule로 추가
git submodule add https://github.com/my-org/skills ./prompts/skills/custom

# claude.yml에서 참조
registries:
  - name: "custom"
    url: "file://./prompts/skills/custom"
    type: "local"
```

---

## Registry 우선순위 (Resolution Order)

Claude는 다음 순서로 Skills를 검색합니다:

1. **Local Registry** - 프로젝트 내 `.claude/skills/`
2. **Project Config** - `claude.yml`에 정의된 registries (순서대로)
3. **Global Config** - `~/.claude/config.yml`의 registries
4. **Default Registries** - Anthropic official + community

---

## Registry 관리 명령어

```bash
# 모든 등록된 registry 나열
claude registry list

# Registry 우선순위 확인
claude registry list --with-priority

# Registry에서 사용 가능한 skills 검색
claude registry search --registry vercel-labs --query react

# Registry 상태 확인 (접근성, 최신 업데이트)
claude registry status --registry anthropic

# 등록된 registry 제거
claude registry remove --name my-company-skills

# Registry 캐시 갱신
claude registry refresh --all
```

---

## Best Practices

### 1. Registry 선택

- **프로토타입**: Anthropic official + Vercel Labs 추천
- **프로덕션**: 검증된 skills + 엔터프라이즈 registry
- **팀 프로젝트**: 회사 내부 registry + 커뮤니티 registry 혼합

### 2. Skill 버전 관리

```yaml
skills:
  - name: "react-patterns"
    registry: "vercel-labs"
    version: "^1.2.0"  # Semantic versioning

  - name: "security-review"
    registry: "anthropic"
    version: "latest"  # 항상 최신 버전
```

### 3. Registry 보안

```bash
# 신뢰할 수 있는 registry만 추가
# NEVER: 서명되지 않은 또는 검증되지 않은 registry

# 정기적으로 registry 감사
claude registry audit --verbose

# Private registry는 항상 HTTPS 사용
# 액세스 토큰은 환경변수로 관리
export CLAUDE_REGISTRY_TOKEN_INTERNAL=$(cat ~/.tokens/internal-registry)
```

### 4. 성능 최적화

```bash
# Registry 캐시 설정
claude config set registry.cache-ttl 3600  # 1시간

# 오프라인 모드 (캐시된 skills만 사용)
claude skill install --offline --registry local

# Registry 미러링 (대역폭 절감)
claude registry mirror --source anthropic --dest local
```

---

## Skill 개발 및 배포

자신의 Skills를 만들어 공유하려면:

```bash
# 새로운 skill 프로젝트 생성
claude skill init --name my-awesome-skill --template default

# 로컬에서 테스트
claude skill install --local ./my-awesome-skill

# GitHub에 배포 후 registry에 등록
cd my-awesome-skill && git push origin main

# Registry에 등록 요청
# Anthropic 커뮤니티 registry: community-contributions 이슈 생성
# 또는 자신의 registry에 직접 추가
```

---

## 문제 해결

### Registry 연결 오류

```bash
# Registry 연결 테스트
claude registry test --name anthropic

# 상세 진단 로그
claude registry test --name anthropic --verbose

# 프록시 설정 (필요한 경우)
claude config set registry.proxy https://proxy.company.com:3128
```

### Skill 버전 충돌

```bash
# 의존성 확인
claude skill deps --registry anthropic --skill code-explorer

# 호환 버전 찾기
claude registry search --registry community --skill python-fastapi --all-versions
```

---

## 참고 자료

- [Claude Code Skill Registry Documentation](https://claude.ai/docs/skills)
- [GitHub: Vercel Agent Skills](https://github.com/vercel-labs/agent-skills)
- [Claude Skills Best Practices](https://claude.ai/docs/skills/best-practices)
