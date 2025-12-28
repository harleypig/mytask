# Development Milestones

This document defines the development milestones for the task manager project. Each milestone represents a single, cohesive concept that can be completed independently.

## Milestone Completion Criteria

Before a milestone can be considered complete, it must satisfy:

1. **Documentation**: Complete documentation covering the milestone's functionality
2. **Tests**: If the milestone includes code changes, comprehensive tests must be written
3. **Working Implementation**: The milestone's functionality must be implemented and working
4. **Versioning**: The milestone should create a new version:
   * **Milestones 1-5**: Can be minor version changes (`X.Y.0`) depending on the nature of changes
   * **Milestone 6 and later**: Milestone 6 (Recurring Tasks) introduces breaking changes and requires a major version (`X.0.0`). Later milestones will be evaluated individually.

Milestones should be completed in order, as later milestones may depend on earlier ones.

---

## Cross-Milestone Considerations

### Forgiveness Principle
- Be forgiving in file format parsing, CLI input, and data validation; preserve user intent and recover gracefully from malformed input or files.

### Testing
- Each milestone needs comprehensive tests (happy paths, edge cases, error cases, multi-host where relevant).
- Testing framework: Perl `Test::More` (existing suite); extend with supporting modules as needed. Git-integration strategy and coverage goals remain to be refined.

### Program Help
- Every CLI command/option must include `--help` with concise examples; consider a `task help` command for discovery.

### Documentation
- Complete docs before marking a milestone done; include usage, configuration, examples, edge cases, and limitations.

### Hooks Integration
- Identify hook events, required context, and examples for new functionality; pre-hooks may modify/abort, post-hooks may trigger side effects.

### Configuration Needs
- Follow the precedence hierarchy (CLI > env vars > data dir > global > defaults); document defaults and validation.

### Quality and UX
- Consistent error messages/logging, clear output formats, multi-host safety, backward-compatibility awareness, validation of inputs/config/data, and good user feedback.

### Performance Philosophy
- Optimize for human-scale use; prefer simplicity over premature optimization. Profile only when users report issues.

---

## Milestone 1: Task File Format (Basic) ✅ COMPLETE

**Goal**: Define and document the basic task file format (TOML structure) with examples for core scenarios.

**Status**: ✅ Complete - All requirements met, tests passing, documentation complete.

**Scope**:
* Define the TOML structure for task files
* Document core fields and their purposes:
  * ID (unique identifier)
  * Description
  * Status (pending, done, deleted, archived)
  * Created/modified timestamps
  * Due date / scheduled date
* Create example task files for basic scenarios:
  * Simple task (basic fields only)
  * Task with timestamped journal entries (notes)
  * Task with due date
  * Completed task
  * Deleted task
* Validate that examples are parseable TOML
* Document field validation rules for core fields

**Deliverables**:
* Documentation in `docs/data-model.md` (or separate format specification)
* Example task files demonstrating basic scenarios
* TOML schema or validation rules for core fields

**Tests**:
* Parse all example task files successfully
* Validate field types and constraints for core fields
* Test edge cases (empty fields, special characters, etc.)

**Dependencies**: None (foundational)

---

## Milestone 2: Basic Commands

**Goal**: Implement the core CLI commands for basic task operations.

**Scope**:
* `mytask add` - Create a new task
* `mytask list` - List tasks with optional filtering
* `mytask show` - Display details of a specific task
* `mytask done` - Mark a task as completed
* `mytask edit` - Edit an existing task
* `mytask delete` - Delete a task

**Requirements**:
* Commands work with the task file format from Milestone 1
* Commands handle basic error cases (missing files, invalid IDs, etc.)
* Output is suitable for both human reading and shell piping
* Commands support `--data-dir` option for specifying repository location

**Deliverables**:
* Working CLI implementation
* Documentation in `docs/cli-design.md`
* Command help text (`--help` for each command)

**Tests**:
* Unit tests for each command
* Integration tests for command workflows
* Test error handling (invalid input, missing files, etc.)
* Test `--data-dir` option

