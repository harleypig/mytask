# TODO

This file contains open questions and tasks organized by milestone. Items that don't fit into specific milestones are in the Future section.

## Milestone 1: Task File Format (Basic)

### ID Strategy

**Question**: What ID strategy should we use?

**Options**:
- Human-friendly incremental IDs (e.g., `t1`, `t2`, `t3`)
- UUIDs (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- Content-based hash (e.g., SHA-256 of task content)

**Considerations**:
- UUIDs are collision-resistant across machines but less human-friendly
- Incremental IDs are human-friendly but require coordination to avoid collisions
- Content-based hashes ensure uniqueness but change when task content changes

**Recommendation**: UUIDs for primary IDs, with optional short aliases stored as metadata for quick reference.

### Example Task File Format

**Question**: What should a concrete task file look like?

**Considerations**:
- Should show TOML structure
- Should demonstrate all fields
- Should be readable and editable by humans
- Should handle edge cases (long descriptions, special characters, etc.)

**Action**: Create example task files to validate the format.

### Directory Structure

**Question**: What should a task repository directory structure look like?

**Considerations**:
- Where do tasks live? (`tasks/` directory?)
- Where does config live? (`.mytask/` or root?)
- Where do indices/cache live? (if needed)
- What files should be gitignored?

**Action**: Define the repository structure specification.

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