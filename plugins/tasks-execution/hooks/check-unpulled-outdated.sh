#!/bin/bash

# SessionStart hook: Check for unpulled changes and outdated task branches
# This hook alerts Claude when:
# 1. Documented branches have unpulled commits from remote (need to pull + /init)
# 2. Open tasks have parent branches that moved ahead (need to rebase/merge)

# Exit codes:
# 0 - Success (output will be added as context)
# Non-zero - Hook failed (output ignored)

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  # Not a git repo, nothing to check
  exit 0
fi

# Fetch latest from remote (silently)
git fetch --quiet 2>/dev/null || true

# Storage for issues found
unpulledBranches=()
outdatedTasks=()

# Current branch
currentBranch=$(git branch --show-current 2>/dev/null || echo "")

# ====================
# CHECK 1: Unpulled changes in documented branches
# ====================

if [ -d ".claude-project/project" ]; then
  # Find all documented branches
  documentedBranches=$(find .claude-project/project -maxdepth 1 -type d -not -path ".claude-project/project" 2>/dev/null | xargs -n 1 basename 2>/dev/null)

  for branch in $documentedBranches; do
    # Check if branch exists in git
    if ! git rev-parse --verify "$branch" > /dev/null 2>&1; then
      continue
    fi

    # Check if branch has a remote tracking branch
    if ! git rev-parse --verify "$branch@{upstream}" > /dev/null 2>&1; then
      continue
    fi

    # Check for UNPULLED commits (remote ahead of local)
    unpulledCount=$(git rev-list --count "$branch..$branch@{upstream}" 2>/dev/null || echo "0")

    if [ "$unpulledCount" -gt 0 ]; then
      # This branch has unpulled commits
      unpulledBranches+=("$branch:$unpulledCount")
    fi
  done
fi

# ====================
# CHECK 2: Outdated task branches (parent moved ahead)
# ====================

if [ -d ".claude-project/tasks" ]; then
  # Find all tasks
  taskDirs=$(find .claude-project/tasks -maxdepth 1 -type d -not -path ".claude-project/tasks" -not -path "*/.archive" 2>/dev/null)

  for taskDir in $taskDirs; do
    taskName=$(basename "$taskDir")
    taskMdPath="$taskDir/TASK.md"
    summaryPath="$taskDir/SUMMARY.md"

    # Check if TASK.md exists
    if [ ! -f "$taskMdPath" ]; then
      continue
    fi

    # Check if task is completed (skip completed tasks)
    if [ -f "$summaryPath" ]; then
      if grep -q "Status.*Complete" "$summaryPath" 2>/dev/null; then
        # Task completed, skip
        continue
      fi
    fi

    # Extract parent branch and merge base from TASK.md
    parentBranch=$(grep '^\*\*Parent Branch\*\*:' "$taskMdPath" 2>/dev/null | sed 's/.*`\(.*\)`.*/\1/')
    mergeBase=$(grep '^\*\*Merge Base\*\*:' "$taskMdPath" 2>/dev/null | sed 's/.*`\(.*\)`.*/\1/' | awk '{print $1}')

    if [ -z "$parentBranch" ] || [ -z "$mergeBase" ]; then
      # No git metadata, skip
      continue
    fi

    if [ "$parentBranch" = "not-a-git-repo" ] || [ "$mergeBase" = "not-applicable" ]; then
      # Not applicable, skip
      continue
    fi

    # Check if parent branch exists
    if ! git rev-parse --verify "$parentBranch" > /dev/null 2>&1; then
      continue
    fi

    # Get current parent HEAD
    parentHead=$(git rev-parse "$parentBranch" 2>/dev/null)

    # Check if merge base is a valid commit
    if ! git rev-parse --verify "$mergeBase" > /dev/null 2>&1; then
      continue
    fi

    mergeBaseCommit=$(git rev-parse "$mergeBase" 2>/dev/null)

    # Check if parent has moved ahead
    if [ "$parentHead" != "$mergeBaseCommit" ]; then
      # Parent branch has new commits
      commitsAhead=$(git rev-list --count "$mergeBase..$parentBranch" 2>/dev/null || echo "0")

      if [ "$commitsAhead" -gt 0 ]; then
        outdatedTasks+=("$taskName:$parentBranch:$commitsAhead")
      fi
    fi
  done
fi

# ====================
# Generate Output
# ====================

# If nothing found, exit
if [ ${#unpulledBranches[@]} -eq 0 ] && [ ${#outdatedTasks[@]} -eq 0 ]; then
  exit 0
fi

# Build context message
contextMessage=""

# Add explicit trigger for Claude to display this immediately
contextMessage+="🚨 DISPLAY THIS TO USER IMMEDIATELY AT SESSION START 🚨\n"
contextMessage+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

# Section 1: Unpulled branches
if [ ${#unpulledBranches[@]} -gt 0 ]; then
  contextMessage+="⚠️  UNPULLED CHANGES IN DOCUMENTED BRANCHES\n\n"
  contextMessage+="The following branches have documentation but are BEHIND remote:\n\n"

  for item in "${unpulledBranches[@]}"; do
    branchName="${item%:*}"
    commitCount="${item#*:}"

    if [ "$branchName" = "$currentBranch" ]; then
      contextMessage+="  • $branchName (CURRENT) - $commitCount commit(s) behind remote\n"
    else
      contextMessage+="  • $branchName - $commitCount commit(s) behind remote\n"
    fi
  done

  contextMessage+="\nRisk: Local documentation is outdated. Remote has newer commits.\n"
  contextMessage+="\nRecommended actions:\n"
  contextMessage+="1. Pull latest: git pull origin <branch-name>\n"
  contextMessage+="2. Run /init in each branch to sync documentation with updated code\n\n"
fi

# Section 2: Outdated task branches
if [ ${#outdatedTasks[@]} -gt 0 ]; then
  if [ -n "$contextMessage" ]; then
    contextMessage+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
  fi

  contextMessage+="⚠️  OUTDATED TASK BRANCHES DETECTED\n\n"
  contextMessage+="The following tasks have parent branches that moved ahead:\n\n"

  for item in "${outdatedTasks[@]}"; do
    IFS=':' read -r taskName parentBranch commitsAhead <<< "$item"
    contextMessage+="  • Task: $taskName\n"
    contextMessage+="    Parent: $parentBranch (moved $commitsAhead commits ahead)\n"
    contextMessage+="    Risk: Task may be out of sync with parent\n\n"
  done

  contextMessage+="Recommended actions:\n"
  contextMessage+="1. For each task: /do <task-name>\n"
  contextMessage+="   → Will detect divergence and offer rebase/merge\n"
  contextMessage+="2. Or manually: git checkout <task-branch> && git rebase <parent>\n\n"
fi

contextMessage+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
contextMessage+="To suppress this check, disable hook in ~/.claude/settings.json"

# Output JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$contextMessage"
  }
}
EOF

exit 0
