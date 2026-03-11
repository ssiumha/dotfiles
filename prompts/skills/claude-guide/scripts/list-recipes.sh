#!/bin/bash
# List available hook recipes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECIPES_DIR="$SCRIPT_DIR/../recipes"

echo "| Recipe | Event | Description |"
echo "|--------|-------|-------------|"

for recipe in "$RECIPES_DIR"/*.yaml; do
  [[ ! -f "$recipe" ]] && continue

  name=$(grep '^name:' "$recipe" | head -1 | cut -d: -f2 | xargs)
  event=$(grep '^event:' "$recipe" | head -1 | cut -d: -f2 | xargs)
  desc=$(grep '^description:' "$recipe" | head -1 | cut -d: -f2- | xargs)

  echo "| $name | $event | $desc |"
done
