---
description: Display dashboard of all tasks with their status and progress
---

# Tasks Dashboard

Display overview of all tasks in `.claude-project/tasks/` with their current status, branch, and progress.

## Your Task

Create a comprehensive dashboard showing all tasks in the project.

### Step 1: Scan for Tasks

```bash
# Find all task directories
taskDirs = $(find .claude-project/tasks -maxdepth 1 -type d -not -path ".claude-project/tasks" -not -path "*/.archive" 2>/dev/null | sort)

if [ -z "$taskDirs" ]; then
  echo ""
  echo "📭 No tasks found in .claude-project/tasks/"
  echo ""
  echo "Create your first task with:"
  echo "  /do <task-name> \"Description\""
  echo ""
  exit 0
fi

taskCount = $(echo "$taskDirs" | wc -l)
```

### Step 2: Read Task Metadata

For each task directory, extract information:

```javascript
tasks = [];

for (taskDir of taskDirs) {
  taskName = basename(taskDir);
  summaryPath = `${taskDir}/SUMMARY.md`;
  taskPath = `${taskDir}/TASK.md`;

  // Initialize task info
  task = {
    name: taskName,
    status: 'Unknown',
    phase: 'Unknown',
    branch: 'Unknown',
    duration: 'Unknown',
    lastUpdated: 'Unknown'
  };

  // Read SUMMARY.md if exists
  if (fileExists(summaryPath)) {
    summary = readFile(summaryPath);

    // Extract current phase
    phaseMatch = summary.match(/\*\*Phase\*\*: (\d+) - (.+)/);
    if (phaseMatch) {
      task.phase = `Phase ${phaseMatch[1]}: ${phaseMatch[2]}`;
    }

    // Extract status
    statusMatch = summary.match(/\*\*Status\*\*: (.+)/);
    if (statusMatch) {
      rawStatus = statusMatch[1].trim();

      // Map to emoji status
      if (rawStatus.includes('Completed') || rawStatus.includes('Complete')) {
        task.status = '✅ Done';
      } else if (rawStatus.includes('In Progress') || rawStatus.includes('IN PROGRESS')) {
        task.status = '🔄 Active';
      } else if (rawStatus.includes('Blocked')) {
        task.status = '❌ Blocked';
      } else if (rawStatus.includes('Hold') || rawStatus.includes('Paused')) {
        task.status = '⏸️  On Hold';
      } else {
        task.status = '❓ Unknown';
      }
    }

    // Extract last updated
    lastUpdatedMatch = summary.match(/\*\*Last Updated\*\*: (.+)/);
    if (lastUpdatedMatch) {
      task.lastUpdated = lastUpdatedMatch[1].trim();
    }

    // Extract duration (if completed)
    durationMatch = summary.match(/\*\*Total Duration\*\*: (.+)/);
    if (durationMatch) {
      task.duration = durationMatch[1].trim();
    } else if (task.status === '🔄 Active') {
      // Calculate duration from started time
      startedMatch = summary.match(/\*\*Started\*\*: (.+)/);
      if (startedMatch) {
        started = parseDate(startedMatch[1]);
        now = new Date();
        elapsed = formatDuration(now - started);
        task.duration = elapsed;
      }
    }
  }

  // Read TASK.md if exists (for git metadata)
  if (fileExists(taskPath)) {
    taskMd = readFile(taskPath);

    // Extract task branch
    branchMatch = taskMd.match(/\*\*Task Branch\*\*: `(.+)`/);
    if (branchMatch) {
      task.branch = branchMatch[1];
    }

    // Extract parent branch (for context)
    parentMatch = taskMd.match(/\*\*Parent Branch\*\*: `(.+)`/);
    if (parentMatch) {
      task.parentBranch = parentMatch[1];
    }
  }

  tasks.push(task);
}
```

### Step 3: Calculate Statistics

```javascript
stats = {
  total: tasks.length,
  completed: tasks.filter(t => t.status === '✅ Done').length,
  active: tasks.filter(t => t.status === '🔄 Active').length,
  onHold: tasks.filter(t => t.status === '⏸️  On Hold').length,
  blocked: tasks.filter(t => t.status === '❌ Blocked').length,
  unknown: tasks.filter(t => t.status === '❓ Unknown').length
};
```

### Step 4: Render Dashboard

