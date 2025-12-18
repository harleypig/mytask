# CLI Design

This document specifies the command-line interface for the task manager.

## Design Principles

The CLI should provide:

* **Reasonable CLI UX**:

  * `mytask add`, `mytask list`, `mytask done`, etc. or similar verbs.
  * Output suitable for TUI use or shell piping.
  * Easy to integrate into scripts and other tools.

* **Keyboard-centric workflows**: Optimized for fast, scriptable interactions.

* **Composability**: Commands should work well with pipes, filters, and other Unix tools.

* **Forgiveness**: The CLI should be as forgiving as possible while maintaining
  usability. See [Design Decisions](design-decisions.md) for the forgiveness
  principle.

---

## Command Structure

### Command Syntax

The basic command structure is:

```
mytask <command> [options] "description"
```

**Order Requirements** (strict):
- `<command>` must come first (e.g., `add`, `list`, `done`)
- `[options]` come after the command
- `"description"` (or other positional arguments) come last

**Forgiveness Within Sections**:
- Within `[options]`, order doesn't matter: `mytask add --due 2024-01-20 --tag work` is equivalent to `mytask add --tag work --due 2024-01-20`
- **Option name format is forgiving**: Only the option name matters, not the format. All of these are equivalent:
  - `--tag`, `-tag`, `tag:`, `tag=`
  - `--due`, `-due`, `due:`, `due=`
  - This accommodates different user expectations, preferences, typos, and similar issues
- Description parsing is forgiving: handles quotes, unquoted strings, special characters
- Date formats are parsed leniently: accepts various ISO 8601 formats, relative dates, etc.
- **Multiple values**: Options that accept multiple values can be specified in two ways:
  - Comma-separated list: `tag:tag1,tag2` or `tag=tag1,tag2`
  - Repeated options: `tag: tag1 tag: tag2` or `--tag tag1 --tag tag2`
  - Separator character may be configurable via configuration setting (future enhancement)

### Description Parsing (for `mytask add`)

For the `mytask add` command, the description parsing follows these rules:

- **First unrecognized option keyword**: The first token that doesn't match any
  recognized option keyword (regardless of format) indicates the start of the
  description. Everything from that point forward becomes part of the description.

- **Description can be unquoted**: The description doesn't require quotes,
  making it easy to add tasks quickly.

- **Quoting option values**: When option values contain spaces or could be
  mistaken for option keywords, quote the value to prevent it from being
  interpreted as the start of the description.

**Examples**:
```bash
# Simple case - description starts after recognized options
mytask add -due tomorrow "do the thing"
# Description: "do the thing"

# Unquoted value causes early description start
mytask add -due tomorrow noon -tag test do the thing
# Parsed as: -due="tomorrow", description="noon -tag test do the thing"
# Note: "noon" doesn't match any option, so description starts there

# Quoting the value fixes it
mytask add -due "tomorrow noon" -tag test do the thing
# Parsed as: -due="tomorrow noon", -tag="test", description="do the thing"

# Description can be unquoted if no ambiguity
mytask add -due tomorrow do-the-thing
# Description: "do-the-thing"

# Quoted description works too
mytask add -due tomorrow "do the thing"
# Description: "do the thing"
```

This forgiving parsing allows users to write commands naturally while
accommodating cases where option values might be mistaken for the description
start.

**Examples**:
```bash
# Correct order
mytask add --due 2024-01-20 "Review pull request"

# Options can be in any order
mytask add --tag work --due 2024-01-20 "Review pull request"
mytask add --due 2024-01-20 --tag work "Review pull request"

# Option format is forgiving - all equivalent:
mytask add --tag work "Review pull request"
mytask add -tag work "Review pull request"
mytask add tag:work "Review pull request"
mytask add tag=work "Review pull request"

# Multiple values - comma-separated
mytask add tag:work,urgent "Review pull request"
mytask add tag=work,urgent "Review pull request"

# Multiple values - repeated options
mytask add tag: work tag: urgent "Review pull request"
mytask add --tag work --tag urgent "Review pull request"

# Description can be quoted or unquoted (if no spaces)
mytask add "Review pull request"
mytask add review-pr

# But command must come first
mytask "Review pull request" add  # ERROR - wrong order
```

The exact command name is `mytask` (matches the project name).

### Proposed Commands

* `mytask add` - Create a new task
* `mytask list` - List tasks with optional filtering
* `mytask show` - Display details of a specific task
* `mytask done` - Mark a task as completed
* `mytask edit` - Edit an existing task
* `mytask delete` - Delete a task
* `mytask sync` - Sync with git remotes (if configured)
* `mytask recur` - Create or manage recurring tasks
* `mytask generate` - Manually trigger task generation for recurring tasks
* `mytask auto-complete` - Manually trigger auto-completion check for recurring tasks
* `mytask config dump` - Dump configuration (default or resolved)

Some of these tasks (generate?, auto-complete?) may be incorporated as automatically run every time the `mytask` command is executed.

### Global Options

All commands support global options:

* `--data-dir <path>` or `-d <path>` - Specify the data directory (overrides configuration and environment variables)
* `--config <path>` - Specify path to global config file (overrides XDG default)
* `--verbose` or `-v` - Increase verbosity
* `--quiet` or `-q` - Reduce output
* `--help` or `-h` - Show help

The `--data-dir` option is essential for working with multiple repositories:

* **Multiple repositories**: Users can have multiple data directories, each acting as an independent repository
* **Different remotes**: Each data directory can connect to different remote repositories
* **Override defaults**: Allows specifying a data directory without modifying configuration files
* **Flexible workflows**: Enables separation of personal/work/experimental repositories

**Note**: The data directory IS the repository. There is no separate repository concept—each data directory is a complete, self-contained task repository that can operate independently and sync to its own remote(s).

### Configuration Dump Command

The `mytask config dump` command provides visibility into configuration:

* `mytask config dump --default` - Show built-in default configuration values
* `mytask config dump` (no flags) - Show resolved/working configuration (after all resolution steps)
* Output format: TOML (matches configuration file format)
* Useful for:
  * Debugging configuration issues
  * Understanding what configuration is actually in effect
  * Creating initial configuration files from defaults
  * Verifying configuration resolution order

**Examples**:
```bash
# Show what configuration would be used (resolved)
mytask config dump

# Show built-in defaults only
mytask config dump --default

# Save resolved config to file
mytask config dump > my-config.toml
```

---

## Open Design Questions

### CLI Command Name

The CLI command is **`mytask`** (matches the project name). Short aliases may be added in the future (e.g., `mt` or `t`), but `mytask` is the primary command name.

### Output Formats

* Should commands support multiple output formats (plain text, JSON, TOML)?
* How should list output be formatted for optimal readability and scriptability?

### Filtering and Querying

* What filtering options should be available?
* How should complex queries be expressed?

---

## Integration Points

The CLI should integrate well with:

* **Task hooks**: Built-in hooks system for task operation automation (see [Design Decisions](design-decisions.md))
* **Git hooks**: Pre-commit, post-commit hooks for automatic syncing
* **Cron jobs**: Scheduled task processing
* **Shell scripts**: Easy to call from automation
* **TUI tools**: Output format suitable for terminal UI consumption

### Hook Integration

The CLI executes hooks automatically during task operations:
* Pre-operation hooks can validate or modify task data before operations
* Post-operation hooks can trigger notifications, logging, or other side effects
* Hook execution is transparent to users but can be monitored via verbose/debug flags
* Failed hooks can optionally abort operations or just log warnings

