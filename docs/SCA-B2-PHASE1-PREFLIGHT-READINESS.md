# SCA — Backblaze B2 configuration, Phase 1: preflight readiness

Date: 2026-11-09 · Type: preparation + offline validation only · **Nothing was run against Backblaze.**

## Input

Backblaze Support's written confirmation (2026-11-09) for bucket `sca-secure-backups-2026`:

- `writeBucketRetentions` is required for S3 `PutObjectLockConfiguration`.
- `readBucketRetentions` is required for S3 `GetObjectLockConfiguration`.
- `writeBuckets` is **not** required.
- A temporary bucket-restricted key with those two capabilities can set default GOVERNANCE / 14 days, and can be deleted afterwards.
- Uploader keys need neither capability.

## Change made

Private implementation repository, branch `review/backblaze-b2-config-script`:
`dfd9d64` → **`0292e51`** (2 files).

- `ops/backblaze/sca-b2.sh`: `TMP_KEY_CAPS='["readBucketRetentions","writeBucketRetentions"]'`. No other script change.
- `ops/backblaze/README.md`: new SHA-256, the Support prerequisite marked done, operator fills in 2 key names (was 3 values), and the `backup-run.sh` `set -e` issue marked resolved by PR #27.
- New script SHA-256 (before the operator fills in the key names): `664ec376b93679012688246e5ab3874d3c9a70fea160e6e5403f7a80c37e12f0`

## Confirmations (from the script source)

| # | Requirement | Result |
|---|---|---|
| 2 | Temporary key caps exactly `readBucketRetentions,writeBucketRetentions` | **PASS**: set; `objectlock` re-checks after login that the key holds exactly these (sorted equality) |
| 3 | Temporary key restricted to `sca-secure-backups-2026` | **PASS**: `b2_create_key` with `bucketIds:[<that bucket id>]`, 1-hour expiry; login re-checks bucket = only that bucket; revoked at the end of the phase and on any failure, Ctrl-C or exit |
| 4 | Default lock GOVERNANCE, never COMPLIANCE, exactly 14 days | **PASS**: fixed `LOCK_BODY` `{"Mode":"GOVERNANCE","Days":14}`; read back via S3 (`Days==14`, `Years==null`) and the native API (`governance`, `{duration:14,unit:days}`); any other existing retention → refuse, no change |
| 5 | Replacement uploader caps exactly `deleteFiles,listAllBucketNames,listBuckets,listFiles,readFiles,writeFiles` | **PASS**: fixed `UPLOADER_CAPS`; verified after creation (exact caps, this bucket only, prefix `sca/sca-backup-`, no expiry, cannot list keys, cannot read retention, confined to its prefix) |
| 6 | Recovery key stays read-only | **PASS (by design)**: every phase checks recovery caps ⊆ `listAllBucketNames,listBuckets,listFiles,readFiles,readBuckets` and bucket = this bucket only; `delete_key` refuses the recovery key. The live key's actual state is first observed by `preflight` |

Defense in depth: the script refuses to run on the production host (verified on this host) and outside an interactive terminal. Secrets are entered only through hidden prompts and passed through stdin or environment variables.

## Offline validation (no network, no credentials)

- `bash -n`: clean.
- Mock harness: the script's functions loaded with `curl`/`aws` stubbed to Backblaze-shaped JSON; every API method called is recorded.
  - `preflight`, healthy bucket: PASS. API calls were only `b2_authorize_account`, `b2_list_buckets`, `b2_list_file_versions` and `b2_list_keys`, all read-only.
  - Recovery key with `writeFiles` → **FAILED** (correct). Recovery key on all buckets → **FAILED** (correct). Missing lifecycle rule → **FAILED** (correct).
  - `objectlock`: `b2_create_key` payload capabilities = exactly `["readBucketRetentions","writeBucketRetentions"]`, bucketIds = the one bucket, `validDurationInSeconds:3600`; PUT body GOVERNANCE/14; temporary key revoked at the end.
  - `TMP_KEY_CAPS` including `bypassGovernance` → rejected before any network call.
- Real script on this host → `FAILED: this looks like the production server` (guard works).
- **Not run:** ShellCheck, which is not installed on the host and was not installed (the previous review, `dfd9d64`, was ShellCheck 0.10.0 clean; this change is a single string literal).
- Limitation: the harness proves the script's logic against JSON shaped from the API documentation, not live Backblaze responses. `preflight` is the first live proof.

## Operator inputs still required (no secrets in the script or in chat)

1. Approved trusted workstation (not the SCA server) with `bash`, `curl`, `jq` and `base64` (`aws` and `rclone` are needed only for later phases).
2. Script from `0292e51`, with SHA-256 checked and `bash -n` clean.
3. `OLD_UPLOADER_KEY_NAME`: the exact **name** of the existing uploader key (from the Backblaze console).
4. `RECOVERY_KEY_NAME`: the exact **name** of the existing read-only recovery key.
5. Master (administrative) key ID and secret, typed only into the script's hidden prompts, from the password manager, by the person the owner designates.
6. Owner go-ahead for `preflight`.

## Preconditions `preflight` will check (it fails closed if any differ)

Bucket private · Object Lock enabled · SSE-B2 · exactly one lifecycle rule (`sca/sca-backup-`, hide 16, delete +2) · bucket empty except `LOCKTEST` objects · recovery key read-only and on this bucket only · old uploader key present.

## Open items (not blocking preflight)

- Support has not yet said whether lifecycle retries deleting a hidden version once its lock expires. This matters for the day-15/day-21 `observe` checks.
- `objectlock`, `uploader-key`, `test` and `retire` each need their own approval gate.

## Verdict

**GO for `preflight`** (read-only), once the owner approves the operator and workstation and the operator has the two key names. NO-GO for every other phase until its gate is approved.

No change was made to Backblaze, application keys, uploads, production configuration, the production database, Shopify, or deployments.
