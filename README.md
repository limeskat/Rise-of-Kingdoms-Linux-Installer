# Rise of Kingdoms - Linux Installer Script

**A simple bash script to install and run the PC version of Rise of Kingdoms on Linux using spritz-wine-cachyos-wow64 and DXVK**

## Prerequisites
 
- `curl`
- `tar`
- A downloaded Rise of Kingdoms Windows installer `.exe` ([get it from the official site](https://rok.lilith.com/))
  
## How to Install Rise of Kingdoms on Linux
 
**Option 1 - Clone and run:**
```bash
git clone https://github.com/limeskat/Rise-of-Kingdoms-Linux-Installer.git
cd Rise-of-Kingdoms-Linux-Installer
bash rok_installer.sh --file /path/to/rok_installer.exe
```
 
**Option 2 - Run directly:**
```bash
curl -fsSL https://raw.githubusercontent.com/limeskat/Rise-of-Kingdoms-Linux-Installer/refs/heads/main/rok_installer.sh | bash -s -- --file /path/to/rok_installer.exe
```
 
> [!NOTE]
> It is better to install just the launcher, then exit and let it download the game files on first launch rather than waiting through the full download during setup.
 
After installation, **Rise of Kingdoms** will appear in your application launcher.

## Usage

```bash
bash rok_installer.sh [OPTION] [FILE]
```

`--file [FILE]` — Path to the Rise of Kingdoms Windows installer `.exe`. Downloads Wine and DXVK, sets up a Wine prefix, runs the installer, and creates a desktop shortcut.

`--help` — displays available option.

`--version` — Show script version.

**Example:**
```bash
bash rok_installer.sh --file ~/Downloads/rokpc_ff5a7e4128320b4b392ab0f84ab433ca.exe
```

## Fixes: Rise of Kingdoms Stuck at 6% or Black Screen on Wine
 
If you tried running the game manually through default Wine or Proton, you likely encountered a freeze at **6% loading** or a permanent **black screen**. 

This issue is widely attributed to the game's login integration and Terms of Service (ToS) prompts, which rely on an embedded WebView container that standard Wine setups often fail to render. When this background window fails to initialize, the game engine hangs or visually glitches into a black screen.

This installer automatically configures a patched **spritz-wine-cachyos-wow64** build that properly handles these embedded web elements, allowing you to seamlessly bypass the 6% hang and log into your account.

## Supports All Major Linux Distributions
 
Tested on Arch Linux.The script self-contains its Wine and DXVK dependencies inside the local prefix, it should function on any modern Linux distribution (including Ubuntu, Fedora, Debian, Mint, and Pop!_OS) as long as `curl` and `tar` are available.

## Credits & Upstream Sources

The script dynamically fetches the latest verified spritz-wine-cachyos-wow64 and DXVK versions directly from [**An Anime Team's game-integrations**](https://github.com/an-anime-team/game-integrations/tree/master/packages/components)  repository:

* **Wine Source:** [spritz-wine-cachyos.json](https://raw.githubusercontent.com/an-anime-team/game-integrations/refs/heads/master/packages/components/wine/spritz-wine-cachyos.json)
* **DXVK Source:** [dxvk.json](https://raw.githubusercontent.com/an-anime-team/game-integrations/refs/heads/master/packages/components/dxvk/dxvk.json)

## License
This project is released under the [GNU General Public License v3.0](LICENSE).

---
If this script helped you get the game installed and run properly, please drop a ⭐ to help others in need find it!