**Dependencies**: Milestone 1 (Task File Format)

**Open Questions**:
* CLI command name: `mytask`, `task`, `tt`/`t`, or another option? Balance memorability, conflicts, and clarity.

---

## Milestone 3: Configuration Handling

**Goal**: Implement the multi-tiered configuration system (global, data directory, environment variables, CLI options).

**Scope**:
* Built-in default configuration values (reasonable defaults when no config is provided)
* Global configuration file (`$XDG_CONFIG_HOME/mytask/config.toml`)
* Data directory configuration file (`config.toml` in repository root)
* Environment variable support (`MYTASK_*` prefix)
* Configuration hierarchy resolution (CLI > environment variables > data directory > global > defaults)
* Configuration file parsing and validation
* Support for `--data-dir` and `--config` CLI options
* `mytask config dump` command for viewing default or resolved configuration

**Requirements**:
* Define reasonable built-in defaults for all configuration values
* Follow XDG Base Directory Specification for global config
* Configuration files are valid TOML
* Environment variables use `MYTASK_` prefix with uppercase naming
* Configuration resolution follows documented precedence order
* CLI options override environment variables and configuration files
* Environment variables override configuration files
* Graceful handling of missing configuration files
* `mytask config dump` outputs TOML format matching configuration file structure

**Deliverables**:
* Built-in default configuration values (documented)
* Configuration management implementation
* Environment variable parsing and resolution
* `mytask config dump` command implementation
* Documentation in `docs/design-decisions.md` (Configuration System section)
* Example configuration files
* Configuration validation

**Tests**:
* Test built-in defaults are used when no configuration is provided
* Test configuration file parsing
* Test environment variable parsing and resolution
* Test configuration hierarchy resolution (verify precedence order)
* Test CLI option overrides (including environment variables)
* Test `mytask config dump --default` shows built-in defaults
* Test `mytask config dump` shows resolved configuration
* Test XDG directory handling
* Test missing configuration file handling
* Test environment variable naming convention

**Dependencies**: Milestone 1 (Task File Format)

---

## Milestone 4: Hooks System

**Goal**: Implement the hooks system for task operation automation, allowing power users to override built-in functionality and test new components.

**Scope**:
* Hook discovery and loading from configuration files (global and data directory)
* Hook execution at defined events where it makes sense, `pre-` and `post-` event (pre-create, post-create, etc.)
* Hook context provision (task data, operation type, environment)
* Pre-hook data modification support
* Post-hook side effects support
* Hook error handling and abort capability
* Hook configuration parsing and validation
* Support for hooks in both global and data directory configuration files

**Requirements**:
* Hooks are defined as top-level TOML tables in configuration files
* Hooks receive task data via stdin (TOML or JSON format)
* Pre-hooks can modify task data and abort operations
* Post-hooks can perform side effects (notifications, logging, etc.)
* Hook failures are logged with configurable abort behavior
* Data directory hooks take precedence over global hooks
* Hooks enable power users to:
  * Override built-in task operations
  * Test new functionality before incorporating into base code
  * Customize behavior per repository
  * Integrate with external systems and tools

**Deliverables**:
* Hooks system implementation
* Hook execution engine
* Hook configuration parsing and validation
* Documentation in `docs/design-decisions.md` (Hooks System section)
* Example hook scripts demonstrating common use cases
* Hook testing framework

**Tests**:
* Test hook discovery and loading from configuration files
* Test hook execution at each event type
* Test pre-hook data modification
* Test pre-hook abort capability
* Test post-hook side effects
* Test hook error handling
* Test hook precedence (data directory over global)
* Test hook context provision
* Test hook failures and abort behavior

**Dependencies**: Milestone 2 (Basic Commands), Milestone 3 (Configuration Handling)

**Versioning**: Can be minor version change (`X.Y.0`) - Adds new functionality without breaking existing features.

---

## Milestone 5: Tags

