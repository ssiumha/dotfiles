# Testing and Validation

Playbook 작성 후 반드시 검증해야 합니다.

## Syntax Check (필수)

작성한 playbook의 YAML 문법을 검증합니다.

```bash
# 기본 syntax check
ansible-playbook deploy.yml --syntax-check

# extra vars가 필요한 경우
ansible-playbook deploy.yml --syntax-check -e "server=test"
```

**언제 실행:**
- Playbook 작성 직후
- 수정할 때마다
- Git commit 전

**왜 중요한가:**
- YAML 문법 오류를 사전에 발견
- 변수 미정의 문제 조기 발견
- 실행 전 빠른 검증 (1-2초)

## Dry-Run (권장)

실제 변경 없이 어떤 작업이 수행될지 확인합니다.

```bash
# check mode: 변경 없이 시뮬레이션
ansible-playbook deploy.yml --check -e "server=app-server-1"

# check + diff: 변경될 내용까지 표시
ansible-playbook deploy.yml --check --diff -e "server=app-server-1"
```

**주의사항:**
- check mode는 완벽하지 않음 (일부 모듈은 지원 안 함)
- 파일이 없으면 diff가 정확하지 않을 수 있음
- 일부 task는 check mode에서 skip될 수 있음

**언제 사용:**
- 운영 배포 전 변경 사항 확인
- 새로운 playbook 테스트
- 불확실한 변경 사항 검토

## Inventory 검증

Inventory 파일이 올바른지 확인합니다.

```bash
# inventory 전체 확인
ansible-inventory --list

# 특정 호스트 확인
ansible-inventory --host app-server-1

# 호스트 그룹 확인
ansible-inventory --graph
```

**확인 사항:**
- 호스트가 올바른 그룹에 속해있는지
- ansible_host IP가 정확한지
- 변수가 올바르게 설정되었는지

## List Hosts

어떤 호스트에 배포될지 미리 확인합니다.

```bash
# 대상 호스트 확인
ansible-playbook deploy.yml --list-hosts -e "server=app-server-1"

# 모든 task 확인
ansible-playbook deploy.yml --list-tasks -e "server=app-server-1"

# 특정 tag만 확인
ansible-playbook deploy.yml --list-tasks --tags haproxy
```

**활용:**
- 잘못된 호스트로 배포 방지
- playbook 구조 파악
- 어떤 task가 실행될지 사전 확인

## Ansible Lint (선택)

Playbook의 best practices를 검증합니다.

```bash
# ansible-lint 설치
pip install ansible-lint

# playbook 검증
ansible-lint deploy.yml

# 특정 규칙 무시
ansible-lint -x 301,303 deploy.yml

# 심각한 오류만 표시
ansible-lint --severity error deploy.yml
```

**흔한 경고:**
- `[301]` Commands should not change things if nothing needs doing
- `[303]` Use shell only when shell functionality is required
- `[305]` Use shell only when shell functionality is required
- `[208]` File permissions unset or incorrect
- `[106]` Role name does not match ^[a-z][a-z0-9_]+$ pattern

**처리 방법:**
- 경고는 무시해도 됨 (프로젝트 상황에 따라)
- 에러는 반드시 수정
- `.ansible-lint` 파일로 규칙 커스터마이징 가능

## Verbose 모드

실행 과정을 상세히 확인합니다.

```bash
# 기본 verbose
ansible-playbook deploy.yml -v

# 더 상세히 (연결 정보)
ansible-playbook deploy.yml -vv

# 매우 상세히 (모듈 실행 내용)
ansible-playbook deploy.yml -vvv

# 디버그 수준 (내부 동작)
ansible-playbook deploy.yml -vvvv
```

**언제 사용:**
- 에러 디버깅
- 느린 task 원인 파악
- SSH 연결 문제 진단

## 검증 워크플로우

### 개발 환경 배포

```bash
# 1. Syntax check (필수)
ansible-playbook deploy.yml --syntax-check -e "server=app-server-1"

# 2. List hosts (확인)
ansible-playbook deploy.yml --list-hosts -e "server=app-server-1"

# 3. Dry-run (권장)
ansible-playbook deploy.yml --check --diff -e "server=app-server-1"

# 4. 실제 실행
ansible-playbook deploy.yml -e "server=app-server-1"
```

### 운영 환경 배포

```bash
# 1. Syntax check
ansible-playbook deploy.yml --syntax-check -e "server=app-server-2"

# 2. Lint (권장)
ansible-lint deploy.yml

# 3. Inventory 확인
ansible-inventory --host app-server-2

# 4. List hosts (필수)
ansible-playbook deploy.yml --list-hosts -e "server=app-server-2"

# 5. Dry-run (필수!)
ansible-playbook deploy.yml --check --diff -e "server=app-server-2"

# 6. 사용자 확인 후 실행
ansible-playbook deploy.yml -e "server=app-server-2"
```

## Justfile 통합

검증 명령어를 justfile에 통합하여 쉽게 사용합니다.

```justfile
# Syntax check
ansible-check playbook:
    cd ansible && ansible-playbook playbooks/{{playbook}}.yml --syntax-check -e "server=test"

# Dry-run with diff
ansible-dry playbook server:
    cd ansible && ansible-playbook playbooks/{{playbook}}.yml --check --diff -e "server={{server}}"

# List hosts
ansible-list playbook server:
    cd ansible && ansible-playbook playbooks/{{playbook}}.yml --list-hosts -e "server={{server}}"

# Lint
ansible-lint playbook:
    cd ansible && ansible-lint playbooks/{{playbook}}.yml

# 실제 배포 (검증 후)
ansible-deploy playbook server:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible

    echo "Running syntax check..."
    ansible-playbook playbooks/{{playbook}}.yml --syntax-check -e "server={{server}}"

    echo "Running dry-run..."
    ansible-playbook playbooks/{{playbook}}.yml --check --diff -e "server={{server}}"

    echo ""
    read -p "Continue with deployment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled"
        exit 1
    fi

    ansible-playbook playbooks/{{playbook}}.yml -e "server={{server}}"
```

**사용:**
```bash
# Syntax check
just ansible-check deploy-etc

# Dry-run
just ansible-dry deploy-etc app-server-1

# List hosts
just ansible-list deploy-etc app-server-1

# Lint
just ansible-lint deploy-etc

# 안전한 배포 (검증 포함)
just ansible-deploy deploy-etc app-server-1
```

## CI/CD 통합

GitHub Actions 예시:

```yaml
name: Ansible Validation

on:
  pull_request:
    paths:
      - 'ansible/**'

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Ansible
        run: pip install ansible ansible-lint

      - name: Syntax Check
        run: |
          cd ansible
          ansible-playbook playbooks/*.yml --syntax-check -e "server=test"

      - name: Ansible Lint
        run: |
          cd ansible
          ansible-lint playbooks/*.yml
```

## Best Practices

1. **항상 syntax check 먼저**
   - 가장 빠른 검증
   - Git commit 전 필수

2. **운영 배포는 dry-run 필수**
   - 변경 사항을 눈으로 확인
   - 예상치 못한 변경 방지

3. **Justfile로 자동화**
   - 검증 절차를 일관되게 유지
   - 실수 방지

4. **Verbose 모드 활용**
   - 문제 발생 시 -vvv로 재실행
   - 디버깅 시간 단축

5. **CI에서 자동 검증**
   - PR마다 자동으로 syntax check + lint
   - 팀 전체의 품질 유지

## 참고

- [Ansible Check Mode](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html)
- [Ansible Lint](https://ansible-lint.readthedocs.io/)
- [Testing Strategies](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)
