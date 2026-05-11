---
disable-model-invocation: true
name: task-naming
description: >-
  CLI command naming convention for Justfile and Makefile. Enforces GAT
  (group-action-target) word order, grouped listing, mandatory descriptions.
  Use when creating Justfile recipes, Makefile targets, or reviewing task
  runner configs for naming consistency. Also use when asking "what should
  I name this command?" for task runners.
  Do NOT use for npm scripts, mise tasks, or Claude Code skill naming.
argument-hint: "[audit|create] [file-path]"
user-invocable: true
---

상세 절차는 INSTRUCTIONS.md를 참조하세요.