**Goal**: Add tag support to tasks for categorization and filtering.

**Scope**:
* Extend task file format to include tags field (array of strings)
* Update `mytask add` command to accept tags
* Update `mytask edit` command to modify tags
* Update `mytask list` command to filter by tags
* Document tag format and usage
* Determine if tag == label
* Determine if tag must match existing list (which is definable by user) or is free form

**Requirements**:
* Tags are simple strings (no special characters or validation beyond basic constraints)
* Multiple tags per task
* Tags are case-sensitive or case-insensitive (to be decided)
* Filtering by tags in list command

**Deliverables**:
* Updated task file format documentation
* Example task files with tags
* Updated CLI commands supporting tags
* Documentation in `docs/data-model.md`

**Tests**:
* Test tag parsing and storage
* Test tag filtering in list command
* Test tag editing
* Test edge cases (empty tags, special characters, etc.)

**Dependencies**: Milestone 1 (Task File Format), Milestone 2 (Basic Commands)

**Open Questions**:
* Are tags equivalent to labels?
* Should tags be constrained to a predefined list or be free-form?
* Should tags be case-sensitive or case-insensitive?

---

## Milestone 6: Recurring Tasks

**Goal**: Implement task generation and auto-completion for repeating tasks.

**Scope**:
* Extend task file format to include recurrence fields:
  * Recurrence type (fixed, relative, sequential)
  * Recurrence interval
  * Auto-completion deadline and action
  * Parent recurrence ID
  * Sequence number
* Implement `mytask recur` command for creating recurring tasks
* Implement task generation logic
* Implement auto-completion logic
* Support all three recurrence patterns (fixed, relative, sequential)

**Requirements**:
* Tasks can be marked as recurring with configuration
* System generates next task instance based on pattern
* Auto-completion handles incomplete recurring tasks
* Multi-host safe (idempotent operations)
* Determine if we want to support conversion of a task to recurring and vice-versa

**Deliverables**:
* Updated task file format documentation
* Example recurring task files for each pattern
* Recurrence engine implementation
* Updated CLI commands
* Documentation in `docs/data-model.md` (Recurring Tasks section)

**Tests**:
* Test recurrence pattern parsing
* Test task generation for each pattern
* Test auto-completion logic
* Test multi-host scenarios
* Test edge cases (skipped tasks, early completion, etc.)

**Dependencies**: Milestone 1 (Task File Format), Milestone 2 (Basic Commands), Milestone 3 (Configuration Handling), Milestone 4 (Hooks System)

**Versioning**: **Major version change** (`X.0.0`) - This milestone introduces breaking changes to the task file format (recurrence fields) and CLI interface (new commands).

**Open Questions**:
* Auto-completion timing: cron/background/on-demand? Run on every command or explicit only?
* Multi-host coordination: timestamps/sequence numbers/locks?
* Recurrence template storage: in task file vs separate template vs config?
* Default action for incomplete recurring tasks: complete/skip/delete; per-task vs global setting?
* Support converting tasks to/from recurring?

---

## Milestone 7: Task Dependencies

**Goal**: Add parent/child and dependency relationships between tasks.

**Scope**:
* Extend task file format to include dependency fields:
  * Parents (array of task IDs)
  * Dependencies (array of task IDs)
* Update `mytask add` command to accept parent/dependency references
* Update `mytask edit` command to modify relationships
* Update `mytask list` command to show relationships
* Implement dependency validation (prevent circular dependencies)
* Document dependency format and usage

**Requirements**:
* Support multiple parents per task
* Support multiple dependencies per task
* Prevent circular dependency chains
* Relationships survive sync/merge

**Deliverables**:
* Updated task file format documentation
* Example task files with dependencies
* Updated CLI commands supporting dependencies
* Dependency validation logic
* Documentation in `docs/data-model.md` (Task Graph section)

**Tests**:
* Test dependency parsing and storage
* Test circular dependency detection
* Test dependency filtering/display
* Test sync/merge scenarios with dependencies
* Test edge cases (missing dependencies, deleted tasks, etc.)

