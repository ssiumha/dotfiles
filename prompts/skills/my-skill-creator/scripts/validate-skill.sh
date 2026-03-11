#!/usr/bin/env bash
# validate-skill: Validate skill structure and content
# Usage: validate-skill.sh <skill-name>

set -euo pipefail

SKILLS_DIR="$HOME/dots/prompts/skills"

[[ $# -lt 1 ]] && { echo "Usage: validate-skill.sh <skill-name>"; exit 1; }

SKILL_NAME="$1"
SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
SKILL_MD="$SKILL_DIR/SKILL.md"
ERRORS=0

error() { echo "❌ $1"; ((ERRORS++)); }
warn() { echo "⚠️  $1"; }
ok() { echo "✅ $1"; }

echo "Validating skill: $SKILL_NAME"
echo "---"

# 1. Check SKILL.md exists
[[ -f "$SKILL_MD" ]] && ok "SKILL.md exists" || error "SKILL.md not found"

if [[ -f "$SKILL_MD" ]]; then
    # 2. Check frontmatter
    head -5 "$SKILL_MD" | grep -q "^name:" && ok "Frontmatter: name" || error "Missing: name in frontmatter"
    head -5 "$SKILL_MD" | grep -q "^description:" && ok "Frontmatter: description" || error "Missing: description in frontmatter"

    # 3. Check line count
    LINES=$(wc -l < "$SKILL_MD" | tr -d ' ')
    if [[ $LINES -lt 50 ]]; then
        warn "Line count: $LINES (too short, <50)"
    elif [[ $LINES -gt 600 ]]; then
        error "Line count: $LINES (too long, >600)"
    else
        ok "Line count: $LINES"
    fi

    # 4. Check required sections
    grep -q "^## Instructions" "$SKILL_MD" && ok "Section: Instructions" || error "Missing: ## Instructions"
    grep -q "^## Examples" "$SKILL_MD" && ok "Section: Examples" || warn "Missing: ## Examples"

    # 5. Check for placeholders (should be filled)
    if grep -q "{skill-name}\|{TODO}\|{언제 사용" "$SKILL_MD"; then
        warn "Unfilled placeholders found"
    fi

    # 6. Check description quality (What + When pattern)
    DESC=$(grep "^description:" "$SKILL_MD" | head -1)
    if echo "$DESC" | grep -q "Use when\|할 때\|시 사용\|proactively"; then
        ok "Description: context-based (What + When)"
    else
        warn "Description: add 'Use when' or usage context"
    fi
fi

echo "---"
if [[ $ERRORS -eq 0 ]]; then
    echo "✅ Validation passed"
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi
