# Contributing

This document describes how to contribute to the project. For development environment setup, see [DEVELOPMENT.md](DEVELOPMENT.md).

## Contribution Process

### Before You Start

1. Review the project documentation:
   * Read [README.md](README.md) for project overview
   * Review [milestones.md](milestones.md) to understand development priorities
   * Check [TODO.md](../../TODO.md) for open questions and tasks
   * Review [AGENTS.md](../../AGENTS.md) for development guidelines

2. Set up your development environment:
   * Choose a Perl environment setup method:
     * **Standard setup**: Uses `local::lib` for project-specific module isolation
     * **Perlbrew setup**: Uses `perlbrew` for Perl version and module management
   * Run `./scripts/bootstrap.sh` (automatically detects your setup)
   * See [DEVELOPMENT.md](DEVELOPMENT.md) for complete setup instructions for both scenarios

3. Identify what you want to work on:
   * Create an issue and discuss with the developers before starting work
   * Check current milestone status in [milestones.md](milestones.md)
   * Review open questions in [TODO.md](../../TODO.md)
   * Consider future milestones if current ones are complete

### Working on Milestones

The project follows a milestone-based development approach. Each milestone must satisfy:

1. **Documentation**: Complete documentation covering the milestone's functionality
2. **Tests**: Comprehensive tests for all code changes
3. **Working Implementation**: Functionality must be implemented and working
4. **Versioning**: Follow versioning guidelines (see [milestones.md](milestones.md))

**Milestone Requirements**:

* Follow the milestone structure defined in [milestones.md](milestones.md)
* Ensure documentation is complete before marking milestone complete
* Write tests for all code changes
* Follow guidelines in [AGENTS.md](../../AGENTS.md)
* Update relevant documentation as you implement features

### Code Contributions

**Code Style**:

* Follow Perl best practices (use `strict` and `warnings`)
* Write clear, readable code over clever optimizations
* Document complex logic with comments
* Follow repository naming conventions (see [AGENTS.md](../../AGENTS.md))
* Follow consistent indentation (spaces or tabs - to be decided)

**Testing**:

* Write tests for all new functionality
* Test edge cases and error conditions
* Ensure tests pass before submitting
* See [DEVELOPMENT.md](DEVELOPMENT.md) for testing framework details (TBD)

**Documentation**:

* Update relevant documentation files as you implement features
* Follow documentation principles (78-column wrapping, clear examples)
* Ensure documentation matches implementation
* See [DEVELOPMENT.md](DEVELOPMENT.md) for documentation structure

### Cross-Milestone Considerations

When working on any milestone, consider:

* **Testing**: Write comprehensive tests (see [TODO.md](../../TODO.md) - Testing Strategy)
* **Program Help**: Add `--help` documentation for new commands
* **Documentation**: Update relevant docs files
* **Hooks Integration**: Consider hook integration points for new functionality
* **Configuration Needs**: Identify configuration options and defaults
* **Error Handling**: Consistent error messages and graceful degradation
* **Logging**: Appropriate log levels and configurable verbosity
* **Output Formats**: Consider multiple output formats where appropriate
* **Multi-Host / Sync**: Ensure features work across multiple machines
* **Backward Compatibility**: Consider impact on existing task files
* **Performance**: Ensure reasonable performance (see [TODO.md](../../TODO.md) - Performance Considerations)
* **Validation**: Validate input data and provide clear error messages
* **User Experience**: Intuitive syntax and clear feedback

See [TODO.md](../../TODO.md) - General / Cross-Milestone for detailed requirements.

## Git Workflow

Follow the Git Workflow guidelines in [AGENTS.md](../../AGENTS.md):

* Commit frequently with descriptive messages
* Prefer conventional commit messages when applicable
* Create feature branches from the latest main branch
* Prefix branches appropriately (`feature/`, `bugfix/`, `refactor/`)
* Use `git add -u` for modifications, add new files explicitly
* Prefer squash merges when merging feature branches

## Questions and Clarifications

If you have questions about:

* **Design decisions**: Check [design-decisions.md](design-decisions.md)
* **Open questions**: See [TODO.md](../../TODO.md)
* **Milestone requirements**: Review [milestones.md](milestones.md)
* **Development setup**: See [DEVELOPMENT.md](DEVELOPMENT.md)

---

**Note**: This is a living document. Update it as contribution processes evolve.
