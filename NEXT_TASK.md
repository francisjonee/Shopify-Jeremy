# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-STAFF-COLLECTOR-SUPPORT-040` is **DONE** (ChatGPT-audited, governed `--no-ff` merge, and deployed to
production `main` at `ec75d4f5cd18fbb4b9314e28fa8ab99fb6a44398`; base was `bd5b2e7`, feature HEAD `cb4f357`).
Authorized staff can now locate a collector by the opaque `COL-…` reference and view their
canonically-owned items read-only (`GET admin/sca/collectors`, `GET admin/sca/collectors/{ref}`, dedicated
`sca.collector.support` ACL) — no more raw DB lookups for collector support. Email is withheld (not
authorized by the accepted staff privacy model); no schema migration. Deploy gate:
`CollectorSupportTest` 11 passed / 53 assertions; full `tests/Feature/Sca` 509 passed / 2166 assertions.
Production business/provenance baseline verified identical before and after deployment.

`SCA-PRODUCTION-CUTOVER` remains **BLOCKED/DEFERRED** awaiting Jeremy (permanent domain/access); it does not
block application development.

*The 040 task spec/evidence is preserved in the implementation repo report
`docs/task-reports/SCA-STAFF-COLLECTOR-SUPPORT-040.md`.*

ChatGPT promotes exactly one next task here when ready. **SCA-041 is not activated.**
