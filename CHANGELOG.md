# Changelog

All notable changes to claude-nodejs marketplace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-01

### Added

#### tasks-execution Plugin

**Commands**:
- `/init-project` - 3-mode project documentation system
  - INIT MODE: Create documentation from scratch with interactive Q&A
  - SYNC MODE: Synchronize existing docs with codebase (find discrepancies)
  - DIFF MODE: Create docs from parent branch + git diff (90% token savings!)

- `/do` - 8-phase complete task development workflow
  - Phase 0: Business Analysis (interactive, plan mode)
  - Phase 1: System Design (system-designer agent)
  - Phase 2: Implementation (code-implementer agent)
  - Phase 3: Bug Hunting (iterative, max 5 iterations)
  - Phase 4: Code Cleanliness (quality checks)
  - Phase 5: Test Creation (auto-generated integration tests)
  - Phase 6: Test Execution (background app + test runner)
  - Phase 7: Test Fixing (iterative, max 3 iterations)
  - Phase 8: Final Summary (complete documentation)

- `/tasks` - Tasks dashboard with status tracking
  - Summary statistics (total, completed, active, blocked)
  - Table view (task, branch, status, phase)
  - Active task details
  - Recent completions (7 days)

**Agents**:
- `project-documenter` - Creates and maintains project documentation
- `system-designer` - Translates business requirements to technical specs
- `code-implementer` - Implements code per specifications with quality rules

**Hooks**:
- `check-unpulled-outdated.sh` - SessionStart hook
  - Checks unpulled changes in documented branches
  - Checks outdated tasks (parent moved ahead)
  - Alerts Claude to suggest sync actions

**Helpers**:
- `sync-worktree.sh` - Syncs .claude-project across git worktrees
  - Called automatically by /init-project and /do
  - Uses rsync for intelligent sync (only changed files)

**Features**:
- Branch-aware workflow (per-branch docs, git metadata)
- Token-optimized DIFF MODE (copy + edit strategy)
- Checkpoint resume via SUMMARY.md
- Parent divergence detection with rebase/merge offers
- Relative diff analysis (only task changes)
- Worktree synchronization

#### worktree Plugin

**Command**:
- `/worktree` - Git worktree creator with environment setup
  - Single arg: Create worktree for existing or new branch
  - Two args: Create branch2 from branch1, then worktree
  - Auto-sync .claude-project/ and .claude/
  - Auto-configure .env with free PORT
  - Smart branch type detection (task vs major)

**Features**:
- Automatic PORT conflict resolution
- Full .claude directory copy (commands, agents, skills, CLAUDE.md)
- WORKTREE-INFO.md creation
- Branch type detection (suggests /init-project only for major branches)

### Documentation

**Comprehensive guides** (~270KB total):
- INIT-COMMAND-SETUP.md - Detailed /init-project guide
- DO-COMMAND-GUIDE.md - Detailed /do guide
- TASKS-COMMAND-GUIDE.md - /tasks usage
- WORKTREE-COMMAND-GUIDE.md - /worktree usage
- DIFF-MODE-OPTIMIZATION.md - Token savings explanation
- BRANCH-AWARE-COMMANDS.md - Branch workflow
- WORKTREE-SYNC-GUIDE.md - Sync mechanism

### Initial Release

This is the initial release (v1.0.0) of the claude-nodejs marketplace.

**Marketplace Structure**:
- 2 plugins (tasks-execution, worktree)
- 4 commands total
- 3 agents
- 2 helper scripts
- 1 SessionStart hook

**Statistics**:
- ~2600 lines of code
- ~270KB documentation
- 11 comprehensive guides
- Production-ready

---

[1.0.0]: https://github.com/tesoldofficial/claude-nodejs/releases/tag/v1.0.0
