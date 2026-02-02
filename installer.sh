#!/usr/bin/env bash

# ==========================================
# Kenso Minimal Installer
# ==========================================

set -euo pipefail

# -----------------------------
# Paths
# -----------------------------
BASE_DIR="$HOME/hyprkenso"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d%H%M)"

# Required packages (minimal)
PACKAGES=(
  downgrade
  hyprland
  waybar
  rofi
  neovim
  swaync
  python
  matugen-bin
  wlogout
  swww
  swappy
  tmux
  thunar
  brave-bin
  zsh
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
  zsh-theme-powerlevel10k-git
  cava
  kitty
  yazi
  fastfetch
  rmpc-git
  quickshell-git
  mpd
)

# Dotfiles repos
REPOS=(
  "https://github.com/aadritobasu/kenso-matugen"
  "https://github.com/aadritobasu/kenso-hypr"
  "https://github.com/aadritobasu/kenso-nvim"
  "https://github.com/aadritobasu/kenso-rofi"
  "https://github.com/aadritobasu/kenso-quickshell"
  "https://github.com/aadritobasu/kenso-swaync"
  "https://github.com/aadritobasu/kenso-waybar"
  "https://github.com/aadritobasu/kenso-icon-themes"
  "https://github.com/aadritobasu/kenso-spicetify"
  "https://github.com/aadritobasu/kenso-wlogout"
  "https://github.com/aadritobasu/wallpapers"
  "https://github.com/aadritobasu/kenso-fastfetch-config"
)

# -----------------------------
# Ensure yay exists
# -----------------------------
if ! command -v yay &>/dev/null; then
  echo "❌ yay not found. Install yay first!"
  exit 1
fi

# -----------------------------
# 1️⃣ Install minimal packages
# -----------------------------
echo "📦 Installing required packages..."
yay -Syu --noconfirm

for pkg in "${PACKAGES[@]}"; do
  if yay -Q "$pkg" &>/dev/null; then
    echo "✔ $pkg already installed"
  else
    echo "📦 Installing $pkg..."
    yay -S --noconfirm --needed "$pkg"
  fi
done

# -----------------------------
# 2️⃣ Clone dotfiles into ~/hyprkenso
# -----------------------------
echo "📥 Cloning dotfiles..."
mkdir -p "$BASE_DIR"

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  target="$BASE_DIR/$name"

  if [[ -d "$target/.git" ]]; then
    echo "🔄 Updating $name"
    git -C "$target" pull
  else
    echo "📥 Cloning $name"
    git clone "$repo" "$target"
  fi
done

# -----------------------------
# 3️⃣ Backup and copy configs
# -----------------------------
echo "🗄 Backing up existing configs..."
mkdir -p "$BACKUP_DIR"

backup_and_copy() {
  local src="$1"
  local dest="$2"
  if [[ -d "$dest" ]]; then
    mv "$dest" "$BACKUP_DIR/"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -r "$src" "$dest"
  echo "→ Copied $(basename "$src") → $dest"
}

echo "📂 Copying dotfiles to ~/.config..."
backup_and_copy "$BASE_DIR/kenso-hypr"        "$HOME/.config/hypr"
backup_and_copy "$BASE_DIR/kenso-nvim"        "$HOME/.config/nvim"
backup_and_copy "$BASE_DIR/kenso-rofi"        "$HOME/.config/rofi"
backup_and_copy "$BASE_DIR/kenso-waybar"      "$HOME/.config/waybar"
backup_and_copy "$BASE_DIR/kenso-swaync"      "$HOME/.config/swaync"
backup_and_copy "$BASE_DIR/kenso-wlogout"     "$HOME/.config/wlogout"
backup_and_copy "$BASE_DIR/kenso-quickshell"  "$HOME/.config/quickshell"
backup_and_copy "$BASE_DIR/kenso-spicetify"	  "$HOME/.config/spicetify"
backup_and_copy "$BASE_DIR/kenso-matugen"     "$HOME/.config"

