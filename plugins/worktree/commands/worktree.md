---
description: Create and configure git worktree with environment setup
---

# Git Worktree Management (/worktree)

Create git worktrees with automatic environment configuration and .claude-project sync.

## Command Syntax

```bash
/worktree <branch>                 # Create worktree for branch (existing or new from current)
/worktree <branch1> <branch2>      # Create branch2 from branch1, then worktree for branch2
```

## CRITICAL: Parse Arguments and Determine Mode

### Mode 1: Single Branch Argument

```bash
/worktree feature-auth
```

**Logic:**
```javascript
branchName = argument1;

// Check if branch exists
branchExists = $(git rev-parse --verify ${branchName} >/dev/null 2>&1 && echo "yes" || echo "no")

if (branchExists === "yes") {
  mode = "create-worktree-for-existing";
  targetBranch = branchName;
} else {
  mode = "create-new-branch-and-worktree";
  targetBranch = branchName;
  sourceBranch = currentBranch;
}
```

### Mode 2: Two Branch Arguments

```bash
/worktree main feature-auth
```

**Logic:**
```javascript
sourceBranch = argument1;
targetBranch = argument2;

// Check if source branch exists
sourceExists = $(git rev-parse --verify ${sourceBranch} >/dev/null 2>&1 && echo "yes" || echo "no")

if (sourceExists === "no") {
  // ERROR
  echo "❌ ERROR: Source branch '${sourceBranch}' does not exist"
  echo ""
  echo "Available branches:"
  git branch -a | head -10
  echo ""
  echo "Usage: /worktree <existing-branch> <new-branch>"
  exit 1
}

// Check if target already exists
targetExists = $(git rev-parse --verify ${targetBranch} >/dev/null 2>&1 && echo "yes" || echo "no")

if (targetExists === "yes") {
  echo "⚠️  WARNING: Branch '${targetBranch}' already exists"

  AskUserQuestion:
    Question: "Branch ${targetBranch} exists. How to proceed?"
    Options:
      - "Create worktree for existing ${targetBranch}" → mode = create-worktree
      - "Delete and recreate ${targetBranch} from ${sourceBranch}" → delete + create
      - "Cancel" → exit

} else {
  mode = "create-branch-and-worktree";
}
```

---

## STEP 1: Determine Worktree Path

**Convention**: Worktree в sibling directory с suffix

```bash
# Get current directory info
currentDir = $(pwd)
currentDirName = $(basename "$currentDir")
parentDir = $(dirname "$currentDir")

# Determine worktree path
worktreePath = "${parentDir}/${currentDirName}-${targetBranch}"

echo ""
echo "📁 Worktree Configuration:"
echo "   Current directory: ${currentDir}"
echo "   Target branch: ${targetBranch}"
echo "   Worktree path: ${worktreePath}"
echo ""

# Check if path already exists
if [ -d "$worktreePath" ]; then
  echo "⚠️  WARNING: Directory already exists: ${worktreePath}"

  AskUserQuestion:
    Question: "Worktree directory exists. What to do?"
    Options:
      - "Use different path" → Prompt for custom path
      - "Remove and recreate" → rm -rf, then create
      - "Cancel" → exit

  if (choice == "custom-path") {
    worktreePath = getUserInput("Enter worktree path:");
  } else if (choice == "remove") {
    rm -rf "${worktreePath}"
  } else {
    exit 0
  }
fi
```

---

## STEP 2: Create Branch (if needed)

**If mode requires creating new branch:**

```bash
if [ "$mode" = "create-new-branch-and-worktree" ] || [ "$mode" = "create-branch-and-worktree" ]; then
  echo "🌿 Creating new branch: ${targetBranch} from ${sourceBranch}"

  git checkout "${sourceBranch}"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to checkout ${sourceBranch}"
    exit 1
  fi

  git checkout -b "${targetBranch}"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to create branch ${targetBranch}"
    exit 1
  fi

  echo "✅ Branch ${targetBranch} created from ${sourceBranch}"

  # Switch back to original branch
  git checkout "${currentBranch}"
fi
```

---

## STEP 3: Create Git Worktree

