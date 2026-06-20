#!/bin/bash
set -e

for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: required command '$cmd' not found"; exit 1; }
done

make_directories(){
    mkdir -p "$HOME/Games/RiseofKingdoms/wine_bin" "$HOME/Games/RiseofKingdoms/temp"
    echo "Directories created at $HOME/Games"
}

get_dxvk_json(){
    echo "fetching dxvk json"
    curl -fL "$DXVK_SOURCE" -o $TEMP_FOLDER/dxvk.json
}

get_wine_json(){
    echo "fetching wine json"
    curl -fL "$WINE_SOURCE" -o $TEMP_FOLDER/wine.json
}

download_wine_bin(){
    echo "Downloading wine binaries"    
    WINE_BIN_URL=$(grep -m 1 'url' $WINE_JSON | grep -oE  '": ?"[^"]*"' | sed 's/": *"//; s/"$//')
    curl -fL -O --output-dir "$TEMP_FOLDER" "$WINE_BIN_URL"
    echo "Downloaded wine binaries"
}

install_wine_prefix(){
    echo "Installing wine binaries"
    WINE_BIN_NAME=$(grep -m 1 'file' $WINE_JSON | grep -oE  '": ?"[^"]*"' | sed 's/": *"//; s/"$//')    
    tar -xf "$TEMP_FOLDER/$WINE_BIN_NAME" --strip-components=1 -C "$WIN_BIN_FOLDER"
    WINEDEBUG=-all,-fixme,+err WINEPREFIX="$WINE_PREFIX" "$WIN_BIN_FOLDER"/bin/wineboot --init
    echo "wine prefix installed"
}

download_dxvk(){
    echo "Downloading DXVK"  
    DXVK_URL=$(grep -m 1 'url' $DXVK_JSON | grep -oE  '": ?"[^"]*"' | sed 's/": *"//; s/"$//')
    curl -fL -O --output-dir "$TEMP_FOLDER" "$DXVK_URL"
    echo "DXVK downloaded"
}

