#!/usr/bin/env bash
# install.sh — Set up openclaw-analytics on your OpenClaw instance
#
# What this does:
#   1. Asks for your OpenClaw workspace path and email address
#   2. Detects himalaya binary path
#   3. Substitutes placeholders in all scripts
#   4. Symlinks scripts to ~/.local/bin/
#   5. Copies HTML template to your workspace/templates/
#   6. Creates workspace/rapporter/ output directory

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$REPO_DIR/bin"
TEMPLATE_SRC="$REPO_DIR/templates"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
err()  { echo -e "${RED}✗${NC} $*"; }

echo ""
echo "=== openclaw-analytics installer ==="
echo ""

# --- 1. Workspace path ---
DEFAULT_WORKSPACE="$HOME/.openclaw/workspace"
read -rp "OpenClaw workspace path [$DEFAULT_WORKSPACE]: " WORKSPACE
WORKSPACE="${WORKSPACE:-$DEFAULT_WORKSPACE}"

if [[ ! -d "$WORKSPACE" ]]; then
  warn "Directory $WORKSPACE does not exist — creating it."
  mkdir -p "$WORKSPACE"
fi
ok "Workspace: $WORKSPACE"

# --- 2. Recipient email ---
read -rp "Default recipient email [your-email@example.com]: " EMAIL
if [[ -z "$EMAIL" ]]; then
  warn "No email set — scripts will use 'your-email@example.com' as default. Edit scripts later."
  EMAIL="your-email@example.com"
fi
ok "Email: $EMAIL"

# --- 3. Himalaya binary ---
HIMALAYA_BIN=""
for candidate in \
    "/home/linuxbrew/.linuxbrew/bin/himalaya" \
    "$HOME/.linuxbrew/bin/himalaya" \
    "$(which himalaya 2>/dev/null || true)"; do
  if [[ -x "$candidate" ]]; then
    HIMALAYA_BIN="$candidate"
    break
  fi
done

if [[ -z "$HIMALAYA_BIN" ]]; then
  warn "himalaya not found. hmail will not work until you install himalaya and update bin/hmail."
  HIMALAYA_BIN="/usr/local/bin/himalaya"  # placeholder
else
  ok "himalaya: $HIMALAYA_BIN"
fi

# --- 4. Claude CLI check ---
if command -v claude &>/dev/null; then
  ok "claude CLI: $(which claude)"
else
  warn "claude CLI not found. Install it from https://claude.ai/code"
fi

# --- 5. Prepare directories ---
INSTALL_BIN="$HOME/.local/bin"
RAPPORTDIR="$WORKSPACE/rapporter"
TEMPLATEDIR="$WORKSPACE/templates"

mkdir -p "$INSTALL_BIN" "$RAPPORTDIR" "$TEMPLATEDIR"
ok "Directories ready"

# --- 6. Substitute paths in scripts and install ---
echo ""
echo "Installing scripts to $INSTALL_BIN ..."

for src in "$BIN_SRC"/*; do
  name="$(basename "$src")"
  dest="$INSTALL_BIN/$name"

  # Sed-substitute placeholders
  sed \
    -e "s|/home/lars/.openclaw/workspace|$WORKSPACE|g" \
    -e "s|/home/lars/.local/bin|$INSTALL_BIN|g" \
    -e "s|lsoraas@gmail.com|$EMAIL|g" \
    -e "s|/home/linuxbrew/.linuxbrew/bin/himalaya|$HIMALAYA_BIN|g" \
    "$src" > "$dest"

  chmod +x "$dest"
  ok "  $name"
done

# --- 7. Copy HTML template ---
echo ""
echo "Copying templates to $TEMPLATEDIR ..."
cp "$TEMPLATE_SRC/investorsammenligning.html" "$TEMPLATEDIR/"
ok "  investorsammenligning.html"

# --- 8. Python dependency check ---
echo ""
if python3 -c "import yfinance" 2>/dev/null; then
  ok "yfinance (Python) installed"
else
  warn "yfinance not installed — needed for fetch-stocks and send-stock-report"
  echo "     Install with: pip3 install yfinance"
fi

# --- Done ---
echo ""
echo "=== Installation complete ==="
echo ""
echo "Quick test:"
echo "  list-rapporter"
echo "  tech-trend-analyse \"Rust\" --budget 0.10"
echo ""
echo "If email doesn't work, check himalaya config:"
echo "  himalaya account list"
echo ""
echo "Edit $INSTALL_BIN/hmail to change the FROM address."
echo ""