```javascript
console.log('');
console.log('╔═══════════════════════════════════════════════════════════╗');
console.log('║                     TASKS DASHBOARD                        ║');
console.log('╚═══════════════════════════════════════════════════════════╝');
console.log('');

// Statistics
console.log('📊 Tasks Summary:');
console.log(`   Total: ${stats.total}`);
if (stats.completed > 0) console.log(`   ✅ Completed: ${stats.completed}`);
if (stats.active > 0) console.log(`   🔄 In Progress: ${stats.active}`);
if (stats.onHold > 0) console.log(`   ⏸️  On Hold: ${stats.onHold}`);
if (stats.blocked > 0) console.log(`   ❌ Blocked: ${stats.blocked}`);
if (stats.unknown > 0) console.log(`   ❓ Unknown: ${stats.unknown}`);
console.log('');

// Sort tasks: Active first, then On Hold, then Completed, then others
sortedTasks = [
  ...tasks.filter(t => t.status === '🔄 Active'),
  ...tasks.filter(t => t.status === '❌ Blocked'),
  ...tasks.filter(t => t.status === '⏸️  On Hold'),
  ...tasks.filter(t => t.status === '❓ Unknown'),
  ...tasks.filter(t => t.status === '✅ Done')
];

// Render table header
console.log('┌─────────────┬──────────────────────┬──────────┬───────────────────────┐');
console.log('│ Task        │ Branch               │ Status   │ Phase                 │');
console.log('├─────────────┼──────────────────────┼──────────┼───────────────────────┤');

// Render table rows
for (task of sortedTasks) {
  taskNamePadded = task.name.padEnd(11).substring(0, 11);
  branchPadded = task.branch.padEnd(20).substring(0, 20);
  statusPadded = task.status.padEnd(8);
  phasePadded = task.phase.padEnd(21).substring(0, 21);

  console.log(`│ ${taskNamePadded} │ ${branchPadded} │ ${statusPadded} │ ${phasePadded} │`);
}

console.log('└─────────────┴──────────────────────┴──────────┴───────────────────────┘');
console.log('');

// Legend
console.log('Legend:');
console.log('  ✅ Done      - All phases completed, tests passing');
console.log('  🔄 Active    - Currently being worked on');
console.log('  ⏸️  On Hold  - Paused, waiting for dependencies or decision');
console.log('  ❌ Blocked   - Has blockers preventing progress');
console.log('  ❓ Unknown   - Status unclear (check SUMMARY.md)');
console.log('');

// Usage hints
console.log('Commands:');
console.log('  /do <task-name>           - Continue or start a task');
console.log('  /do <task-name> начни заново - Restart task from scratch');
console.log('');
```

### Step 5: Show Active Tasks Details (if any)

If there are active tasks, show additional details:

```javascript
activeTasks = tasks.filter(t => t.status === '🔄 Active');

if (activeTasks.length > 0) {
  console.log('━'.repeat(60));
  console.log('');
  console.log('🔄 ACTIVE TASKS DETAILS:');
  console.log('');

  for (task of activeTasks) {
    console.log(`📋 ${task.name}`);
    console.log(`   Branch: ${task.branch}`);
    console.log(`   Current: ${task.phase}`);
    if (task.duration !== 'Unknown') {
      console.log(`   Duration: ${task.duration}`);
    }
    if (task.lastUpdated !== 'Unknown') {
      console.log(`   Updated: ${task.lastUpdated}`);
    }

    // Read SUMMARY.md for more context
    summaryPath = `.claude-project/tasks/${task.name}/SUMMARY.md`;
    if (fileExists(summaryPath)) {
      summary = readFile(summaryPath);

      // Extract pending phases
      pendingMatch = summary.match(/## Pending Phases\n([\s\S]+?)(?=\n##|\n---|\z)/);
      if (pendingMatch) {
        pendingPhases = pendingMatch[1].trim().split('\n').filter(line => line.includes('[ ]'));

        if (pendingPhases.length > 0 && pendingPhases.length <= 3) {
          console.log(`   Next steps:`);
          pendingPhases.slice(0, 3).forEach(phase => {
            phaseName = phase.replace(/- \[ \] /, '').trim();
            console.log(`     - ${phaseName}`);
          });
        }
      }
    }

    console.log('');
  }

  console.log('━'.repeat(60));
  console.log('');
}
```

### Step 6: Show Blocked Tasks Warning (if any)

