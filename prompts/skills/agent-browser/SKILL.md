---
name: agent-browser
description: Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, or extract information from web pages.
---

# Browser Automation with agent-browser

웹 브라우저를 자동화하여 테스트, 폼 작성, 스크린샷, 데이터 추출 등을 수행합니다.

## Instructions

### 워크플로우: 탐색 → 분석 → 상호작용 → 검증

#### Quick start

```bash
agent-browser open <url>        # Navigate to page
agent-browser snapshot -i       # Get interactive elements with refs
agent-browser click @e1         # Click element by ref
agent-browser fill @e2 "text"   # Fill input by ref
agent-browser close             # Close browser
```

#### Core workflow

1. Navigate: `agent-browser open <url>`
2. Snapshot: `agent-browser snapshot -i` (returns elements with refs like `@e1`, `@e2`)
3. Interact using refs from the snapshot
4. Re-snapshot after navigation or significant DOM changes

## Commands

### Navigation
```bash
agent-browser open <url>      # Navigate to URL
agent-browser back            # Go back
agent-browser forward         # Go forward
agent-browser reload          # Reload page
agent-browser close           # Close browser
```

### Snapshot (page analysis)
```bash
agent-browser snapshot        # Full accessibility tree
agent-browser snapshot -i     # Interactive elements only (recommended)
agent-browser snapshot -c     # Compact output
agent-browser snapshot -d 3   # Limit depth to 3
```

### Interactions (use @refs from snapshot)
```bash
agent-browser click @e1           # Click
agent-browser dblclick @e1        # Double-click
agent-browser fill @e2 "text"     # Clear and type
agent-browser type @e2 "text"     # Type without clearing
agent-browser press Enter         # Press key
agent-browser press Control+a     # Key combination
agent-browser hover @e1           # Hover
agent-browser check @e1           # Check checkbox
agent-browser uncheck @e1         # Uncheck checkbox
agent-browser select @e1 "value"  # Select dropdown
agent-browser scroll down 500     # Scroll page
agent-browser scrollintoview @e1  # Scroll element into view
```

### Get information
```bash
agent-browser get text @e1        # Get element text
agent-browser get value @e1       # Get input value
agent-browser get title           # Get page title
agent-browser get url             # Get current URL
```

### Screenshots
```bash
agent-browser screenshot          # Screenshot to stdout
agent-browser screenshot path.png # Save to file
agent-browser screenshot --full   # Full page
```

### Wait
```bash
agent-browser wait @e1                     # Wait for element
agent-browser wait 2000                    # Wait milliseconds
agent-browser wait --text "Success"        # Wait for text
agent-browser wait --load networkidle      # Wait for network idle
```

### Semantic locators (alternative to refs)
```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
```

## Examples

### Example 1: Form submission

```bash
agent-browser open https://example.com/form
agent-browser snapshot -i
# Output shows: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # Check result
```

### Example 2: Authentication with saved state

```bash
# Login once
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later sessions: load saved state
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

### Example 3: Data extraction

```bash
agent-browser open https://example.com/products
agent-browser snapshot -i
# Find product titles and prices
agent-browser get text @e5  # Product title
agent-browser get text @e6  # Price
agent-browser screenshot products.png
```

## Advanced Features

### Sessions (parallel browsers)

**동시 사용 시 `--session` 필수.** `--session` 없이 실행하면 모든 세션이 `default` daemon을 공유하여 서로 간섭한다.

세션 이름 규칙:
- worktree에서 실행 → worktree 브랜치명 사용
- 메인에서 실행 → 작업 목적으로 명명 (예: `qa-login`, `data-extract`)

```bash
agent-browser --session my-feature open site-a.com   # 세션 A
agent-browser --session my-feature snapshot -i        # 같은 세션에서 조작

agent-browser --session other-task open site-b.com    # 세션 B (독립)
agent-browser session list                            # 활성 세션 목록
```

### JSON output (for parsing)

Add `--json` for machine-readable output:
```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
```

### Debugging

```bash
agent-browser open example.com --headed  # Show browser window
agent-browser console                    # View console messages
agent-browser errors                     # View page errors
```

## Best Practices

1. **동시 사용 시 `--session` 지정**: `--session` 없으면 `default` 세션을 공유하여 간섭 발생. 항상 고유한 세션명 사용
2. **Always snapshot before interacting**: Get fresh refs after navigation or DOM changes
3. **Use interactive snapshot (`-i`)**: Reduces noise, focuses on actionable elements
4. **Wait appropriately**: Use `wait --load networkidle` after actions that trigger navigation
5. **Save auth state**: Reuse login sessions with `state save/load`
6. **Take screenshots for verification**: Visual confirmation of expected state
7. **Use semantic locators for stable tests**: `find role/text/label` is more resilient than refs
8. **작업 완료 후 `close`**: 유휴 daemon은 15분 후 자동 종료되지만, 리소스 절약을 위해 명시적 close 권장

## Technical Details

- Based on Playwright browser automation
- Supports Chromium, Firefox, and WebKit
- Uses accessibility tree for element detection
- Provides stable references (@e1, @e2) for elements
- Handles common web testing scenarios out-of-the-box
