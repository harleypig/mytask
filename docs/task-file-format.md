# Task File Format Specification

This document defines the TOML file format used for storing tasks in the
mytask system. Each task is stored as a separate TOML file in the `tasks/`
directory of a task repository.

**Note**: The authoritative source of truth for the task file format is the
JSON Schema definition in `docs/schema/task-file-schema.json`. This document
provides human-readable documentation, but the schema file defines the exact
validation rules and constraints. The Perl module `lib/MyTask/Schema.pm`
provides programmatic access to the schema for validation.

## File Structure

Task files are organized into three distinct sections:

1. **`[task]`** - User-modifiable metadata (description, status, dates, etc.)
2. **`[meta]`** - Program-managed metadata (ID, timestamps, etc.)
3. **`[[notes]]`** - Timestamped journal entries (user notes and app logs)

This structure makes it clear which fields users should edit manually and
which are managed by the application.

## File Naming Convention

Task files are named using their UUID identifier:

```
<uuid>.toml
```

Example: `550e8400-e29b-41d4-a716-446655440000.toml`

The UUID must be a valid UUID v4 format (8-4-4-4-12 hexadecimal digits
separated by hyphens).

## Section: [task] - User-Modifiable Fields

The `[task]` section contains all fields that users can safely modify
manually. These fields control the task's content, status, and scheduling.

### Required Fields

#### `description` (string)

A short, human-readable description of the task.

**Example**: `"Review pull request #123"`

**Validation**:
- Must be a non-empty string
- No length limit (but should be concise for display purposes)
- May contain any Unicode characters
- Leading and trailing whitespace should be trimmed

#### `status` (enum string)

The current state of the task. Must be one of:

- `"pending"` - Task is active and awaiting completion
- `"done"` - Task has been completed
- `"deleted"` - Task has been deleted (soft delete)
- `"archived"` - Task has been archived (preserved but inactive)

**Example**: `"pending"`

**Validation**:
- Must be exactly one of the four allowed values
- Case-sensitive
- Required field

### Optional Fields

#### `alias` (string)

A short, human-friendly identifier for quick reference. Useful for
command-line operations where typing the full UUID is cumbersome.

**Example**: `"t1"` or `"review-pr"`

**Validation**:
- Must be a non-empty string if present
- Should be unique within the repository (recommended but not enforced)
- No specific format requirements
- Case-sensitive

#### `due` (string, ISO 8601 date or timestamp)

The due date or deadline for the task. Can be a date or full timestamp.

**Format**: `YYYY-MM-DD` (date only) or `YYYY-MM-DDTHH:MM:SS` (with time)

**Example**: `"2024-01-20"` or `"2024-01-20T17:00:00Z"`

**Validation**:
- Must be valid ISO 8601 date or timestamp
- If timestamp format is used, should include timezone information
- No constraints on past vs. future dates

#### `scheduled` (string, ISO 8601 date or timestamp)

When the task is scheduled to start or be worked on. Can be a date or full
timestamp.

**Format**: `YYYY-MM-DD` (date only) or `YYYY-MM-DDTHH:MM:SS` (with time)

**Example**: `"2024-01-18"` or `"2024-01-18T09:00:00Z"`

**Validation**:
- Must be valid ISO 8601 date or timestamp
- If timestamp format is used, should include timezone information
- No constraints on past vs. future dates

## Section: [meta] - Program-Managed Fields

The `[meta]` section contains fields that are managed by the application.
Users should generally not modify these fields manually, though the format
allows it for recovery and advanced use cases.

### Required Fields

#### `id` (string, UUID)

The unique identifier for the task. Must be a valid UUID v4 string.

