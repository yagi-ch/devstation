#!/usr/bin/env bash
set -e

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         devstation — git setup       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Identity
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

read -rp "  Full name [${CURRENT_NAME:-Your Name}]: " NAME
NAME=${NAME:-$CURRENT_NAME}

read -rp "  Email [${CURRENT_EMAIL:-you@example.com}]: " EMAIL
EMAIL=${EMAIL:-$CURRENT_EMAIL}

git config --global user.name "$NAME"
git config --global user.email "$EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf input

echo "  ✓ Git identity configured"

# SSH key
KEY="$HOME/.ssh/id_ed25519"
if [ -f "$KEY" ]; then
  echo ""
  echo "  ℹ SSH key already exists: $KEY"
else
  echo ""
  read -rp "  Generate SSH key for GitHub? [Y/n]: " GEN
  if [[ ! "$GEN" =~ ^[Nn]$ ]]; then
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
    echo "  ✓ Key generated: $KEY"
  fi
fi

# Show public key
if [ -f "${KEY}.pub" ]; then
  echo ""
  echo "  ── Add this key to GitHub ────────────────────────────────"
  echo "  github.com → Settings → SSH keys → New SSH key"
  echo ""
  echo "  $(cat "${KEY}.pub")"
  echo "  ────────────────────────────────────────────────────────"
  echo ""
  read -rp "  Press Enter once you've added the key to GitHub..."

  # Test connection
  echo ""
  echo "  → Testing GitHub connection..."
  if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    GH_USER=$(ssh -T git@github.com 2>&1 | grep -o 'Hi [^!]*' | cut -d' ' -f2)
    echo "  ✓ Connected as: $GH_USER"
  else
    echo "  ✗ Could not connect — check that the key was added to GitHub"
  fi
fi

echo ""
echo "  ── Git config summary ──────────────────────────────────"
echo "  name   : $(git config --global user.name)"
echo "  email  : $(git config --global user.email)"
echo "  branch : $(git config --global init.defaultBranch)"
echo "  ────────────────────────────────────────────────────────"
echo ""
echo "  Run again anytime to update."
echo ""
