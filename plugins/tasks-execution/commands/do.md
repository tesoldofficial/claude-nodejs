---
description: Complete task development workflow from business analysis to tested implementation
---

# Task Development Workflow (/do)

Complete end-to-end task implementation: business analysis → architecture → coding → bug hunting → testing.

## CRITICAL: Mode Detection and Input Validation

### Step 1: Parse Command Arguments

```
/do <task-name> [description or "начни заново"]
```

**Examples**:
- `/do AUTH-123` - Resume existing or start new
- `/do AUTH-123 Implement JWT authentication` - Start with description
- `/do AUTH-123 начни заново` - Restart existing task from scratch
- `/do user-login` - Start new task (no description)

### Step 2: Validate Task Name

**CRITICAL**: Check if `<task-name>` is actually a description (invalid):

```javascript
function isTaskDescription(name) {
  // Invalid if:
  // - Too long (> 50 chars)
  // - Starts with action verb in full form
  // - Contains punctuation (except hyphen)
  // - Full sentence structure

  const actionVerbs = /^(Реализовать|Реализуй|Add|Fix|Implement|Create|Update|Delete|Remove|Исправить|Добавить|Создать|Удалить)\s/i;
  const hasPunctuation = /[.,!?;:]/;
  const tooLong = name.length > 50;
  const isFullSentence = actionVerbs.test(name) && name.split(/\s+/).length > 3;

  return tooLong || isFullSentence || hasPunctuation.test(name);
}
```

**If invalid (user passed description as task name)**:

```markdown
❌ ERROR: Передано описание задачи вместо названия

Вы передали: "{input}"

Это похоже на описание задачи, а не на название.

Валидные названия задач (короткие идентификаторы):
  ✅ AUTH-123
  ✅ user-login
  ✅ fix-auth-bug
  ✅ V-37

Невалидные (это описания):
  ❌ "Реализовать логин пользователя"
  ❌ "Add JWT authentication to the API"
  ❌ "Fix the bug in authentication flow"

Пожалуйста, используйте формат:
  /do <короткое-название> "Описание задачи"

Например:
  /do AUTH-123 "Реализовать JWT авторизацию с refresh токенами"
```

**STOP execution** if validation fails.

### Step 3: Get Current Git Branch

```bash
currentBranch = $(git branch --show-current 2>/dev/null || echo "not-a-git-repo")

if [ "$currentBranch" = "not-a-git-repo" ]; then
  echo "⚠️  WARNING: Not a git repository"
  echo "   Git branch tracking will be disabled"
fi
```

### Step 4: Check for "Restart" Command

```javascript
const restartKeywords = /начни\s+заново|start\s+over|restart|reset|с\s+нуля/i;

if (description && restartKeywords.test(description)) {
  isRestart = true;
}
```

### Step 5: Check Existing Task and Branch

```bash
ls -la .claude-project/tasks/{task-name}/ 2>/dev/null
```

**If exists AND isRestart = true:**
```bash
# Backup old version
mv .claude-project/tasks/{task-name} .claude-project/tasks/{task-name}-backup-$(date +%Y%m%d-%H%M%S)

# Create fresh directory
mkdir -p .claude-project/tasks/{task-name}/{files,tests}

# Start from Phase 0
currentPhase = 0
```

**If exists AND isRestart = false:**
```bash
# Resume from checkpoint
# Read SUMMARY.md to determine current phase
currentPhase = readCheckpoint(.claude-project/tasks/{task-name}/SUMMARY.md)

# CRITICAL: Branch Validation
# Read git branch from TASK.md metadata
taskBranch = extractBranchFromTaskMd(.claude-project/tasks/{task-name}/TASK.md)

if [ "$currentBranch" != "not-a-git-repo" ] && [ "$taskBranch" != "not-a-git-repo" ]; then
  if [ "$currentBranch" != "$taskBranch" ]; then
    echo ""
    echo "⚠️  WARNING: Git branch mismatch detected!"
    echo ""
    echo "Task was started in branch: ${taskBranch}"
    echo "You are currently in branch: ${currentBranch}"
    echo ""
    echo "This may cause issues if:"
    echo "  - Code from different branches is incompatible"
    echo "  - Tests expect specific branch state"
    echo ""

    AskUserQuestion:
      Question: "Branch mismatch detected. How to proceed?"
      Options:
        - "Switch to task branch (${taskBranch})" → git checkout ${taskBranch}, then continue
        - "Continue in current branch (${currentBranch})" → Update TASK.md with new branch, continue
        - "Cancel task" → Stop execution

    # Handle user choice
    if (choice == "switch") {
      git checkout ${taskBranch}
      currentBranch = ${taskBranch}
    } else if (choice == "continue") {
      # Update TASK.md with new branch
      updateTaskMdBranch(${currentBranch})
      echo "ℹ️  Updated task to continue in branch: ${currentBranch}"
    } else {
      exit 0
    }
  else
    echo "✅ Branch matches: ${currentBranch}"
  fi
fi
```

**If NOT exists:**
```bash
# New task - offer to create git branch

if [ "$currentBranch" != "not-a-git-repo" ]; then
  echo ""
  echo "📋 Starting new task: {task-name}"
  echo "   Current branch: ${currentBranch}"
  echo ""

  # Suggest branch name based on task-name
  suggestedBranch="feature/{task-name}"

  # If already in a feature branch, don't suggest creating another
  if [[ "$currentBranch" == feature/* ]] || [[ "$currentBranch" == fix/* ]]; then
    echo "ℹ️  Already in a feature/fix branch: ${currentBranch}"
    echo "   Will continue in current branch"
    taskBranch = ${currentBranch}
  else
    AskUserQuestion:
      Question: "Create a new git branch for this task?"
      Options:
        - "Yes, create ${suggestedBranch}" → git checkout -b ${suggestedBranch}
        - "Yes, but custom name" → Prompt for branch name, create it
        - "No, continue in ${currentBranch}" → Stay in current branch

    # Handle user choice
    if (choice == "suggested") {
      # Save parent branch before creating new one
      parentBranch = ${currentBranch}

      git checkout -b ${suggestedBranch}
      taskBranch = ${suggestedBranch}
      echo "✅ Created and switched to branch: ${suggestedBranch}"
      echo "   Parent branch: ${parentBranch}"
    } else if (choice == "custom") {
      # Save parent branch
      parentBranch = ${currentBranch}

      # Get custom branch name from user
      customBranch = getUserInput("Enter branch name:")
      git checkout -b ${customBranch}
      taskBranch = ${customBranch}
      echo "✅ Created and switched to branch: ${customBranch}"
      echo "   Parent branch: ${parentBranch}"
    } else {
      taskBranch = ${currentBranch}
      parentBranch = ${currentBranch}  # Same branch (no branching)
      echo "ℹ️  Continuing in branch: ${currentBranch}"
    }
  fi
else
  taskBranch = "not-a-git-repo"
  parentBranch = "not-a-git-repo"
fi

# Create new task structure
mkdir -p .claude-project/tasks/{task-name}/{files,tests}

# Determine merge base (last common commit with parent)
if [ "$parentBranch" != "not-a-git-repo" ] && [ "$parentBranch" != "$taskBranch" ]; then
  mergeBase = $(git merge-base ${parentBranch} ${taskBranch})
  mergeBaseShort = $(git rev-parse --short ${mergeBase})

  echo "📍 Merge base: ${mergeBaseShort}"
  echo "   (last common commit with ${parentBranch})"
else
  mergeBase = "not-applicable"
  mergeBaseShort = "not-applicable"
fi

# Save git metadata for future reference
gitMetadata = {
  taskBranch: ${taskBranch},
  parentBranch: ${parentBranch},
  mergeBase: ${mergeBase},
  createdAt: $(date -Iseconds)
}

# Start from Phase 0
currentPhase = 0
```

