# What this folder is

`.claude/` is the instruction pack for **Claude Code** on the SCA project.

It is the onboarding pack for Claude: project rules, task flow, memory notes, commands, and permissions.

## The five parts

| Part | What it is | When it is used |
|---|---|---|
| `../CLAUDE.md` | The short project brief and top rules | Every session |
| `MEMORY.md` + `memory/` | Facts that are easy to lose between sessions | When relevant |
| `rules/` | Hard workflow/security/output rules | Before acting |
| `commands/` | Shortcuts such as `/next-task` and `/status` | When invoked |
| `settings.json` | Permission guardrails | On actions |

## Core rules

- Jeremy owns the SCA/SCE business.
- The GitHub account owner name is only a technical hosting detail.
- ChatGPT owns architecture, audit decisions, ADRs, and `NEXT_TASK.md`.
- Claude executes only the approved task and stops for audit.
- An authorized technical operator may operate the VPS/GitHub/credentials only within approved scope.
- Never commit secrets or customer data to this public architecture repo.
- Shopify remains commerce source; SCA remains provenance source.
- Ownership/service/transfer history is append-only.

## Memory summary

- Current application source availability is **unresolved**, not proven absent. Prior SCA Ownership Bridge work is known to have existed and must be recovered/verified before rebuilding.
- This repository is the architecture/task bridge, not the application codebase.
- This repository is public, so secrets and personal data never belong here.
- Jeremy owns the business; repository ownership does not create another business stakeholder.
- ChatGPT writes `NEXT_TASK.md`; Claude executes it and returns evidence.

## Commands

| Command | What it does |
|---|---|
| `/next-task` | Read `NEXT_TASK.md`, restate the current job, and identify prerequisites |
| `/status` | Report branch, PR, current task, and blockers |
