# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-CERTIFICATION-CORRECTION-038` is **DONE** (ChatGPT-audited, governed `--no-ff` merge, and deployed to
production `main` at `bd5b2e795c21c0828413554ac78f47216a982fa4`; base was `df80e4b`, feature HEAD `9d1c0e4`).
Staff can now revoke or re-certify (supersede) a certification through the dedicated
`sca.eyewear.certification.correct` surface — append-only, permanent QR identity preserved, and the accepted
(Option A) constant-shape public-passport contract unchanged. **No schema migration** (the certification
ledger already supplied `reason` / `successor_certification_id` / `supersedes_certification_id`). Deploy test
gate: `CertificationCorrectionTest` 21 passed / 99 assertions; full `tests/Feature/Sca` 498 passed / 2113
assertions. Production business/provenance baseline verified identical before and after deployment.

*The 038 task spec is preserved in the implementation repo report
`docs/task-reports/SCA-CERTIFICATION-CORRECTION-038.md`.*

ChatGPT promotes exactly one next task here when ready. **SCA-039 is not activated.**