**Dependencies**: Milestone 1 (Task File Format), Milestone 2 (Basic Commands)

**Open Questions**:
* Depth of support: simple parent/child, multiple parents, full DAG, dependency chains?
* Representation in TOML that survives sync/merge? (arrays of task IDs recommended to start)

---

## Future Milestones

The following milestones are planned but not yet fully defined. They should follow the same pattern: single concept, documentation, tests, working implementation.

### Projects

**Goal**: Add project/context support to tasks for organization.

**Scope**:
* Extend task file format to include project field (single string)
* Update `mytask add` command to accept project
* Update `mytask edit` command to modify project
* Update `mytask list` command to filter by project
* Document project format and usage

**Requirements**:
* Single project per task (not multiple)
* Project is a simple string identifier
* Filtering by project in list command
* Project can be empty/null

**Deliverables**:
* Updated task file format documentation
* Example task files with projects
* Updated CLI commands supporting projects
* Documentation in `docs/data-model.md`

**Tests**:
* Test project parsing and storage
* Test project filtering in list command
* Test project editing
* Test edge cases (empty project, special characters, etc.)

**Dependencies**: Milestone 1 (Task File Format), Milestone 2 (Basic Commands)

### Git Integration

**Goal**: Detect and interact with git repositories for sync.

**Design Considerations**:
* Locking strategies: advisory locking, rely on git conflicts, or file locking (e.g., `File::NFSLock`).
* Conflict resolution: field-wise merge vs last-writer-wins vs manual resolution via git tools.
* Recommended approach: advisory locking for same-machine edits; rely on git for multi-machine sync; hybrid conflict handling (timestamps tracked, status last-writer-wins with detection, descriptions/notes via merge markers, tags/dependencies union-merged).

**Dependencies**: Milestone 2 (Basic Commands), Milestone 3 (Configuration Handling)

### Export/Import

**Goal**: Implement export and import functionality for various formats.

**Dependencies**: Milestone 2 (Basic Commands)

### Conflict Handling

**Goal**: Detect and assist with merge conflicts in task files.

**Dependencies**: Milestone 2 (Basic Commands), Git Integration milestone

### Timestamp Format and Reliability

**Goal**: Evaluate moving from ISO 8601 to Unix epochs (or hybrid) for reliability, while preserving readability and validating manual edits.

### Notes Entry Sorting and Timestamp Handling

**Goal**: Keep `[[notes]]` entries chronologically ordered; handle identical timestamps, out-of-order edits, and large arrays efficiently.

### Invalid Filename and Format Recovery

**Goal**: Detect and repair non-UUID filenames and incomplete/invalid TOML; optionally auto-fix with backups, generate UUIDs, and preserve content.

### Show/Reminder Fields

**Goal**: Add deferred-visibility (`show`/`show_date`) and reminder fields (single or array) using human-friendly relative formats; define parsing, validation, and listing defaults.

### Additional UIs and Packaging

**Goal**: Explore Docker image, curses-based TUI, web UI, Android app, and PAR::Packer packaging.

---

## Milestone Summary

Here is the complete list of milestones in priority order:

1. **Milestone 1**: Task File Format (Basic) - Simple tasks, notes, status, due dates
2. **Milestone 2**: Basic Commands - add, list, show, done, edit, delete
3. **Milestone 3**: Configuration Handling - Multi-tiered config system
4. **Milestone 4**: Hooks System - Task operation automation and power-user overrides
5. **Milestone 5**: Tags - Categorization with tags
6. **Milestone 6**: Recurring Tasks - Task generation and auto-completion
7. **Milestone 7**: Task Dependencies - Parent/child and dependency relationships

**Future Milestones** (not yet fully defined):

* **Git Integration** - Git repository detection and sync
* **Export/Import** - Format conversion functionality
* **Conflict Handling** - Merge conflict detection and assistance
* **Projects** - Project/context organization (moved to future milestones, was Milestone 5)
