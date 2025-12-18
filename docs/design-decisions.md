# Design Decisions

This document captures the key design decisions made for the task manager system.

## Forgiveness Principle

**Core Philosophy**: The application must be **as forgiving as possible** while
maintaining data integrity and usability.

**Rationale**: Users should be able to quickly create tasks manually, make
mistakes, and recover gracefully. The system should accommodate:
- Invalid filenames (non-UUID format)
- Incomplete or malformed TOML files
- Manual edits that break format conventions
- Quick command-line operations that don't follow strict formats

**Implementation Approach**:
- **Automatic recovery**: Where possible, automatically fix or complete invalid
  data
- **Graceful degradation**: Continue operating even with some invalid files
- **Recovery tools**: Provide commands to validate and fix issues
- **Clear error messages**: When automatic recovery isn't possible, provide
  helpful guidance
- **Preserve user intent**: When fixing issues, preserve as much user content
  as possible

**Examples**:
- Files with invalid names should be automatically renamed to UUID format
- Partial TOML structures should be completed with required fields
- Invalid date formats should be parsed leniently where possible
- Missing required fields should be inferred or prompted for
- CLI option formats are forgiving: `--tag`, `-tag`, `tag:`, `tag=` are all
  equivalent (only the option name matters)
- Multiple values can be specified as comma-separated lists or repeated
  options, accommodating different user preferences and typos

### Notes Entry Timestamp Handling

When notes entries are manually added without timestamps, the application
handles them forgivingly:

- **Entry between existing entries**: If a note entry is added manually
  without a timestamp and is positioned between existing entries, the
  application will assign a timestamp that is the shortest reasonable time
  after the previous entry's timestamp. This preserves chronological order
  while accommodating manual edits.

- **Last entry**: If a note entry is added manually without a timestamp and
  is the last entry in the notes array, the application will use the current
  timestamp (when the program is run) as the entry's timestamp.

- **Sorting**: Notes entries should be maintained in chronological order by
  timestamp. The application will need to sort the `[[notes]]` array when
  reading task files to ensure proper date ordering, especially after manual
  edits or when entries are added out of order.

This forgiving approach allows users to quickly add notes without worrying
about timestamp formatting, while the application maintains proper
chronological ordering.

See [TODO.md](../TODO.md) for future work on invalid filename and format
recovery.

---

## Storage Model Decision

**Initial approach**: Flat `tasks/` directory with all task files in a single location.

* Status encoded in file metadata (not filesystem location)
* Simple to implement and reason about
* Easy to list, search, and manipulate with standard tools

**Future extensibility**: Structure can be added later if needed (e.g., `tasks/by-project/`, `tasks/archive/`) without breaking existing workflows. This hybrid approach allows us to start simple and evolve the organization as requirements become clearer.

---

## File Format

Tasks are stored as **TOML** files organized into three sections:

* **`[task]`** - User-modifiable fields (description, status, dates, tags, etc.)
* **`[meta]`** - Program-managed fields (ID, timestamps, etc.)
* **`[[notes]]`** - Timestamped journal entries (user notes and app logs)

This structure is human-readable and merge-friendly, making it easy to parse with
standard tools (`toml-cli`, `jq` with TOML support, etc.) while clearly
separating user-modifiable content from program-managed metadata.

TOML provides a good balance between human readability and structured data,
making it ideal for tasks that need to be both machine-parseable and manually
editable.

**Schema**: The authoritative source of truth for the task file format is the
JSON Schema definition in `docs/schema/task-file-schema.json`. The Perl module
`lib/MyTask/Schema.pm` provides programmatic validation against this schema.

See [Task File Format](task-file-format.md) for complete format specification.

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

1. **CLI options**: Command-line flags override all configuration files and environment variables
2. **Environment variables**: System environment variables override configuration files
3. **Task-level configuration**: Individual tasks can override certain settings (if supported)
4. **Data directory configuration**: Repository-specific settings in the data directory
5. **Global configuration**: User-wide defaults following XDG conventions
6. **Built-in defaults**: System defaults if no other configuration is found

### Built-in Default Configuration

When no configuration files, environment variables, or CLI options are provided, the system uses these built-in defaults:

* **Data directory**: Current working directory (`.`)
  * Rationale: Allows immediate use without setup; users can override via CLI or config
