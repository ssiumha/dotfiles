# Playbook Patterns for Safe Deployment

안전하고 구조화된 배포 playbook을 만드는 패턴들입니다.

## 기본 구조

### 최소 Playbook

```yaml
---
- name: Deploy Configuration
  hosts: target_servers
  become: yes

  tasks:
    - name: Copy configuration file
      copy:
        src: files/config.conf
        dest: /etc/service/config.conf
```

### 권장 구조

```yaml
---
- name: Deploy Configuration
  hosts: "{{ target_server }}"
  gather_facts: no

  vars_prompt:
    - name: deploy_password
      prompt: "\nEnter password for {{ target_server }}"
      private: yes

  vars:
    ansible_user: deploy
    ansible_password: "{{ deploy_password }}"
    ansible_become_password: "{{ deploy_password }}"

  become: yes

  pre_tasks:
    - name: Display deployment info
      debug:
        msg:
          - "==========================================="
          - "Deploying to: {{ inventory_hostname }}"
          - "User: {{ ansible_user }}"
          - "==========================================="
      delegate_to: localhost
      become: no

  tasks:
    # Main tasks here

  post_tasks:
    - name: Deployment complete
      debug:
        msg: "Deployment completed successfully"
      delegate_to: localhost
      become: no

  handlers:
    - name: restart service
      systemd:
        name: myservice
        state: restarted
```

## Block 구조로 서비스 분리

여러 서비스를 배포할 때 block으로 구조화합니다.

### 기본 Block

```yaml
tasks:
  - name: Service A Configuration
    block:
      - name: Check Service A config exists
        stat:
          path: "files/service-a.conf"
        register: has_service_a
        delegate_to: localhost
        become: no

      - name: Deploy Service A
        copy:
          src: files/service-a.conf
          dest: /etc/service-a/config.conf
        when: has_service_a.stat.exists
        notify: restart service-a

    when: deploy_service_a | default(true)
```

### 여러 서비스 Block

```yaml
tasks:
  # HAProxy Block
  - name: HAProxy Configuration
    block:
      - name: Check HAProxy config
        stat:
          path: "files/haproxy.cfg"
        register: has_haproxy
        delegate_to: localhost
        become: no

      - name: Show HAProxy diff
        include_role:
          name: file_diff_checker
        vars:
          diff_local_path: "files/haproxy/"
          diff_remote_path: "/etc/haproxy/"
          diff_label: "HAProxy Configuration"
        when: has_haproxy.stat.exists

      - name: Confirm HAProxy deployment
        pause:
          prompt: "Deploy HAProxy? (yes/no)"
        when: has_haproxy.stat.exists

      - name: Deploy HAProxy config
        copy:
          src: files/haproxy.cfg
          dest: /etc/haproxy/haproxy.cfg
        when: has_haproxy.stat.exists
        notify: reload haproxy

    when: has_haproxy.stat.exists | default(false)

  # Nginx Block
  - name: Nginx Configuration
    block:
      # Similar structure...
    when: has_nginx.stat.exists | default(false)

handlers:
  - name: reload haproxy
    systemd:
      name: haproxy
      state: reloaded

  - name: reload nginx
    systemd:
      name: nginx
      state: reloaded
```

## include_role로 공통 로직 재사용

### Role 사용

```yaml
- name: Check configuration differences
  include_role:
    name: file_diff_checker
  vars:
    diff_local_path: "files/configs/"
    diff_remote_path: "/etc/service/"
    diff_label: "Service Configuration"
    diff_use_sudo: true
```

### Role 결과 활용

```yaml
- name: Check differences
  include_role:
    name: file_diff_checker
  vars:
    diff_local_path: "files/"
    diff_remote_path: "/etc/service/"

- name: Deploy only if changes detected
  copy:
    src: "files/{{ item }}"
    dest: "/etc/service/{{ item }}"
  loop: "{{ diff_file_list }}"
  when: diff_has_changes
```

## 사용자 확인 패턴

### pause로 확인

