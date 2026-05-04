#!/usr/bin/env bash
# ================================================================
#  Rise of Kingdoms — Linux/Lutris Setup Script
#  AAGL-aware: wires an existing AAGL prefix into Lutris,
#              or guides you through creating one first.
#
#  Approach:
#    Writes a Lutris game config + registers in the Lutris DB
#    directly. This bypasses the "installer script" flow entirely,
#    avoiding runner-download errors for AAGL-managed Wine builds.
#
#  Modes:
#    A) AAGL prefix already exists  -> read it, wire Lutris to it
#    B) No AAGL prefix yet          -> install AAGL, run it, come back
# ================================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m';     NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[ERR]${NC}   $*"; exit 1; }
section() { echo -e "\n${BOLD}━━━━  $*  ━━━━${NC}"; }

# ── Lutris paths ─────────────────────────────────────────────────
LUTRIS_GAMES="$HOME/.local/share/lutris/games"
LUTRIS_DB="$HOME/.local/share/lutris/pga.db"

# ── Known AAGL paths ─────────────────────────────────────────────
AAGL_DATA_CANDIDATES=(
    "$HOME/.local/share/anime-game-launcher"
    "$HOME/.local/share/an-anime-game-launcher"
)

_resolve_aagl_data_dir() {
    for candidate in "${AAGL_DATA_CANDIDATES[@]}"; do
        if [[ -d "$candidate" ]]; then
            AAGL_DATA="$candidate"
            AAGL_CONFIG="$candidate/config.json"
            AAGL_DEFAULT_PREFIX="$candidate/prefix"
            info "AAGL data dir -> $AAGL_DATA"
            return 0
        fi
    done
    AAGL_DATA="${AAGL_DATA_CANDIDATES[0]}"
    AAGL_CONFIG="$AAGL_DATA/config.json"
    AAGL_DEFAULT_PREFIX="$AAGL_DATA/prefix"
    return 1
}

_resolve_aagl_data_dir || true

AAGL_BINARY_NAMES=(
    "anime-game-launcher"
    "an-anime-game-launcher"
    "AnAnimeGameLauncher"
)
AAGL_APPIMAGE_DIRS=(
    "$HOME/Applications"
    "$HOME/.local/bin"
    "$HOME/bin"
    "/opt"
)
AAGL_FLATPAK_ID="moe.launcher.AnAnimeGameLauncher"

_aagl_is_installed() {
    for name in "${AAGL_BINARY_NAMES[@]}"; do
        command -v "$name" &>/dev/null && return 0
    done

    flatpak list 2>/dev/null | grep -qi "$AAGL_FLATPAK_ID" && return 0

    for dir in "${AAGL_APPIMAGE_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -maxdepth 2 \( -iname "*anime*game*launcher*" \
            -o -iname "*aagl*" \) 2>/dev/null \
            | grep -q . && return 0
    done

    for candidate in "${AAGL_DATA_CANDIDATES[@]}"; do
        [[ -d "$candidate" ]] && return 0
    done

    return 1
}

# ================================================================
#  STEP 0 — Dependency check
# ================================================================
section "Checking Dependencies"

REQUIRED=(lutris python3)
MISSING=()

for cmd in "${REQUIRED[@]}"; do
    command -v "$cmd" &>/dev/null && ok "$cmd found" || MISSING+=("$cmd")
done

