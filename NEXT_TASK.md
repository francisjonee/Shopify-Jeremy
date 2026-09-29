# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized.

`SCA-STAFF-REGISTRY-OPERATIONS-051` is **DONE** (`--no-ff` merged + deployed to production `main` at
`c8e3f5943e9b8e6ecd22accdce9db7719bab97ba`; base/prior-deployed `ec2b2efcaab6f9f8d4c8c236645285dd8158ec37`,
feature `e168cffd62e90e54204b48e53e2a8d5badbf6b3c` = reviewed `a4240fd` + pre-merge grammar fix). Read-only
operational filtering/search/sort + physical-item QR lookup on the staff eyewear registry index. **No schema/
migration** (deploy migrate → "Nothing to migrate", migrations unchanged at 118); no domain mutation; one new
POST lookup route under the existing `sca.eyewear` ACL. Deploy gate: focused `StaffRegistryOperationsTest`
17/123; full `tests/Feature/Sca` 614/3327. Non-mutating production verification confirmed: index GET + lookup
POST gated `sca.eyewear`, lookup is POST-only (GET → 404), unauth fails closed, certified `/p/{token}` → 200 +
bogus → constant 404 (SCA-038 Option A intact), QR token never exposed. Production before/after IDENTICAL
(counts + 7 fingerprints across item-metadata/certs/cert_events/ownership/projection/media-checksum/qr-identity
all MATCH; SCA-041/042/044–049 unchanged). Pilot restored to normal posture (deployed main clean, `--no-dev`,
kr-app healthy on the pilot bind, MariaDB private, DOCKER-USER IP-lock unchanged).

**No queued item has been promoted.** Per the authority rule, ChatGPT may promote exactly one queued item from
`TASK_QUEUE.md` into this file after auditing SCA-051. Until then there is no authorization to start any task.
**`SCA-052` must not start.**

*Open correctness defect (do NOT fix without a governed task): `DEFECT-001` — collector green authenticity badge
on revoked/uncertified items (`docs/PENDING-DEFECTS.md`). `SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED
awaiting a Jeremy-provided permanent HTTPS domain + access.*
