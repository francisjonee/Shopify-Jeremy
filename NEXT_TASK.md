# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-MY-COLLECTION-ENRICHMENT-042` is **DONE** (ChatGPT-audited, governed `--no-ff` merge, and deployed to
production `main` at `50c54ad2ce0afe8f993e11d8b1979e5d667c7935`; base `223cc40`, feature HEAD `29715de`).
Collector item detail now distinguishes certificate PDFs as **Current certificate** vs **Superseded /
historical** — derived read-time from each media asset's certification linkage vs the canonical
`current_certification_id`, with the document's public certification number. No evidence was
mutated/regenerated/deleted/hidden; no successor PDF was generated; no schema change. Isolated deploy gate:
`CertificateDocumentClassificationTest` 11 passed / 33 assertions; full `tests/Feature/Sca` 532 passed /
2231 assertions. `migrate --force` → "Nothing to migrate." Production business/provenance baseline
(incl. `media_assets`) verified identical before and after; the pilot predecessor PDF
(`SCA-CERT-2026-FEE6D3D8`) renders as historical while the item's current certification is the successor
(`SCA-CERT-2026-5AC07F22`). SCA-041 passport access unchanged.

*Test-history note: during independent verification two earlier runs (each chained after other
memory-heavy work on this swapless shared host) reported a single transient failure that was
**not reproducible** across isolated runs; the isolated focused and full gates were clean. Root cause is
not asserted as proven.*

`SCA-PRODUCTION-CUTOVER` remains **BLOCKED/DEFERRED** awaiting Jeremy; it does not block application
development.

*The 042 spec/evidence is preserved in the implementation repo report
`docs/task-reports/SCA-MY-COLLECTION-ENRICHMENT-042.md`.*

ChatGPT promotes exactly one next task here when ready. **SCA-043 is not activated.**
