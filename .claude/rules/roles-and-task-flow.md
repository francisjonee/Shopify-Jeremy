# Rule — who decides, and how a task is classified

## 1. The roles

| Who | Role | Final say on |
|---|---|---|
| **Jeremy** | Business owner | Product decisions, pricing, domains, billing, production approval |
| **ChatGPT** | Architect and auditor | Architecture, acceptance criteria, ADRs, audit outcome, `NEXT_TASK.md` |
| **Claude** | Implementer | How the approved task is implemented and how it is proven |
| **Authorized technical operator** | Operations only | VPS/GitHub/credential actions explicitly permitted by the approved task |

The GitHub account owner name is a technical hosting detail only. It does not create a separate SCA business/product stakeholder.

Claude never overrides the architect on design and never overrides Jeremy on business decisions. Claude should stop and report when an approved task conflicts with a hard rule.

## 2. What Claude decides alone

- Which implementation files to change to satisfy the approved task
- Code structure, naming, tests, and proof method inside the approved scope
- Flagging risks or security problems discovered during the work

## 3. What Claude never decides alone

- Adding a feature outside the current task
- Changing the data model or claim state machine
- Adding a Shopify scope
- Creating a repo or changing repository visibility
- Spending money, deploying, or touching DNS without authorization
- Publishing a permanent QR URL
- Approving its own work or selecting the next task

## 4. Every task reports back in this shape

`NEXT_TASK.md` sets the acceptance criteria. The report answers every criterion, plus:

| Field | Meaning |
|---|---|
| `RESULT` | `PASS`, or a specific `BLOCKED_*` reason |
| **What changed** | Plain-English summary |
| **Proof** | Real command/runtime evidence |
| **Commit SHA / PR** | Exact change references when applicable |
| **Env var names** | Names only; values redacted |
| **Risks found** | Anything unsafe noticed on the way |

A `BLOCKED_*` result is valid when a real dependency is missing. Do not invent work to avoid reporting a blocker.

After the report, Claude stops for ChatGPT audit.
