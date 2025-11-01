# Branch-Aware Commands - Complete Update

Обновлены команды `/init-project` и `/do` с поддержкой per-branch workflow и автоматической синхронизации.

## 🎯 Что изменилось

### 1. `/init-project` команда - Per-Branch Documentation

**Старая структура**:
```
.claude-project/project/
├── ABOUT.md
├── business/
└── architecture/
```

**Новая структура (per-branch)**:
```
.claude-project/project/
├── main/                    # Docs for main branch
│   ├── ABOUT.md
│   ├── business/
│   └── architecture/
├── feature-auth/            # Docs for feature-auth branch
│   ├── ABOUT.md
│   ├── business/
│   └── architecture/
└── develop/                 # Docs for develop branch
    ├── ABOUT.md
    └── ...
```

**Режимы работы** (расширено с 2 до 3):

| Режим | Условие | Действие |
|-------|---------|----------|
| **INIT MODE** | Нет docs ни для одной ветки | Создаёт docs с нуля |
| **SYNC MODE** | Docs для текущей ветки существуют | Синхронизирует с кодом |
| **DIFF MODE** | Docs для других веток есть, для текущей нет | Создаёт docs на основе diff от parent |

### 2. `/do` команда - Branch Validation & Tracking

**Добавлено**:

✅ **Git branch tracking** в TASK.md:
```markdown
## Git Metadata
**Task Branch**: `feature/AUTH-123`
**Parent Branch**: `main`
**Created**: 2025-11-01
```

✅ **Branch validation** при продолжении задачи:
- Если задача начата в ветке A, но сейчас в ветке B → предупреждение
- Опции: переключиться на A / продолжить в B / отменить

✅ **Branch creation offer** при старте новой задачи:
- Предлагает создать `feature/{task-name}` branch
- Или позволяет ввести custom название
- Или продолжить в текущей ветке

✅ **Relative diff analysis**:
- Все анализы (bugs, tests, cleanliness) относительно parent branch
- `git diff ${parentBranch}...${taskBranch}`
- Анализируется только код задачи, не весь проект

✅ **Parent branch context**:
- Читает project docs из `.claude-project/project/${parentBranch}/`
- Task разрабатывается в контексте parent branch состояния

## 🔄 Три режима /init-project команды

### INIT MODE - Новый проект

**Когда**: Нет documentation ни для одной ветки

**Действия**:
1. Получает текущую ветку: `git branch --show-current`
2. Создаёт `.claude-project/project/${currentBranch}/`
3. Интерактивно собирает информацию о проекте
4. Создаёт полную документацию с нуля
5. Сохраняет метаданные: initialized from `${currentBranch}`, date

**Пример**:
```bash
# В ветке main, нет никакой документации
git checkout main
/init-project

# Создаёт: .claude-project/project/main/
```

### SYNC MODE - Синхронизация существующей документации

**Когда**: Документация для текущей ветки уже существует

**Действия**:
1. Читает существующую документацию текущей ветки
2. Анализирует текущий код
3. Находит расхождения (docs vs code)
4. Спрашивает пользователя, что правильно
5. Обновляет документацию
6. Помечает изменения датой

**Пример**:
```bash
# В ветке main, docs уже есть (.claude-project/project/main/)
git checkout main
/init-project

# SYNC MODE: обновляет .claude-project/project/main/
```

### DIFF MODE - Создание docs на основе diff (НОВОЕ!)

**Когда**: Для текущей ветки нет docs, но для других веток есть

**Действия**:
1. Определяет parent branch (откуда создана текущая ветка)
2. Читает документацию parent branch
3. Анализирует `git diff ${parentBranch}...${currentBranch}`
4. Создаёт docs для текущей ветки:
   - **Копирует** неизменённые секции из parent
   - **Обновляет** изменённые секции на основе git diff
   - **Добавляет** новые секции с пометкой "Added in this branch"
5. Помечает источник: "Based on `${parentBranch}` documentation"

