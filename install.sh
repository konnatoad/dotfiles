#!/bin/bash

error() {
  echo "[ERROR] $1"
  exit 1
}

# install chezmoi, git, yay and zsh
sudo pacman -S --needed git base-devel chezmoi zsh && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

# Initialize chezmoi
chezmoi init github.com/konnatoad/dotfiles || error "Failed to init chezmoi"

# install starship
curl -sS https://starship.rs/install.sh | sh

# Apply dotfiles
chezmoi apply -R || error "Failed to apply dotfiles"

# Install the custom keyboard layout
sudo cp ~/.local/share/chezmoi/setup/custom_fi /usr/share/X11/xkb/symbols/

# Install AUR packages
yes | yay -S --needed --noconfirm --answerdiff=None --answerclean=None - <~/.local/share/chezmoi/setup/aur_packages.txt

# install ohmyzsh and plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Getting ohmyz.sh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ""
  echo "✓ oh-my-zsh installed successfully."
else
  echo ".oh-my-zsh already found, skipping."
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  echo "Getting zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
  echo "zsh-autosuggestions already present, skipping."
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  echo "Getting zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
  echo "zsh-syntax-highlighting already present, skipping."
fi

# set zsh as shell
chsh -s /usr/bin/zsh

if ! command -v cargo &>/dev/null; then
  curl https://sh.rustup.rs/ -sSf | sh
fi

source $HOME/.cargo/env

echo "All done."
