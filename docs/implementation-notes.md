# Implementation Notes

This document describes implementation language choice and rationale.

## Implementation Language: Perl

Perl is a strong fit for this project because it excels at file-based workflows, structured text parsing, portable command-line tooling, and resilient data-handling. The CPAN ecosystem provides robust modules for filesystem operations (`Path::Tiny`, `File::Spec`), structured formats (`TOML::Tiny` for TOML parsing), UUIDs and unique IDs (`Data::UUID`), timestamps (`Time::Piece`, `DateTime`), and locking (`File::NFSLock`). Perl's strengths in text manipulation, its mature module ecosystem, and its ability to build clean CLI tools (`Getopt::Long`, `App::Cmd`, `MooX::Options`, `CLI::Osprey`) make it ideal for a task manager that relies on plain-text storage and git-friendly syncing.

Its portability and ease of packaging (fatpacking or PAR::Packer if desired) mean that the system will remain durable and easy to install across multiple hosts without heavy dependencies. Perl's philosophy of "files, hashes, and text" directly supports the project's goals: readable task files, simple merges, straightforward scripting, and long-term maintainability.

---

## Key CPAN Modules

### Filesystem Operations

* `Path::Tiny` - Modern, simple file path manipulation
* `File::Spec` - Portable file path operations

### Structured Data Formats

* `TOML::Tiny` - TOML parsing and generation

### Unique Identifiers

* `Data::UUID` - UUID generation

### Date/Time Handling

* `Time::Piece` - Simple date/time objects
* `DateTime` - Comprehensive date/time handling (if needed)

### File Locking

* `File::NFSLock` - Advisory file locking for concurrent access

### CLI Framework

* `Getopt::Long` - Command-line option parsing
* `App::Cmd` - Application framework for CLI tools
* `MooX::Options` - Moo-based option handling
* `CLI::Osprey` - Modern CLI framework

---

## Packaging and Distribution

The system should be:

* **Portable**: Works on any Unix-like environment
* **Easy to install**: Minimal dependencies, or packaged as a standalone executable
* **Distributable**: Can be fatpacked or packaged with PAR::Packer for single-file distribution

### Development Dependencies

The project uses **`local::lib`** for managing Perl module dependencies during development. This ensures:

* **Isolated dependencies**: Project modules don't interfere with system Perl
* **No root access required**: Developers can install dependencies without administrator privileges
* **Consistent environments**: All developers use the same dependency versions

See [DEVELOPMENT.md](DEVELOPMENT.md) for setup instructions and [design-decisions.md](design-decisions.md) for rationale.

---

## Testing Strategy

(To be expanded - see TODO.md for testing strategy questions)

The implementation should be:

* **Testable**: Data model and operations are easy to test
* **Resilient**: "Corrupt the data and see what happens" is feasible and understandable
* **Well-tested**: Comprehensive test suite covering edge cases and multi-host scenarios