**Пример**:
```bash
# Есть .claude-project/project/main/ (полная документация)
# Создали новую ветку
git checkout -b feature/auth

# Сделали изменения (добавили AuthService, новые endpoints)
# Запускаем init
/init-project

# DIFF MODE:
# 1. Определяет parent = main
# 2. Читает .claude-project/project/main/
# 3. Анализирует git diff main...feature/auth
# 4. Создаёт .claude-project/project/feature-auth/:
#    - Копирует business docs (не изменились)
#    - Обновляет architecture/SYSTEM-DESIGN.md (добавлен AuthService)
#    - Обновляет architecture/API-DESIGN.md (новые endpoints)
#    - Помечает: "Based on main branch, updated for feature/auth"
```

**Результат**: `.claude-project/project/feature-auth/` содержит:
- Полную документацию (унаследованную + обновлённую)
- Только изменённые секции переписаны
- Остальное скопировано из parent
- Все изменения помечены

## 🔄 Workflow /do с branch awareness

### Новая задача в новой ветке

```bash
# В main ветке
git checkout main

# Убедимся, что есть project docs
/init-project  # Если нет docs для main

# Запускаем задачу
/do AUTH-123 "Implement JWT authentication"
```

**Что происходит:**
1. Валидация: "AUTH-123" ✅ (валидное название)
2. Git branch check: текущая ветка = `main`
3. Предложение: "Create feature/AUTH-123 branch?"
   - User выбирает "Yes"
   - `git checkout -b feature/AUTH-123`
   - Сохраняет: taskBranch = `feature/AUTH-123`, parentBranch = `main`
4. Создаёт `tasks/AUTH-123/` с git metadata
5. **Phase 0**: Читает project context из `.claude-project/project/main/` (parent branch)
6. **Phases 1-8**: Разрабатывает задачу
7. **Bug hunting**: Анализирует `git diff main...feature/AUTH-123` (только изменения задачи)
8. **Tests**: Создаёт тесты для новой функциональности (на основе diff)

### Продолжить задачу в той же ветке

```bash
# Вчера работали, прервали на Phase 3
git checkout feature/AUTH-123

/do AUTH-123
```

**Что происходит:**
1. Проверяет задача существует ✅
2. Читает git metadata из TASK.md:
   - taskBranch = `feature/AUTH-123`
   - parentBranch = `main`
3. Git branch check:
   - Текущая ветка = `feature/AUTH-123`
   - Ветка из TASK.md = `feature/AUTH-123`
   - **Совпадают** ✅
4. Читает SUMMARY.md → Phase 2 completed
5. Продолжает с Phase 3

### Продолжить задачу в НЕПРАВИЛЬНОЙ ветке (ошибка)

```bash
# Случайно переключились на другую ветку
git checkout feature/payments

# Пытаемся продолжить задачу AUTH
/do AUTH-123
```

**Что происходит:**
1. Проверяет задача существует ✅
2. Читает git metadata из TASK.md:
   - taskBranch = `feature/AUTH-123`
   - parentBranch = `main`
3. Git branch check:
   - Текущая ветка = `feature/payments` ❌
   - Ветка из TASK.md = `feature/AUTH-123` ❌
   - **НЕ совпадают!** ⚠️

**Предупреждение:**
```
⚠️  WARNING: Git branch mismatch detected!

Task was started in branch: feature/AUTH-123
You are currently in branch: feature/payments

This may cause issues if:
  - Code from different branches is incompatible
  - Tests expect specific branch state

How to proceed?
  1. Switch to task branch (feature/AUTH-123)
  2. Continue in current branch (feature/payments)
  3. Cancel task
```

**User выбирает** вариант 1 → `git checkout feature/AUTH-123` → продолжает

### Создать docs для feature branch

```bash
# Есть docs для main
# ls .claude-project/project/main/ ✓

# Создали feature branch и сделали изменения
git checkout -b feature/new-api
# ... делаем изменения ...
git commit -m "Add new API endpoints"

# Создаём docs для feature branch
/init-project
```

**Что происходит**:

1. **Mode detection**:
   - currentBranch = `feature/new-api`
   - Docs для `feature/new-api`? → NO
   - Docs для других веток? → YES (main)
   - **Режим: DIFF MODE**

