---
name: tmux-agent
description: Automates tmux pane/window orchestration for Claude instances. Use when running dev servers in separate panes, monitoring logs across panes, checking process status, sending commands to other panes, or when background tasks need persistent terminal output instead of run_in_background.
---

# tmux-agent

Claude가 tmux를 자율적으로 조작하여 다른 pane을 인식하고, 명령을 전송하며, 프로세스 상태를 파악합니다.

## Quick Reference

| 작업 | 워크플로우 | 핵심 명령어 |
|------|-----------|------------|
| Pane 목록 | WF1: Discover | `tmux list-panes -a -F "..."` |
| 출력 캡처 | WF2: Observe | `tmux capture-pane -t {target} -p` |
| 명령 전송 | WF3: Command | `tmux send-keys "cmd" Enter` |
| 윈도우 생성 | WF4: Create | `tmux new-window -n "name"` |
| 유휴 감지 | WF5: Idle | 프롬프트 패턴 매칭 |

## 핵심 철학

- **비침투적 관찰**: `capture-pane`으로 프로세스 방해 없이 상태 파악
- **간결한 전송**: `send-keys "cmd" Enter` 형식으로 한 번에 전송
- **Escape 처리**: 특수문자 이스케이핑 철저히 (`resources/02-send-keys-safety.md`)
- **Naming convention**: 구조화된 이름으로 pane 역할 명시

## Instructions

### 워크플로우 1: Discover (Pane 인식)

**목적**: 현재 tmux 세션의 모든 pane 파악

**단계**:
1. **전체 pane 목록** (디렉토리 + 프로세스 포함)
   ```bash
   tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} [#{pane_current_command}] #{pane_current_path}"
   ```

2. **현재 세션만**
   ```bash
   tmux list-panes -F "#{window_index}.#{pane_index} [#{pane_current_command}] #{pane_current_path}"
   ```

3. **특정 프로세스 필터링** (예: Claude)
   ```bash
   tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" -f "#{m:*claude*,#{pane_current_command}}"
   ```

4. **타겟 선택**: 다음 워크플로우에 사용할 pane 식별

**트리거 키워드**: "pane 목록", "어떤 pane", "tmux 상태"

---

### 워크플로우 2: Observe (출력 캡처)

**목적**: 특정 pane의 출력 내용 읽기 (프로세스 방해 없이)

**단계**:
1. **기본 캡처** (현재 화면)
   ```bash
   tmux capture-pane -t {target} -p
   ```

2. **히스토리 포함** (최근 N줄)
   ```bash
   tmux capture-pane -t {target} -p -S -100
   ```

3. **ANSI 코드 포함** (디버깅용)
   ```bash
   tmux capture-pane -t {target} -p -e
   ```

4. **출력 분석**: 에러 패턴, 완료 상태, 프롬프트 대기 여부 확인
   - 패턴 참조: `resources/01-capture-patterns.md`

**트리거 키워드**: "pane 출력", "캡처", "로그 확인"

---

### 워크플로우 3: Command (명령 전송)

**목적**: 다른 pane에 명령어 전송 (race condition 안전)

**단계**:
1. **타겟 확인**: pane이 명령 대기 중인지 확인 (WF5 선행 권장)

2. **안전한 전송 패턴**
   ```bash
   tmux send-keys -t {target} "command" Enter
   ```

3. **특수문자 이스케이핑** (필수 확인)
   ```bash
   # 쌍따옴표 내
   tmux send-keys -t 1.0 "echo \"hello\""      # " → \"
   tmux send-keys -t 1.0 "echo \$HOME"         # $ → \$

   # 작은따옴표 (더 안전)
   tmux send-keys -t 1.0 'echo "$HOME"'
   ```
   - 상세 참조: `resources/02-send-keys-safety.md`

4. **특수 키 전송**
   ```bash
   tmux send-keys -t {target} C-c      # Ctrl+C
   tmux send-keys -t {target} C-d      # Ctrl+D
   tmux send-keys -t {target} -l "C-c" # 리터럴 "C-c" 텍스트
   ```

5. **결과 확인** (선택): WF2로 출력 캡처

**트리거 키워드**: "명령 전송", "send", "실행해줘", "pane에"

---

### 워크플로우 4: Create (윈도우/Pane 생성)

**목적**: 새 작업 공간 생성 및 초기화

