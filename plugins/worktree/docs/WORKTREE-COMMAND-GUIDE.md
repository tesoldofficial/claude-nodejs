# Команда `/worktree` - Git Worktree Management

Создание и настройка git worktrees с автоматической конфигурацией окружения.

## 📦 Что создано

**Command**: `~/.claude/commands/worktree.md`

**Назначение**: Упрощённое создание git worktrees с автоматической настройкой

## 🚀 Синтаксис

```bash
/worktree <branch>                # Создать worktree для ветки (существующей или новой)
/worktree <branch1> <branch2>     # Создать branch2 от branch1, затем worktree
```

## 📋 Режимы работы

### Режим 1: Один аргумент - `/worktree <branch>`

**Если ветка существует**:
```bash
/worktree V-37  # V-37 already exists
```
**Действие**: Создаёт worktree для существующей ветки V-37

**Если ветка НЕ существует**:
```bash
/worktree feature-auth  # feature-auth doesn't exist
```
**Действие**:
1. Создаёт новую ветку `feature-auth` от текущей ветки
2. Создаёт worktree для `feature-auth`

### Режим 2: Два аргумента - `/worktree <source> <target>`

```bash
/worktree main feature-payments
```

**Действие**:
1. Проверяет `main` существует → если нет, **ОШИБКА**
2. Создаёт ветку `feature-payments` от `main`
3. Создаёт worktree для `feature-payments`

**Ошибка если source не существует**:
```bash
/worktree non-existent feature-new
```
**Вывод**:
```
❌ ERROR: Source branch 'non-existent' does not exist

Available branches:
  main
  develop
  feature-auth

Usage: /worktree <existing-branch> <new-branch>
```

## 🔧 Что делает команда

### 1. Создаёт Git Worktree

```bash
# Определяет путь
currentDir: ~/CRT/fea/
worktreePath: ~/CRT/fea-feature-auth/

# Создаёт worktree
git worktree add ~/CRT/fea-feature-auth feature-auth
```

### 2. Синхронизирует .claude-project

```bash
# Копирует всю папку
cp -r ~/CRT/fea/.claude-project ~/CRT/fea-feature-auth/

# Результат:
# - Все docs доступны сразу
# - Все tasks видны
# - Project context на месте
```

### 3. Копирует и настраивает .env

```bash
# Копирует .env
cp .env ~/CRT/fea-feature-auth/.env

# Находит текущий порт
currentPort = 3000 (from .env)

# Находит свободный порт
newPort = findFreePort(3000)
# Проверяет: 3001, 3002, 3003...
# Первый свободный: 3001

# Обновляет PORT в worktree
sed 's/PORT=3000/PORT=3001/' ~/CRT/fea-feature-auth/.env

# Результат: worktree запускается на другом порту
```

### 4. Копирует CLAUDE.md (проектный)

```bash
# Если есть .claude/CLAUDE.md (project-specific)
cp .claude/CLAUDE.md ~/CRT/fea-feature-auth/.claude/

# Результат: проектные стандарты доступны в worktree
```

### 5. Создаёт WORKTREE-INFO.md

```markdown
# Worktree Information

Branch: feature-auth
Created: 2025-11-01
Source: main
Port: 3001

## Running
npm start  # Uses PORT=3001

## Cleanup
git worktree remove ~/CRT/fea-feature-auth
```

### 6. Выводит summary с next steps

```
✅ WORKTREE CREATED

Path: ~/CRT/fea-feature-auth/
Branch: feature-auth
Port: 3001

Next steps:
  1. cd ~/CRT/fea-feature-auth
  2. npm install
  3. /init-project  # Create branch docs
  4. npm start  # Runs on 3001
```

## 📊 Примеры использования

### Use Case 1: Работа над несколькими задачами параллельно

**Задача 1** в main worktree:
```bash
cd ~/CRT/fea
/do AUTH-123 "Implement auth"
# Working...
```

**Хотите начать Задачу 2**, не прерывая Задачу 1:
```bash
# Создаём worktree для новой задачи
/worktree feature-payments

# Результат:
# ~/CRT/fea-feature-payments/ created
# PORT=3001 configured

cd ~/CRT/fea-feature-payments
npm install
npm start  # Runs on 3001 (не конфликтует с 3000)

/do PAY-456 "Implement payments"
# Develop in parallel with AUTH-123
```

**Теперь**:
- Terminal 1: `cd ~/CRT/fea && npm start` (port 3000, AUTH-123)
- Terminal 2: `cd ~/CRT/fea-feature-payments && npm start` (port 3001, PAY-456)
- Обе задачи развиваются параллельно без конфликтов!

