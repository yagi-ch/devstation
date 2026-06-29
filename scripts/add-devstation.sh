#!/usr/bin/env bash
# Usage: ./scripts/add-devstation.sh <name> <ssh-port> "<public-key>"
# Example: ./scripts/add-devstation.sh yves 2222 "ssh-ed25519 AAAA..."
set -e

NAME=$1
PORT=$2
PUBKEY=$3
BASE_DIR=${DEVSTATION_BASE_DIR:-/mnt/ssd/docker/appdata}

if [ -z "$NAME" ] || [ -z "$PORT" ] || [ -z "$PUBKEY" ]; then
  echo "Usage: $0 <name> <ssh-port> \"<public-key>\""
  echo "  DEVSTATION_BASE_DIR (optional, default: /mnt/ssd/docker/appdata)"
  exit 1
fi

CONTAINER="devstation-$NAME"
HOME_DIR="$BASE_DIR/$CONTAINER/home"
WG_DIR="$BASE_DIR/$CONTAINER/wireguard"
SSH_DIR="$HOME_DIR/dev/.ssh"

echo "→ Creating directories..."
sudo mkdir -p "$SSH_DIR" "$WG_DIR"
sudo chmod 700 "$SSH_DIR"
echo "$PUBKEY" | sudo tee "$SSH_DIR/authorized_keys" > /dev/null
sudo chmod 600 "$SSH_DIR/authorized_keys"
echo "✓ Done: $SSH_DIR"

echo ""
echo "─────────────────────────────────────────────"
echo "  Portainer stack → Environment variables"
echo "─────────────────────────────────────────────"
echo "  CONTAINER_NAME = $CONTAINER"
echo "  SSH_PORT       = $PORT"
echo "  HOME_DIR       = $HOME_DIR"
echo "  WIREGUARD_DIR  = $WG_DIR"
echo "─────────────────────────────────────────────"
echo ""
echo "→ Connect: ssh -p $PORT dev@<host-ip>"
