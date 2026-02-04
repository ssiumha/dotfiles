# Diff Checking Pattern

배포 전에 변경 사항을 확인하는 것은 필수입니다. 잘못된 설정 파일 배포로 인한 서비스 장애를 방지할 수 있습니다.

## 문제 정의

### 기존 방식의 문제점

**1. synchronize 모듈의 --itemize-changes**
```yaml
- name: Check changes
  synchronize:
    src: local/config.conf
    dest: /etc/service/config.conf
    rsync_opts:
      - "--dry-run"
      - "--itemize-changes"
```

❌ **문제점:**
- 파일 목록만 표시 (`>f++++++++ file`)
- 실제 내용의 차이 (+ - 라인)는 표시 안 됨
- 사용자가 "무엇이 바뀌는지" 알 수 없음

**2. 별도 diff 체크 스크립트**
```yaml
- name: Download file
  fetch:
    src: /etc/service/config.conf
    dest: /tmp/remote.conf

- name: Run diff
  shell: diff -u /tmp/remote.conf local/config.conf
```

❌ **문제점:**
- 여러 파일 처리 시 복잡함
- 임시 파일 관리 필요
- 코드 중복

## 해결책: Copy 모듈의 네이티브 Diff

Ansible의 copy 모듈은 `check_mode` + `diff` 조합으로 완벽한 diff 체크를 제공합니다.

### 기본 사용법

```yaml
- name: Check file differences
  copy:
    src: local/config.conf
    dest: /etc/service/config.conf
  check_mode: yes
  diff: yes
```

**출력 예시:**
```diff
--- before: /etc/service/config.conf
+++ after: /path/to/local/config.conf
@@ -10,6 +10,7 @@
 bind 0.0.0.0:80

+# New configuration
 upstream backend {
-    server 192.168.1.100:8080;
+    server 10.0.1.100:8080;
+    server 10.0.1.101:8080;
}
```

✅ **장점:**
- **색상 출력**: + 라인은 녹색, - 라인은 빨간색
- **Ansible 네이티브**: 별도 도구 불필요
- **간결한 코드**: 3줄로 해결
- **신뢰성**: Ansible이 관리하는 SSH 연결 사용

## file_diff_checker Role 패턴

여러 파일을 체계적으로 체크하는 재사용 가능한 role입니다.

### 디렉토리 구조

```
ansible/roles/file_diff_checker/
├── tasks/
│   └── main.yml
└── defaults/
    └── main.yml
```

### defaults/main.yml

```yaml
---
diff_use_sudo: true
diff_label: "File Differences"
```

### tasks/main.yml

```yaml
---
# File Diff Checker Role
# Uses Ansible copy module's native diff feature

- name: Validate required parameters
  assert:
    that:
      - diff_local_path is defined
      - diff_remote_path is defined
    fail_msg: "diff_local_path and diff_remote_path are required"

- name: Ensure remote directory exists
  file:
    path: "{{ diff_remote_path }}"
    state: directory
    mode: '0755'
  become: "{{ diff_use_sudo }}"

# Step 1: Get list of local files
- name: Find local files
  find:
    paths: "{{ diff_local_path }}"
    file_type: file
    recurse: no
  register: diff_local_files
  delegate_to: localhost
  become: no

- name: Extract local file basenames
  set_fact:
    diff_file_list: "{{ diff_local_files.files | map(attribute='path') | map('basename') | list }}"

- name: Display files to check
  debug:
    msg:
      - "======================================"
      - "{{ diff_label }} - Files Found"
      - "======================================"
      - "Total files: {{ diff_file_list | length }}"
      - "Files: {{ diff_file_list | join(', ') }}"

# Step 2: Show diff using copy module (check mode)
- name: Show file differences
  copy:
    src: "{{ diff_local_path }}{{ item }}"
    dest: "{{ diff_remote_path }}{{ item }}"
  check_mode: yes
  diff: yes
  loop: "{{ diff_file_list }}"
  become: "{{ diff_use_sudo }}"
  register: diff_results
  when: diff_file_list | length > 0

# Step 3: Count changed files
- name: Count changed files
  set_fact:
    diff_changed_count: >-
      {{
        diff_results.results | default([])
        | selectattr('changed', 'equalto', true)
        | list
        | length
      }}
  when: diff_file_list | length > 0

- name: Set no changes count
  set_fact:
    diff_changed_count: 0
  when: diff_file_list | length == 0

- name: Display change summary
  debug:
    msg:
      - "======================================"
      - "{{ diff_label }} - Summary"
      - "======================================"
      - "Total files checked: {{ diff_file_list | length }}"
      - "Changed files: {{ diff_changed_count }}"

# Step 4: No changes message
- name: Display no changes message
  debug:
    msg:
      - "======================================"
      - "{{ diff_label }} - No Changes"
      - "======================================"
      - "All files are up to date"
  when: diff_changed_count | int == 0

# Step 5: Export results for use in playbook
- name: Set diff results fact
  set_fact:
    diff_has_changes: "{{ diff_changed_count | int > 0 }}"
    diff_file_count: "{{ diff_changed_count | default(0) }}"
```

