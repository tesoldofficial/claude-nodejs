# Claude Node.js Plugins

This marketplace contains two plugins for professional Node.js development with Claude Code.

## Available Plugins

### 1. [tasks-execution](./tasks-execution/)

Complete project documentation and task development workflow.

**Commands**:
- `/init-project` - Project documentation (3 modes: INIT, SYNC, DIFF)
- `/do` - 8-phase task development workflow
- `/tasks` - Tasks dashboard

**Agents**:
- project-documenter - Creates/maintains project documentation
- system-designer - Architectural design from business requirements
- code-implementer - Implements code per specifications

**Hooks**:
- SessionStart: check-unpulled-outdated.sh (unpulled + outdated detection)
- Worktree sync: sync-worktree.sh

**Key Features**:
- Branch-aware workflow
- Token-optimized DIFF MODE (90% savings)
- Auto-generated integration tests
- Checkpoint resume (SUMMARY.md)
- Quality assurance (bug hunting, cleanliness checks)

---

### 2. [worktree](./worktree/)

Git worktree management with automatic environment configuration.

**Command**:
- `/worktree` - Create worktrees with full environment setup

**Key Features**:
- Auto-sync .claude-project/ and .claude/
- Auto-configure PORT (find free port, update .env)
- Smart branch type detection (task vs major)
- Conflict-free parallel development

---

## Installation

Install the entire marketplace:

```bash
# In Claude Code
/plugin install https://github.com/tesoldofficial/claude-nodejs.git
```

Or install individual plugins (see each plugin's README for details).

## Quick Comparison

| Feature | tasks-execution | worktree |
|---------|----------------|----------|
| Project docs | ✅ /init-project | ➖ |
| Task workflow | ✅ /do (8 phases) | ➖ |
| Dashboard | ✅ /tasks | ➖ |
| Worktree creation | ➖ | ✅ /worktree |
| Port auto-config | ➖ | ✅ |
| Branch detection | ✅ | ✅ |
| Worktree sync | ✅ (helper) | ✅ (uses helper) |

**Recommendation**: Install both for complete workflow.

## Typical Workflow

```bash
# 1. Initialize project (tasks-execution)
/init-project

# 2. Create worktree for task (worktree)
/worktree V-39

# 3. Develop task (tasks-execution)
cd ../project-V-39
/do TASK-1 "Feature description"

# 4. Check status (tasks-execution)
/tasks

# 5. Parallel development (worktree)
/worktree V-40
cd ../project-V-40
npm start  # PORT auto-configured!
/do TASK-2 "Another feature"
```

## Documentation

Each plugin includes detailed documentation in its `docs/` directory.

## License

MIT - see [LICENSE.md](../LICENSE.md)

## Author

tesold

---

**Marketplace**: claude-nodejs
**Repository**: https://github.com/tesoldofficial/claude-nodejs
