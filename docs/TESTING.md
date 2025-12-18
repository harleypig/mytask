# Testing Guide

This document describes the testing strategy and conventions for the mytask
project.

## Testing Framework

We use **Test::More** as the primary testing framework:

- Simple, straightforward API
- Well-established and widely used
- Excellent documentation and community support
- Works seamlessly with `prove` test runner
- Sufficient for unit tests, integration tests, and edge cases

## Test Structure

Tests are located in the `t/` directory following standard Perl conventions:

```
t/
├── 00-load.t          # Basic module loading tests
├── 01-format.t        # Task file format parsing tests
├── 02-examples.t      # Example file validation tests
├── 03-commands.t      # CLI command tests (future)
└── ...
```

### Test File Naming

- Use descriptive names: `01-format.t`, `02-examples.t`
- Prefix with numbers for execution order if needed
- Use `.t` extension
- Use hyphens or underscores (be consistent)

## Writing Tests

### Basic Test Structure

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;

# Test setup
BEGIN {
    use_ok('MyTask::Format') or BAIL_OUT("Cannot load MyTask::Format");
}

# Test cases
subtest "Basic task parsing" => sub {
    my $task_file = path('docs/examples/simple-task.toml');
    ok($task_file->exists, "Example file exists");

    # Parse and validate
    my $task = parse_task_file($task_file);
    is($task->{task}{description}, "Review pull request #123", "Description matches");
    is($task->{task}{status}, "pending", "Status is pending");
    is($task->{meta}{id}, "550e8400-e29b-41d4-a716-446655440000", "ID matches");
};

done_testing;
```

### Test Conventions

1. **Always use `done_testing`** at the end (or specify test count)
2. **Use descriptive test names** in assertions
3. **Group related tests** with `subtest`
4. **Use appropriate assertions**:
   - `ok($condition, $message)` - General truth test
   - `is($got, $expected, $message)` - String/number equality
   - `is_deeply($got, $expected, $message)` - Deep structure comparison
   - `like($string, $regex, $message)` - Pattern matching
   - `unlike($string, $regex, $message)` - Negative pattern matching
   - `dies_ok { code } $message` - Exception testing
   - `lives_ok { code } $message` - No exception

5. **Test both success and failure cases**
6. **Test edge cases** (empty values, special characters, etc.)

## Testing Task Files

For examples of how to test task files, see the test files in the `t/` directory:

- `t/01-format-schema.t` - Schema validation and edge case testing
- `t/02-examples.t` - Example file validation and structure testing

These test files demonstrate:
- TOML parsing and structure validation
- Field value validation (UUIDs, timestamps, status enums)
- Edge case handling (missing fields, invalid values)
- Notes entry validation

## Testing Example Files

Example files in `docs/examples/` should be tested to ensure:
- They are valid TOML
- They conform to the task file format specification
- Required fields are present
- Field values are valid
- Structure matches the three-section format

## Schema Validation

The task file format is defined by a JSON Schema (`docs/schema/task-file-schema.json`)
which serves as the authoritative source of truth. The Perl module `MyTask::Schema`
provides programmatic validation against this schema.

Tests in `t/01-format-schema.t` validate:
- Schema definition structure
- Example files against the schema
- Edge cases (missing fields, invalid values, etc.)
- Notes entry validation
- Special character handling

When updating the format specification, ensure both the JSON Schema and the
Perl schema module are updated to maintain consistency.

## Running Tests

### Using `make` (Recommended)

The project includes a `Makefile` with convenient test targets:

```bash
# Run all tests (default)
make test

# Run tests with verbose output
make test-verbose

# Run tests in parallel (4 jobs)
make test-parallel

# Run specific test file
make test-file FILE=t/01-format-schema.t

# Show help
make help
```

The Makefile automatically uses `prove -l` to add the `lib/` directory to Perl's include path, so you don't need to remember the `-l` flag.

### Using `prove` Directly

You can also use `prove` directly:

```bash
# Run all tests
prove -l t/

# Run specific test file
prove -l t/02-examples.t

# Verbose output
prove -lv t/

# Parallel execution
prove -j4 -l t/
```

**Note**: Remember to use the `-l` flag (or `-Ilib`) to add the `lib/` directory to Perl's include path so your `MyTask::*` modules can be found.

### Direct execution

```bash
perl -Ilib t/02-examples.t
```

## Test Coverage Goals

- **Unit tests**: Test individual functions/modules in isolation
- **Integration tests**: Test components working together
- **Format validation**: Ensure all example files are valid
- **Edge cases**: Test boundary conditions and error cases
- **Forgiveness**: Test forgiving parsing behavior

## Helper Modules

Consider creating test helper modules in `t/lib/`:

- `t/lib/Test/MyTask.pm` - Common test utilities
- `t/lib/Test/MyTask/Format.pm` - Format validation helpers
- `t/lib/Test/MyTask/Fixtures.pm` - Test fixtures and sample data

## Continuous Integration

Tests should be run:
- Before committing code
- In CI/CD pipelines
- As part of pre-commit hooks (if configured)

## Future Enhancements

- Test coverage reporting (Devel::Cover)
- Performance testing for large task repositories
- Multi-host scenario simulation
- Mock git repositories for sync testing