```bash
echo ""
echo "📦 Creating git worktree..."
echo "   Branch: ${targetBranch}"
echo "   Path: ${worktreePath}"
echo ""

git worktree add "${worktreePath}" "${targetBranch}"

if [ $? -ne 0 ]; then
  echo "❌ Failed to create worktree"
  exit 1
fi

echo "✅ Worktree created successfully"
```

---

## STEP 4: Sync .claude-project

**Copy .claude-project from current directory to worktree:**

```bash
if [ -d ".claude-project" ]; then
  echo ""
  echo "📋 Syncing .claude-project to worktree..."

  cp -r .claude-project "${worktreePath}/"

  if [ $? -eq 0 ]; then
    echo "✅ .claude-project synced"

    # Count files
    fileCount=$(find "${worktreePath}/.claude-project" -type f | wc -l)
    echo "   Files copied: ${fileCount}"
  else
    echo "⚠️  Failed to sync .claude-project (non-critical)"
  fi
else
  echo "ℹ️  No .claude-project in current directory, skipping sync"
fi
```

---

## STEP 5: Copy and Configure .env

**Copy .env files and update port to avoid conflicts:**

```bash
echo ""
echo "⚙️  Configuring environment files..."

# Copy main .env if exists
if [ -f ".env" ]; then
  cp .env "${worktreePath}/.env"

  # Find current port in source .env
  if grep -q "^PORT=" .env; then
    currentPort=$(grep "^PORT=" .env | cut -d= -f2 | tr -d ' ')
  else
    currentPort="3000"  # Default assumption
  fi

  echo "   Current port: ${currentPort}"

  # Find free port for new worktree
  newPort=$(findFreePort ${currentPort})

  echo "   New port: ${newPort}"

  # Update PORT in worktree .env
  if grep -q "^PORT=" "${worktreePath}/.env"; then
    # PORT exists, replace it
    sed -i "s/^PORT=.*/PORT=${newPort}/" "${worktreePath}/.env"
  else
    # PORT doesn't exist, add it
    echo "" >> "${worktreePath}/.env"
    echo "# Auto-configured for worktree" >> "${worktreePath}/.env"
    echo "PORT=${newPort}" >> "${worktreePath}/.env"
  fi

  echo "   ✅ .env configured with PORT=${newPort}"
else
  echo "   ℹ️  No .env file found"
  newPort="3000"  # Default for WORKTREE-INFO.md
fi

# Copy additional .env.* files (except .env.test and *.local)
envExtraFiles=$(find . -maxdepth 1 -name ".env.*" -not -name ".env.test" -not -name ".env.*.local" -type f 2>/dev/null)

if [ -n "$envExtraFiles" ]; then
  echo ""
  echo "   Copying additional .env files..."

  for envFile in $envExtraFiles; do
    envFileName=$(basename "$envFile")
    cp "$envFile" "${worktreePath}/${envFileName}"

    if [ $? -eq 0 ]; then
      echo "   ✅ ${envFileName}"
    fi
  done
fi

echo ""
```

**Helper function: findFreePort**

```bash
function findFreePort() {
  local basePort=$1
  local testPort=$((basePort + 1))
  local maxAttempts=100

  for ((i=0; i<maxAttempts; i++)); do
    # Check if port is in use
    if ! lsof -i:${testPort} >/dev/null 2>&1 && \
       ! grep -r "PORT=${testPort}" ../*/.env 2>/dev/null | grep -v "^${worktreePath}"; then
      # Port is free
      echo ${testPort}
      return 0
    fi

    testPort=$((testPort + 1))
  done

  # Fallback: random high port
  echo $((10000 + RANDOM % 10000))
}
```

---

## STEP 6: Copy Project-Level .claude Directory

**Copy entire .claude/ directory if exists (project-specific configs, commands, agents):**

