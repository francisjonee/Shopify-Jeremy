# SCA — First Genuine QR Passport: Staff Execution Handover

**A staff-facing checklist to issue the first genuine SCA QR Passport for `SCA-058DAA468939` (Alain Mikli
AO1347) once the physical pair is in hand. Confirmed read-only on 2026-11-02: the item is still INTAKE /
uncertified (0 authentications, 0 certifications, 0 QR, no owner). Nothing was submitted, finalized, or
certified — this is the runbook, not the execution.** Prod `6e36aa7`. **STOP.**

> Written for: the SCA staff member (and owner/approver) who will perform the first authentication and QR
> Passport issuance in the admin dashboard.

---

## 0. Before you start — authorization & access
- [ ] **Owner go-ahead** for the first genuine certification is given.
- [ ] You are signed in to the SCA admin dashboard and your account holds **all five** abilities:
      `sca.eyewear.view`, `sca.eyewear.metadata.correct`, `sca.eyewear.catalog` (for photos),
      `sca.eyewear.authenticate`, `sca.eyewear.certify`. If any action below is missing/greyed out, you lack
      that ability — ask the owner to grant it; do not work around it.
- [ ] You have the **physical pair** and, ideally, a QR label printer / label stock ready.

## The target record
| | |
|---|---|
| SCA reference | **`SCA-058DAA468939`** (item id 17) |
| Shopify variant | `48797037494559` (SKU `4879703749`) |
| Catalog title | ALAIN MIKLI Mod. AO1347 – Col.2895 – Brand New/Unworn with Factory Lenses |
| State now | INTAKE / uncertified — brand & model are blank (to be verified from the frame) |

---

## 1. Open the item
- [ ] Go to **Registry → `/admin/sca/eyewear`**, search **`SCA-058DAA468939`**, open its detail page.
- [ ] Confirm it shows **Intake / Not authenticated**, a **Shopify ✓** link badge, and **no** Certified/QR
      badge. (If it already shows a certification or QR, **STOP** — see §Stop safely.)

## 2. Physically inspect the pair (REQUIRED before any PASSED result)
- [ ] Confirm the **physical pair genuinely exists** and matches this record (Alain Mikli AO1347, the Shopify
      listing). The catalog/quantity is **not** proof of physical presence.
- [ ] Inspect authenticity and condition in hand. **You may only record a PASSED result after this physical
      inspection** — never pass an item from the catalog listing alone.
- [ ] If anything cannot be verified (identity, authenticity, condition, or the pair is not physically
      present), **do not pass it** — go to §Stop safely.

## 3. Record verified brand & model (BEFORE certification)
*Why first: certification freezes a permanent certificate snapshot of the item's details. If brand/model are
blank at that moment, the permanent Passport/certificate will show blank identity.*
- [ ] On the item detail page, click **"Correct item metadata"** (`…/{id}/metadata/correct`).
- [ ] Enter the **verified brand** (e.g. "Alain Mikli") and **model** (e.g. "AO1347 Col.2895") **as read from
      the physical frame**. Add `frame_serial`, `year`, `country_of_origin`, `materials`,
      `original_specifications` only if confirmed. **Leave anything unknown blank — never invent a value.**
- [ ] Save, and confirm the detail page now shows the corrected brand/model.
- [ ] *(Recommended, optional)* Upload clear **evidence photos** of the pair via the item's image upload
      (needs `sca.eyewear.catalog`). Photos attach to the item; the authentication form itself has no photo
      field.

## 4. Authenticate (records a draft inspection)
- [ ] Click **"Authenticate"** (`…/{id}/authenticate`).
- [ ] Set **Result = Passed** (only after §2). A passed result **requires** a **Condition grade (A / B / C /
      D)** — choose the grade you assessed in hand (a genuine new/unworn pair is typically A, but you decide).
- [ ] Add **notes** if useful (optional, ≤5000 chars). Save — this creates a **draft** inspection.
  - *(If the pair fails or you're unsure: record Result = Failed or Inconclusive instead — these take no
    grade — and STOP; do not finalize/certify.)*

## 5. Finalize the authentication (irreversible)
- [ ] Review the draft on the item page. When you're certain, click **Finalize** and type **`FINALIZE`** to
      confirm (`…/authentications/{authId}/finalize`).
- [ ] This makes the authentication **immutable provenance evidence** — it cannot be undone. Only finalize a
      correct, passed inspection.

## 6. Certify → mints the QR Passport (irreversible)
- [ ] Click **Certify → Certify (confirm)** (`…/{id}/certify/confirm`), review the shown item + source
      authentication, then type **`ISSUE`** to confirm (`…/{id}/certify`).
- [ ] In one step this **issues the certification, activates the permanent QR Passport, and freezes the
      certificate snapshot**. **Write down the certification number** shown in the success message.

## 7. Verify the certificate PDF & public Passport (task 7)
- [ ] On the item detail page, confirm it now shows a **current certification** and an **active QR**.
- [ ] Open the **QR view** (`…/{id}/qr`) and the **certificate PDF** (the on-demand certificate action on the
      item): confirm the certificate shows the **correct brand, model, SCA reference, and certification
      number** (this is the frozen snapshot — if brand/model are wrong/blank here, they were not entered in
      §3; see §Stop safely before relying on it).
- [ ] Open the **public Passport** at **`/p/{qr_public_token}`** (the token from the QR view) in a normal
      browser: confirm it displays the pair with the **green authenticity badge** and **no private/staff or
      owner data**.

## 8. Print and affix the QR label
- [ ] Open **`…/{id}/qr/label`** (or the batch label action) and print the QR label; affix it to the physical
      pair.

## 9. Done — and what is NOT part of this
- [ ] The Passport is issued. **Collector claiming / ownership transfer is a SEPARATE, later step** — do
      **not** initiate any customer claim or ownership change as part of issuing the Passport.

---

## Stop safely — when NOT to proceed
Stop and escalate to the owner (and leave the record as-is) if, at any point:
- The **physical pair is not present** or does not match the record (brand/model/listing).
- You **cannot verify authenticity, identity, or condition** → record **Failed / Inconclusive** (no grade)
  and stop; do **not** finalize or certify.
- The item page already shows a **certification or active QR** (it has already been issued) → stop and
  report.
- The **certificate/Passport preview shows wrong or blank brand/model** → stop **before** relying on it;
  (brand/model are locked once certified, so fix identity in §3 **before** §6, not after).
- Any dashboard action you need is **missing/denied** (missing ACL) → stop and ask the owner.
Nothing in steps 1–8 is irreversible **until you type `FINALIZE` (§5)**; before that you can safely abandon
the draft. After finalize/certify the evidence and certificate are permanent.

## Safety posture (this handover)
Read-only preparation only. This document confirmed item 17 is INTAKE/uncertified and did **not** submit any
authentication, finalize, certify, mint a QR, print a label, or change ownership; no Shopify call, no DB
write, no deployment. Secure-claim RC `4bd88d2` remains blocked. Prod unchanged at `6e36aa7`.

**STOP — Staff handover prepared for `SCA-058DAA468939` (item 17, Alain Mikli AO1347, variant
`48797037494559`), confirmed still INTAKE/uncertified (0 auth/cert/QR/owner). The checklist above covers the
exact dashboard pages, inputs, and ACLs for metadata correction → physical inspection → authentication →
finalize → certify (mints the QR Passport + certificate snapshot) → certificate/Passport verification → QR
label print, with explicit physical-inspection-before-PASS and brand/model-before-certify gates and
safe-stop criteria. Nothing was executed; prod `6e36aa7` unchanged.**
