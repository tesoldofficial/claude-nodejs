# Worktree Plugin

Git worktree management with automatic environment configuration and conflict-free parallel development.

## Overview

This plugin simplifies git worktree creation with automatic setup:
- Creates git worktrees with one command
- Syncs .claude-project/ (docs + tasks)
- Copies .claude/ (commands + agents + skills + CLAUDE.md)
- Auto-configures .env with free PORT
- Smart branch type detection (task vs major branches)

## Command

### `/worktree <branch> [source]`

Create git worktree with full environment setup.

**Syntax**:
```bash
/worktree <branch>                # Worktree for existing or new branch from current
/worktree <source> <target>       # Create target from source, then worktree
```

**Examples**:
```bash
# Existing branch
/worktree V-37
# → ~/project-V-37/, PORT=3001

# New branch from current
/worktree feature-auth
# → Creates feature-auth from current
# → ~/project-feature-auth/, PORT=3002

# New branch from specific source
/worktree main hotfix-bug
# → Creates hotfix-bug from main
# → ~/project-hotfix-bug/, PORT=3003
```

## What It Does

1. **Creates git worktree** in sibling directory
   - Pattern: `{parentDir}/{currentDirName}-{branchName}`

2. **Syncs .claude-project/**
   - All documentation
   - All tasks
   - Full copy

3. **Copies .claude/**
   - CLAUDE.md (project standards)
   - commands/ (project commands)
   - agents/ (project agents)
   - skills/ (project skills)

4. **Copies .env with PORT auto-config**
   - Finds free PORT (scans all worktrees + running processes)
   - Updates PORT in worktree .env
   - Prevents port conflicts

5. **Creates WORKTREE-INFO.md**
   - Branch info, PORT, cleanup instructions

## Branch Type Detection

**Task Branch** (V-39, TASK-123, feature-X-123):
- Uses parent branch documentation
- NO /init-project suggested
- Perfect for short-lived task branches

**Major Branch** (V-37, main, develop):
- May need own documentation
- /init-project suggested if long-lived
- Source for other branches

## Use Cases

### Parallel Development
```bash
# Terminal 1: Feature A
cd ~/project-feature-a
npm start  # PORT=3001
/do TASK-1 "..."

# Terminal 2: Feature B
cd ~/project-feature-b
npm start  # PORT=3002
/do TASK-2 "..."

# Both running simultaneously!
```

### Code Review
```bash
/worktree origin/colleague-pr
cd ~/project-colleague-pr
npm install && npm start  # PORT=3001
# Review in isolation
```

### Hotfix
```bash
/worktree main hotfix-critical
cd ~/project-hotfix-critical
/do FIX-999 "Critical bug"
# Urgent fix without disrupting other work
```

### Version Maintenance
```bash
/worktree v36  # PORT=3001
/worktree v37  # PORT=3002
/worktree v38  # PORT=3003
# Multiple versions active
```

## PORT Configuration

Auto-finds free PORT by:
1. Scanning .env in all worktrees
2. Checking running processes (lsof)
3. Finding first free port (3001, 3002, ...)
4. Fallback to random 10000-20000 if 100+ worktrees

## Installation

Part of `claude-nodejs` marketplace.

```bash
# Install marketplace
/plugin install https://github.com/tesoldofficial/claude-nodejs.git
```

## Integration

Works seamlessly with other plugins:
- Uses worktree-sync helper (from tasks-execution plugin)
- /init-project in worktree (DIFF MODE)
- /do in worktree (uses parent docs)
- /tasks shows all tasks (synced)

## Documentation

- [Worktree Command Guide](./docs/WORKTREE-COMMAND-GUIDE.md) - Detailed usage
- [Worktree Sync Guide](./docs/WORKTREE-SYNC-GUIDE.md) - Sync mechanism

## Requirements

- Claude Code installed
- Git repository
- rsync (for intelligent sync)

## Version

**Current**: 1.0.0

## License

MIT

## Author

tesold

---

Part of [claude-nodejs](https://github.com/tesoldofficial/claude-nodejs) marketplace.
