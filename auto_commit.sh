#!/bin/bash
# Auto-commit script for workspace changes
# Usage: ./auto_commit.sh [custom message]

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# Get current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
    echo "[$TIMESTAMP] No changes to commit"
    exit 0
fi

# Determine commit message
if [ -z "$1" ]; then
    # Get list of changed files for auto-generated message
    CHANGED_FILES=$(git status --short | head -5 | sed 's/^...//' | tr '\n' ', ' | sed 's/, $//')
    if [ -z "$CHANGED_FILES" ]; then
        CHANGED_FILES="workspace files"
    fi
    COMMIT_MSG="Update: $CHANGED_FILES [$TIMESTAMP]"
else
    COMMIT_MSG="$1 [$TIMESTAMP]"
fi

# Add all changes and commit
git add -A
git commit -m "$COMMIT_MSG"

echo "[$TIMESTAMP] Committed: $COMMIT_MSG"
