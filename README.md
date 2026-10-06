# cvinz78

![Banner](assets/banner.png)

**cvinz78** ist ein Windows-Batch-Skript (`hdd.bat`) zur Datenträger-Verwaltung mit farbigem Textmenü und Command-Line-Modus. Es bündelt die wichtigsten Wartungsaufgaben rund um Festplatten und SSDs in einem Werkzeug.

[🇩🇪 Deutsch (diese Datei)](README.md) · [🇬🇧 English](README_EN.md)

## Funktionen

| Menüpunkt | Beschreibung | Befehl |
|---|---|---|
| 1 | Festplatten defragmentieren | `defrag <Laufwerk> /U /V` |
| 2 | Festplatte auf Fehler prüfen und reparieren | `chkdsk <Laufwerk> /f` |
| 3 | SSD Trim durchführen | `Optimize-Volume -ReTrim -Verbose` |
| 4 | Diskpart starten (Partitionsverwaltung) | `diskpart` |
| 5 | System neustarten oder herunterfahren | `shutdown /r` bzw. `/s` |

## Screenshots

### Hauptmenü (interaktiver Modus)
![Hauptmenü](assets/screenshot-menue.png)

### Festplatte defragmentieren
![Defragmentierung](assets/screenshot-defrag.png)

### CHKDSK mit Systemlaufwerk-Erkennung
![CHKDSK](assets/screenshot-chkdsk.png)

### Hilfe im Argumentmodus
![Hilfe](assets/screenshot-hilfe.png)

## Installation

1. [`hdd.bat`](hdd.bat) herunterladen (z. B. nach `C:\Tools\hdd.bat`)
2. Optional: `C:\Tools` zur `PATH`-Umgebungsvariable hinzufügen, damit `hdd` aus jedem Verzeichnis aufrufbar ist

Weitere Voraussetzungen: Windows 10/11 mit PowerShell (ist Bestandteil von Windows). Beim ersten Start richtet das Skript die benötigten Administratorrechte automatisch ein (UAC-Abfrage).

## Verwendung

### Interaktiver Modus

```
hdd
```

Startet das farbige Menü. Nach Auswahl einer Aktion werden die verfügbaren Laufwerke angezeigt und das Ziellaufwerk abgefragt (Eingabe `0` wechselt zurück ins Hauptmenü).

### Argumentmodus

| Aufruf | Wirkung |
|---|---|
| `hdd -d C:` | Laufwerk C: defragmentieren |
| `hdd -c C:` | Laufwerk C: auf Fehler prüfen und reparieren |
| `hdd -t C:` | SSD-Trim für Laufwerk C: |
| `hdd -r` | System neustarten |
| `hdd -s` | System herunterfahren |
| `hdd -nc` | Farben deaktivieren (kombinierbar, z. B. `hdd -nc -d C:`) |
| `hdd -h`, `--help`, `/?` | Hilfe anzeigen |

Im Argumentmodus fragt das Skript nicht nach und gibt den Exitcode des ausgeführten Befehls zurück – praktisch für Automatisierung und die Weiterleitung in Dateien (dort empfiehlt sich `-nc`).

### Hinweise

- **Administratorrechte** werden für alle Aktionen benötigt; das Skript startet sich bei Bedarf automatisch mit erhöhten Rechten neu.
- Bei **`chkdsk C:`** erkennt das Skript das Systemlaufwerk und plant die Prüfung beim nächsten Neustart ein, falls das Laufwerk nicht gesperrt werden kann (Bestätigung mit `J`).
- **Diskpart** arbeitet direkt auf den Datenträgern – Befehle dort sorgfältig prüfen.
- Der Terminal-Emulator muss ANSI-Escape-Sequenzen unterstützen (Windows-Terminal und moderne Windows-Versionen tun dies standardmäßig; mit `-nc` läuft alles farblos).

## Lizenz

Copyright © 2026 cvinz78

Dieses Projekt ist unter der [GPL-3.0](LICENSE) (GNU General Public License v3.0) lizenziert.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
