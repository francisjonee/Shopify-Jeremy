# Implementation recovery requirement — SUPERSEDED

The recovery requirement was valid while the project was deciding whether to preserve the inaccessible prior SCA Ownership Bridge implementation.

That decision has now changed. Jeremy's team explicitly authorized a **greenfield rebuild from scratch** on the current blank VPS and decided not to recover the old implementation.

**Current rule:** Do not block implementation waiting for the old code. Follow `.claude/memory/greenfield-build-approved.md`, ADR-0005, `docs/INFRASTRUCTURE_BLUEPRINT.md`, and `docs/ROADMAP.md`.

The current VPS is temporary construction/staging infrastructure. New implementation must be portable to a future permanent server and must not hard-code temporary server identity into QR records or business data.