* **Editor**: `$EDITOR` environment variable, or `vi` if `$EDITOR` is unset
  * Rationale: Respects user's system editor preference; falls back to universal default
* **Date format**: ISO 8601 (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS` for timestamps)
  * Rationale: Standard, unambiguous, sortable format
* **Time zone**: System timezone (as reported by OS)
  * Rationale: Uses system default; can be overridden if needed
* **Hooks**: None enabled by default
  * Rationale: Minimal default; users enable hooks as needed
* **Output format**: Plain text (human-readable)
  * Rationale: Works well for both interactive use and shell piping
* **Verbosity**: Normal (warnings and errors only)
  * Rationale: Quiet by default; verbose mode available when needed

These defaults ensure the system works out-of-the-box with minimal configuration while allowing full customization through configuration files, environment variables, or CLI options.

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
2. Check environment variables
3. Check task-level configuration (if applicable)
4. Check data directory `config.toml`
5. Check global `config.toml`
6. Use built-in defaults

### Environment Variables

Environment variables provide a way to override configuration settings without modifying configuration files. This is useful for:

* **Temporary overrides**: Testing different configurations
* **Script automation**: Setting configuration in shell scripts
* **CI/CD pipelines**: Configuring behavior in automated environments
* **System-wide defaults**: Setting defaults at the system level

**Naming convention**: Environment variables use the prefix `MYTASK_` followed by the configuration key in uppercase with underscores. For example:
* `MYTASK_DATA_DIR` - Override default data directory
* `MYTASK_EDITOR` - Override default editor
* `MYTASK_DATE_FORMAT` - Override date format preference

**Scope**: Environment variables override configuration files but are overridden by CLI options. This allows CLI options to always take precedence for maximum flexibility.

**Examples**:
```bash
# Set data directory via environment variable
export MYTASK_DATA_DIR=/path/to/tasks
mytask list

# Override with CLI option (takes precedence)
mytask list --data-dir /other/path
```

### Future Extensibility

The configuration system is designed to be extensible. Future additions could include:

* **Current directory configuration**: `.mytask/config.toml` in current working directory
* **Parent directory search**: Walk up directory tree looking for config files
* **Per-command configuration**: Command-specific config files

### Design Rationale

* **XDG compliance**: Follows standard Unix conventions for configuration location
* **Multi-tiered**: Allows both global defaults and per-repository customization
* **CLI override**: Ensures command-line always wins for flexibility
* **Version-controlled**: Data directory config can be committed to git, syncing settings across machines
* **Extensible**: Architecture supports future configuration sources without breaking existing setups

---

## Perl Module Management: local::lib

The project uses **`local::lib`** for managing Perl module dependencies. This approach keeps project dependencies isolated from the system Perl installation, avoiding conflicts and permission issues.

### Rationale

* **Isolation**: Project dependencies are installed in a local directory, separate from system Perl modules
* **No root access required**: Modules can be installed without administrator privileges
* **Reproducibility**: Each developer can have identical dependency environments
* **Portability**: Works across different systems without modifying system-wide Perl installations
* **Git-friendly**: The local library path can be configured per-project or per-user

### Usage

Developers set up `local::lib` in their development environment, and the project's Perl scripts will automatically use the local module library. This ensures consistent dependency versions across development environments.

See [DEVELOPMENT.md](DEVELOPMENT.md) for setup instructions.

---

## Directory Structure and Naming Conventions

The project follows conventions to keep the root directory clean and organized.

### Dot-Named Files and Directories

Files and directories that are not part of the core project structure should be **dot-named** (prefixed with a dot) to keep the root directory clean:

* **`.local-lib/`** - local::lib directory for Perl module dependencies (project-specific)
* **`.git/`** - Git repository metadata (standard)
* **`.gitignore`** - Git ignore patterns (standard)
* Other development artifacts should follow this pattern

### Directory Purposes

* **`bin/`** - Contains **tool scripts** (the actual application executables). These are the user-facing commands that will be installed or executed.
* **`scripts/`** - Contains **development scripts** (e.g., `local-env.sh` for setting up local development environment). These are helper scripts for developers, not part of the application itself.

### Rationale

* **Clean root directory**: Dot-naming keeps non-core files hidden and organized
* **Clear separation**: Distinguishing `bin/` (application) from `scripts/` (development) clarifies purpose
* **Standard conventions**: Follows Unix conventions for hidden files and common directory naming

