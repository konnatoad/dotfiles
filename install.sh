#!/bin/bash

error() {
  echo "[ERROR] $1"
  exit 1
}

# Install chezmoi, git, yay, and zsh if missing
REQUIRED_PKGS=("git" "base-devel" "chezmoi")
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! pacman -Q "$pkg" &>/dev/null; then
    sudo pacman -S --needed "$pkg" || error "Failed to install $pkg"
  fi
done

if ! command -v zsh &>/dev/null; then
  sudo pacman -S --needed zsh || error "Failed to install zsh"
else
  echo "zsh already installed, skipping."
fi

# Install yay if missing
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay-bin.git || error "Failed to clone yay"
  cd yay-bin && makepkg -si || error "Failed to build yay"
  cd .. && rm -rf yay-bin
else
  echo "yay already installed, skipping."
fi

# Initialize chezmoi
chezmoi init github.com/konnatoad/dotfiles || error "Failed to init chezmoi"

# Install Starship
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh || error "Failed to install Starship"
else
  echo "starship already installed, skipping."
fi

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
if [[ -f ~/.local/share/chezmoi/setup/pacman_packages.txt ]]; then
  echo "Installing pacman packages..."
  xargs -r sudo pacman -S --needed <~/.local/share/chezmoi/setup/pacman_packages.txt || error "Failed to install pacman packages"
fi

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
