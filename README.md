# devstation

A self-hosted remote development environment accessible over SSH. Works with VS Code Remote SSH, JetBrains Gateway, or any SSH-capable editor. Connect from anywhere, pick up where you left off.

## What's included

| Category | Tools |
|---|---|
| Shell | zsh, bash, tmux, fzf, ripgrep, fd, bat, tree |
| Editors | vim, nano |
| Git | git, GitHub CLI (`gh`) |
| Node.js | nvm, Node 20 & 22 (default), pnpm, yarn, Claude Code |
| Python | python3, pyenv, uv, pipx, poetry, ruff |
| GPU | CUDA 12.5 runtime (optional — works without GPU too) |
| Network | WireGuard, iptables, net-tools, ping, dig, traceroute, lsof |

SSH is the only entry point. Password authentication is disabled — key only.

## Build

The image is automatically built and pushed to Docker Hub on every push to `main` via GitHub Actions.

Pull the latest image:

```bash
docker pull yagich/dev-tools-container:latest
```

Or build locally:

```bash
docker build -t dev-tools-container .
```

## Run

Copy `.env.example` to `.env` and adjust the paths:

```bash
cp .env.example .env
```

**Without GPU:**

```bash
docker compose up -d
```

**With NVIDIA GPU:**

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

`docker-compose.gpu.yml` adds `runtime: nvidia`, `shm_size: 8gb`, and the GPU device reservation. It requires [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) on the host.

### Variables

| Variable | Default | Description |
|---|---|---|
| `SSH_PORT` | `2222` | Host port mapped to SSH |
| `HOME_DIR` | `./data/home` | Host path mounted as `/home` inside the container |
| `WIREGUARD_DIR` | `./data/wireguard` | Host path mounted as `/etc/wireguard` |
| `DOCKER_IMAGE` | `yagich/dev-tools-container:latest` | Override to use a custom image |

> **First run:** make sure `$HOME_DIR/dev/.ssh/authorized_keys` exists with your public key before starting the container.

## Connect

```bash
ssh -p 2222 dev@<host-ip>
```

Or add this to your `~/.ssh/config`:

```
Host devbox
  HostName <host-ip>
  Port 2222
  User dev
  IdentityFile ~/.ssh/id_ed25519
```

Then just `ssh devbox`.

## WireGuard

Drop your config files in `$WIREGUARD_DIR` on the host (they appear at `/etc/wireguard/` inside the container), then:

```bash
sudo wg-quick up wg0
```

Required dependencies (`wireguard-tools`, `iptables`, `resolvconf`) and the `tun` device are already set up.
