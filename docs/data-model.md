# Data Model

This document describes the task data structure, fields, and relationships.

**Note**: The authoritative source of truth for the task file format is the
JSON Schema definition in `docs/schema/task-file-schema.json`. This document
provides high-level descriptions, but the schema file defines the exact
validation rules and constraints.

## Task Semantics

Tasks are organized into three sections (see [Task File Format](task-file-format.md)
for complete format specification):

1. **`[task]`** - User-modifiable fields (description, status, dates, etc.)
2. **`[meta]`** - Program-managed fields (ID, timestamps, etc.)
3. **`[[notes]]`** - Timestamped journal entries (user notes and app logs)

### Basic Fields

Every task includes these core fields:

**In `[task]` section (user-modifiable):**
* **Description**: Short description of the task (required)
* **Status**: Current state (pending, done, deleted, archived) (required)
* **Due date / scheduled date**: Optional date fields for scheduling (ISO 8601)
* **Alias**: Optional short, human-friendly identifier
* **Tags**: Array of tags for categorization (future milestone)
* **Project/context**: Optional project or context grouping (future milestone)

**In `[meta]` section (program-managed):**
* **ID**: Unique identifier for the task (UUID v4) (required)
* **Created/modified timestamps**: When the task was created and last modified (ISO 8601) (required)

**In `[[notes]]` section (timestamped journal):**
* **Notes**: Array of timestamped journal entries containing user notes and
  app-generated logs. Each entry has a timestamp and entry text, with optional
  type field to distinguish user notes from app logs.

Tasks may also include recurrence-related fields:

* **Recurrence type**: Type of recurrence pattern (`fixed`, `relative`, `sequential`, or `none`)
* **Recurrence interval**: Interval for fixed/relative patterns (e.g., "daily", "weekly", "7 days")
* **Auto-completion deadline**: When to auto-handle incomplete recurring tasks
* **Auto-completion action**: Action to take (`complete`, `skip`, `delete`)
* **Parent recurrence ID**: Links task instances to their recurrence template
* **Sequence number**: Position in sequence (for sequential patterns)

### Optional Fields

Tasks may also include:

* **Parents / dependents**: Task graph relationships (see below) (future milestone)
* **Recurrence pattern**: Configuration for repeating tasks (see below) (future milestone)

**Notes**: The `[[notes]]` section provides timestamped journal entries for
documenting task progress, adding context, and maintaining an audit trail of
app-generated actions. Users can add entries manually, and the application
can add log entries to track status changes, field updates, and other
operations.

---

## Repeating Tasks

Tasks can be configured to repeat automatically, supporting three distinct patterns:

### 1. Daily/Weekly Recurring Tasks

**Pattern**: Tasks that must be done regularly (e.g., "take medication daily", "weekly team meeting").

**Behavior**:
* Task is generated on a fixed schedule (daily, weekly, etc.)
* If not completed by a deadline (e.g., midnight), the task is auto-handled (completed, skipped, or deleted based on configuration)
* Next task is generated immediately after auto-handling, maintaining the fixed schedule
* Example: Daily medication task auto-completes at midnight if not marked done, and the next day's task is created

**Use cases**: Medication reminders, regular meetings, routine maintenance

### 2. "Lawn Mower" Pattern

**Pattern**: Tasks that should be done regularly, but scheduling is relative to completion (e.g., "mow lawn weekly").

**Behavior**:
* Task is generated with an initial due date
* If completed early or late, the next task is scheduled relative to the **completion date**, not the original due date
* If skipped, the next task is scheduled relative to when it was skipped/auto-handled
* Example: Lawn mowing due Saturday, but done Monday → next task due 7 days from Monday, not Saturday

**Use cases**: Weekly chores, periodic maintenance, flexible recurring tasks

### 3. "Reading" Pattern (Sequential)

**Pattern**: Sequential tasks where each must be completed before the next is generated (e.g., "read chapter 1", "read chapter 2").

**Behavior**:
* Next task is only generated when the current task is marked as completed
* Missing a day doesn't create a backlog of tasks
* Tasks are generated sequentially, one at a time
* Example: Reading chapter 1 → only when marked done does chapter 2 task appear