### Use Case 2: Быстрое создание worktree для hotfix

```bash
# Production bug, нужен срочный hotfix
/worktree main hotfix-critical-bug

# Результат:
# Branch: hotfix-critical-bug (от main)
# Worktree: ~/CRT/fea-hotfix-critical-bug/
# Port: 3002
# .claude-project synced (have main docs immediately)

cd ~/CRT/fea-hotfix-critical-bug
/do FIX-999 "Fix critical production bug"
# Быстрая разработка, отдельно от других веток
```

### Use Case 3: Review коллеги в отдельном worktree

```bash
# Коллега создал feature-auth, нужно review
git fetch origin

/worktree origin/feature-auth

# Результат:
# Worktree для remote branch
# Можно запустить и протестировать

cd ~/CRT/fea-feature-auth
npm install
npm start  # PORT=3001

# Review code
# Run tests
# Verify functionality
```

### Use Case 4: Версионные ветки

```bash
# Уже есть V-36, V-37
# Создаём V-38 от V-37

/worktree V-37 V-38

# Результат:
# Branch V-38 от V-37
# Worktree ~/CRT/fea-V-38/
# .claude-project включает docs для V-37 (parent)
# PORT=3003 (если 3000, 3001, 3002 заняты)

cd ~/CRT/fea-V-38
/init-project  # DIFF MODE создаст docs для V-38 на основе V-37
```

## 🔍 Детальная механика

### Определение пути worktree

**Convention**:
```
Current directory: ~/CRT/fea
Target branch: feature-auth
Worktree path: ~/CRT/fea-feature-auth
```

**Pattern**: `{parentDir}/{currentDirName}-{branchName}`

**Примеры**:
- `~/project/main` + `V-37` → `~/project/main-V-37`
- `~/app/src` + `hotfix` → `~/app/src-hotfix`
- `/var/www/api` + `feature-new` → `/var/www/api-feature-new`

### Поиск свободного порта

**Алгоритм**:
```javascript
1. Получить basePort из текущего .env (default: 3000)
2. Собрать используемые порты:
   - Scan все worktrees: grep PORT= */.env
   - Scan running processes: lsof -i
3. Проверять последовательно: basePort+1, basePort+2, ...
4. Первый свободный → использовать
5. Если 100 попыток не нашли → random 10000-20000
```

**Пример**:
```
Current worktrees:
  ~/CRT/fea/.env: PORT=3000
  ~/CRT/fea-V-37/.env: PORT=3001

findFreePort(3000):
  Check 3001 → used ✗
  Check 3002 → free ✓
  Return 3002
```

### Копирование файлов

**Что копируется**:
```
Source (current dir)    →    Target (worktree)
─────────────────────────────────────────────────
.claude-project/        →    .claude-project/  (full copy)
.env                    →    .env (PORT updated)
.claude/CLAUDE.md       →    .claude/CLAUDE.md (if exists)
```

**Что НЕ копируется**:
```
node_modules/     ← Rebuild с npm install
.git/             ← Shared (это git worktree feature)
build/            ← Rebuild
dist/             ← Rebuild
.env.test         ← User-specific
```

## ⚙️ Конфигурация портов

### Типичные конфликты портов

**Проблема**: Несколько worktrees запущены одновременно

**Без /worktree**:
```bash
# Worktree 1
cd ~/CRT/fea
npm start  # PORT=3000

# Worktree 2 (manual)
cd ~/CRT/fea-V-37
npm start  # PORT=3000 ← CONFLICT! ❌
# Error: Port 3000 already in use
```

**С /worktree**:
```bash
# Worktree 1 (original)
cd ~/CRT/fea
npm start  # PORT=3000

# Worktree 2 (created with /worktree)
cd ~/CRT/fea-V-37  # Created by /worktree V-37
npm start  # PORT=3001 ✓ (auto-configured)

# Worktree 3
/worktree V-38
cd ~/CRT/fea-V-38
npm start  # PORT=3002 ✓
```

**Результат**: Все worktrees запускаются одновременно без конфликтов

### Docker Compose порты

Если проект использует docker-compose.yml:

```yaml
# Original (fea/.env: PORT=3000)
services:
  app:
    ports:
      - "${PORT}:3000"  # 3000:3000

# Worktree (fea-V-37/.env: PORT=3001)
services:
  app:
    ports:
      - "${PORT}:3000"  # 3001:3000 ✓ No conflict
```

## 🎯 Best Practices

### 1. Используйте /worktree для долгоживущих веток

```bash
# Feature branch, которая будет развиваться неделями
/worktree feature-major-refactoring

# Работаете в отдельном worktree
# Main worktree не затронут
```