---

## PHASE 0: Business Analysis (Plan Mode)

**Goal**: Fully understand the task before any implementation.

**Trigger**: currentPhase == 0

### Step 0: Check Parent Branch Divergence

**IMPORTANT**: Verify parent branch hasn't moved ahead since task creation.

```bash
if [ "$parentBranch" != "not-a-git-repo" ] && [ -n "$mergeBase" ] && [ "$mergeBase" != "not-applicable" ]; then
  # Check if parent branch has new commits since task started
  parentHead = $(git rev-parse ${parentBranch})

  if [ "$parentHead" != "$mergeBase" ]; then
    # Parent has moved ahead
    commitsAhead = $(git rev-list --count ${mergeBase}..${parentBranch})

    echo ""
    echo "⚠️  NOTICE: Parent branch has moved ahead!"
    echo ""
    echo "   Parent branch: ${parentBranch}"
    echo "   Task created from commit: ${mergeBaseShort}"
    echo "   Parent branch now at: $(git rev-parse --short ${parentBranch})"
    echo "   Commits ahead: ${commitsAhead}"
    echo ""
    echo "This means parent branch has ${commitsAhead} new commits."
    echo "Your task branch may be out of sync."
    echo ""

    AskUserQuestion:
      Question: "Parent branch has ${commitsAhead} new commits. Update task branch?"
      Options:
        - "Yes, rebase onto ${parentBranch}" → Rebase and update merge base
        - "Yes, merge ${parentBranch}" → Merge and update merge base
        - "No, continue with old baseline" → Keep original merge base
        - "Cancel task" → Exit

    if (choice == "rebase") {
      echo "🔄 Rebasing ${taskBranch} onto ${parentBranch}..."
      git rebase ${parentBranch}

      if [ $? -eq 0 ]; then
        echo "✅ Rebase successful"
        mergeBase = $(git merge-base ${parentBranch} ${taskBranch})
        mergeBaseShort = $(git rev-parse --short ${mergeBase})
        # Update TASK.md
        updateTaskMdMergeBase(${mergeBase})
      else
        echo "❌ Rebase failed - resolve conflicts manually"
        exit 1
      fi

    } else if (choice == "merge") {
      echo "🔀 Merging ${parentBranch} into ${taskBranch}..."
      git merge ${parentBranch}

      if [ $? -eq 0 ]; then
        echo "✅ Merge successful"
        mergeBase = $(git merge-base ${parentBranch} ${taskBranch})
        mergeBaseShort = $(git rev-parse --short ${mergeBase})
        # Update TASK.md
        updateTaskMdMergeBase(${mergeBase})
      else
        echo "❌ Merge failed - resolve conflicts manually"
        exit 1
      fi

    } else if (choice == "continue") {
      echo "ℹ️  Continuing with original merge base: ${mergeBaseShort}"
    } else {
      exit 0
    }
  else
    echo "✅ Parent branch unchanged since task creation"
  fi
fi
```

### Step 1: Check Project Documentation for Parent Branch

**IMPORTANT**: Verify project documentation exists for parent branch.

```bash
# Determine documentation path for parent branch
if [ "$parentBranch" != "not-a-git-repo" ]; then
  projectDocsPath = ".claude-project/project/${parentBranch}"
else
  projectDocsPath = ".claude-project/project"
fi

# Check if parent branch docs exist
if [ ! -f ${projectDocsPath}/ABOUT.md ]; then
  echo ""
  echo "⚠️  CRITICAL: Project documentation missing for parent branch!"
  echo ""
  echo "Required: ${projectDocsPath}/ABOUT.md"
  echo ""
  echo "Tasks must be developed in context of parent branch (${parentBranch})."
  echo "Without project documentation, task quality will be suboptimal."
  echo ""

  # Check if docs exist for other branches
  otherBranchDocs = $(ls -d .claude-project/project/*/ 2>/dev/null)

  if [ -n "$otherBranchDocs" ]; then
    echo "📄 Found documentation for other branches:"
    ls -d .claude-project/project/*/ | xargs -n 1 basename
    echo ""
  fi

  echo "Recommendation: Run /init-project for ${parentBranch} branch first."
  echo ""

  # Ask user what to do
  AskUserQuestion:
    Question: "Project documentation missing for ${parentBranch}. How to create it?"
    Options:
      - "Switch to ${parentBranch} and run /init-project" → Checkout parent, init, return
      - "Run /init-project based on another branch" → DIFF MODE from selected branch
      - "Continue without context (not recommended)" → Warning only
      - "Cancel task" → Exit

  if (choice == "switch-and-init") {
    echo "🔄 Switching to ${parentBranch}..."
    git checkout ${parentBranch}

    # Execute /init-project
    /init-project

    # Return to task branch
    git checkout ${taskBranch}
    projectDocsPath = ".claude-project/project/${parentBranch}"
    echo "✅ Returned to task branch: ${taskBranch}"

  } else if (choice == "init-from-other") {
    if [ -z "$otherBranchDocs" ]; then
      echo "❌ No other branch docs available"
      echo "   Please run /init-project in ${parentBranch} first"
      exit 1
    fi

    # List available branches
    availableBranches = $(ls -d .claude-project/project/*/ | xargs -n 1 basename)

    AskUserQuestion:
      Question: "Which branch docs to use as base for ${parentBranch}?"
      Options: [dynamically from availableBranches]

    selectedBase = {user choice}

    # Switch to parent branch
    git checkout ${parentBranch}

    # Run /init-project (will use DIFF MODE from selectedBase)
    /init-project

    # Return to task branch
    git checkout ${taskBranch}
    projectDocsPath = ".claude-project/project/${parentBranch}"

  } else if (choice == "continue") {
    echo "⚠️  WARNING: Proceeding without project context"
    projectDocsPath = null
  } else {
    exit 0
  }
else
  echo "✅ Found project documentation: ${projectDocsPath}/"
fi
```