**Use cases**: Sequential reading, step-by-step projects, progressive learning

### Recurrence Configuration

Tasks with recurrence patterns include:

* **Recurrence type**: `fixed` (daily/weekly), `relative` (lawn mower), or `sequential` (reading)
* **Interval**: For fixed and relative types, the interval (e.g., "daily", "weekly", "7 days")
* **Auto-completion deadline**: For recurring tasks with a due date, when to auto-handle incomplete tasks (e.g., "midnight", "end of day")
* **Auto-completion action**: What to do with incomplete tasks (`complete`, `skip`, `delete`)
* **Template**: Base task data to use when generating the next instance
* **Sequence position**: For sequential tasks, current position in the sequence

### Task Generation and Auto-Completion

**Generation triggers**:
* Fixed recurring: On schedule (e.g., daily at midnight)
* Relative recurring: When current task is completed or auto-handled
* Sequential: Only when current task is marked as completed

**Auto-completion process** (for fixed recurring tasks):
1. System checks for tasks past their auto-completion deadline
2. Applies configured auto-completion action (complete/skip/delete)
3. Generates next task instance according to the recurrence pattern
4. Logs the auto-completion event for audit purposes

**Multi-host considerations**:
* Auto-completion should be idempotent (safe to run on multiple machines)
* Generation timestamps and sequence numbers help prevent duplicate task creation
* Conflict resolution handles cases where multiple machines generate tasks simultaneously

---

## Task Graph / Dependencies

Tasks can have relationships with other tasks:

* **Parent/child relationships**: Tasks can have parent tasks or child tasks
* **Dependencies**: Tasks can depend on other tasks being completed

The exact depth and complexity of these relationships is still under consideration (see Open Design Questions).

---

## ID Strategy

**Decision**: UUIDs (v4) are used as the primary identifier for tasks, with
optional short aliases stored as metadata for quick reference.

**Rationale**:
- UUIDs are collision-resistant across machines, making them ideal for
  multi-host synchronization
- No coordination required between machines when creating tasks
- Optional `alias` field provides human-friendly short identifiers for
  command-line operations
- UUIDs ensure uniqueness even when tasks are created concurrently on
  different machines

**Implementation**:
- Task files are named `<uuid>.toml` (e.g., `550e8400-e29b-41d4-a716-446655440000.toml`)
- The `id` field in the `[meta]` section contains the UUID as a string
- The optional `alias` field in the `[task]` section can contain a short identifier (e.g., `"t1"` or `"review-pr"`)
- Aliases are recommended to be unique but not enforced by the format

See [task-file-format.md](task-file-format.md) for complete format
specification.

## Open Design Questions

### Task Graph / Dependencies

* How deeply do I want to lean into parent/child or dependency graphs?
* How do I model these relationships in a way that survives sync/merge?

### Conflict Strategy

* When two machines edit the same task file:

  * How to detect which field "wins"?
  * Do I want field-wise merges or "last-writer wins"?
* Is it acceptable to occasionally drop to manual conflict resolution via `git mergetool`?

### Recurring Tasks Implementation

* **Auto-completion timing**: How should auto-completion be triggered?
  * Cron job? Background daemon? On-demand check?
  * Should it run automatically on every command, or require explicit invocation?
* **Multi-host coordination**: How to prevent duplicate task generation when multiple machines run auto-completion?
  * Use timestamps and sequence numbers?
  * Lock files or other coordination mechanisms?
* **Recurrence template storage**: Where should recurrence templates be stored?
  * In the task file itself?
  * Separate template files?
  * Configuration file?
* **Auto-completion action defaults**: What should the default action be for incomplete recurring tasks?
  * Complete, skip, or delete?
  * Should this be configurable per task or globally?

---

## File Format Details

Tasks are stored as TOML files. See [design-decisions.md](design-decisions.md) for more information on the TOML format choice.

For complete details on the task file format, including field definitions,
validation rules, and examples, see [task-file-format.md](task-file-format.md).

