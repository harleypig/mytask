## Perlcritic Hardening Tasks

- [x] Re-enable `TestingAndDebugging::RequireUseStrict` for Perl sources; keep hook `types` to Perl.
- [x] Re-enable `InputOutput::ProhibitTwoArgOpen` and `InputOutput::ProhibitBarewordFileHandles` by migrating to three-arg `open` with lexical handles.
- [x] Re-enable `Bangs::ProhibitBitwiseOperators` after replacing intentional bitwise usage or adding scoped `## no critic`.
- [x] Re-enable `ValuesAndExpressions::ProhibitAccessOfPrivateData` by using accessors or scoped `## no critic`.
- [x] Audit `.perlcriticrc` exclusions; remove temporary excludes once code is compliant. (Current exclude list is empty; no temporary excludes remain.)
- [x] Evaluate `.perlcriticrc` globals (encoding, severity, allow-unsafe, caching, top) for possible tightening before raising severity. (Set `allow-unsafe = 0`; keep severity at 5 for now; top=10 retained; no caching tweaks.)
- [x] Raise profile-strictness from `quiet` to `warn` (perlcritic valid values: quiet/warn/fatal); "stern" unsupported.
- [x] Raise profile-strictness from `stern` to `fatal`, fix any remaining config issues. (Applied `fatal`; no config issues reported.)
- [x] Raise severity 5 → 4; fix new violations.
- [ ] Raise severity 4 → 3; fix new violations.
  - [x] Decide handling for logicLAB::RequireParamsValidate / Subroutines::RequireArgUnpacking (standardize Params::Validate usage vs suppress).
  - [x] Decide handling for Subroutines::ProhibitCallsToUnexportedSubs (suppress in tests only).
  - [x] Resolve CodeLayout::TabIndentSpaceAlign (retidy or targeted suppression) in Schema/tests.
  - [x] Decide on HashBarewords policy in tests (quote keys vs suppress in test files).
  - [x] Address Modules::ProhibitExcessMainComplexity in t/02-examples.t (refactor vs suppress with rationale).
  - [x] Apply /x or suppress for long regexes in tests where appropriate.
  - [x] Decide on postderef enforcement (migrate to ->@* / ->%* or suppress in tests).
- [ ] Evaluate feasibility of severity 2; list blockers if not practical.
  - [ ] Address long schema path line / method chain (Tics::ProhibitLongLines, ValuesAndExpressions::ProhibitLongChainsOfMethodCalls) in `lib/MyTask/Schema.pm`.
  - [ ] Replace `unless` blocks in `lib/MyTask/Schema.pm` (ControlStructures::ProhibitUnlessBlocks) with clearer `if`/early-return form.
  - [ ] Fix spacing flag near bottom of `lib/MyTask/Schema.pm` (CodeLayout::ProhibitSpaceIndentation).
  - [ ] Handle empty quotes fallback warning in `lib/MyTask/Schema.pm` (Lax::ProhibitEmptyQuotes::ExceptAsFallback).
  - [ ] Remove or justify top-level no-critic in `t/02-examples.t` (Miscellanea::ProhibitUselessNoCritic).
  - [ ] Replace `$@` usage in `t/02-examples.t` diagnostics (Variables::ProhibitPunctuationVars).
  - [ ] Reorder equality comparisons to put constants on the left in `t/02-examples.t` (ValuesAndExpressions::RequireConstantOnLeftSideOfEqualityChecks).
  - [ ] Break long lines in `t/02-examples.t` to satisfy line-length limits.
- [ ] Evaluate feasibility of severity 1; list blockers if not practical.
- [ ] Add a dedicated perlcritic CI job (non-modifying) to enforce the stricter profile.
- [ ] Document perlcritic workflow in `docs/DEVELOPMENT.md` (how to run, common suppressions, expected severity).

## Severity 2 Findings — Options and Decisions

### Long schema path line / method chain (`lib/MyTask/Schema.pm`)
**Complaint:** Exceeds line-length and long method-chain limits (Tics::ProhibitLongLines, ValuesAndExpressions::ProhibitLongChainsOfMethodCalls).
**Options:**
- Break the chain across lines using intermediate variables.
- Shorten via helper (e.g., `schema_path()` returning the Path::Tiny object).
- Suppress locally around the chain with a brief rationale.
**Notes:** Decision: pass schema path into the library (no hard-coded path). That implies adding a parameter or accessor so the call site owns the location. Leave a suppression only if the path must remain long after refactor.
**Decision:** _TBD_

