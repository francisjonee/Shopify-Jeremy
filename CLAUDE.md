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

The project is now authorized as a **greenfield SCA build from scratch**. Do not wait for or attempt to recover the inaccessible old Ownership Bridge unless a future task explicitly changes that decision.

The current VPS is a **temporary construction/staging environment**, not the permanent SCA server. Build so the application can later move to permanent infrastructure without rebuilding the product, regenerating permanent QR codes, or rewriting provenance history.

The approved implementation direction is recorded in:

- `docs/ADR-0005-GREENFIELD-PORTABLE-SCA-BUILD.md`
- `docs/INFRASTRUCTURE_BLUEPRINT.md`
- `docs/ROADMAP.md`

Core implementation rules now established:

- application source goes in a separate **private implementation repository**;
- initial stack is TypeScript + Node.js + Next.js + PostgreSQL + Prisma + Docker;
- use a modular monolith first;
- Shopify remains the commerce source;
- SCA owns unique physical eyewear identity, Certification ID, QR, claims, ownership, and provenance;
- canonical QR generation is in SCA, not Shopify;
- the printed QR travels with the physical eyewear;
- Shopify purchase creates claim eligibility;
- the customer registers ownership only after scanning the QR, signing into SCA, and completing the claim;
- no permanent QR may depend on the temporary VPS IP/hostname.

---

## 3. Where things live

| Path | What is in it |
|---|---|
| `README.md` | The business, roles, and system boundaries |
| `docs/PRODUCT_REQUIREMENTS.md` | What SCA has to do |
| `docs/ARCHITECTURE.md` | Target design, data model, QR/claim model, and state machine |
| `docs/INFRASTRUCTURE_BLUEPRINT.md` | Temporary-to-permanent hosting and portability blueprint |
| `docs/ROADMAP.md` | Ordered implementation phases |
| `docs/EXECUTION_WORKFLOW.md` | Architect → Implementer → Audit loop |
| `docs/ADR-0002-ARIANEE-REJECTED.md` | Arianee rejected as the core platform |
| `docs/ADR-0003-CLAUDE-TASK-CONTROLLER.md` | Controller workflow; automatic live dispatch remains deferred |
| `docs/ADR-0004-VPS-HOSTING-SUPERSEDES-ADR-0001.md` | VPS hosting allowed |
| `docs/ADR-0005-GREENFIELD-PORTABLE-SCA-BUILD.md` | Current greenfield portable-build decision |
| `NEXT_TASK.md` | **The one current job.** ChatGPT writes it; Claude executes it |
| `.claude/` | Claude instruction pack |

The implementation repository and working directory are established by the approved current task. Do not put application source into this public architecture repository.

---

## 4. The rules that must not be broken

1. **Never commit a secret.** No Shopify client secret, access token, database URL, session secret, API key, or `.env` contents.
2. **Provenance is append-only.** Ownership, transfer, and service history are events that get added. Never overwrite history.
3. **Shopify is not the provenance database.** Shopify owns products, stock, and orders. SCA owns certification, physical-item identity, QR, ownership, and history.
4. **Shopify scopes stay read-only** — `read_products`, `read_inventory`, `read_orders`, `read_customers` — unless an approved ADR/task changes them.
5. **A public QR scan never shows private data.** No email, phone, address, or account details.
6. **Permanent QR identity belongs to SCA.** Never hard-code a temporary server IP/hostname or staging route into a lifetime QR.
7. **Architecture changes need an ADR first.** ChatGPT writes/approves the architecture decision.
8. **No production deploy or permanent QR release unless the current task explicitly authorizes it and required approval exists.**
9. **The temporary VPS is disposable.** Irreplaceable source, database, media, or secrets must not exist only on that machine.

---

## 5. Approval gates — ask before, not after

Claude stops and asks when the current task does not already authorize:

- connecting/modifying the live Second Chance Eyewear Shopify store;
- spending money;
- production deploys, DNS changes, or permanent QR publication;
- creating a new repository or changing repository visibility;
- sending anything to a real customer;
- credential or infrastructure changes outside the approved task.

If the current `NEXT_TASK.md` explicitly authorizes one of these actions, that task is the approval for that bounded action only.

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