### Step 2: Create or Read TASK.md

**If TASK.md exists:**
```bash
# Read existing task description
taskContent = read(.claude-project/tasks/{task-name}/TASK.md)
```

**If TASK.md does NOT exist:**
```bash
# Create from command description
if (description provided) {
  write(.claude-project/tasks/{task-name}/TASK.md):
    """
    # Task: {task-name}

    ## Git Metadata

    **Task Branch**: `${taskBranch}`
    **Parent Branch**: `${parentBranch}`
    **Created**: ${timestamp}

    > This task is developed relative to parent branch ${parentBranch}.
    > All changes: git diff ${parentBranch}...${taskBranch}
    > Project context: .claude-project/project/${parentBranch}/

    ---

    ## Initial Description
    {description from command}

    ## Status
    Draft - Needs detailed analysis

    ---
    *Created: {timestamp}*
    """
} else {
  # Ask user for task description
  AskUserQuestion:
    Question: "В чём заключается задача {task-name}?"
    [Free text input]

  # Write response to TASK.md with git metadata
}
```

### Step 3: Read Project Context from Parent Branch

```bash
if [ -n "$projectDocsPath" ] && [ "$projectDocsPath" != "null" ]; then
  echo "📖 Reading project context from parent branch documentation..."
  echo "   Path: ${projectDocsPath}/"

  # Read key context files
  projectContext = {
    business: read(${projectDocsPath}/business/OVERVIEW.md),
    architecture: read(${projectDocsPath}/architecture/OVERVIEW.md),
    techStack: read(${projectDocsPath}/architecture/OVERVIEW.md - tech stack section),
    conventions: read(${projectDocsPath}/CONVENTIONS.md)
  }

  echo "✅ Project context loaded from parent branch ${parentBranch}"
else
  echo "⚠️  No project context available"
  projectContext = null
fi
```

### Step 4: Iterative Business Analysis

**Use iterative reasoning from CLAUDE.md:**

```markdown
Iteration 1-20 (until complete clarity):

1. **Question Phase** (ask yourself):
   - What is the business goal? Who are the users?
   - What are the acceptance criteria?
   - What are edge cases from user perspective?
   - What dependencies exist (other tasks, APIs, data)?
   - What are technical constraints?
   - What's unclear or ambiguous?

2. **Hypothesis Phase** (try to answer):
   - Based on TASK.md, what can I infer?
   - Based on parent branch project docs (${projectDocsPath}/), what patterns fit?
   - Based on existing codebase (via Explore agent), what's already there?

3. **Critical Analysis**:
   - What assumptions am I making?
   - What could go wrong?
   - What alternatives exist?
   - Are there contradictions?

4. **Conclusion**:
   - Can I fully specify this task now?
   - If YES → Move to Step 4
   - If NO → Continue iteration OR ask user

5. **User Questions** (if stuck after 3-5 iterations):
   Use AskUserQuestion to clarify:
   - Ambiguous requirements
   - Missing business context
   - Technical choices (which library? which approach?)
   - Priority decisions
```

### Step 4: Finalize TASK.md

Update TASK.md with complete specification:

```markdown
# Task: {task-name}

## Git Metadata

**Task Branch**: `{taskBranch}`
**Parent Branch**: `{parentBranch}`
**Merge Base**: `{mergeBaseShort}` (last common commit with parent)
**Created**: {timestamp}

> All code analysis (bugs, tests, cleanliness) is relative to merge base.
> Git diff: `git diff {mergeBase}...{taskBranch}`
> Project context: `.claude-project/project/{parentBranch}/`

---

## Business Context

**Goal**: [What business problem this solves]

**Users**: [Who will use this feature]

**Value**: [Why this matters]

## Requirements

### Functional Requirements
1. [Requirement 1]
2. [Requirement 2]
...

### Non-Functional Requirements
- Performance: [criteria]
- Security: [requirements]
- Compatibility: [constraints]

## User Stories / Scenarios

### Scenario 1: [Happy Path]
**Given**: [precondition]
**When**: [user action]
**Then**: [expected result]

### Scenario 2: [Edge Case]
...

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
...

## Technical Constraints

- [Constraint 1]
- [Constraint 2]

## Dependencies

- Depends on: [other tasks, APIs, libraries]
- Blocks: [what this unblocks]

## Out of Scope

- [What this task does NOT include]

---
*Last updated: {timestamp}*
*Status: Ready for System Design*
```

### Step 5: Update SUMMARY.md (First Checkpoint)

```markdown
# Task {task-name} - Progress Summary

## Current Phase
**Status**: Completed
**Phase**: 0 - Business Analysis
**Started**: {timestamp}
**Completed**: {timestamp}

## Phase 0: Business Analysis ✅

**Duration**: {minutes} minutes
**Iterations**: {count}
**User Questions Asked**: {count}

**Output**:
- tasks/{task-name}/TASK.md - Complete business specification
- All requirements clarified and documented

**Key Decisions**:
- [Decision 1]
- [Decision 2]

**Next Phase**: System Design (Phase 1)

---
*Last updated: {timestamp}*
```

---

## PHASE 1: System Design

**Goal**: Create high-level technical architecture.

**Trigger**: currentPhase == 1 OR (currentPhase == 0 AND Phase 0 completed)

### Step 1: Launch system-designer Agent

```
Task tool with:
  subagent_type: system-designer
  description: "Design system for {task-name}"
  prompt: "
    Design technical architecture for the following task.

    Business Requirements: See .claude-project/tasks/{task-name}/TASK.md
    Project Context: See .claude-project/project/

    Create detailed technical specification at interface level:
    - Which services/classes to create/modify
    - Method signatures with parameters and return types
    - Data flow between components
    - Error handling strategy
    - Edge cases handling

    Output format: Structured Markdown document
  "
```

### Step 2: Save Output to SYSTEM-DESIGN.md

Agent output → `.claude-project/tasks/{task-name}/SYSTEM-DESIGN.md`

### Step 3: Update SUMMARY.md

```markdown
## Phase 1: System Design ✅

**Duration**: {minutes} minutes
**Agent**: system-designer
**Output**: tasks/{task-name}/SYSTEM-DESIGN.md

**Architecture Summary**:
- Services created: [count]
- DTOs/Interfaces: [count]
- Database changes: [Yes/No]
- API endpoints: [count]

**Key Design Decisions**:
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

**Next Phase**: Implementation (Phase 2)
```

---

## PHASE 2: Implementation

**Goal**: Write production-ready code per specification.

**Trigger**: currentPhase == 2

### Step 1: Launch code-implementer Agent

