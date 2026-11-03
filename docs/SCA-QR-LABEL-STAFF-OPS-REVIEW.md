# SCA — QR Label Printing & Staff Operations Review (read-only)

**The QR-label mechanism is technically sound and safe to begin with: the QR itself is robust (SVG,
highest error-correction, full black/white contrast, a proper quiet zone), it encodes the canonical
public-Passport URL with the exact token the public resolver accepts, "one active QR per item" is
structurally guaranteed, and uncertified inventory is correctly excluded (verified in code AND data —
the 205 imported records have zero QR and zero certifications, and every active QR belongs to a
currently-certified item). There is NO P0. The real risk before live authentication is operational,
not cryptographic: the printed label shows only the opaque SCA reference — no brand or model — so a
staffer attaching a sheet of near-identical labels to a stack of physical pairs has no human-readable
cross-check and can mis-attach a QR to the wrong pair (the single highest-priority finding); and the
physical QR size is set only by CSS, so a browser left on "shrink-to-fit" can print an unscannable
label. The smallest safe fix is to print the brand + model (and a batch sequence number) on the label
card.** Read-only review; no DB write, no QR/cert generation, no printing, no deployment, no Shopify
call, no edge change; production unchanged at `6e36aa7`; the 205 imported records untouched. 2026-11-03.
**STOP.**

> Written for: the owner (Jeremy) + the staff who will print and attach QR labels, and the external
> auditor reading from GitHub.

## What works well (no change needed)
- **QR image [4]:** `chillerlan/php-qrcode`, SVG markup, error-correction level **H** (highest), 4-module
  quiet zone, explicit per-module **#000 on #fff** (full contrast). One shared encoder
  (`renderActiveQrSvg`) drives the download, single label, and batch sheet, so a printed QR can never
  diverge from the downloaded one.
- **Correct identification [5][6]:** the QR encodes `config('app.url')` + `/p/{token}` using the **same**
  `sca_qr_identifiers.public_token` the public `PassportResolver` matches (canonical host; no hard-coded
  URL; path-only route joined to APP_URL).
- **One-active-QR [9]:** structurally guaranteed — `QrService::activate` refuses a second activation,
  `reissue` revokes-then-activates atomically under a `FOR UPDATE` item lock, the projection fold throws
  `ProvenanceIntegrityException` if it ever finds >1 open interval, and `public_token` is UNIQUE. A
  reissued/retired QR immediately stops being the active pointer, so a superseded tag can't be printed
  via normal resolution and stops verifying when scanned.
- **Exclusion of uncertified [11][12]:** label resolution keys strictly off
  `sca_item_current_state.active_qr_identifier_id`; an item with none (all 205 imports) → single actions
  return a constant, data-free **404** and batch **silently omits** it. The listing only renders the
  "Print label" checkbox for items that have an active QR. **Data confirms:** items 208; QR rows 3; items
  with a current cert 3; items with an active QR 3; **active QR without a current cert = 0**; imported ids
  7–211 → **0 QR, 0 cert**.
- **Human-readable match on the label:** the SCA `public_ref` is printed as 10pt monospace directly below
  the QR; the raw `public_token` never appears on any label.
- **Staff workflow [10]:** certify (`sca.eyewear.certify`, typed ISSUE) mints + activates the QR and
  freezes the snapshot; the item-detail "Certification & QR" tab then surfaces **Download printable QR
  (SVG)** and **Print QR label** only when both a current cert and an active QR exist; batch printing is a
  POST+CSRF form from the registry listing. On-screen print guidance is shown (scale 100%, fit-to-page
  off, A4/Letter, B&W on matte).

## Findings (classified)

### P0 — none
No security, privacy, or critical-flow blocker. Exclusion, certified-only issuance, one-active-QR, and
correct URL/token all hold in code and data.

