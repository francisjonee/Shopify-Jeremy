# NEXT TASK

**STATUS:** ACTIVE — `SCA-STAFF-REGISTRY-OPERATIONS-051` **pushed for FINAL PRE-MERGE RE-VERIFICATION** after
the conditional-pass grammar fix (push only — NOT merged, NOT deployed, production NOT migrated). Base = deployed
`main` `ec2b2efcaab6f9f8d4c8c236645285dd8158ec37`; feature branch `sca-staff-registry-operations-051` now @
**`e168cffd62e90e54204b48e53e2a8d5badbf6b3c`** (2 commits: reviewed `a4240fd` preserved + grammar fix `e168cff`;
base..HEAD = the same 5-file scope). **Pre-merge review finding resolved:** `normalizeQrToken` was broader than
the `/p/{token}` contract (accepted any `…/{token}` path); it now accepts ONLY a bare token or a value whose
parsed URL path is exactly `/p/{token}` (rejects `/anything/{token}`, `/foo/p/{token}`, trailing slash, encoded
slashes, uppercase/wrong-length/non-hex), no host dependency — proven by new focused case `rg16`. Focused
`StaffRegistryOperationsTest` **17/123**; full `tests/Feature/Sca` **614/3327**; `php -l` clean. Read-only (no
schema/mutation; one POST lookup route under existing `sca.eyewear` ACL); Option-A/PassportResolver/QR lifecycle
untouched. Pilot restored to deployed `ec2b2ef`. Must not be merged/deployed and SCA-052 must not start until
ChatGPT authorizes. Evidence in `docs/task-reports/SCA-STAFF-REGISTRY-OPERATIONS-051.md`.

*Prior: `SCA-049` DONE (deployed `ec2b2ef`); `SCA-050` product/ops audit DONE. `SCA-PRODUCTION-CUTOVER` remains
BLOCKED/DEFERRED. SCA-052 must not start.*

## Title

SCA-STAFF-REGISTRY-OPERATIONS-051 — read-only operational filtering / search / sort + physical-item lookup on
the existing staff eyewear registry index

## Goal

Turn the existing staff eyewear registry index into a practical operational lookup surface using only canonical
existing data — no second source of truth, no new projection, no duplicated lifecycle concept. Removes the most
frequent raw-DB staff operations (find items by state; find the item behind a physical certificate / QR).

## Executable directive (as governed)

Extend `EyewearItemController@index` + `eyewear/index.blade.php` (and a small validated request) with read-only
filtering/search/sort over canonical data, and add ONE POST lookup action for QR resolution. No domain mutation;
**no schema/migration** (if inspection during build proves an unavoidable schema need, STOP and report rather
than expand scope). No new projection or duplicated lifecycle state.

### Filters / search (GET query string; preserved across pagination via `withQueryString`)
- **Preserve** the existing `search` (bound LIKE over `public_ref`/`brand`/`model_name`/`frame_serial`) and
  `intake_type` filter unchanged.
- **Certification number** — narrow to items holding a certification whose `certification_number` matches the
  (trimmed/normalized) input. Resolve through `sca_certifications` across **all** rows (current AND
  historical/superseded), via a subquery on `eyewear_item_id` (never a join that duplicates item rows).
  **Decision (recorded):** an old/superseded certificate number MUST locate the same item — a legitimate
  physical historical certificate stays discoverable; do not search only the current projection.
- **Registry status** — filter on `sca_item_current_state.registry_status` (canonical set: normal, lost,
  stolen, recovered, disputed, retired, invalidated). Unknown value → ignored (fail safe).
- **Lifecycle state** — filter on `sca_item_current_state.lifecycle_state` (canonical projection enum). Unknown
  value → ignored.
- **Ownership state** — at minimum owned vs unowned: owned = `current_owner_collector_id IS NOT NULL`, unowned =
  `IS NULL`. Never expose the owner's identity/COL-ref — only the boolean state.