```javascript
blockedTasks = tasks.filter(t => t.status === '❌ Blocked');

if (blockedTasks.length > 0) {
  console.log('⚠️  BLOCKED TASKS:');
  console.log('');

  for (task of blockedTasks) {
    console.log(`   ❌ ${task.name}: ${task.phase}`);

    // Try to extract blocker reason from SUMMARY.md
    summaryPath = `.claude-project/tasks/${task.name}/SUMMARY.md`;
    if (fileExists(summaryPath)) {
      summary = readFile(summaryPath);

      blockerMatch = summary.match(/\*\*Blocked by\*\*: (.+)/);
      if (blockerMatch) {
        console.log(`      Reason: ${blockerMatch[1]}`);
      }
    }
  }

  console.log('');
  console.log('   Review blocked tasks to unblock progress.');
  console.log('');
}
```

### Step 7: Show Recent Completions (if any)

```javascript
completedTasks = tasks.filter(t => t.status === '✅ Done');

// Get recently completed (last 7 days)
recentlyCompleted = completedTasks.filter(task => {
  if (task.lastUpdated === 'Unknown') return false;

  lastUpdate = parseDate(task.lastUpdated);
  daysSince = (new Date() - lastUpdate) / (1000 * 60 * 60 * 24);

  return daysSince <= 7;
});

if (recentlyCompleted.length > 0) {
  console.log('🎉 RECENTLY COMPLETED (last 7 days):');
  console.log('');

  for (task of recentlyCompleted.slice(0, 5)) {  // Show max 5
    console.log(`   ✅ ${task.name} (${task.branch})`);

    if (task.duration !== 'Unknown') {
      console.log(`      Duration: ${task.duration}`);
    }
  }

  console.log('');
}
```

## Output Example

Example output for a project with several tasks:

```
╔═══════════════════════════════════════════════════════════╗
║                     TASKS DASHBOARD                        ║
╚═══════════════════════════════════════════════════════════╝

📊 Tasks Summary:
   Total: 5 tasks
   ✅ Completed: 2
   🔄 In Progress: 2
   ⏸️  On Hold: 1

┌─────────────┬──────────────────────┬──────────┬───────────────────────┐
│ Task        │ Branch               │ Status   │ Phase                 │
├─────────────┼──────────────────────┼──────────┼───────────────────────┤
│ AUTH-123    │ feature/AUTH-123     │ 🔄 Active│ Phase 3: Bug Hunting  │
│ PAY-456     │ feature/payments     │ 🔄 Active│ Phase 5: Test Creation│
│ DASH-789    │ feature/dashboard    │ ⏸️  Hold │ Phase 1: System Design│
│ USER-234    │ feature/profile      │ ✅ Done  │ Phase 8: Complete     │
│ FIX-101     │ fix/auth-bug         │ ✅ Done  │ Phase 8: Complete     │
└─────────────┴──────────────────────┴──────────┴───────────────────────┘

Legend:
  ✅ Done      - All phases completed, tests passing
  🔄 Active    - Currently being worked on
  ⏸️  On Hold  - Paused, waiting for dependencies or decision
  ❌ Blocked   - Has blockers preventing progress
  ❓ Unknown   - Status unclear (check SUMMARY.md)

Commands:
  /do <task-name>           - Continue or start a task
  /do <task-name> начни заново - Restart task from scratch

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 ACTIVE TASKS DETAILS:

📋 AUTH-123
   Branch: feature/AUTH-123
   Current: Phase 3: Bug Hunting (Iteration 2)
   Duration: 1h 25m
   Updated: 2025-11-01 14:30
   Next steps:
     - Phase 4: Code Cleanliness Review
     - Phase 5: Test Creation
     - Phase 6: Test Execution

📋 PAY-456
   Branch: feature/payments
   Current: Phase 5: Test Creation
   Duration: 2h 15m
   Updated: 2025-11-01 13:45
   Next steps:
     - Phase 6: Test Execution
     - Phase 7: Test Fix Planning
     - Phase 8: Final Summary

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 RECENTLY COMPLETED (last 7 days):

   ✅ USER-234 (feature/profile)
      Duration: 3h 20m

   ✅ FIX-101 (fix/auth-bug)
      Duration: 45m

```

## Edge Cases

### No SUMMARY.md

If task directory exists but no SUMMARY.md:

