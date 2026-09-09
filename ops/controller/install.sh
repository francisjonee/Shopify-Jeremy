#!/usr/bin/env bash
#
# Install the SCA task controller onto the VPS.
#
# Creates the controller home outside this repository, copies the two scripts in,
# and leaves the controller in dry-run mode. Run as root. Installs nothing that
# executes on a schedule — see systemd/README before enabling unattended runs.

set -euo pipefail

SCA_HOME="${SCA_HOME:-/opt/sca-controller}"
SCA_USER="${SCA_USER:-sceyewear}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
id "$SCA_USER" >/dev/null 2>&1 || { echo "service account $SCA_USER does not exist" >&2; exit 1; }

install -d -o "$SCA_USER" -g "$SCA_USER" -m 755 "$SCA_HOME" "$SCA_HOME/bin" "$SCA_HOME/logs" "$SCA_HOME/logs/runs"
install -d -o "$SCA_USER" -g "$SCA_USER" -m 750 "$SCA_HOME/state" "$SCA_HOME/run"
install -d -o "$SCA_USER" -g "$SCA_USER" -m 700 "$SCA_HOME/config"

install -o "$SCA_USER" -g "$SCA_USER" -m 750 "$SRC/sca-controller"    "$SCA_HOME/bin/sca-controller"
install -o "$SCA_USER" -g "$SCA_USER" -m 750 "$SRC/sca-controllerctl" "$SCA_HOME/bin/sca-controllerctl"

if [ ! -f "$SCA_HOME/config/controller.env" ]; then
  install -o "$SCA_USER" -g "$SCA_USER" -m 600 "$SRC/controller.env.example" "$SCA_HOME/config/controller.env"
  echo "created $SCA_HOME/config/controller.env from the example — fill it in on the VPS"
fi

echo "installed. Check it with:"
echo "  sudo -u $SCA_USER $SCA_HOME/bin/sca-controllerctl status"
