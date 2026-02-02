#!/usr/bin/env bash
set -euo pipefail

REPO="cmgzone/gitucli"
INSTALL_DIR="$HOME/.gitu-cli"
BIN_DIR="$INSTALL_DIR/bin"
BIN_PATH="$BIN_DIR/gitu"

echo "Installing Gitu CLI..."

ARCH="$(uname -m)"
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  ASSET_NAME="gitu-macos-x64"
else
  ASSET_NAME="gitu-linux-x64"
fi

echo "Finding latest release..."
RELEASE_JSON="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")"
DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -Eo '"browser_download_url":\s*"[^"]+"' | cut -d'"' -f4 | grep "/$ASSET_NAME$" | head -n 1)"

if [ -z "$DOWNLOAD_URL" ]; then
  echo "No matching asset found for $ASSET_NAME"
  exit 1
fi

mkdir -p "$BIN_DIR"
TMP_PATH="$(mktemp)"
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_PATH"
chmod +x "$TMP_PATH"
mv "$TMP_PATH" "$BIN_PATH"

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  SHELL_NAME="$(basename "$SHELL")"
  if [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE="$HOME/.zshrc"
  else
    PROFILE="$HOME/.bashrc"
  fi
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$PROFILE"
  export PATH="$BIN_DIR:$PATH"
  echo "Added to PATH in $PROFILE"
fi

echo "Gitu CLI installed to $BIN_PATH"
echo "Open a new terminal and run: gitu --help"
