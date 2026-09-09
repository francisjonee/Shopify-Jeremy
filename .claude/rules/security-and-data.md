# Rule — secrets, provenance, and privacy

These are the rules that cost real money or real trust when broken.

## 1. This repo is public

Anyone can read it. Before every commit, check the diff for:

- Shopify client secret, API key, or access token
- Database URL or password
- Session secret, magic-link secret, webhook signing secret
- `.env` file contents
- A real customer name, email, phone, address, or order number

**Never paste a secret to "test" something.** If a secret is needed, use an environment
variable and commit only its **name**.

If a secret ever does land in a commit: stop, tell Francis immediately, and treat the
secret as burned. It must be rotated. Deleting the commit is not enough — GitHub keeps it.

**Word check:** *rotate* = replace the key with a new one and cancel the old one.
*environment variable* = a setting stored on the server, outside the code.

## 2. Provenance is append-only

Ownership, transfers, and service work are **events**. They get added to a list.

- Never model the owner as one field that gets overwritten. That destroys the history,
  which is the entire product.
- A transfer adds a new event. The previous owner stays in the record.
- The current owner is worked out from the active state, not stored as the only truth.

This is `docs/PRODUCT_REQUIREMENTS.md` and `docs/ARCHITECTURE.md`, and it is not
negotiable in a pull request.

## 3. Shopify is not the provenance database

| Shopify owns | SCA owns |
|---|---|
| Products, variants, stock | Certification ID and authentication result |
| Orders and payments | Condition grade and inspection photos |
| The original purchaser reference | Ownership, transfers, service, lost/stolen |

One Shopify product is **not** always one physical pair. Jeremy sells unique collectible
items. The model must allow one record per physical frame.

## 4. Shopify scopes stay read-only

Baseline, and nothing more:

```text
read_products  read_inventory  read_orders  read_customers
```

No write scope without an approved ADR. Production calls bind to the **real** Second
Chance Eyewear store, identified by its exact `*.myshopify.com` name — never guessed from
the public shop address.

## 5. Public QR scans never leak private data

A scan may show status, certification ID, specifications, condition, and an approved
public history summary.

A scan must **never** show an email, phone number, address, account details, or a full
owner name unless that owner chose to make it public.

The public registry works from an **allowlist** — a written list of fields that are
allowed out. Anything not on the list stays private by default.

## 6. Webhooks

When they are eventually built: verify the Shopify signature, process each event once
even if it arrives twice, survive retries, and keep an audit trail. A duplicated order
event must never create a duplicate ownership record.

**Word check:** *webhook* = Shopify calling your app to say something happened, like
"this order was paid".
