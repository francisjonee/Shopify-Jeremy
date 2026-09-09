# The SCA task controller

A small program on the project server. It reads the one approved task on `main`, starts
Claude Code for exactly that task, records what happened, and stops.

It is not an architect. It never picks work, never approves anything, and never merges.

This is the implementation of `ADR-0003-CLAUDE-TASK-CONTROLLER.md`.

**Word check:** *controller* = the program that starts Claude. *dispatch* = one launch of
Claude for one task.

---

## 1. Why it exists

A task file on GitHub does not wake Claude up. Somebody has to press go.

The controller is that press. ChatGPT writes the task, the controller launches Claude for
it once, and then everything stops until ChatGPT has read the evidence.

---

## 2. Where it lives

| Thing | Where |
|---|---|
| Source, version controlled | `ops/controller/` in this repo |
| Installed copy | `/opt/sca-controller/bin/` on the server |
| Settings | `/opt/sca-controller/config/controller.env` — **not in Git** |
| State and logs | `/opt/sca-controller/state/` and `/opt/sca-controller/logs/` — **not in Git** |
| Working copy of the repo | `/opt/sca-controller/repo/` |

State and logs stay off GitHub because they hold server paths and run detail. This repo is
public.

It runs as the `sceyewear` account, not as root.

---

## 3. What one run does

1. Takes a lock, so two runs can never overlap.
2. Stops if HOLD is set.
3. Fetches `NEXT_TASK.md` from `main`.
4. Reads `STATUS`, `TASK_ID` and `RETRY_GENERATION`.
5. Stops unless `STATUS` is `READY`.
6. Stops if that exact `TASK_ID` and `RETRY_GENERATION` were dispatched before.
7. Writes the pair into a list, so it can never be dispatched twice.
8. Makes the task branch, for example `task/sca-ctrl-001-gen0`.
9. Starts Claude Code for that one task.
10. Records `AWAITING_ARCHITECT_AUDIT`, and stops.

ChatGPT reads the evidence. To send the same task back, ChatGPT raises
`RETRY_GENERATION` by one. That makes a new pair, so the controller will run it again.

---

## 4. The commands

Run everything as the service account.

Check where things stand:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl status
```

Dispatch once, without calling Claude:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl run --dry-run
```

Dispatch for real:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl run --live
```

Read the audit trail:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl log 20
```

---

## 5. The stop switches

**HOLD** stops the next dispatch. Nothing running is touched.

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl hold "paused by Francis"
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl resume
```

**KILL** stops the Claude run that is happening now, and sets HOLD at the same time.

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl kill "stop now"
```

`resume` is the only way back. Nothing clears HOLD on its own.

---

## 6. The safety rules built in

- **Dry-run is the default.** Live needs `--live` *and* `SCA_ALLOW_LIVE=1` in the settings
  file. It ships as `0`.
- **One at a time.** A file lock means a second run exits instead of racing.
- **No repeat dispatch.** The task ID and retry number are written down before Claude
  starts, so a crash mid-run cannot cause a second launch.
- **No merging.** The controller has no merge command, and it refuses to start if one is
  ever added to its own source.
- **Append-only trail.** Every decision is added to a log as one line. Lines are never
  edited or removed.
- **Non-root.** It runs as `sceyewear`.
- **No secrets in Git.** Settings live in a file on the server, readable only by that
  account.

---

## 7. States it can record

| State | Meaning |
|---|---|
| `RUNNING` | Claude was launched for this task |
| `AWAITING_ARCHITECT_AUDIT` | Finished. Waiting for ChatGPT to read the evidence |
| `FAILED_CLAUDE_INVOCATION` | Claude was launched but exited with an error |
| `FAILED_TASK_UNPARSEABLE` | `NEXT_TASK.md` had no readable task ID or retry number |
| `BLOCKED_LIVE_NOT_ENABLED` | `--live` was asked for, but live mode is switched off |
| `HELD` | HOLD was set, so nothing was dispatched |
| `IDLE` | `STATUS` on `main` was not `READY` |

---

## 8. Before live mode can be used

The service account has no credentials of its own yet. It needs two, set by Francis in
`/opt/sca-controller/config/controller.env`:

- `ANTHROPIC_API_KEY` — so the account can run Claude Code
- `GH_TOKEN` — so the account can push a branch and open a pull request

Names only. Never put the values in Git. Do not copy another account's credentials in.

---

## 9. Running it on a schedule

Not yet. `ops/controller/systemd/` holds the two files that would do it. They are not
installed and not switched on. That waits for the audit and for Francis's approval.
