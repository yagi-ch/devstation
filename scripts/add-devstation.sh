#!/usr/bin/env bash
set -e

BASE_DIR=${DEVSTATION_BASE_DIR:-/mnt/ssd/docker/appdata}

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      devstation — new instance       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Name
read -rp "  Dev name (e.g. yves, alice): " NAME
if [ -z "$NAME" ]; then echo "Name cannot be empty."; exit 1; fi

# SSH port — suggest next available
SUGGESTED_PORT=2222
while ss -tlnH "sport = :$SUGGESTED_PORT" 2>/dev/null | grep -q .; do
  SUGGESTED_PORT=$((SUGGESTED_PORT + 1))
done
read -rp "  SSH port [$SUGGESTED_PORT]: " PORT
PORT=${PORT:-$SUGGESTED_PORT}

# Public key
echo ""
echo "  ── Public key ──────────────────────────────────────────"
echo "  The new dev should run this on their machine:"
echo ""
echo "    cat ~/.ssh/id_ed25519.pub"
echo "    # or: cat ~/.ssh/id_rsa.pub"
echo "    # or: cat ~/.ssh/id_ed25519_work.pub"
echo ""
echo "  If they don't have a key yet:"
echo ""
echo "    ssh-keygen -t ed25519 -C \"name@email.com\""
echo "    cat ~/.ssh/id_ed25519.pub"
echo ""
echo "  ────────────────────────────────────────────────────────"
read -rp "  Paste public key here: " PUBKEY
if [ -z "$PUBKEY" ]; then echo "Public key cannot be empty."; exit 1; fi

# Setup
CONTAINER="devstation-$NAME"
HOME_DIR="$BASE_DIR/$CONTAINER/home"
WG_DIR="$BASE_DIR/$CONTAINER/wireguard"
SSH_DIR="$HOME_DIR/dev/.ssh"

echo ""
echo "  → Creating directories..."
sudo mkdir -p "$SSH_DIR" "$WG_DIR"
sudo chmod 700 "$SSH_DIR"
echo "$PUBKEY" | sudo tee "$SSH_DIR/authorized_keys" > /dev/null
sudo chmod 600 "$SSH_DIR/authorized_keys"
echo "  ✓ $SSH_DIR"

HOST_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              Portainer — Environment variables           ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  %-20s  %-35s║\n" "CONTAINER_NAME" "$CONTAINER"
printf "║  %-20s  %-35s║\n" "SSH_PORT" "$PORT"
printf "║  %-20s  %-35s║\n" "HOME_DIR" "$HOME_DIR"
printf "║  %-20s  %-35s║\n" "WIREGUARD_DIR" "$WG_DIR"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Connect:  ssh -p $PORT dev@$HOST_IP"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
