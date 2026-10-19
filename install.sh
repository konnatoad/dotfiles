#!/bin/bash
# fresh arch install -> this setup. safe to re-run.
# usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/konnatoad/dotfiles/main/install.sh)"
set -euo pipefail

src="$HOME/.local/share/chezmoi"

log() { printf '\033[1;34m::\033[0m %s\n' "$1"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run as your user, not root"

# steam and the lib32 packages live in multilib
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    log "enabling multilib"
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
fi

log "installing base tools"
sudo pacman -Syu --needed --noconfirm git base-devel chezmoi

if ! command -v yay >/dev/null; then
    log "installing yay"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
fi

if [[ -d "$src/.git" ]]; then
    log "updating dotfiles"
    chezmoi git -- pull --ff-only
else
    log "cloning dotfiles"
    chezmoi init konnatoad
fi

log "installing packages"
yay -S --needed --noconfirm --answerdiff None --answerclean None - < "$src/setup/packages.txt" \
    || die "package install failed, fix the list in $src/setup/packages.txt and re-run"

log "applying dotfiles"
chezmoi apply

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
    [[ -d "$plugins/${repo#*/}" ]] || git clone --depth 1 "https://github.com/$repo" "$plugins/${repo#*/}"
done

rustup toolchain list | grep -q . || rustup default stable

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]]; then
    log "setting zsh as login shell"
    chsh -s /usr/bin/zsh
fi

log "done, log out and back in"
