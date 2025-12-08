# Problem Statement: File-Based, Multi-Host Task Manager

## Context

I currently use **Taskwarrior** for managing personal and work tasks. It used to be easy to:

* Keep tasks in a plain, file-based format.
* Sync those tasks across multiple machines (servers, laptops, WSL, etc.).
* Version-control the data directory with `git`.
* Do occasional manual surgery on the data when needed.

Originally this worked fine with:

* **taskd** – now effectively abandonware and not something I want to rely on.
* **git-backed data directory** – committing/syncing Taskwarrior’s data between machines.

Taskwarrior’s move toward a **SQLite-based backend** breaks a core part of my workflow:

* SQLite doesn’t merge cleanly across machines.
* It’s not “friendly” to `git`, `diff`, or ad-hoc scripting.
* It turns tasks into something opaque that’s harder to manage, inspect, or repair.

I want a task system that fits *my* environment, not the other way around.

---

## Core Problem

I need a **task management system** that:

* Works across multiple machines/servers.
* Can be synced via simple tools (`git`, `rsync`, Syncthing, etc.).
* Stores data in **plain files** that are:

  * Easy to inspect.
  * Easy to fix with a text editor.
  * Reasonably mergeable when conflicts happen.
* Doesn’t depend on a central always-on service (like taskd).

The current landscape (Taskwarrior w/ SQLite, web apps, heavyweight systems) does not satisfy:

* **Multi-host, low-friction sync** using existing tooling.
* **Durability and longevity**: I want to be able to read these tasks in 10+ years with nothing but a shell and a text editor.
* **Hackability**: I want to be able to write small scripts around the data format without reverse engineering a database.

---

## High-Level Idea

Model tasks similar to **mail storage**:

* Like **Maildir**: **one file per task** in a directory structure.
* Or like **mbox**: a **log-like file** append-only (or mostly) structure.

The exact format can be specialized to tasks, but the principle is:

> **Tasks are files, not rows in a database.**

I’ve already experimented with:

* **One task per text file**, possibly allowing:

  * Multiple parents and dependents.
  * Arbitrary metadata.
* Storing the task directory in `git` to sync across machines.

I want to formalize this idea into a coherent tool and data model.

---

## Storage Model Decision

**Initial approach**: Flat `tasks/` directory with all task files in a single location.

* Status encoded in file metadata (not filesystem location)
* Simple to implement and reason about
* Easy to list, search, and manipulate with standard tools

**Future extensibility**: Structure can be added later if needed (e.g., `tasks/by-project/`, `tasks/archive/`) without breaking existing workflows. This hybrid approach allows us to start simple and evolve the organization as requirements become clearer.

---

## File Format

Tasks will be stored as **TOML** files with the following structure:

* TOML frontmatter for structured metadata (ID, status, dates, tags, etc.)
* Optional freeform body text for notes/description
* Human-readable and merge-friendly
* Easy to parse with standard tools (`toml-cli`, `jq` with TOML support, etc.)

TOML provides a good balance between human readability and structured data, making it ideal for tasks that need to be both machine-parseable and manually editable.

---

## Goals

### Functional Goals

1. **Multi-host support**

   * I can use the tool on multiple machines (servers, laptops, etc.).
   * Tasks stay in sync using `git`, `rsync`, or similar.
   * No single “central” always-on service is required.

2. **Plain-text, file-based storage**

   * Each task is a file (or part of an append-only file).
   * Format is structured TOML but still human-readable.
   * Easy to:

     * `grep` for things.
     * `sed`/`awk`/`jq` the data.
     * Fix broken state by hand.

3. **Simple, robust conflict handling**

   * Git merge conflicts are text-level and understandable.
   * The tool can:

     * Detect conflicting edits.
     * Optionally assist in resolving conflicts.
   * The data model avoids “hyper-fragility” (e.g., no global sequence numbers that explode if two machines add tasks at the same time).

4. **Task semantics (rough cut)**

   * Basic fields:

     * ID
     * Description
     * Status (pending, done, deleted, etc.)
     * Created/modified timestamps
     * Due date / scheduled date
     * Tags
     * Project/context
   * Optional:

     * Parents / dependents (task graph)
     * Notes / freeform body text

5. **Reasonable CLI UX**

   * `task add`, `task list`, `task done`, etc. or similar verbs.
   * Output suitable for TUI use or shell piping.
   * Easy to integrate into scripts and other tools.

### Non-Functional Goals

1. **Portability**

   * Works on any Unix-like environment.
   * Minimal dependencies (no heavy DB required).

2. **Longevity**

   * If the code disappears, the data is still:

     * Readable.
     * Recoverable.
     * Convertible to other formats.

3. **Testability**

   * Data model and operations are easy to test.
   * “Corrupt the data and see what happens” is feasible and understandable.