2. **Parent identification**:
   - Проверяет git reflog
   - Или спрашивает: "Which branch is feature/new-api based on?"
   - User: "main"
   - parentBranch = `main`

3. **Read parent docs**:
   - Читает всю документацию из `.claude-project/project/main/`

4. **Analyze git diff**:
   - `git diff main...feature/new-api`
   - Находит: добавлены новые контроллеры, эндпоинты
   - Изменены: некоторые сервисы

5. **Create docs for feature/new-api**:
   - **Копирует** business docs (не изменились)
   - **Обновляет** architecture/SYSTEM-DESIGN.md (новые компоненты)
   - **Обновляет** architecture/API-DESIGN.md (новые endpoints)
   - **Копирует** conventions, setup (не изменились)
   - **Помечает** все изменения: "Added in feature/new-api branch"

**Результат**: `.claude-project/project/feature-new-api/` с:
- Полной документацией
- Унаследованным контекстом из main
- Обновлёнными секциями для изменений ветки

## 📊 Преимущества branch-aware workflow

### Для разработчиков

✅ **Контекст ветки**:
- Каждая feature ветка имеет свою документацию
- Понятно, что изменилось относительно main

✅ **Меньше дублирования**:
- DIFF MODE копирует неизменённое из parent
- Обновляет только то, что изменилось

✅ **История изменений**:
- Документация отслеживает, что добавлено в каждой ветке
- Можно сравнить docs разных веток

✅ **Безопасность**:
- /do предупреждает, если продолжаете задачу не в той ветке
- Предотвращает путаницу и конфликты

### Для AI-ассистентов (Claude)

✅ **Правильный контекст**:
- /do читает project context из parent branch
- Понимает, в каком состоянии проекта разрабатывается задача

✅ **Точный анализ**:
- Bug hunting анализирует только изменения задачи
- Не ищет баги во всём проекте

✅ **Релевантные тесты**:
- Тесты создаются только для новой функциональности
- На основе diff от parent branch

### Для проектов

✅ **Эволюция документации**:
- Main branch имеет стабильную документацию
- Feature branches имеют дельты
- После merge feature → main, docs тоже можно смержить

✅ **Параллельная разработка**:
- Несколько feature веток могут иметь свои docs
- Не конфликтуют друг с другом

✅ **Прозрачность изменений**:
- Видно, какие изменения в какой ветке
- Документация отражает branch-specific features

## 🔍 Детальные примеры

### Пример 1: Полный цикл с branch workflow

```bash
# 1. Инициализация main branch
git checkout main
/init-project
# Создаёт: .claude-project/project/main/
# Вопросы о проекте, полная документация

# 2. Первая задача
/do AUTH-123 "Implement JWT authentication"
# Предлагает создать feature/AUTH-123
# Создаёт ветку: feature/AUTH-123 (parent: main)
# Сохраняет в TASK.md: taskBranch = feature/AUTH-123, parentBranch = main
# Читает context из .claude-project/project/main/
# Разрабатывает задачу (phases 0-8)
# Bug hunting на: git diff main...feature/AUTH-123

# 3. Создать docs для feature branch (опционально)
git checkout feature/AUTH-123
/init-project
# DIFF MODE:
# - Parent = main
# - Читает .claude-project/project/main/
# - Анализирует git diff main...feature/AUTH-123
# - Создаёт .claude-project/project/feature-AUTH-123/
# - Копирует неизменённое, обновляет изменённое

# 4. Прервали задачу, продолжаем на следующий день
git checkout feature/AUTH-123
/do AUTH-123
# Branch validation: текущая = feature/AUTH-123, TASK = feature/AUTH-123 ✓
# Reads SUMMARY.md → continues from last phase

# 5. Merge в main
git checkout main
git merge feature/AUTH-123

# 6. Синхронизация main docs
/init-project
# SYNC MODE (для main):
# - Читает .claude-project/project/main/
# - Анализирует новый код (из merged feature)
# - Обновляет документацию main
```

### Пример 2: Случайно не в той ветке

