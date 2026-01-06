#!/bin/bash
set -e

echo "🚀 Starting Coder workspace dotfiles installation..."

# 1. Prepare .config directory
echo "📦 Copying configuration files..."
mkdir -p "$HOME/.config/omf"
if [ -d ".config" ]; then
  cp -a .config/. "$HOME/.config/"
  echo "✅ Copied .config directory"
fi

# 2. Configure the OMF Bundle
# This tells OMF exactly what to install as soon as it starts
echo "plus lolfish" > "$HOME/.config/omf/bundle"
echo "✨ Added lolfish to OMF bundle"

# 3. Setup Fish Shell
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
FISH_PATH=$(command -v fish)

if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
  echo "🔧 Attempting to change shell to fish..."
  # Use sudo -n (non-interactive) to fail gracefully if a password is required
  if ! grep -q "$FISH_PATH" /etc/shells; then
    sudo tee -a /etc/shells <<< "$FISH_PATH"
  fi
  sudo chsh -s "$FISH_PATH" "$USER" || echo "⚠️ Could not change shell automatically. Please run 'chsh -s $(which fish)' manually."
else
  echo "✅ Fish is already the default shell."
fi

# 4. Install Oh My Fish (only if not already installed)
if [ ! -f "$HOME/.local/share/omf/init.fish" ]; then
  echo "🔧 Installing Oh My Fish..."
  curl -s https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install_omf
  fish install_omf --path=~/.local/share/omf --config=~/.config/omf --noninteractive
  rm install_omf
else
  echo "✅ Oh My Fish is already installed. Skipping installation."
  # Even if OMF is installed, we can force a reload of the bundle
  fish -c "omf reload"
fi

echo "🎉 Setup complete!"