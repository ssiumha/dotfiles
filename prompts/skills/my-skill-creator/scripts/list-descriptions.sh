#!/usr/bin/env bash
# list-descriptions.sh - 모든 skill의 description을 출력하여 모니터링/개선에 활용
# Usage: bash list-descriptions.sh [filter]

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/dots/prompts/skills}"
FILTER="${1:-}"

echo "# Skill Descriptions"
echo "# $(date '+%Y-%m-%d')"
echo ""
echo "| Skill | Description |"
echo "|-------|-------------|"

for skill_dir in "$SKILLS_DIR"/*/; do
    skill_file="$skill_dir/SKILL.md"
    [[ -f "$skill_file" ]] || continue

    name=$(basename "$skill_dir")

    # Filter if provided
    if [[ -n "$FILTER" ]] && [[ "$name" != *"$FILTER"* ]]; then
        continue
    fi

    # Extract description from frontmatter
    description=$(awk '
        /^---$/ { if (in_front) exit; in_front=1; next }
        in_front && /^description:/ {
            sub(/^description:\s*/, "");
            gsub(/\|/, "\\|");
            print;
            exit
        }
    ' "$skill_file")

    [[ -z "$description" ]] && description="(no description)"

    echo "| $name | $description |"
done

echo ""
echo "## 개선 체크리스트"
echo ""
echo "각 description이 다음을 포함하는지 확인:"
echo "- [ ] What: 무엇을 하는지 명확"
echo "- [ ] When: 언제 사용하는지 (Use when...)"
echo "- [ ] 구체적 키워드 포함"
