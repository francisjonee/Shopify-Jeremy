# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-COLLECTOR-PASSPORT-ACCESS-041` is **DONE** (ChatGPT-audited, governed `--no-ff` merge, and deployed to
production `main` at `223cc40a8928af9b70ff2ab711b18c3fa4c31b38`; base was `ec75d4f`, feature HEAD `1a72d65`).
An authenticated current owner can now open the same canonical public passport their physical QR resolves to,
directly from My Collection (`GET collector/collection/{ref}/passport`, behind `collector.auth`) — a
read-only owner+eligibility-authorized redirect to the existing `/p/{token}`. `PassportResolver`/
`PassportController` unchanged (Option-A preserved); no schema migration. Deploy gate:
`CollectorPassportAccessTest` 12 passed / 32 assertions; full `tests/Feature/Sca` 521 passed / 2198
assertions. Production business/provenance baseline verified identical before and after deployment.

`SCA-PRODUCTION-CUTOVER` remains **BLOCKED/DEFERRED** awaiting Jeremy (permanent domain/access); it does not
block application development.

*The 041 task spec/evidence is preserved in the implementation repo report
`docs/task-reports/SCA-COLLECTOR-PASSPORT-ACCESS-041.md`.*

ChatGPT promotes exactly one next task here when ready. **SCA-042 is not activated.**
