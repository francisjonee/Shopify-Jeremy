## What changed

<!-- One or two plain sentences. What is different now? -->

## Which task is this?

<!-- The TASK_ID from NEXT_TASK.md, or the Issue number. -->

- Task ID:
- Result: `RESULT=PASS` / `BLOCKED_<reason>`

## Proof it works

<!-- Paste the real command and the real output. Never "it should work". -->

```
```

## Checks

- [ ] This does exactly the approved task — nothing extra
- [ ] No token, key, password, database URL or `.env` content is in the diff
- [ ] No real customer name, email, phone, address or order number is in the diff
- [ ] Environment variables appear by **name only**, values redacted
- [ ] Nothing in the provenance model overwrites history — ownership stays append-only
- [ ] No new Shopify scope, and no write scope, without an approved ADR
- [ ] No application source added to this architecture repo

## Anything that needs a yes

<!-- Connecting the live Shopify store, spending money, deploying, DNS, a permanent QR
     URL, creating a repo. Say it here so it is not missed. -->

## Notes for the architect

<!-- Anything ChatGPT needs when auditing this against the acceptance criteria. -->