# Wallpapers
mkdir -p "$HOME/Pictures"
backup_and_copy "$BASE_DIR/wallpapers" "$HOME/Pictures/wallpapers"

# -----------------------------
# 4️⃣ Copy icon themes
# -----------------------------
echo "🎨 Copying icon themes..."
mkdir -p "$HOME/.local/share/icons"
cp -r "$BASE_DIR/kenso-icon-themes"/* "$HOME/.local/share/icons/"
echo "✔ Icons copied to ~/.local/share/icons"

# -----------------------------
# 5️⃣ Install fastfetch
# -----------------------------
echo "⚡ Installing fastfetch..."
cd "$BASE_DIR/kenso-fastfetch-config"
chmod +x install.sh
./install.sh
cd "$HOME"

# -----------------------------
# 6️⃣ Enable/start MPD
# -----------------------------
echo "🎵 Enabling and starting MPD..."
sudo systemctl enable --now mpd.service

echo "🎉 Kenso minimal setup complete!"
echo "📁 Dotfiles cloned to $BASE_DIR"
echo "🗄 Backup of old configs at $BACKUP_DIR"

# -----------------------------
# 7️⃣ Install Powerlevel10k
# -----------------------------
echo "🌟 Installing Powerlevel10k..."

# Zsh config directory
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Ensure Oh My Zsh exists
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "❌ Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Clone Powerlevel10k if missing
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    echo "✔ Powerlevel10k cloned"
else
    echo "✔ Powerlevel10k already installed"
fi

# Ensure ZSH_THEME is set in .zshrc
if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    echo "✔ ZSH_THEME set to Powerlevel10k in .zshrc"
fi

echo "✅ Powerlevel10k installation complete!"
# -----------------------------
# 9️⃣ Copy Zsh config files to home (~)
# -----------------------------
echo "📂 Copying Zsh configs to ~"

ZSH_SRC="$BASE_DIR/kenso-zsh"  # replace with the actual folder name in your repo

if [[ -d "$ZSH_SRC" ]]; then
    for file in "$ZSH_SRC"/*; do
        filename=$(basename "$file")
        # Backup existing file if present
        if [[ -f "$HOME/$filename" ]]; then
            mkdir -p "$BACKUP_DIR"
            mv "$HOME/$filename" "$BACKUP_DIR/"
            echo "🗄 Backed up existing $filename"
        fi
        cp "$file" "$HOME/"
        echo "→ Copied $filename to ~"
    done
else
    echo "⚠ Zsh config folder not found at $ZSH_SRC"
fi


# -----------------------------
# 8️⃣ Change default shell to zsh
# -----------------------------
echo "🌀 Changing default shell to zsh..."

# Check current shell
CURRENT_SHELL=$(getent passwd $USER | cut -d: -f7)

if [[ "$CURRENT_SHELL" != "$(which zsh)" ]]; then
    echo "🔄 Changing shell from $CURRENT_SHELL to $(which zsh)"
    chsh -s "$(which zsh)"
    echo "✔ Default shell changed to zsh"
else
    echo "✔ Default shell is already zsh"
fi
# -----------------------------
# Force downgrade Hyprland to 0.52.2
# -----------------------------
echo "⬇ Forcing Hyprland downgrade to 0.52.2"

# Ensure downgrade tool exists
if ! command -v downgrade &>/dev/null; then
  echo "📦 Installing downgrade tool..."
  yay -S --noconfirm downgrade
fi

# Downgrade Hyprland non-interactively
sudo downgrade hyprland --version 0.52.2 --yes

# Lock Hyprland to prevent upgrades
PACMAN_CONF="/etc/pacman.conf"
if ! grep -q "^IgnorePkg.*hyprland" "$PACMAN_CONF"; then
  echo "🔒 Locking Hyprland version in pacman.conf"
  sudo sed -i '/^\[options\]/a IgnorePkg = hyprland' "$PACMAN_CONF"
fi

echo "✔ Hyprland locked at 0.52.2"