- **Date** — on `sca_eyewear_items.created_at` (the item **intake** date — the canonical per-item operational
  date; per-related-row dates like cert `issued_at` are rejected as they would duplicate rows / invent a new
  lifecycle concept). Inclusive `from`/`to` (Y-m-d) boundaries; malformed dates ignored.
- The projection is joined **1:1** (`sca_item_current_state` is exactly one row per item, PK
  `eyewear_item_id`); use a LEFT JOIN selecting `sca_eyewear_items.*` so no item is dropped and **one item is
  always one index result**, regardless of certification/event/history counts.

### Sorting
Deterministic, allowlisted sort keys only (e.g. `ref`→public_ref, `brand`, `model`→model_name,
`intake`→created_at, `status`→registry_status, `lifecycle`→lifecycle_state) + `dir` ∈ {asc,desc}. Default =
intake (created_at) desc. **Stable tie-breaker:** always append `sca_eyewear_items.id` desc. Unknown sort/dir →
default (never interpolate raw input into the ORDER BY).

### Physical-item QR lookup (POST only)
Add one POST action (reusing the existing `sca.eyewear` view ACL). Accept a pasted/scanned QR token OR a
canonical `/p/{token}` value in the request **body**; normalize (extract the token segment from a `/p/…` URL,
trim) and validate well-formed before use. Resolve by **exact** `sca_qr_identifiers.public_token` to the owning
`eyewear_item_id` — an administrative lookup that resolves **any** QR (active, stale, or revoked), so it does
**not** reuse `PassportResolver` and does **not** touch the SCA-038 Option-A public-passport contract or QR
permanence. On a unique match → redirect to the existing admin item detail (`admin.sca.eyewear.show`). On no
match / malformed → redirect back to the index with a neutral "not found" notice. The raw token is **never**
rendered in results, put in any URL after resolution (POST body only; redirect target carries the item id, not
the token), added to logs by this feature, or echoed into HTML.

### Security / privacy (hard gate)
Retain the existing staff `sca.eyewear` ACL + auth boundary. Do NOT expose, merely to implement this: collector
PII/identity/COL-ref, raw QR tokens, certification `public_token`s, internal DB ids beyond the pre-existing
item-id already used in the detail link, claim/transfer/grant/reset secrets, correction reasons, snapshot
checksums, or any other provenance internals. The certification **number** (a public-safe display ref) and the
registry/lifecycle status (already shown) are the only newly-surfaced values.

### Read-only boundary
No domain mutation from any registry GET or the QR-lookup POST (it reads + redirects only). No new projection /
duplicated state. One item = one row.

### Tests (focused suite) — must cover
existing search regression; certification-number lookup; **historical/superseded** cert-number lookup (same
item found); each accepted status filter (registry + lifecycle); owned/unowned; date semantics + inclusive
boundaries; sort allowlist + default + stable ordering; combined filters; pagination preserving query state;
unknown/malformed values fail safe; authorization (unauth/other-guard denied); no sensitive-data leakage
(no PII/tokens/ids/secrets in HTML); **no duplicate item rows** (item with multiple certs appears once); zero
mutation from registry GETs; QR lookup (match → redirect to detail; miss/malformed → safe; token not echoed).

Run the focused suite AND the full `tests/Feature/Sca` suite on the disposable `sca_domain_test` DB; record
exact totals.

### Delivery
Implement on a governed feature branch off `ec2b2ef`; **push only**; restore the pilot to deployed `ec2b2ef`
(clean tree, `--no-dev`, existing exposure/IP-lock, private MariaDB); push governance evidence; STOP for
ChatGPT audit. **Do NOT merge or deploy. Do NOT start SCA-052.**

*Separately: the SCA-050 collector green-authenticity-badge inconsistency is recorded in
`docs/PENDING-DEFECTS.md` as an open correctness defect — it is NOT fixed in SCA-051.*
