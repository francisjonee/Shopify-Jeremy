# SCA Architect–Implementer Execution Workflow

This document defines the mandatory delivery loop for Jeremy's Second Chance Authenticators platform.

## Authority

- **Jeremy / Business Owner** provides business goals, requirements, priorities, and production approvals.
- **ChatGPT / Architect + Auditor** converts Jeremy's goals and brainstorming into architecture, acceptance criteria, ADRs, roadmap changes, task-queue ordering, exactly one implementation task in `NEXT_TASK.md`, and owns the GitHub PR audit/merge gate.
- **Claude / Implementer** executes only the current approved task. Claude does not choose the roadmap, approve its own work, merge its own work, or continue into the next task without a new `NEXT_TASK.md` written after architecture audit.
- **GitHub** is the canonical source of truth for architecture decisions, task state, implementation findings, evidence, and audit history.

## Delivery Control Files

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
6. Claude continuously commits implementation progress in logical checkpoints.
7. Claude records discoveries, deviations, risks, test evidence, commands, versions, operational notes, and recommendations in a committed task report.
8. Claude pushes the completed task branch and stops when the task is complete or blocked.
9. Claude returns evidence: branch name, commit SHA(s), changed files, test/build/runtime results, task-report path, findings, and blockers. Claude does **not** need to create or merge the PR unless a specific `NEXT_TASK.md` explicitly says otherwise.
10. No additional feature work may begin while the completed task is awaiting architecture audit.
11. ChatGPT verifies the pushed branch, creates the PR when needed, audits implementation and committed evidence against the task and architecture, and records the audit result.
12. If accepted, ChatGPT merges the audited PR, verifies any required post-merge deployment, records completion, updates `TASK_QUEUE.md`, updates the roadmap if needed, and replaces `NEXT_TASK.md` with exactly one next approved task.
13. If rejected, ChatGPT increments `RETRY_GENERATION` for the **same TASK_ID** and writes a narrow remediation task. Claude fixes only the rejected scope and returns new committed evidence.

## PR Ownership and Merge Gate

- Claude's normal responsibility ends at: implement → test → commit → push branch → commit task report → stop.
- ChatGPT owns: branch verification → PR creation when needed → audit → approve/reject → merge → governance updates.
- Claude must never merge a task PR unless a current `NEXT_TASK.md` explicitly delegates that action.
- A pushed branch is sufficient for handoff; lack of GitHub API credentials on the VPS is not a blocker to task implementation.
- The exact head SHA audited by ChatGPT must be the head SHA merged. If the branch changes after audit, ChatGPT must re-audit before merge.

## Governed Development Preview

While the temporary SCA Development Preview remains in service:

`Claude implements -> pushes branch -> ChatGPT audits/merges -> accepted main is deployed to the same preview.`

Rules:
- never deploy arbitrary unmerged branches to the stakeholder preview;
- the preview must track accepted `main` only;
- after a merge that materially changes the application, the post-merge deployment/verification is part of the acceptance closeout;
- permanent QR/public identity URLs must never use the temporary preview IP.

## Mandatory Commit Discipline

Claude must treat Git as the durable engineering memory of the project.

For every implementation task:
- make logical commits as meaningful checkpoints are completed;
- do not leave important findings only in chat/terminal output;
- commit documentation whenever deployment, configuration, behavior, architecture assumptions, or operational procedures are discovered;
- preserve evidence needed for future developers to understand why a decision was made;
- never commit secrets, real passwords, tokens, private keys, or sensitive `.env` values.

### Required task report

Each task must create or update:

`docs/task-reports/<TASK_ID>.md`

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

If the task is blocked before application code can be changed, Claude must still commit a findings report when repository access allows it.

## Findings vs Authority

Claude may recommend future work, but findings do not authorize scope expansion. ChatGPT decides whether findings modify the roadmap, queue, ADRs, or next task.

## Claude Stop Rule

After returning completion evidence, Claude must stop. Claude may resume only when `NEXT_TASK.md` contains a new or revised `STATUS: READY` task written after architecture audit. Claude must never start a `QUEUED` task simply because it appears next in `TASK_QUEUE.md`.

## Task Ownership

Only ChatGPT acting as Architect + Auditor should define or replace the implementation task in `NEXT_TASK.md`.

Claude must not:
- invent or self-promote the next task;
- reorder `TASK_QUEUE.md` unless explicitly authorized;
- expand scope because related work appears useful;
- change architecture decisions without an approved ADR;
- self-approve completion;
- merge its own task PR;
- deploy to production unless explicitly authorized;
- modify Shopify scopes, permanent QR rules, ownership semantics, or system-of-record boundaries unless explicitly authorized.

## Task Format

Every `NEXT_TASK.md` should contain at minimum:
- `STATUS`
- `TASK_ID`
- `RETRY_GENERATION` when applicable
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

`RETRY_GENERATION` is used only when ChatGPT rejects or remediates the same task ID. Brand-new tasks start without retry generation unless needed later.

## Audit Outcomes

### PASS
The implementation satisfies the task and architecture. Required evidence and task report are committed. ChatGPT merges the audited branch/PR, closes any post-merge deployment gate, updates queue state, and issues the next task.

### REJECT / REMEDIATION REQUIRED
The implementation fails one or more acceptance criteria, violates a prohibited change, lacks sufficient evidence, omits the task report, or conflicts with architecture. ChatGPT issues a narrow remediation for the same task ID.

### BLOCKED
A required credential, environment, source artifact, business decision, infrastructure dependency, or external access is unavailable. Claude documents the blocker and stops. ChatGPT decides whether to change architecture, request the missing dependency, reorder the queue, or issue another task.

## Principle

Jeremy decides what the business needs. ChatGPT controls architecture, sequencing, PR audit, and merge. Claude builds only the current approved unit and uses Git commits plus task reports as durable engineering memory. The roadmap defines where SCA is going, the task queue defines what is planned, and `NEXT_TASK.md` defines what is allowed now.
