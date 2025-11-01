# Git Worktree Synchronization - Complete Guide

Автоматическая синхронизация `.claude-project/` между всеми git worktree одного репозитория.

## 📦 Что создано

### Sync Helper Script
**Расположение**: `~/.claude/hooks/sync-worktree-claude-project.sh` (executable)

**Назначение**: Синхронизирует `.claude-project/` папку во все git worktrees

**Вызывается**: Автоматически в конце `/init-project`, `/do` команд

## 🎯 Проблема и решение

### Проблема: Git Worktrees изолированы

**Git worktree** позволяет иметь несколько рабочих копий одного репозитория:

```
home/tesold/CRT/
├── fea/           # Main worktree (branch: main)
├── fea-V-37/      # Worktree для V-37 branch
└── fea-v36/       # Worktree для v36 branch
```

**Без синхронизации**:
```
# В fea/ создали документацию
fea/.claude-project/project/main/ABOUT.md ✓

# В fea-V-37/ нет этой документации
fea-V-37/.claude-project/  ← EMPTY or OUTDATED

# Claude в fea-V-37 не видит project context!
```

**Последствия**:
- ❌ Claude в worktree B не знает о проекте
- ❌ Tasks из worktree A не видны в worktree B
- ❌ Дублирование усилий
- ❌ Рассинхронизация

### Решение: Автоматическая синхронизация

**После каждой операции** (/init-project, /do):
```
1. Detect all worktrees: git worktree list
2. Sync .claude-project/ to each worktree
3. Use rsync (only changed files)
4. Report what was synced
```

**С синхронизацией**:
```
# В fea/ создали docs
fea/.claude-project/project/main/ABOUT.md ✓

# Автоматически sync в другие worktrees
fea-V-37/.claude-project/project/main/ABOUT.md ✓ (copied)
fea-v36/.claude-project/project/main/ABOUT.md ✓ (copied)

# Claude везде видит одинаковый context!
```

## 🔄 Как работает sync

### Алгоритм

```bash
1. Check if git repository
   ↓
2. Get all worktrees: git worktree list --porcelain
   ↓
3. For each worktree (except source):
   ├─ If .claude-project doesn't exist:
   │  └─ Full copy: cp -r .claude-project/ target/
   │
   └─ If .claude-project exists:
      └─ Smart sync: rsync --update (only newer files)
   ↓
4. Report summary
```

### Что синхронизируется

✅ **Включается в sync**:
- `project/` - вся документация проекта
- `tasks/` - все задачи
- `templates/` - шаблоны
- Любые другие файлы в `.claude-project/`

❌ **Исключается из sync**:
- `*.tmp`, `*.swp` - временные файлы
- `node_modules/` - зависимости (rebuild в каждом worktree)
- `.env.test` - credentials (user-specific)
- `.DS_Store` - OS файлы

### rsync опции

```bash
rsync -a --update --itemize-changes \
  --exclude='.DS_Store' \
  --exclude='*.swp' \
  --exclude='*.tmp' \
  --exclude='node_modules/' \
  --exclude='tests/.env.test' \
  source/.claude-project/ target/.claude-project/
```

**Флаги**:
- `-a` (archive): сохраняет permissions, timestamps
- `--update`: копирует только если source новее
- `--itemize-changes`: показывает что изменилось
- `--exclude`: skip указанных файлов

## 📊 Примеры использования

### Пример 1: Первая инициализация

**Worktrees**:
```
fea/        (main branch)
fea-V-37/   (V-37 branch)
fea-v36/    (v36 branch)
```

