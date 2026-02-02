#!/usr/bin/env bash

# ==========================================
# Kenso Full Installer (COPY MODE)
# Packages + Dotfiles + Services
# ==========================================

set -euo pipefail

# ------------------------------------------
# Paths
# ------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_LIST="$SCRIPT_DIR/package-list.txt"

BASE_DIR="$HOME/hyprkenso"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d%H%M)"

# ------------------------------------------
# Sanity checks
# ------------------------------------------
if [[ ! -f "$PACKAGE_LIST" ]]; then
  echo "❌ package-list.txt not found"
  exit 1
fi

if ! command -v yay &>/dev/null; then
  echo "❌ yay not installed"
  exit 1
fi

# ------------------------------------------
# 1️⃣ Install packages using yay
# ------------------------------------------
echo "📦 Installing packages..."
yay -Syu --noconfirm

while IFS= read -r pkg || [[ -n "$pkg" ]]; do
  [[ -z "$pkg" ]] && continue
  [[ "$pkg" =~ ^# ]] && continue

  if yay -Q "$pkg" &>/dev/null; then
    echo "✔ $pkg already installed"
  else
    yay -S --noconfirm --needed "$pkg"
  fi
done < "$PACKAGE_LIST"

# ------------------------------------------
# 2️⃣ Clone dotfiles into ~/hyprkenso
# ------------------------------------------
echo "📥 Cloning dotfiles..."
mkdir -p "$BASE_DIR"

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
  "https://github.com/aadritobasu/kenso-fastfetch-config"
  "https://github.com/aadritobasu/wallpapers"
)

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  dest="$BASE_DIR/$name"

  if [[ -d "$dest/.git" ]]; then
    echo "🔄 Updating $name"
    git -C "$dest" pull
  else
    echo "📥 Cloning $name"
    git clone "$repo" "$dest"
  fi
done

# ------------------------------------------
# 3️⃣ Backup existing configs
# ------------------------------------------
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
  echo "→ Copied $(basename "$dest")"
}

# ------------------------------------------
# 4️⃣ Copy dotfiles into ~/.config
# ------------------------------------------
echo "📂 Copying configs..."

backup_and_copy "$BASE_DIR/kenso-hypr"        "$HOME/.config/hypr"
backup_and_copy "$BASE_DIR/kenso-nvim"        "$HOME/.config/nvim"
backup_and_copy "$BASE_DIR/kenso-rofi"        "$HOME/.config/rofi"
backup_and_copy "$BASE_DIR/kenso-waybar"      "$HOME/.config/waybar"
backup_and_copy "$BASE_DIR/kenso-swaync"      "$HOME/.config/swaync"
backup_and_copy "$BASE_DIR/kenso-wlogout"     "$HOME/.config/wlogout"
backup_and_copy "$BASE_DIR/kenso-quickshell"  "$HOME/.config/quickshell"
backup_and_copy "$BASE_DIR/kenso-matugen"     "$HOME/.config/matugen"
cd "$BASE_DIR/kenso-fastfetch-config"
chmod +x install.sh
./install.sh
cd ~
# Wallpapers
mkdir -p "$HOME/Pictures"
backup_and_copy "$BASE_DIR/wallpapers" "$HOME/Pictures/wallpapers"

# ------------------------------------------
# 5️⃣ Start & enable services
# ------------------------------------------
echo "🚀 Starting services..."

start_system() {
  sudo systemctl enable --now "$1" 2>/dev/null || true
}

start_user() {
  systemctl --user enable --now "$1" 2>/dev/null || true
}

# System services
start_system mpd.service
start_system bluetooth.service
start_system NetworkManager.service
start_system sddm.service
# User services
start_user pipewire.service
start_user pipewire-pulse.service
start_user wireplumber.service
start_user swaync.service

echo "🎉 Kenso setup complete!"
echo "📦 Dotfiles cloned in: $BASE_DIR"
echo "🗄 Backup stored at: $BACKUP_DIR"
