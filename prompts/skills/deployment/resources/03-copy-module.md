# Copy Module Deep Dive

Ansible의 copy 모듈은 단순히 파일을 복사하는 것 이상의 기능을 제공합니다. check_mode와 diff를 활용하면 안전한 배포 워크플로우를 만들 수 있습니다.

## 기본 사용법

### 단일 파일 복사

```yaml
- name: Copy configuration file
  copy:
    src: files/nginx.conf
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
```

### 여러 파일 복사

```yaml
- name: Copy multiple files
  copy:
    src: "files/{{ item }}"
    dest: "/etc/service/{{ item }}"
  loop:
    - config.conf
    - logrotate.conf
    - systemd.service
```

## check_mode: Dry-Run

`check_mode: yes`를 사용하면 실제로 파일을 복사하지 않고 변경 사항만 확인합니다.

### 기본 예시

```yaml
- name: Check if file would change
  copy:
    src: files/config.conf
    dest: /etc/service/config.conf
  check_mode: yes
  register: check_result

- debug:
    msg: "File would be changed: {{ check_result.changed }}"
```

**동작:**
- 원격 파일과 로컬 파일을 비교
- 다르면 `changed: true`
- 같으면 `changed: false`
- 실제 복사는 하지 않음

### 조건부 실행

```yaml
- name: Check configuration
  copy:
    src: files/important.conf
    dest: /etc/service/important.conf
  check_mode: yes
  register: config_check

- name: Confirm before deployment
  pause:
    prompt: "Configuration will change. Continue? (yes/no)"
  when: config_check.changed

- name: Deploy configuration
  copy:
    src: files/important.conf
    dest: /etc/service/important.conf
  when: config_check.changed
```

## diff: 변경 내용 표시

`diff: yes`를 사용하면 unified diff 형식으로 변경 내용을 표시합니다.

### Diff 표시

```yaml
- name: Show file differences
  copy:
    src: files/config.conf
    dest: /etc/service/config.conf
  check_mode: yes
  diff: yes
```

**출력:**
```diff
--- before: /etc/service/config.conf
+++ after: /path/to/files/config.conf
@@ -15,7 +15,8 @@
 [server]
 port = 8080
-host = localhost
+host = 0.0.0.0
+workers = 4

 [logging]
 level = info
```

**색상:**
- `---` / `+++`: 파일 경로
- `@@`: 변경 위치 (청록색)
- `+`: 추가된 라인 (녹색)
- `-`: 삭제된 라인 (빨간색)

### check_mode + diff 조합

```yaml
- name: Preview changes before deployment
  copy:
    src: "files/{{ item }}"
    dest: "/etc/service/{{ item }}"
  check_mode: yes
  diff: yes
  loop:
    - config.conf
    - database.conf
  register: diff_results

- name: Count changed files
  set_fact:
    changed_count: "{{ diff_results.results | selectattr('changed') | list | length }}"

- debug:
    msg: "{{ changed_count }} file(s) will be updated"
```

## Loop와 조합

### 파일 목록으로 반복

```yaml
- name: Deploy configuration files
  copy:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: "{{ item.mode | default('0644') }}"
  loop:
    - { src: 'files/app.conf', dest: '/etc/app/app.conf' }
    - { src: 'files/db.conf', dest: '/etc/app/db.conf', mode: '0600' }
  check_mode: yes
  diff: yes
```

### 동적 파일 목록

```yaml
- name: Find local configuration files
  find:
    paths: files/configs/
    patterns: '*.conf'
  register: local_configs
  delegate_to: localhost

- name: Deploy all configurations
  copy:
    src: "{{ item.path }}"
    dest: "/etc/service/{{ item.path | basename }}"
  loop: "{{ local_configs.files }}"
  check_mode: yes
  diff: yes
```

## Register와 결과 처리

### changed 상태 확인

```yaml
- name: Copy configuration
  copy:
    src: files/config.conf
    dest: /etc/service/config.conf
  check_mode: yes
  register: result

- debug:
    msg: "Status: {{ 'Changed' if result.changed else 'No change' }}"
```

### Loop 결과 처리