```yaml
- name: Show deployment plan
  debug:
    msg:
      - "The following will be deployed:"
      - "- HAProxy: {{ has_haproxy.stat.exists }}"
      - "- Nginx: {{ has_nginx.stat.exists }}"

- name: Confirm deployment
  pause:
    prompt: "\nContinue with deployment? (yes/no)"
  register: deploy_confirm

- name: Abort if not confirmed
  meta: end_host
  when: deploy_confirm.user_input != "yes"
```

### 조건부 확인

```yaml
- name: Check critical configuration
  copy:
    src: files/production.conf
    dest: /etc/service/production.conf
  check_mode: yes
  diff: yes
  register: prod_check

- name: Confirm critical change
  pause:
    prompt: "WARNING: Production config will change! Continue? (yes/no)"
  when:
    - prod_check.changed
    - environment == "production"
```

## Handlers 활용

### 기본 Handler

```yaml
tasks:
  - name: Deploy configuration
    copy:
      src: files/config.conf
      dest: /etc/service/config.conf
    notify: restart service

handlers:
  - name: restart service
    systemd:
      name: myservice
      state: restarted
```

### 여러 Handler 체인

```yaml
tasks:
  - name: Deploy nginx config
    copy:
      src: files/nginx.conf
      dest: /etc/nginx/nginx.conf
    notify:
      - validate nginx config
      - reload nginx

handlers:
  - name: validate nginx config
    command: nginx -t

  - name: reload nginx
    systemd:
      name: nginx
      state: reloaded
    listen: "reload nginx"  # 명시적 트리거
```

### 조건부 Handler

```yaml
handlers:
  - name: restart production service
    systemd:
      name: myservice
      state: restarted
    when: environment == "production"

  - name: restart development service
    systemd:
      name: myservice-dev
      state: restarted
    when: environment == "development"
```

## 전체 워크플로우 예시

### 안전한 배포 Playbook

```yaml
---
- name: Safe Configuration Deployment
  hosts: "{{ target_server }}"
  gather_facts: no

  vars_prompt:
    - name: deploy_password
      prompt: "\nEnter password for {{ target_server }}"
      private: yes

  vars:
    ansible_user: deploy
    ansible_password: "{{ deploy_password }}"
    ansible_become_password: "{{ deploy_password }}"

  become: yes

  pre_tasks:
    - name: Display deployment info
      debug:
        msg:
          - "==========================================="
          - "Deploying to: {{ inventory_hostname }}"
          - "==========================================="
      delegate_to: localhost
      become: no

    # Detect available services
    - name: Check for HAProxy config
      stat:
        path: "files/haproxy/haproxy.cfg"
      register: has_haproxy
      delegate_to: localhost
      become: no

    - name: Check for Nginx config
      stat:
        path: "files/nginx/nginx.conf"
      register: has_nginx
      delegate_to: localhost
      become: no

    - name: Display detected services
      debug:
        msg:
          - "=== Services Detected ==="
          - "HAProxy: {{ 'Yes' if has_haproxy.stat.exists else 'No' }}"
          - "Nginx: {{ 'Yes' if has_nginx.stat.exists else 'No' }}"
      delegate_to: localhost
      become: no

  tasks:
    # HAProxy Block
    - name: HAProxy Configuration Block
      block:
        - name: Check HAProxy differences
          include_role:
            name: file_diff_checker
          vars:
            diff_local_path: "files/haproxy/"
            diff_remote_path: "/etc/haproxy/"
            diff_label: "HAProxy Configuration"

        - name: Validate HAProxy config
          command: haproxy -c -f files/haproxy/haproxy.cfg
          delegate_to: localhost
          become: no
          changed_when: false

        - name: Confirm HAProxy deployment
          pause:
            prompt: "\nDeploy HAProxy configuration? (yes/no)"
          register: haproxy_confirm

        - name: Abort HAProxy if not confirmed
          meta: end_host
          when: haproxy_confirm.user_input != "yes"

        - name: Deploy HAProxy configuration
          copy:
            src: "files/haproxy/{{ item }}"
            dest: "/etc/haproxy/{{ item }}"
          loop:
            - haproxy.cfg
          when: haproxy_confirm.user_input == "yes"
          notify: reload haproxy

      when: has_haproxy.stat.exists

    # Nginx Block
    - name: Nginx Configuration Block
      block:
        - name: Check Nginx differences
          include_role:
            name: file_diff_checker
          vars:
            diff_local_path: "files/nginx/"
            diff_remote_path: "/etc/nginx/"
            diff_label: "Nginx Configuration"

        - name: Confirm Nginx deployment
          pause:
            prompt: "\nDeploy Nginx configuration? (yes/no)"
          register: nginx_confirm

        - name: Deploy Nginx configuration
          copy:
            src: "files/nginx/{{ item }}"
            dest: "/etc/nginx/{{ item }}"
          loop:
            - nginx.conf
          when: nginx_confirm.user_input == "yes"
          notify: reload nginx

      when: has_nginx.stat.exists

  post_tasks:
    - name: Deployment summary
      debug:
        msg:
          - ""
          - "==========================================="
          - "Deployment completed for {{ inventory_hostname }}"
          - "==========================================="
      delegate_to: localhost
      become: no

  handlers:
    - name: reload haproxy
      systemd:
        name: haproxy
        state: reloaded

    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded
```