```bash
# Задача AUTH-123 в ветке feature/AUTH-123
# Но случайно переключились на develop
git checkout develop

# Пытаемся продолжить задачу
/do AUTH-123
```

**Результат**:
```
⚠️  WARNING: Git branch mismatch detected!

Task was started in branch: feature/AUTH-123
You are currently in branch: develop

This may cause issues if:
  - Code from different branches is incompatible
  - Tests expect specific branch state

How to proceed?
  1. Switch to task branch (feature/AUTH-123) ← Recommended
  2. Continue in current branch (develop)
  3. Cancel task
```

User выбирает 1 → автоматически `git checkout feature/AUTH-123` → продолжает задачу

### Пример 3: DIFF MODE для feature branch

```bash
# Есть полная документация для main
ls .claude-project/project/main/
# ABOUT.md, business/, architecture/, etc. ✓

# Создаём feature branch
git checkout -b feature/new-dashboard

# Разрабатываем (добавляем DashboardController, новые endpoints)
# ... coding ...
git add . && git commit -m "Add dashboard feature"

# Создаём docs для feature branch
/init-project
```

**Что делает DIFF MODE:**

1. **Detects mode**:
   ```
   📄 Mode: DIFF - Documentation exists for other branches
      Will create docs for feature/new-dashboard based on changes from parent
   ```

2. **Identifies parent**:
   ```
   📍 Parent branch identified: main
   ```

3. **Reads parent docs**:
   ```
   📖 Reading parent branch documentation: .claude-project/project/main/
   ✅ Parent documentation loaded
   ```

4. **Analyzes diff**:
   ```
   📊 Branch Diff Analysis:
      Parent: main
      Current: feature/new-dashboard
      Commits ahead: 5
      Files changed: 8
   ```

5. **Categorizes changes**:
   ```
   Architecture Changes:
   - ✓ New service: DashboardService
   - ✓ New controller: DashboardController

   API Changes:
   - ✓ New endpoint: GET /api/dashboard/stats
   - ✓ New endpoint: POST /api/dashboard/widgets

   Data Model Changes:
   - ✓ New entity: Widget
   ```

6. **Creates branch docs**:
   ```
   Creating: .claude-project/project/feature-new-dashboard/

   ABOUT.md:
     ✓ Copied project name, tagline (unchanged)
     ✓ Updated status: "Current Focus: Dashboard feature"
     ✓ Added: "Branch Context" section

   business/:
     ✓ Copied all files (business requirements unchanged)
     ✓ Note: "Inherited from parent branch main"

   architecture/SYSTEM-DESIGN.md:
     ✓ Copied unchanged components from parent
     ✓ Added: DashboardService [Added in feature/new-dashboard]
     ✓ Added: DashboardController [Added in feature/new-dashboard]

   architecture/API-DESIGN.md:
     ✓ Copied existing endpoints from parent
     ✓ Added: GET /api/dashboard/stats [Added in feature/new-dashboard]
     ✓ Added: POST /api/dashboard/widgets [Added in feature/new-dashboard]

   architecture/DATA-MODEL.md:
     ✓ Copied existing entities from parent
     ✓ Added: Widget entity [Added in feature/new-dashboard]
   ```

**Итоговая структура**:
```
.claude-project/project/feature-new-dashboard/ABOUT.md:

# MyProject

> SaaS Analytics Platform

## Quick Overview

[Same as main - inherited]

## Branch Context

**Current Branch**: `feature/new-dashboard`
**Parent Branch**: `main`
**Diverged**: 5 commits ahead
**Key Changes**:
- Added Dashboard feature
- New DashboardService and controller
- New API endpoints for dashboard stats
- New Widget entity

## Documentation Metadata

- **Initialized**: 2025-11-01 from branch `feature/new-dashboard`
- **Based on**: Documentation from `main` branch (copied + updated)
- **Last updated**: 2025-11-01

---

> This documentation reflects the state of the `feature/new-dashboard` branch.
> For parent branch state, see `.claude-project/project/main/`
```

## 🎯 Branch-specific task development

### Workflow integration

