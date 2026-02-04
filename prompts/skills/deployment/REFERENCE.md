# Ansible Deployment Automation - Reference

Ansible을 활용한 안전한 서버 배포 자동화 패턴 모음입니다.

## 개요

서버 설정 파일을 배포할 때 다음과 같은 문제를 해결합니다:

1. **배포 전 변경 사항을 확인할 수 없음** → Diff 체크 패턴
2. **비밀번호를 여러 번 입력해야 함** → vars_prompt 활용
3. **Diff 출력에 색상이 없어 가독성 떨어짐** → Copy 모듈 네이티브 diff
4. **복잡한 shell 스크립트로 인한 유지보수 어려움** → Ansible 네이티브 기능 활용

## 리소스 목록

### 01. Diff Checking (`resources/01-diff-checking.md`)

**언제 사용하나요?**
- 배포 전에 변경 사항을 확인하고 싶을 때
- 실수로 잘못된 파일을 배포하는 것을 방지하고 싶을 때
- 운영 환경에 배포 시 안전장치가 필요할 때

**핵심 내용:**
- 3가지 diff 체크 방식 비교 (synchronize, fetch+diff, copy)
- copy 모듈의 check_mode + diff가 최선인 이유
- file_diff_checker role 구현 패턴
- 색상 diff 출력 방법

**학습 곡선:** ⭐⭐ (중간)

### 02. SSH Authentication (`resources/02-ssh-auth.md`)

**언제 사용하나요?**
- Ansible 실행 시 비밀번호를 여러 번 입력하기 귀찮을 때
- SSH + sudo 비밀번호가 같은 환경에서 한 번만 입력하고 싶을 때
- ProxyJump 설정이 필요한 Gateway 환경일 때

**핵심 내용:**
- vars_prompt로 비밀번호 재사용
- ansible_password + ansible_become_password 설정
- ProxyJump vs 직접 연결 선택 기준
- VPN 환경에서의 함정

**학습 곡선:** ⭐ (쉬움)

### 03. Copy Module (`resources/03-copy-module.md`)

**언제 사용하나요?**
- 파일을 배포하면서 diff를 확인하고 싶을 때
- Dry-run으로 변경 사항만 확인하고 싶을 때
- Ansible 네이티브 방식으로 파일 동기화하고 싶을 때

**핵심 내용:**
- copy 모듈의 check_mode 파라미터
- diff 파라미터로 색상 diff 출력
- loop와 조합하여 여러 파일 처리
- changed 상태 판단 및 활용

**학습 곡선:** ⭐ (쉬움)

### 04. Playbook Patterns (`resources/04-playbook-patterns.md`)

**언제 사용하나요?**
- 안전한 배포 playbook을 설계하고 싶을 때
- 서비스별로 구조화된 배포 프로세스가 필요할 때
- 사용자 확인 후 배포하는 워크플로우를 만들고 싶을 때

**핵심 내용:**
- Block 구조로 서비스별 배포 분리
- include_role로 공통 로직 재사용
- pause로 사용자 확인
- handlers로 서비스 reload

**학습 곡선:** ⭐⭐⭐ (어려움)

## 권장 학습 순서

### 초급: 기본 배포 자동화
1. Copy Module (03) - 파일 배포 기본
2. SSH Authentication (02) - 비밀번호 입력 간소화
3. Diff Checking (01) - 배포 전 확인

### 중급: 안전한 배포 프로세스
1. Diff Checking (01) - file_diff_checker role 구현
2. Playbook Patterns (04) - 구조화된 배포 playbook
3. 실전 적용 - 운영 환경 배포

## 실전 시나리오

### 시나리오 1: 단일 서버 설정 파일 배포

**목표**: `/etc/nginx/nginx.conf` 파일을 배포하되, 변경 사항을 확인한 후 진행

**필요 리소스**:
- 03-copy-module.md (copy 모듈 사용법)
- 02-ssh-auth.md (비밀번호 입력)

**구현**:
```yaml
- name: Deploy nginx.conf
  copy:
    src: files/nginx.conf
    dest: /etc/nginx/nginx.conf
  check_mode: yes
  diff: yes
```

### 시나리오 2: 여러 서비스 설정 파일 일괄 배포

**목표**: HAProxy, Squid, Alloy 등 여러 서비스의 설정 파일을 순차적으로 배포

**필요 리소스**:
- 01-diff-checking.md (file_diff_checker role)
- 04-playbook-patterns.md (block 구조)
- 02-ssh-auth.md (vars_prompt)

**구현**:
- file_diff_checker role 생성
- Block 구조로 서비스별 분리
- 각 서비스마다 diff → 확인 → 배포 → reload

### 시나리오 3: Gateway를 통한 원격 서버 배포

**목표**: ProxyJump를 통해 내부 서버에 배포

**필요 리소스**:
- 02-ssh-auth.md (ProxyJump 설정)
- 01-diff-checking.md (원격 diff 체크)

**구현**:
- ansible.cfg에 ProxyJump 설정
- file_diff_checker가 ProxyJump를 통해 동작하도록 설정

## 트러블슈팅

### 문제 1: "Permission denied (publickey,password)"

**원인**: synchronize 모듈이 rsync를 직접 호출하여 ansible SSH 연결을 우회

**해결**: copy 모듈 사용 (ansible SSH 연결 활용)

**참고**: 01-diff-checking.md

### 문제 2: Diff에 색상이 없어 가독성 떨어짐

**원인**: shell diff + debug 모듈 사용 시 ANSI 색상 코드가 escape 처리됨

**해결**: copy 모듈의 diff 파라미터 사용 (Ansible이 자동 색상 처리)

**참고**: 03-copy-module.md

### 문제 3: ProxyJump 설정이 재귀적으로 적용됨

**원인**: Gateway 서버 자체에 접속할 때도 ProxyJump가 적용됨

**해결**: ansible.cfg에서 ProxyJump 제거, 필요 시 host별 설정

**참고**: 02-ssh-auth.md

## Best Practices

1. **항상 diff를 확인한 후 배포**
   - check_mode로 먼저 확인
   - 사용자 승인 후 실제 배포

2. **Ansible 네이티브 기능 우선**
   - shell 스크립트보다 Ansible 모듈 사용
   - rsync보다 copy 모듈 사용

3. **비밀번호는 한 번만**
   - vars_prompt로 재사용
   - ansible_password + ansible_become_password

4. **구조화된 playbook**
   - Block으로 서비스별 분리
   - Role로 공통 로직 재사용
   - Handlers로 서비스 재시작

5. **테스트 가능한 구조**
   - check_mode로 dry-run
   - 개발 환경에서 먼저 테스트
   - 운영 배포는 신중하게

## 관련 문서

- [Ansible 공식 문서 - Copy Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)
- [Ansible 공식 문서 - Check Mode](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
