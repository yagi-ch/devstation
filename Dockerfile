FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Bootstrap curl/gpg, puis ajout des dépôts externes en un seul layer
RUN apt update && apt install -y --no-install-recommends curl gnupg ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /usr/share/keyrings /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list

# Tous les paquets en un seul apt update
RUN apt update && apt install -y \
    openssh-server \
    sudo \
    rsync \
    git \
    curl wget \
    vim nano \
    htop tmux \
    python3 python3-pip python3-venv python3-dev pipx \
    build-essential make \
    zsh \
    unzip \
    jq \
    tree \
    ripgrep \
    fd-find \
    fzf \
    bat \
    net-tools \
    iputils-ping \
    dnsutils \
    traceroute \
    lsof \
    wireguard-tools \
    iptables \
    resolvconf \
    gh \
    docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Créer l'utilisateur dev — mot de passe désactivé (auth SSH par clé uniquement)
RUN useradd -m -s /bin/bash dev && \
    passwd -l dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Config SSH — auth par clé uniquement
RUN mkdir /var/run/sshd && \
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    rm -f /etc/ssh/sshd_config.d/*cloud-init* 2>/dev/null || true && \
    echo 'PasswordAuthentication no' > /etc/ssh/sshd_config.d/99-hardening.conf && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config.d/99-hardening.conf

USER dev
WORKDIR /home/dev

# nvm + Node.js
ENV NVM_DIR=/home/dev/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install 20 && \
    nvm install 22 && \
    nvm alias default 22 && \
    nvm use default && \
    npm install -g @anthropic-ai/claude-code pnpm yarn

RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

# uv (gestionnaire Python moderne)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Poetry et ruff via pipx
RUN pipx install poetry && \
    pipx install ruff && \
    pipx ensurepath

# pyenv pour gérer plusieurs versions Python
RUN curl https://pyenv.run | bash && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Alias utiles
RUN echo 'alias ll="ls -lah"' >> ~/.bashrc && \
    echo 'alias cat="batcat"' >> ~/.bashrc && \
    echo 'alias fd="fdfind"' >> ~/.bashrc

USER root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