[[ ${#MISSING[@]} -eq 0 ]] || die "Missing: ${MISSING[*]}\nInstall them and re-run."

# Verify Lutris DB exists
[[ -f "$LUTRIS_DB" ]] || die "Lutris database not found at: $LUTRIS_DB\nOpen Lutris at least once first."


# ================================================================
#  STEP 1 — Detect AAGL and decide mode
# ================================================================
section "Detecting AAGL Setup"

MODE=""

if [[ -f "$AAGL_CONFIG" ]]; then
    ok "AAGL config found -> $AAGL_CONFIG"
    MODE="A"
elif [[ -d "$AAGL_DEFAULT_PREFIX/drive_c" ]]; then
    ok "AAGL prefix found -> $AAGL_DEFAULT_PREFIX"
    MODE="A"
elif _aagl_is_installed; then
    warn "AAGL is installed but no config/prefix exists yet."
    MODE="B_INSTALLED"
else
    warn "AAGL not found on this system."
    MODE="B_MISSING"
fi

info "Mode -> $MODE"


# ================================================================
#  MODE B — AAGL not ready
# ================================================================
if [[ "$MODE" == "B_MISSING" || "$MODE" == "B_INSTALLED" ]]; then
    section "Action Required -- AAGL Prefix Not Ready"

    if [[ "$MODE" == "B_MISSING" ]]; then
        echo -e "${YELLOW}"
        echo "  AAGL is not installed."
        echo "  It applies the runtime patches that bypass anti-cheat."
        echo "  This script cannot replace that -- it only wires AAGL's"
        echo "  work into Lutris."
        echo ""
        echo "  Install AAGL first:"
        echo ""
        echo "    GitHub Page: https://github.com/an-anime-team/an-anime-game-launcher"
        echo -e "${NC}"
    fi

    echo -e "${BOLD}After installing AAGL, do this before re-running this script:${NC}"
    echo "  1. Open AAGL"
    echo "  2. Let it create the Wine prefix (happens automatically)"
    echo "  3. Download "
    echo "     -- spritz-wine-cachyos "
    echo "     -- dxvk-git "
    echo "  4. Exit AAGL completely"
    echo "  5. Re-run this script"
    echo ""
    die "Re-run after AAGL has set up the prefix."
fi


# ================================================================
#  MODE A — AAGL prefix exists, read everything from it
# ================================================================

# ── Resolve prefix path ──────────────────────────────────────────
section "Reading AAGL Prefix"

PREFIX_PATH=""

if [[ -f "$AAGL_CONFIG" ]]; then
    info "Parsing prefix from $AAGL_CONFIG ..."
    PREFIX_PATH=$(python3 -c "
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
    p = (cfg.get('wine', {}).get('prefix')
         or cfg.get('game', {}).get('wine', {}).get('prefix')
         or cfg.get('prefix'))
    if p: print(p)
except Exception as e:
    sys.stderr.write(str(e) + chr(10))
" "$AAGL_CONFIG" 2>/dev/null || true)

    if [[ -n "$PREFIX_PATH" ]]; then
        ok "Prefix from config.json -> $PREFIX_PATH"
    else
        warn "config.json found but could not extract prefix path."
    fi
else
    warn "No config.json at: $AAGL_CONFIG"
fi

if [[ -z "$PREFIX_PATH" ]]; then
    warn "Falling back to default prefix location."
    PREFIX_PATH="$AAGL_DEFAULT_PREFIX"
    info "Default prefix -> $PREFIX_PATH"
fi

[[ -d "$PREFIX_PATH/drive_c" ]] \
    || die "Prefix invalid (no drive_c): $PREFIX_PATH\nRun AAGL and launch the game at least once first."

ok "Prefix validated -> $PREFIX_PATH"


# ── Resolve Wine binary ──────────────────────────────────────────
section "Locating Wine Binary"

WINE_BIN=""

if [[ -f "$AAGL_CONFIG" ]]; then
    WINE_BIN=$(python3 -c "
import json, sys, os
try:
    cfg = json.load(open(sys.argv[1]))
    wine_cfg = cfg.get('game', {}).get('wine', {})
    builds = wine_cfg.get('builds')
    selected = wine_cfg.get('selected')
    if builds and selected:
        path64 = os.path.join(builds, selected, 'bin', 'wine64')
        path32 = os.path.join(builds, selected, 'bin', 'wine')
        if os.path.exists(path64):
            print(path64)
        elif os.path.exists(path32):
            print(path32)
except Exception as e:
    pass
" "$AAGL_CONFIG" 2>/dev/null || true)

    if [[ -n "$WINE_BIN" && -x "$WINE_BIN" ]]; then
        ok "Wine binary from config.json -> $WINE_BIN"
    else
        WINE_BIN=$(grep -oP '\"wine\"\s*:\s*\"\K[^\"]+' "$AAGL_CONFIG" \
            | grep -v "^$" | head -1 || true)

        if [[ -z "$WINE_BIN" || ! -x "$WINE_BIN" ]]; then
            WINE_BIN=$(grep -oP '\"path\"\s*:\s*\"\K[^\"]+/bin/wine(?=\")' \
                "$AAGL_CONFIG" | head -1 || true)
        fi
    fi
fi

if [[ -z "$WINE_BIN" || ! -x "$WINE_BIN" ]]; then
    info "Searching for wine in $AAGL_DATA ..."
    WINE_BIN=$(find "$AAGL_DATA" -name "wine" -type f 2>/dev/null \
        | grep "bin/wine$" | head -1 || true)
fi

if [[ -z "$WINE_BIN" || ! -x "$WINE_BIN" ]]; then
    warn "Could not find AAGL's Wine binary. Falling back to system wine."
    warn "This may NOT include anti-cheat patches from AAGL's build."
    WINE_BIN=$(command -v wine || true)
    [[ -n "$WINE_BIN" ]] || die "No wine binary found anywhere on the system."
fi

ok "Wine binary -> $WINE_BIN"


# ── Helper: smart game exe finder ────────────────────────────────
# Pure bash. Searches for RoK executables with priority ordering.
# Excludes Windows system dirs and installer/uninstaller binaries.
_find_rok_exe() {
    local search_root="$1"
    local priority1="" priority2="" priority3=""

    while IFS= read -r -d '' exe; do
        local lower_path
        lower_path=$(echo "$exe" | tr '[:upper:]' '[:lower:]')

        # Skip Windows system directories
        case "$lower_path" in
            */windows/*|*/system32/*|*/syswow64/*|*/winsxs/*|*/microsoft.net/*) continue ;;
        esac

        # Skip installers/uninstallers/updaters/redistributables
        local basename_lower
        basename_lower=$(basename "$lower_path")
        case "$basename_lower" in
            *unins*|*setup*|*update*|*redist*|*vcredist*|*dxsetup*) continue ;;
        esac

        local dir_lower
        dir_lower=$(dirname "$lower_path")

        # Priority 1: directory has "rise of kingdoms" AND file is launcher
        if [[ "$dir_lower" == *"rise of kingdoms"* && "$basename_lower" == *launcher* ]]; then
            priority1="$exe"
            break  # best possible match
        fi

        # Priority 2: directory has RoK-related name
        if [[ -z "$priority2" ]]; then
            case "$dir_lower" in
                *"rise of kingdoms"*|*riseofkingdoms*|*rok*) priority2="$exe" ;;
            esac
        fi

        # Priority 3: filename has RoK-related name
        if [[ -z "$priority3" ]]; then
            case "$basename_lower" in
                *rok*|*kingdom*|*riseofkingdom*) priority3="$exe" ;;
            esac
        fi
    done < <(find "$search_root" -maxdepth 8 -iname "*.exe" -print0 2>/dev/null)

    # Return best match
    echo "${priority1:-${priority2:-${priority3:-}}}"
}


# ── Game setup mode ──────────────────────────────────────────────
section "Game Setup"

echo ""
echo -e "${BOLD}How is Rise of Kingdoms set up?${NC}"
echo ""
echo "  1) Already installed (I can point to the game's launcher.exe)"
echo "     e.g., /mnt/winD/Rise of Kingdoms/launcher.exe"
echo "     e.g., $PREFIX_PATH/drive_c/Program Files/Rise of Kingdoms/launcher.exe"
echo ""
echo "  2) I have a downloaded installer .exe that needs to run first"
echo "     e.g., ~/Downloads/rokpc_ff5a7e4128320b4b392ab0f84ab433ca.exe"
echo ""
read -rp "Choose [1/2]: " SETUP_MODE

GAME_EXE=""

case "$SETUP_MODE" in
    2)
        # ── Run installer inside the AAGL prefix ────────────────────
        section "Running Game Installer"

        read -rp "Enter the full path to the installer .exe: " INSTALLER_EXE
        [[ -f "$INSTALLER_EXE" ]] || die "File not found: $INSTALLER_EXE"

        info "Launching installer inside AAGL prefix..."
        info "Wine:   $WINE_BIN"
        info "Prefix: $PREFIX_PATH"
        echo ""
        echo -e "${YELLOW}The installer window should appear shortly.${NC}"
        echo -e "${YELLOW}Install the game, then close the installer when finished.${NC}"
        echo -e "${YELLOW}This script will continue after the installer exits.${NC}"
        echo ""

        # Run the installer using the AAGL Wine + prefix
        WINEPREFIX="$PREFIX_PATH" "$WINE_BIN" "$INSTALLER_EXE" || true

        ok "Installer finished."
        echo ""

        section "Locating Installed Game"

        # Try to auto-detect after install
        info "Scanning prefix for the installed game..."
        GAME_EXE=$(_find_rok_exe "$PREFIX_PATH/drive_c")

        if [[ -n "$GAME_EXE" && -f "$GAME_EXE" ]]; then
            ok "Auto-detected installed game -> $GAME_EXE"
            echo ""
            read -rp "Is this correct? [Y/n]: " CONFIRM
            if [[ "$CONFIRM" =~ ^[Nn] ]]; then
                GAME_EXE=""
            fi
        fi

        if [[ -z "$GAME_EXE" || ! -f "$GAME_EXE" ]]; then
            echo ""
            echo "  Where did the installer put the game?"
            echo "  Look inside: $PREFIX_PATH/drive_c/Program Files/"
            echo "  Or provide any path (e.g., /mnt/winD/Rise of Kingdoms/launcher.exe)"
            read -rp "  Enter the full path to the game's launcher.exe: " GAME_EXE
            [[ -f "$GAME_EXE" ]] || die "File not found: $GAME_EXE"
        fi
        ;;

    *)
        # ── Already installed ───────────────────────────────────────
        section "Locating Game Executable"

        # 1. Ask the user first
        echo ""
        echo "  Enter the path to the game's launcher.exe"
        echo "  (e.g., /mnt/winD/Rise of Kingdoms/launcher.exe)"
        echo "  Or leave empty to auto-detect inside the prefix."
        read -rp "  Path: " USER_EXE

        if [[ -n "$USER_EXE" ]]; then
            if [[ -f "$USER_EXE" ]]; then
                GAME_EXE="$USER_EXE"
                ok "Using game exe -> $GAME_EXE"
            else
                warn "File not found: $USER_EXE. Falling back to auto-detect."
            fi
        fi

        # 2. Check AAGL config for game path
        if [[ -z "$GAME_EXE" && -f "$AAGL_CONFIG" ]]; then
            GAME_EXE=$(python3 -c "
import json, sys, os
try:
    cfg = json.load(open(sys.argv[1]))
    path = cfg.get('game', {}).get('path', {}).get('global')
    if path and os.path.exists(path):
        for exe in ['launcher.exe', 'Rise of Kingdoms.exe', 'rok.exe']:
            full_path = os.path.join(path, exe)
            if os.path.exists(full_path):
                print(full_path)
                sys.exit(0)
except Exception as e:
    pass
" "$AAGL_CONFIG" 2>/dev/null || true)

            if [[ -z "$GAME_EXE" ]]; then
                GAME_EXE=$(grep -oP '\"path\"\s*:\s*\"\K[^\"]+\.exe' "$AAGL_CONFIG" \
                    | grep -iE "rok|kingdom|RiseOf" | head -1 || true)
            fi
        fi

        # 3. Search inside prefix
        if [[ -z "$GAME_EXE" || ! -f "$GAME_EXE" ]]; then
            info "Scanning prefix for launcher..."
            GAME_EXE=$(_find_rok_exe "$PREFIX_PATH/drive_c")
        fi

        # 4. Last resort: ask
        if [[ -z "$GAME_EXE" || ! -f "$GAME_EXE" ]]; then
            warn "Could not auto-detect game executable."
            echo ""
            echo "  You can specify ANY path, including Windows partitions"
            echo "  (e.g., /mnt/winD/Rise of Kingdoms/launcher.exe)"
            read -rp "  Enter the full path to the game .exe: " GAME_EXE
            [[ -f "$GAME_EXE" ]] || die "File not found: $GAME_EXE"
        fi
        ;;
esac

ok "Game exe -> $GAME_EXE"
GAME_WORKDIR=$(dirname "$GAME_EXE")


# ── Extract AAGL environment variables ───────────────────────────
section "Extracting AAGL Environment Variables"

declare -A ENV_VARS

ENV_VARS["WINEFSYNC"]="1"
ENV_VARS["WINEESYNC"]="1"
ENV_VARS["WINE_LARGE_ADDRESS_AWARE"]="1"
ENV_VARS["WINEDEBUG"]="-all"
ENV_VARS["DXVK_HUD"]="0"
ENV_VARS["DXVK_ASYNC"]="1"
ENV_VARS["STAGING_SHARED_MEMORY"]="1"
ENV_VARS["__GL_SHADER_DISK_CACHE"]="1"
ENV_VARS["__GL_SHADER_DISK_CACHE_SKIP_CLEANUP"]="1"

if [[ -f "$AAGL_CONFIG" ]]; then
    while IFS= read -r line; do
        KEY=$(echo "$line" | grep -oP '\"[A-Z][A-Z_0-9]+\"' | tr -d '\"' | head -1 || true)
        VAL=$(echo "$line" | grep -oP ':\s*\"\K[^\"]+' | head -1 || true)
        if [[ -n "$KEY" && -n "$VAL" && "$KEY" =~ ^[A-Z_] ]]; then
            ENV_VARS["$KEY"]="$VAL"
            info "  env from config: $KEY=$VAL"
        fi
    done < <(python3 -c "
import json, sys
try:
    cfg = json.load(open('$AAGL_CONFIG'))
    env = cfg.get('game', {}).get('environment', \
          cfg.get('environment', \
          cfg.get('env', {})))
    for k, v in env.items():
        print(f'\"{k}\": \"{v}\"')
except: pass
" 2>/dev/null || true)
fi

ok "${#ENV_VARS[@]} environment variables resolved."


# ================================================================
#  Write Lutris game config (direct registration, NOT installer)
# ================================================================
section "Writing Lutris Game Configuration"

mkdir -p "$LUTRIS_GAMES"

GAME_SLUG="rise-of-kingdoms"
GAME_NAME="Rise of Kingdoms"
INSTALL_TS=$(date +%s)
CONFIGPATH="${GAME_SLUG}-${INSTALL_TS}"
CONFIG="$LUTRIS_GAMES/${CONFIGPATH}.yml"

# Build env block
ENV_BLOCK=""
for KEY in "${!ENV_VARS[@]}"; do
    ENV_BLOCK+="    ${KEY}: \"${ENV_VARS[$KEY]}\"\n"
done

# Write the game config YAML (same format Lutris uses internally)
cat > "$CONFIG" <<YAML
game:
  exe: ${GAME_EXE}
  prefix: ${PREFIX_PATH}
  working_dir: ${GAME_WORKDIR}
  arch: win64

wine:
  custom_wine_path: ${WINE_BIN}
  version: custom

system:
  env:
$(echo -e "$ENV_BLOCK")
YAML

ok "Lutris game config -> $CONFIG"


# ── Register in Lutris database ──────────────────────────────────
section "Registering Game in Lutris Database"

# Remove any previous entries for this slug to avoid duplicates
python3 -c "
import sqlite3, sys

db_path = sys.argv[1]
slug = sys.argv[2]
name = sys.argv[3]
configpath = sys.argv[4]
install_ts = int(sys.argv[5])

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Check if slug already exists
cur.execute('SELECT id, configpath FROM games WHERE slug = ?', (slug,))
existing = cur.fetchone()

if existing:
    old_id, old_config = existing
    # Update existing entry
    cur.execute('''
        UPDATE games SET
            name = ?,
            configpath = ?,
            runner = 'wine',
            platform = 'Windows',
            installed = 1,
            installed_at = ?
        WHERE slug = ?
    ''', (name, configpath, install_ts, slug))
    print(f'Updated existing game (id={old_id}, old_config={old_config})')
else:
    # Insert new entry
    cur.execute('''
        INSERT INTO games (name, sortname, slug, installer_slug, parent_slug,
                           platform, runner, executable, directory, installed,
                           installed_at, configpath, has_custom_banner,
                           has_custom_icon, has_custom_coverart_big, playtime)
        VALUES (?, '', ?, '', '', 'Windows', 'wine', '', '', 1, ?, ?,
                0, 0, 0, 0.0)
    ''', (name, slug, install_ts, configpath))
    print(f'Inserted new game (id={cur.lastrowid})')

conn.commit()
conn.close()
" "$LUTRIS_DB" "$GAME_SLUG" "$GAME_NAME" "$CONFIGPATH" "$INSTALL_TS"

ok "Game registered in Lutris database."


# ================================================================
#  DONE
# ================================================================
section "Done"

echo ""
echo -e "${GREEN}${BOLD}Rise of Kingdoms is now registered in Lutris.${NC}"
echo ""
printf "  %-18s %s\n" "AAGL prefix:"   "$PREFIX_PATH"
printf "  %-18s %s\n" "Wine binary:"   "$WINE_BIN"
printf "  %-18s %s\n" "Wine version:"  "custom (AAGL-managed)"
printf "  %-18s %s\n" "Game exe:"      "$GAME_EXE"
printf "  %-18s %s\n" "Lutris config:" "$CONFIG"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Close and reopen Lutris"
echo "  2. 'Rise of Kingdoms' should appear in your game list"
echo "  3. Click Play"
echo ""
echo -e "${YELLOW}Rules for this setup:${NC}"
echo "  [OK]  Normal play  -> launch from Lutris"
echo "  [OK]  After a game update -> open AAGL, apply update, close AAGL,"
echo "        then go back to Lutris for gameplay"
echo "  [NO]  Never run Lutris and AAGL at the same time"
echo "  [NO]  Never wineboot or recreate the prefix manually"
echo "        (it will wipe AAGL's anti-cheat patches)"
echo ""
echo -e "${YELLOW}If the game crashes on first Lutris launch:${NC}"
echo "  -> Open AAGL, reach the title screen, close it,"
echo "     then try Lutris again."
echo "  -> This re-seeds the runtime patches into the prefix."
echo ""
