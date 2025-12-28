## Perlcritic Hardening Tasks

- [x] Re-enable `TestingAndDebugging::RequireUseStrict` for Perl sources; keep hook `types` to Perl.
- [x] Re-enable `InputOutput::ProhibitTwoArgOpen` and `InputOutput::ProhibitBarewordFileHandles` by migrating to three-arg `open` with lexical handles.
- [x] Re-enable `Bangs::ProhibitBitwiseOperators` after replacing intentional bitwise usage or adding scoped `## no critic`.
- [x] Re-enable `ValuesAndExpressions::ProhibitAccessOfPrivateData` by using accessors or scoped `## no critic`.
- [ ] Audit `.perlcriticrc` exclusions; remove temporary excludes once code is compliant.
- [ ] Raise severity stepwise (e.g., 5 → 4 → 3) and fix new violations per step.
- [ ] Add a dedicated perlcritic CI job (non-modifying) to enforce the stricter profile.
- [ ] Document perlcritic workflow in `docs/DEVELOPMENT.md` (how to run, common suppressions, expected severity).
