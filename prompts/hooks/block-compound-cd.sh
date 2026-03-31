#!/bin/bash
# PreToolUse hook: block "cd path && ..." compound commands in Bash
# Forces agents to run commands from their current working directory

# Read stdin (JSON with tool_name, tool_input)
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Block: cd to worktree path (agent is already in the worktree)
if echo "$command" | grep -qE '^cd\s+.*\.claude/worktrees'; then
  echo '{"decision":"block","reason":"worktree 경로로 cd 금지. 이미 worktree 안에 있습니다. cd 없이 명령만 실행하세요."}'
  exit 0
fi

# Block: git -C <path> ... (worktree 경로만 차단, 다른 프로젝트 접근은 허용)
if echo "$command" | grep -qE '^git\s+-C\s+.*\.claude/worktrees'; then
  echo '{"decision":"block","reason":"git -C로 worktree 접근 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: GIT_DIR= 환경변수로 다른 저장소 접근
if echo "$command" | grep -qE 'GIT_DIR='; then
  echo '{"decision":"block","reason":"GIT_DIR= 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: --git-dir 옵션으로 다른 저장소 접근
if echo "$command" | grep -qE 'git\s+.*--git-dir'; then
  echo '{"decision":"block","reason":"--git-dir 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: --work-tree 옵션으로 다른 작업 디렉토리 지정
if echo "$command" | grep -qE 'git\s+.*--work-tree'; then
  echo '{"decision":"block","reason":"--work-tree 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: git commit --amend — 사용자에게 직접 실행 요청
if echo "$command" | grep -qE 'git\s+commit\s+.*--amend'; then
  echo '{"decision":"block","reason":"git commit --amend는 직접 실행할 수 없습니다. 정말 필요한 경우, 사용자에게 ! git commit --amend 실행을 요청하세요."}'
  exit 0
fi

# Block: git checkout -b (branch creation should go through worktree)
if echo "$command" | grep -qE 'git\s+checkout\s+-b'; then
  echo '{"decision":"block","reason":"git checkout -b 금지. branch 생성은 worktree를 통해서만 가능합니다."}'
  exit 0
fi

exit 0