### 2. Один worktree = один контекст

```bash
# Worktree 1: Feature development
cd ~/CRT/fea-feature-auth
/do AUTH-123 "..."

# Worktree 2: Bug fixing
cd ~/CRT/fea-main
/do FIX-456 "..."

# Не смешиваются contexts
```

### 3. Cleanup после merge

```bash
# После merge feature → main
git checkout main
git merge feature-auth

# Удалить worktree
git worktree remove ~/CRT/fea-feature-auth

# Удалить ветку
git branch -d feature-auth
```

### 4. Используйте разные порты для одновременного запуска

```bash
# Terminal 1
cd ~/CRT/fea && npm start  # 3000

# Terminal 2
cd ~/CRT/fea-V-37 && npm start  # 3001

# Terminal 3
cd ~/CRT/fea-v36 && npm start  # 3002

# Все работают одновременно
```

### 5. Проверяйте /tasks из любого worktree

```bash
# Worktree A: создали задачу
cd ~/CRT/fea
/do TASK-1 "..."

# Worktree B: проверяем задачи
cd ~/CRT/fea-V-37
/tasks
# Shows TASK-1 ✓ (synced via worktree sync)
```

## ⚠️ Ограничения и известные проблемы

### 1. Disk space

Каждый worktree занимает место:
- Source code: duplicated
- node_modules: ~200-500 MB per worktree
- .claude-project: shared (~1-5 MB)

**Рекомендация**: Периодически удаляйте ненужные worktrees

### 2. Git database shared

Все worktrees используют один `.git/`:
- Commits видны везде
- Branches общие
- git fetch обновляет для всех

**Это feature**, не bug!

### 3. Port exhaustion

Если много worktrees (10+), порты могут закончиться в диапазоне 3000-3100

**Решение**: findFreePort fallback на random 10000-20000

### 4. npm install required

После создания worktree:
```bash
cd new-worktree
npm install  # Required, node_modules not copied
```

**Альтернатива**: Symlink node_modules (рискованно если deps различаются)

## 🔗 Интеграция с другими командами

### /worktree → /init-project

```bash
# 1. Create worktree
/worktree feature-dashboard

# 2. Navigate to worktree
cd ~/CRT/fea-feature-dashboard

# 3. Initialize docs for this branch
/init-project
# DIFF MODE: uses parent branch docs + git diff
# Creates: .claude-project/project/feature-dashboard/
```

### /worktree → /do

```bash
# 1. Create worktree
/worktree feature-auth

# 2. Develop task in worktree
cd ~/CRT/fea-feature-auth
/do AUTH-123 "Implement authentication"

# Task developed in isolated worktree
# Synced back to all worktrees automatically
```

### /tasks after /worktree

```bash
# Create multiple worktrees
/worktree feature-a
/worktree feature-b

# Create tasks in each
cd ~/CRT/fea-feature-a && /do TASK-A "..."
cd ~/CRT/fea-feature-b && /do TASK-B "..."

# Check from any worktree
cd ~/CRT/fea
/tasks
# Shows: TASK-A, TASK-B (both synced!)
```

## 📊 Пример полного workflow

### Scenario: Параллельная разработка двух features

```bash
# === SETUP ===

# Main worktree
cd ~/CRT/fea  # main branch
/init-project  # Create project docs

# === FEATURE 1 ===

/worktree feature-auth
cd ~/CRT/fea-feature-auth
npm install
npm start  # PORT=3001

# New terminal for development
/init-project  # DIFF MODE for feature-auth
/do AUTH-123 "JWT authentication"
# Phases 0-8... complete

# === FEATURE 2 (parallel) ===

# Back to main worktree
cd ~/CRT/fea
/worktree feature-payments
cd ~/CRT/fea-feature-payments
npm install
npm start  # PORT=3002 (auto-configured!)

# New terminal
/init-project  # DIFF MODE for feature-payments
/do PAY-456 "Stripe integration"
# Phases 0-8... complete

# === MONITORING ===

# From ANY worktree:
/tasks

# Output:
┌────────────┬───────────────────┬──────────┬──────────┐
│ AUTH-123   │ feature-auth      │ ✅ Done  │ Phase 8  │
│ PAY-456    │ feature-payments  │ 🔄 Active│ Phase 5  │
└────────────┴───────────────────┴──────────┴──────────┘

# === TESTING ===

# Terminal 1: Auth feature
cd ~/CRT/fea-feature-auth
curl http://localhost:3001/api/auth/login  # Works!

# Terminal 2: Payment feature
cd ~/CRT/fea-feature-payments
curl http://localhost:3002/api/payments  # Works!

# Both running simultaneously!

# === CLEANUP ===

# После merge feature-auth
git checkout main
git merge feature-auth
git push

# Remove worktree
git worktree remove ~/CRT/fea-feature-auth
git branch -d feature-auth

# Update main docs
/init-project  # SYNC MODE
```

