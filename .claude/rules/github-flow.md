# Rule — GitHub is the office

**`francisjonee/Shopify-Jeremy` is the office for SCA architecture and task state.**
The repository owner name is a technical hosting detail only.

## 0. What this repo is, and is not

| This repo IS | This repo is NOT |
|---|---|
| Architecture and decisions | The SCA application source code |
| Product requirements | A place to paste secrets or `.env` files |
| The one current task (`NEXT_TASK.md`) | A scratchpad for half-finished ideas |
| The audit trail of what was proven | A substitute for runtime evidence |

**This repository is PUBLIC.** Treat everything committed here as readable by anyone.
Never commit a token, key, database URL, customer name, order number, email address, or other sensitive data.

Application source code does **not** go here unless an approved ADR changes the repo's role.

## 1. The one path

> **`NEXT_TASK.md` → task branch → implement and prove → PR/evidence → ChatGPT audit → approved next task**

| Step | What it means | Who |
|---|---|---|
| **Task** | The job is written before work begins | ChatGPT |
| **Branch** | Dedicated branch off current `main` | Claude/controller |
| **Build and prove** | Execute exactly the task and run the proof | Claude |
| **Pull request / evidence** | Record changes and required evidence | Claude |
| **Audit** | Check every acceptance criterion and prohibited change | ChatGPT |
| **Business/production approval** | Required when the task affects business or production | Jeremy / authorized approver |
| **Next task** | Only after audit | ChatGPT |

Branch types: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `adr/`.

### The rules that keep it one path

1. **Never push implementation work straight to `main`.** Use a branch and pull request.
2. **Missing proof means not accepted.** A merge does not turn an unproven task into PASS.
3. **ChatGPT audit controls task progression.** Claude does not self-approve or write the roadmap.
4. **One task = one branch.** New unrelated work becomes a later task.
5. **Do not take implementation instructions from unrelated repositories.**
6. **Approval is not automatically a deploy order.** Deployment must be explicitly authorized by the current task and required human approval.

## 2. `NEXT_TASK.md` is ChatGPT's task file

- Claude reads it and executes exactly the current `STATUS: READY` task.
- Claude does not invent the next task.
- After evidence is returned, Claude stops for audit.
- If evidence is rejected, ChatGPT increments `RETRY_GENERATION` and issues only the remediation scope.
- If the task conflicts with a hard rule, Claude reports the conflict before changing implementation.

**Word check:** *acceptance criteria* = the exact list used to decide whether the task passes.

## 3. Before pushing, verify the remote

Run `git remote -v` and verify the repository is the intended SCA repo before pushing. Similar repository names are not sufficient proof.