**Format**: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` where x is hexadecimal
and y is one of 8, 9, A, or B.

**Example**: `"550e8400-e29b-41d4-a716-446655440000"`

**Validation**:
- Must match UUID v4 format
- Must be unique within the repository
- Should not be changed after task creation (program-managed)

#### `created` (string, ISO 8601 timestamp)

When the task was created. Must be in ISO 8601 format.

**Format**: `YYYY-MM-DDTHH:MM:SS` or `YYYY-MM-DDTHH:MM:SSZ` for UTC

**Example**: `"2024-01-15T10:30:00"` or `"2024-01-15T10:30:00Z"`

**Validation**:
- Must be valid ISO 8601 timestamp
- Should include timezone information (Z for UTC or offset)
- Should not be changed after task creation (program-managed)
- Set automatically when task is created

#### `modified` (string, ISO 8601 timestamp)

When the task was last modified. Must be in ISO 8601 format.

**Format**: `YYYY-MM-DDTHH:MM:SS` or `YYYY-MM-DDTHH:MM:SSZ` for UTC

**Example**: `"2024-01-15T14:45:00Z"`

**Validation**:
- Must be valid ISO 8601 timestamp
- Should include timezone information
- Must be equal to or later than `created` timestamp
- Updated automatically by the application when any field changes

## Section: [[notes]] - Timestamped Journal Entries

The `[[notes]]` section is an array of tables, each containing a
timestamped journal entry. Entries can be created by users (manual notes)
or by the application (action logs).

### Note Entry Structure

Each note entry is a TOML table with the following fields:

#### `timestamp` (string, ISO 8601 timestamp, required)

When the note entry was created. Must be in ISO 8601 format.

**Format**: `YYYY-MM-DDTHH:MM:SS` or `YYYY-MM-DDTHH:MM:SSZ` for UTC

**Example**: `"2024-01-15T10:30:00Z"`

**Validation**:
- Must be valid ISO 8601 timestamp
- Should include timezone information
- Required field

#### `entry` (string, required)

The content of the note entry. Can be a single line or multiline text.

**Example**: `"Initial notes about the task."`

**Example** (multiline):
```toml
entry = '''
Started review, found some issues:
- Error handling needs improvement
- Missing edge case coverage
'''
```

**Validation**:
- Must be a non-empty string
- No format constraints (freeform)
- Preserve whitespace and line breaks
- Can use TOML multiline literal strings (`'''`) or basic strings (`"""`)

#### `type` (string, optional)

The type of note entry. Used to distinguish user notes from app-generated
logs.

**Values**:
- `"note"` - User-created note (default if not specified)
- `"log"` - Application-generated log entry
- `"comment"` - User comment (future use)
- `"status-change"` - Logged status change (future use)

**Example**: `"log"`

**Validation**:
- Optional field
- If present, should be one of the recognized types
- Case-sensitive

### User Notes vs. App Logs

**User Notes**: Created manually by users for journaling, task tracking, or
documentation. These are the primary use case for the notes section.

**App Logs**: Automatically created by the application to track actions and
changes. Examples:
- Task creation
- Status changes
- Field updates
- Recurrence generation
- Auto-completion events

App logs help maintain an audit trail of what the application has done,
which is useful for debugging, understanding task history, and maintaining
data integrity.

### Example Notes Section

```toml
# User-created notes
[[notes]]
timestamp = "2024-01-15T10:30:00Z"
entry = "Initial notes about the task. Need to review authentication changes."

[[notes]]
timestamp = "2024-01-16T14:20:00Z"
entry = '''
Started review, found some issues:
- Error handling needs improvement
- Missing edge case coverage
'''

# App-generated log entry
[[notes]]
timestamp = "2024-01-17T09:15:00Z"
type = "log"
entry = "Status changed from 'pending' to 'done'"
```

## Complete Example

```toml
# User-modifiable metadata
[task]
description = "Review pull request #123"
status = "pending"
due = "2024-01-20"
alias = "review-pr"

# Program-managed metadata
[meta]
id = "550e8400-e29b-41d4-a716-446655440000"
created = "2024-01-15T10:30:00Z"
modified = "2024-01-15T14:45:00Z"

# Timestamped journal entries
[[notes]]
timestamp = "2024-01-15T10:30:00Z"
entry = "Initial notes about the task. Need to review authentication changes."

[[notes]]
timestamp = "2024-01-16T14:20:00Z"
entry = "Started review, found some issues with error handling."

[[notes]]
timestamp = "2024-01-17T09:15:00Z"
type = "log"
entry = "Status changed from 'pending' to 'done'"
```

## Field Validation Rules

### Type Validation

- **Strings**: Must be valid TOML strings (quoted or literal)
- **Enums**: Must match exactly one of the allowed values
- **Timestamps**: Must be valid ISO 8601 format
- **Dates**: Must be valid ISO 8601 date format
- **Arrays**: Notes array must contain valid table entries

### Constraint Validation

- Required fields must be present and non-empty
- `[meta].modified` must be >= `[meta].created`
- UUID format must be valid UUID v4
- Status must be one of: `pending`, `done`, `deleted`, `archived`
- Note entries must have `timestamp` and `entry` fields

### Section Organization

- `[task]` section must exist and contain required fields
- `[meta]` section must exist and contain required fields
- `[[notes]]` section is optional (array may be empty or absent)
- Notes entries should be ordered chronologically (by timestamp)

### Edge Cases

The format should handle:

- **Special characters**: Unicode characters, quotes, newlines in strings
- **Long text**: No length limits, but tools may truncate for display
- **Empty fields**: Optional fields may be omitted entirely
- **Whitespace**: Leading/trailing whitespace should be trimmed for
  structured fields
- **Timezone handling**: Timestamps should include timezone information
  when possible
- **Empty notes array**: `[[notes]]` section may be absent or empty

## Manual Editing Guidelines

When manually editing task files:

- **Safe to edit**: All fields in the `[task]` section
- **Generally avoid**: Fields in the `[meta]` section (though allowed for
  recovery)
- **Can add**: New entries to the `[[notes]]` array
- **Can modify**: Existing note entries (though timestamps should generally
  be preserved)

The three-section structure makes it visually clear which fields are
user-modifiable and which are program-managed.

## TOML Parsing Requirements

Task files must be valid TOML according to the TOML v1.0 specification.
Parsers should:

- Handle all TOML string types (basic, literal, multiline)
- Support ISO 8601 date and timestamp parsing
- Support TOML array of tables syntax (`[[notes]]`)
- Preserve note entry content exactly as written
- Report clear errors for invalid TOML syntax
- Validate field types and constraints after parsing
- Validate section structure (required sections present)

## Example Task Files

See the `docs/examples/` directory for complete example task files
demonstrating various scenarios:

- `simple-task.toml` - Basic task with minimal fields
- `task-with-notes.toml` - Task with timestamped journal entries
- `task-with-due-date.toml` - Task with due date
- `completed-task.toml` - Completed task
- `deleted-task.toml` - Deleted task
- `task-with-alias.toml` - Task with alias field

## Future Extensions

This format may be extended in future milestones to include:

- Tags (array of strings in `[task]` section)
- Project/context (string in `[task]` section)
- Recurrence configuration (table in `[task]` section)
- Task dependencies (arrays of task IDs in `[task]` section)
- Additional note entry types (extend `type` field in `[[notes]]`)
- Note entry metadata (e.g., `author`, `tags` per note entry)

These extensions will maintain the three-section structure defined here.