### 사용 예시

```yaml
- name: Check HAProxy configuration differences
  include_role:
    name: file_diff_checker
  vars:
    diff_local_path: "files/haproxy/"
    diff_remote_path: "/etc/haproxy/"
    diff_label: "HAProxy Configuration"
    diff_use_sudo: true
```

## 발전 과정 (Why Copy Module?)

### 시도 1: synchronize + fetch + shell diff

```yaml
# 1. synchronize로 변경 파일 목록 추출
- synchronize:
    rsync_opts: ["--dry-run", "--itemize-changes"]
  register: sync_result

# 2. fetch로 원격 파일 다운로드
- fetch:
    src: "{{ item }}"
    dest: "/tmp/{{ item }}"
  loop: "{{ changed_files }}"

# 3. shell diff 실행
- shell: diff -u "/tmp/{{ item }}" "local/{{ item }}"
  loop: "{{ changed_files }}"
```

❌ **실패 이유:**
- synchronize의 rsync가 ansible SSH 연결을 우회
- vars_prompt 비밀번호를 사용하지 못함
- "Permission denied (publickey,password)" 오류

### 시도 2: find + fetch + shell diff

```yaml
# 1. find로 로컬 파일 목록
- find:
    paths: "local/"
  register: local_files

# 2. fetch로 원격 파일 다운로드
- fetch:
    src: "/etc/{{ item }}"
    dest: "/tmp/{{ item }}"

# 3. shell diff
- shell: diff -u "/tmp/{{ item }}" "local/{{ item }}"
```

✅ **작동함** - 하지만 복잡함

### 시도 3: copy 모듈 (최종)

```yaml
- copy:
    src: "local/{{ item }}"
    dest: "/etc/{{ item }}"
  check_mode: yes
  diff: yes
```

✅ **최선:**
- 코드 45% 감소 (174줄 → 95줄)
- Ansible 네이티브 기능
- 색상 diff 자동
- 안정적

## 색상 Diff 출력

copy 모듈의 diff는 Ansible이 자동으로 색상을 적용합니다:

- `---` / `+++`: 파일 경로
- `@@`: 변경 위치 (청록색)
- `+`: 추가된 라인 (녹색)
- `-`: 삭제된 라인 (빨간색)
- (변경 없음): 흰색/기본색

**ANSI 색상 코드를 직접 추가할 필요 없음!**

## 주의사항

1. **check_mode는 변경하지 않음**
   - 실제 파일 복사 안 함
   - 항상 `changed: true` 반환 (diff가 있으면)

2. **become 권한 필요**
   - `/etc/` 등 시스템 디렉토리 접근 시
   - `become: yes` 설정

3. **여러 파일 처리 시**
   - loop 사용
   - `register` 결과는 `.results` 배열

4. **diff 크기 제한**
   - 기본 104448 bytes
   - `ANSIBLE_MAX_DIFF_SIZE` 환경변수로 조정 가능

## Best Practices

1. **항상 check_mode로 먼저 확인**
2. **diff 결과를 사용자에게 보여주고 확인받기**
3. **여러 서비스는 block으로 분리**
4. **Role로 추출하여 재사용**

## 참고

- [Ansible Copy Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)
- [Ansible Check Mode](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html)
