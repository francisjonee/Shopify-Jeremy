# The SCA task controller

A small program on the project VPS. It reads the one approved task on `main`, starts Claude Code for exactly that task, records what happened, and stops.

It is not an architect. It never picks work, never approves itself, and never merges.

This implements `ADR-0003-CLAUDE-TASK-CONTROLLER.md`.

## 1. Why it exists

A task file on GitHub does not wake Claude by itself. The controller provides that execution bridge.

ChatGPT writes the task. The controller dispatches that exact task once. Claude returns evidence. Then the workflow stops until ChatGPT audits the result and publishes a new/revised task.

## 2. Where it lives

| Thing | Where |
|---|---|
| Version-controlled source | `ops/controller/` in this repo |
| Installed copy | `/opt/sca-controller/bin/` on the VPS |
| Settings | `/opt/sca-controller/config/controller.env` — **not in Git** |
| State and logs | `/opt/sca-controller/state/` and `/opt/sca-controller/logs/` — **not in Git** |
| Working copy | `/opt/sca-controller/repo/` |

It runs as the non-root `sceyewear` service account unless an approved task changes that design.

## 3. What one run does

1. Takes a lock so two runs cannot overlap.
2. Stops if HOLD is set.
3. Fetches `NEXT_TASK.md` from `main`.
4. Reads `STATUS`, `TASK_ID`, and `RETRY_GENERATION`.
5. Stops unless `STATUS` is `READY`.
6. Stops if that exact `TASK_ID#RETRY_GENERATION` was already dispatched.
7. Records the dispatch key before Claude starts.
8. Creates/uses the task branch.
9. Starts Claude Code for only that task in live mode, or simulates dispatch in dry-run mode.
10. Records the final controller state and stops for architecture audit.

Raising `RETRY_GENERATION` creates a new dispatch key for a remediation attempt.

## 4. Commands

Check status:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl status
```

Dry-run without calling Claude:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl run --dry-run
```

Live dispatch, only when explicitly authorized and configured:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl run --live
```

Read recent audit entries:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl log 20
```

## 5. Stop switches

HOLD stops future dispatches:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl hold "approved pause reason"
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl resume
```

KILL stops the active Claude process and sets HOLD:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl kill "approved stop reason"
```

## 6. Safety rules

- Dry-run is the default safety mode.
- Live mode requires both `--live` and `SCA_ALLOW_LIVE=1`.
- `flock` prevents overlapping runs.
- `TASK_ID#RETRY_GENERATION` prevents duplicate dispatch.
- The controller never merges PRs.
- Dispatch/audit logs are append-only.
- The controller runs non-root.
- Secrets stay outside Git.
- Missing proof means the task is not accepted even if controller code was already merged.

## 7. Controller states

| State | Meaning |
|---|---|
| `RUNNING` | Claude was launched for this task |
| `AWAITING_ARCHITECT_AUDIT` | Execution completed and waits for ChatGPT audit |
| `FAILED_CLAUDE_INVOCATION` | Claude invocation failed |
| `FAILED_TASK_UNPARSEABLE` | Current task could not be parsed |
| `BLOCKED_LIVE_NOT_ENABLED` | Live dispatch requested while live mode is disabled |
| `HELD` | HOLD blocked dispatch |
| `IDLE` | Current task is not READY |

## 8. Credentials and live mode

Dry-run proof does not require production dispatch credentials.

Live mode requires the service account to receive only the credentials explicitly authorized for this workflow, stored outside Git. Credential values must never appear in the architecture repo, PRs, logs, or chat evidence.

## 9. Scheduling

Unattended scheduling stays disabled until ChatGPT accepts the controller proof and a later approved task explicitly enables it.
