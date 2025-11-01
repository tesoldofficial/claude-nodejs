# Claude Node.js - Professional Project Management for Claude Code

Comprehensive marketplace with plugins for Node.js project management, task development, and git worktree workflows.

![](https://img.shields.io/badge/Claude%20Code-Marketplace-blue?style=flat-square)
![](https://img.shields.io/badge/Version-1.0.0-green?style=flat-square)
![](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

## Overview

This marketplace provides two powerful plugins for Node.js development with Claude Code:

1. **tasks-execution** - Complete project documentation and task development workflow
2. **worktree** - Git worktree management with automatic environment configuration

## Plugins

### 🚀 Tasks Execution Plugin

**Complete project and task management system** with:
- `/init-project` - 3-mode documentation (INIT/SYNC/DIFF with 90% token savings)
- `/do` - 8-phase task workflow (Business → Design → Code → Bugs → Tests → Summary)
- `/tasks` - Dashboard of all tasks with status tracking
- Specialized agents (project-documenter, system-designer, code-implementer)
- SessionStart hook (unpulled + outdated detection)
- Worktree sync (automatic .claude-project synchronization)

**Perfect for**: Professional Node.js development with comprehensive quality checks and documentation.

[**Learn more →**](./plugins/tasks-execution/README.md)

---

### 🌿 Worktree Plugin

**Git worktree management made easy** with:
- `/worktree` - Create worktrees with one command
- Auto-sync .claude-project/ and .claude/
- Auto-configure .env with free PORT
- Smart branch type detection
- Conflict-free parallel development

**Perfect for**: Working on multiple features/versions simultaneously without conflicts.

[**Learn more →**](./plugins/worktree/README.md)

## Installation

### Quick Install (Marketplace)

```bash
# In Claude Code, run:
/plugin install https://github.com/tesoldofficial/claude-nodejs.git
```

This installs both plugins.

### Manual Install

Clone the repository and install plugins individually:

```bash
git clone https://github.com/tesoldofficial/claude-nodejs.git
cd claude-nodejs

# Install specific plugin
cp -r plugins/tasks-execution ~/.claude/plugins/marketplaces/claude-nodejs/plugins/
cp -r plugins/worktree ~/.claude/plugins/marketplaces/claude-nodejs/plugins/
```

## Quick Start

### Initialize Your Project

```bash
cd your-nodejs-project
/init-project
```

Creates comprehensive documentation in `.claude-project/project/main/`:
- Business context (customers, goals, requirements, user journeys)
- Technical architecture (tech stack, system design, data model, API, infrastructure)
- Development guides (conventions, setup)

### Develop Your First Task

```bash
/do AUTH-123 "Implement JWT authentication with refresh tokens"
```

**What happens**:
1. **Phase 0**: Business analysis (interactive questions to clarify requirements)
2. **Phase 1**: System design (system-designer agent creates architecture)
3. **Phase 2**: Implementation (code-implementer writes production code)
4. **Phase 3**: Bug hunting (iterative until no P0 bugs)
5. **Phase 4**: Code cleanliness check
6. **Phase 5**: Test creation (auto-generated integration tests)
7. **Phase 6**: Test execution (runs tests, verifies implementation)
8. **Phase 8**: Final summary (complete documentation)

**Result**: `.claude-project/tasks/AUTH-123/` with:
- TASK.md (business spec)
- SYSTEM-DESIGN.md (architecture)
- tests/ (auto-generated integration tests)
- SUMMARY.md (complete progress report)

### Check Task Status

```bash
/tasks
```

See dashboard of all tasks with status, branch, and current phase.

### Create Worktrees for Parallel Development

```bash
# Create worktree for V-39 task
/worktree V-39

# Navigate and develop
cd ../your-project-V-39
npm install
npm start  # PORT=3001 (auto-configured!)

/do TASK-2 "Another feature"
```

**Now you can**:
- Run both tasks simultaneously (different PORTs)
- Switch between worktrees seamlessly
- See all tasks from any worktree (/tasks)

## Key Features

### 🎯 Branch-Aware Workflow

- **Per-branch documentation**: Each major branch (main, develop, V-37) can have its own docs
- **Task branches use parent docs**: Task branches (V-39, TASK-123) don't need separate docs
- **Git metadata tracking**: Every task knows its branch, parent, and merge base
- **Parent divergence detection**: Auto-detects when parent branch moved ahead
- **Smart rebase/merge**: Offers to update task branch when parent changes

### 💡 Token Optimization

- **DIFF MODE**: 90% output token savings (copy parent docs + edit only changes)
- **Task branches**: 100% savings (use parent docs, don't create own)
- **Efficient**: Scales to many branches without token explosion

### 🔄 Worktree Support

- **Auto-sync**: .claude-project/ synced across all worktrees automatically
- **Environment config**: .env copied with auto PORT configuration
- **Project configs**: .claude/ directory copied (commands, agents, skills, CLAUDE.md)
- **Conflict-free**: Multiple worktrees with different PORTs run simultaneously

### ✅ Quality Assurance

- **8-phase workflow**: Structured development from analysis to tests
- **Auto-generated tests**: Integration tests based on specs
- **Iterative bug fixing**: Bug hunter runs until no P0 bugs (max 5 iterations)
- **Code cleanliness**: Automated quality checks
- **Checkpoint resume**: Can interrupt and continue from any phase

### 🔍 Automatic Checks (SessionStart Hook)

On every Claude Code startup:
- **Unpulled changes**: Detects when remote is ahead of local
- **Outdated tasks**: Detects when parent branch moved ahead
- **Proactive suggestions**: Claude suggests `git pull && /init-project` or `/do <task>` (rebase)

## Project Structure

After using this marketplace:

```
your-project/
├── .claude-project/
│   ├── project/
│   │   ├── main/              # Main branch docs (INIT MODE)
│   │   ├── V-37/              # Version branch docs (DIFF MODE)
│   │   └── develop/           # Develop branch docs (DIFF MODE)
│   └── tasks/
│       ├── AUTH-123/          # Task with full documentation
│       │   ├── TASK.md
│       │   ├── SYSTEM-DESIGN.md
│       │   ├── SUMMARY.md
│       │   └── tests/         # Auto-generated
│       └── PAY-456/
│
├── .env (PORT=3000)
└── [source code]

Worktrees (sibling directories):
../your-project-V-39/  (PORT=3001)  # Task worktree
../your-project-V-40/  (PORT=3002)  # Another task
```

## Workflow Example

```bash
# Day 1: Setup
cd ~/project
/init-project
# → .claude-project/project/main/ created

# Day 2: Feature A
/worktree feature-auth
cd ../project-feature-auth
npm install && npm start  # PORT=3001
/do AUTH-123 "JWT authentication"
# → 8 phases → complete

# Day 3: Feature B (parallel)
cd ~/project
/worktree feature-payments
cd ../project-feature-payments
npm start  # PORT=3002
/do PAY-456 "Stripe integration"
# → Both features developed independently!

# Day 4: Check status
/tasks
# Shows: AUTH-123 ✅ Done, PAY-456 🔄 Active (Phase 5)

# Day 5: Sync check (SessionStart hook)
# → Hook detects main 3 commits behind remote
# → Claude suggests: git pull origin main && /init-project
```

## Documentation

### Plugin Documentation
- [tasks-execution Plugin](./plugins/tasks-execution/README.md)
- [worktree Plugin](./plugins/worktree/README.md)

### Detailed Guides
Located in each plugin's `docs/` directory.

## Requirements

- **Claude Code**: Latest version
- **Git**: For worktree support
- **Node.js**: For test execution
- **rsync**: For intelligent worktree sync

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

- Issues: [GitHub Issues](https://github.com/tesoldofficial/claude-nodejs/issues)
- Discussions: [GitHub Discussions](https://github.com/tesoldofficial/claude-nodejs/discussions)

## License

MIT License - see [LICENSE.md](./LICENSE.md)

## Author

**tesold**

---

**Version**: 1.0.0
**Repository**: https://github.com/tesoldofficial/claude-nodejs
**Marketplace for**: Claude Code
