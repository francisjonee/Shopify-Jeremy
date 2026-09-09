# systemd units — reference only, not installed

The two unit files here are **not installed and not enabled** on the VPS.

`ADR-0003` and `SCA-CTRL-001` both say unattended execution stays off until the dry-run
evidence has been audited by ChatGPT. Until then the controller is run by hand.

**Word check:** *systemd unit* = a file that tells the server how to run a program.
*timer* = the unit that says how often to run it.

## What they would do

- `sca-controller.service` runs the dispatcher once, as the `sceyewear` service account.
- `sca-controller.timer` fires that service every 10 minutes.

## Enabling them later — needs approval first

Do not run these commands until ChatGPT has passed the audit and Francis has approved
unattended execution.

```bash
sudo install -m 644 sca-controller.service sca-controller.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now sca-controller.timer
```

Turning it off again:

```bash
sudo systemctl disable --now sca-controller.timer
```

The HOLD switch works whether or not the timer is running:

```bash
sudo -u sceyewear /opt/sca-controller/bin/sca-controllerctl hold "paused by Francis"
```