```bash
if [ -d ".claude" ]; then
  echo ""
  echo "📁 Copying project .claude directory..."

  # Copy entire .claude directory
  cp -r .claude "${worktreePath}/"

  if [ $? -eq 0 ]; then
    # Count files copied
    claudeFileCount=$(find "${worktreePath}/.claude" -type f | wc -l)

    echo "✅ .claude directory copied (${claudeFileCount} files)"

    # Show what was copied
    if [ -f "${worktreePath}/.claude/CLAUDE.md" ]; then
      echo "   • CLAUDE.md (project standards)"
    fi

    if [ -d "${worktreePath}/.claude/commands" ]; then
      commandCount=$(find "${worktreePath}/.claude/commands" -name "*.md" | wc -l)
      if [ "$commandCount" -gt 0 ]; then
        echo "   • commands/ (${commandCount} project commands)"
      fi
    fi

    if [ -d "${worktreePath}/.claude/agents" ]; then
      agentCount=$(find "${worktreePath}/.claude/agents" -name "*.md" | wc -l)
      if [ "$agentCount" -gt 0 ]; then
        echo "   • agents/ (${agentCount} project agents)"
      fi
    fi

    if [ -d "${worktreePath}/.claude/skills" ]; then
      skillCount=$(find "${worktreePath}/.claude/skills" -type d -mindepth 1 -maxdepth 1 | wc -l)
      if [ "$skillCount" -gt 0 ]; then
        echo "   • skills/ (${skillCount} project skills)"
      fi
    fi

  else
    echo "⚠️  Failed to copy .claude directory (non-critical)"
  fi
else
  echo "ℹ️  No .claude directory found, skipping"
fi
```

---

## STEP 7: Check if Branch Needs Documentation

**IMPORTANT: Don't suggest /init-project for task branches**

```bash
echo ""
echo "📚 Documentation setup for ${targetBranch}..."
echo ""

# Determine branch type
# Task branches (for specific tasks) DON'T need their own documentation
# Major branches (version branches, main, develop) DO need documentation

# Heuristics to detect task branch:
isTaskBranch="no"

# Pattern 1: Branch name matches task pattern (V-39, TASK-123, AUTH-456, feature-auth-123)
if [[ "$targetBranch" =~ ^V-[0-9]+$ ]] || \
   [[ "$targetBranch" =~ ^[A-Z]+-[0-9]+$ ]] || \
   [[ "$targetBranch" =~ -[0-9]+$ ]] || \
   [[ "$targetBranch" =~ ^(feature|fix|hotfix)/.+[0-9]+$ ]]; then
  isTaskBranch="yes"
fi

# Pattern 2: Check if parent is version branch (V-37, V-38, etc.)
if [[ "$sourceBranch" =~ ^V-[0-9]+$ ]]; then
  # Creating from version branch likely means task branch
  isTaskBranch="yes"
fi

parentDocsPath=".claude-project/project/${sourceBranch}"

if [ "$isTaskBranch" = "yes" ]; then
  echo "📋 ${targetBranch} detected as TASK BRANCH"
  echo ""
  echo "   Task branches use parent branch documentation."
  echo "   No need to run /init-project for this branch."
  echo ""

  if [ -d "$parentDocsPath" ]; then
    echo "   ✅ Parent branch ${sourceBranch} has documentation"
    echo "   ✅ ${targetBranch} will use .claude-project/project/${sourceBranch}/"
    echo ""
    echo "   When you run /do in this worktree:"
    echo "   - It will read project context from parent (${sourceBranch})"
    echo "   - Tasks will be developed relative to parent baseline"
    echo "   - All analysis will use: git diff ${sourceBranch}...${targetBranch}"
  else
    echo "   ⚠️  Parent branch ${sourceBranch} has NO documentation"
    echo ""
    echo "   Recommendation:"
    echo "   1. Switch to ${sourceBranch} and run /init-project"
    echo "   2. Then return to ${targetBranch} for task development"
  fi

else
  # Major/version branch - may need its own documentation
  echo "📘 ${targetBranch} detected as MAJOR/VERSION BRANCH"
  echo ""

  if [ -d "$parentDocsPath" ]; then
    echo "   ✅ Parent branch ${sourceBranch} has documentation"
    echo ""
    echo "   Optional: Create branch-specific documentation with /init-project"
    echo ""
    echo "   Run /init-project in this worktree if:"
    echo "   - This branch will have significant changes from parent"
    echo "   - Other branches will be created from this branch"
    echo "   - This is a long-lived branch (weeks/months)"
    echo ""
    echo "   Otherwise:"
    echo "   - Just use parent documentation (.claude-project/project/${sourceBranch}/)"
    echo "   - Start working: /do TASK-1 \"...\""
  else
    echo "   ℹ️  Parent branch has no documentation"
    echo ""
    echo "   Run /init-project to create documentation:"
    echo "   cd ${worktreePath}"
    echo "   /init-project"
  fi
fi

echo ""
```

---

