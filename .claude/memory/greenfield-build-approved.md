# Greenfield SCA build is approved

Jeremy's team has explicitly decided not to recover the inaccessible prior Ownership Bridge implementation. SCA will be built from scratch on the currently available blank VPS.

The current VPS is a **temporary construction/staging environment**, not the permanent home of SCA.

**Why it matters:** Claude should no longer block product work waiting for the old implementation. New code is authorized, but it must be portable to a future permanent server.

**How to apply:** Follow ADR-0005, `docs/INFRASTRUCTURE_BLUEPRINT.md`, and `docs/ROADMAP.md`. Keep application source in a private implementation repository. Do not hard-code the temporary VPS IP/hostname. QR identity belongs to SCA, not Shopify. Permanent QR uses a Jeremy-controlled domain. Shopify purchase creates claim eligibility; ownership is registered only after SCA account sign-in/claim.
