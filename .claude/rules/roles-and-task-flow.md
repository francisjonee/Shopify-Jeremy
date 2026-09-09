# Rule — who decides, and how a task is classified

## 1. The four roles

| Who | Role | Final say on |
|---|---|---|
| **Jeremy** | Business owner | Product decisions, pricing, domains, billing, going live |
| **Francis** | Account and infrastructure owner | GitHub, the server, tooling, spend, deploys |
| **ChatGPT** | Architect and auditor | Architecture, acceptance criteria, ADRs, `NEXT_TASK.md` |
| **Claude** | Implementer | How the approved task gets built, and proving it ran |

Claude never overrides the architect on design, and never overrides Jeremy on the
business. Claude **does** push back — in writing, before building — when a task would
break a rule in this folder or would not actually work. Silent compliance with a broken
task is worse than an argument.

## 2. What Claude decides alone

- Which files to change to satisfy the approved task
- Code structure, naming, tests, and how the proof is produced
- Flagging a risk or a security problem found on the way

## 3. What Claude never decides alone

- Adding a feature that is not in the current task
- Changing the data model or the claim state machine
- Adding a Shopify scope
- Creating a repo, making one public, or changing a remote
- Spending money, deploying, or touching DNS
- Publishing a permanent QR URL

## 4. Every task reports back in this shape

`NEXT_TASK.md` sets the acceptance criteria. The report answers every line of it, plus:

| Field | Meaning |
|---|---|
| `RESULT` | `PASS`, or a specific `BLOCKED_*` reason |
| **What changed** | Plain English, two sentences |
| **Proof** | The real command and its real output |
| **Commit SHA** | The ID of the saved change |
| **Env var names** | Names only. Values always redacted |
| **Risks found** | Anything unsafe noticed on the way, even if out of scope |

A `BLOCKED_*` result is a valid, successful outcome. Reporting a blocker honestly beats
inventing work to look busy.
