# SSH Authentication & Password Management

Ansible 실행 시 비밀번호를 여러 번 입력하는 것은 번거롭습니다. vars_prompt를 활용하면 한 번의 입력으로 SSH + sudo를 모두 처리할 수 있습니다.

## 문제 정의

### 비밀번호를 여러 번 입력해야 하는 경우

1. **SSH 접속 시** → ansible_password
2. **sudo 실행 시** → ansible_become_password
3. **여러 호스트 배포 시** → 각 호스트마다 반복

❌ **불편함:**
- 같은 비밀번호를 2-3번 입력
- 여러 호스트 배포 시 더 많이 입력
- 자동화의 의미가 퇴색

## 해결책: vars_prompt로 비밀번호 재사용

### 기본 패턴

```yaml
---
- name: Deploy Configuration
  hosts: "{{ target_server }}"
  gather_facts: no

  vars_prompt:
    - name: server_password
      prompt: "\nEnter password for {{ target_server }} (SSH + sudo)"
      private: yes

  vars:
    ansible_user: deploy
    ansible_password: "{{ server_password }}"
    ansible_become_password: "{{ server_password }}"

  become: yes

  tasks:
    - name: Copy configuration file
      copy:
        src: files/config.conf
        dest: /etc/service/config.conf
```

**동작 방식:**
1. Playbook 실행 시 비밀번호 1회 입력
2. `ansible_password`: SSH 인증에 사용
3. `ansible_become_password`: sudo에 사용
4. 모든 task에서 재사용

✅ **장점:**
- 비밀번호 1회 입력
- 명확한 프롬프트 메시지
- `private: yes`로 입력 숨김

## ProxyJump vs 직접 연결

### ProxyJump (Gateway를 통한 접속)

```ini
# ansible.cfg
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -J deploy@gateway.example.com
```

**언제 사용:**
- 내부 서버가 외부에서 직접 접근 불가능할 때
- Gateway 서버를 통해서만 접근 가능할 때
- 보안 정책상 점프 서버를 거쳐야 할 때

⚠️ **함정:**
- Gateway 서버 자체에 접속할 때도 ProxyJump가 적용됨
- 재귀적 프록시: gateway → gateway → gateway...
- "Connection to UNKNOWN port 65535 timed out" 오류

**해결 방법:**
```yaml
# inventory.yml
management:
  hosts:
    gateway:
      ansible_host: gateway.example.com
      ansible_ssh_common_args: ''  # ProxyJump 비활성화
```

### 직접 연결 (VPN 환경)

```ini
# ansible.cfg
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
# ProxyJump 없음
```

**언제 사용:**
- VPN으로 내부 네트워크에 연결된 상태
- 모든 서버에 직접 접근 가능할 때
- Gateway를 거칠 필요가 없을 때

✅ **장점:**
- 설정 간단
- 연결 빠름
- Gateway 서버 재귀 문제 없음

## ansible.cfg SSH 설정

### 기본 설정

```ini
[defaults]
# Inventory
inventory = inventory.yml

# SSH settings
host_key_checking = False
remote_user = deploy
private_key_file = ~/.ssh/id_rsa

# Privilege escalation
become = True
become_method = sudo
become_user = root
become_ask_pass = False  # vars_prompt 사용 시

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
```

### ProxyJump 필요 시

```ini
[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -J deploy@gateway.example.com
```

### Host별 개별 설정

```yaml
# inventory.yml
all:
  vars:
    ansible_user: deploy
    ansible_python_interpreter: /usr/bin/python3

  children:
    internal_servers:
      hosts:
        app-server-1:
          ansible_host: 10.0.1.100
        app-server-2:
          ansible_host: 10.0.1.101

    gateway:
      hosts:
        bastion:
          ansible_host: gateway.example.com
          ansible_ssh_common_args: ''  # ProxyJump 제외
```

## 비밀번호 vs SSH 키

### SSH 키 인증 (권장)

