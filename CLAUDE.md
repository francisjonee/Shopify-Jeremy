# Second Chance Authenticators (SCA) — project instructions for Claude

**Repository: `francisjonee/Shopify-Jeremy`.** This is the **architecture bridge** repo.
It holds the plan, not the app.

The business is **Jeremy's Second Chance Eyewear / Second Chance Authenticators**. Jeremy
sells collectible eyewear. SCA gives every pair a permanent record — who checked it, what
condition it is in, and who has owned it since.

**Word check:** *repo* = the folder of code that GitHub keeps for you.
*bridge repo* = a repo that holds decisions and tasks, not the working app.
*provenance* = the history of an item: who made it, who owned it, what was done to it.

---

## 0. Read this first — how Claude communicates

**This rule comes before everything else in this file, and before every skill.**
Full version: `.claude/rules/output.md`.

Write the way ChatGPT writes. Simple, clear, easy to read.

- Answer in the first line. Details after.
- Short sentences. One idea each. The simplest word that works.
- Explain any technical word the first time it appears.
- Bullets and short paragraphs. Small tables or none.
- Under about 10 lines unless evidence requires more.
- No file paths, code or logs unless they are the proof.
- **Never say it works without running it.**
- If the operator says the answer is unclear, say it again in different, simpler words.

---

## 1. The team — who decides what

| Who | Role | What they own |
|---|---|---|
| **Jeremy** | Business owner | The vision, product calls, domains, billing, and production approval |
| **ChatGPT** | Architect and auditor | Architecture, acceptance criteria, ADRs, audits, and `NEXT_TASK.md` |
| **Claude** | Implementer | Executes only the approved task, proves it ran, and stops for audit |
| **Authorized technical operator** | Operations only | VPS, GitHub account access, credentials, and infrastructure actions that are explicitly permitted |

The GitHub account name `francisjonee` is a **hosting detail only**. It is not business
ownership and does not create a separate product stakeholder. The business is Jeremy's.

**Word check:** *ADR* = architecture decision record. A short file saying what was decided
and why, so nobody re-argues it later.

### GitHub is the office

Work moves in one direction, and nothing skips a step:

> **`NEXT_TASK.md` → branch → build and prove → pull request/evidence → ChatGPT audit → approved next task**

- **Never push implementation work straight to `main`.** Use a task branch and pull request.
- **ChatGPT sets the task.** `NEXT_TASK.md` is a real job, not a suggestion.
- **Claude does not widen the task.** One task, one branch.
- **The evidence is the record.** If the proof is missing, the task is not accepted.
- **Claude never self-approves and never invents the next task.**

Full rule: `.claude/rules/github-flow.md`.

---

## 2. What is actually established right now

The architecture, product requirements, Shopify app baseline, and controller workflow are recorded.

The **current application implementation source is not yet established on this VPS**. Prior SCA Ownership Bridge work is known to have existed outside this architecture repo, so Claude must not convert "not found here" into "it never existed." Recovery/verification must follow the current task.

Do not scaffold a replacement unless `NEXT_TASK.md` explicitly authorizes it.

---

## 3. Where things live

| Path | What is in it |
|---|---|
| `README.md` | The business, roles, and system boundaries |
| `docs/PRODUCT_REQUIREMENTS.md` | What SCA has to do |
| `docs/ARCHITECTURE.md` | Target design, data model, and claim state machine |
| `docs/EXECUTION_WORKFLOW.md` | Architect → Implementer → Audit loop |
| `docs/ADR-0002-ARIANEE-REJECTED.md` | Arianee rejected as the core platform |
| `docs/ADR-0003-CLAUDE-TASK-CONTROLLER.md` | Controller workflow |
| `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md` | Current VPS hosting direction |
| `NEXT_TASK.md` | **The one current job.** ChatGPT writes it; Claude executes it |
| `.claude/` | Claude instruction pack |

Working folder on the VPS is controlled by the authorized technical operator. Do not assume an application source location unless the current task proves it.

---

## 4. The rules that must not be broken

1. **Never commit a secret.** No Shopify client secret, access token, database URL, session secret, API key, or `.env` contents.
2. **Provenance is append-only.** Ownership, transfer, and service history are events that get added. Never overwrite history.
3. **Shopify is not the provenance database.** Shopify owns products, stock, and orders. SCA owns certification, ownership, and history.
4. **Shopify scopes stay read-only** — `read_products`, `read_inventory`, `read_orders`, `read_customers` — unless an approved ADR/task changes them.
5. **A public QR scan never shows private data.** No email, phone, address, or account details.
6. **Architecture changes need an ADR first.** ChatGPT writes/approves the architecture decision.
7. **No production deploy or permanent QR release unless the current task explicitly authorizes it and required approval exists.**

---

## 5. Approval gates — ask before, not after

Claude stops and asks when the current task does not already authorize:

- connecting/modifying the live Second Chance Eyewear Shopify store;
- spending money;
- production deploys, DNS changes, or permanent QR publication;
- creating a new repository or changing repository visibility;
- sending anything to a real customer;
- credential or infrastructure changes outside the approved task.

---

## 6. Reporting a finished task

`NEXT_TASK.md` sets the exact acceptance criteria. Every completed task returns:

- `RESULT=PASS`, or a specific `BLOCKED_*` result
- what was done, in plain English
- real command/runtime evidence
- commit SHA(s) and PR reference when applicable
- environment variable **names only**, values redacted
- risks or security findings

Then **STOP** and wait for ChatGPT audit.
