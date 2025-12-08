# TODO

## Documentation Organization

- [ ] Create `docs/` directory
- [ ] Break up `statement.md` into proto-documentation files:
  - [ ] `docs/overview.md` - High-level problem statement and goals
  - [ ] `docs/design-decisions.md` - Storage model, file format, and other decisions
  - [ ] `docs/data-model.md` - Task structure, fields, and relationships
  - [ ] `docs/architecture.md` - System architecture and component design
  - [ ] `docs/cli-design.md` - Command-line interface specification
  - [ ] `docs/implementation-notes.md` - Implementation language choice and rationale

## Design Questions & Clarifications

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

---

### Conflict Resolution Strategy

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

### Migration Path

**Question**: Do we need a migration tool from Taskwarrior?

**Options**:
- Yes, provide import/export tools
- No, start fresh
- Maybe later (not in MVP)

**Considerations**:
- Migration tools help adoption
- Can be added later if not in MVP
- Export format should be well-documented

---

### Locking Strategy

**Question**: How should we handle concurrent edits on the same machine?

**Options**:
- File locking (e.g., `File::NFSLock`)
- Rely on git (let git handle conflicts)
- Advisory locking (warn but don't prevent)
- No locking (rely on git merge)

**Considerations**:
- File locking prevents concurrent edits but adds complexity
- Git handles conflicts well but may require manual resolution
- Advisory locking provides safety without blocking

**Recommendation**: Use advisory file locking for same-machine edits, rely on git for multi-machine sync.

---

### Performance Considerations

**Question**: How should we handle performance at scale (10k+ tasks)?

**Considerations**:
- Flat directory with 10k files may be slow to list
- Need efficient filtering and searching
- May need indexing or caching strategies
- Should remain simple for human-scale use cases

**Open Questions**:
- Do we need an index file for fast lookups?
- Should we support pagination for large result sets?
- What's the performance target (e.g., list all tasks in <1s)?

---

### Testing Strategy

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

---

### Initial Scope / MVP Definition

**Question**: What features should be in the MVP vs. nice-to-haves?

**MVP Candidates**:
- Create, read, update, delete tasks
- List tasks with filtering
- Basic status management (pending, done, deleted)
- Tags and projects
- Git integration (detect repo, work with git)
- Basic conflict detection

**Nice-to-Haves**:
- Task dependencies/graph
- Advanced filtering and querying
- Import/export tools
- TUI interface
- Recurring tasks
- Task templates

**Question**: What's the minimum viable feature set for v1.0?

---

### Example Task File Format

**Question**: What should a concrete task file look like?

**Considerations**:
- Should show TOML structure
- Should demonstrate all fields
- Should be readable and editable by humans
- Should handle edge cases (long descriptions, special characters, etc.)

**Action**: Create example task files to validate the format.

---

### Directory Structure

**Question**: What should a task repository directory structure look like?

**Considerations**:
- Where do tasks live? (`tasks/` directory?)
- Where does config live? (`.mytask/` or root?)
- Where do indices/cache live? (if needed)
- What files should be gitignored?

**Action**: Define the repository structure specification.