**Действие в fea/**:
```bash
cd ~/CRT/fea
/init-project
```

**Что происходит**:
```
1. INIT MODE создаёт: fea/.claude-project/project/main/
2. Worktree sync запускается:

🔄 Syncing .claude-project across 3 worktrees...

📋 fea-V-37: Creating .claude-project (full copy)
   ✅ Copied successfully

📋 fea-v36: Creating .claude-project (full copy)
   ✅ Copied successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Worktree Sync Summary:
  Total worktrees: 3
  Synced: 2
  Already in sync: 0
  Errors: 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Результат**:
```
fea/.claude-project/project/main/ ✓
fea-V-37/.claude-project/project/main/ ✓ (copied)
fea-v36/.claude-project/project/main/ ✓ (copied)
```

### Пример 2: Обновление в одном worktree

**Действие в fea-V-37/**:
```bash
cd ~/CRT/fea-V-37
/init-project  # DIFF MODE создаёт project/V-37/ docs
```

**Что происходит**:
```
1. DIFF MODE создаёт: fea-V-37/.claude-project/project/V-37/
2. Worktree sync:

🔄 Syncing .claude-project across 3 worktrees...

📋 fea: Syncing changes...
   ✅ Synced 8 file(s)
      - project/V-37/ABOUT.md
      - project/V-37/business/OVERVIEW.md
      - project/V-37/architecture/SYSTEM-DESIGN.md
      ...

📋 fea-v36: Syncing changes...
   ✅ Synced 8 file(s)
      - project/V-37/ABOUT.md
      ...
```

**Результат**:
```
fea-V-37/.claude-project/project/V-37/ ✓ (original)
fea/.claude-project/project/V-37/ ✓ (synced)
fea-v36/.claude-project/project/V-37/ ✓ (synced)
```

Теперь во ВСЕХ worktrees есть документация для V-37 ветки!

### Пример 3: Задача создана в одном worktree

**Действие в fea/**:
```bash
cd ~/CRT/fea
/do AUTH-123 "Implement authentication"
```

**Что происходит**:
```
1. /do создаёт: fea/.claude-project/tasks/AUTH-123/
2. После каждой фазы:
   - Updates SUMMARY.md
   - Worktree sync запускается
3. В конце Phase 8:

🔄 Syncing .claude-project across 3 worktrees...

📋 fea-V-37: Syncing changes...
   ✅ Synced 12 file(s)
      - tasks/AUTH-123/TASK.md
      - tasks/AUTH-123/SUMMARY.md
      - tasks/AUTH-123/SYSTEM-DESIGN.md
      - tasks/AUTH-123/tests/01-login.js
      ...

📋 fea-v36: Syncing changes...
   ✅ Synced 12 file(s)
```

**Результат**:
```bash
# Теперь в ЛЮБОМ worktree можно проверить задачу:

cd ~/CRT/fea-V-37
/tasks
# Shows: AUTH-123 ✅ Done

cd ~/CRT/fea-v36
/tasks
# Shows: AUTH-123 ✅ Done (same!)

# Можно даже продолжить задачу из другого worktree:
cd ~/CRT/fea-v36
/do AUTH-123  # Reads SUMMARY.md, continues from checkpoint
```

### Пример 4: Изменения в разных worktrees

**Сценарий**: Два разработчика работают в разных worktrees одного репозитория

**Developer 1 (в fea/)**:
```bash
cd ~/CRT/fea
/do TASK-1 "Feature 1"
# Creates: tasks/TASK-1/
# Syncs to: fea-V-37/, fea-v36/
```

**Developer 2 (в fea-V-37/)**:
```bash
cd ~/CRT/fea-V-37
/do TASK-2 "Feature 2"
# Creates: tasks/TASK-2/
# Syncs to: fea/, fea-v36/
```

**Результат**: Оба worktree имеют обе задачи:
```bash
cd ~/CRT/fea
/tasks
# Shows: TASK-1, TASK-2

cd ~/CRT/fea-V-37
/tasks
# Shows: TASK-1, TASK-2 (same!)
```

## ⚙️ Технические детали

### Обнаружение worktrees

```bash
git worktree list --porcelain
```

**Output format:**
```
worktree /home/tesold/CRT/fea
HEAD abc123...
branch refs/heads/main

worktree /home/tesold/CRT/fea-V-37
HEAD def456...
branch refs/heads/V-37

worktree /home/tesold/CRT/fea-v36
HEAD xyz789...
branch refs/heads/v36
```

**Извлекаем пути**:
```bash
git worktree list --porcelain | grep "^worktree " | sed 's/^worktree //'
```

**Результат**:
```
/home/tesold/CRT/fea
/home/tesold/CRT/fea-V-37
/home/tesold/CRT/fea-v36
```

### Sync strategy

**Для каждого target worktree:**

```bash
if [ ! -d "$target/.claude-project" ]; then
  # Full copy (first time)
  cp -r source/.claude-project/ target/.claude-project/
else
  # Incremental sync (only changed)
  rsync -a --update source/.claude-project/ target/.claude-project/
fi
```

### Conflict resolution

**rsync --update** strategy:
- Копирует файл только если source **новее** target
- Если target новее → НЕ копирует (сохраняет target)
- Если timestamps одинаковые → НЕ копирует

**Это означает**:
- Если изменили TASK.md в fea-V-37/ (новее)
- Затем запустили /init-project в fea/ (source старее)
- rsync НЕ перезапишет newer файл в fea-V-37/

**Для bi-directional sync**:
- Запустите команду в каждом worktree
- Или запустите sync helper вручную из каждого worktree

## 🔍 Интеграция с командами

### /init-project → worktree sync

```bash
/init-project
```

**Последовательность**:
```
1. INIT/SYNC/DIFF MODE создаёт/обновляет docs
   ↓
2. В конце команды:
   ~/.claude/hooks/sync-worktree-claude-project.sh
   ↓
3. Docs копируются во все worktrees
   ↓
4. Success message
```

### /do → worktree sync

```bash
/do TASK-1 "Description"
```

**Последовательность**:
```
1. Phases 0-8 создают задачу
   ↓
2. В конце Phase 8:
   ~/.claude/hooks/sync-worktree-claude-project.sh
   ↓
3. Вся папка tasks/TASK-1/ копируется во все worktrees
   ↓
4. Success message
```

### /tasks - автоматически работает

```bash
/tasks
```

**Почему работает без sync**:
- /tasks только ЧИТАЕТ .claude-project/tasks/
- Папка уже синхронизирована /init-project или /do
- Показывает одинаковый результат в любом worktree

### Ручная синхронизация

Если нужно синхронизировать вручную:

```bash
~/.claude/hooks/sync-worktree-claude-project.sh
```

**Полезно когда**:
- Сделали изменения в .claude-project/ вручную
- Хотите убедиться что всё в sync
- Debugging sync issues

## 📋 Сценарии использования

### Use Case 1: Работа в разных worktrees

**Setup**:
```bash
# Main worktree
git worktree add ~/CRT/fea-V-37 V-37
git worktree add ~/CRT/fea-v36 v36
```

**Workflow**:
```bash
# Day 1: В main worktree инициализируем проект
cd ~/CRT/fea
/init-project
# Creates: .claude-project/project/main/
# Syncs to: fea-V-37/, fea-v36/

# Day 2: Работаем в V-37 worktree
cd ~/CRT/fea-V-37
git checkout V-37

# Создаём docs для V-37 ветки
/init-project
# DIFF MODE: creates .claude-project/project/V-37/
# Syncs to: fea/, fea-v36/

# Теперь во ВСЕХ worktrees есть docs для main и V-37!

# Day 3: Создаём задачу в fea/
cd ~/CRT/fea
/do AUTH-123 "Auth feature"
# Creates: .claude-project/tasks/AUTH-123/
# Syncs to: fea-V-37/, fea-v36/

# Day 4: Проверяем задачу из fea-V-37/
cd ~/CRT/fea-V-37
/tasks
# Shows: AUTH-123 ✅ Done (synced from fea!)

# Можем даже продолжить задачу:
/do AUTH-123
# Reads SUMMARY.md (synced), continues from checkpoint
```

### Use Case 2: Команда с несколькими worktree

**Team setup**:
- Developer A работает в `~/project/main-wt/`
- Developer B работает в `~/project/feature-wt/`
- Оба worktrees одного репозитория

**Developer A**:
```bash
cd ~/project/main-wt
/init-project
# Creates docs
# Syncs to feature-wt/
```

**Developer B** (позже):
```bash
cd ~/project/feature-wt
/tasks
# Sees all tasks (synced from main-wt!)

/init-project
# DIFF MODE (uses main docs from main-wt, synced)
# Creates feature-specific docs
# Syncs back to main-wt/
```

**Результат**: Оба worktrees имеют полную информацию

### Use Case 3: Switching between worktrees

**Scenario**: Работаете над несколькими задачами в разных worktrees

```bash
# Morning: Task 1 in worktree A
cd ~/CRT/fea
/do TASK-1 "Feature A"
# Phases 0-3 complete
# Synced to all worktrees

# Afternoon: Switch to Task 2 in worktree B
cd ~/CRT/fea-V-37
/do TASK-2 "Feature B"
# Phases 0-8 complete
# Synced to all worktrees (including TASK-1 from earlier!)

# Evening: Check all tasks from any worktree
cd ~/CRT/fea-v36
/tasks
# Shows: TASK-1 (Phase 3), TASK-2 (Complete) ✓

# Can continue TASK-1 from here
/do TASK-1
# Reads SUMMARY.md, continues from Phase 4
# When done, syncs to all worktrees
```

## 🛡️ Edge Cases

### Case 1: Только один worktree

```bash
# No additional worktrees
git worktree list
# Shows only current directory
```

**Sync behavior**:
```
ℹ️  Only one worktree, no sync needed
```

Выходит немедленно, не тратит время.

### Case 2: Worktree удалён

```bash
# Worktree fea-old/ был удалён
# Но git worktree list ещё показывает его
```

**Sync behavior**:
```
⚠️  Worktree not found: fea-old/ (skipped)
```

Пропускает, продолжает с другими.

### Case 3: Конфликтующие изменения

**Scenario**: Файл изменён в обоих worktrees

```
fea/SUMMARY.md: modified 14:00 (содержит "Phase 3")
fea-V-37/SUMMARY.md: modified 14:30 (содержит "Phase 5")
```

**Sync behavior** (rsync --update):
```
# Запускаем sync из fea/ (source)
# fea/SUMMARY.md timestamp: 14:00
# fea-V-37/SUMMARY.md timestamp: 14:30 (newer!)

# rsync видит target newer → НЕ копирует
```

**Решение конфликтов**:
1. Если изменения несовместимы → ручной merge
2. Или запустите команду в каждом worktree для bidirectional sync
3. Или используйте newer файл как source of truth

### Case 4: Нет rsync

**Если rsync не установлен:**

```bash
# Fallback to cp
if ! command -v rsync &> /dev/null; then
  # Use cp instead (less intelligent, but works)
  cp -ru source/.claude-project/* target/.claude-project/
fi
```

## 📊 Производительность

### Первая синхронизация (full copy)

**Размер** .claude-project: ~1-5 MB (зависит от количества tasks)

**Время**:
- 2 worktrees: < 1 секунда
- 5 worktrees: < 2 секунды
- 10 worktrees: < 5 секунд

### Incremental sync (only changes)

**Только изменённые файлы** (обычно 1-10 файлов)

**Время**:
- Любое количество worktrees: < 1 секунда

### Network sync (if worktrees on network drives)

Может быть медленнее, но rsync оптимизирует:
- Проверяет timestamps перед копированием
- Копирует только изменённое

## 🎯 Best Practices

### 1. Регулярно используйте команды в каждом worktree

Чтобы обеспечить bi-directional sync:
```bash
# В worktree A
/init-project  # Syncs A → B, C

# В worktree B
/init-project  # Syncs B → A, C (including changes from B)

# Результат: все worktrees имеют изменения от A и B
```

### 2. Проверяйте sync summary

После команды смотрите на вывод:
```
Worktree Sync Summary:
  Synced: 2
  Errors: 0  ← Should be 0
```

Если Errors > 0 → проверьте permissions, disk space

### 3. При конфликтах используйте newer файл

Если видите что файл не синхронизировался:
```bash
# Check timestamps
ls -la fea/.claude-project/tasks/TASK-1/SUMMARY.md
ls -la fea-V-37/.claude-project/tasks/TASK-1/SUMMARY.md

# If fea-V-37 newer and you want to use fea version:
# Update timestamp in fea to be newer
touch fea/.claude-project/tasks/TASK-1/SUMMARY.md

# Then sync again
~/.claude/hooks/sync-worktree-claude-project.sh
```

### 4. Gitignore .claude-project в каждом worktree

Убедитесь что .gitignore содержит .claude-project:
```bash
# В каждом worktree должен быть .gitignore
# с одинаковым содержимым:
echo ".claude-project/" >> .gitignore
```

Или используйте shared .gitignore через git config.

### 5. Не храните worktree-specific данные

В .claude-project/ не должно быть:
- Absolute paths (используйте relative)
- Worktree-specific configs
- User-specific credentials (они в .env.test который excluded)

## 🔧 Customization

### Добавить exclusions

Если нужно исключить дополнительные файлы:

```bash
# Edit sync script
# Add to rsync command:
--exclude='*.log' \
--exclude='debug/' \
--exclude='cache/'
```

### Bidirectional sync

Для автоматического bidirectional sync создайте wrapper:

```bash
#!/bin/bash
# bidirectional-sync.sh

# Get all worktrees
WORKTREES=$(git worktree list --porcelain | grep "^worktree " | sed 's/^worktree //')

# Sync from each worktree to others
for wt in $WORKTREES; do
  cd "$wt"
  ~/.claude/hooks/sync-worktree-claude-project.sh
done
```

### Периодическая sync (cron)

Если хотите автоматическую sync каждые N минут:

```bash
# Crontab entry
*/10 * * * * cd ~/CRT/fea && ~/.claude/hooks/sync-worktree-claude-project.sh >/dev/null 2>&1
```

## ✅ Преимущества worktree sync

### Для разработчиков

✅ **Consistent view**: Одинаковый .claude-project во всех worktrees
✅ **Task visibility**: Все задачи видны в /tasks везде
✅ **Docs accessibility**: Project docs доступны в любом worktree
✅ **Checkpoint resume**: Можно продолжить задачу из любого worktree

### Для команд

✅ **Collaboration**: Несколько разработчиков в разных worktrees видят всё
✅ **No duplication**: Не нужно пересоздавать docs в каждом worktree
✅ **Efficiency**: Одна команда обновляет всё везде

### Для workflow

✅ **Seamless**: Можно переключаться между worktrees без потери контекста
✅ **Automated**: Sync происходит автоматически
✅ **Safe**: --update не перезаписывает newer файлы

## 🚦 Готовность

**Статус**: ✅ Полностью реализовано

**Компоненты**:
- ✅ Sync helper: `~/.claude/hooks/sync-worktree-claude-project.sh` (executable)
- ✅ Integration в /init-project: FINAL STEP
- ✅ Integration в /do: After Phase 8
- ✅ Documentation в /tasks: Worktree Considerations
- ✅ Guide: `~/WORKTREE-SYNC-GUIDE.md` (этот файл)

**Активация**: Автоматически при запуске /init-project или /do в проекте с worktrees

**Тестирование**:
1. Создайте worktree: `git worktree add path branch`
2. Запустите /init-project в одном worktree
3. Проверьте другой worktree: `ls other-worktree/.claude-project/`
4. Должна появиться синхронизированная папка

---

**Создано**: 2025-11-01
**Integration with**: /init-project, /do, /tasks commands
**Type**: Automatic worktree synchronization
