# ChatGPT is the architect and owns `NEXT_TASK.md`

In this project ChatGPT writes the architecture, the acceptance criteria, the ADRs, and
the single current task. Claude implements it and returns evidence. ChatGPT then audits
the evidence and writes the next task.

**Why it matters:** This is the opposite of the PrepEmail project, where the
`NEXT_TASK.md` lane was revoked and only GitHub Issues assign work. Copying that
revocation here would break this project's governance.

**How to apply:** Treat `NEXT_TASK.md` as a real job. Do exactly it, no more. Do not
write the next one. If it conflicts with a rule in `.claude/rules/`, stop and say so
before writing code.