**단계**:
1. **새 윈도우 생성**
   ```bash
   tmux new-window -n "agent-1"              # 빈 윈도우
   tmux new-window -n "agent-1" "claude"     # Claude 실행
   ```

2. **Pane 분할**
   ```bash
   tmux split-window -h -t 0    # 수평 분할
   tmux split-window -v -t 0    # 수직 분할
   ```

3. **이름 지정**
   ```bash
   tmux rename-window -t {target} "new-name"
   tmux select-pane -t {target} -T "pane-title"
   ```

4. **Naming convention**
   - `agent-{N}`: Claude 인스턴스
   - `monitor-{purpose}`: 모니터링 전용
   - `build-{project}`: 빌드 프로세스
   - 상세 참조: `resources/03-window-management.md`

5. **초기 명령**: WF3으로 초기화 스크립트 전송

**트리거 키워드**: "새 pane", "window 생성", "Claude 실행", "분할"

---

### 워크플로우 5: Idle Detection (유휴 상태 감지)

**목적**: pane이 명령 대기 중인지, 작업 중인지 판단

**단계**:
1. **출력 캡처**
   ```bash
   tmux capture-pane -t {target} -p | tail -5
   ```

2. **프롬프트 패턴 매칭**
   ```bash
   # Shell 프롬프트: $, %, ❯, >, ➜
   echo "$output" | grep -qE '(\$|%|❯|➜|>)\s*$' && echo "IDLE"

   # Claude 프롬프트
   echo "$output" | grep -qE '(You:)\s*$' && echo "IDLE"

   # 에러 패턴
   echo "$output" | grep -qE '(Error:|FAIL|Traceback|panic:)' && echo "FAILED"
   ```

3. **상태 판정**
   - 프롬프트 패턴 매칭 → **IDLE**
   - 에러 패턴 → **FAILED**
   - 그 외 → **ACTIVE**

**트리거 키워드**: "idle", "대기 중", "실행 완료", "상태 확인"

---

## 중요 원칙

1. **타겟 검증**: 명령 전송 전 pane 존재 확인
   ```bash
   tmux list-panes -F "#{pane_id}" | grep -q "{target}"
   ```

2. **간결한 전송**: `send-keys "cmd" Enter` 형식 (sleep 사용 금지)

3. **Escape 처리**: 쌍따옴표 내 `"`, `$`, `` ` `` 반드시 이스케이프

4. **에러 전파**: 하위 pane 에러를 상위 호출자에게 즉시 보고

5. **이름 표준화**: Naming convention 준수로 pane 역할 명확화

## Anti-patterns

| ❌ 위험한 패턴 | ✅ 안전한 패턴 |
|--------------|--------------|
| `send-keys "cmd"` (Enter 누락) | `send-keys "cmd" Enter` |
| `send-keys "echo $VAR"` | `send-keys "echo \$VAR"` 또는 `'echo "$VAR"'` |
| Idle 확인 없이 명령 전송 | WF5로 Idle 확인 후 전송 |
| 하드코딩된 타겟 `0.0` | WF1으로 동적 타겟 탐색 |

## Examples

### 다른 pane에서 테스트 실행
```
User: "pane 1에서 npm test 실행하고 결과 알려줘"
→ WF1: list-panes로 1번 pane 확인
→ WF5: Idle 상태 확인
→ WF3: send-keys "npm test"
→ WF5: 완료 대기 (polling)
→ WF2: 결과 캡처 및 보고
```

### 새 Claude 인스턴스 생성 후 작업 할당
```
User: "새 Claude 띄워서 코드 리뷰 시켜"
→ WF4: new-window -n "agent-review" "claude"
→ WF5: Claude 준비 대기
→ WF6: 프롬프트 전송 + 응답 대기
→ WF2: 결과 캡처
```

### 병렬 작업 오케스트레이션
```
User: "3개 pane에서 각각 다른 테스트 실행"
→ WF1: 사용 가능한 pane 3개 식별
→ WF3 x 3: 각 pane에 테스트 명령 전송 (병렬)
→ WF5: 모든 pane 완료 대기 (polling)
→ WF2 x 3: 결과 수집 및 통합 보고
```

## Technical Details

리소스 파일:
- `resources/01-capture-patterns.md`: 에러/완료/프롬프트 패턴
- `resources/02-send-keys-safety.md`: Escape 처리
- `resources/03-window-management.md`: 레이아웃 및 이름 규칙
