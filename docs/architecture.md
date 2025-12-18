# Architecture

This document describes the system architecture and deployment model.

## Repository / Deployment Model

**The data directory IS the repository.** Each data directory is a complete, self-contained task repository that can operate independently.

### Single Repository Characteristics

Each task repository (data directory) should behave like a standalone project repository:

* A task repository is **self-contained** and can run entirely locally with no remote configured.
* All functionality (creating, listing, updating tasks, etc.) must work with:

  * No network access.
  * No central server.
  * No git remote.
* If desired, a repository can be linked to one or more git remotes (e.g., GitHub, GitLab, a bare repo on a server), and:

  * Sync is handled using normal `git` workflows (`pull`, `push`, `fetch`, etc.).
  * There is no assumption of a single "canonical" or always-on server.
* Multiple machines can collaborate on the same task repository the same way they would on a code repository:

  * Clone, branch, commit, merge, push, and pull are all valid workflows.
  * Conflicts are resolved using standard git tooling.

In other words, a task repository should behave exactly like a code repository: fully functional on its own, with optional remotes for sync and collaboration, but no hard dependency on them.

### Multiple Repositories

A single server or user can have **multiple data directories**, each acting as an independent repository:

* Each data directory is a separate repository with its own tasks and configuration
* Each data directory can connect to **different remote repositories** (or no remote at all)
* This allows users to:
  * Separate personal and work tasks into different repositories
  * Maintain multiple projects with independent sync targets
  * Test or experiment with repositories without affecting production data
* The CLI `--data-dir` option allows users to specify which repository to operate on
* Global configuration can define default data directory, but users can override per-command

This design supports complex workflows where a user might have:
* `~/tasks/personal/` → syncs to `github.com/user/personal-tasks`
* `~/tasks/work/` → syncs to `gitlab.com/company/work-tasks`
* `~/tasks/experimental/` → local-only, no remote

### Repository Structure

A task repository (data directory) has the following structure:

```
data-directory/         # This IS the repository
├── tasks/              # Directory containing task files (TOML)
│   ├── <uuid>.toml    # Task files named by UUID (e.g., 550e8400-e29b-41d4-a716-446655440000.toml)
│   └── ...
├── config.toml         # Repository configuration (hooks, settings)
└── .git/               # Git repository (if using git for sync)
```

**Important**: The data directory itself is the repository. There is no separate "repository" concept—the data directory contains everything needed to function as a complete task repository.

**Task File Naming**: Task files are stored in the `tasks/` directory and named using their UUID identifier in the format `<uuid>.toml`. For example, a task with ID `550e8400-e29b-41d4-a716-446655440000` would be stored as `tasks/550e8400-e29b-41d4-a716-446655440000.toml`.

The `config.toml` file in the data directory root contains:
* Hook definitions (see [Design Decisions](design-decisions.md))
* Repository-specific settings
* Overrides for global configuration
* Optional metadata

This structure keeps configuration version-controlled alongside tasks, ensuring hooks and settings sync across machines when the repository is cloned or synced.

**Git Ignore Patterns**: If using git for synchronization, the repository should include a `.gitignore` file. Recommended patterns:
* Cache or index files (if any are created in future milestones)
* Temporary files
* Editor backup files (e.g., `*.swp`, `*~`)
* OS-specific files (e.g., `.DS_Store`, `Thumbs.db`)

All task files (`tasks/*.toml`) and the `config.toml` file should be committed to git.

### Configuration File Locations

The system uses multiple configuration files:

* **Global config**: `$XDG_CONFIG_HOME/mytask/config.toml` (typically `~/.config/mytask/config.toml`)
  * User-wide defaults and preferences
  * Default data directory location
  
* **Data directory config**: `config.toml` in the task repository root
  * Repository-specific settings
  * Hooks and automation
  
* **Task-level config**: Within individual task TOML files (future feature)
  * Task-specific overrides

See [Design Decisions](design-decisions.md) for details on the configuration hierarchy and resolution order.

---

## Interoperability Through Git

Because each data directory is a git-managed directory of plain-text files, any external tool that understands git can also interact with the task data. This enables:

* Mobile or desktop apps that embed a git client (e.g., an Android app) to clone, edit, or sync tasks directly.
* Third-party tools to parse or manipulate tasks without needing to integrate with a custom API or service.
* Automation or scripting layers to consume tasks the same way they would consume files in any code repository.
* Each data directory can have its own git remote(s), allowing independent sync targets.

This design keeps task data maximally open, inspectable, and ecosystem-friendly—any tool that understands git and text files can participate. Multiple data directories can coexist, each with their own git configuration and remote repositories.

---

## Environment & Constraints

### User Environment

* I manage multiple machines/servers (including remote boxes).
* I already have:

  * `git` everywhere.
  * SSH everywhere.
  * Familiarity with shell scripting and automation.
* I prefer:

  * Keyboard-centric workflows.
  * Tools that can be scripted, piped, and composed.

### System Requirements

This means the task manager should:

* Fit well into a dotfiles / infra-as-code environment.
* Avoid hidden magic.
* Play nicely with `git` hooks, cron jobs, etc.
* Provide hooks system for automation and integration (separate from git hooks).

---

## Component Design

The system will consist of:

* **Data layer**: File-based storage using TOML format
* **Core logic**: Task operations (create, read, update, delete, query)
* **Recurrence engine**: Task generation and auto-completion for repeating tasks
* **Hooks system**: Event-driven script execution for automation and integration
* **CLI interface**: Command-line tool for user interaction
* **Git integration**: Detection and interaction with git repositories
* **Conflict handling**: Detection and resolution of merge conflicts
* **Configuration management**: Multi-tiered TOML-based configuration system (global, data directory, task-level)

### Hooks System Architecture

The hooks system is integrated into the core task operations:

* **Hook discovery**: Loads hook configuration from TOML config file at repository initialization
* **Hook execution**: Executes hooks at appropriate points in task operation lifecycle
* **Hook context**: Provides task data, operation type, and environment to hook scripts
* **Error handling**: Manages hook failures gracefully with configurable abort behavior
* **Performance**: Hooks are designed to be fast and non-blocking where possible

Hooks enable:
* **Validation**: Pre-operation validation of task data
* **Automation**: Post-operation actions (notifications, logging, etc.)
* **Integration**: Connect with external systems and tools
* **Customization**: Extend functionality without modifying core code

### Recurrence Engine Architecture

The recurrence engine handles automatic task generation and auto-completion:

* **Task generation**: Creates new task instances based on recurrence patterns
* **Auto-completion**: Handles incomplete recurring tasks according to configured rules
* **Pattern support**: Implements three recurrence patterns (fixed, relative, sequential)
* **Idempotency**: Ensures safe operation across multiple hosts/machines
* **Scheduling**: Manages when to generate next tasks and when to auto-complete

The engine integrates with:
* **Core logic**: Triggers task creation and updates
* **Hooks system**: Can trigger hooks when generating or auto-completing tasks
* **CLI**: Provides commands for managing recurring tasks and checking auto-completion status