```javascript
if (!fileExists(summaryPath)) {
  // Task was created but not started or interrupted very early
  task.status = '❓ Unknown';
  task.phase = 'Not started or no checkpoint';

  // Try reading TASK.md for basic info
  if (fileExists(taskPath)) {
    taskMd = readFile(taskPath);

    // Extract branch from TASK.md
    branchMatch = taskMd.match(/\*\*Task Branch\*\*: `(.+)`/);
    if (branchMatch) {
      task.branch = branchMatch[1];
    }

    // Check if TASK.md has full specification
    if (taskMd.includes('## Acceptance Criteria')) {
      task.phase = 'Business Analysis complete';
    } else {
      task.phase = 'Initial setup only';
    }
  }
}
```

### Malformed SUMMARY.md

If SUMMARY.md exists but doesn't match expected format:

```javascript
try {
  // Parse SUMMARY.md
  // ...
} catch (error) {
  task.status = '⚠️  Error';
  task.phase = 'Could not parse SUMMARY.md';

  console.log(`   ⚠️  Warning: Could not parse SUMMARY.md for ${taskName}`);
  console.log(`      File may be corrupted or in old format`);
}
```

### Very long task names or branches

Truncate with ellipsis:

```javascript
function truncate(str, maxLen) {
  if (str.length <= maxLen) return str.padEnd(maxLen);

  return str.substring(0, maxLen - 1) + '…';
}

taskNamePadded = truncate(task.name, 11);
branchPadded = truncate(task.branch, 20);
```

## Additional Features

### Show task count by status

At the end of dashboard:

```
📈 Progress Overview:

   ████████████░░░░░░░░ 40% Complete (2/5)

   Pipeline:
   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
   │Active│ → │ Hold │ → │Done  │   │Block │
   │  2   │   │  1   │   │  2   │   │  0   │
   └──────┘   └──────┘   └──────┘   └──────┘
```

### Filter by status (optional argument)

```bash
# If user provides filter argument
/tasks active
/tasks completed
/tasks blocked
```

Parse argument and filter:

```javascript
if (argument === 'active') {
  tasks = tasks.filter(t => t.status === '🔄 Active');
  console.log('Showing only active tasks');
}
// Similar for other filters
```

### Show archived tasks (optional)

```bash
/tasks --archived

# Scan .claude-project/tasks/.archive/
# Show archived tasks separately
```

## Performance Considerations

For projects with many tasks (50+):

```javascript
// Limit table rows
const MAX_DISPLAY = 20;

if (sortedTasks.length > MAX_DISPLAY) {
  displayTasks = sortedTasks.slice(0, MAX_DISPLAY);

  console.log(`Showing first ${MAX_DISPLAY} of ${sortedTasks.length} tasks`);
  console.log(`Use /tasks active or /tasks completed to filter`);
  console.log('');

  // Show table for first 20
  // ...

  console.log('');
  console.log(`... and ${sortedTasks.length - MAX_DISPLAY} more tasks`);
}
```

## Important Notes

- **Read-only operation**: This command only reads files, never modifies
- **Fast execution**: Should complete in < 2 seconds even for 50+ tasks
- **Graceful degradation**: If files missing or malformed, show what's available
- **Useful hints**: Always show commands user can run next
- **Worktree aware**: Scans .claude-project/tasks/ which is synced across all worktrees

## Worktree Considerations

When using git worktrees:

**Automatic sync:**
- /init-project and /do commands automatically sync .claude-project/ to all worktrees
- /tasks reads from .claude-project/tasks/ which is synced
- You see all tasks regardless of which worktree you're in

**Manual sync (if needed):**
```bash
~/.claude/hooks/sync-worktree-claude-project.sh
```

**Expected behavior:**
- Run /tasks in worktree A → see all tasks
- Run /tasks in worktree B → see same tasks
- Tasks created in any worktree visible in all

## Quality Checklist

- [ ] Scans all task directories
- [ ] Reads SUMMARY.md and TASK.md correctly
- [ ] Extracts status, phase, branch, duration
- [ ] Calculates accurate statistics
- [ ] Renders clean table
- [ ] Sorts tasks logically (active first)
- [ ] Shows active task details
- [ ] Warns about blocked tasks
- [ ] Shows recent completions
- [ ] Handles edge cases (missing files, malformed data)
- [ ] Performance: fast even with many tasks
- [ ] Helpful: suggests next commands

---

This is a pure display command - think of it as `git status` for tasks.
