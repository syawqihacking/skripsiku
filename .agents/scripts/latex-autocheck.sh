#!/usr/bin/env bash
# ==============================================================================
# Antigravity Lifecycle Hook: Auto-compile LaTeX on file edits
# Runs after replace_file_content, write_to_file, or multi_replace_file_content
# ==============================================================================

set -o pipefail

# Read stdin JSON payload from Antigravity Hook runner
INPUT=$(cat)

# Extract TargetFile from payload
TARGET_FILE=$(python3 -c '
import sys, json
try:
    data = json.loads(sys.argv[1])
    args = data.get("toolCall", {}).get("args", {})
    print(args.get("TargetFile", ""))
except Exception:
    print("")
' "$INPUT" 2>/dev/null)

# Locate workspace root (parent of .agents)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# If target file is LaTeX or BibTeX, run quick compile
if [[ "$TARGET_FILE" =~ \.(tex|bib)$ ]]; then
    if [[ "$TARGET_FILE" =~ proposal-sentimen-madura ]]; then
        if [ -x "$WORKSPACE_ROOT/proposal-sentimen-madura/compile.sh" ]; then
            cd "$WORKSPACE_ROOT/proposal-sentimen-madura"
            ./compile.sh quick > /dev/null 2>&1 || true
        fi
    elif [ -x "$WORKSPACE_ROOT/compile.sh" ]; then
        cd "$WORKSPACE_ROOT"
        ./compile.sh quick > /dev/null 2>&1 || true
    fi
fi

# Always return valid empty JSON object as required by PostToolUse contract
echo "{}"
