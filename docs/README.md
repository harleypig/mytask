# Overview: File-Based, Multi-Host Task Manager

## Context

I currently use **Taskwarrior** for managing personal and work tasks. It used to be easy to:

* Keep tasks in a plain, file-based format.
* Sync those tasks across multiple machines (servers, laptops, WSL, etc.).
* Version-control the data directory with `git`.
* Do occasional manual surgery on the data when needed.

Originally this worked fine with:

* **taskd** – now effectively abandonware and not something I want to rely on.
* **git-backed data directory** – committing/syncing Taskwarrior's data between machines.

Taskwarrior's move toward a **SQLite-based backend** breaks a core part of my workflow:

* SQLite doesn't merge cleanly across machines.
* It's not "friendly" to `git`, `diff`, or ad-hoc scripting.
* It turns tasks into something opaque that's harder to manage, inspect, or repair.

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
* Doesn't depend on a central always-on service (like taskd).

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

I've already experimented with:

* **One task per text file**, possibly allowing:

  * Multiple parents and dependents.
  * Arbitrary metadata.
* Storing the task directory in `git` to sync across machines.

I want to formalize this idea into a coherent tool and data model.

---

## Goals

### Functional Goals

1. **Multi-host support**

   * I can use the tool on multiple machines (servers, laptops, etc.).
   * Tasks stay in sync using `git`, `rsync`, or similar.
   * No single "central" always-on service is required.

2. **Plain-text, file-based storage**

   * Each task is a file (or part of an append-only file).
   * Format is structured TOML but still human-readable.
   * Easy to:

     * `grep` for things.
     * `sed`/`awk`/`jq` the data.
     * Fix broken state by hand.
   * **Forgiving**: The system handles invalid filenames, incomplete formats,
     and manual edits gracefully, automatically fixing issues where possible.

3. **Simple, robust conflict handling**

   * Git merge conflicts are text-level and understandable.
   * The tool can:

     * Detect conflicting edits.
     * Optionally assist in resolving conflicts.
   * The data model avoids "hyper-fragility" (e.g., no global sequence numbers that explode if two machines add tasks at the same time).

4. **Task semantics (rough cut)**

   * Basic fields:

     * ID
     * Description
     * Status (pending, done, deleted, archived, etc.)
     * Created/modified timestamps
     * Due date / scheduled date
     * Tags
     * Project/context
   * Optional:

     * Parents / dependents (task graph)
     * Notes (timestamped journal entries in `[[notes]]` array)

5. **Reasonable CLI UX**

   * `mytask add`, `mytask list`, `mytask done`, etc. or similar verbs.
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
   * "Corrupt the data and see what happens" is feasible and understandable.

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

## Summary

I want a **simple, file-based task manager** with:

* Plain-text storage.
* Git-friendly sync.
* A data model that's resilient to multi-host, occasionally-disconnected workflows.
* Enough structure for dependencies and metadata.
* A CLI that doesn't get in my way.

Databases solve some hard problems but introduce others I don't actually have. For my use case, **tasks as files** (Maildir/mbox-inspired) is the right mental model; I just need the tooling and format to make it practical.

---

## Documentation

For more detailed information, see the following documents in reading order:

1. [Design Decisions](design-decisions.md) - Storage model and file format decisions
2. [Data Model](data-model.md) - Task structure, fields, and relationships
3. [Architecture](architecture.md) - System architecture and deployment model
4. [CLI Design](cli-design.md) - Command-line interface specification
5. [Implementation Notes](implementation-notes.md) - Implementation language choice and technical details
6. [Migration and Export](migration.md) - Migration tools and export formats
7. [Development Milestones](milestones.md) - Project milestones and completion criteria
8. [Development Guide](DEVELOPMENT.md) - Development environment setup and workflow
9. [Contributing](CONTRIBUTING.md) - Contribution guidelines and process
