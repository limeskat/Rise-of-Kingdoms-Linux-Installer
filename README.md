# Rise of Kingdoms - Linux Installer Script

> **Run Rise of Kingdoms on Linux with Lutris, using AAGL.**

## Overview

`rok-setup.sh` is a Bash script that wires an existing **[An Anime Game Launcher (AAGL)](https://github.com/an-anime-team/an-anime-game-launcher)** environment into **[Lutris](https://lutris.net/)**, giving you a one-click "Play" button for Rise of Kingdoms on Lutris.

**What it does:**

- Reads AAGL's `config.json` to extract the Wine prefix, Wine binary, and environment variables
- Writes a Lutris-compatible game config YAML
- Registers the game directly in Lutris's SQLite database
- Supports games installed inside the prefix _or_ on mounted NTFS/external drives

**What it does NOT do:**

- Create its own Wine prefix (that would break anti-cheat)
- Download or install Wine runners
- Replace AAGL - it only bridges AAGL's work into Lutris

---

## Prerequisites

### 1. System Packages

```
lutris
python3
```


<details>
<summary><b>Distro-specific install commands</b></summary>

**Fedora / openSUSE:**

```bash
sudo dnf install lutris python3
```

**Arch / Manjaro:**

```bash
sudo pacman -S lutris python
```

**Ubuntu / Debian:**

```bash
sudo apt install lutris python3
```

**Flatpak (any distro):**

```bash
flatpak install flathub net.lutris.Lutris
```


</details>

### 2. Lutris — First Run Required

The script writes directly to Lutris's SQLite database at `~/.local/share/lutris/pga.db`. This file is only created after Lutris has been **opened at least once**.

### 3. AAGL — An Anime Game Launcher

AAGL provides the **patched Wine build** and **anti-cheat bypass** that Rise of Kingdoms requires to run on Linux. This script does not replace AAGL — it only bridges AAGL's work into Lutris.

> **If AAGL is not installed**. See [AAGL Installation Options](https://github.com/an-anime-team/an-anime-game-launcher) below.

**Before running this script, AAGL must have:**

1. Created a Wine prefix (happens automatically on first launch)
2. Downloaded its custom Wine build (e.g., `spritz-wine-cachyos-wow64-*`) + dxvk-git

---

## Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/rok.git
cd rok

# Make the script executable
chmod +x rok-setup.sh
```

---

## Usage

### Step 1 : Prepare AAGL

Before running the script, ensure AAGL has fully initialized:

1. Install AAGL for your distro (see [AAGL install options](https://github.com/an-anime-team/an-anime-game-launcher) below)
2. Open AAGL and
3. Download spritz-wine-cachyos-wow64(default) + dxvk-git
4. let it create the Wine prefix
5. Close AAGL completely

### Step 2 : Run the Script

```bash
./rok-setup.sh
```

### Step 3 : Launch

1. Close and reopen Lutris
2. **"Rise of Kingdoms"** appears in your game list
3. Click **Play**

---

## Game Setup Modes

When the script asks _"How is Rise of Kingdoms set up?"_, you'll choose one of two modes:

### Option 1 : Already Installed

Point the script to an existing `launcher.exe`. This works for:

- Games installed inside the AAGL prefix (`~/.local/share/anime-game-launcher/prefix/drive_c/...`)
- Games on a mounted Windows/NTFS partition (`/mnt/winD/Rise of Kingdoms/launcher.exe`)
- Any custom location

If you leave the path empty, the script auto-scans the prefix.

### Option 2 : Run an Installer

Provide a downloaded installer `.exe`. The script will:

1. Launch it inside the AAGL Wine prefix
2. Wait for installation to complete
3. Auto-detect the installed game executable
4. Continue with Lutris registration

---

## License

This project is released under the [MIT License](LICENSE).
