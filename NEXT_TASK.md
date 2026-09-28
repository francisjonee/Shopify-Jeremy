# NEXT TASK

**STATUS:** NONE — no executable task is currently authorized.

`SCA-ITEM-METADATA-CORRECTION-046` is **DONE** (`--no-ff` merged + deployed to production `main` at
`bb52a9dae425a97e601f4e0ea88f063b5994401d`; base `17854a86f12d16485c7eb05ffa5418d7036a8eee`, feature
`fa9686344b5abae5b0323cd57f89b9592e3ec3d2`). Production migration applied once (batch 10): the append-only
`sca_item_metadata_events` ledger (FK + `correction_group_id`/composite indexes + exact 7-field CHECK +
both `_no_update`/`_no_delete` triggers), created with **0 rows** and no backfill. Production business data
verified byte-identical before/after (counts + item-metadata / media-checksum / current-state-projection
fingerprints all unchanged); no metadata correction, PDF generation, or certification/snapshot change was
performed. Deploy gate: focused `ItemMetadataCorrectionTest` 18/93; full `tests/Feature/Sca` 575/3099.

**No queued item has been promoted.** Per the authority rule, ChatGPT may promote exactly one queued item
from `TASK_QUEUE.md` into this file after auditing SCA-046. Until then there is no authorization to start
any task. **`SCA-047` must not start.**

*`SCA-PRODUCTION-CUTOVER` remains BLOCKED/DEFERRED awaiting a Jeremy-provided permanent HTTPS domain + access.*

## Legacy metadata-correction policy (recorded with SCA-046)

- `brand` and `model_name` are certificate-PDF render inputs. Correcting them is **blocked**
  (`LEGACY_PDF_FIELD_LOCKED`) when the item's current certification is a **snapshot-less legacy** cert;
  allowed only when there is **no** current certification OR the current certification has an **SCA-045
  snapshot**. Mixed unsafe+safe correction requests fail **atomically**.
- The 5 non-PDF fields — `frame_serial`, `year`, `country_of_origin`, `materials`,
  `original_specifications` — remain **always correctable**.
- **No automatic or reconstructed legacy snapshot** is created by SCA-046. All 3 production certifications
  are currently snapshot-less, so brand/model on them stays locked. Verified legacy-snapshot reconstruction
  (Option B) remains a **separate future prerequisite** task, not authorized here.
