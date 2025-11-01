---
description: Initialize project structure with comprehensive documentation
---

# Project Initialization

You are tasked with initializing or synchronizing a comprehensive project structure and documentation system.

## Mode Detection - CRITICAL FIRST STEP

### Step 1: Get Current Git Branch

```bash
currentBranch = $(git branch --show-current 2>/dev/null || echo "not-a-git-repo")

if [ "$currentBranch" = "not-a-git-repo" ]; then
  echo "⚠️  Not a git repository - documentation will not be branch-specific"
  documentationPath = ".claude-project/project"
else
  echo "📍 Current branch: ${currentBranch}"
  documentationPath = ".claude-project/project/${currentBranch}"
fi
```

### Step 2: Check Documentation State

**Per-branch documentation structure:**
```
.claude-project/project/
├── main/              # Docs for main branch
│   ├── ABOUT.md
│   ├── business/
│   └── architecture/
├── feature-auth/      # Docs for feature-auth branch
│   ├── ABOUT.md
│   ├── business/
│   └── architecture/
└── develop/           # Docs for develop branch
    └── ...
```

**Check multiple conditions:**

```bash
# Check 1: Does documentation exist for current branch?
ls -la ${documentationPath}/ 2>/dev/null

currentBranchHasDocs = $?  # 0 if exists, non-zero if not

# Check 2: Do docs exist for other branches?
otherBranches = $(ls -d .claude-project/project/*/ 2>/dev/null | grep -v "${currentBranch}")

otherBranchDocs = [ -n "$otherBranches" ]  # true if other branch docs exist
```

### Step 3: Determine Mode

**Decision tree:**

```
┌─ Current branch has docs?
│
├─ YES → SYNC MODE
│         (update existing docs for current branch)
│
└─ NO → Check if other branch docs exist
        │
        ├─ YES → DIFF MODE
        │         (create docs based on diff from parent branch docs)
        │
        └─ NO → INIT MODE
                  (create fresh docs from scratch)
```

**Mode selection logic:**

```bash
if [ $currentBranchHasDocs -eq 0 ]; then
  mode="SYNC"
  echo "📄 Mode: SYNC - Documentation exists for ${currentBranch}"
  echo "   Will synchronize with current codebase"

elif [ $otherBranchDocs = true ]; then
  mode="DIFF"
  echo "📄 Mode: DIFF - Documentation exists for other branches"
  echo "   Will create docs for ${currentBranch} based on changes from parent"

else
  mode="INIT"
  echo "📄 Mode: INIT - No documentation found"
  echo "   Will create fresh documentation"
fi
```