```bash
# 1. Main branch - initial project setup
git checkout main
/init-project
# Creates: .claude-project/project/main/ (full docs)

# 2. Feature branch - new task
git checkout -b feature/AUTH-123
/do AUTH-123 "Implement authentication"
# Offers to stay in feature/AUTH-123 (already in feature branch)
# Saves: taskBranch = feature/AUTH-123, parentBranch = main
# Reads context from: .claude-project/project/main/
# Analyzes changes: git diff main...feature/AUTH-123

# 3. Feature branch - create docs (optional)
/init-project
# DIFF MODE: creates .claude-project/project/feature-AUTH-123/
# Based on main docs + diff changes

# 4. Another developer - different feature
git checkout main
git checkout -b feature/payments
/do PAY-456 "Implement payment gateway"
# Creates branch feature/PAY-456
# Reads context from: .claude-project/project/main/
# Independent from AUTH-123 task

# 5. Merge AUTH-123 to main
git checkout main
git merge feature/AUTH-123

# 6. Update main docs
/init-project
# SYNC MODE for main:
# - Reads .claude-project/project/main/
# - Finds new code from AUTH-123 merge
# - Updates main docs with authentication feature
```

## 📁 Финальная структура проекта

```
my-project/
├── .claude-project/
│   ├── tasks/
│   │   ├── AUTH-123/              # Task in feature/AUTH-123 branch
│   │   │   ├── TASK.md            # Git metadata: branch = feature/AUTH-123, parent = main
│   │   │   ├── SYSTEM-DESIGN.md
│   │   │   ├── SUMMARY.md
│   │   │   ├── CHANGES.diff       # git diff main...feature/AUTH-123
│   │   │   ├── files/
│   │   │   └── tests/
│   │   │
│   │   └── PAY-456/               # Task in feature/PAY-456 branch
│   │       ├── TASK.md            # Git metadata: branch = feature/PAY-456, parent = main
│   │       └── ...
│   │
│   └── project/
│       ├── main/                  # Docs for main branch (stable, production)
│       │   ├── ABOUT.md
│       │   ├── business/
│       │   └── architecture/
│       │
│       ├── feature-AUTH-123/      # Docs for feature branch (optional)
│       │   ├── ABOUT.md           # Based on main + auth changes
│       │   └── ...
│       │
│       └── develop/               # Docs for develop branch (if exists)
│           └── ...
│
├── .gitignore                     # Contains: .claude-project/
└── [source code]
```

## ✅ Критерии качества

### Для /do команды

- [ ] Task name validation работает корректно
- [ ] Git metadata сохраняется в TASK.md
- [ ] Branch validation при продолжении задачи
- [ ] Offers branch creation для новых задач
- [ ] Читает project context из parent branch
- [ ] Все анализы используют diff от parent branch
- [ ] SUMMARY.md tracks progress с branch info

### Для /init-project команды

- [ ] Per-branch directory structure создаётся
- [ ] INIT MODE для первой инициализации
- [ ] SYNC MODE для существующих branch docs
- [ ] DIFF MODE для новых веток с parent docs
- [ ] Parent branch determination работает
- [ ] Git diff analysis точный
- [ ] Копирование unchanged секций
- [ ] Обновление changed секций
- [ ] Branch metadata в ABOUT.md

## 🚦 Готовность

**Статус**: ✅ Полностью реализовано

**Обновлённые файлы**:
- `~/.claude/commands/do.md` - branch awareness, validation, parent context
- `~/.claude/commands/init-project.md` - per-branch structure, 3 modes (INIT/SYNC/DIFF)

**Документация**:
- `~/DO-COMMAND-GUIDE.md` - полный гайд по /do
- `~/INIT-COMMAND-SETUP.md` - полный гайд по /init-project (обновить!)
- `~/BRANCH-AWARE-COMMANDS.md` - этот файл

**Следующие шаги**:
1. Обновить INIT-COMMAND-SETUP.md с DIFF MODE
2. Протестировать оба commands на реальном проекте

---

*Created: 2025-11-01*
*Branch-aware workflow implementation*