### P1 — significant (address before high-volume labelling)
| # | Where | Problem | Practical risk | Recommended correction |
|---|---|---|---|---|
| P1-1 | `…/Resources/views/eyewear/_qr-label-card.blade.php` (label card, used by single + batch) | The label prints only the **opaque SCA reference** (`public_ref`) plus a fixed brand line "Second Chance Authenticators" and a generic caption. **Brand/model are not printed.** In a batch sheet, labels differ only by an opaque 12-hex reference, with no per-row sequence number. | **Mis-attachment [13]:** matching a sheet of near-identical labels to a stack of physical pairs relies entirely on reading opaque hex refs — a transposition attaches the wrong QR (hence the wrong Passport) to a genuine pair. This is the biggest real-world staff risk. | Print the **brand + model** on the card (and a batch sequence number) so each label carries a human-readable cross-check. |
| P1-2 | `qr-print-label.blade.php` / `qr-print-labels.blade.php` print CSS | Physical QR size is set **only by CSS** (30 mm single; inside 44 mm grid cells batch); the generator has no fixed pixel size and there is **no server-side PDF**. If the browser print dialog is left on shrink/fit-to-page, the QR can print too small to scan. | Operator-dependent **unscannable labels**; mitigated by on-screen hints but **not enforced**. | Provide a fixed-size print artifact (e.g. a server-rendered PDF at exact label dimensions) or otherwise lock the scale so output doesn't depend on browser settings. |

### P2 — optional improvements
| # | Where | Problem | Note |
|---|---|---|---|
| P2-1 | `EyewearItemController::renderActiveQrSvg` | The label action requires only an **active QR**, not a **current certification** — a divergence from `PassportResolver` (which also requires a current issued cert). An item whose cert was revoked **without** a replacement but whose active QR pointer persisted would still **print** a label that **404s when scanned**. | Latent: not currently reachable in data (active-QR-without-current-cert = 0; the batch checkbox keys on active-QR presence independent of cert). Aligning the label gate to require a current cert would close it. |
| P2-2 | `qrLabelsBatch` + `qr-print-labels.blade.php` | Ineligible selected items are omitted with only an **aggregate count** ("N of M omitted"), not named; dropped items shift the remaining labels' positions. | Compounds P1-1. Naming the omitted items (or disabling their selection) would help. |
| P2-3 | print views | No label-stock (Avery-style) template or registration marks; targets plain A4/Letter via the native browser dialog. | Acceptable at low volume; a label-stock template would help at scale. |
| P2-4 | routes/acl | QR/label actions are gated by `sca.eyewear.view` (same as detail), with **no dedicated print ACL and no owner/assignee scoping** — any viewer can print any item's label. | Not a confidentiality issue (the QR resolves a public page). A dedicated ACL would tighten least-privilege. |
| P2-5 | `show.blade.php:355` (item detail) | The `public_token` is shown as plain text on the detail page. | Acceptable post-R0 (the token is the public identifier, not a claim credential), but unnecessary to display. |

## Actual defects vs optional improvements [14]
- **Genuine logic gap (latent):** P2-1 (label gate diverges from the passport resolver) — a real inconsistency, not currently reachable in data.
- **Design/operational gaps (not code defects):** P1-1 (no brand/model on label) and P1-2 (scale depends on browser) — the software is internally consistent; the workflow is fragile. These are the ones that matter before live labelling.
- **Optional polish:** P2-2, P2-3, P2-4, P2-5.

## Smallest safe implementation task [16]
**Add brand + model (and a batch sequence number) to the QR label card.** It directly removes the
top mis-attachment risk (P1-1) and is tiny and low-risk: pass `brand`/`model_name` from
`renderActiveQrSvg()` and render them on `_qr-label-card.blade.php` (≈2 files) — presentation-only, no
schema, no QR/lifecycle/eligibility change, fully testable in the isolated sandbox, and it inherits the
existing exclusion (it only ever renders for items that already resolve an active QR). Close seconds, if
desired in the same slice: align the label gate to require a current certification (P2-1) and name the
omitted batch items (P2-2). A fixed-size PDF (P1-2) is a larger, separate task.

## Safety posture (this task)
Read-only review. No production DB write; no authentication/certification/QR generation; no physical
label printing; no deployment or migration; no Shopify API call or store change; no edge/Caddy change;
secure claiming not activated; the 205 imported records untouched. The two read-only DB checks were
`SELECT`-only. Production unchanged at `6e36aa7`.

**STOP — QR labelling is technically sound (robust SVG/ECC-H QR, canonical passport URL + exact token,
one-active-QR guaranteed, uncertified correctly excluded in code and data — 205 imports have 0 QR/0
cert, 0 active-QR-without-cert). NO P0. P1: the label omits brand/model (mis-attachment risk — the top
staff risk) and the QR's physical size depends on browser print scaling (scannability). P2: label gate
requires active-QR-not-current-cert (latent), silent aggregate batch omission, no label-stock template,
no dedicated print ACL, token shown on detail. Smallest safe next task: print brand + model (+ batch
sequence number) on the label card. Read-only; nothing changed; prod `6e36aa7` intact.**
