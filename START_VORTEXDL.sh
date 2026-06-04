#!/usr/bin/env bash
# ============================================================
#  VortexDL — Mac / Linux One-Click Launcher
#  Run: bash START_VORTEXDL.sh
#  Or:  chmod +x START_VORTEXDL.sh && ./START_VORTEXDL.sh
# ============================================================

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# Move to the folder containing this script
cd "$(dirname "$0")"

clear
echo -e "${CYAN}"
echo "  ██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗██████╗ ██╗"
echo "  ██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝██╔══██╗██║"
echo "  ██║   ██║██║   ██║██████╔╝   ██║   █████╗   ╚███╔╝ ██║  ██║██║"
echo "  ╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ ██║  ██║██║"
echo "   ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██╔╝ ██╗██████╔╝███████╗"
echo "    ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}[ TikTok No-WM | Instagram HD | YT Shorts | 1000+ Sites ]${RESET}"
echo "  ============================================================"
echo ""

# ── STEP 1: Check Python ─────────────────────────────────────────────
echo -e "  ${CYAN}[1/5]${RESET} Checking Python..."

PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        VER=$("$cmd" --version 2>&1)
        echo -e "  ${GREEN}[OK]${RESET} Found: $VER (using '$cmd')"
        PYTHON="$cmd"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo -e "  ${RED}[ERROR]${RESET} Python 3 not found."
    echo ""
    echo "  Install it:"
    echo "    Mac:   brew install python3   OR  https://python.org/downloads"
    echo "    Linux: sudo apt install python3 python3-pip"
    echo ""
    exit 1
fi

# ── STEP 2: Check pip ────────────────────────────────────────────────
echo -e "  ${CYAN}[2/5]${RESET} Checking pip..."
if ! $PYTHON -m pip --version &>/dev/null; then
    echo -e "  ${YELLOW}[INFO]${RESET} pip not found. Installing..."
    $PYTHON -m ensurepip --upgrade 2>/dev/null || \
    curl https://bootstrap.pypa.io/get-pip.py | $PYTHON
fi
echo -e "  ${GREEN}[OK]${RESET} pip ready."

# ── STEP 3: Install dependencies ─────────────────────────────────────
echo ""
echo -e "  ${CYAN}[3/5]${RESET} Installing / checking dependencies..."
echo "        (flask, yt-dlp, flask-cors)"

$PYTHON -m pip install --quiet --upgrade flask yt-dlp flask-cors
if [ $? -ne 0 ]; then
    echo -e "  ${RED}[ERROR]${RESET} Failed to install dependencies."
    echo "  Try: pip3 install flask yt-dlp flask-cors"
    exit 1
fi
echo -e "  ${GREEN}[OK]${RESET} All dependencies ready."

# ── STEP 4: Check files ───────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}[4/5]${RESET} Checking project files..."

if [ ! -f "app.py" ]; then
    echo -e "  ${RED}[ERROR]${RESET} app.py not found in $(pwd)"
    echo "  Make sure START_VORTEXDL.sh is in the same folder as app.py"
    exit 1
fi

if [ ! -f "index.html" ]; then
    echo -e "  ${RED}[ERROR]${RESET} index.html not found in $(pwd)"
    exit 1
fi

echo -e "  ${GREEN}[OK]${RESET} app.py found."
echo -e "  ${GREEN}[OK]${RESET} index.html found."

# ── STEP 5: Free port 5000 ────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}[5/5]${RESET} Freeing port 5000 if in use..."
PID=$(lsof -ti:5000 2>/dev/null)
if [ -n "$PID" ]; then
    kill -9 $PID 2>/dev/null
    sleep 1
    echo -e "  ${YELLOW}[INFO]${RESET} Killed old process on port 5000."
fi
echo -e "  ${GREEN}[OK]${RESET} Port 5000 ready."

# ── START SERVER ──────────────────────────────────────────────────────
echo ""
echo "  ============================================================"
echo -e "   ${BOLD}Starting VortexDL server...${RESET}"
echo "  ============================================================"
echo ""

# Start Flask in background, log to server.log
$PYTHON app.py > server.log 2>&1 &
SERVER_PID=$!
echo "  Server PID: $SERVER_PID"
echo $SERVER_PID > .vortexdl.pid

# ── WAIT FOR SERVER ───────────────────────────────────────────────────
echo -n "  Waiting for server"
for i in $(seq 1 15); do
    sleep 1
    echo -n "."
    # Try a quick curl to see if it's up
    if curl -s --max-time 1 http://localhost:5000 &>/dev/null; then
        echo ""
        echo -e "  ${GREEN}[OK]${RESET} Server is up!"
        break
    fi
done
echo ""

# ── OPEN BROWSER ──────────────────────────────────────────────────────
FULL_PATH="$(pwd)/index.html"
echo -e "  Opening browser..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$FULL_PATH"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$FULL_PATH"
elif command -v gnome-open &>/dev/null; then
    gnome-open "$FULL_PATH"
else
    echo -e "  ${YELLOW}[INFO]${RESET} Open this file manually in your browser:"
    echo "  file://$FULL_PATH"
fi

# ── DONE ─────────────────────────────────────────────────────────────
echo ""
echo "  ============================================================"
echo ""
echo -e "  ${GREEN}${BOLD}VortexDL is running!${RESET}"
echo ""
echo -e "  Website  : ${CYAN}file://$FULL_PATH${RESET}"
echo -e "  API      : ${CYAN}http://localhost:5000${RESET}"
echo -e "  Downloads: ${CYAN}$(pwd)/downloads/${RESET}"
echo -e "  Log file : ${CYAN}$(pwd)/server.log${RESET}"
echo ""
echo "  Press Ctrl+C to stop the server."
echo ""
echo "  ============================================================"
echo ""

# Keep script alive so Ctrl+C kills the server cleanly
trap "echo ''; echo '  Stopping VortexDL...'; kill $SERVER_PID 2>/dev/null; rm -f .vortexdl.pid; echo '  Server stopped. Bye!'; exit 0" INT TERM

# Tail server logs so user can see activity
tail -f server.log
