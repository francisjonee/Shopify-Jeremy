# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized.

`SCA-COLLECTOR-CERTIFICATION-HISTORY-048` is **DONE** (`--no-ff` merged + deployed to production `main` at
`96cc584556c78b009ccb8e88afe228f08891e7ba`; base/prior-deployed `bb52a9dae425a97e601f4e0ea88f063b5994401d`,
feature `52e01aa7a0f71261aef8e3cf9673fb975468bfbb`). Read-only collector-facing certification history on the
My Collection item detail (current / superseded+successor / revoked → neutral "This item currently has no
active certification." notice), folded from `sca_certifications` + `sca_certification_events` via
`ProjectionService`; owner-authorized; numbers/dates/status only. **No schema/migration** (deploy migrate →
"Nothing to migrate", migrations count unchanged at 118); no route/ACL change; no domain mutation. SCA-038
Option A public passport, SCA-041 passport access, SCA-042 document classification all verified unchanged.
Deploy gate: focused `ItemCertificationHistoryTest` 11/51; full `tests/Feature/Sca` 586/3150. Production
before/after IDENTICAL (counts + certifications / cert_events / current-state-projection / media-checksum
fingerprints all MATCH). Pilot restored to normal posture (deployed main clean, `--no-dev`, caches cleared,
kr-app healthy on the pilot bind, MariaDB private, DOCKER-USER IP-lock unchanged).

The read-only `SCA-049` planning/architecture audit (Collector Ownership & Transfer History) is also **DONE**
(planning only — no code/branch/migration/mutation; full report at
`docs/SCA-049-COLLECTOR-OWNERSHIP-TRANSFER-HISTORY.md`). It recommends **one** candidate: a read-only
"Ownership history" section on the existing My Collection item detail — an owner-authorized, neutral, dated
timeline built from `sca_ownership_events` + transfer ledgers via `ProjectionService`, withholding all
other-collector identity, staff refs, correction reasons, tokens and internal ids; no schema, no route.

**No queued item has been promoted.** Per the authority rule, ChatGPT may promote exactly one queued item
from `TASK_QUEUE.md` into this file after auditing these reports. Until then there is no authorization to start
any task. **`SCA-050` must not start.**

*`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting a Jeremy-provided permanent HTTPS domain + access.*
