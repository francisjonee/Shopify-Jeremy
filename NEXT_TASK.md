# NEXT TASK

**STATUS:** ACTIVE — `SCA-EXPANSION-PLANNING-039` (READ-ONLY planning/design). Audit delivered; awaiting ChatGPT review and SCA-040 selection. No product code, no schema, no migration, no deploy.

*Prior task `SCA-CERTIFICATION-CORRECTION-038` is DONE (merged + deployed `bd5b2e795c21c0828413554ac78f47216a982fa4`).*

## Title

SCA-EXPANSION-PLANNING-039 — Application expansion audit (read-only)

## Implementer

Claude (planning only)

## Why this task now

Production cutover remains **BLOCKED/DEFERRED** (Jeremy has not provided the permanent domain/access). That must not block continued application development. With the trusted provenance core pilot-validated, this task audits the accepted application and recommends the best next capabilities.

## Executable directive

Audit the accepted SCA application at implementation `main` @ `bd5b2e795c21c0828413554ac78f47216a982fa4`. Inspect actual routes/controllers/services/schema/projections/views and `docs/PRODUCT_REQUIREMENTS.md` — not only the historical roadmap.

Skip for now (keep under `SCA-PRODUCTION-CUTOVER`, do not modify): permanent domain/DNS/Caddy, permanent QR printing, Shopify live OAuth/webhooks, SMTP/provider config, off-server backup infra, retirement of the temporary `IP:8080` exposure, production secrets/cutover.

Determine what already exists and what is missing for: staff collector lookup/support; collector profile/account management; notifications; item metadata correction/editing; registry search/filtering; reporting/export; market/value history; external authentication intake; resale/marketplace; collector documents/certificate access; public-passport access from collector surfaces; staff dashboards/operational queues; audit/history visibility.

Evaluate families A–F (collector experience; staff operations; market/value; external paid authentication; resale/marketplace; notifications). For each: what exists; exact missing capability; user/business value; dependencies; provenance/security/privacy risks; schema-change needed?; complexity; sequencing. Distinguish explicit Jeremy requirement vs roadmap idea vs implementation gap vs recommendation.

Architectural boundary: existing provenance stays authoritative and append-only. Expansion must not redefine permanent item identity, ownership ledger, certification ledger, QR permanence, claim semantics, transfer semantics, or the public-passport privacy/security contract. Flag conflicts rather than designing around them.

Produce a ranked roadmap (NOW / NEXT / LATER / DEFERRED) and recommend exactly one smallest SCA-040 task (problem statement; exact scope; non-goals; routes/UI; data/schema impact; ACL/privacy; acceptance criteria; regression boundaries). Do NOT activate SCA-040.

Read-only: no implementation branch, no application code, no migrations, no production DB mutation, no deploy, no DNS/Caddy/firewall/Shopify/mail changes, do not disturb the live pilot.

## Result (delivered)

Full audit, ranked roadmap, and the recommended smallest SCA-040 (**SCA-COLLECTOR-PASSPORT-ACCESS-040**, with a read-only staff-collector-lookup alternative) are committed at **`docs/SCA-EXPANSION-PLANNING-039.md`** in this governance repo.

**STOP — audit for ChatGPT review. SCA-040 recommended but NOT activated. Do not start SCA-040.**
