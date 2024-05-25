# Dotfiles

This repository contains my personal configuration files (dotfiles) for macOS. 

## Usage

1. Clone this repo with git into `$HOME/dotfiles`
2. `cd` into this repo
3. Run `setup.sh` to set up the system and install necessary packages

The `setup.sh` script performs the following operations:

- Shows hidden files in Finder
- Checks if Homebrew is installed, installs if not
- Installs all packages from Brewfile
- Checks if SDKMAN! is installed, installs if not
- Removes existing .zshrc and adopts new configurations
- Sets up git configurations
- Sources .zshrc

The `backup.sh` script dumps the current Homebrew packages into a Brewfile.
