#!/bin/bash
set -e

make_directories(){
    mkdir -p "$HOME/Games/RiseofKingdoms/wine_bin" "$HOME/Games/RiseofKingdoms/temp"
    echo "Directories created at $HOME/Games"
}

get_json(){
    echo "fetching json"
    curl -L "$WINE_SOURCE" -o $TEMP_FOLDER/wine.json
    curl -L "$DXVK_SOURCE" -o $TEMP_FOLDER/dxvk.json
}

download_wine_bin(){
    echo "Downloading wine binaries"    
    WINE_BIN_URL=$(grep -m 1 'url' $WINE_JSON | grep -oE  '": ?"[^"]*"' | sed 's/": *"//; s/"$//')
    curl -L -O --output-dir "$TEMP_FOLDER" "$WINE_BIN_URL"
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
    curl -L -O --output-dir "$TEMP_FOLDER" "$DXVK_URL"
    echo "DXVK downloaded"
}

install_dxvk(){
    echo "Installing DXVK"
    DXVK_NAME=$(grep -m 1 'file' $DXVK_JSON | grep -oE  '": ?"[^"]*"' | sed 's/": *"//; s/"$//')
    echo "$DXVK_NAME"    
    tar -xf "$TEMP_FOLDER/$DXVK_NAME" --strip-components=1 -C "$TEMP_FOLDER"
    
    cp "$TEMP_FOLDER"/x64/* "$WINE_PREFIX/drive_c/windows/system32/"
    cp "$TEMP_FOLDER"/x32/* "$WINE_PREFIX/drive_c/windows/syswow64/"
    
    for dll in d3d9 d3d10core d3d11 dxgi; do
        WINEPREFIX="$WINE_PREFIX" $WINE_BIN reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" \
            /v "$dll" /d "native,builtin" /f 2>/dev/null
    done
    echo "DXVK installed"
}

install_rok(){
    WINEDEBUG=-all,-fixme,+err WINEPREFIX="$WINE_PREFIX" $WINE_BIN "$ROK_EXE"
    echo "installed"
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

if [ "$1" == "--file" ];then
    make_directories

    TEMP_FOLDER="$HOME/Games/RiseofKingdoms/temp"    
    WINE_PREFIX="$HOME/Games/RiseofKingdoms"
    WIN_BIN_FOLDER="$HOME/Games/RiseofKingdoms/wine_bin"

    WINE_SOURCE="https://raw.githubusercontent.com/an-anime-team/game-integrations/refs/heads/master/packages/components/wine/spritz-wine-cachyos.json"
    DXVK_SOURCE="https://raw.githubusercontent.com/an-anime-team/game-integrations/refs/heads/master/packages/components/dxvk/dxvk.json"
    get_json
    WINE_JSON=$TEMP_FOLDER/wine.json
    DXVK_JSON=$TEMP_FOLDER/dxvk.json

    download_wine_bin
    install_wine_prefix
    WINE_BIN=$WIN_BIN_FOLDER/bin/wine

    download_dxvk
    install_dxvk

    ROK_EXE=$2
    install_rok
    
    LAUNCHER_LOC="$WINE_PREFIX/drive_c/Program Files (x86)/Rise of Kingdoms/launcher.exe"
    make_launcher_script

    ICON_URL="https://raw.githubusercontent.com/limeskat/Rise-of-Kingdoms-Linux-Installer/refs/heads/main/asset/icon.png"
    curl -L -O --output-dir "$TEMP_FOLDER" "$ICON_URL"
    mv $TEMP_FOLDER/icon.png $WINE_PREFIX
    ICON_LOC=$WINE_PREFIX/icon.png
    make_shortcuts

    delete_temp
elif [ "$1" == "--help" ];then
    echo "Usage: bash rok-setup.sh [OPTION] [FILE]"
    echo ""
    echo "  --file [FILE]   Path to the Rise of Kingdoms Windows installer .exe"
    echo "  --help          Show this help message"
    echo "  --version       Show script version"
    echo ""
    echo "Example:"
    echo "  bash rok-setup.sh --file ~/Downloads/rokpc_ff5a7e4128320b4b392ab0f84ab433ca.exe"  
elif [ "$1" == "--version" ];then
    echo "v1.1"
else
    echo "Usage: bash rok-setup.sh --file /path/to/rok_installer.exe"
    echo "Run 'bash rok-setup.sh --help' for more information."
fi        