## 환경별 설정

### inventory에서 환경 구분

```yaml
# inventory.yml
all:
  children:
    production:
      hosts:
        app-server-1:
          ansible_host: 10.0.1.10
      vars:
        environment: production

    development:
      hosts:
        dev-server-1:
          ansible_host: 10.0.2.10
      vars:
        environment: development
```

### Playbook에서 환경 활용

```yaml
- name: Deploy configuration
  copy:
    src: "files/{{ environment }}/config.conf"
    dest: /etc/service/config.conf

- name: Production safety check
  pause:
    prompt: "WARNING: Deploying to PRODUCTION! Continue? (yes/no)"
  when: environment == "production"
```

## 검증 및 테스트

Playbook 작성 후 반드시 검증해야 합니다. 상세한 내용은 **05-testing-validation.md**를 참조하세요.

**핵심 워크플로우:**
```bash
# 1. Syntax check (필수)
ansible-playbook deploy.yml --syntax-check -e "server=test"

# 2. Dry-run (권장)
ansible-playbook deploy.yml --check --diff -e "server=app-server-1"

# 3. 실제 배포
ansible-playbook deploy.yml -e "server=app-server-1"
```

상세 내용:
- Syntax check, dry-run, lint
- Inventory 검증
- CI/CD 통합
- Justfile 자동화

→ **resources/05-testing-validation.md** 참조

## Best Practices

1. **항상 pre_tasks로 정보 표시**
   - 어디에 배포하는지 명확히
   - 사용자가 확인할 수 있게

2. **Block으로 서비스 구조화**
   - 논리적 단위로 분리
   - 조건부 실행 쉬움

3. **include_role로 재사용**
   - 공통 로직 중복 제거
   - 일관성 유지

4. **pause로 사용자 확인**
   - 운영 환경은 필수
   - 중요한 변경 사항은 확인

5. **handlers로 서비스 재시작**
   - 변경 있을 때만 재시작
   - 검증 후 재시작

6. **meta: end_host로 안전하게 중단**
   - 사용자가 거부하면 즉시 중단
   - 다른 호스트는 영향 없음

## 트러블슈팅

### "No hosts matched"

**원인:** hosts 패턴이 inventory와 맞지 않음

**해결:**
```bash
ansible-inventory --list  # inventory 확인
ansible-playbook deploy.yml -e "target_server=web-1" --list-hosts
```

### Handler가 실행 안 됨

**원인:** changed: false

**해결:** copy 모듈이 changed를 반환하는지 확인

### Block 전체가 스킵됨

**원인:** when 조건이 false

**해결:** 조건 확인, `-vvv`로 디버그

## 참고

- [Ansible Playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html)
- [Ansible Blocks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html)
- [Ansible Handlers](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html)
