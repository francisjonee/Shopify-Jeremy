# NEXT TASK

**STATUS:** NONE — no executable task is authorized.

`SCA-PUBLIC-PASSPORT-PILOT-034` is **DONE** (audited, merged to implementation `main` at `2029f09`, and manually pilot-validated normal → lost → recovered → stolen → recovered/normal with certification/authentication intact, permanent SCA identity stable, and no collector identity exposed publicly).

Per the governance rule, there is no active executable task until **ChatGPT promotes exactly one** item from `TASK_QUEUE.md` into this file. Claude must not self-promote or start the recommendation below.

---

## Recommendation for ChatGPT (NOT promoted, NOT authorized to start)

**Recommended next task:** `SCA-PRODUCTION-CUTOVER` — Permanent infrastructure & production-cutover **design/ADR + reversible prep** (supersedes the old `SCA-PRODUCTION-018` stub).

**Why it is next (from committed evidence):** the trusted provenance product is complete and pilot-validated end to end (intake → authentication → certification → permanent QR identity → claim → transfer → My Collection → ownership history → lost/stolen/recovered → public passport). The single remaining *product* dependency is the **permanent Jeremy-controlled HTTPS / public-QR domain**, which is the shared blocker behind every standing deferral: permanent QR printing (007/008), Shopify live OAuth + webhooks (009), and retiring the temporary-IP pilot exposure (CONTROLLED-PILOT-001). No further core application feature is required for the pilot to be trustworthy.

**Dependencies:** core product accepted (satisfied through 034) **+ a Jeremy-controlled production domain and secure credentials** (business/infra input Claude cannot self-provide). This is why the task should start as design/ADR, not a live cutover.

**Proposed scope (design + reversible prep only):**
- Produce an ADR + sequenced cutover plan covering: permanent domain + DNS; `sr-caddy` reverse-proxy route to `kr-app` over a shared container network (not a published host port); flip `SCA_PUBLIC_PREVIEW=0` and set the permanent `PUBLIC_QR_BASE_URL`; permanent QR-printing enablement; durable off-server backups + a restore rehearsal; production secrets management + admin-credential rotation; firewall/exposure cleanup (restore kr-app to loopback, remove the temporary IP allow-rules); Shopify live OAuth + webhook activation.
- Prove the permanent SCA identity/token and all provenance survive cutover unchanged (host-independence already validated in 034).

**Non-goals / boundaries:** do **not** perform live DNS/Caddy/Shopify/QR-domain cutover, activate production QR, change firewall/exposure, rotate live credentials, or mutate the live pilot record as part of the design task. No new passport, no QR-architecture redesign, no expansion features. Any actual infra mutation is a separate, explicitly-approved step once Jeremy supplies the domain.

**Acceptance boundary:** a committed cutover ADR + dependency/sequence checklist + rollback plan, with zero production infrastructure mutation and the live pilot untouched.

---

*History note:* the earlier `SCA-PUBLIC-PASSPORT-PILOT-034` task specification that previously occupied this file is preserved in the implementation repo's task report `docs/task-reports/SCA-PUBLIC-PASSPORT-PILOT-034.md`.