### `unless` blocks (`lib/MyTask/Schema.pm`)
**Complaint:** ControlStructures::ProhibitUnlessBlocks flags readability concerns.
**Options:**
- Rewrite as `if` with early return/next.
- Invert condition and keep a single `if`.
- Scoped suppression with rationale if logic clearer as-is.
**Notes:** Decision: avoid hard-coded path; likely refactor to an early-return `if` once the path is injected. If we keep `unless`, document why.
**Decision:** Don't hard code the path in the Schema.pm library. It should be passed by the code using the library. Save this for last and we'll review it again then.

### Space indentation flag near bottom (`lib/MyTask/Schema.pm`)
**Complaint:** CodeLayout::ProhibitSpaceIndentation triggered (likely alignment).
**Options:**
- Normalize indentation to spaces per perltidy style (re-run or hand-fix).
- If alignment intentional, add scoped no-critic with comment.
**Notes:** Decision asks whether this is a tab-enforcement rule. Clarify: policy disallows tabs and mixed indentation; we already prefer spaces. If flagged, it likely saw mixed whitespace/alignment—fix spacing and keep policy (do not remove from `.perlcriticrc`).
**Decision:** Add a rule to workflow.md that if this complaint shows up after perltidy is run on the code, then exclude it with as scoped suppression as possible.

### Empty quotes fallback warning (`lib/MyTask/Schema.pm`)
**Complaint:** Lax::ProhibitEmptyQuotes::ExceptAsFallback flags `""` empty-string usage.
**Options:**
- Replace with an explicit message or undef fallback as appropriate.
- Clarify intent with a variable name and comment.
- Scoped suppression if empty string is correct API contract.
**Notes:** Decision: return `undef` unless the API contract requires an empty string. If empty string is intentional, document it and keep/scope a suppression.
**Decision:** Return undef, unless required, then document and keep/scope suppression.

### Useless no-critic at top (`t/02-examples.t`)
**Complaint:** Miscellanea::ProhibitUselessNoCritic detects unused blanket suppression.
**Options:**
- Remove if no longer needed.
- Narrow to specific policies actually required.
- Justify with a comment if intentionally retained.
**Notes:** Decision: narrow to needed policies, add comment about test-specific laxness. Also add a rule to `WORKFLOW.md` stating test files may carry targeted suppressions when needed for reliability.
**Decision:** Narrow to specific policies actually required. Add a comment explaining the need for the exclusion, as well as the note that test files only need to be as strict as needed to make the tests reliable. Add a rule to workflow.md for this as a general requirement.

### `$@` in diagnostics (`t/02-examples.t`)
**Complaint:** Variables::ProhibitPunctuationVars flags `$@` usage.
**Options:**
- Capture exception into a lexical `$err` and use that in diag.
- Use `$EVAL_ERROR` from English.pm.
- Scoped suppression if minimal and intentional.
**Notes:** Decision: in tests, scoped suppression is fine; add workflow guidance. In production code, prefer lexical capture or `$EVAL_ERROR`.
**Decision:** Scoped suppression in test files for this policy is fine. Add a rule to workflow.md that supports this (lax for test files), and uses capture into a lexical for other cases.

### Constant on left side of equality (`t/02-examples.t`)
**Complaint:** ValuesAndExpressions::RequireConstantOnLeftSideOfEqualityChecks.
**Options:**
- Swap operands so constant is on the left.
- Add helper to normalize comparisons.
- Scoped suppression if a swap hurts readability.
**Notes:** Decision: prefer swapping operands; add workflow note that constants-first is the norm unless readability suffers (document exceptions).
**Decision:** Swap operands so constant is on the left. Add a rule to workflow.md that prefers this in most, if not all, cases.

### Long lines (`t/02-examples.t`)
**Complaint:** Exceeds line-length policy.
**Options:**
- Wrap long strings/regexes; use `qr//x` with indentation.
- Extract strings to variables/constants.
- Scoped suppression for unavoidable literals.
**Notes:** Decision: no current offenders seen; add workflow note that `qr//x` is preferred, and scoped suppressions are last resort for unavoidable literals.
**Decision:** I don't see any code that has this issue. Add to WORKFLOW.md the rule for this policy that qr//x is preferred, but unavailable literals should be as limited to scoped suppression as possible.