## STEP 8: Create README in Worktree

**Create helpful README in worktree root:**

```bash
cat > "${worktreePath}/WORKTREE-INFO.md" << 'WORKTREE_EOF'
# Worktree Information

This is a git worktree for branch: ${targetBranch}

## Created
- Date: $(date)
- Source branch: ${sourceBranch}
- Parent directory: ${parentDir}

## Configuration

**Port**: ${newPort} (configured in .env)

**To avoid conflicts:**
- This worktree runs on PORT=${newPort}
- Original worktree runs on PORT=${currentPort}
- Make sure to use different ports

## Running the Application

```bash
npm start  # Will use PORT=${newPort} from .env
# or
npm run dev
```

## Documentation

Run \`/init\` to create branch-specific documentation:
```bash
cd $(pwd)
/init  # Will create .claude-project/project/${targetBranch}/
```

## Cleanup

When done with this worktree:
```bash
# Remove worktree
git worktree remove ${worktreePath}

# Delete branch (if no longer needed)
git branch -d ${targetBranch}
```

---

*Created by Claude Code /worktree command*
WORKTREE_EOF

echo "✅ Created WORKTREE-INFO.md"
```

---

## STEP 9: Final Summary

```bash
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           ✅ WORKTREE CREATED SUCCESSFULLY                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Branch: ${targetBranch}"
echo "Path: ${worktreePath}"
echo ""

if [ -f "${worktreePath}/.env" ]; then
  echo "Configuration:"
  echo "  PORT: ${newPort} (configured in .env)"
  echo ""
fi

echo "Next steps:"
echo ""
echo "  1. Navigate to worktree:"
echo "     cd ${worktreePath}"
echo ""
echo "  2. Install dependencies (if needed):"
echo "     npm install"
echo ""
echo "  3. Initialize documentation:"
echo "     /init"
echo ""
echo "  4. Start development:"
echo "     npm start  # Runs on port ${newPort}"
echo ""
echo "  5. Create tasks:"
echo "     /do TASK-1 \"Description\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To return to original worktree:"
echo "  cd ${currentDir}"
echo ""
echo "To list all worktrees:"
echo "  git worktree list"
echo ""
echo "To remove this worktree later:"
echo "  git worktree remove ${worktreePath}"
echo ""
```

---

## Helper Functions

### findFreePort()

```bash
function findFreePort() {
  local basePort=$1
  local testPort=$((basePort + 1))

  # Check worktrees for used ports
  local worktrees=$(git worktree list --porcelain | grep "^worktree " | sed 's/^worktree //')

  local usedPorts=()

  # Scan .env files in all worktrees for PORT
  for wt in $worktrees; do
    if [ -f "$wt/.env" ]; then
      local port=$(grep "^PORT=" "$wt/.env" 2>/dev/null | cut -d= -f2 | tr -d ' ')
      if [ -n "$port" ]; then
        usedPorts+=($port)
      fi
    fi
  done

  # Also check currently running processes
  local runningPorts=$(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d: -f2 | sort -u)

  # Combine used ports
  allUsedPorts=$(printf '%s\n' "${usedPorts[@]}" "$runningPorts" | sort -u)

  # Find first free port starting from basePort + 1
  for ((i=1; i<=100; i++)); do
    testPort=$((basePort + i))

    # Check if port is in used ports
    if ! echo "$allUsedPorts" | grep -q "^${testPort}$"; then
      echo ${testPort}
      return 0
    fi
  done

  # Fallback to random high port
  echo $((10000 + RANDOM % 10000))
}
```

### copyEnvFiles()

**Copy additional .env.* files:**

```bash
function copyEnvFiles() {
  local targetDir=$1

  # Find all .env.* files (except .env.test which is user-specific)
  local envFiles=$(find . -maxdepth 1 -name ".env.*" -not -name ".env.test" -not -name ".env.*.local" 2>/dev/null)

  if [ -n "$envFiles" ]; then
    echo ""
    echo "📋 Copying additional .env files..."

    for envFile in $envFiles; do
      envFileName=$(basename "$envFile")
      cp "$envFile" "${targetDir}/${envFileName}"

      if [ $? -eq 0 ]; then
        echo "   ✅ ${envFileName}"
      else
        echo "   ⚠️  Failed to copy ${envFileName}"
      fi
    done
  fi
}
```

