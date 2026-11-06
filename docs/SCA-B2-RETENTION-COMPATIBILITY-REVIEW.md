# SCA — Backblaze B2 Retention & Object-Lock Compatibility Review (read-only)

**The existing uploader publishes exactly one object per night — the encrypted `.gpg` — by staging it as
`<name>.part` and then server-side **moving** it to the final name (a copy followed by a delete of the
`.part`). Because of that delete step, a bucket-wide **default Object Lock retention is only partly
compatible**: uploads still succeed (the delete becomes a versioned delete-marker), but every transient
`.part` becomes an orphaned locked version that cannot be removed until its lock expires — roughly doubling
stored bytes for the retention window — and **Compliance mode makes that irreversible**, which is the wrong
default for a first setup. The recommended design is therefore: enable the default lock in **Governance**
(not Compliance) mode at 14 days for real immutability the routine key cannot override, pair it with a
**custom lifecycle rule** (hide at 16 days, delete 2 days later — longer than the lock so nothing is
blocked) to actually remove the uniquely-named daily archives (and clean up the orphaned `.part` versions
after their lock lifts), and give the uploader a **bucket-scoped key with write+list+read+delete but no
bypass/retention powers**, plus a **separate read-only key** for restore verification. Expected steady-state
storage is ~140–150 GB (~$1/month) because immutability + the `.part` pattern keeps about two copies during
the window; without the default lock it would be ~75–80 GB (~$0.45/month). The single most important action
is setting the lifecycle rule — the bucket is currently "keep all versions" with no cleanup, which would
grow without bound.** Read-only; no B2 change, no upload, no key created, no software installed, no
production change. 2026-11-06, prod `e3f73f8b`. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. Bucket: `sca-secure-backups-2026`,
> `s3.us-east-005.backblazeb2.com`, private, SSE-B2 on, Object Lock enabled, default retention NOT yet
> saved, lifecycle = keep all versions, 0 files.

## 1. How the existing upload path works (verified in `scripts/lib-offsite.sh` + `backup-run.sh`)
- **One object per backup:** only `sca-backup-<UTC>.tar.gz.gpg` is uploaded. The `.sha256` sidecar is **not**
  uploaded (local convenience only), and the manifest/per-component hashes are **inside** the encrypted
  bundle — so there are no multi-object consistency concerns; retention/lock apply to just the `.gpg`.
- **Atomic publish:** `rclone copyto file → <final>.part`, then `rclone moveto <final>.part → <final>`
  (server-side copy + delete of `.part`); `aws s3 cp`/`aws s3 mv` for the aws path. On any failure it runs
  `rclone delete`/`aws s3 rm` on `.part`. The final name only ever appears once a complete object exists.
- **No overwrites, no sync-deletes of finals:** names are unique per day (timestamp), so the uploader never
  rewrites or deletes an existing final archive. The **only** deletes it issues are against its own
  transient `.part` (the move's delete, and failure cleanup).
- **Implication:** the uploader **requires a delete capability** (for the `.part`). It never needs to
  delete a final archive.

## 2. Is a 14-day **Compliance** default lock compatible? — Partly, and not recommended
- Object Lock forces **versioning**. A bucket **default** retention locks **every** new version — including
  each transient `.part`.
- The `moveto` deletes `.part` with no version id → B2 records a **delete-marker** (allowed under lock), so
  **the upload still succeeds**. But the underlying `.part` version stays **locked and billable** until its
  14-day retention expires; it cannot be removed early by anyone.
- **Compliance = irreversible:** not even the account owner can shorten or delete a locked version. A single
  mis-upload (wrong/huge object) is then billed until expiry with no recourse. For a first off-site setup
  this is a liability, not a benefit.
- **Verdict:** functional but wasteful (orphaned locked `.part` ≈ one extra copy per day) and unsafe to make
  irreversible. **Use Governance mode instead** (below).

## 3. Does the uploader do anything that conflicts with immutable objects?
No destructive operation on **final** archives — no overwrite, no bucket sync/delete, no modification. The
only deletes target the transient `.part`. Under any default lock those `.part` deletes degrade to
delete-markers (orphaned locked versions), which is the sole conflict; it is a **cost/cleanup** issue, not a
correctness failure. (If B2 ever rejected the `.part` delete outright under lock, the nightly `moveto` would
fail and `backup-run.sh` would log a failed upload — low risk with delete-marker semantics, but worth
watching on the first night.)

## 4. How retention should apply
- **Only the `.gpg`** is remote, so lock + lifecycle apply to `sca-backup-*.tar.gz.gpg` (and its transient
  `*.tar.gz.gpg.part`). The `.sha256` and `MANIFEST.txt` are **not** separate remote objects — nothing extra
  to retain. Integrity is proven by a successful GPG decrypt of the single bundle.

## 5. Automatic cleanup for **uniquely-named** daily archives
- Each day is a **new key** with exactly **one version**. Therefore version-count / "keep previous versions
  for N days" style rules do **nothing** here — there are no older versions of a given key to expire.
- Cleanup must act on the **age of the current version**: a lifecycle rule using
  `daysFromUploadingToHiding` (hide/expire the current version → delete-marker) then
  `daysFromHidingToDeleting` (permanently remove the hidden version). This is what deletes old daily
  archives, and it also eventually clears orphaned `.part` versions **after** their lock lifts.

## 6. Lifecycle vs Object-Lock interplay
- B2 lifecycle **cannot delete a version still under Object Lock** — it defers until the lock expires. So
  `daysFromUploadingToHiding` must be **≥ the lock days** (else deletion is simply blocked/deferred).
- Recommended rule (prefix `sca-backup-`): **`daysFromUploadingToHiding = 16`, `daysFromHidingToDeleting = 2`**
  (effective ~18-day life). 16 > 14-day lock, so deletion is never blocked; the 2-day buffer avoids removing
  a copy the instant it's hidden.

## 7. Safest retention + cleanup recommendation
| Setting | Recommended value | Why |
|---|---|---|
| Object Lock default retention | **Governance, 14 days** | immutability the routine key can't override; owner can still bypass to fix mistakes (Compliance can't) |
| Lifecycle (prefix `sca-backup-`) | `daysFromUploadingToHiding=16`, `daysFromHidingToDeleting=2` | removes unique daily archives after the lock lifts; cleans orphaned `.part`; buffer |
| Keep-all-versions (current) | **replace with the rule above** | "keep all versions" + no cleanup = unbounded growth |