```
Task tool with:
  subagent_type: code-implementer
  description: "Implement {task-name}"
  prompt: "
    Implement the feature per the following specifications:

    Business Requirements: .claude-project/tasks/{task-name}/TASK.md
    Technical Design: .claude-project/tasks/{task-name}/SYSTEM-DESIGN.md
    Project Context: .claude-project/project/

    Follow all 10 code quality rules strictly:
    1. No unused parameters
    2. Methods under 50 lines
    3. Imports at top
    4. Clear naming
    5. Enums/Constants over magic strings
    6. NEVER use 'any' type
    7. Loops/Maps over repetitive if-else
    8. ConfigService over hardcoded env
    9. Decorators for cross-cutting concerns
    10. Additional quality checks

    Write clean, maintainable, tested code.
  "
```

### Step 2: Verify Implementation

```bash
# Get list of changed files (relative to parent branch)
if [ "$parentBranch" != "not-a-git-repo" ] && [ "$parentBranch" != "$taskBranch" ]; then
  # Compare against parent branch
  git diff ${parentBranch}...HEAD --name-only > .claude-project/tasks/{task-name}/FILES-CHANGED.txt
  git diff ${parentBranch}...HEAD > .claude-project/tasks/{task-name}/CHANGES.diff
else
  # No parent branch tracking, use recent commits
  git diff HEAD~1 --name-only > .claude-project/tasks/{task-name}/FILES-CHANGED.txt
  git diff HEAD~1 > .claude-project/tasks/{task-name}/CHANGES.diff
fi
```

### Step 3: Update SUMMARY.md

```markdown
## Phase 2: Implementation ✅

**Duration**: {minutes} minutes
**Agent**: code-implementer

**Files Changed**: {count} files
- [file1]
- [file2]
- ...

**Implementation Notes**:
- Followed SYSTEM-DESIGN.md specification
- All quality rules applied
- No 'any' types used
- All methods under 50 lines

**Next Phase**: Bug Hunting (Phase 3)
```

---

## PHASE 3: Bug Hunting (Iterative)

**Goal**: Find and fix all P0 (critical) bugs.

**Trigger**: currentPhase == 3

**Safety Limit**: Maximum 5 iterations

### Iteration Loop

```javascript
let iteration = 1;
const MAX_ITERATIONS = 5;

while (iteration <= MAX_ITERATIONS) {
  console.log('\n====...');
  console.log('🐛 Bug Hunting - Iteration ITERATION_NUM');
  console.log('====...\n');

  // Step 1: Run bug-hunter-analyzer
  bugReport = Task(
    subagent_type: 'bug-hunter-analyzer',
    description: "Analyze code for {task-name} iteration ITERATION_NUM`,
    prompt: "
      Analyze code changes for this task relative to parent branch.

      Task Context: .claude-project/tasks/{task-name}/TASK.md
      System Design: .claude-project/tasks/{task-name}/SYSTEM-DESIGN.md
      Code Changes: .claude-project/tasks/{task-name}/CHANGES.diff
                   (git diff ${parentBranch}...${taskBranch})

      IMPORTANT: Analyze ONLY changes in this task (diff from parent branch),
      not the entire codebase.

      Look for:
      - Data flow issues (null checks, type coercion, variable shadowing)
      - Business logic violations
      - Error handling gaps
      - Security issues (API keys in logs, SQL injection, XSS)
      - Performance issues (N+1 queries)
      - Code quality issues

      Categorize by priority: P0 (Critical), P1 (High), P2 (Medium)
    "
  );

  // Step 2: Save report
  saveBugReport(`.claude-project/tasks/{task-name}/BUGS-ITERATION-ITERATION_NUM.md');

  // Step 3: Parse bug counts
  const p0Count = bugReport.criticalBugs.length;
  const p1Count = bugReport.highPriorityBugs.length;
  const p2Count = bugReport.mediumPriorityBugs.length;

  console.log('\nBugs found:');
  console.log('  P0 (Critical): P0_COUNT');
  console.log('  P1 (High):     P1_COUNT');
  console.log('  P2 (Medium):   P2_COUNT');

  // Step 4: Check if P0 bugs exist
  if (p0Count === 0) {
    console.log('\n✅ No critical bugs found!');

    if (p1Count > 0 || p2Count > 0) {
      console.log('ℹ️  P1_COUNT P1 and P2_COUNT P2 bugs documented but not blocking.');
      console.log('   See BUGS-ITERATION-ITERATION_NUM.md for details.');
    }

    // Update SUMMARY.md with final iteration
    updateSummary(`
      ## Phase 3: Bug Hunting ✅

      **Total Iterations**: ITERATION_NUM
      **Final Status**: No critical bugs

      **Iteration History**:
      ${iterationHistory}

      **Remaining Issues**:
      - P1 bugs: P1_COUNT (documented in BUGS-ITERATION-ITERATION_NUM.md)
      - P2 bugs: P2_COUNT (documented in BUGS-ITERATION-ITERATION_NUM.md)

      **Next Phase**: Code Cleanliness Review (Phase 4)
    ');

    break; // Exit loop - no P0 bugs
  }

  // Step 5: Fix P0 bugs
  console.log('\n🔧 Fixing P0_COUNT critical bugs...');

  Task(
    subagent_type: 'code-implementer',
    description: "Fix P0 bugs for {task-name} iteration ITERATION_NUM`,
    prompt: "
      Fix the following P0 (Critical) bugs found in bug analysis:

      Bug Report: .claude-project/tasks/{task-name}/BUGS-ITERATION-ITERATION_NUM.md

      Focus ONLY on P0 (Critical) bugs. Fix them according to the recommended solutions in the report.

      Maintain code quality standards.
    "
  );

  console.log('✅ P0 bugs fixed (iteration ITERATION_NUM)');

  // Update SUMMARY.md with iteration progress
  updateSummary(`
    ### Iteration ITERATION_NUM:
    - Bugs found: P0_COUNT P0, P1_COUNT P1, P2_COUNT P2
    - Action: Fixed P0_COUNT P0 bugs
    - Report: BUGS-ITERATION-ITERATION_NUM.md
  ');

  // Step 6: Increment and continue
  iteration++;

  if (iteration > MAX_ITERATIONS) {
    console.error('\n❌ WARNING: Reached maximum bug-fix iterations (${MAX_ITERATIONS})!');
    console.error('   Some P0 bugs may still remain.');
    console.error('   Manual review recommended.');
    console.error('   See BUGS-ITERATION-${iteration-1}.md for remaining issues.');

    updateSummary(`
      ## Phase 3: Bug Hunting ⚠️ (INCOMPLETE)

      **Status**: Reached maximum iterations (${MAX_ITERATIONS})
      **Remaining P0 Bugs**: P0_COUNT

      ⚠️  MANUAL REVIEW REQUIRED

      See BUGS-ITERATION-${iteration-1}.md for details.
    ');

    break;
  }
}
```

---

## PHASE 4: Code Cleanliness Review

**Goal**: Ensure code follows project quality standards.

**Trigger**: currentPhase == 4

### Step 1: Launch code-cleanliness-reviewer Agent

```
Task tool with:
  subagent_type: 'code-cleanliness-reviewer'
  description: "Review code cleanliness for {task-name}"
  prompt: "
    Review code changes for this task for cleanliness issues.

    Changed Files: .claude-project/tasks/{task-name}/FILES-CHANGED.txt
    Full Diff: .claude-project/tasks/{task-name}/CHANGES.diff
               (git diff ${parentBranch}...${taskBranch})
    Project Standards: .claude/CLAUDE.md

    IMPORTANT: Review ONLY files changed in this task (diff from parent branch),
    not the entire codebase.

    Check for:
    1. Unused parameters
    2. Large methods (>50 lines)
    3. Dynamic imports in code
    4. Unclear naming
    5. Strings instead of enums
    6. Usage of 'any'
    7. Excessive if-else instead of iteration
    8. Hardcoded environment variables
    9. Decorator opportunities
    10. Additional issues (duplicated code, console.log, unused imports)

    Report by severity: Critical, Medium, Low
  "
