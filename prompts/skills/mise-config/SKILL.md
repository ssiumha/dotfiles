---
disable-model-invocation: true
name: mise-config
description: Generates mise.toml project configuration. Use when setting up project tools, environment variables, or task automation with mise.
---

# Mise Configuration Generator

Generates mise.toml configuration files for project-level tool management, environment variables, and task automation.

## When to Use This Skill

- Setting up mise for a new project
- Adding tools (Node, Python, Ruby, etc.) to mise.toml
- Configuring environment variables
- Creating tasks/scripts for build automation
- Configuring mise settings (auto_install, python_venv, etc.)

## File Naming Conventions

mise supports multiple configuration file locations with the following priority order:

1. `mise.local.toml` - Local overrides (gitignored)
2. `mise.toml` - Project configuration (committed)
3. `mise/<env>.toml` - Environment-specific (e.g., mise/production.toml)
4. `mise/config.toml` - Alternative location
5. `.mise/config.toml` - Hidden directory variant

**Recommendation**: Use `mise.toml` for project defaults, `mise.local.toml` for local overrides.

## Keyword-Based Resource Loading

When users mention specific keywords, load the corresponding resource file:

| Keywords | Resource | Section |
|----------|----------|---------|
| tools, version | resources/01-tools.md | [tools] |
| env, environment | resources/02-env.md | [env] |
| tasks, script, task | resources/03-tasks.md | [tasks.*] |
| settings, config | resources/04-settings.md | [settings] |

**Multiple keywords**: Load all matching resources.

## Basic Template

Minimal `mise.toml` for a new project:

```toml
[tools]
node = "20"

[env]
NODE_ENV = "development"

[tasks.dev]
run = "npm run dev"

[tasks.build]
description = "Build the project"
run = "npm run build"
```

## Quick Start

### Node.js 프로젝트
1. `mise.toml` 생성:
   ```toml
   [tools]
   node = "20"
   ```
2. 설치: `mise install`
3. 확인: `node --version`

### Build 자동화
1. `mise.toml`에 추가:
   ```toml
   [tasks.build]
   run = "npm run build"
   ```
2. 실행: `mise run build`

### 환경별 설정
1. `mise.toml` (개발 기본값)
2. `mise.production.toml` (프로덕션 오버라이드)
3. 활성화: `MISE_ENV=production mise install`

## Common Use Cases

### 1. JavaScript/TypeScript Project

```toml
[tools]
node = "20"
pnpm = "latest"

[env]
NODE_ENV = "development"

[tasks.dev]
description = "Start dev server"
run = "pnpm dev"

[tasks.build]
description = "Build for production"
run = "pnpm build"
depends = ["lint", "test"]

[tasks.lint]
run = "pnpm lint"

[tasks.test]
run = "pnpm test"
```

### 2. Python Project

```toml
[tools]
python = "3.11"

[env]
_.python.venv = { path = ".venv", create = true }

[settings]
python_venv_auto_create = true

[tasks.install]
description = "Install dependencies"
run = "pip install -r requirements.txt"

[tasks.test]
run = "pytest"
```

### 3. Multi-Language Project

```toml
[tools]
node = "20"
python = "3.11"
go = "1.21"

[tasks.build]
description = "Build all components"
depends = ["build-frontend", "build-backend"]

[tasks.build-frontend]
run = "npm run build"
dir = "frontend"

[tasks.build-backend]
run = "go build -o bin/server ./cmd/server"
dir = "backend"
```

## Configuration Workflow

1. **Identify requirements**: What tools, environment variables, and tasks are needed?
2. **Load relevant resources**: Based on keywords mentioned
3. **Generate configuration**: Combine sections into mise.toml
4. **Add file-based tasks** (optional): For complex scripts, use separate task files

## Task Files vs TOML Tasks

**TOML tasks** (recommended for simple commands):
- Good for: single commands, command lists, simple dependencies
- Inline in mise.toml

**File-based tasks** (for complex scripts):
- Good for: multi-line scripts, Ruby/Python logic, reusable functions
- Stored in `.mise/tasks/` or `mise/tasks/`
- Example: `.mise/tasks/deploy` (executable file with `#MISE` metadata)

## User's Existing Setup

The user has a global mise configuration at `~/dots/config/mise/config.toml` with:
- Many CLI tools (fzf, ripgrep, bat, jq, etc.)
- Ruby setup tasks
- DevOps tools setup tasks
- Custom task files in Ruby (common.rb provides shared helpers)

When generating project configurations, assume the user already has common tools globally and focus on project-specific needs.

## Output Format

Always provide:
1. **File path**: Where to save the configuration (e.g., `mise.toml`)
2. **Complete configuration**: Ready to copy-paste
3. **Next steps**: How to activate the configuration

Example output:

```
Save as `mise.toml`:

[Generated configuration here]

To activate:
  mise install        # Install tools
  mise trust          # Trust the config (first time)
  mise run build      # Run tasks
```

## Advanced Features

### Incremental Builds

Tasks can detect changes and skip unnecessary work:

```toml
[tasks.build]
run = "npm run build"
sources = ["src/**/*.ts", "package.json"]
outputs = ["dist/**/*.js"]
```

### Template Variables

Environment variables support templates:

```toml
[env]
PROJECT_ROOT = "{{config_root}}"
HOME_DIR = "{{env.HOME}}"
```

### Task Arguments

Tasks can accept runtime arguments:

```toml
[tasks.deploy]
run = "kubectl apply -f manifests/$1"
# Usage: mise run deploy production
```

## Error Handling

Common issues:
- **"tool not found"**: Tool not in mise registry → use `ubi:`, `npm:`, `cargo:` prefix
- **"task failed"**: Check `depends` order, ensure prerequisite tasks succeed
- **"permission denied"**: File-based tasks need executable bit (`chmod +x`)

## Related Commands

- `mise use <tool>[@version]` - Add tool to mise.toml
- `mise set <key>=<value>` - Add environment variable
- `mise tasks` - List available tasks
- `mise run <task>` - Execute a task
- `mise watch -t <task>` - Watch for changes and re-run task
