# Cursor Agent Hooks — Practical Reference (Unofficial Spec)

This is a **practical, experience-based reference** for Cursor Agent Hooks, distilled from the official docs, observed behavior, and community reports. See `Resources` below for links.

> Treat this as *how it actually behaves*, not how we wish it behaved.

## File locations

Cursor loads hooks from **both** locations (project overrides global):

```text
<repo>/.cursor/hooks.json
~/.cursor/hooks.json
```

Project hooks run **before** global hooks.

## `hooks.json` structure

```json
{
  "version": 1,
  "hooks": {
    "<eventName>": [
      { "command": "path/to/script" }
    ]
  }
}
```

**Notes**

* `version` **must** be `1`
* `hooks` is a map of event → array of hook definitions
* Multiple hooks are *allowed*, but see **Multi-hook behavior** below

## Common input fields (all events)

The official documentation states that **all hook events receive a common base payload**, with event-specific fields layered on top.

### Documented common fields

Per the official docs (`Input (all hooks)`), **all hooks receive these base fields**:

```json
{
  "conversation_id": "string",
  "generation_id": "string",
  "model": "string",
  "hook_event_name": "string",
  "cursor_version": "string",
  "workspace_roots": ["<path>"],
  "user_email": "string | null"
}
```

**Notes from official docs**

* `hook_event_name`: which lifecycle event triggered the hook
* `conversation_id`: stable for a chat/session (new chat → new id)
* `generation_id`: stable for a single prompt/response cycle within a conversation
* `workspace_roots`: array to support multi-root workspaces

### Observed reality / caveats

* `event` is **sometimes missing** in practice; do not rely on it exclusively
* `repo` is inconsistently populated across versions
* `cwd` is the **most reliable** common field

**Best practice**: Treat common fields as *best-effort metadata*, not guarantees. Always defensively parse.

### Fields seen in the wild (sometimes undocumented or inconsistently documented)

The following fields show up in real payloads and third-party deep dives, but you should treat them as **optional**:

```json
{
  "conversation_id": "668320d2-2fd8-4888-b33c-2a466fec86e7",
  "generation_id": "490b90b7-a2ce-4c2c-bb76-cb77b125df2f",
  "hook_event_name": "beforeShellExecution",
  "workspace_roots": ["/Users/schacon/projects/cc-hooks-example"],
  "prompt": "do something super duper awesome",
  "attachments": [
    {
      "type": "file",
      "file_path": "path/to/open/file.rb"
    }
  ]
}
```

**Notes from other resources**

* GitButler’s deep dive shows `conversation_id`, `generation_id`, `workspace_roots`, `hook_event_name`, and (for prompt-related hooks) `prompt` + `attachments` as part of the stdin payloads.
* Forum reports suggest payload metadata and message handling can vary by platform/version; don’t build hard dependencies on any field other than `command` (for `beforeShellExecution`) and `cwd`.

## Version tagging / compatibility notes

Hooks have been described as **beta** since Cursor **1.7**, and multiple regressions have been reported in **2.0+** (especially on Windows):

* **Cursor 1.7 (beta):** Hooks introduced; return-message fields (`userMessage`/`agentMessage`) are reported to work as documented.
* **Cursor 2.0.x:** Multiple reports that returned `userMessage`/`agentMessage` are ignored (e.g., 2.0.64, 2.0.77).
* **Cursor 2.1.x:** Ongoing reports of hooks not executing or behaving inconsistently (e.g., 2.1.6), and cases where the UI claims hooks ran but scripts never executed (e.g., 2.1.42).

**Recommendation**: When you share hook configs across machines/teams, annotate them like:

```text
Verified on: Cursor 1.7.x (macOS/Linux)
Known issues: Cursor 2.0–2.1 on Windows may ignore hook return messages and/or fail to execute project hooks.
```

If hooks are mission-critical (e.g., blocking `git push`/`terraform apply`), consider a **real Git hook** fallback as the authoritative enforcement layer.

## Supported hook events

### `beforeShellExecution`

**The only truly powerful hook**

Runs **before the agent executes any shell command**.

#### Capabilities

* Can **allow or deny** command execution
* Receives full command as input
* Can message the agent and/or user

#### Input (stdin)

```json
{
  "command": "git commit -m test",
  "cwd": "/path/to/repo"
}
```

#### Output (stdout)

```json
{
  "continue": true,
  "permission": "allow",
  "agentMessage": "optional but recommended",
  "userMessage": "optional; unreliable"
}
```

