# SCA — Backblaze B2 Confirmed Storage Path & Lifecycle (owner-confirmed config record)

**Owner-confirmed off-site configuration to apply when uploader setup is later authorized. Remote
destination: `b2:sca-secure-backups-2026/sca` (objects under the `sca/` prefix). Lifecycle rule prefix:
`sca/sca-backup-`, hide after 16 days, delete 2 days after hiding. This prefix matches BOTH the final
`.gpg` objects and the transient `.part` objects, so retention/cleanup covers both. No software installed,
no credentials configured, no upload performed, no production change — this is a recorded decision only.**
2026-11-06, prod `e3f73f8b`. **STOP.**

> Written for: the owner (Jeremy) and the external auditor. Supplements the compatibility analysis in
> `SCA-B2-RETENTION-COMPATIBILITY-REVIEW.md` (gov `452b45d`) with the owner's confirmed values.

## Confirmed values
| Item | Value |
|---|---|
| `SCA_BACKUP_REMOTE` (to set in `app/.env` later) | `b2:sca-secure-backups-2026/sca` |
| Bucket | `sca-secure-backups-2026` (endpoint `s3.us-east-005.backblazeb2.com`, private, SSE-B2, Object Lock enabled) |
| Lifecycle rule `fileNamePrefix` | `sca/sca-backup-` |
| Lifecycle `daysFromUploadingToHiding` | **16** |
| Lifecycle `daysFromHidingToDeleting` | **2** |

## Resulting object keys (verified against `scripts/lib-offsite.sh`)
The uploader builds `final="${remote%/}/$(basename file)"` and the transient is `${final}.part`. With the
confirmed remote:
- **Final:** `sca/sca-backup-<UTC>.tar.gz.gpg` (e.g. `sca/sca-backup-20261106T021702Z.tar.gz.gpg`)
- **Transient during upload:** `sca/sca-backup-<UTC>.tar.gz.gpg.part`
- Only the `.gpg` is published (the `.sha256` sidecar is NOT uploaded; the manifest is embedded in the
  encrypted bundle).

**Prefix coverage:** both keys begin with **`sca/sca-backup-`**, so the single lifecycle prefix
`sca/sca-backup-` applies to the final objects and to any transient/orphaned `.part` objects (the latter
arise if a bucket-default Object Lock is set; see the compatibility review). Hide 16 > any 14-day lock, so
lifecycle deletion is never blocked by Object Lock.

## Still owner-gated / not yet done (unchanged)
- Default Object Lock retention: recommended **Governance 14 days** (not Compliance) — owner's choice.
- Create the two bucket-scoped application keys: uploader (`listBuckets, listFiles, readFiles, writeFiles,
  deleteFiles`, no bypass) and a separate read-only verify key (`listFiles, readFiles`).
- Create the lifecycle rule above in the B2 dashboard.
- Only after separate authorization: Claude installs `rclone`, writes the root-only `rclone.conf`, sets
  `SCA_BACKUP_REMOTE=b2:sca-secure-backups-2026/sca` in `app/.env`, backfills, and verifies a downloaded
  artifact via the disposable restore test.

## Safety posture (this task)
Read-only recording of an owner-confirmed configuration. No software installed; no credentials configured;
no bucket upload; no B2 setting changed; no production change; no Shopify call; no secrets exposed.

**STOP — Recorded: off-site remote `b2:sca-secure-backups-2026/sca` → objects `sca/sca-backup-<UTC>.tar.gz.gpg`
(+`.part`); lifecycle prefix `sca/sca-backup-` (covers both), hide 16d / delete +2d. Nothing installed,
configured, uploaded, or changed — applies when uploader setup is authorized.**
