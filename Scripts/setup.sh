#!/bin/bash

set -euo pipefail

LOG_FILE="$HOME/install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "▶ Arch + Hyprland Setup Starting..."
echo "📅 $(date)"
echo "📄 Logging to $LOG_FILE"

# Ask user which GPU drivers to install
echo -n "Which GPU driver do you want to install? [amd/nvidia/skip]: "
read -r GPU_CHOICE

if [[ "$GPU_CHOICE" == "amd" ]]; then
  echo "🛠 Installing AMD GPU drivers..."
  sudo pacman -S --needed mesa lib32-mesa vulkan-radeon
elif [[ "$GPU_CHOICE" == "nvidia" ]]; then
  echo "🛠 Installing NVIDIA GPU drivers..."
  sudo pacman -S --needed nvidia nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader
else
  echo "⚠ Skipping GPU driver installation."
fi

echo "▶ Updating system..."
sudo pacman -Syu --noconfirm

echo "▶ Installing Bluetooth & Printing support..."
sudo pacman -S --needed bluez bluez-utils cups system-config-printer print-manager
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now cups.service

echo "▶ Installing general applications..."
sudo pacman -S --needed \
  firefox kitty neovim thunar steam fastfetch wine discord \
  7zip ark spectacle timeshift wget git viewnior \
  lm_sensors btop rocm-smi-lib hyprland

echo "▶ Installing yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay
  makepkg -si --noconfirm
  cd ..
  rm -rf ~/yay
else
  echo "✔ yay is already installed."
fi

echo "▶ Installing AUR packages..."
yay -S --needed coolercontrol mpvpaper catppuccin-cursors-mocha youtube-music-bin

echo "▶ Running sensors-detect (non-interactive)..."
sudo sensors-detect --auto || true

echo "▶ Installing Hyprland environment components..."
sudo pacman -S --needed \
  wofi ttf-font-awesome swaync hyprshot hyprlock hypridle \
  wireplumber pavucontrol xdg-desktop-portal-hyprland hyprpolkitagent \
  playerctl blueman networkmanager network-manager-applet cliphist waybar mpv swww cava

sudo systemctl enable --now NetworkManager
systemctl --user enable --now waybar.service

echo "▶ Cloning and applying dotfiles from GitHub..."
git clone https://github.com/steve-conrad/Dot-Files.git ~/Dot-Files
mkdir -p ~/.config
cp -r ~/Dot-Files/Arch/.config/* ~/.config/

chmod +x ~/.config/hypr/detect_borderless.sh 2>/dev/null || echo "(detect_borderless.sh not found, skipping)"

echo "▶ Setting Thunar as default file manager..."
xdg-mime default thunar.desktop inode/directory

echo "▶ Configuring Hyprland autologin..."

BASH_PROFILE="$HOME/.bash_profile"
if ! grep -q 'uwsm check may-start' "$BASH_PROFILE" 2>/dev/null; then
  echo "Adding Hyprland autostart to .bash_profile..."
  cat <<EOF >> "$BASH_PROFILE"

# Hyprland autostart
if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
EOF
fi

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF

echo "✅ Setup complete! Reboot to launch Hyprland."

