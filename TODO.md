# TODO

Track milestone progress. All milestone details, open questions, and decisions live in `docs/milestones.md`.

* When adding a new task, determine if it fits in the current or any future milestone and add it to the appropriate section in `docs/milestones.md`, otherwise add it below.

## Milestones

- [x] Milestone 1: Task File Format (Basic) — complete
- [ ] Milestone 2: Basic Commands
- [ ] Milestone 3: Configuration Handling
- [ ] Milestone 4: Hooks System
- [ ] Milestone 5: Tags
- [ ] Milestone 6: Recurring Tasks
- [ ] Milestone 7: Task Dependencies

## Future Milestones

- [ ] Projects
- [ ] Git Integration
- [ ] Export/Import
- [ ] Conflict Handling
- [ ] Show/Reminder Fields & Forgiving Recovery
- [ ] Additional UIs (TUI/Web/Android) and packaging (Docker, PAR::Packer)

## Commitizen Configuration Follow-ups

- [ ] Decide on changelog handling and add `changelog_file` if/when `cz bump` is used (e.g., `CHANGELOG.md`).
- [ ] Enforce concise titles by setting `message_length_limit` (suggested: 72).
- [ ] Decide whether to explicitly allow autosquash prefixes; add `allowed_prefixes` for `fixup!` / `squash!` if desired.
- [ ] Confirm whether to keep `update_changelog_on_bump: true` now or defer until the release workflow is defined.
- [ ] Align tagging style: if tags should be prefixed (e.g., `v1.2.3`), set `tag_format: v$version`; otherwise keep `$version`.

## Perl Tools

Use [tidyall](https://metacpan.org/dist/Code-TidyAll/view/bin/tidyall) for the various linters, validators and such.
