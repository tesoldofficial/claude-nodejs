# Tasks Execution Plugin

Complete project documentation and task development workflow for Claude Code with branch-aware design and worktree synchronization.

## Overview

This plugin provides a comprehensive system for managing Node.js projects with:
- **Project Documentation** (/init-project) - 3 modes: INIT, SYNC, DIFF
- **Task Development** (/do) - 8-phase automated workflow
- **Tasks Dashboard** (/tasks) - Track all tasks and their status
- **Specialized Agents** - project-documenter, system-designer, code-implementer
- **Hooks** - Auto-check unpulled changes and outdated tasks

## Commands

### `/init-project` - Project Documentation

Initialize or synchronize comprehensive project documentation.

**3 Automatic Modes:**
- **INIT MODE**: Create documentation from scratch (interactive)
- **SYNC MODE**: Synchronize docs with code (find discrepancies)
- **DIFF MODE**: Create docs from parent branch + git diff (90% token savings!)

**Per-branch structure**: `.claude-project/project/{branch}/`

**Example**:
```bash
/init-project
# Auto-detects mode based on existing docs
# Creates modular documentation (business + architecture)
```

**See**: [docs/INIT-COMMAND-SETUP.md](./docs/INIT-COMMAND-SETUP.md)

---

### `/do <task-name> [description]` - Task Development

Complete end-to-end task implementation through 8 phases.

**Usage**:
```bash
/do AUTH-123 "Implement JWT authentication"  # New task
/do AUTH-123                                  # Continue existing
/do AUTH-123 начни заново                    # Restart from scratch
```

**8 Phases**:
1. Business Analysis (interactive, plan mode)
2. System Design (system-designer agent → SYSTEM-DESIGN.md)
3. Implementation (code-implementer → production code)
4. Bug Hunting (bug-hunter, iterative, max 5)
5. Code Cleanliness (quality checks)
6. Test Creation (auto-generated integration tests)
7. Test Execution (background app + test runner)
8. Final Summary (complete documentation)

**Branch Awareness**:
- Tracks git metadata (taskBranch, parentBranch, mergeBase)
- Validates branch on resume
- Detects parent divergence, offers rebase/merge
- All analysis relative to merge base

**Checkpoint Resume**: SUMMARY.md updated after each phase

**See**: [docs/DO-COMMAND-GUIDE.md](./docs/DO-COMMAND-GUIDE.md)

---

### `/tasks` - Tasks Dashboard

Display overview of all tasks with their status and progress.

**Usage**:
```bash
/tasks
```

**Output**:
```
📊 Tasks Summary: Total 5 | ✅ Done 2 | 🔄 Active 2

┌──────────┬──────────────┬─────────┬──────────┐
│ Task     │ Branch       │ Status  │ Phase    │
├──────────┼──────────────┼─────────┼──────────┤
│ AUTH-123 │ feature-auth │ ✅ Done │ Phase 8  │
│ PAY-456  │ feature-pay  │ 🔄 Active│ Phase 5 │
└──────────┴──────────────┴─────────┴──────────┘
```

**Statuses**: ✅ Done | 🔄 Active | ⏸️ On Hold | ❌ Blocked | ❓ Unknown

**See**: [docs/TASKS-COMMAND-GUIDE.md](./docs/TASKS-COMMAND-GUIDE.md)

## Agents

### project-documenter
Creates and maintains comprehensive project documentation. Used by /init-project.

### system-designer
Translates business requirements into technical specifications. Used by /do (Phase 1).

### code-implementer
Implements code per specifications with strict quality rules. Used by /do (Phase 2).

## Hooks

### check-unpulled-outdated.sh (SessionStart)
Checks on startup:
- Unpulled changes in documented branches (remote ahead of local)
- Outdated task branches (parent moved ahead of merge base)

Alerts Claude to suggest: `git pull && /init-project` or `/do <task>` (rebase/merge)

### sync-worktree.sh
Syncs .claude-project/ across all git worktrees automatically.

Called by: /init-project and /do commands after completion.

## Installation

This plugin is part of the `claude-nodejs` marketplace.

**Install marketplace**:
```bash
# In Claude Code
/plugin install https://github.com/tesoldofficial/claude-nodejs.git
```

**Or install plugin directly**:
```bash
# TBD: specific installation command
```

## Configuration

**SessionStart Hook** (optional, recommended):

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "<path-to-plugin>/hooks/check-unpulled-outdated.sh"
          }
        ]
      }
    ]
  }
}
```

## Quick Start

```bash
# 1. Initialize project
/init-project
# Creates .claude-project/project/main/

# 2. Start first task
/do TASK-1 "Implement user authentication"
# 8-phase workflow → fully tested implementation

# 3. Check status
/tasks
# Dashboard with all tasks

# 4. Next session
# Hook checks unpulled + outdated
# Claude suggests sync if needed
```

## Features

### Branch-Aware Workflow
- Per-branch documentation
- Git metadata tracking
- Parent divergence detection
- Branch validation

### Token Optimization
- DIFF MODE: 90% output token savings (copy + edit)
- Task branches: use parent docs (no duplication)

### Worktree Support
- Auto-sync .claude-project across worktrees
- Tasks visible in all worktrees
- Consistent experience

### Quality Assurance
- 8-phase development process
- Auto-generated integration tests
- Iterative bug fixing (max 5 iterations)
- Code cleanliness checks

## Documentation

- [INIT Command Setup](./docs/INIT-COMMAND-SETUP.md) - Detailed /init-project guide
- [DO Command Guide](./docs/DO-COMMAND-GUIDE.md) - Detailed /do guide
- [Tasks Dashboard Guide](./docs/TASKS-COMMAND-GUIDE.md) - /tasks usage
- [DIFF Mode Optimization](./docs/DIFF-MODE-OPTIMIZATION.md) - Token savings
- [Branch-Aware Commands](./docs/BRANCH-AWARE-COMMANDS.md) - Branch workflow

## Requirements

- Claude Code installed
- Git repository
- Node.js project (for tests)

## Version

**Current**: 1.0.0

## License

MIT

## Author

tesold

---

Part of [claude-nodejs](https://github.com/tesoldofficial/claude-nodejs) marketplace.
