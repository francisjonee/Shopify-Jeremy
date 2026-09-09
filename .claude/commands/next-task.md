---
description: Read NEXT_TASK.md and restate the current job in plain English
---

Read `NEXT_TASK.md` and every file it lists under **Required Inputs**.

Then answer, in under 10 lines, following `.claude/rules/output.md`:

1. **The task ID and one-sentence goal**, in plain English.
2. **Is it ready?** `STATUS` must say `READY`. Anything else — stop and say so.
3. **What Claude will actually do** — the concrete steps, not a restatement.
4. **What is blocking it**, if anything. Missing access, missing code, missing decision.
5. **What is needed from Francis or Jeremy before starting** — approvals, credentials,
   a store name. Say it now, not halfway through.

Do not start building. This command reads and reports only.

Check the task against `.claude/rules/security-and-data.md`. If it would break a rule
there, say which rule and stop.
