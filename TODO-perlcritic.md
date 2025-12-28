## Perlcritic Hardening Tasks

- [x] Re-enable `TestingAndDebugging::RequireUseStrict` for Perl sources; keep hook `types` to Perl.
- [x] Re-enable `InputOutput::ProhibitTwoArgOpen` and `InputOutput::ProhibitBarewordFileHandles` by migrating to three-arg `open` with lexical handles.
- [x] Re-enable `Bangs::ProhibitBitwiseOperators` after replacing intentional bitwise usage or adding scoped `## no critic`.
- [x] Re-enable `ValuesAndExpressions::ProhibitAccessOfPrivateData` by using accessors or scoped `## no critic`.
- [x] Audit `.perlcriticrc` exclusions; remove temporary excludes once code is compliant. (Current exclude list is empty; no temporary excludes remain.)
- [x] Evaluate `.perlcriticrc` globals (encoding, severity, allow-unsafe, caching, top) for possible tightening before raising severity. (Set `allow-unsafe = 0`; keep severity at 5 for now; top=10 retained; no caching tweaks.)
- [x] Raise profile-strictness from `quiet` to `warn` (perlcritic valid values: quiet/warn/fatal); "stern" unsupported.
- [ ] Raise profile-strictness from `stern` to `fatal`, fix any remaining config issues.
- [ ] Raise severity stepwise (e.g., 5 → 4 → 3) and fix new violations per step.
- [ ] Add a dedicated perlcritic CI job (non-modifying) to enforce the stricter profile.
- [ ] Document perlcritic workflow in `docs/DEVELOPMENT.md` (how to run, common suppressions, expected severity).
