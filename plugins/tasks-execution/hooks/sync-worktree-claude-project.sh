#!/bin/bash

# Worktree Synchronization Helper
# Syncs .claude-project directory across all git worktrees of the same repository
#
# Usage: sync-worktree-claude-project.sh [source-path]
# If source-path not provided, uses current directory's .claude-project

set -e

# Determine source directory
if [ -n "$1" ]; then
  SOURCE_DIR="$1"
else
  SOURCE_DIR="$(pwd)"
fi

# Check if we're in a git repository
if ! git -C "$SOURCE_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  echo "⚠️  Not a git repository, skipping worktree sync"
  exit 0
fi

# Check if .claude-project exists in source
if [ ! -d "$SOURCE_DIR/.claude-project" ]; then
  echo "⚠️  No .claude-project in source directory, skipping sync"
  exit 0
fi

# Get list of all worktrees for this repository
WORKTREES=$(git -C "$SOURCE_DIR" worktree list --porcelain | grep "^worktree " | sed 's/^worktree //')

if [ -z "$WORKTREES" ]; then
  echo "ℹ️  No worktrees found (single working directory)"
  exit 0
fi

# Count worktrees
WORKTREE_COUNT=$(echo "$WORKTREES" | wc -l)

if [ "$WORKTREE_COUNT" -eq 1 ]; then
  echo "ℹ️  Only one worktree, no sync needed"
  exit 0
fi

# Resolve absolute path of source
SOURCE_ABS=$(cd "$SOURCE_DIR" && pwd)

echo ""
echo "🔄 Syncing .claude-project across $WORKTREE_COUNT worktrees..."
echo ""

# Counter for successful syncs
SYNCED=0
SKIPPED=0
ERRORS=0

# Sync to each worktree
while IFS= read -r worktree; do
  # Skip if it's the source directory itself
  WORKTREE_ABS=$(cd "$worktree" 2>/dev/null && pwd || echo "$worktree")

  if [ "$WORKTREE_ABS" = "$SOURCE_ABS" ]; then
    continue
  fi

  WORKTREE_NAME=$(basename "$worktree")

  # Check if target worktree exists
  if [ ! -d "$worktree" ]; then
    echo "⚠️  Worktree not found: $worktree (skipped)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  TARGET_CLAUDE="$worktree/.claude-project"

  # If target doesn't have .claude-project, simply copy
  if [ ! -d "$TARGET_CLAUDE" ]; then
    echo "📋 $WORKTREE_NAME: Creating .claude-project (full copy)"

    cp -r "$SOURCE_DIR/.claude-project" "$TARGET_CLAUDE"

    if [ $? -eq 0 ]; then
      SYNCED=$((SYNCED + 1))
      echo "   ✅ Copied successfully"
    else
      ERRORS=$((ERRORS + 1))
      echo "   ❌ Copy failed"
    fi

    continue
  fi

  # Target has .claude-project - need to sync changes
  echo "🔄 $WORKTREE_NAME: Syncing changes..."

  # Use rsync for intelligent sync
  # --archive: preserve permissions, timestamps
  # --update: only copy if source is newer
  # --itemize-changes: show what changed
  # --exclude: skip temporary files

  RSYNC_OUTPUT=$(rsync -a --update --itemize-changes \
    --exclude='.DS_Store' \
    --exclude='*.swp' \
    --exclude='*.tmp' \
    --exclude='node_modules/' \
    --exclude='tests/.env.test' \
    "$SOURCE_DIR/.claude-project/" "$TARGET_CLAUDE/" 2>&1)

  if [ $? -eq 0 ]; then
    # Check if anything was actually synced
    if [ -n "$RSYNC_OUTPUT" ]; then
      # Count changed files
      CHANGED_COUNT=$(echo "$RSYNC_OUTPUT" | grep -c '^>' || echo "0")

      if [ "$CHANGED_COUNT" -gt 0 ]; then
        echo "   ✅ Synced $CHANGED_COUNT file(s)"
        SYNCED=$((SYNCED + 1))

        # Show summary of changes (first 5)
        echo "$RSYNC_OUTPUT" | grep '^>' | head -5 | while read -r line; do
          filename=$(echo "$line" | awk '{print $2}')
          echo "      - $filename"
        done

        if [ "$CHANGED_COUNT" -gt 5 ]; then
          echo "      ... and $((CHANGED_COUNT - 5)) more"
        fi
      else
        echo "   ℹ️  Already in sync"
        SKIPPED=$((SKIPPED + 1))
      fi
    else
      echo "   ℹ️  Already in sync"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    echo "   ❌ Sync failed: $RSYNC_OUTPUT"
    ERRORS=$((ERRORS + 1))
  fi

done <<< "$WORKTREES"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Worktree Sync Summary:"
echo "  Total worktrees: $WORKTREE_COUNT"
echo "  Synced: $SYNCED"
echo "  Already in sync: $SKIPPED"
echo "  Errors: $ERRORS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Exit with success even if some syncs failed
# (don't want to block the main command)
exit 0
