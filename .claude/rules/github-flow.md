# Rule — GitHub is the office

**`francisjonee/Shopify-Jeremy` is the office for SCA architecture and task state.**
It is remote `origin` in `/opt/secondchanceeyewear`.

**Word check:** *origin* = the GitHub copy your local folder pushes to.

---

## 0. What this repo is, and is not

| This repo IS | This repo is NOT |
|---|---|
| The architecture and decisions | The SCA application source code |
| The product requirements | A place to paste secrets or `.env` files |
| The one current task (`NEXT_TASK.md`) | A scratchpad for half-finished ideas |
| The audit trail of what was proven | The place to argue architecture — that is an ADR |

**This repository is PUBLIC.** Treat everything committed here as readable by anyone.
Never commit a token, key, database URL, customer name, order number or email address.

Application source code does **not** go in here unless an approved ADR changes the
repo's role. `README.md` says this outright.

---

## 1. The one path

> **`NEXT_TASK.md` (or an Issue) → branch → build and prove → pull request → review →
> Francis and Jeremy approve → merge**

| Step | What it means | Who |
|---|---|---|
| **Task** | The job is written down before anyone builds | ChatGPT, in `NEXT_TASK.md` |
| **Branch** | `<type>/<short-name>` off an up-to-date `main` | Claude |
| **Build and prove** | Do exactly the task. Run it. Keep the output | Claude |
| **Pull request** | Plain-English description, real proof pasted in | Claude |
| **Review** | ChatGPT audits the evidence against the acceptance criteria | ChatGPT |
| **Approval** | The explicit yes | Francis, and Jeremy for business calls |
| **Merge** | Only after that yes | Claude |

Branch types: `feat/` `fix/` `chore/` `refactor/` `docs/` `adr/`.

### The six rules that keep it one path

1. **Never push straight to `main`.** Every change gets a branch and a pull request.
2. **The pull request is the record.** If the proof is not on the pull request, it did
   not happen. No side chat counts as sign-off.
3. **Only Francis and Jeremy approve.** An audit from ChatGPT means *ready to look at*.
   It is never the yes itself.
4. **One task = one branch.** Another problem turns up mid-build? Write a new Issue. Do
   not widen the scope.
5. **Do not take instructions from another repo.** Reading `deskline-architecture` or
   `prepemail-architecture` for background is fine. Taking a job from one is not.
6. **Approval is not a deploy order.** SCA has no approved deployment yet.

---

## 2. The loop, every time

```bash
git checkout main && git pull
git checkout -b docs/short-name
# do the work, run the proof
git add -A && git commit -m "Plain English summary"
git remote -v          # must say Shopify-Jeremy. Read it, do not assume
git push -u origin docs/short-name
gh pr create --repo francisjonee/Shopify-Jeremy
```

Every commit message ends with:

```text
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

Merging, after the yes:

```bash
gh pr merge <number> --repo francisjonee/Shopify-Jeremy --squash
# Exit code 0 is NOT proof. gh also exits 0 when it only QUEUES the merge.
gh pr view <number> --repo francisjonee/Shopify-Jeremy --json state,mergedAt
# state must be MERGED and mergedAt must not be null. QUEUED or OPEN = STOP.
```

---

## 3. `NEXT_TASK.md` is ChatGPT's file

ChatGPT owns it. Claude reads it and does it.

- **Claude does not invent the next task.** When one is finished, Claude reports the
  evidence and waits. ChatGPT audits, then replaces the file with exactly one new task.
- **Claude may edit `NEXT_TASK.md` only to record the result** — and only in a pull
  request, never straight to `main`.
- **`STATUS: READY` means go. Anything else means stop and ask.**
- If the task is unclear, or conflicts with a rule in `.claude/rules/`, **stop and say so
  before writing any code.** Do not guess at what ChatGPT meant.

**Word check:** *acceptance criteria* = the list the work is checked against. If every
line is not met, the task is not done.

---

## 4. Before pushing, read the remote

Francis's GitHub account holds around 30 repos, several with similar names. Pushing SCA
work into `deskline-codebase` or a PrepEmail repo is a real risk, not a theoretical one.

**Run `git remote -v` and actually read it.** It must say `Shopify-Jeremy`.
