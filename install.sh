#!/bin/bash
set -e

echo "🚀 Starting Coder workspace dotfiles installation..."

# --------------------------------------------------------
# 1. Prepare .config directory
# --------------------------------------------------------
echo "📦 Copying configuration files..."
mkdir -p "$HOME/.config/omf"
if [ -d ".config" ]; then
  cp -a .config/. "$HOME/.config/"
  echo "✅ Copied .config directory"
fi

# --------------------------------------------------------
# 2. Setup Fish Shell
# --------------------------------------------------------
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

# --------------------------------------------------------
# 3. Install Oh My Fish & Set Theme
# --------------------------------------------------------
if [ ! -f "$HOME/.local/share/omf/init.fish" ]; then
  echo "🔧 Installing Oh My Fish..."
  curl -s https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install_omf
  fish install_omf --path=~/.local/share/omf --config=~/.config/omf --noninteractive
  rm install_omf
  echo "✅ Oh My Fish installed successfully."
else
  echo "✅ Oh My Fish is already installed."
  fish -c "omf reload"
fi

# --- NEW: Ensure Lambda theme is installed and set ---
echo "🎨 Setting theme to Lambda..."
fish -c "omf install lambda"
fish -c "omf theme lambda"
echo "✅ Theme set to Lambda."

# --------------------------------------------------------
# 4. Lazygit Setup
# --------------------------------------------------------
echo "--- Lazygit Setup ---"

if command -v lazygit &> /dev/null; then
    echo "Lazygit is already installed."
else
    echo "Lazygit not found. Attempting user-local installation..."
    
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$LOCAL_BIN"

    if command -v fish &> /dev/null; then
        fish -c "if not contains \"$LOCAL_BIN\" \$fish_user_paths; set -U fish_user_paths \$fish_user_paths \"$LOCAL_BIN\"; end"
        echo "Added $LOCAL_BIN to your Fish PATH for persistence."
    fi

    echo "Fetching latest Lazygit version..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -oP '"tag_name": "v\K[^"]*')
    
    if [ -z "$LAZYGIT_VERSION" ]; then
        echo "Error: Could not determine latest Lazygit version. Installation aborted."
    else
        echo "Found version: v$LAZYGIT_VERSION"
        LAZYGIT_DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        
        echo "Downloading Lazygit..."
        curl -Lo /tmp/lazygit.tar.gz "$LAZYGIT_DOWNLOAD_URL"
        
        echo "Extracting binary..."
        tar -xzf /tmp/lazygit.tar.gz -C /tmp
        
        if [ -f /tmp/lazygit ]; then
            install /tmp/lazygit "$LOCAL_BIN"
            echo "Lazygit installed successfully to $LOCAL_BIN/lazygit"
        else
            echo "Error: Lazygit binary not found after extraction."
        fi

        rm /tmp/lazygit.tar.gz /tmp/lazygit 2>/dev/null
    fi
fi

# --------------------------------------------------------
# 5. Install lolcat (NEW)
# --------------------------------------------------------
echo "--- Lolcat Setup ---"

# Check if lolcat is already installed
if command -v lolcat &> /dev/null; then
    echo "✅ lolcat is already installed."
else
    echo "🌈 Installing lolcat via Snap..."
    # Attempt install using user provided command
    if sudo snap install lolcat; then
        echo "✅ lolcat installed successfully."
    else
        echo "⚠️  Snap installation failed. Attempting apt fallback..."
        # Fallback for environments where snap might not be available (common in containers)
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y lolcat
            echo "✅ lolcat installed via apt."
        else
            echo "❌ Could not install lolcat. Snap failed and apt not found."
        fi
    fi
fi

# --------------------------------------------------------
# 6. Configure Aliases
# --------------------------------------------------------
echo "🔗 Configuring aliases..."
FISH_CONFIG="$HOME/.config/fish/config.fish"

# Ensure the config file exists
if [ ! -f "$FISH_CONFIG" ]; then
    mkdir -p "$(dirname "$FISH_CONFIG")"
    touch "$FISH_CONFIG"
fi

# Check if the alias already exists to avoid duplication
if ! grep -q 'alias gst' "$FISH_CONFIG"; then
    echo 'alias gst="git status | lolcat"' >> "$FISH_CONFIG"
    echo "✅ Alias 'gst' added for 'git status'."
    echo 'alias pwd="pwd | lolcat"' >> "$FISH_CONFIG"
    echo 'alias l="ls -a | lolcat"' >> "$FISH_CONFIG"
else
    echo "✅ Alias 'gst' already exists."
fi

echo "🎉 Setup complete!"
