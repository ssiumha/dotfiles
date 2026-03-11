#!/bin/bash

###############################################################################
# list-installed.sh
#
# Lists installed skills with their source repository and installation date.
# Reads from .claude/skills/.registry.json if it exists.
#
# Usage:
#   ./list-installed.sh [--json] [--quiet]
#
# Options:
#   --json    Output as JSON format (default: formatted table)
#   --quiet   Output only skill names (one per line)
#
# Exit codes:
#   0 - Success
#   1 - Not in a git repository
#   2 - jq not available and --json flag used
#   3 - Registry file doesn't exist or is invalid
#
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
OUTPUT_FORMAT="table"
QUIET_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --json)
      OUTPUT_FORMAT="json"
      shift
      ;;
    --quiet)
      QUIET_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

###############################################################################
# Find project root using git
###############################################################################
if ! PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo -e "${RED}Error: Not in a git repository${NC}" >&2
  exit 1
fi

###############################################################################
# Define registry path
###############################################################################
REGISTRY_FILE="${PROJECT_ROOT}/.claude/skills/.registry.json"

###############################################################################
# Check if registry file exists
###############################################################################
if [[ ! -f "$REGISTRY_FILE" ]]; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "{}"
  elif [[ "$QUIET_MODE" == true ]]; then
    # No output for quiet mode when empty
    :
  else
    echo -e "${YELLOW}No skills installed yet.${NC}"
    echo "Registry file not found: $REGISTRY_FILE"
  fi
  exit 0
fi

###############################################################################
# Helper function: Parse JSON with jq or fallback
###############################################################################
parse_json() {
  local json_filter="$1"
  local json_file="$2"

  # Try using jq if available
  if command -v jq &>/dev/null; then
    jq "$json_filter" "$json_file" 2>/dev/null
    return $?
  fi

  # Fallback: Return empty if jq not available and format is json
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "Error: jq is not installed. Cannot parse JSON output." >&2
    exit 2
  fi

  # For non-JSON output, we can attempt basic parsing
  return 1
}

###############################################################################
# Read and parse registry file
###############################################################################
if ! REGISTRY_JSON=$(cat "$REGISTRY_FILE" 2>/dev/null); then
  echo -e "${RED}Error: Cannot read registry file${NC}" >&2
  exit 3
fi

# Validate JSON structure
if ! echo "$REGISTRY_JSON" | grep -q "^{"; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "{}"
  else
    echo -e "${YELLOW}No skills installed yet.${NC}"
  fi
  exit 0
fi

###############################################################################
# Output: JSON format
###############################################################################
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  if command -v jq &>/dev/null; then
    jq '.' "$REGISTRY_FILE"
  else
    echo "Error: jq is not installed. Cannot parse JSON." >&2
    exit 2
  fi
  exit 0
fi

###############################################################################
# Output: Quiet mode (skill names only)
###############################################################################
if [[ "$QUIET_MODE" == true ]]; then
  if command -v jq &>/dev/null; then
    jq -r 'keys[]' "$REGISTRY_FILE" 2>/dev/null || true
  else
    # Fallback regex parsing for skill names
    grep -oP '^\s*"\K[^"]+(?="\s*:)' "$REGISTRY_FILE" 2>/dev/null || true
  fi
  exit 0
fi

###############################################################################
# Output: Formatted table
###############################################################################
if ! command -v jq &>/dev/null; then
  # Fallback output without jq
  echo -e "${YELLOW}Warning: jq not found. Using basic output format.${NC}"
  echo "Registry file: $REGISTRY_FILE"
  echo "---"

  # Try to extract skill names and source with grep
  if grep -q '"source"' "$REGISTRY_FILE"; then
    echo "Installed skills found. Please install 'jq' for formatted output:"
    echo "  brew install jq  (macOS)"
    echo "  apt-get install jq  (Linux)"
  else
    echo -e "${YELLOW}No skills installed.${NC}"
  fi
  exit 0
fi

# Use jq for formatted output
SKILLS_COUNT=$(jq 'length' "$REGISTRY_FILE")

if [[ "$SKILLS_COUNT" -eq 0 ]]; then
  echo -e "${YELLOW}No skills installed yet.${NC}"
  exit 0
fi

echo -e "${BLUE}Installed Skills (${GREEN}${SKILLS_COUNT}${BLUE}):${NC}"
echo "---"

# Create formatted table header
printf "%-35s %-40s %-20s\n" "Skill Name" "Source Repository" "Installation Date"
printf "%-35s %-40s %-20s\n" "---" "---" "---"

# Parse and display each skill
jq -r 'to_entries[] | "\(.key) | \(.value.source // "unknown") | \(.value.installedAt // "unknown")"' "$REGISTRY_FILE" | \
  while IFS='|' read -r skill_name source installed_at; do
    # Trim whitespace
    skill_name=$(echo "$skill_name" | xargs)
    source=$(echo "$source" | xargs)
    installed_at=$(echo "$installed_at" | xargs)

    # Format date if it's in ISO format (remove 'Z' and microseconds)
    if [[ "$installed_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
      installed_at=${installed_at%Z*}  # Remove 'Z' suffix
      installed_at=${installed_at%.*}  # Remove microseconds
    fi

    # Truncate long values for display
    if [[ ${#skill_name} -gt 33 ]]; then
      skill_name="${skill_name:0:30}..."
    fi
    if [[ ${#source} -gt 38 ]]; then
      source="${source:0:35}..."
    fi

    printf "%-35s %-40s %-20s\n" "$skill_name" "$source" "$installed_at"
  done

echo "---"
echo -e "${BLUE}Total: ${GREEN}${SKILLS_COUNT}${NC}"
echo ""
echo -e "${YELLOW}Tip:${NC} Use 'cat ${REGISTRY_FILE} | jq' for full details"
