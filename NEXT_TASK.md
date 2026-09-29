# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized.

`SCA-COLLECTOR-OWNERSHIP-TRANSFER-HISTORY-049` is **DONE** (`--no-ff` merged + deployed to production `main` at
`ec2b2efcaab6f9f8d4c8c236645285dd8158ec37`; base/prior-deployed `96cc584556c78b009ccb8e88afe228f08891e7ba`,
feature `e3abf76695d3539ab59a5afe24a0bcb020b02a5a`). Read-only owner-facing ownership/transfer history on the
My Collection item detail (neutral non-identifying dated timeline from `sca_ownership_events` via
`ProjectionService`; transfer pairs folded by `source_transfer_event_id`; entries exactly `{label,date,mine}`).
**No schema/migration** (deploy migrate → "Nothing to migrate", migrations count unchanged at 118); no route/
ACL change; no domain mutation. SCA-048 certification history present alongside; SCA-041 passport access,
SCA-042 document classification, SCA-038 Option A public passport all verified intact. Deploy gate: focused
`ItemOwnershipHistoryTest` 11/50; full `tests/Feature/Sca` 597/3201. Production before/after IDENTICAL (counts +
ownership_events / current-state-projection / certifications / media-checksum fingerprints all MATCH). Pilot
restored to normal posture (deployed main clean, `--no-dev`, caches cleared, kr-app healthy on the pilot bind,
MariaDB private, DOCKER-USER IP-lock unchanged).

The read-only `SCA-050` Product Experience & Operations audit is also **DONE** (planning only — no code/branch/
migration/mutation; full report at `docs/SCA-050-PRODUCT-EXPERIENCE-OPERATIONS-AUDIT.md`). It recommends **one**
candidate: **staff registry operational filtering & item lookup** — add lifecycle/registry-status/owner/date
filters + certification-number search to the existing paginated eyewear index (read-only, no schema, one
controller+view), removing the most frequent raw-DB staff operation and the physical-item→admin dead-end.

**No queued item has been promoted.** Per the authority rule, ChatGPT may promote exactly one queued item from
`TASK_QUEUE.md` into this file after auditing these reports. Until then there is no authorization to start any
task. **`SCA-051` must not start.**

*`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting a Jeremy-provided permanent HTTPS domain + access.*
