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

# Block: git -C <path> ...
if echo "$command" | grep -qE '^git\s+-C\s'; then
  echo '{"decision":"block","reason":"git -C 금지. worktree에서 직접 git 명령을 실행하세요."}'
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
