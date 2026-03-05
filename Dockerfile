FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# Prevents the Homebrew install script from prompting
ENV NONINTERACTIVE=1

# Homebrew dependencies + zsh + fontconfig (for fc-cache)
RUN apt-get update && apt-get install -y \
    build-essential \
    procps \
    curl \
    file \
    git \
    zsh \
    fontconfig \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Homebrew refuses to run as root
RUN useradd -m -s /bin/zsh dotfiles && \
    echo "dotfiles ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dotfiles
WORKDIR /home/dotfiles

COPY --chown=dotfiles:dotfiles . dotfiles/

WORKDIR /home/dotfiles/dotfiles

RUN ./main.sh setup headless
