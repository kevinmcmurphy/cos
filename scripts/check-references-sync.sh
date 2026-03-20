#!/bin/bash
# Pre-commit hook: verify reference files are in sync
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"

FAIL=0
for file in "$REPO_ROOT/_references/"*; do
    filename=$(basename "$file")
    for skill_dir in morning-sweep evening-review; do
        target="$REPO_ROOT/skills/$skill_dir/references/$filename"
        if [ ! -f "$target" ]; then
            echo "ERROR: $target is missing (expected copy of _references/$filename)"
            FAIL=1
        elif ! diff -q "$file" "$target" > /dev/null 2>&1; then
            echo "ERROR: $target differs from _references/$filename"
            echo "Run: ./scripts/sync-references.sh"
            FAIL=1
        fi
    done
done

if [ $FAIL -ne 0 ]; then
    echo ""
    echo "Reference files are out of sync. Run ./scripts/sync-references.sh and re-add."
    exit 1
fi
