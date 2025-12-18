# TODO

This file contains open questions and tasks organized by milestone. Items that don't fit into specific milestones are in the Future section.

## General Principles

### Forgiveness Principle

**Core Philosophy**: The application must be **as forgiving as possible** while
maintaining data integrity and usability. This principle applies across all
aspects of the system:

- **File Format**: Handle invalid filenames, incomplete TOML, and malformed
  files gracefully
- **CLI Interface**: Parse user input leniently, accepting various formats
  while maintaining clear structure
- **Data Validation**: Automatically fix issues where possible, preserve user
  intent when recovering from errors
- **Manual Edits**: Support users who manually edit task files, even if they
  break conventions

See [docs/design-decisions.md](docs/design-decisions.md) for detailed
documentation of the forgiveness principle and [Future: Invalid Filename and
Format Recovery](#invalid-filename-and-format-recovery) for implementation
plans.

## Milestone 1: Task File Format (Basic) ✅ APPROVED

**Status**: Approved and completed. All requirements met per [docs/milestones.md](docs/milestones.md).

### ID Strategy ✅ RESOLVED

**Decision**: UUIDs (v4) for primary IDs, with optional short aliases stored as metadata for quick reference.

**Implementation**: 
- Task files named `<uuid>.toml` (e.g., `550e8400-e29b-41d4-a716-446655440000.toml`)
- Optional `alias` field for human-friendly short identifiers
- Documented in [docs/data-model.md](docs/data-model.md) and [docs/task-file-format.md](docs/task-file-format.md)

### Example Task File Format ✅ RESOLVED

**Implementation**: Example task files created in `docs/examples/`:
- `simple-task.toml` - Basic task with minimal fields
- `task-with-notes.toml` - Task with notes field (multiline string)
- `task-with-due-date.toml` - Task with due date
- `completed-task.toml` - Completed task
- `deleted-task.toml` - Deleted task
- `task-with-alias.toml` - Task with alias field

All examples are valid, parseable TOML. Complete format specification documented in [docs/task-file-format.md](docs/task-file-format.md).

### Directory Structure ✅ RESOLVED

**Decision**: 
- Tasks live in `tasks/` directory
- Config lives in `config.toml` in repository root
- Repository structure documented in [docs/architecture.md](docs/architecture.md)

**Implementation**: Repository structure specification complete with task file naming conventions and git ignore recommendations.

---

## Milestone 2: Basic Commands

### CLI Command Name

**Question**: What should the CLI command be called?

**Options**:
- `mytask` (matches project name)
- `task` (generic, might conflict with Taskwarrior)
- `tt` or `t` (short alias)
- Something else?

**Considerations**:
- Should be memorable and not conflict with existing tools
- Short commands are faster to type
- Descriptive names are clearer

---

## Milestone 5: Tags

### Tag Design Decisions

**Questions**:
- Determine if tag == label
- Determine if tag must match existing list (which is definable by user) or is free form
- Are tags case-sensitive or case-insensitive?

**Considerations**:
- Free-form tags are more flexible
- Predefined tag lists provide consistency and validation
- Case sensitivity affects filtering and matching

---

## Milestone 6: Recurring Tasks

### Recurring Tasks Implementation

**Questions**:
- **Auto-completion timing**: How should auto-completion be triggered?
  * Cron job? Background daemon? On-demand check?
  * Should it run automatically on every command, or require explicit invocation?
- **Multi-host coordination**: How to prevent duplicate task generation when multiple machines run auto-completion?
  * Use timestamps and sequence numbers?
  * Lock files or other coordination mechanisms?
- **Recurrence template storage**: Where should recurrence templates be stored?
  * In the task file itself?
  * Separate template files?
  * Configuration file?
- **Auto-completion action defaults**: What should the default action be for incomplete recurring tasks?
  * Complete, skip, or delete?
  * Should this be configurable per task or globally?
- **Task conversion**: Do we want to support conversion of a task to recurring and vice-versa?

---

## Milestone 7: Task Dependencies

### Task Graph / Dependencies

**Question**: How deeply should we support parent/child or dependency graphs?

**Options**:
- Simple parent/child (one parent per task)
- Multiple parents allowed
- Full DAG (directed acyclic graph) support
- Dependency chains (task A depends on task B)

**Considerations**:
- Simpler models are easier to implement and reason about
- More complex models provide more flexibility
- Need to ensure relationships survive sync/merge

**Question**: How do we model these relationships in TOML in a way that survives sync/merge?

**Recommendation**: Start with simple parent/child relationships, allow multiple parents, represent as arrays of task IDs in TOML.

---

## Future Milestones

### Git Integration

**Locking Strategy**

**Question**: How should we handle concurrent edits on the same machine?

**Options**:
- File locking (e.g., `File::NFSLock`)
- Rely on git (let git handle conflicts)
- Advisory locking (warn but don't prevent)
- No locking (rely on git merge)

**Considerations**:
- File locking prevents concurrent edits but adds complexity
- File locking is only relevant to processes that honor NFSLock
- Git handles conflicts well but may require manual resolution
- Advisory locking provides safety without blocking

**Recommendation**: Use advisory file locking for same-machine edits, rely on git for multi-machine sync.

**Conflict Resolution Strategy**

**Question**: How should we handle conflicts when two machines edit the same task file?

**Options**:
- Field-wise merges (merge individual fields intelligently)
- Last-writer-wins (simple but may lose data)
- Manual resolution via git merge tools (always)

**Considerations**:
- Field-wise merging is complex but preserves more data
- Last-writer-wins is simple but can lose edits
- Git merge markers allow manual resolution but require user intervention

**Recommendation**: Hybrid approach:
- Timestamps: Keep both, track modification history
- Status: Last-writer-wins (with conflict detection)
- Description/notes: Git merge markers, manual resolution
- Tags: Union merge (both sets combined)
- Dependencies: Union merge

**Question**: Is it acceptable to occasionally drop to manual conflict resolution via `git mergetool`?

---

## General / Cross-Milestone

Each milestone should consider the following cross-cutting concerns:

### Testing

**Question**: How should we structure the test suite?

**Considerations**:
- Test data model parsing/validation
- Test conflict detection and resolution
- Test multi-host scenarios (simulated via git branches)
- Test edge cases (malformed files, missing dependencies, etc.)
- Test CLI commands and output formats

**Open Questions**:
- What testing framework to use? (Perl: Test::More, Test2, etc.)
- How to test git integration? (temporary repos, mocks?)
- What's the target test coverage?

**Milestone Requirements**:
- Each milestone must include comprehensive tests for its functionality
- Tests should cover happy paths, error cases, and edge cases
- Integration tests should verify milestone functionality works with previous milestones

### Program Help (CLI Help Command)

**Considerations**:
- Each new command or option should have `--help` documentation
- Help text should be clear, concise, and include examples where helpful
- Help should be accessible via `task <command> --help` or `task help <command>`
- Consider adding a `task help` command for general help and command listing

**Milestone Requirements**:
- New CLI commands must include help text
- Help text should document all options and usage patterns
- Examples in help text should be practical and relevant

### Documentation

**Considerations**:
- Each milestone must have complete documentation before completion
- Documentation should cover usage, configuration, examples, and edge cases
- Update relevant documentation files (data-model.md, cli-design.md, etc.)
- Include practical examples and use cases

**Milestone Requirements**:
- Documentation must be complete and accurate
- Examples should demonstrate real-world usage
- Edge cases and limitations should be documented
- Documentation should be reviewed and updated as implementation progresses

### Hooks Integration

**Considerations**:
- New functionality should consider hook integration points
- Pre-hooks can validate or modify data before operations
- Post-hooks can trigger notifications, logging, or side effects
- Hook context should include relevant information for the operation
- Consider which hook events make sense for new functionality

**Milestone Requirements**:
- Identify appropriate hook events for new functionality
- Ensure hook context includes necessary information
- Document hook integration points
- Provide example hooks demonstrating integration

### Configuration Needs

**Considerations**:
- New features may require configuration options
- Configuration should follow the multi-tiered system (CLI > env vars > data dir > global > defaults)
- Consider user preferences and defaults
- Configuration should be documented and validated

**Milestone Requirements**:
- Identify configuration needs for new functionality
- Define reasonable defaults
- Document configuration options
- Ensure configuration follows established hierarchy

### Additional Cross-Milestone Considerations

**Error Handling**:
- Consistent error messages and exit codes
- Graceful degradation when possible
- Clear error reporting for users
- Error logging for debugging

**Logging**:
- Appropriate log levels (debug, info, warn, error)
- Logging for operations, errors, and important state changes
- Configurable verbosity
- Log format consistency

**Output Formats**:
- Consider multiple output formats (plain text, JSON, TOML) where appropriate
- Output should be suitable for both human reading and shell piping
- Consistent formatting across commands

**Multi-Host / Sync Considerations**:
- Ensure new features work correctly across multiple machines
- Consider merge conflicts and resolution
- Idempotent operations where possible
- Timestamp and version tracking

**Backward Compatibility**:
- Consider impact on existing task files
- Maintain compatibility with previous versions where possible
- Document breaking changes clearly
- Provide migration paths if needed

**Performance Implications**:
- Consider performance impact of new features, but don't over-optimize
- Optimize for human-scale use cases (hundreds to tens of thousands of tasks)
- Focus on user experience over raw performance metrics
- Simple implementations preferred over complex optimizations
- Profile only if users report performance issues

**Validation**:
- Validate input data and configuration
- Provide clear validation error messages
- Validate data integrity and relationships
- Handle malformed data gracefully

**User Experience**:
- Intuitive command syntax and options
- Clear feedback for user actions
- Helpful error messages
- Consistent behavior across commands

### Performance Considerations

**Philosophy**: This tool is designed for a single user or smallish team. While we always want to reduce cycles and optimize where reasonable, performance is **not a priority** as long as the user has a decent experience.

**Considerations**:
- Optimize for human-scale use cases (hundreds to tens of thousands of tasks)
- Focus on user experience over raw performance metrics
- Simple, straightforward implementations are preferred over complex optimizations
- Performance optimizations should not compromise code clarity or maintainability
- If operations feel responsive to users, that's sufficient

**Milestone Requirements**:
- Ensure operations complete in reasonable time for typical use cases
- Avoid obvious performance bottlenecks (e.g., reading entire directory unnecessarily)
- Profile only if users report performance issues
- Prefer simplicity over premature optimization

**Open Questions** (only address if performance becomes an issue):
- Do we need an index file for fast lookups?
- Should we support pagination for large result sets?
- What's the performance target? (Answer: "Good enough" - if users don't complain, it's fine)

---

## Future

Future enhancements and features that are not part of the core milestones:

* **Docker Image**: A docker image
* **Curses-based TUI**: Terminal user interface using curses/ncurses for interactive task management
* **Web-based UI**: Web interface for accessing and managing tasks through a browser
* **Android app**: Native Android application for mobile task management

* Consider using PAR::Packer as a release tool

### Timestamp Format and Reliability

**Problem**: ISO 8601 timestamps can be confusing and unreliable, especially
when tasks are edited manually or created outside the tool. Timezone handling,
format variations, and manual edits can lead to inconsistent or incorrect
timestamps.

**Proposal**: Consider using Unix epoch timestamps (seconds since 1970-01-01)
as a more reliable format:
- Unambiguous (no timezone confusion)
- Easy to compare and sort
- Simple numeric format
- Widely supported

**Challenges**:
- Need to handle edits/additions made outside the tool (manual file edits)
- Users may manually edit timestamps incorrectly
- Need to detect and fix invalid or inconsistent timestamps
- Migration from ISO 8601 format if we change
- Human readability trade-off (epochs are less readable than ISO 8601)

**Considerations**:
- Should we use epochs for internal storage but display as ISO 8601?
- How to validate and fix timestamps when files are edited manually?
- Should we support both formats during a transition period?
- How to handle timezone information if we switch to epochs?
- Should `created` timestamp be immutable (never change, even on manual edit)?
- How to detect and prevent timestamp manipulation that breaks causality
  (e.g., `modified` before `created`)?

**Status**: Design consideration for future evaluation. Current format uses ISO
8601 timestamps as specified in [docs/task-file-format.md](docs/task-file-format.md).

### Notes Entry Sorting and Timestamp Handling

**Requirement**: Notes entries in the `[[notes]]` array must be maintained in
chronological order by timestamp. The application should:

- Sort notes entries by timestamp when reading task files
- Handle cases where entries are manually added out of order
- Ensure proper chronological ordering after manual edits
- Preserve user intent when assigning timestamps to entries without them

**Implementation Considerations**:
- When should sorting occur? (on read, on write, or both?)
- How to handle entries with identical timestamps?
- Should sorting be automatic or require explicit command?
- Performance implications for large notes arrays

**Status**: Future enhancement. See [Design Decisions](docs/design-decisions.md)
for forgiving timestamp handling details.

### Invalid Filename and Format Recovery

**Problem**: The application should be forgiving and handle cases where users
create task files with invalid filenames or incomplete/invalid formats. For
example:
- Invalid filename: `quickie-manual-file.toml` (not a UUID)
- Incomplete format: `echo 'do this thing' > /path/to/task/quickie-manual-file`
- Partial format: `echo 'description = do this thing' > /path/to/task/quickie-manual-file`

**Requirements**:
- Application should detect invalid filenames (non-UUID format)
- Application should detect incomplete or invalid TOML formats
- Provide automatic recovery/fixing where possible
- Provide a command (e.g., `mytask fix` or `mytask validate --fix`) to scan
  and fix invalid files
- Option to automatically fix files on detection (with confirmation or flag)
- Generate proper UUIDs for files with invalid names
- Complete partial TOML structures with required fields
- Preserve as much content as possible from invalid files

**Considerations**:
- Should fixing be automatic or require explicit command?
- How to handle files that are too broken to recover?
- Should we log/report what was fixed?
- Should we create backups before fixing?
- How to handle conflicts when renaming files to UUID format?

### Show Date Field

**Problem**: Tasks may have a due date far in the future, but users don't want
to see them in their task list until closer to the due date. This helps reduce
clutter and focus on tasks that are relevant now.

**Proposal**: Add a `show` or `show_date` field that controls when a task
appears in listings. Tasks with a `show` date in the future should be hidden
from normal task listings until that date is reached.

**Use Cases**:
- Task due in 6 months, but don't want to see it until 2 weeks before
- Long-term projects that shouldn't clutter the immediate task list
- Tasks that become relevant only at a specific time

**Behavior**:
- Tasks with `show` date in the future are excluded from `mytask list` by
  default
- Tasks with `show` date in the past or today are included normally
- Option to show all tasks including future ones (e.g., `mytask list --all`)
- If `show` date is not set, task is always visible (backward compatible)
- `show` date can be before, equal to, or after `due` date

**Format Preference**: Use simple relative text format (preference, to be
finalized during implementation):
- `-2 weeks` or `2 weeks` = 2 weeks before the due date
- `+2 weeks` = 2 weeks after the due date (could be used to highlight past due
  tasks)
- Relative to the `due` date field
- Human-readable and easy to edit manually

**Considerations**:
- Field name: `show`, `show_date`, or `visible_from`?
- Should `show` date default to `created` date if not specified?
- How to handle tasks where `show` date is after `due` date?
- Should `mytask list` have a flag to include/exclude future tasks?
- Parsing and validation of relative time formats
- Interaction with filtering and querying commands
- How to handle tasks without a `due` date (absolute date fallback?)

**Status**: Future enhancement. Format preference noted above, but exact
implementation details to be determined when this feature is implemented.

### Reminder Field

**Problem**: Users may want to be reminded about tasks at specific times
before or on the due date. This is separate from the due date itself and
allows for multiple reminders or reminder scheduling.

**Proposal**: Add a `reminder` field (or `reminders` array) to support task
reminders. Supports multiple reminders via array structure.

**Use Cases**:
- Remind me 1 week before a task is due
- Remind me on the day a task is due
- Multiple reminders at different intervals
- Reminders independent of due date

**Format Preference**: Use simple relative text format (preference, to be
finalized during implementation):
- `-2 weeks` or `2 weeks` = 2 weeks before the due date
- `+2 weeks` = 2 weeks after the due date (could be used to highlight past due
  tasks)
- Relative to the `due` date field
- Human-readable and easy to edit manually
- Support arrays for multiple reminders: `reminders = ["-1 week", "-1 day", "0"]`

**Considerations**:
- Field structure: Single `reminder` field or `reminders` array? (Preference:
  array to support multiple reminders)
- Should reminders be relative to `due` date, `show` date, or absolute?
- How are reminders delivered? (CLI notification, hook integration, etc.)
- Should reminders be one-time or recurring?
- Interaction with recurring tasks
- Should reminders be stored in task file or separate reminder system?
- Parsing and validation of relative time formats
- Timezone handling for reminder times
- How to handle tasks without a `due` date (absolute date fallback?)

**Status**: Future enhancement. Format preference noted above, but exact
structure and implementation details to be determined when this feature is
implemented.