```yaml
- name: Deploy multiple files
  copy:
    src: "files/{{ item }}"
    dest: "/etc/service/{{ item }}"
  loop:
    - config1.conf
    - config2.conf
    - config3.conf
  check_mode: yes
  register: copy_results

- name: Show which files changed
  debug:
    msg: "{{ item.item }} - Changed: {{ item.changed }}"
  loop: "{{ copy_results.results }}"
  loop_control:
    label: "{{ item.item }}"
  when: item.changed
```

## 고급 기능

### 백업 생성

```yaml
- name: Copy with backup
  copy:
    src: files/config.conf
    dest: /etc/service/config.conf
    backup: yes  # 기존 파일을 .backup으로 저장
```

### 검증 (validation)

```yaml
- name: Copy nginx config with validation
  copy:
    src: files/nginx.conf
    dest: /etc/nginx/nginx.conf
    validate: nginx -t -c %s  # 복사 전 검증
```

### Content 직접 지정

```yaml
- name: Create config from template variable
  copy:
    content: |
      [server]
      host = {{ server_host }}
      port = {{ server_port }}
    dest: /etc/service/config.conf
  check_mode: yes
  diff: yes
```

## 권한 및 소유권

### 기본 설정

```yaml
- name: Copy with permissions
  copy:
    src: files/secret.key
    dest: /etc/service/secret.key
    owner: service
    group: service
    mode: '0600'  # rw-------
```

### become 사용

```yaml
- name: Copy to system directory
  copy:
    src: files/system.conf
    dest: /etc/system/system.conf
  become: yes  # sudo 권한으로 실행
```

## 실전 패턴

### 1. Diff → 확인 → 배포

```yaml
# Step 1: Show diff
- name: Check changes
  copy:
    src: files/config.conf
    dest: /etc/service/config.conf
  check_mode: yes
  diff: yes
  register: config_diff

# Step 2: User confirmation
- pause:
    prompt: "Deploy configuration? (yes/no)"
  when: config_diff.changed

# Step 3: Deploy
- name: Deploy configuration
  copy:
    src: files/config.conf
    dest: /etc/service/config.conf
  when: config_diff.changed
```

### 2. 여러 파일 일괄 처리

```yaml
- name: Find all configuration files
  find:
    paths: files/
    patterns: '*.conf'
  register: conf_files
  delegate_to: localhost

- name: Check all configurations
  copy:
    src: "{{ item.path }}"
    dest: "/etc/service/{{ item.path | basename }}"
  check_mode: yes
  diff: yes
  loop: "{{ conf_files.files }}"
  register: all_diffs

- name: Count changes
  set_fact:
    total_changes: "{{ all_diffs.results | selectattr('changed') | list | length }}"

- name: Deploy all if confirmed
  copy:
    src: "{{ item.path }}"
    dest: "/etc/service/{{ item.path | basename }}"
  loop: "{{ conf_files.files }}"
  when: deploy_confirmed | default(false)
```

### 3. 서비스 재시작과 연동

```yaml
- name: Deploy application config
  copy:
    src: files/app.conf
    dest: /etc/app/app.conf
  notify: restart app service

handlers:
  - name: restart app service
    systemd:
      name: app
      state: restarted
```

## 주의사항

### 1. check_mode 제한사항

- 원격 파일이 없으면 항상 `changed: true`
- 실제 배포 시 권한 문제 발생 가능
- 검증(validation)은 실행 안 됨

### 2. Diff 크기 제한

```bash
# 기본 제한: 104448 bytes
export ANSIBLE_MAX_DIFF_SIZE=524288  # 512KB로 증가
```

### 3. 민감한 정보

```yaml
- name: Copy secret file
  copy:
    src: files/secret.key
    dest: /etc/service/secret.key
    mode: '0600'
  no_log: yes  # diff 출력 숨김
```

## copy vs template vs synchronize

### copy
- 정적 파일 복사
- check_mode + diff 지원
- 단순하고 명확

### template
- Jinja2 템플릿 렌더링
- 변수 치환 필요 시
- check_mode + diff 지원

### synchronize
- rsync 기반
- 디렉토리 동기화
- ❌ vars_prompt와 호환 문제

**권장:** 설정 파일 배포는 copy 또는 template 사용

## Best Practices

1. **항상 check_mode로 먼저 확인**
2. **diff로 변경 내용 검토**
3. **중요 파일은 backup: yes**
4. **권한 명시 (mode, owner, group)**
5. **validate로 문법 검증**

## 참고

- [Ansible Copy Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)
- [Ansible Check Mode](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html)
