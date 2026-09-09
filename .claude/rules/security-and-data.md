# Rule — secrets, provenance, and privacy

These are the rules that cost real money or real trust when broken.

## 1. This repo is public

Anyone can read it. Before every commit, check the diff for:

- Shopify client secret, API key, or access token
- Database URL or password
- Session secret, magic-link secret, webhook signing secret
- `.env` file contents
- A real customer name, email, phone, address, or order number

**Never paste a secret to "test" something.** If a secret is needed, use an environment variable and commit only its **name**.

If a secret ever lands in a commit: stop, alert the authorized technical operator and ChatGPT immediately, and treat the secret as compromised. Rotate it. Deleting the commit is not enough.

**Word check:** *rotate* = replace the key with a new one and cancel the old one.
*environment variable* = a setting stored outside the code.

## 2. Provenance is append-only

Ownership, transfers, and service work are **events**. They get added to a history.

- Never model the owner as one field that erases the previous owner.
- A transfer adds a new event. Prior ownership stays in the record.
- Current ownership is derived from the active state while history remains preserved.

This is required by `docs/PRODUCT_REQUIREMENTS.md` and `docs/ARCHITECTURE.md`.

## 3. Shopify is not the provenance database

| Shopify owns | SCA owns |
|---|---|
| Products, variants, stock | Certification ID and authentication result |
| Orders and payments | Condition grade and inspection media |
| Original purchaser reference | Ownership, transfers, service, lost/stolen status |

One Shopify product is **not** automatically one physical pair. SCA must represent the actual physical collectible item.

## 4. Shopify scopes stay read-only

Baseline:

```text
read_products  read_inventory  read_orders  read_customers
```

No write scope without an approved ADR/task. Production calls must bind to the exact approved live Second Chance Eyewear store, never a guessed store identity.

## 5. Public QR scans never leak private data

A scan may show approved public status, certification ID, specifications, condition, and provenance summary.

A scan must **never** show email, phone, address, credentials, account details, or private owner data.

Public output uses an allowlist: anything not explicitly approved for public display stays private by default.

## 6. Webhooks

When built: verify Shopify signatures, process each event idempotently, survive retries, and keep an audit trail. Duplicate order events must never create duplicate ownership/provenance records.
