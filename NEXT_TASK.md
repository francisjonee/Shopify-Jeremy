# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized.

`SCA-COLLECTOR-AUTHENTICITY-BADGE-052` is **DONE** (`--no-ff` merged + deployed to production `main` at
`0e2e151b2023186ce18347c514903dce217c1685`; base/prior-deployed `c8e3f5943e9b8e6ecd22accdce9db7719bab97ba`,
feature `efe7dd92c5af608294fd7517c30e261e57c4d8ca`). It **fixes DEFECT-001**: the collector My Collection
authenticity badge now shows the green ✓ "Authenticated & Certified" iff the item is currently certified;
non-certified states render neutral (no ✓), consistent with the SCA-048 notice; authentication is derived
independently from `sca_authentications` so revocation no longer erases historical authentication evidence.
**No schema/migration** (deploy migrate → "Nothing to migrate", migrations unchanged at 118); read-model +
presentation only; no domain mutation. Deploy gate: focused `ItemAuthenticityBadgeTest` 7/48; full
`tests/Feature/Sca` 621/3375. Production before/after IDENTICAL (counts + 7 fingerprints —
certs/cert_events/authentications/projection/media-checksum/qr-identity/ownership — all MATCH). Non-mutating
verification confirmed green ✓ only via `authenticity_certified`, owner-auth intact, certified `/p/{token}` →
200 + bogus → constant 404 (SCA-038 Option A), PassportPresenter + SCA-041/042/048/049/051 unchanged. Pilot
restored to normal posture (deployed main clean, `--no-dev`, kr-app healthy on the pilot bind, MariaDB private,
DOCKER-USER IP-lock unchanged).

**No queued item has been promoted.** Per the authority rule, ChatGPT may promote exactly one queued item from
`TASK_QUEUE.md` into this file after reviewing this deployment. Until then there is no authorization to start
any task. **`SCA-053` must not start.**

*No open correctness defects (DEFECT-001 is FIXED, see `docs/PENDING-DEFECTS.md`). `SCA-PRODUCTION-CUTOVER`
remains BLOCKED/DEFERRED awaiting a Jeremy-provided permanent HTTPS domain + access.*
