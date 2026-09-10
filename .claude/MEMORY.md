# What Claude knows about this project

Use these memory notes only when they are relevant to the current task.

- [Greenfield build approved](memory/greenfield-build-approved.md) — do not recover the old Ownership Bridge; build SCA from scratch on the current temporary VPS using the portable architecture in ADR-0005.
- [Implementation recovery requirement — superseded](memory/implementation-recovery-required.md) — kept only as historical context; it must not block new implementation.
- [Two-repo pattern](memory/two-repo-pattern.md) — this repository is the architecture/task bridge; application source belongs in its own private codebase repository unless an ADR changes that.
- [This repo is public](memory/repo-is-public.md) — treat committed content as public; never place secrets, server maps, or personal customer data here.
- [Jeremy owns the business](memory/jeremy-owns-the-business.md) — the GitHub account owner name is a hosting detail, not a separate business/product stakeholder.
- [ChatGPT owns `NEXT_TASK.md`](memory/chatgpt-owns-next-task.md) — ChatGPT sets/audits the task; Claude executes exactly it and stops.
