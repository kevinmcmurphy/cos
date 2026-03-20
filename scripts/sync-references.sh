#!/bin/bash
# Sync canonical references to both skill directories
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Syncing references from _references/ to skill directories..."
cp "$REPO_ROOT/_references/"* "$REPO_ROOT/skills/morning-sweep/references/"
cp "$REPO_ROOT/_references/"* "$REPO_ROOT/skills/evening-review/references/"
echo "Done."