**Go to appropriate mode section:**
- **SYNC MODE**: [Jump to SYNC MODE](#sync-mode-update-existing-documentation)
- **DIFF MODE**: [Jump to DIFF MODE](#diff-mode-create-docs-from-branch-diff)
- **INIT MODE**: [Jump to INIT MODE](#init-mode-create-new-documentation)

---

## SYNC MODE: Update Existing Documentation

**Trigger**: Documentation exists for current branch (`${documentationPath}/` exists)

### Your Task in Sync Mode

Ensure documentation reflects the current state of the codebase by finding and fixing discrepancies.

### Sync Workflow

#### 1. Read All Existing Documentation

Read every documentation file for current branch:
- `${documentationPath}/ABOUT.md`
- `${documentationPath}/business/*.md`
- `${documentationPath}/architecture/*.md`
- `${documentationPath}/CONVENTIONS.md`
- `${documentationPath}/SETUP.md`

Create a mental model of what the documentation CLAIMS the project is.

#### 2. Analyze Current Codebase Implementation

Thoroughly explore the actual codebase:

**Use Task tool with Explore agent:**
- Understand actual project structure
- Identify real technology stack
- Find actual architectural patterns
- Discover real data models
- Map actual API endpoints
- Understand real data flows

**Key files to examine:**
- `package.json` / `requirements.txt` / etc - actual dependencies
- Config files - actual infrastructure setup
- Database models/entities - actual data schema
- API controllers/routes - actual endpoints
- Service layer - actual business logic
- README - any implementation notes

#### 3. Find Discrepancies

Compare documentation vs. reality. Look for:

**Technology Stack Mismatches:**
- Documentation says "PostgreSQL" but code uses "MongoDB"
- Documentation says "NestJS" but it's actually "Express"
- Documented dependencies that don't exist in package.json

**Architecture Mismatches:**
- Documentation describes layered architecture, code is actually flat
- Documented patterns not actually used
- Components described in docs don't exist in code

**Data Model Mismatches:**
- Entities documented but not in database
- Fields in code not in documentation
- Relationships incorrectly described

**API Mismatches:**
- Endpoints documented but don't exist
- Endpoints exist but not documented
- Different request/response formats than documented

**Business Logic Mismatches:**
- Workflows described differently than implemented
- Features documented as complete but not in code
- Features in code not documented

**Infrastructure Mismatches:**
- Deployment process different than documented
- Environment variables don't match
- CI/CD pipeline different

#### 4. Create Discrepancy Report

Before making changes, create a report using TodoWrite:

```markdown
## Documentation Sync - Discrepancies Found

### Technology Stack
- ❌ DOCS: PostgreSQL | REALITY: MongoDB
- ❌ DOCS: NestJS | REALITY: Express.js
- ✅ DOCS: TypeScript | REALITY: TypeScript (correct)

### Architecture
- ❌ DOCS: Repository pattern | REALITY: Direct DB access
- ❌ DOCS: 3-layer architecture | REALITY: Controllers + Services only

### Data Model
- ❌ DOCS: User.profileImage field | REALITY: Doesn't exist
- ⚠️  DOCS: Missing Order.trackingNumber | REALITY: Field exists

### API Endpoints
- ❌ DOCS: GET /api/users/:id | REALITY: Endpoint removed
- ⚠️  DOCS: Missing POST /api/orders/cancel | REALITY: Exists

### Business Logic
- ❌ DOCS: Email verification required | REALITY: Optional
- ❌ DOCS: Payment with Stripe | REALITY: Uses PayPal

[Continue for all areas...]
```

#### 5. Ask User for Guidance

Use AskUserQuestion to clarify intent:

**Present discrepancies and ask:**
- "I found X discrepancies. Should I update docs to match code, or is code wrong?"
- "Feature Y is documented but not implemented. Should I remove from docs or mark as [Planned]?"
- "Database schema differs from docs. Which is the source of truth?"

#### 6. Update Documentation

Based on user guidance and code analysis:

**For outdated information:**
- Update to match current implementation
- Add note: "Updated YYYY-MM-DD - synced with actual implementation"

**For missing information:**
- Add sections describing features found in code
- Mark new sections: "Added YYYY-MM-DD - discovered in codebase"

**For removed features:**
- Remove from docs or move to "Deprecated" section
- Add note explaining removal

**For planned but unimplemented features:**
- Mark clearly as `[Planned]` or `[In Development]`
- Don't claim they exist if they don't

#### 7. Update Timestamps

Update "Last updated" in every modified file with current date.

#### 8. Verify Accuracy

Final check:
- [ ] All tech stack matches package.json/requirements.txt
- [ ] All documented endpoints exist in code
- [ ] All database entities match models
- [ ] All architectural patterns actually used
- [ ] All business logic matches implementation
- [ ] No phantom features (documented but don't exist)
- [ ] No undocumented features (exist but not in docs)

### Sync Mode Quality Checklist

- [ ] Read all existing documentation
- [ ] Analyzed actual codebase thoroughly
- [ ] Created discrepancy report
- [ ] Asked user for guidance on conflicts
- [ ] Updated all outdated information
- [ ] Added missing information from code
- [ ] Removed/marked non-existent features
- [ ] Updated all timestamps
- [ ] Verified documentation now matches reality
- [ ] No false claims remain in docs

---

## DIFF MODE: Create Docs from Branch Diff

**Trigger**: Current branch has NO docs, but other branches HAVE docs

### Your Task in Diff Mode

Create documentation for current branch by analyzing changes from parent branch.

### Diff Workflow

#### 1. Identify Parent Branch

**Find which branch this one was created from:**

```bash
# Method 1: Check git reflog
parentBranch = $(git reflog show ${currentBranch} | grep 'branch.*from' | head -1 | sed 's/.*from //' | awk '{print $1}')

# Method 2: Ask user if unclear
if [ -z "$parentBranch" ]; then
  # List available branches with docs
  availableBranches = $(ls -d .claude-project/project/*/ | xargs -n 1 basename)

  AskUserQuestion:
    Question: "Which branch is ${currentBranch} based on?"
    Options: [dynamically generated from availableBranches]
    # e.g., main, develop, feature-x
fi

echo "📍 Parent branch identified: ${parentBranch}"
```

#### 2. Read Parent Branch Documentation

```bash
parentDocsPath = ".claude-project/project/${parentBranch}"

if [ ! -d "$parentDocsPath" ]; then
  echo "⚠️  WARNING: Parent branch ${parentBranch} has no documentation!"
  echo "   Falling back to INIT MODE"
  mode = "INIT"
  # Jump to INIT MODE
else
  echo "📖 Reading parent branch documentation: ${parentDocsPath}/"

  # Read all parent docs
  parentDocs = {
    about: read(${parentDocsPath}/ABOUT.md),
    business: {
      overview: read(${parentDocsPath}/business/OVERVIEW.md),
      requirements: read(${parentDocsPath}/business/REQUIREMENTS.md),
      userJourneys: read(${parentDocsPath}/business/USER-JOURNEYS.md)
    },
    architecture: {
      overview: read(${parentDocsPath}/architecture/OVERVIEW.md),
      systemDesign: read(${parentDocsPath}/architecture/SYSTEM-DESIGN.md),
      dataModel: read(${parentDocsPath}/architecture/DATA-MODEL.md),
      apiDesign: read(${parentDocsPath}/architecture/API-DESIGN.md),
      infrastructure: read(${parentDocsPath}/architecture/INFRASTRUCTURE.md)
    },
    conventions: read(${parentDocsPath}/CONVENTIONS.md),
    setup: read(${parentDocsPath}/SETUP.md)
  }

  echo "✅ Parent documentation loaded"
fi
```

#### 3. Analyze Git Diff Between Branches

```bash
# Get comprehensive diff from parent to current branch
git diff ${parentBranch}...${currentBranch} > /tmp/branch-diff.patch

# Get commit history
git log ${parentBranch}..${currentBranch} --oneline > /tmp/commits-list.txt

# Get changed files summary
git diff ${parentBranch}...${currentBranch} --stat > /tmp/files-stat.txt

echo ""
echo "📊 Branch Diff Analysis:"
echo "   Parent: ${parentBranch}"
echo "   Current: ${currentBranch}"
echo "   Commits ahead: $(git rev-list --count ${parentBranch}..${currentBranch})"
echo "   Files changed: $(git diff ${parentBranch}...${currentBranch} --name-only | wc -l)"
echo ""
```

#### 4. Categorize Changes

**Analyze what changed between branches:**

Use Explore agent or manual analysis to categorize:

```markdown
**Technology Stack Changes:**
- New dependencies added to package.json?
- Framework version upgrades?
- New libraries introduced?

**Architecture Changes:**
- New services/modules created?
- Existing services modified significantly?
- New architectural patterns introduced?

**Data Model Changes:**
- New entities/tables?
- Schema migrations?
- New fields in existing entities?

**API Changes:**
- New endpoints?
- Modified endpoints?
- Removed endpoints?
- Changed request/response formats?

**Business Logic Changes:**
- New features implemented?
- Existing workflows modified?
- New business rules?

**Infrastructure Changes:**
- New environment variables?
- Deployment config changes?
- CI/CD pipeline updates?
```

#### 5. Create Documentation for Current Branch

**Create new documentation in `${documentationPath}/` based on:**
- **Parent docs** as base (copy unchanged sections)
- **Git diff** for identifying changes
- **Commit messages** for understanding intent

```bash
# Create directory structure
mkdir -p ${documentationPath}/{business,architecture}

# For each documentation file:
# 1. Copy from parent if section unchanged
# 2. Update if section modified
# 3. Add if section is new
# 4. Mark all changes with timestamps
```

#### 6. Update Strategy Per File

**ABOUT.md:**
```markdown
# [Copy project name from parent - likely unchanged]

> [Copy tagline - likely unchanged]

## Quick Overview

[Update if significant features added, otherwise copy from parent]

## Documentation Map

[Same structure as parent]

## Project Status

[UPDATE THIS - current branch focus]

- **Phase**: [Update based on branch purpose]
- **Current Focus**: [What this branch is working on]
- **Next Milestone**: [Branch-specific goals]

## Branch Context

**Current Branch**: `${currentBranch}`
**Parent Branch**: `${parentBranch}`
**Diverged**: ${commitsAhead} commits ahead
**Key Changes**: [Summary of major changes in this branch]

## Documentation Metadata

- **Initialized**: [Date] from branch `${currentBranch}`
- **Based on**: Documentation from `${parentBranch}` branch
- **Last updated**: [Date]

---

> This documentation reflects the state of the `${currentBranch}` branch.
> For parent branch state, see `.claude-project/project/${parentBranch}/`
```

**business/OVERVIEW.md:**
- **IF** business goals changed in this branch → Update business context
- **ELSE** → Copy from parent + add note:
  ```markdown
  > Inherited from parent branch `${parentBranch}` - no business changes in this branch
  ```

**business/REQUIREMENTS.md:**
- **IF** new requirements added → Add them with marker:
  ```markdown
  ## New Requirements in ${currentBranch}

  > Added in this branch

  - REQ-NEW-001: [New requirement from this branch]
  ```
- **Copy** unchanged requirements from parent

**architecture/SYSTEM-DESIGN.md:**
- **Analyze** which components changed (from git diff)
- **Update** only changed components
- **Copy** unchanged components from parent
- **Mark** new components:
  ```markdown
  ### NewService [Added in ${currentBranch}]

  > Added 2025-11-01 in branch ${currentBranch}
  ```

**architecture/DATA-MODEL.md:**
- **Check** migration files in git diff
- **Update** only modified entities
- **Add** new entities with marker
- **Copy** unchanged entities

**And so on for all files...**

#### 7. Verification

Final check:
- [ ] All directories created for ${currentBranch}
- [ ] Parent docs copied where appropriate
- [ ] Changes from git diff reflected in docs
- [ ] All new sections marked with branch context
- [ ] Branch metadata added to ABOUT.md
- [ ] Cross-links updated for current branch path
- [ ] No broken references

#### 8. Summary

```markdown
## DIFF MODE Summary

**Created documentation for**: `${currentBranch}` branch
**Based on**: `${parentBranch}` branch documentation
**Changes incorporated**: ${commitsAhead} commits, ${filesChanged} files

**Documentation path**: .claude-project/project/${currentBranch}/

**Changes documented**:
- [Change category 1]: [summary]
- [Change category 2]: [summary]

**Inherited from parent** (unchanged):
- [Section 1]
- [Section 2]

---

This documentation reflects branch-specific changes while inheriting
stable context from parent branch.
```

### Diff Mode Quality Checklist

- [ ] Parent branch identified correctly
- [ ] Parent docs read successfully
- [ ] Git diff analyzed comprehensively
- [ ] Changed sections updated in new docs
- [ ] Unchanged sections copied from parent
- [ ] New additions marked with branch context
- [ ] Branch metadata added
- [ ] Cross-links work for current branch
- [ ] No duplicate content from parent

---

## INIT MODE: Create New Documentation

**Trigger**: No documentation exists for any branch

### Your Task in Init Mode

Create a complete project documentation system by:

### 0. Capture Initialization Context

**Current branch** (already captured in Mode Detection step):
- Branch: `${currentBranch}`
- Documentation path: `${documentationPath}`

Save this information to include in documentation metadata:
- **Initialized from branch**: `${currentBranch}`
- **Initialization date**: {current-date}

This helps track project context and evolution across branches.

### 1. Create Directory Structure

Create the following directories:
- `.claude-project/tasks/` - for task management and tracking
- `${documentationPath}/` - for project documentation (branch-specific)
- `${documentationPath}/business/` - for business requirements and context
- `${documentationPath}/architecture/` - for technical architecture and design

**Example for branch `main`:**
```
.claude-project/
├── tasks/
└── project/
    └── main/
        ├── business/
        └── architecture/
```

### 2. Update .gitignore

Add `.claude-project/` to the project's `.gitignore` file. If `.gitignore` doesn't exist, create it.

### 3. Gather Project Information Interactively

Use the AskUserQuestion tool to collect comprehensive information about the project:

**First round - Business Context:**
- What is the primary business goal of this project?
- Who are the target users/customers?
- What key problem does this solve?
- What is the expected business value?

**Second round - Technical Context:**
- What is the technology stack?
- What are the key architectural patterns used?
- What are the main external integrations?
- What are critical constraints (performance, security, compliance)?

**Third round - Current State:**
- What is the current project phase? (planning/development/production)
- What are the immediate priorities?
- What are known technical debts or challenges?
- What features are planned next?

### 4. Create Modular Documentation

Based on the gathered information, create a comprehensive, interconnected documentation structure:

#### 4.1 Main Entry Point: `ABOUT.md`

Create `${documentationPath}/ABOUT.md` with:
- Project name and tagline
- Quick overview (2-3 sentences)
- Links to all other documentation modules
- Quick navigation table of contents
- Branch metadata (current branch, initialization date)

#### 4.2 Business Documentation

Create in `${documentationPath}/business/`:

**`OVERVIEW.md`**:
- Customer/stakeholder identification
- Primary business goals
- Key business value propositions
- Target user personas
- Success metrics

**`REQUIREMENTS.md`**:
- Functional requirements (grouped by feature area)
- Non-functional requirements (performance, security, etc.)
- Business constraints and limitations
- Compliance requirements

**`USER-JOURNEYS.md`**:
- Key user workflows
- User pain points being addressed
- User expectations and needs
- Edge cases from user perspective

#### 4.3 Technical Architecture Documentation

Create in `${documentationPath}/architecture/`:

**`OVERVIEW.md`**:
- Technology stack
- High-level architecture diagram (as ASCII art or Markdown)
- Key architectural patterns
- Design principles followed

**`SYSTEM-DESIGN.md`**:
- System components and their responsibilities
- Data flow between components
- Integration points (APIs, databases, external services)
- Authentication and authorization flows

**`DATA-MODEL.md`**:
- Database schema
- Key entities and relationships
- Data constraints and validations
- Migration strategy

**`API-DESIGN.md`** (if applicable):
- API endpoints
- Request/response formats
- Error handling patterns
- Rate limiting and security

**`INFRASTRUCTURE.md`**:
- Deployment architecture
- Environment configurations
- CI/CD pipeline
- Monitoring and logging

#### 4.4 Development Documentation

Create in `${documentationPath}/`:

**`CONVENTIONS.md`**:
- Coding standards
- Naming conventions
- File organization patterns
- Code review guidelines

**`SETUP.md`**:
- Development environment setup
- Required dependencies
- Environment variables
- Local development workflow

### 5. Implementation Guidelines

When creating documentation:

**Use Markdown features effectively:**
- Use headers for hierarchy
- Use tables for structured data
- Use code blocks for examples
- Use links to connect related documents

**Make it modular:**
- Each file should be focused on one aspect
- Files should reference each other with relative links
- Keep files under 300 lines for readability
- Use `See [Filename](./path/to/file.md)` for cross-references

**Make it actionable:**
- Include concrete examples
- Provide rationale for decisions
- Document trade-offs considered
- Note future considerations

**Keep it current:**
- Add "Last updated" timestamp
- Note what sections need expansion
- Mark uncertain/TBD items clearly

### 6. Example ABOUT.md Structure

```markdown
# Project Name

> Brief tagline describing the project

## Quick Overview

[2-3 sentences describing what this project does and why it exists]

## Documentation Map

### Business Context
- [Business Overview](./business/OVERVIEW.md) - Customer needs and business goals
- [Requirements](./business/REQUIREMENTS.md) - Functional and non-functional requirements
- [User Journeys](./business/USER-JOURNEYS.md) - Key workflows and user expectations

### Technical Architecture
- [Architecture Overview](./architecture/OVERVIEW.md) - System design and tech stack
- [System Design](./architecture/SYSTEM-DESIGN.md) - Components and data flow
- [Data Model](./architecture/DATA-MODEL.md) - Database schema and entities
- [API Design](./architecture/API-DESIGN.md) - Endpoints and contracts
- [Infrastructure](./architecture/INFRASTRUCTURE.md) - Deployment and operations

### Development
- [Conventions](./CONVENTIONS.md) - Coding standards and patterns
- [Setup Guide](./SETUP.md) - Getting started with development

## Project Status

- **Phase**: [Planning/Development/Production]
- **Current Focus**: [What's being worked on now]
- **Next Milestone**: [Upcoming goals]

## Documentation Metadata

- **Initialized**: [Date] from branch `[branch-name]`
- **Last updated**: [Date]
- **Documentation initialized by**: Claude Code `/init` command

---

*Generated with Claude Code*
```

## Execution Strategy

1. **Create all directories first** using mkdir commands
2. **Update .gitignore** using Edit or Write tool
3. **Gather information interactively** - ask all questions, wait for answers
4. **Analyze responses** - understand the project deeply before writing
5. **Create documentation** - start with ABOUT.md, then create all referenced files
6. **Cross-link everything** - ensure all documents reference each other appropriately
7. **Review completeness** - verify all sections are addressed

## Important Notes

- **Be thorough** - This is a detailed, time-consuming task. Take your time.
- **Be interactive** - Use AskUserQuestion liberally to gather accurate information
- **Be specific** - Fill documentation with actual project details, not placeholders
- **Think systemically** - Show how pieces connect
- **Maintain consistency** - Use same terminology throughout all documents
- **Be practical** - Include actionable information, not just theory

## Quality Checklist

Before completing, verify:
- [ ] All directories created
- [ ] .gitignore updated
- [ ] All user questions asked and answered
- [ ] ABOUT.md created with full navigation
- [ ] All referenced files actually exist
- [ ] Cross-links work correctly
- [ ] No placeholder/dummy content
- [ ] Documentation reflects actual project specifics
- [ ] Technical details match gathered information
- [ ] Business context is clear and complete
- [ ] Worktree sync completed (if applicable)

You have access to all tools. Use TodoWrite to track your progress through this multi-step process.

**Start by creating the directory structure and gathering initial project information.**

---

## FINAL STEP (ALL MODES): Sync to Git Worktrees

**CRITICAL**: After creating/updating documentation, sync to all git worktrees.

### Execute Worktree Sync

```bash
# Run worktree sync helper
~/.claude/hooks/sync-worktree-claude-project.sh

# This will:
# 1. Detect all git worktrees of this repository
# 2. Sync .claude-project/ to each worktree
# 3. Use rsync for intelligent sync (only changed files)
# 4. Report summary of sync operation
```

**What gets synced:**
- All documentation files (.claude-project/project/*)
- All task files (.claude-project/tasks/*)
- Configuration files
- Templates

**What does NOT get synced:**
- Temporary files (*.tmp, *.swp)
- node_modules in tests/
- .env.test (user-specific credentials)

**Example output:**
```
🔄 Syncing .claude-project across 3 worktrees...

📋 fea-V-37: Syncing changes...
   ✅ Synced 5 file(s)
      - project/main/ABOUT.md
      - project/main/architecture/OVERVIEW.md
      - tasks/AUTH-123/SUMMARY.md
      - tasks/AUTH-123/TASK.md
      - tasks/AUTH-123/SYSTEM-DESIGN.md

📋 fea-v36: Already in sync
   ℹ️  Already in sync

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Worktree Sync Summary:
  Total worktrees: 3
  Synced: 1
  Already in sync: 1
  Errors: 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If sync fails:**
- Command continues anyway (doesn't block)
- Error logged but not critical
- User can manually sync later

**Why this is important:**
When working with git worktrees, each worktree is a separate working directory but shares the same git repository. Without sync:
- Documentation in worktree A is invisible to Claude in worktree B
- Tasks created in one worktree don't show in /tasks in another
- Inconsistent state across worktrees

With sync:
- All worktrees have same .claude-project/
- Documentation always accessible
- Tasks visible everywhere
- Consistent experience

**Note**: Sync is one-way from current worktree to others. If you make changes in another worktree, run /init or /do there to propagate back.