#### Behavior

* If `permission` is `deny` or `continue` is `false`, the command **never executes**
* Cursor treats this as a hard policy gate

#### Ideal use cases

* `git commit` / `git push` gating
* pre-commit enforcement
* terraform / prod safety checks
* forcing dry-run usage

### `afterShellExecution`

Runs **after** a shell command completes.

#### Input (stdin)

```json
{
  "command": "make test",
  "exitCode": 1
}
```

#### Output (stdout)

```json
{}
```

#### Notes

* Output is ignored
* Cannot block or influence behavior

Best used for logging or metrics.

### `afterFileEdit`

Runs when the **agent** edits a file.

#### Input (stdin)

```json
{
  "path": "src/foo.py"
}
```

#### Output (stdout)

```json
{}
```

#### Important limitations

* Fires **only for agent edits**, not human edits
* Cannot block anything
* No file contents provided

#### Gotchas

* Easy to create edit → format → edit loops
* No guarantee edit is “final”

Best used sparingly.

### `stop`

Runs when the agent finishes a task.

#### Input (stdin)

```json
{}
```

#### Output (stdout)

```json
{}
```

#### Observations

* Often fires after the agent has already finalized output
* Cannot reliably affect agent response

Mostly useless except for telemetry.

## Execution environment

Hooks run as **child processes of Cursor**:

* No TTY
* Inherits environment (PATH, venv, etc.)
* Working directory usually repo root

**Strongly recommended boilerplate**:

```bash
#!/usr/bin/env bash
set -euo pipefail
payload="$(cat)"
```

Failing to consume stdin can cause deadlocks.

## Multi-hook behavior (⚠️ critical)

### Documented

Multiple hooks may be defined per event.

### Reality (observed)

* Often **only the first hook executes**
* Execution order is unreliable
* Failure handling between hooks is undefined

### Recommendation

➡️ **One hook per event**<br />
➡️ Dispatch internally:

```bash
case "$cmd" in
  git\ commit*) handle_commit ;;
  git\ push*)   handle_push ;;
esac
```

## Messaging reliability

| Field          | Reliability     |
| -------------- | --------------- |
| `agentMessage` | ✅ usually shown |
| `userMessage`  | ⚠️ inconsistent |
| stdout/stderr  | ❌ ignored       |

**Best practice**: Put all actionable info in `agentMessage`.

## Hard limits (cannot do)

* ❌ Trigger on *human* file edits
* ❌ Modify agent chat output
* ❌ Intercept non-shell actions
* ❌ Replace real Git hooks
* ❌ Guarantee hook ordering

Hooks are **guardrails**, not automation frameworks.

## Recommended patterns

### ✅ Safe

* Gate `git commit`, `git push`
* Enforce tooling presence
* Require dry-run flags
* Validate repo state

### ⚠️ Risky

* Auto-formatting on `afterFileEdit`
* Multiple hooks per event
* Long-running hooks

### ❌ Avoid

* Depending on hooks for correctness
* Emulating CI logic
* Assuming hooks fire for humans

## Design philosophy (important)

Cursor hooks behave like a **policy firewall**:

* narrow scope
* explicit control
* agent-focused

They are *not* a general automation system.

## Assessment

Cursor hooks are:

* powerful
* underspecified
* fragile if abused

Treat them like **seatbelts, not engines**.

If Cursor adds schemas, ordering guarantees, or human-edit hooks, this will change. Until then, this model is correct.

## Resources

The following sources were used to compile and validate the information in this document:

* **Official Cursor Hooks documentation**
  [https://cursor.com/docs/agent/hooks](https://cursor.com/docs/agent/hooks)

* **Cursor 1.7 changelog (Hooks introduction)**
  [https://cursor.com/changelog/1-7](https://cursor.com/changelog/1-7)

* **GitButler – Cursor Hooks Deep Dive**
  [https://blog.gitbutler.com/cursor-hooks-deep-dive](https://blog.gitbutler.com/cursor-hooks-deep-dive)

* **Skywork – How to use Cursor Hooks (Guide)**
  [https://skywork.ai/blog/how-to-cursor-1-7-hooks-guide/](https://skywork.ai/blog/how-to-cursor-1-7-hooks-guide/)

* **Cursor Community Forum (bug reports & behavior confirmation)**
  [https://forum.cursor.com/](https://forum.cursor.com/)

* **Empirical behavior testing**
  Observed behavior from real-world usage with `beforeShellExecution`, multi-hook configurations, and pre-commit gating patterns.
