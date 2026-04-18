# Agent Task: Implement Event-Driven Wrapper for CLI Coding Agents + Neovim Integration

## Objective

Build a **thin wrapper system** around an existing CLI coding agent (e.g. Aider or similar) that emits **structured JSON events (NDJSON)** describing its behavior in real time.

This wrapper will enable **Neovim integration** by providing a machine-readable event stream for:

* task lifecycle tracking
* file changes
* patch application
* logs/output

The system should remain **agent-agnostic**, lightweight, and extensible.

---

## High-Level Architecture

```
Neovim Plugin (consumer)
        ↑
 NDJSON Event Stream
        ↑
Agent Wrapper (you implement this)
        ↑
CLI Agent (Aider / Claude Code / etc.)
```

---

## Scope (v1 — Minimal Viable System)

### You are building:

1. A **wrapper CLI tool**
2. That executes an existing agent CLI
3. And emits **structured events to stdout (NDJSON)**

### You are NOT building:

* multi-agent orchestration
* UI
* full MCP system
* deep Neovim plugin (only assume it will consume events)

---

## Core Requirements

### 1. Event Stream Format

* Output must be **newline-delimited JSON (NDJSON)**
* Each line = one event
* Must be valid JSON
* Must flush immediately (real-time streaming)

---

### 2. Base Event Schema

Every event MUST follow this structure:

```json
{
  "id": "evt_<unique_id>",
  "type": "<domain.action>",
  "timestamp": "<ISO8601>",
  "agent": "<agent_name>",
  "task_id": "<task_id>",
  "worktree": "<worktree_name>",
  "data": {}
}
```

---

### 3. Required Event Types (v1)

Implement ONLY these:

#### Task Lifecycle

* `task.started`
* `task.completed`
* `task.failed`

#### File / Code

* `file.modified`
* `patch.applied`

#### Logging

* `log`

---

### 4. Event Definitions

#### task.started

```json
{
  "type": "task.started",
  "data": {
    "title": "<task description>"
  }
}
```

---

#### task.completed

```json
{
  "type": "task.completed",
  "data": {
    "status": "success"
  }
}
```

---

#### task.failed

```json
{
  "type": "task.failed",
  "data": {
    "error": "<error message>"
  }
}
```

---

#### file.modified

```json
{
  "type": "file.modified",
  "data": {
    "path": "<relative file path>"
  }
}
```

---

#### patch.applied

```json
{
  "type": "patch.applied",
  "data": {
    "files": ["file1", "file2"],
    "summary": "<short description>"
  }
}
```

---

#### log

```json
{
  "type": "log",
  "data": {
    "level": "info|warn|error",
    "message": "<text>"
  }
}
```

---

## Functional Behavior

### 1. Wrapper CLI Interface

Example usage:

```bash
agent-wrapper run \
  --agent aider \
  --task "implement authentication" \
  --worktree wt-auth \
  --task-id task-auth
```

---

### 2. Execution Flow

1. Emit `task.started`
2. Launch underlying CLI agent
3. Stream stdout/stderr
4. Detect file changes
5. Emit events accordingly
6. Emit `task.completed` or `task.failed`

---

### 3. File Change Detection (Important)

You MUST detect file modifications.

Acceptable approaches:

* Git diff polling:

  ```bash
  git diff --name-only
  ```
* File system watch
* Snapshot before/after

On detection:
→ emit `file.modified`

---

### 4. Patch Detection

When multiple file changes occur together:
→ emit `patch.applied`

This can be:

* heuristic-based (time window)
* triggered after agent step completes

---

### 5. Logging

All meaningful output from the agent should be captured and emitted as:

```json
{
  "type": "log",
  "data": {
    "level": "info",
    "message": "<line from stdout>"
  }
}
```

---

## Implementation Details

### Language

Use **Python** (preferred) or Node.js

---

### Process Handling

* Spawn agent using subprocess
* Stream stdout/stderr asynchronously
* Do NOT block

---

### ID Generation

Use:

* UUID or incrementing counter

---

### Timestamp

Use ISO 8601:

```
2026-04-18T18:21:00Z
```

---

### Output Rules

* Write ONLY JSON events to stdout
* No extra text
* No formatting
* Flush after every line

---

## Example Output (End-to-End)

```json
{"id":"evt_1","type":"task.started","timestamp":"...","agent":"aider","task_id":"task-auth","worktree":"wt-auth","data":{"title":"implement authentication"}}
{"id":"evt_2","type":"log","timestamp":"...","agent":"aider","task_id":"task-auth","worktree":"wt-auth","data":{"level":"info","message":"Editing auth.ts"}}
{"id":"evt_3","type":"file.modified","timestamp":"...","agent":"aider","task_id":"task-auth","worktree":"wt-auth","data":{"path":"auth.ts"}}
{"id":"evt_4","type":"patch.applied","timestamp":"...","agent":"aider","task_id":"task-auth","worktree":"wt-auth","data":{"files":["auth.ts"],"summary":"added login handler"}}
{"id":"evt_5","type":"task.completed","timestamp":"...","agent":"aider","task_id":"task-auth","worktree":"wt-auth","data":{"status":"success"}}
```

---

## Non-Goals (Do NOT implement)

* Multi-agent coordination
* Role system
* GUI
* Neovim plugin
* Persistent storage

---

## Stretch Goals (Optional)

* Structured parsing of agent output
* Git commit detection → `git.commit` event
* Exit codes → richer failure events

---

## Success Criteria

* Wrapper runs any CLI agent
* Emits valid NDJSON events
* Detects file changes
* Streams output in real time
* Can be consumed by Neovim without modification

---

## Final Notes

* Keep it simple
* Prioritize reliability over cleverness
* The goal is **observability**, not control (yet)

This system is the foundation for future:

* multi-agent orchestration
* Neovim-native workflows
* MCP-style integrations

---