install_dxvk(){
    echo "Installing DXVK"
    DXVK_NAME=$(grep -m 1 'file' $DXVK_JSON | grep -oE  '": ?"[^"]*"' | sed 's/": *"//; s/"$//')
    echo "$DXVK_NAME"    
    tar -xf "$TEMP_FOLDER/$DXVK_NAME" --strip-components=1 -C "$TEMP_FOLDER"
    
    cp "$TEMP_FOLDER"/x64/* "$WINE_PREFIX/drive_c/windows/system32/"
    cp "$TEMP_FOLDER"/x32/* "$WINE_PREFIX/drive_c/windows/syswow64/"
    
    for dll in d3d8 d3d9 d3d10core d3d11 dxgi; do
        WINEPREFIX="$WINE_PREFIX" $WINE_BIN reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" \
            /v "$dll" /d "native,builtin" /f 2>/dev/null
    done
    echo "DXVK installed"
}

install_rok(){
    WINEDEBUG=-all,-fixme,+err WINEPREFIX="$WINE_PREFIX" $WINE_BIN "$ROK_EXE"
    echo "installed"
}

find_launcher(){
    local root="$WINE_PREFIX/drive_c"
    local found
    found=$(find "$root" -maxdepth 6 -iname "launcher.exe" 2>/dev/null \
        | grep -iE "rise of kingdoms|riseofkingdoms|rok" | head -1)
    if [ -z "$found" ]; then
        found="$root/Program Files (x86)/Rise of Kingdoms/launcher.exe"
    fi
    echo "$found"
}

make_launcher_script(){
    touch launcher.sh
    chmod +x launcher.sh
    echo "#!/bin/bash" >> launcher.sh
    echo "" >> launcher.sh
    echo "WINEPREFIX=$WINE_PREFIX $WINE_BIN \"$LAUNCHER_LOC\"" >> launcher.sh
    mv launcher.sh "$WINE_PREFIX"/
}

make_shortcuts(){
    echo "creating shortcut"
    touch rok.desktop
    echo "[Desktop Entry]" >> rok.desktop     
    echo "Type=Application" >> rok.desktop     
    echo "Name=Rise of Kingdoms" >> rok.desktop     
    echo "Exec=$WINE_PREFIX/launcher.sh" >> rok.desktop     
    echo "Icon=$ICON_LOC" >> rok.desktop     
    echo "Categories=Game" >> rok.desktop
    mv rok.desktop "$HOME"/.local/share/applications
    echo "shortcut created"     
}

delete_temp(){
    echo "deleting temp files"
    rm -rf "$TEMP_FOLDER"
    echo "installation complete"
}

RUNNER="cachyos"
ACTION=""
ROK_EXE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --file)
            ACTION="install"
            ROK_EXE="$2"
            shift 2
            ;;
        --runner)
            RUNNER="$2"
            shift 2
            ;;
        --help)
            ACTION="help"
            shift
            ;;
        --version)
            ACTION="version"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ "$ACTION" == "install" ];then
    [ -f "$ROK_EXE" ] || { echo "ERROR: installer file not found: $ROK_EXE"; exit 1; }

    make_directories

    TEMP_FOLDER="$HOME/Games/RiseofKingdoms/temp"    
    WINE_PREFIX="$HOME/Games/RiseofKingdoms"
    WIN_BIN_FOLDER="$HOME/Games/RiseofKingdoms/wine_bin"

    WINE_SOURCE_CACHYOS="https://raw.githubusercontent.com/an-anime-team/game-integrations/refs/heads/master/packages/components/wine/spritz-wine-cachyos.json"
    WINE_SOURCE_SODA="https://raw.githubusercontent.com/limeskat/Rise-of-Kingdoms-Linux-Installer/refs/heads/main/wine/wine_soda.json"
    DXVK_SOURCE="https://raw.githubusercontent.com/an-anime-team/game-integrations/refs/heads/master/packages/components/dxvk/dxvk.json"

    case "$RUNNER" in
        cachyos)
            WINE_SOURCE="$WINE_SOURCE_CACHYOS"
            echo "Using runner: spritz-wine-cachyos-wow64 - default"
            ;;
        soda)
            WINE_SOURCE="$WINE_SOURCE_SODA"
            echo "Using runner: Soda (bottlesdevs/wine)"
            ;;
        *)
            echo "ERROR: unknown runner '$RUNNER' (expected: soda or cachyos)" >&2
            exit 1
            ;;
    esac

    get_dxvk_json
    DXVK_JSON=$TEMP_FOLDER/dxvk.json

    get_wine_json
    WINE_JSON=$TEMP_FOLDER/wine.json
    download_wine_bin
    install_wine_prefix
    WINE_BIN=$WIN_BIN_FOLDER/bin/wine

    download_dxvk
    install_dxvk

    install_rok
    
    LAUNCHER_LOC=$(find_launcher)
    if [ ! -f "$LAUNCHER_LOC" ]; then
        echo "WARNING: could not auto-detect launcher.exe."
        echo "Expected around: $LAUNCHER_LOC"
        echo "If the desktop shortcut doesn't start the game, edit this file:"
        echo "  $WINE_PREFIX/launcher.sh"
    fi
    make_launcher_script

    ICON_URL="https://raw.githubusercontent.com/limeskat/Rise-of-Kingdoms-Linux-Installer/refs/heads/main/asset/icon.png"
    curl -fL -O --output-dir "$TEMP_FOLDER" "$ICON_URL"
    mv $TEMP_FOLDER/icon.png $WINE_PREFIX
    ICON_LOC=$WINE_PREFIX/icon.png
    make_shortcuts

    delete_temp
elif [ "$ACTION" == "help" ];then
    echo "Usage: bash rok_installer.sh --file [FILE] [--runner soda|cachyos]"
    echo ""
    echo "  --file [FILE]     Path to the Rise of Kingdoms Windows installer .exe"
    echo "  --runner [NAME]   Wine build to use: soda or cachyos(default) "
    echo "  --help            Show this help message"
    echo "  --version         Show script version"
    echo ""
    echo "Example:"
    echo "  bash rok_installer.sh --file ~/Downloads/rokpc_ff5a7e4128320b4b392ab0f84ab433ca.exe"
    echo ""
    echo "To use the older spritz-wine-cachyos-wow64 runner instead:"
    echo "  bash rok_installer.sh --file ~/Downloads/rokpc_ff5a7e4128320b4b392ab0f84ab433ca.exe --runner cachyos"
elif [ "$ACTION" == "version" ];then
    echo "v1.2"
else
    echo "Usage: bash rok_installer.sh --file /path/to/rok_installer.exe [--runner soda|cachyos]"
    echo "Run 'bash rok_installer.sh --help' for more information."
fi