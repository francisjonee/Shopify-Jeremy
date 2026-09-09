# SCA Product Requirements — Jeremy Vision

## Core Goal

Build Second Chance Authenticators into the trusted digital infrastructure for collectible eyewear. Authentication is the first event in a permanent record that follows the eyewear through ownership, resale, transfer, service, and status changes.

## Required Pre-Sale State

Every pair sold by Second Chance Eyewear should already have:

1. Authentication completed
2. Condition grade recorded
3. Registry / provenance record created
4. Unique SCA Certification ID
5. Permanent QR code created and included with the physical product
6. Ownership state = `UNCLAIMED`

## Second Chance Eyewear Buyer Flow

1. Customer purchases a certified pair from Second Chance Eyewear.
2. Shopify confirms the paid order and identifies the purchased product/variant.
3. SCA links that sale to the corresponding certification record.
4. SCA changes the claim state to `SOLD_AWAITING_CLAIM`.
5. Customer receives the physical eyewear and scans the permanent QR.
6. QR opens the SCA record.
7. SCA shows: “This eyewear has already been authenticated. Claim ownership.”
8. Customer signs in or creates an SCA collector account.
9. Claim eligibility is verified against the original sale and/or a secure claim mechanism.
10. Ownership is registered.
11. The item appears in **My Collection**.

A Shopify purchase makes the buyer **eligible to claim**. It should not automatically become a permanent registered ownership event until the claim is completed.

## External Eyewear Flow

If a collector owns eyewear not purchased from Second Chance Eyewear:

1. Collector submits the piece for paid SCA authentication.
2. SCA authenticates and grades the item.
3. A new SCA Certification ID and permanent provenance record are created.
4. The item is added to the collector’s account after the applicable authentication/claim workflow.

## Digital Provenance Record

Each eyewear record should support:

- Model
- Manufacturer / brand
- Year
- Country of origin
- Materials
- Original specifications
- Authentication record
- Condition grade
- Inspection images
- Certification status
- Current ownership status
- Ownership history
- Transfer history
- Service history
- Market information (future)

The preferred product name is **SCA Digital Provenance Record™**. “Digital Passport” may still be used as consumer-facing UI language.

## Permanent QR

The QR must never expire and must resolve to a Jeremy-controlled SCA domain. The QR identifies the eyewear record, not a temporary session.

A scan may show different behavior depending on record state:

- `UNCLAIMED`
- `SOLD_AWAITING_CLAIM`
- `REGISTERED`
- `TRANSFER_PENDING`
- `LOST`
- `STOLEN`
- `CERTIFICATION_CHANGED`

The same permanent QR remains valid throughout the item’s lifetime.

## Ownership History

Ownership must be event-based and append history. Do not model ownership as a single mutable owner field that destroys prior provenance.

Example:

- Original retail sale
- Jeremy B. — owner 1
- John S. — owner 2
- Jane D. — owner 3

The current owner is derived from the active ownership state, while historical events remain preserved.

## Transfer Ownership

The registered owner can initiate a transfer. The receiving collector must accept/claim the transfer. The previous owner remains in provenance history after transfer completes.

## Service History

Repairs, lens replacements, polishing, tune-ups, inspections, and future services should append service events to the record.

## Lost / Stolen Registry

A registered owner can report an item lost or stolen. Public QR verification should show a warning status without exposing private owner information.

## Insurance Report

Future feature: generate a PDF containing relevant authentication, condition, photos, certification, serial/specification, ownership, and supporting record information.

## Market Information

Future feature, explicitly not an appraisal system. Potential fields include:

- Original retail MSRP
- Average resale
- Highest verified sale
- Lowest verified sale
- Last verified sale

## Collector Dashboard

**My Collection** should eventually include:

- Authenticated pieces
- Brands owned
- Certificates
- Service history
- Transfer history
- Downloadable records
- Optional purchase/insured-value summaries

## Collector Profiles

Future feature: optional public/private collector profile with non-sensitive collection statistics. Do not expose private pricing or personal information by default.

## Privacy Principle

Public QR scans must never expose email, phone, address, credentials, or other private account information. Public ownership display should be privacy-controlled and may show only a status or abbreviated display name.
