# cvinz78

![Banner](assets/banner.png)

**cvinz78** is a Windows batch script (`hdd.bat`) for disk drive management with a colorful text menu and a command-line mode. It bundles the most important maintenance tasks for hard disks and SSDs into a single tool.

[🇩🇪 Deutsch](README.md) · [🇬🇧 English (this file)](README_EN.md)

## Features

| Menu item | Description | Command |
|---|---|---|
| 1 | Defragment hard drives | `defrag <drive> /U /V` |
| 2 | Check and repair drives for errors | `chkdsk <drive> /f` |
| 3 | SSD TRIM | `Optimize-Volume -ReTrim -Verbose` |
| 4 | Start Diskpart (partition management) | `diskpart` |
| 5 | Restart or shut down the system | `shutdown /r` or `/s` |

## Screenshots

### Main menu (interactive mode)
![Main menu](assets/screenshot-menue.png)

### Defragment a drive
![Defragmentation](assets/screenshot-defrag.png)

### CHKDSK with system drive detection
![CHKDSK](assets/screenshot-chkdsk.png)

### Help in argument mode
![Help](assets/screenshot-hilfe.png)

## Installation

1. Download [`hdd.bat`](hdd.bat) (e.g. to `C:\Tools\hdd.bat`)
2. Optional: add `C:\Tools` to your `PATH` environment variable so `hdd` can be called from any directory

Requirements: Windows 10/11 with PowerShell (part of Windows). On first start, the script automatically elevates itself to administrator rights (UAC prompt).

## Usage

### Interactive mode

```
hdd
```

Starts the colored menu. After choosing an action, the available drives are displayed and the target drive is requested (entering `0` returns to the main menu).

### Argument mode

| Call | Effect |
|---|---|
| `hdd -d C:` | Defragment drive C: |
| `hdd -c C:` | Check and repair drive C: |
| `hdd -t C:` | SSD TRIM for drive C: |
| `hdd -r` | Restart the system |
| `hdd -s` | Shut down the system |
| `hdd -nc` | Disable colors (combinable, e.g. `hdd -nc -d C:`) |
| `hdd -h`, `--help`, `/?` | Show help |

In argument mode the script asks no questions and returns the exit code of the executed command – useful for automation and for redirecting output to files (where `-nc` is recommended).

### Notes

- **Administrator rights** are required for all actions; the script automatically restarts itself elevated when needed.
- For **`chkdsk C:`** the script detects the system drive and schedules the check for the next reboot if the drive cannot be locked (confirm with `Y`/`J`).
- **Diskpart** works directly on the disks – check its commands carefully.
- The terminal emulator must support ANSI escape sequences (Windows Terminal and recent Windows versions do this by default; use `-nc` to run without colors).

## License

Copyright © 2026 cvinz78

This project is licensed under the [GPL-3.0](LICENSE) (GNU General Public License v3.0).

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