```

### Step 2: Save Report

Output → `.claude-project/tasks/{task-name}/CLEANLINESS.md`

### Step 3: Fix Critical Issues (if any)

```javascript
if (cleanlinessReport.criticalIssues.length > 0) {
  console.log('\n🧹 Fixing ${cleanlinessReport.criticalIssues.length} critical cleanliness issues...');

  Task(
    subagent_type: 'code-implementer',
    description: "Fix critical cleanliness issues for {task-name}`,
    prompt: "
      Fix critical code cleanliness issues:

      Report: .claude-project/tasks/{task-name}/CLEANLINESS.md

      Fix ONLY critical issues. Maintain functionality.
    "
  );

  console.log('✅ Critical cleanliness issues fixed');
}

if (cleanlinessReport.mediumIssues.length > 0) {
  console.log('ℹ️  ${cleanlinessReport.mediumIssues.length} medium cleanliness issues documented but not blocking.');
}
```

### Step 4: Update SUMMARY.md

```markdown
## Phase 4: Code Cleanliness Review ✅

**Agent**: code-cleanliness-reviewer
**Output**: tasks/{task-name}/CLEANLINESS.md

**Issues Found**:
- Critical: {count} (all fixed)
- Medium: {count} (documented)
- Low: {count} (documented)

**Next Phase**: Test Creation (Phase 5)
```

---

## PHASE 5: Test Creation

**Goal**: Generate comprehensive integration tests.

**Trigger**: currentPhase == 5

### Step 1: Analyze Task Requirements for Test Scenarios

```markdown
Read and analyze:
1. .claude-project/tasks/{task-name}/TASK.md - User stories, scenarios, acceptance criteria
2. .claude-project/tasks/{task-name}/SYSTEM-DESIGN.md - API endpoints, data flow, error cases
3. .claude-project/tasks/{task-name}/CHANGES.diff - Actual implementation (git diff ${parentBranch}...${taskBranch})

Extract test scenarios:
- **Happy Path**: Main success scenario from TASK.md user stories
- **Edge Cases**: Boundary conditions from acceptance criteria
- **Error Cases**: Error handling from SYSTEM-DESIGN.md
- **Integration Flows**: Complete workflows (e.g., register → login → access protected resource)
```

### Step 2: Create Test Structure

Create files in `.claude-project/tasks/{task-name}/tests/`:

**File 1: `package.json`**
```json
{
  "name": "{task-name}-tests",
  "version": "1.0.0",
  "description": "Integration tests for {task-name}",
  "scripts": {
    "test": "node run-all.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "dotenv": "^16.3.1",
    "form-data": "^4.0.0"
  }
}
```

**File 2: `helpers.js`**
```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const API_URL = process.env.API_URL || 'http://localhost:3000';

// Login and get token
async function login(email, password) {
  const response = await axios.post(`${API_URL}/auth/login`, { email, password });
  return response.data.token;
}

// Make API call with token
async function apiCall(token, method, endpoint, data = null) {
  const config = {
    method,
    url: `${API_URL}${endpoint}`,
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    data
  };
  return await axios(config);
}

// Upload file
async function uploadFile(token, endpoint, filePath, fieldName = 'file') {
  const form = new FormData();
  form.append(fieldName, fs.createReadStream(filePath));

  return await axios.post(`${API_URL}${endpoint}`, form, {
    headers: {
      ...form.getHeaders(),
      Authorization: `Bearer ${token}`
    }
  });
}

// Assertions
function assert(condition, message) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}');
  }
}

function assertEqual(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message}\nExpected: ${expected}\nActual: ${actual}');
  }
}

