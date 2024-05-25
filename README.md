# Setup Script Documentation

This README file provides a detailed explanation of each step in the `setup.sh` script. This script is used to set up a MacOS system with the necessary configurations and tools.

## Show Hidden Files in Finder

The script starts by setting the MacOS Finder to show hidden files. This is done using the `defaults write com.apple.finder AppleShowAllFiles YES` command.

## Homebrew Installation

The script then checks if Homebrew is installed on the system. If not, it installs Homebrew. Homebrew is a package manager for MacOS, used to install other software.

## Brewfile Package Installation

Next, the script installs all packages listed in the `Brewfile` using the `brew bundle --file="Brewfile"` command.

## SDKMAN! Installation

The script checks if SDKMAN! is installed. If not, it installs SDKMAN!. SDKMAN! is a tool for managing parallel versions of multiple Software Development Kits on most Unix-based systems.

## .zshrc Configuration

The script removes the existing `.zshrc` file and adopts new configurations. The `.zshrc` file is a shell script that runs whenever you start a new Zsh shell session.

## Git Configuration

The script sets up global Git configurations and ignores specified in `.gitignore`.

## Source .zshrc

Finally, the script reloads the `.zshrc` file, applying the new configurations. This is done using the `source ~/.zshrc` command.

At the end of the script, a message is printed to the console indicating that the installation of dotfiles is complete.