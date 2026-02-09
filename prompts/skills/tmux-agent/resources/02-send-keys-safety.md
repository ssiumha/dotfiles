# send-keys 안전 가이드

## 전송 패턴

tmux send-keys는 터미널에 키 입력을 시뮬레이션합니다.

### 기본 패턴

```bash
# 명령 전송 (Enter 포함)
tmux send-keys -t 1.0 "npm install --save-dev typescript" Enter

# 변수 사용
TARGET="1.0"
CMD="npm install --save-dev typescript"
tmux send-keys -t "$TARGET" "$CMD" Enter
```

---

## 특수문자 Escape 규칙

### 쌍따옴표 (`"`) 내에서

| 문자 | Escape | 예시 |
|------|--------|------|
| `"` | `\"` | `"echo \"hello\""` |
| `$` | `\$` | `"echo \$HOME"` |
| `` ` `` | `` \` `` | `"echo \`date\`"` |
| `\` | `\\` | `"echo \\n"` |
| `!` | `\!` | `"echo \!important"` (bash) |

```bash
# 예시: 변수와 따옴표 포함
tmux send-keys -t 1.0 "echo \"Value: \$HOME\""
# 실행 결과: echo "Value: $HOME"
```

### 작은따옴표 (`'`) 사용 (권장)

작은따옴표 내에서는 변수 확장이 일어나지 않아 더 안전합니다.

```bash
# 작은따옴표로 감싸기 (shell에서 해석 방지)
tmux send-keys -t 1.0 'echo "$HOME"'
# 실행 결과: echo "$HOME" (변수 그대로 전달)

# 단, 작은따옴표 자체는 포함 불가
tmux send-keys -t 1.0 'echo '"'"'hello'"'"''
# 또는
tmux send-keys -t 1.0 "echo 'hello'"
```

### tmux 특수 키

| 키 | send-keys 표현 |
|----|---------------|
| Enter | `Enter` 또는 `C-m` |
| Tab | `Tab` 또는 `C-i` |
| Escape | `Escape` |
| Ctrl+C | `C-c` |
| Ctrl+D | `C-d` |
| Ctrl+Z | `C-z` |
| 위 화살표 | `Up` |
| 아래 화살표 | `Down` |

```bash
# Ctrl+C로 프로세스 중단
tmux send-keys -t 1.0 C-c

# 리터럴 텍스트 "C-c" 전송 (특수키 해석 방지)
tmux send-keys -t 1.0 -l "C-c"
```

---

## 복잡한 명령 전송

### 세미콜론 (`;`)

tmux에서 세미콜론은 명령 구분자입니다. 리터럴로 전송하려면 이스케이프 필요.

```bash
# 위험: tmux가 세미콜론을 명령 구분자로 해석
tmux send-keys -t 1.0 "cmd1; cmd2"

# 안전: 이스케이프
tmux send-keys -t 1.0 "cmd1 \; cmd2"
# 또는 작은따옴표
tmux send-keys -t 1.0 'cmd1; cmd2'
```

### 파이프 (`|`)

파이프는 대부분 그대로 전송됩니다.

```bash
tmux send-keys -t 1.0 "cat file.txt | grep pattern"
# 정상 작동
```

### Heredoc (다중 라인)

```bash
# 방법 1: 임시 파일 사용 (권장)
cat > /tmp/script.sh << 'EOF'
#!/bin/bash
echo "hello"
EOF
tmux send-keys -t 1.0 "bash /tmp/script.sh" Enter
```

---

## 안전 체크리스트

전송 전 확인:

- [ ] 타겟 pane 존재 확인 (`tmux list-panes`)
- [ ] 타겟 pane이 Idle 상태인지 확인
- [ ] 특수문자 이스케이프 완료
- [ ] Enter 포함 확인

전송 후 확인:

- [ ] 명령이 정상 실행되었는지 `capture-pane`으로 확인
- [ ] 에러 발생 시 즉시 보고

---

## 트러블슈팅

### "command not found" 에러

원인: 명령이 잘려서 전송됨
해결: 긴 명령은 임시 파일로 전송

### 특수문자가 해석됨

원인: escape 누락
해결: 작은따옴표 사용 또는 `\` 추가

### 명령이 두 번 실행됨

원인: Enter가 두 번 전송됨
해결: send-keys에 Enter를 한 번만 포함

### pane이 응답하지 않음

원인: 이전 프로세스가 아직 실행 중
해결: WF5로 Idle 상태 확인 후 전송