4. **Performance (sane but not obsessive)**

   * Optimized for a human-scale number of tasks (hundreds to a few tens of thousands).
   * Not trying to handle millions of tasks or real-time collaboration.

---

## Non-Goals

* Not trying to be:

  * A full-blown project management platform.
  * A replacement for calendar systems.
  * A multi-user, concurrent web app.

* Not optimizing for:

  * Giant enterprise datasets.
  * Complex permissions.
  * Fine-grained real-time sync (eventual consistency via git is fine).

---

## Environment & Constraints

### Repository / Deployment Model

Each installation of the task manager should behave like a standalone project repository:

* A task repository is **self-contained** and can run entirely locally with no remote configured.
* All functionality (creating, listing, updating tasks, etc.) must work with:

  * No network access.
  * No central server.
  * No git remote.
* If desired, the same repository can be linked to one or more remotes (e.g., GitHub, GitLab, a bare repo on a server), and:

  * Sync is handled using normal `git` workflows (`pull`, `push`, `fetch`, etc.).
  * There is no assumption of a single “canonical” or always-on server.
* Multiple machines can collaborate on the same task repository the same way they would on a code repository:

  * Clone, branch, commit, merge, push, and pull are all valid workflows.
  * Conflicts are resolved using standard git tooling.

In other words, a task repo should behave exactly like a code repo: fully functional on its own, with optional remotes for sync and collaboration, but no hard dependency on them.

### Interoperability Through Git

Because the task repository is just a git-managed directory of plain-text files, any external tool that understands git can also interact with the task data. This enables:

* Mobile or desktop apps that embed a git client (e.g., an Android app) to clone, edit, or sync tasks directly.
* Third-party tools to parse or manipulate tasks without needing to integrate with a custom API or service.
* Automation or scripting layers to consume tasks the same way they would consume files in any code repository.

This design keeps task data maximally open, inspectable, and ecosystem-friendly—any tool that understands git and text files can participate.

* I manage multiple machines/servers (including remote boxes).
* I already have:

  * `git` everywhere.
  * SSH everywhere.
  * Familiarity with shell scripting and automation.
* I prefer:

  * Keyboard-centric workflows.
  * Tools that can be scripted, piped, and composed.

This means the task manager should:

* Fit well into a dotfiles / infra-as-code environment.
* Avoid hidden magic.
* Play nicely with `git` hooks, cron jobs, etc.

---

## Open Design Questions

1. **ID Strategy**

   * Human-friendly incremental IDs vs. UUIDs vs. hash (e.g., based on content)?
   * How to avoid collisions when multiple machines create tasks concurrently?

2. **Conflict Strategy**

   * When two machines edit the same task file:

     * How to detect which field "wins"?
     * Do I want field-wise merges or "last-writer wins"?
   * Is it acceptable to occasionally drop to manual conflict resolution via `git mergetool`?

3. **Task Graph / Dependencies**

   * How deeply do I want to lean into parent/child or dependency graphs?
   * How do I model these relationships in a way that survives sync/merge?

4. **Interoperability**

   * Do I want an easy bridge from/to Taskwarrior?
   * Do I care about importing/exporting to other tools (e.g., JSON, ICS, etc.)?

---

## Implementation Language: Perl

Perl is a strong fit for this project because it excels at file-based workflows, structured text parsing, portable command-line tooling, and resilient data-handling. The CPAN ecosystem provides robust modules for filesystem operations (`Path::Tiny`, `File::Spec`), structured formats (`TOML::Tiny` for TOML parsing), UUIDs and unique IDs (`Data::UUID`), timestamps (`Time::Piece`, `DateTime`), and locking (`File::NFSLock`). Perl's strengths in text manipulation, its mature module ecosystem, and its ability to build clean CLI tools (`Getopt::Long`, `App::Cmd`, `MooX::Options`, `CLI::Osprey`) make it ideal for a task manager that relies on plain-text storage and git-friendly syncing.

Its portability and ease of packaging (fatpacking or PAR::Packer if desired) mean that the system will remain durable and easy to install across multiple hosts without heavy dependencies. Perl’s philosophy of “files, hashes, and text” directly supports the project’s goals: readable task files, simple merges, straightforward scripting, and long-term maintainability.

## Summary

I want a **simple, file-based task manager** with:

* Plain-text storage.
* Git-friendly sync.
* A data model that’s resilient to multi-host, occasionally-disconnected workflows.
* Enough structure for dependencies and metadata.
* A CLI that doesn’t get in my way.

Databases solve some hard problems but introduce others I don’t actually have. For my use case, **tasks as files** (Maildir/mbox-inspired) is the right mental model; I just need the tooling and format to make it practical.