```bash
# SSH 키 생성
ssh-keygen -t rsa -b 4096 -C "deploy@example.com"

# 공개키 배포
ssh-copy-id -i ~/.ssh/id_rsa.pub deploy@target-server
```

**ansible.cfg:**
```ini
[defaults]
private_key_file = ~/.ssh/id_rsa
```

**Playbook (vars_prompt 불필요):**
```yaml
- name: Deploy Configuration
  hosts: all
  become: yes
  # vars_prompt 없음
```

✅ **장점:**
- 비밀번호 입력 불필요
- 자동화 친화적
- 보안성 높음

### 비밀번호 인증

**언제 사용:**
- SSH 키 배포가 불가능한 환경
- 임시 접근이 필요할 때
- 보안 정책상 SSH 키 사용 제한

```yaml
vars_prompt:
  - name: server_password
    prompt: "\nEnter password"
    private: yes

vars:
  ansible_password: "{{ server_password }}"
  ansible_become_password: "{{ server_password }}"
```

## 다양한 사용자 계정

### SSH 사용자와 sudo 사용자가 다를 때

```yaml
vars_prompt:
  - name: ssh_password
    prompt: "\nEnter SSH password (user: deploy)"
    private: yes

  - name: sudo_password
    prompt: "\nEnter sudo password (user: root)"
    private: yes

vars:
  ansible_user: deploy
  ansible_password: "{{ ssh_password }}"
  ansible_become_user: root
  ansible_become_password: "{{ sudo_password }}"
```

### 호스트별로 다른 비밀번호

```yaml
# vars_prompt는 전역 비밀번호만 지원
# 호스트별 비밀번호는 inventory에 저장 (권장 안 함)

# 대안: --ask-pass 플래그 사용
ansible-playbook deploy.yml --ask-pass --ask-become-pass
```

⚠️ **주의:** 호스트별 비밀번호는 Ansible Vault 사용 권장

## Justfile 통합

```justfile
# Ansible playbook 실행 (비밀번호 입력)
deploy server:
    #!/usr/bin/env bash
    cd ansible && ansible-playbook playbooks/deploy.yml -e "target_server={{server}}"

# SSH 키 사용 시 (비밀번호 불필요)
deploy-key server:
    cd ansible && ansible-playbook playbooks/deploy.yml -e "target_server={{server}}"
```

**사용:**
```bash
just deploy app-server-1
# → 비밀번호 입력 프롬프트 표시
# → SSH + sudo 모두 처리
```

## Best Practices

1. **SSH 키 인증 우선**
   - 가능하면 항상 SSH 키 사용
   - 비밀번호는 임시 접근용

2. **vars_prompt 메시지 명확히**
   - 어떤 서버인지 표시
   - SSH + sudo 모두 사용함을 명시

3. **ProxyJump 신중히 사용**
   - VPN 가능하면 직접 연결
   - Gateway 서버 자체 접속 시 제외

4. **ansible.cfg 중앙 관리**
   - 프로젝트별 ansible.cfg
   - SSH 설정 일원화

5. **비밀번호 저장 금지**
   - Playbook에 하드코딩 절대 금지
   - Ansible Vault 사용 고려

## 트러블슈팅

### "WARNING: Not prompting as we are not in interactive mode"

**원인:** stdout이 터미널이 아님 (파이프, 백그라운드)

**해결:** 직접 터미널에서 실행

### "Connection to UNKNOWN port 65535 timed out"

**원인:** ProxyJump 재귀 적용

**해결:** Gateway 서버에 `ansible_ssh_common_args: ''` 설정

### "Permission denied (publickey,password)"

**원인:**
- SSH 키가 없고 비밀번호도 안 됨
- 잘못된 사용자 이름

**해결:**
- ansible_user 확인
- SSH 키 또는 vars_prompt 설정

## 참고

- [Ansible Prompts](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_prompts.html)
- [Ansible Connection Variables](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#connecting-to-hosts-behavioral-inventory-parameters)
