# Migration and Export

This document describes migration tools and export capabilities for the task manager.

## Migration Tools

Migration tools are **acknowledged as useful** but are **low priority** for the core system. This is because:

* **Tasks are stored as TOML files**: The task format is human-readable and easily parseable
* **Standard format**: TOML is a well-supported format with libraries available in many languages
* **Simple structure**: Task files have a straightforward structure that's easy to convert
* **External tools**: Users can write their own migration scripts using standard TOML parsers

### User-Contributed Migration Tools

If users need migration tools (e.g., to or from Taskwarrior, Todo.txt, or other task managers), they are encouraged to:

1. **Write their own migration scripts**: Since tasks are plain TOML files, migration scripts can be written in any language with TOML support
2. **Submit contributions**: Users can submit migration tools to the project repository
3. **Share independently**: Migration tools can be shared as standalone scripts or separate projects

The project will accept and maintain user-contributed migration tools, but they are not part of the core MVP.

---

## Export Formats

The task manager will support **export functionality** that converts tasks from TOML to other formats. This serves both as a migration aid and as a way to integrate with other tools.

### Export Scope

Export can be performed on:

* **Individual tasks**: Export a single task by ID
* **Task subsets**: Export tasks matching filters (tags, status, project, etc.)
* **All tasks**: Export the entire task repository

### Export Formats

The export functionality will provide **straight conversion** from TOML to the requested format:

* **JSON**: Direct conversion of TOML structure to JSON
* **CSV**: Tabular format with one row per task
* **ICS (iCalendar)**: For calendar integration
* **Markdown**: Human-readable task list format
* **Plain text**: Simple text representation
* **Other formats**: As needed (can be extended)

### Export Implementation

Export is implemented as:

* **Format conversion**: Simple transformation from TOML to target format
* **No data loss**: All task data is preserved in the conversion
* **CLI command**: `task export` command with format options
* **Straightforward**: No complex mapping or transformation logic—just format conversion

### Example Usage

```bash
# Export all tasks to JSON
task export --format json > tasks.json

# Export pending tasks to CSV
task export --format csv --filter status=pending > pending.csv

# Export single task to ICS
task export --format ics --task <task-id> > task.ics
```

---

## Import Functionality

The task manager will support **import functionality** that accepts the same formats as export and performs **straight conversion** to TOML.

### Import Behavior

* **Format support**: Import accepts the same formats as export (JSON, CSV, ICS, Markdown, plain text, etc.)
* **No data manipulation**: Import performs **no data mangling or transformation**—it's a direct format conversion
* **Direct mapping**: Data should map correctly from source format to TOML structure
* **External tools**: Any data manipulation, field mapping, or transformation should be handled by **external tools** before import

### Import Process

1. **Parse source format**: Read and parse the input file (JSON, CSV, etc.)
2. **Convert to TOML**: Direct conversion to TOML structure
3. **Create task files**: Write TOML task files to the repository
4. **No validation**: Import does not validate or normalize data—it trusts the input format

### Data Manipulation

If imported data needs manipulation (e.g., field mapping, data transformation, validation):

* **Use external tools**: Pre-process the data with external scripts or tools
* **Convert format**: External tools can convert from source format → export format → import
* **Clean data**: External tools handle data cleaning, normalization, and validation
* **Then import**: Import the cleaned, properly-formatted data

The import command is intentionally simple: it accepts export formats and converts them directly to TOML, with no manipulation or transformation logic.

### Example Usage

```bash
# Import from JSON (exported from another system)
task import --format json < tasks.json

# Import from CSV (after external preprocessing)
task import --format csv < cleaned-tasks.csv

# Import single task from ICS
task import --format ics < task.ics
```

---

## Summary

* **Migration tools**: Low priority, user-contributed
* **Export**: Core feature, straight TOML → format conversion
* **Import**: Core feature, straight format → TOML conversion (no data manipulation)
* **Data manipulation**: Handled by external tools before import
* **Rationale**: TOML format makes it easy for users to write their own tools