## 🎯 Продвинутые use cases

### Use Case 1: Hotfix в production

```bash
# Production issue, нужен срочный fix
# Но в main worktree идёт другая работа

/worktree main hotfix-critical

cd ~/CRT/fea-hotfix-critical
# .claude-project уже скопирован (main docs доступны)
# PORT=3001 configured

/do FIX-999 "Critical production fix"
# Develop, test, complete

# Deploy
git checkout main
git merge hotfix-critical
git push

# Cleanup
git worktree remove ~/CRT/fea-hotfix-critical
```

### Use Case 2: Code review в отдельном окружении

```bash
# Коллега создал PR: feature-colleague-work
git fetch origin

/worktree origin/feature-colleague-work

cd ~/CRT/fea-feature-colleague-work
npm install
npm start  # PORT=3001

# Review:
# - Read code
# - Run application
# - Check tests: cd .claude-project/tasks/TASK-X/tests && npm test
# - Verify functionality

# После review: cleanup
git worktree remove ~/CRT/fea-feature-colleague-work
```

### Use Case 3: Версионная разработка

```bash
# Поддержка нескольких версий одновременно

# Version 36 maintenance
/worktree v36
cd ~/CRT/fea-v36
npm start  # PORT=3001

# Version 37 development
/worktree v37
cd ~/CRT/fea-v37
npm start  # PORT=3002

# Version 38 planning
/worktree V-37 V-38  # Create V-38 from V-37
cd ~/CRT/fea-V-38
npm start  # PORT=3003

# Все версии доступны одновременно
# Можно тестировать миграцию, совместимость
```

## 🛡️ Safety Features

### 1. Path validation

```bash
# Если worktree path уже существует
if [ -d "$worktreePath" ]; then
  Options:
    - Use different path
    - Remove and recreate
    - Cancel
fi
```

### 2. Source branch validation

```bash
# /worktree source target
if ! git rev-parse source >/dev/null 2>&1; then
  ERROR: Source branch doesn't exist
  Show available branches
  STOP
fi
```

### 3. Disk space check

```bash
availableSpace=$(df -BM . | ...)

if [ $availableSpace -lt 500 ]; then
  WARNING: Low disk space
  Options: Continue / Cancel
fi
```

### 4. Port conflict detection

```bash
# Before assigning port
# Check all worktree .env files
# Check running processes
# Find genuinely free port
```

## 📁 Структура после создания

**После `/worktree feature-auth`**:

```
~/CRT/
├── fea/                        # Original worktree (main)
│   ├── .claude-project/
│   │   ├── project/main/
│   │   └── tasks/AUTH-123/
│   ├── .env (PORT=3000)
│   └── [source code]
│
└── fea-feature-auth/           # New worktree (feature-auth)
    ├── .claude-project/        # ✓ Synced from fea/
    │   ├── project/
    │   │   ├── main/           # ✓ Copied (parent docs)
    │   │   └── feature-auth/   # Create with /init-project
    │   └── tasks/AUTH-123/     # ✓ Copied (visible here too)
    ├── .env (PORT=3001)        # ✓ Auto-configured
    ├── .claude/CLAUDE.md       # ✓ Copied
    ├── WORKTREE-INFO.md        # ✓ Created
    ├── node_modules/           # ← npm install needed
    └── [source code]           # ✓ Checked out to feature-auth
```

## 🚀 Quick Reference

```bash
# Create worktree for existing branch
/worktree V-37

# Create new branch + worktree from current
/worktree feature-new

# Create branch2 from branch1 + worktree
/worktree main feature-payments

# List all worktrees
git worktree list

# Remove worktree
git worktree remove path/to/worktree

# Remove worktree + delete branch
git worktree remove path/to/worktree
git branch -D branch-name
```

## 🎉 Готовность

**Статус**: ✅ Полностью реализовано

**Файлы**:
- `~/.claude/commands/worktree.md` - command definition
- `~/WORKTREE-COMMAND-GUIDE.md` - этот гайд

**Интеграция**:
- Использует worktree sync helper
- Совместимо с /init-project, /do, /tasks
- Automatic port configuration

**Следующий шаг**: Запустить `/worktree` для создания первого worktree

---

*Created: 2025-11-01*
*Integration with: /init-project, /do, /tasks, worktree-sync helper*
*Type: Worktree creation and configuration command*
