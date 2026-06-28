# Rise of Kingdoms - Linux Installer Script

**A simple bash script to install and run the PC version of Rise of Kingdoms on Linux using Wine and DXVK**

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
After installation, **Rise of Kingdoms** will appear in your application launcher.

## Usage

```bash
bash rok_installer.sh [OPTION] [FILE]
```

`--file [FILE]` — Path to the Rise of Kingdoms Windows installer `.exe`. Downloads Wine and DXVK, sets up a Wine prefix, runs the installer, and creates a desktop shortcut.

`--runner [NAME]` — Which Wine build to use: `soda` or `cachyos` (default). See [If RoK still freezes at 6%](#if-rok-still-freezes-at-6-or-shows-a-black-screen) below.

`--help` — displays available option.

`--version` — Show script version.

**Example:**
```bash
bash rok_installer.sh --file ~/Downloads/rokpc_ff5a7e4128320b4b392ab0f84ab433ca.exe
```

## Fixes: Rise of Kingdoms Stuck at 6% or Black Screen on Wine
 
If you tried running the game manually through default Wine or Proton, you likely encountered a freeze at **6% loading** or a permanent **black screen**.

The exact root cause is still being looked into, but it consistently occurs when the game tries to display its login / Terms of Service overlay during initialization.

### If RoK still freezes at 6% or shows a black screen
1. Try the other runner instead, in case your specific setup behaves better with it:
   ```bash
   bash rok_installer.sh --file /path/to/rok_installer.exe --runner soda
   ```
   `cachyos` - spritz-wine-cachyos-wow64 [NelloKudo/spritz-wine](https://github.com/NelloKudo/spritz-wine) [default]
   
   `soda` - Soda 9.0-1 [bottlesdevs/wine](https://github.com/bottlesdevs/wine)
   
2. If you are using NVIDIA + Wayland try switching to X11 [[more details](https://github.com/limeskat/Rise-of-Kingdoms-Linux-Installer/issues/1)]
3. If above solution does not work , please open an issue with your distro, desktop environment, session type (X11/Wayland), and GPU/driver.

## Compatibilty
 
The script self-contains its Wine and DXVK dependencies inside the local prefix, it should function on any modern Linux distribution (including Ubuntu, Fedora, Debian, Mint, and Pop!_OS) as long as `curl` and `tar` are available.

## License
This project is released under the [GNU General Public License v3.0](LICENSE).

---
If this helped you get the game running, a ⭐ helps others find the project.