function assertContains(object, key, value) {
  if (object[key] !== value) {
    throw new Error(`Expected ${key} to be ${value}, got ${object[key]}');
  }
}

module.exports = {
  API_URL,
  login,
  apiCall,
  uploadFile,
  assert,
  assertEqual,
  assertContains
};
```

**File 3: `.env.test.example`**
```env
API_URL=http://localhost:3000
TEST_USER_EMAIL=test@example.com
TEST_USER_PASSWORD=password123
```

**File 4: `run-all.js`**
```javascript
const fs = require('fs');
const { spawn } = require('child_process');

// Get all test files (numbered 01-*, 02-*, etc.)
const testFiles = fs.readdirSync(__dirname)
  .filter(file => /^\d{2}-.+\.js$/.test(file))
  .sort();

console.log('\n====...');
console.log('Running TEST_COUNT test files sequentially');
console.log(====...\n');

let passed = 0;
let failed = 0;

async function runTest(file) {
  return new Promise((resolve) => {
    const child = spawn('node', [file], { stdio: 'inherit' });

    child.on('exit', (code) => {
      if (code === 0) {
        passed++;
        resolve(true);
      } else {
        failed++;
        resolve(false);
      }
    });
  });
}

(async () => {
  for (const file of testFiles) {
    await runTest(file);
  }

  console.log('\n====...');
  console.log('TEST SUMMARY');
  console.log(====...');
  console.log('Total: TEST_COUNT');
  console.log('Passed: ${passed} ✅');
  console.log('Failed: ${failed} ❌');
  console.log(====...\n');

  process.exit(failed > 0 ? 1 : 0);
})();
```

### Step 3: Generate Test Files

For each test scenario from Step 1, create numbered test file:

**Example: `01-happy-path-{scenario}.js`**
```javascript
/**
 * Test: {Scenario Name from TASK.md}
 *
 * Expected behavior:
 * - {Acceptance criterion 1}
 * - {Acceptance criterion 2}
 */

require('dotenv').config({ path: require('path').join(__dirname, '.env.test') });
const { login, apiCall, assert, assertEqual, API_URL } = require('./helpers');

async function test{ScenarioName}() {
  console.log('\n' + '='.repeat(60));
  console.log('1️⃣  TEST: {Scenario Name}');
  console.log('='.repeat(60));

  try {
    // Step 1: {Description from user story}
    console.log('\n📝 Step 1: {Action}');
    const email = process.env.TEST_USER_EMAIL;
    const password = process.env.TEST_USER_PASSWORD;
    const token = await login(email, password);
    console.log('✅ Step 1 completed');

    // Step 2: {Next action}
    console.log('\n📝 Step 2: {Action}');
    const response = await apiCall(token, 'GET', '/api/{endpoint}');
    assertEqual(response.status, 200, 'Response status should be 200');
    console.log('✅ Step 2 completed');

    // Step 3: Verify {expected result from acceptance criteria}
    console.log('\n📝 Step 3: Verify {result}');
    assert(response.data.{field}, '{Field} should exist');
    console.log('✅ Step 3 completed');

    console.log('\n' + '='.repeat(60));
    console.log('✅ SUCCESS: {Scenario Name} passed');
    console.log('='.repeat(60));

  } catch (error) {
    console.error('\n' + '='.repeat(60));
    console.error('❌ ERROR:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    }
    console.error('='.repeat(60));
    process.exit(1);
  }
}

test{ScenarioName}();
```

**Generate tests for:**
1. Happy path scenarios (01-*, 02-*)
2. Edge case scenarios (10-*, 11-*)
3. Error handling scenarios (20-*, 21-*)
4. Integration flow scenarios (30-*, 31-*)

### Step 4: Create README.md

```markdown
# Tests for {task-name}

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy environment template:
   ```bash
   cp .env.test.example .env.test
   ```

3. Configure `.env.test` with your test credentials

## Test Scenarios

### Happy Path Tests
- `01-{scenario}.js` - {Description from TASK.md}
- `02-{scenario}.js` - {Description}

### Edge Case Tests
- `10-{scenario}.js` - {Description}

### Error Handling Tests
- `20-{scenario}.js` - {Description}

### Integration Flow Tests
- `30-{scenario}.js` - {Description}

## Running Tests

**Run all tests:**
```bash
npm test
```

**Run specific test:**
```bash
npm run test:01
```

## Expected Results

All tests should pass with ✅ status.

If tests fail:
1. Check API is running on correct URL
2. Verify test credentials in .env.test
3. Review error messages for debugging info
```

### Step 5: Update SUMMARY.md

```markdown
## Phase 5: Test Creation ✅

**Test Scenarios Created**: {count}
- Happy path: {count}
- Edge cases: {count}
- Error handling: {count}
- Integration flows: {count}

**Test Structure**:
- package.json: Dependencies configured
- helpers.js: Common utilities
- run-all.js: Sequential test runner
- README.md: Test documentation

**Tests Location**: tasks/{task-name}/tests/

**Next Phase**: Test Execution (Phase 6)
```

---

## PHASE 6: Test Execution

**Goal**: Run tests and verify implementation.

**Trigger**: currentPhase == 6

### Step 1: Start Application in Background

```bash
# Start application (assuming npm start or similar)
# Use run_in_background to allow tests to run concurrently

Bash(
  command: "npm start",
  run_in_background: true,
  description: "Start application for testing"
)

# Wait for app to be ready (5 seconds)
sleep 5

# Save background process ID for later cleanup
appProcessId = {bash_id from Bash tool}
```

### Step 2: Install Test Dependencies

```bash
cd .claude-project/tasks/{task-name}/tests && npm install
```

### Step 3: Run Tests

```bash
cd .claude-project/tasks/{task-name}/tests && npm test
```

**Capture output** for analysis.

### Step 4: Analyze Results

```javascript
if (exitCode === 0) {
  // All tests passed
  console.log('\n✅ ALL TESTS PASSED!\n');

  testsPassed = true;

  updateSummary(`
    ## Phase 6: Test Execution ✅

    **Result**: All tests passed
    **Total Tests**: {count}
    **Duration**: {time}

    All acceptance criteria verified.

    **Next Phase**: Final Summary (Phase 8)
  ');

} else {
  // Some tests failed
  console.log('\n❌ SOME TESTS FAILED\n');
  console.log('Analyzing failures...\n');

  testsPassed = false;

  // Parse test output to identify which tests failed
  failedTests = parseFailedTests(testOutput);

  updateSummary(`
    ## Phase 6: Test Execution ❌

    **Result**: {failedCount} tests failed
    **Failed Tests**:
    ${failedTests.map(t => `- ${t.name}: ${t.error}`).join('\n')}

    **Next Phase**: Fix Planning (Phase 7)
  ');
}
```

### Step 5: Cleanup Background Process

```bash
KillShell(shell_id: appProcessId)
```

---

## PHASE 7: Test Failure Analysis & Fix Planning

**Goal**: Analyze failures, create fix plan, implement fixes, re-test.

**Trigger**: currentPhase == 7 OR (Phase 6 completed AND testsPassed === false)

**Safety Limit**: Maximum 3 iterations

### Iteration Loop

```javascript
let fixIteration = 1;
const MAX_FIX_ITERATIONS = 3;

while (fixIteration <= MAX_FIX_ITERATIONS) {
  console.log('\n====...');
  console.log('🔧 Test Fix - Iteration ${fixIteration}');
  console.log(====...\n');

  // Step 1: Analyze test failures
  console.log('📊 Analyzing test failures...\n');

  const analysisReport = analyzeTestFailures({
    testOutput: lastTestOutput,
    taskSpec: read('.claude-project/tasks/{task-name}/TASK.md'),
    systemDesign: read('.claude-project/tasks/{task-name}/SYSTEM-DESIGN.md'),
    code: gitDiff()
  });

  // Step 2: Create fix plan
  const fixPlan = createFixPlan(analysisReport);

  saveFixPlan(`.claude-project/tasks/{task-name}/TEST-FIX-PLAN-${fixIteration}.md');

  console.log('\n📋 Fix Plan Created:');
  console.log('\nProblems Identified: ${fixPlan.problems.length}');
  fixPlan.problems.forEach((p, i) => {
    console.log('  ${i+1}. ${p.test}: ${p.issue}');
    console.log('     → Fix: ${p.proposedFix}');
  });

  // Step 3: Use TodoWrite to show plan to user
  const todoItems = fixPlan.problems.map(p => ({
    content: `Fix ${p.test}: ${p.issue}`,
    status: 'pending',
    activeForm: `Fixing ${p.test}`
  }));
  TodoWrite({ todos: todoItems });

  // Step 4: Implement fixes
  console.log('\n🔧 Implementing fixes...\n');

  Task(
    subagent_type: 'code-implementer',
    description: "Fix test failures for {task-name} iteration ${fixIteration}`,
    prompt: "
      Fix the following test failures:

      Fix Plan: .claude-project/tasks/{task-name}/TEST-FIX-PLAN-${fixIteration}.md

      Implement the proposed fixes while maintaining code quality.
    "
  );

  console.log('✅ Fixes implemented\n');

  // Step 5: Re-run tests
  console.log('🧪 Re-running tests...\n');

  // Start app in background
  Bash(command: "npm start", run_in_background: true);
  sleep(5);

  // Run tests
  testOutput = Bash(command: "cd .claude-project/tasks/{task-name}/tests && npm test");

  // Cleanup
  KillShell(shell_id: appProcessId);

  // Step 6: Check results
  if (testOutput.exitCode === 0) {
    console.log('\n✅ ALL TESTS NOW PASS!\n');

    updateSummary(`
      ## Phase 7: Test Fix ✅

      **Fix Iterations**: ${fixIteration}
      **Final Result**: All tests passing

      **Iteration History**:
      ${fixIterationHistory}

      **Next Phase**: Final Summary (Phase 8)
    ');

    break; // Exit loop - tests pass

  } else {
    console.log('\n⚠️  ${parseFailedTestCount(testOutput)} tests still failing\n');

    fixIteration++;

    if (fixIteration > MAX_FIX_ITERATIONS) {
      console.error('\n❌ WARNING: Reached maximum test-fix iterations (${MAX_FIX_ITERATIONS})!');
      console.error('   Some tests still failing.');
      console.error('   Manual debugging recommended.');
      console.error('   See TEST-FIX-PLAN-${fixIteration-1}.md for analysis.');

      updateSummary(`
        ## Phase 7: Test Fix ⚠️ (INCOMPLETE)

        **Status**: Reached maximum fix iterations (${MAX_FIX_ITERATIONS})
        **Tests Still Failing**: ${parseFailedTestCount(testOutput)}

        ⚠️  MANUAL DEBUGGING REQUIRED

        See TEST-FIX-PLAN-${fixIteration-1}.md for last analysis.
      ');

      break;
    }

    // Update for next iteration
    lastTestOutput = testOutput;
  }
}
```

**Helper: createFixPlan()**
```javascript
function createFixPlan(analysisReport) {
  return {
    problems: analysisReport.failures.map(failure => ({
      test: failure.testName,
      issue: failure.errorMessage,
      rootCause: analyzeRootCause(failure),
      proposedFix: suggestFix(failure),
      priority: assignPriority(failure)
    }))
  };
}
```

**Fix Plan Format (`TEST-FIX-PLAN-{N}.md`):**
```markdown
# Test Fix Plan - Iteration {N}

## Failed Tests Summary

Total failed: {count}

## Problem Analysis

### Test: {test-name}

**Error**: {error message}

**Root Cause**: {analysis of why it failed}

**Expected Behavior** (from TASK.md):
{acceptance criteria}

**Actual Behavior**:
{what happened}

**Proposed Fix**:
{specific code changes needed}

**Priority**: High/Medium/Low

---

### Test: {test-name-2}
...

## Implementation Notes

{Any additional context for implementer}
```

---

## PHASE 8: Final Summary

**Goal**: Create comprehensive task summary.

**Trigger**: currentPhase == 8 OR (all previous phases completed successfully)

### Step 1: Compile Complete Summary

Update `.claude-project/tasks/{task-name}/SUMMARY.md` with final comprehensive report:

```markdown
# Task {task-name} - COMPLETED ✅

## Overview

**Task Name**: {task-name}
**Started**: {timestamp}
**Completed**: {timestamp}
**Total Duration**: {hours}h {minutes}m

**Status**: ✅ Complete and Tested

---

## Phase Summary

### Phase 0: Business Analysis ✅
**Duration**: {time}
**Output**: TASK.md (complete business specification)
**Iterations**: {count}
**User Questions**: {count}

**Key Requirements**:
- {requirement 1}
- {requirement 2}

### Phase 1: System Design ✅
**Duration**: {time}
**Agent**: system-designer
**Output**: SYSTEM-DESIGN.md

**Architecture**:
- Services: {count}
- DTOs/Interfaces: {count}
- Endpoints: {count}
- Database changes: {Yes/No}

### Phase 2: Implementation ✅
**Duration**: {time}
**Agent**: code-implementer
**Files Changed**: {count}

**Implementation**:
- All quality rules followed
- No 'any' types
- Methods under 50 lines
- Clean, maintainable code

### Phase 3: Bug Hunting ✅
**Iterations**: {count}
**Final Status**: No P0 bugs

**Bug History**:
- Iteration 1: {p0} P0, {p1} P1, {p2} P2 → Fixed P0
- Iteration {N}: 0 P0, {p1} P1, {p2} P2 → Complete

**Remaining Issues**:
- P1: {count} (documented in BUGS-ITERATION-{N}.md)
- P2: {count} (documented in BUGS-ITERATION-{N}.md)

### Phase 4: Code Cleanliness ✅
**Agent**: code-cleanliness-reviewer
**Issues**:
- Critical: {count} (all fixed)
- Medium: {count} (documented)
- Low: {count} (documented)

### Phase 5: Test Creation ✅
**Tests Created**: {count}
- Happy path: {count}
- Edge cases: {count}
- Error handling: {count}
- Integration: {count}

**Location**: tasks/{task-name}/tests/

### Phase 6: Test Execution ✅
**Result**: All {count} tests passed
**Duration**: {time}

### Phase 7: Test Fix {✅ or ⚠️}
**Iterations**: {count}
**Final Status**: {All passing or Some issues remain}

{If issues remain:}
⚠️  MANUAL REVIEW NEEDED
See TEST-FIX-PLAN-{N}.md

---

## Files Created/Modified

### Documentation
- tasks/{task-name}/TASK.md
- tasks/{task-name}/SYSTEM-DESIGN.md
- tasks/{task-name}/BUGS-ITERATION-*.md
- tasks/{task-name}/CLEANLINESS.md
- tasks/{task-name}/SUMMARY.md

### Tests
- tasks/{task-name}/tests/ (complete test suite)

### Source Code
{List of changed files from git diff}

---

## Acceptance Criteria Status

{For each criterion from TASK.md:}
- [x] {Criterion 1} - Verified in test 01-*.js
- [x] {Criterion 2} - Verified in test 02-*.js
- ...

---

## Next Steps

1. Review and merge code changes
2. Run tests in CI/CD pipeline
3. Deploy to staging environment
4. {Any additional notes}

---

*Task completed: {timestamp}*
*Generated by Claude Code /do command*
```

### Step 2: Final Console Output

```
====...
🎉 TASK {task-name} COMPLETED!
====...

Summary:
  Business Analysis:     ✅ Complete
  System Design:         ✅ Complete
  Implementation:        ✅ Complete
  Bug Hunting:           ✅ No P0 bugs
  Code Cleanliness:      ✅ Critical issues fixed
  Test Creation:         ✅ {count} tests
  Test Execution:        ✅ All passing

Duration: {hours}h {minutes}m

Documentation:
  📄 TASK.md              - Business requirements
  🏗️  SYSTEM-DESIGN.md     - Technical architecture
  🐛 BUGS-ITERATION-*.md  - Bug analysis
  🧹 CLEANLINESS.md       - Code quality
  📊 SUMMARY.md           - Complete summary

Tests:
  📁 tasks/{task-name}/tests/ - {count} integration tests
  ✅ All tests passing

Files Changed: {count}

Next: Review changes and create PR

====...
```

### Step 3: Sync to Git Worktrees

**IMPORTANT**: Sync .claude-project/ to all git worktrees.

```bash
# Execute worktree sync
~/.claude/hooks/sync-worktree-claude-project.sh

# This ensures:
# - Task visible in /tasks from all worktrees
# - SUMMARY.md accessible everywhere
# - Tests available in all worktrees
# - Consistent .claude-project/ state

# If worktrees exist, will sync
# If no worktrees (single directory), will skip
```

**Why critical for /do:**
- Task created in worktree A should be visible in worktree B
- When you run `/tasks` in any worktree, you see all tasks
- SUMMARY.md checkpoint works across worktrees
- Tests can be run from any worktree

---

## Error Handling & Edge Cases

### If .claude-project/project/ doesn't exist

```markdown
⚠️  WARNING: Project documentation not found

Claude Code works best with project context.

Recommendation: Run /init-project first to create:
- .claude-project/project/ABOUT.md
- Business context, architecture, tech stack docs

Options:
1. Run /init-project now (takes 10-15 minutes)
2. Continue without context (not recommended)
3. Cancel this task

What would you like to do?
```

### If task name validation fails

```markdown
❌ ERROR: Invalid task name

You provided: "{input}"

This looks like a task description, not a name.

✅ Valid task names (short identifiers):
  - AUTH-123
  - user-login
  - V-37
  - fix-auth-bug

❌ Invalid (these are descriptions):
  - "Реализовать логин пользователя"
  - "Add JWT authentication"

Please use:
  /do <short-name> "Description here"

Example:
  /do AUTH-123 "Implement JWT auth with refresh tokens"
```

### If system-designer fails

```markdown
❌ ERROR: System Design phase failed

The system-designer agent encountered an error.

This could be due to:
- Unclear task requirements in TASK.md
- Missing project context
- Technical constraints not specified

Recommendations:
1. Review TASK.md - are requirements clear?
2. Check .claude-project/project/ - is context sufficient?
3. Try running /do again with clearer description

Error details: {error message}
```

### If tests continuously fail (3+ iterations)

```markdown
⚠️  WARNING: Maximum test-fix iterations reached

After 3 attempts, some tests are still failing.

This suggests:
- Complex integration issues
- Missing dependencies
- Environment configuration problems
- Logic errors in implementation

Manual debugging recommended.

Review:
- tasks/{task-name}/TEST-FIX-PLAN-3.md - Last fix attempt
- Test output logs
- API response errors

Would you like to:
1. Continue with manual debugging
2. Simplify requirements and restart
3. Review system design for issues
```

---

## Usage Examples

### Example 1: New Task

```bash
/do AUTH-123 "Implement JWT authentication with access and refresh tokens. Users should be able to login, logout, and refresh their tokens. Tokens expire after 1 hour."
```

**Flow:**
1. Validates "AUTH-123" ✅
2. Creates tasks/AUTH-123/ structure
3. Phase 0: Business analysis (asks clarifying questions)
4. Phase 1: system-designer creates SYSTEM-DESIGN.md
5. Phase 2: code-implementer writes code
6. Phase 3: bug-hunter finds and fixes bugs (2 iterations)
7. Phase 4: cleanliness review (1 critical issue fixed)
8. Phase 5: Creates 5 test files
9. Phase 6: All tests pass ✅
10. Phase 8: SUMMARY.md completed

**Result**: Fully implemented, tested, documented feature

### Example 2: Resume Existing Task

```bash
/do AUTH-123
```

**Flow:**
1. Checks tasks/AUTH-123/ exists ✅
2. Reads SUMMARY.md → last phase was 4 (cleanliness)
3. Continues from Phase 5 (test creation)
4. Completes remaining phases

### Example 3: Restart Task

```bash
/do AUTH-123 начни заново
```

**Flow:**
1. Detects "начни заново" keyword
2. Backs up tasks/AUTH-123/ → tasks/AUTH-123-backup-20251101-120000/
3. Creates fresh tasks/AUTH-123/
4. Starts from Phase 0

### Example 4: Invalid Task Name

```bash
/do "Реализовать JWT авторизацию для пользователей"
```

**Flow:**
1. Validates name → FAILS (too long, starts with verb)
2. Shows error message with examples
3. STOPS execution

**User corrects:**
```bash
/do AUTH-123 "Реализовать JWT авторизацию для пользователей"
```

---

## Quality Checklist

Before marking task complete, verify:

- [ ] TASK.md has complete business specification
- [ ] SYSTEM-DESIGN.md has detailed architecture
- [ ] No P0 bugs remain (verified by bug-hunter)
- [ ] Critical cleanliness issues fixed
- [ ] All tests created and passing
- [ ] SUMMARY.md documents entire process
- [ ] Files changed are tracked in git
- [ ] .claude-project added to .gitignore

---

## Important Notes

### TodoWrite Usage

Use TodoWrite throughout the process to:
- Track phase progress
- Show user current status
- List upcoming steps
- Display errors/warnings

**Example:**
```javascript
TodoWrite({
  todos: [
    { content: "Phase 0: Business Analysis", status: "completed", activeForm: "Completed" },
    { content: "Phase 1: System Design", status: "completed", activeForm: "Completed" },
    { content: "Phase 2: Implementation", status: "in_progress", activeForm: "Implementing code" },
    { content: "Phase 3: Bug Hunting", status: "pending", activeForm: "Hunting bugs" },
    // ...
  ]
});
```

### SUMMARY.md Updates

Update SUMMARY.md **after every phase** to enable checkpoint resume.

### Agent Error Handling

If any agent fails:
1. Log error to SUMMARY.md
2. Show error to user
3. Provide recommendations
4. Allow user to decide: retry / skip / cancel

### Git Integration

**No automatic commits** - user manages git workflow.

**Track changes:**
```bash
git diff > .claude-project/tasks/{task-name}/CHANGES.diff
```

### Background Process Management

Always cleanup background processes:
```javascript
try {
  // Start app
  processId = Bash(command: "npm start", run_in_background: true);

  // Run tests
  runTests();

} finally {
  // Always kill background process
  KillShell(shell_id: processId);
}
```

---

You have access to all tools. Use them wisely to orchestrate this comprehensive workflow.

**Remember**: Quality over speed. Take time to do it right.
