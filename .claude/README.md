# What this folder is

`.claude/` is the instruction pack for **Claude Code** on the SCA project.

It is read automatically every time a session starts in `/opt/secondchanceeyewear`. You
never have to load it or mention it.

Think of it as the onboarding pack you would hand a new hire — written for the AI, so
nobody has to explain the same things every session.

---

## The five parts

| Part | What it is | When it is used |
|---|---|---|
| `../CLAUDE.md` | The short brief — the team, the repo, the top rules | Every session |
| `MEMORY.md` + `memory/` | Facts the repo does not say out loud | Pulled in when they matter |
| `rules/` | The hard rules. Not negotiable | `output.md` on **every reply**; the rest before anything risky |
| `commands/` | Shortcuts you type as `/name` | When you type them |
| `settings.json` | Permissions — what runs freely, what asks first, what is banned | On every action |

---

## Rules — five files

| File | What it covers |
|---|---|
| `output.md` | **How every answer must look.** Answer first, plain English, under about 10 lines, proof before "it works", worst news at the top. **This one beats every skill** |
| `github-flow.md` | **GitHub is the office.** Task → branch → pull request → approval → merge. Never push to `main`. Why this repo holds no app code |
| `roles-and-task-flow.md` | **Who decides.** Jeremy the business, Francis the account and spend, ChatGPT the architecture, Claude the build. What a finished task must report |
| `security-and-data.md` | **The expensive mistakes.** The repo is public, provenance is append-only, Shopify stays read-only, QR scans never leak private data |
| `writing-and-code-style.md` | Match the docs, match the codebase, plain commit messages |

## Memory — five facts

`MEMORY.md` is the index. The short version:

- There is no SCA app yet, anywhere — and `SCA-BOOT-001` says do not build one to fill it
- Every project here splits into an architecture repo and a codebase repo
- This repo is **public**, unlike all the others
- Jeremy owns the business; the GitHub account name means nothing
- ChatGPT writes `NEXT_TASK.md`; Claude does exactly it and reports evidence

## Commands — two

| Command | What it does |
|---|---|
| `/next-task` | Read `NEXT_TASK.md`, restate the job in plain English, and say what is needed before starting |
| `/status` | Where the project stands: branch, open pull requests, current task, what is blocked |