---

## Full Execution Flow

### Example 1: Create worktree for existing branch

```bash
/worktree V-37
```

**Execution:**
```
1. Check: V-37 branch exists? → YES
2. Mode: create-worktree-for-existing
3. Worktree path: ../fea-V-37/
4. Create: git worktree add ../fea-V-37 V-37
5. Sync .claude-project: cp -r .claude-project ../fea-V-37/
6. Copy .env: cp .env ../fea-V-37/.env
7. Find free port: 3001
8. Update ../fea-V-37/.env: PORT=3001
9. Copy CLAUDE.md: cp .claude/CLAUDE.md ../fea-V-37/.claude/
10. Create WORKTREE-INFO.md
11. Summary message

✅ Worktree ready at ../fea-V-37/
```

### Example 2: Create new branch from current, then worktree

```bash
/worktree feature-auth
```

**Execution:**
```
1. Check: feature-auth branch exists? → NO
2. Mode: create-new-branch-and-worktree
3. Current branch: main
4. Create branch: git checkout -b feature-auth (then back to main)
5. Worktree path: ../fea-feature-auth/
6. Create: git worktree add ../fea-feature-auth feature-auth
7-11. Same as Example 1

✅ Worktree ready at ../fea-feature-auth/
```

### Example 3: Create branch2 from branch1, then worktree

```bash
/worktree develop feature-payments
```

**Execution:**
```
1. Check: develop exists? → YES ✓
2. Check: feature-payments exists? → NO
3. Mode: create-branch-and-worktree
4. Create branch: git checkout develop && git checkout -b feature-payments
5. Worktree path: ../fea-feature-payments/
6. Create: git worktree add ../fea-feature-payments feature-payments
7-11. Same as above

✅ Worktree ready at ../fea-feature-payments/
```

### Example 4: Error - source branch doesn't exist

```bash
/worktree non-existent-branch feature-new
```

**Execution:**
```
1. Check: non-existent-branch exists? → NO ❌

ERROR Output:
❌ ERROR: Source branch 'non-existent-branch' does not exist

Available branches:
  main
  develop
  feature-auth
  V-37
  v36

Usage: /worktree <existing-branch> <new-branch>

STOP execution
```

---

## Advanced Features

### Port Configuration Strategies

**Strategy 1: Sequential (current implementation)**
```javascript
basePort = 3000
newPort = 3001, 3002, 3003, ... (first available)
```

**Strategy 2: Hash-based (predictable)**
```javascript
// Deterministic port based on branch name
hash = simpleHash(branchName)
newPort = 3000 + (hash % 100)  // 3000-3099 range
```

**Strategy 3: Ask user**
```javascript
AskUserQuestion:
  Question: "Current worktrees use ports 3000, 3001. Which port for this worktree?"
  Options:
    - "Auto-detect free port (${suggestedPort})"
    - "Custom port" → prompt for number
```

### Copy Additional Files

**Optional files to copy:**

```bash
# Copy package-lock.json or yarn.lock
if [ -f "package-lock.json" ]; then
  cp package-lock.json "${worktreePath}/"
  echo "✅ package-lock.json copied"
fi

# Copy docker-compose.yml (but may need port updates)
if [ -f "docker-compose.yml" ]; then
  cp docker-compose.yml "${worktreePath}/"

  # Update ports in docker-compose.yml
  sed -i "s/:${currentPort}/:${newPort}/g" "${worktreePath}/docker-compose.yml"

  echo "✅ docker-compose.yml copied and ports updated"
fi

# Copy .vscode settings
if [ -d ".vscode" ]; then
  cp -r .vscode "${worktreePath}/"
  echo "✅ .vscode settings copied"
fi
```

### Symlink node_modules (optional)

**Instead of npm install in each worktree:**

```bash
AskUserQuestion:
  Question: "Handle node_modules for new worktree?"
  Options:
    - "Symlink to current (fast, but requires identical deps)"
    - "Run npm install (safe, but slower)"
    - "Skip (do manually later)"

if (choice == "symlink") {
  ln -s "$(pwd)/node_modules" "${worktreePath}/node_modules"
  echo "✅ node_modules symlinked"
} else if (choice == "install") {
  cd "${worktreePath}"
  npm install
  cd "${currentDir}"
  echo "✅ Dependencies installed"
}
```

