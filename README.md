# dotfiles

Dotfiles for my current Arch Linux setup, managed with [chezmoi](https://www.chezmoi.io).

Configuration includes:

- Zsh (with autosuggestions & syntax highlighting)
- Starship prompt
- Hyprland, Waybar, Rofi
- Neovim (LazyVim-based)
- Spicetify, Vesktop theming
- Modified `custom_fi` keymap for my ansi layout kb to include `less`, `greater` and `bar` under `AltGr + comma`, `AltGr + dot`, and `AltGr + dash`

---

## Install

### Only apply dotfiles

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply konnatoad
```

### Full setup (dotfiles + tools)

```bash
sh -c "$(curl -sS https://raw.githubusercontent.com/konnatoad/dotfiles/main/install.sh)"
```