- **Does 14-day immutability cost more than 14 days of storage? YES.** Lock 14d + hide@16 + delete@18 ⇒ each
  archive is billed ~16–18 days, not 14; plus each orphaned `.part` is billed ~14–16 days. Realistic
  steady-state ≈ **~140–150 GB ≈ ~$0.85–0.95/month** (B2 ~$6/TB-month; verify current pricing). Removing the
  default lock (or a future uploader tweak that drops `.part`) halves it to **~75–80 GB ≈ ~$0.45/month**.

## 8. Minimum bucket-scoped app-key permissions
- **Uploader key (routine, on the server):** scoped to `sca-secure-backups-2026`; capabilities
  **`listBuckets, listFiles, readFiles, writeFiles, deleteFiles`**. `deleteFiles` **is** technically
  necessary — the `.part`→final move and failure cleanup delete the transient object. **Do NOT grant**
  `bypassGovernance`, `writeBucketRetentions`, `writeBucketEncryption`, or any key-management capability.
  Governance lock ensures this key cannot actually destroy a final archive (its deletes become
  delete-markers; locked versions survive, and lifecycle — run by B2, not the key — does the real cleanup).
  Optional extra scoping: restrict the key to name-prefix `sca/`.
- **Restore-verification key (separate):** **`listFiles, readFiles` only** (read-only). Used to download an
  artifact for the disposable restore test. No write/delete.
- Keep `bypassGovernance`/retention-override on the **owner's master key only**, used manually if ever needed.

## 9. Who configures what
- **Owner (B2 dashboard):** (a) set the **lifecycle rule** in §7; (b) set **default Object Lock = Governance
  14 days** (or leave unset for the lower-cost/lower-immutability option); (c) create the two app keys in §8;
  (d) record both keys securely (never in git/`app/.env`/chat).
- **Claude (server, after separate authorization):** install `rclone`; write a **root-only**
  `rclone.conf` (`/root/.config/rclone/rclone.conf`, `600`) with the S3 endpoint
  `s3.us-east-005.backblazeb2.com` + the **uploader** key; set `SCA_BACKUP_REMOTE=<remote>:sca-secure-backups-2026/sca`
  (non-secret path) in `app/.env`; backfill recent artifacts; then run `backup-verify-restore.sh verify`
  against a downloaded object using the **read-only** key (disposable DB; plain + backgrounded, never under
  `bash -x | grep` or killed mid-run).

## 10. Risks
- **Permanent retention / runaway charges:** Compliance mode is irreversible → **choose Governance**. "Keep
  all versions" with no lifecycle grows without bound → **set the lifecycle rule**. A default lock bills the
  orphaned `.part` versions (~2× during the window) — bounded and ~$1/mo, cleared by lifecycle after expiry.
- **Early deletion:** none if `daysFromUploadingToHiding ≥ lock days` (16 ≥ 14). Lock also prevents B2 from
  deleting under retention.
- **Failed uploads:** the uploader key **must** include `deleteFiles` (else the `.part` move fails and the
  nightly upload errors). Watch the first post-config nightly for `OK off-site published`.
- **No code change needed** for this design. (A future option — uploading straight to the final name, no
  `.part` — would remove the orphaned-`.part` cost and let the uploader key drop `deleteFiles`; out of scope
  here.)

## Safety posture (this task)
Read-only. No Backblaze setting changed; no bucket upload; no application key created; no software installed;
no production change; no Shopify call; no credential or encryption secret exposed. Analysis from the local
scripts + the owner-provided bucket facts only.

**STOP — Recommended B2 config for the existing `.part`→promote uploader: (1) lifecycle rule prefix
`sca-backup-`, `daysFromUploadingToHiding=16` + `daysFromHidingToDeleting=2` (the must-do — bucket is
currently unbounded "keep all versions"); (2) default Object Lock = **Governance 14d**, NOT Compliance
(irreversible); (3) uploader key bucket-scoped list/read/write/**delete** (delete needed for `.part`), no
bypass/retention powers; (4) separate read-only key for restore verify. Uploads stay compatible (the `.part`
delete becomes a delete-marker); expect ~140–150 GB ≈ ~$1/mo because lock+`.part` keep ~2 copies in-window
(>14 days billable). Owner sets lifecycle + lock + keys in the dashboard; Claude later installs rclone, sets
`SCA_BACKUP_REMOTE`, backfills, and verifies — on separate authorization. Nothing changed this task.**
