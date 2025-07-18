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

# Install Rust (if missing)
if ! command -v cargo &>/dev/null; then
  curl https://sh.rustup.rs -sSf | sh || error "Failed to install Rust"
fi

# Source Rust env
source "$HOME/.cargo/env"
source ~/.zprofile

# Apply dotfiles
chezmoi apply -R || error "Failed to apply dotfiles"

# Install pacman packages
yes | sudo pacman -S --needed --noconfirm - <~/.local/share/chezmoi/setup/pacman_packages.txt

# Install AUR packages
yes | yay -S --needed --noconfirm --answerdiff=None --answerclean=None - <~/.local/share/chezmoi/setup/aur_packages.txt

# oh-my-zsh and plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ""
else
  echo "oh-my-zsh already present, skipping."
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already present, skipping."
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting already present, skipping."
fi

# Set Zsh as the default shell
if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
  chsh -s /usr/bin/zsh || error "Failed to set Zsh as default shell"
else
  echo "Zsh already set as default shell."
fi

echo "All done."
