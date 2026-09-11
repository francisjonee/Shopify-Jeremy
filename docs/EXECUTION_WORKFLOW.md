# SCA Architect–Implementer Execution Workflow

This document defines the mandatory delivery loop for Jeremy's Second Chance Authenticators platform.

## Authority

- **Jeremy / Business Owner** provides business goals, requirements, priorities, and production approvals.
- **ChatGPT / Architect + Auditor** converts Jeremy's goals and brainstorming into architecture, acceptance criteria, ADRs, roadmap changes, task-queue ordering, and exactly one implementation task in `NEXT_TASK.md`.
- **Claude / Implementer** executes only the current approved task. Claude does not choose the roadmap, approve its own work, or continue into the next task without a new `NEXT_TASK.md` written after architecture audit.
- **GitHub** is the canonical source of truth for architecture decisions, task state, implementation findings, evidence, and audit history.

## Delivery Control Files

The project uses three different planning levels and they must not be confused:

1. **`docs/ROADMAP.md`** — phase-level destination and major product milestones.
2. **`TASK_QUEUE.md`** — ordered backlog of planned implementation tasks and dependencies. Queue items are not executable authorization.
3. **`NEXT_TASK.md`** — exactly one current executable task for Claude.

Only `NEXT_TASK.md` authorizes work.

## Mandatory Loop

1. Jeremy requirements / brainstorming are discussed.
2. ChatGPT decides the architecture and implementation boundary.
3. ChatGPT updates roadmap/queue when required and writes exactly one current task into `NEXT_TASK.md` with acceptance criteria and prohibited changes.
4. Claude reads the architecture documents, `TASK_QUEUE.md`, and `NEXT_TASK.md`.
5. Claude implements only that task in the implementation repository.
6. Claude continuously commits implementation progress in logical checkpoints rather than accumulating one large uncommitted change.
7. Claude records discoveries, deviations, risks, test evidence, commands, versions, operational notes, and recommendations in the implementation repository as a committed task report.
8. Claude stops when the task is complete or blocked.
9. Claude returns evidence: commit SHA(s), changed files, test/build/runtime results, task-report path, findings, PR URL, and any blockers required by the task.
10. No additional feature work may begin while the completed task is awaiting architecture audit.
11. ChatGPT audits both implementation and the committed findings/evidence against the task and architecture.
12. If accepted, ChatGPT records completion, updates `TASK_QUEUE.md`, updates the roadmap if implementation findings materially affect it, and replaces `NEXT_TASK.md` with exactly one next approved task.
13. If rejected, ChatGPT increments `RETRY_GENERATION` and writes a remediation task. Claude fixes only the rejected scope and returns new committed evidence.

## Mandatory Commit Discipline

Claude must treat Git as the durable engineering memory of the project.

For every implementation task:

- make logical commits as meaningful checkpoints are completed;
- do not leave important findings only in chat/terminal output;
- do not wait until the very end to create the first commit if meaningful work has already been completed;
- commit documentation whenever deployment, configuration, behavior, architecture assumptions, or operational procedures are discovered;
- preserve evidence needed for future developers to understand why a decision was made;
- never commit secrets, real passwords, tokens, private keys, or sensitive `.env` values.

### Required task report

Each task must create or update a committed report inside the private implementation repository under:

```text
docs/task-reports/<TASK_ID>.md
```

The report must contain at minimum:

- task ID and date;
- result: PASS / BLOCKED / remediation needed;
- exact versions/components used;
- implementation summary;
- files/components changed;
- commands/procedures that matter for reproducibility;
- tests, smoke tests, build/migration results;
- security findings;
- architecture findings or assumptions discovered;
- operational findings;
- known issues / technical debt;
- recommendations for later tasks;
- explicit scope confirmation;
- commit SHA(s) and PR reference when available.

If the task is blocked before application code can be changed, Claude must still commit a findings report when repository access allows it. If committing is impossible because the repository itself is inaccessible, the blocker report must explicitly say so.

## Findings vs Authority

Claude is expected to discover problems and recommend future work, but findings do not authorize scope expansion.

Claude may write recommendations such as:

- a security fix should be prioritized;
- a queue item should be split;
- an architecture assumption is wrong;
- an upstream limitation was discovered;
- a dependency should be upgraded or replaced.

Claude must **not** implement those recommendations unless they are part of the current `NEXT_TASK.md`.

ChatGPT decides whether findings modify the roadmap, queue, ADRs, or next task.

## Claude Stop Rule

After returning completion evidence, Claude must stop. A message such as "I can continue with..." is not authorization to continue.

Claude may resume only when `NEXT_TASK.md` contains a new or revised task with `STATUS: READY` written after architecture audit.

Claude must never start a `QUEUED` task simply because it appears next in `TASK_QUEUE.md`.

## Task Ownership

Only ChatGPT acting as Architect + Auditor should define or replace the implementation task in `NEXT_TASK.md` as part of this workflow.

Claude must not:

- invent or self-promote the next task;
- reorder `TASK_QUEUE.md` unless explicitly authorized by the current task;
- expand the current scope because related work appears useful;
- change architecture decisions without an approved ADR;
- self-approve completion;
- deploy to production unless the current task explicitly authorizes production deployment;
- modify Shopify scopes, permanent QR rules, ownership semantics, or system-of-record boundaries unless the current task explicitly authorizes that change.

## Task Format

Every `NEXT_TASK.md` should contain at minimum:

- `STATUS`
- `TASK_ID`
- `RETRY_GENERATION`
- title
- objective
- required inputs
- implementation work
- acceptance criteria
- prohibited changes
- required evidence
- required commit/task-report instructions
- completion rule
- last-completed summary

## Audit Outcomes

### PASS

The implementation satisfies the task and architecture. Required evidence and task report are committed. ChatGPT records the accepted result, updates queue state, and issues the next task.

### REJECT / REMEDIATION REQUIRED

The implementation does not satisfy one or more acceptance criteria, violates a prohibited change, lacks sufficient committed evidence, omits the required task report, or conflicts with architecture. ChatGPT issues a narrow remediation task. Claude must not proceed to unrelated work.

### BLOCKED

A required credential, environment, source artifact, business decision, infrastructure dependency, or external access is unavailable. Claude documents the blocker and findings, commits that evidence where possible, and stops. ChatGPT decides whether to change architecture, request the missing dependency, reorder the queue, or issue another task.

## Principle

Jeremy decides what the business needs. ChatGPT controls architecture, sequencing, and audit. Claude builds only the current approved unit and uses Git commits plus task reports as durable engineering memory. The roadmap defines where SCA is going, the task queue defines what is planned, and `NEXT_TASK.md` defines what is allowed now.
