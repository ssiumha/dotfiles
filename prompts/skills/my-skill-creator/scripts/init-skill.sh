#!/usr/bin/env bash
# init-skill: Initialize a new skill directory with template files
# Usage: init-skill.sh <skill-name>

set -euo pipefail

SKILLS_DIR="$HOME/dots/prompts/skills"
TEMPLATE_DIR="$SKILLS_DIR/skill-creator/templates"

[[ $# -lt 1 ]] && { echo "Usage: init-skill.sh <skill-name>"; exit 1; }

SKILL_NAME="$1"

# Validate skill name (kebab-case)
if [[ ! "$SKILL_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "Error: Skill name must be kebab-case (e.g., my-skill-name)"
    exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

# Check if already exists
if [[ -d "$SKILL_DIR" ]]; then
    echo "Error: Skill '$SKILL_NAME' already exists at $SKILL_DIR"
    exit 1
fi

# Create directories
echo "Creating skill: $SKILL_NAME"
mkdir -p "$SKILL_DIR/resources"

# Copy and customize template
if [[ -f "$TEMPLATE_DIR/SKILL-template.md" ]]; then
    SKILL_TITLE=$(echo "$SKILL_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    sed -e "s/{skill-name}/$SKILL_NAME/g" \
        -e "s/{Skill Name}/$SKILL_TITLE/g" \
        "$TEMPLATE_DIR/SKILL-template.md" > "$SKILL_DIR/SKILL.md"
fi

echo "Created: $SKILL_DIR/"
echo "Next: Edit SKILL.md, then run validate-skill.sh $SKILL_NAME"
