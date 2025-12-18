# Repository Workflow

This document defines project-specific workflow rules and conventions for
the mytask project. These rules extend and override the general principles
defined in `AGENTS.md`.

## Milestone Completion Process

### Component vs. Milestone Completion

**Components** (individual tasks, subtasks, or deliverables within a
milestone) can be marked as completed as work progresses. This allows
tracking of incremental progress.

**Milestones** require explicit approval from the project maintainer before
they can be marked as completed, even if all components within the milestone
are complete.

### Rationale

As individual components are completed, we may discover that:
- Something needs to be changed or adjusted
- Additional work is required beyond the original scope
- Design decisions need to be reconsidered
- Integration issues emerge that weren't apparent during component
  development

By requiring explicit approval for milestone completion, we ensure that:
- All components are reviewed together for consistency
- Integration issues are caught before marking milestones complete
- Design decisions are validated holistically
- Changes can be made without marking issues as "future" problems

### Process

1. **Component Completion**: Individual components within a milestone can
   be marked as completed (e.g., "✅ RESOLVED" or "✅ COMPLETED") as work
   progresses.

2. **Milestone Status**: Milestones should be marked with component-level
   completion status but should NOT be marked as fully completed until
   explicitly approved.

3. **Approval Required**: Before a milestone can be marked as complete, the
   project maintainer must explicitly approve it. This approval should be
   documented in the TODO.md file.

4. **Status Indicators**: Use the following status indicators:
   - Components: `✅ RESOLVED` or `✅ COMPLETED` (when component is done)
   - Milestones: `⏳ PENDING APPROVAL` (when components are done but
     milestone needs approval)
   - Milestones: `✅ APPROVED` (only after explicit approval)

### Example

```
## Milestone 1: Task File Format (Basic) ⏳ PENDING APPROVAL

### ID Strategy ✅ RESOLVED
[... component details ...]

### Example Task File Format ✅ RESOLVED
[... component details ...]

### Directory Structure ✅ RESOLVED
[... component details ...]

**Status**: All components complete. Awaiting maintainer approval.
```

After approval:

```
## Milestone 1: Task File Format (Basic) ✅ APPROVED

[... same component details ...]

**Status**: Approved by [maintainer] on [date].
```

## Development Workflow

### Branch Naming

Branch names follow a prefix pattern:
- Feature branches: `feature/<description>`
- Bugfix branches: `bugfix/<description>`
- Milestone branches: `milestone/<milestone-name>` (e.g., `milestone/task-file-format`)

**Automatic Prefix Application**: When a branch name is requested with only
the descriptive part (e.g., "task-file-format"), the appropriate prefix
should be automatically applied based on context:
- If the request mentions "milestone" or relates to milestone work, use
  `milestone/` prefix
- If the request mentions a bug fix or bug, use `bugfix/` prefix
- If the request mentions a new feature, use `feature/` prefix
- If it's not obvious which type it is, ask the user for clarification

**Examples**:
- Request: "create a branch for the first milestone named task-file-format"
  → Create: `milestone/task-file-format`
- Request: "create branch fix-auth-bug"
  → Create: `bugfix/fix-auth-bug`
- Request: "create branch add-search-feature"
  → Create: `feature/add-search-feature`
- Request: "create branch refactor-parser"
  → Ask: "Is this a feature, bugfix, or milestone branch?"

### Code Formatting

**Indentation**: Use 2-space indentation for all code files. Do not use tabs
except where required by external tools (e.g., Makefiles).

**Rationale**: Consistent indentation improves readability and reduces merge
conflicts. Two spaces provide a good balance between visual indentation and
line length.

**Enforcement**: All Perl files, test files, configuration files, and
documentation should use 2-space indentation. Tabs should only be used when
required by external tools (such as Makefiles).

### Commit Messages

Follow conventional commit format when applicable:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code refactoring
- `test:` for test additions/changes

### Code Review

- All changes should be reviewed before merging
- Milestone completion requires explicit approval (see above)
- Component completion can be self-approved by the developer/agent

## Documentation Standards

- Documentation should be clear, concise, and practical
- Include examples where helpful
- Update documentation as implementation progresses
- Cross-reference related documents

## Testing Requirements

- Each milestone must include comprehensive tests
- Tests should cover happy paths, error cases, and edge cases
- Integration tests should verify milestone functionality works with
  previous milestones
- Test coverage should be documented

