# Design Decisions

This document captures the key design decisions made for the task manager system.

## Storage Model Decision

**Initial approach**: Flat `tasks/` directory with all task files in a single location.

* Status encoded in file metadata (not filesystem location)
* Simple to implement and reason about
* Easy to list, search, and manipulate with standard tools

**Future extensibility**: Structure can be added later if needed (e.g., `tasks/by-project/`, `tasks/archive/`) without breaking existing workflows. This hybrid approach allows us to start simple and evolve the organization as requirements become clearer.

---

## File Format

Tasks will be stored as **TOML** files with the following structure:

* TOML frontmatter for structured metadata (ID, status, dates, tags, etc.)
* Optional freeform body text for notes/description
* Human-readable and merge-friendly
* Easy to parse with standard tools (`toml-cli`, `jq` with TOML support, etc.)

TOML provides a good balance between human readability and structured data, making it ideal for tasks that need to be both machine-parseable and manually editable.

---

## Hooks System

The task manager includes a **hooks system** (similar to git hooks but separate from git) that allows users to execute scripts at specific events during task operations. Hooks are a first-class feature designed into the system from the start, not bolted on later.

### Hook Events

Hooks can be triggered at the following events:

* **pre-create**: Before a task is created
* **post-create**: After a task is successfully created
* **pre-update**: Before a task is updated
* **post-update**: After a task is successfully updated
* **pre-delete**: Before a task is deleted
* **post-delete**: After a task is successfully deleted
* **pre-list**: Before listing tasks (allows filtering/modification of query)
* **post-list**: After listing tasks (allows post-processing of results)

### Hook Configuration Format

Hooks are configured in TOML configuration files. Hooks can be defined in:

* **Data directory config**: `config.toml` in the task repository root (repository-specific hooks)
* **Global config**: `$XDG_CONFIG_HOME/mytask/config.toml` (user-wide default hooks)

Each hook event is defined as a **top-level TOML table** (section), allowing multiple hooks per event. Data directory hooks take precedence over global hooks for the same event:

```toml
[hooks.pre-create]
script = "/path/to/pre-create-script.sh"
enabled = true

[hooks.post-create]
script = "/path/to/post-create-script.sh"
enabled = true

[hooks.pre-update]
script = "/path/to/pre-update-script.sh"
enabled = true
```

### Hook Execution

* Hooks receive task data (as TOML or JSON) via stdin
* Hooks can modify task data (pre- hooks) or perform side effects (post- hooks)
* Pre- hooks can abort the operation by exiting with non-zero status
* Hook scripts are executed in the repository root directory
* Hook failures are logged but don't necessarily abort operations (configurable per hook)

### Design Rationale

* **TOML top-level tables**: Using TOML top-level sections (tables) provides a clean, structured way to define hooks that's consistent with the task file format
* **Separate from git**: Hooks are independent of git hooks, allowing task-specific automation without interfering with git workflows
* **First-class feature**: Built into the core architecture ensures hooks are reliable, well-tested, and properly integrated with all task operations
* **Scriptable**: Hooks enable automation, validation, notifications, and integration with other tools

---

## Configuration System

The task manager uses a **multi-tiered configuration system** that allows settings to be defined at different levels, with higher-priority levels overriding lower-priority ones.

### Configuration Hierarchy

Configuration is resolved in the following order (highest priority first):

1. **CLI options**: Command-line flags override all configuration files
2. **Task-level configuration**: Individual tasks can override certain settings (if supported)
3. **Data directory configuration**: Repository-specific settings in the data directory
4. **Global configuration**: User-wide defaults following XDG conventions

### Global Configuration

Global configuration follows **XDG Base Directory Specification**:

* **Location**: `$XDG_CONFIG_HOME/mytask/config.toml` (defaults to `~/.config/mytask/config.toml` if `XDG_CONFIG_HOME` is unset)
* **Purpose**: User-wide defaults and preferences
* **Contents**:
  * Default data directory location
  * User preferences (editor, date format, etc.)
  * Global hook definitions (if desired)
  * Default settings for new repositories

### Data Directory Configuration

**The data directory IS the repository.** Each data directory is a complete, independent task repository.

Data directory configuration is repository-specific:

* **Location**: `config.toml` in the data directory root (the data directory itself is the repository)
* **Purpose**: Repository-specific settings and hooks
* **Contents**:
  * Hook definitions (see [Hooks System](#hooks-system))
  * Repository-specific settings
  * Overrides for global configuration
  * Optional metadata

The data directory location can be:
* Specified via CLI option (e.g., `--data-dir` or `-d`)
* Defined in global configuration file
* Defaults to a standard location (e.g., `~/.local/share/mytask` or current directory)

**Multiple data directories**: A single user or server can have multiple data directories, each acting as an independent repository. Each data directory can connect to different remote repositories (or no remote at all). This allows separation of concerns (e.g., personal vs. work tasks) and independent sync targets.

### Task-Level Configuration

Individual tasks may be able to override certain configuration values:

* **Location**: Within the task's TOML file itself
* **Purpose**: Task-specific behavior overrides
* **Scope**: Limited to settings that make sense per-task (e.g., notification preferences, custom hooks)
* **Status**: This is a potential future feature; exact scope to be determined

### Configuration Resolution

When resolving a configuration value:

1. Check CLI options first
2. Check task-level configuration (if applicable)
3. Check data directory `config.toml`
4. Check global `config.toml`
5. Use built-in defaults

### Future Extensibility

The configuration system is designed to be extensible. Future additions could include:

* **Current directory configuration**: `.mytask/config.toml` in current working directory
* **Parent directory search**: Walk up directory tree looking for config files
* **Environment variables**: Override specific settings via environment variables
* **Per-command configuration**: Command-specific config files

### Design Rationale

* **XDG compliance**: Follows standard Unix conventions for configuration location
* **Multi-tiered**: Allows both global defaults and per-repository customization
* **CLI override**: Ensures command-line always wins for flexibility
* **Version-controlled**: Data directory config can be committed to git, syncing settings across machines
* **Extensible**: Architecture supports future configuration sources without breaking existing setups

