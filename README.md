# dev-tools-container

A self-contained Ubuntu 24.04 development environment accessible over SSH. Designed for remote work — connect from anywhere, pick up where you left off.

## What's included

| Category | Tools |
|---|---|
| Shell | zsh, bash, tmux, fzf, ripgrep, fd, bat, tree |
| Editors | vim, nano |
| Git | git, GitHub CLI (`gh`) |
| Node.js | nvm, Node 20 & 22 (default), pnpm, yarn, Claude Code |
| Python | python3, pyenv, uv, pipx, poetry, ruff |
| Docker | docker CLI + compose plugin (talks to the host socket) |
| Network | WireGuard, iptables, net-tools, ping, dig, traceroute, lsof |

SSH is the only entry point. Password authentication is disabled — key only.

## Build

```bash
docker build -t dev-tools .
```

## Run

### With Docker Compose (recommended)

Copy `.env.example` to `.env` and adjust the values:

```bash
cp .env.example .env
docker compose up -d
```

| Variable | Default | Description |
|---|---|---|
| `SSH_PORT` | `2222` | Host port forwarded to SSH inside the container |
| `AUTHORIZED_KEYS` | `~/.ssh/authorized_keys` | Path to your public key file on the host |
| `PROJECTS_DIR` | `~/projects` | Host directory mounted at `/home/dev/projects` |

### With Docker CLI

```bash
docker run -d \
  --name dev \
  -p 2222:22 \
  -v ~/.ssh/authorized_keys:/home/dev/.ssh/authorized_keys:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  dev-tools
```

| Flag | Why |
|---|---|
| `-p 2222:22` | Expose SSH on host port 2222 (change as needed) |
| `authorized_keys` volume | Inject your public key without baking it into the image |
| `docker.sock` volume | Let the container's Docker CLI talk to the host daemon |
| `NET_ADMIN` + `SYS_MODULE` | Required for WireGuard to create/manage network interfaces |
| `src_valid_mark` sysctl | Required for WireGuard routing rules to work correctly |

> **Note:** WireGuard runs in the container but relies on the kernel module of the host. Any kernel >= 5.6 has it built in, so no extra setup is needed on modern hosts.

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

## Persist your work

The container is stateless by default. Mount a volume to keep your projects across restarts:

```bash
docker run -d \
  ...
  -v ~/projects:/home/dev/projects \
  dev-tools
```

## WireGuard

Place your config in `/home/dev/wg0.conf` (or mount it as a volume), then:

```bash
sudo wg-quick up /home/dev/wg0.conf
```

The container has all required dependencies (`wireguard-tools`, `iptables`, `resolvconf`).
