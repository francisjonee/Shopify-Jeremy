# NEXT TASK

**STATUS: ACTIVE — SCA STAFF NAVIGATION / DISCOVERABILITY. Executable stage: DISCOVERY/PLAN ONLY (DONE, awaiting audit).**

Promoted 2026-10-06 after governance reconciliation (`0c8c090`) passed ChatGPT audit. Deployed baseline `30b680f797bdcf0d9bf2e6031c32c4f80c41dfc4`, migrations **120**, FP **`62b2e42fe409b4ec91f3381b35da819e`**.

## Objective

Make already-built staff capabilities reachable naturally, without knowing hidden URLs — **discoverability only**. No new functionality, no replacement workflows, existing ACLs preserved (navigation visibility must never grant authorization).

## Current stage — DISCOVERY/PLAN (complete; STOP for audit)

The discovery/plan is committed at `docs/SCA-STAFF-NAV-DISCOVERABILITY-DISCOVERY.md`. **Do not implement yet.** Summary of findings:

- SCA sidebar has exactly two entries (Eyewear Registry, Shopify Integration). Krayin forces single-segment menu keys, so dotted-ACL capabilities are **by design** surfaced as permission-gated in-page buttons, not sidebar items.
- **Collector Support (SCA-040)** is **already discoverable** via a permission-gated button on the Eyewear Registry index → **optional convenience, not a true gap**; recommend **no change** (a sidebar entry would fight the menu-key/ACL constraint).
- **Ownership Correction (SCA-035)** is the **one true raw-URL-only gap**: its link lives on the ownership-history page, which item-detail links **only when `ownership > 0`** → **zero-ownership items have no UI path**. **Fix = a permission-gated "Correct ownership…" link on the item-detail page (`show.blade.php`), shown to `sca.eyewear.ownership.correct` holders regardless of ownership state**, pointing at the existing confirm route. Navigation-only.
- No other built capability is raw-URL-only.

## Recommended implementation scope (for the NEXT executable stage, if approved)

1. **(Required)** Add the permission-gated "Correct ownership…" item-detail link in `packages/Sca/Registry/src/Resources/views/eyewear/show.blade.php` → existing `admin.sca.eyewear.ownership.correct.confirm` route; gated by `bouncer()->hasPermission('sca.eyewear.ownership.correct')`; shown regardless of ownership count.
2. **(Optional, default none)** Collector Support — already reachable; no change recommended.

Tests: item-detail shows the link to authorized staff incl. **zero-ownership** items; hidden for unauthorized staff who still get 403 on the route (visibility ≠ authorization); link targets the confirm route; full `tests/Feature/Sca` green; zero provenance mutation; no schema change.

## Hard constraints

Discoverability only. **Do NOT** change provenance/ownership semantics, collector behavior, QR, certification, Shopify, SMTP, schema/migrations, public routes, Caddy/Docker, or infrastructure. **Do NOT** add sidebar entries for dotted-ACL capabilities, build a dashboard/worklists, create replacement workflows, or broaden any permission to make a link visible.

## Stage gate

**Executable stage is DISCOVERY/PLAN ONLY — now complete and committed. STOP for ChatGPT audit.** Implementation is a separate stage requiring explicit promotion/authorization. Completing the recommended scope would **CLOSE** Staff Navigation / Discoverability.
