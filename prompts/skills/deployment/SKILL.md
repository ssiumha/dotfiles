---
name: deployment
description: Automates deployments and infrastructure management. Use for PM2, Helmfile/K8s, Ansible playbooks, database config, monitoring setup, or multi-server automation.
---

# Deployment & Infrastructure Automation

배포, 인프라, 모니터링, 서버 자동화를 통합 관리합니다.

**핵심 철학**:
- 점진적 롤아웃, 빠른 롤백
- 배포 전 diff 확인 필수
- 환경별 설정 분리 (dev/staging/prod)
- Ansible 네이티브 기능 우선 (shell 스크립트 최소화)
- 관측성(Observability) 기본 탑재

## Instructions

### 워크플로우: 요청 분석 및 리소스 선택

사용자 요청의 키워드를 분석하여 필요한 리소스만 로드합니다.

#### 키워드 매칭

**Ansible 자동화** (resources/01-05)
| 키워드 | 리소스 |
|--------|--------|
| ansible, diff, 차이, 변경 사항, dry-run | 01-diff-checking.md |
| SSH, 인증, 비밀번호, vars_prompt, ProxyJump | 02-ssh-auth.md |
| copy 모듈, 파일 동기화, 파일 배포 | 03-copy-module.md |
| playbook, role, handler, 서비스 reload | 04-playbook-patterns.md |
| syntax check, lint, 검증, 테스트 | 05-testing-validation.md |

**DevOps 인프라** (resources/06-09)
| 키워드 | 리소스 |
|--------|--------|
| 배포, deploy, PM2, 스크립트 | 06-deployment.md |
| postgres, mysql, DB, 데이터베이스 | 07-database.md |
| helmfile, k8s, kubernetes | 08-helmfile-k8s.md |
| prometheus, grafana, 모니터링, observability | 09-observability.md |

#### 리소스 적용

1. **환경 파악**: 타겟 환경 확인 (VM, K8s, 컨테이너, Ansible)
2. **리소스 로드**: 키워드 매칭으로 필요 리소스 Read
3. **설정 생성**: 환경에 맞는 설정 파일 생성
4. **검증**: dry-run, diff로 변경 사항 확인

## Examples

### Ansible 안전 배포
User: "Ansible로 설정 파일 안전하게 배포"
→ Read 01-diff-checking.md, 03-copy-module.md, 04-playbook-patterns.md
→ Playbook 생성 (diff → 확인 → 배포 → reload)

### PM2 배포
User: "PM2로 Node 앱 배포 설정"
→ Read 06-deployment.md
→ ecosystem.config.js 생성

### Helmfile K8s 배포
User: "Helmfile로 K8s 배포 설정해줘"
→ Read 08-helmfile-k8s.md
→ helmfile.yaml + values/ 생성

### Observability 구축
User: "Prometheus, Grafana 모니터링 설정"
→ Read 09-observability.md
→ prometheus.yml, dashboard 설정

## Technical Details

상세한 설정 및 예제는 각 리소스 파일 참조:
- `REFERENCE.md`: 리소스 전체 개요
- Ansible: 01-05 (diff, SSH, copy, playbook, testing)
- DevOps: 06-09 (deployment, database, k8s, observability)
