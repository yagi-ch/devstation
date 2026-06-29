#!/bin/bash
set -e

# On first mount, /home/dev will be empty — bootstrap it from the image snapshot.
# On subsequent starts, the user's home already exists — skip to avoid overwriting.
if [ ! -f /home/dev/.bootstrapped ]; then
  echo "[devstation] First start — bootstrapping home directory..."
  cp -rn /opt/dev-home/. /home/dev/
  chown -R dev:dev /home/dev
  touch /home/dev/.bootstrapped
  echo "[devstation] Done."
fi

exec /usr/sbin/sshd -D
