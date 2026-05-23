# Rise of Kingdoms - Linux Installer Script

**Run Rise of Kingdoms on Linux with spritz-wine-cachyos-wow64 and dxvk.**

## Installation

just clone and run script while passing the --file arg ...

```bash
git clone https://github.com/limeskat/Rise-of-Kingdoms-Linux-Installer.git
cd Rise-of-Kingdoms-Linux-Installer
bash install.sh --file /path/to/rok_installer.exe
```
or
Dont forget to mention the instraller.exe location!!
```bash
curl -fsSL https://raw.githubusercontent.com/limeskat/Rise-of-Kingdoms-Linux-Installer/blob/main/rok_installer.sh | bash -s -- --file ~/Downloads/rok_installer.exe
```

eg..
`bash rok_installer.sh --file /home/user/Downloads/rokpc_random.exe`
`bash rok_installer.sh --file ~/Downloads/rokpc_random.exe`
After installation, Rise of Kingdoms will appear in your application launcher.

> [!NOTE]
> It is better to just install the launcher then exit and download the game files later.

## Usage

```bash
bash rok_installer.sh [OPTION] [FILE]
```

`--file [FILE]` — Path to the Rise of Kingdoms Windows installer `.exe`. Downloads Wine and DXVK, sets up a Wine prefix, runs the installer, and creates a desktop shortcut.

`--help` — displays available option.

`--version` — Show script version.

## License

This project is released under the [MIT License](LICENSE).