---

## Error Handling

### Git not a repository

```bash
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ ERROR: Not a git repository"
  echo ""
  echo "Git worktrees can only be created in git repositories."
  echo ""
  echo "Initialize git first:"
  echo "  git init"
  echo ""
  exit 1
fi
```

### Disk space check

```bash
# Check available disk space
availableSpace=$(df -BM . | tail -1 | awk '{print $4}' | sed 's/M//')

if [ "$availableSpace" -lt 500 ]; then
  echo "⚠️  WARNING: Low disk space (${availableSpace}MB available)"
  echo "   Worktree creation may fail"

  AskUserQuestion:
    Question: "Low disk space. Continue?"
    Options:
      - "Yes, continue"
      - "Cancel"
fi
```

### Worktree path conflicts

```bash
# If path contains spaces or special characters
if [[ "$worktreePath" =~ [[:space:]] ]]; then
  echo "⚠️  WARNING: Worktree path contains spaces"
  echo "   Path: ${worktreePath}"
  echo ""
  echo "This may cause issues with some tools."

  AskUserQuestion:
    Question: "Path has spaces. Continue?"
    Options:
      - "Yes, use this path"
      - "Enter different path"
      - "Cancel"
fi
```

---

## Quality Checklist

Before completing, verify:
- [ ] Git worktree created successfully
- [ ] Branch created (if needed)
- [ ] .claude-project synced to worktree
- [ ] .env copied and PORT updated
- [ ] CLAUDE.md copied (if exists)
- [ ] WORKTREE-INFO.md created
- [ ] Free port found and configured
- [ ] No port conflicts with existing worktrees
- [ ] Summary message displayed with next steps

---

## Usage Examples

### Example 1: Simple worktree for existing branch

```bash
# You're in ~/project/main-wt (main branch)
# V-37 branch exists in git

/worktree V-37
```

**Result:**
```
✅ Worktree created at ~/project/main-wt-V-37/
   Branch: V-37
   Port: 3001
   .claude-project: ✓ synced
   .env: ✓ copied (PORT=3001)
   CLAUDE.md: ✓ copied
```

### Example 2: Create new feature branch + worktree

```bash
# You're in main branch
# Want to create feature-auth branch

/worktree feature-auth
```

**Result:**
```
✅ Branch feature-auth created from main
✅ Worktree created at ../fea-feature-auth/
   Port: 3001
   All configs synced
```

### Example 3: Create branch from specific source

```bash
# Create feature-v2-api from develop branch

/worktree develop feature-v2-api
```

**Result:**
```
✅ Branch feature-v2-api created from develop
✅ Worktree created at ../fea-feature-v2-api/
   Port: 3002
```

### Example 4: Error - source doesn't exist

```bash
/worktree non-existent new-feature
```

**Result:**
```
❌ ERROR: Source branch 'non-existent' does not exist

Available branches:
  main
  develop

STOPPED
```

---

## Important Notes

### TodoWrite Usage

Use TodoWrite to track worktree creation progress:

```javascript
TodoWrite({
  todos: [
    { content: "Validate arguments", status: "completed" },
    { content: "Create git worktree", status: "completed" },
    { content: "Sync .claude-project", status: "in_progress" },
    { content: "Configure .env", status: "pending" },
    { content: "Copy CLAUDE.md", status: "pending" }
  ]
});
```

### Cleanup Instructions

Always provide cleanup instructions in summary:

```bash
echo "To remove this worktree later:"
echo "  git worktree remove ${worktreePath}"
echo "  # Or: git worktree remove ${worktreePath} --force (if has changes)"
echo ""
echo "To delete the branch:"
echo "  git branch -d ${targetBranch}  # Safe delete (only if merged)"
echo "  git branch -D ${targetBranch}  # Force delete"
```

### Post-Creation Actions

After worktree created, suggest:

```bash
echo "Recommended next actions:"
echo ""
echo "  1. cd ${worktreePath}"
echo "  2. /init  # Create branch-specific docs"
echo "  3. /do TASK-1 \"First task in this worktree\""
echo "  4. npm start  # Verify app runs on PORT=${newPort}"
```

---

You have access to all tools. Use Bash for git operations, file copying, and port checks.

**Important**: This command creates a fully configured development environment in the new worktree.
