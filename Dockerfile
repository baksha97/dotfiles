FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Minimal bootstrap deps — setup-linux.sh installs the rest via apt
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    fontconfig \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Run as non-root so $SUDO resolves correctly in setup-linux.sh
RUN useradd -m -s /bin/zsh dotfiles && \
    echo "dotfiles ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dotfiles
WORKDIR /home/dotfiles

COPY --chown=dotfiles:dotfiles . dotfiles/

WORKDIR /home/dotfiles/dotfiles

RUN ./main.sh setup headless
