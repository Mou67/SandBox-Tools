<div align="center">

# Windows Sandbox Dev/Test Toolkit

Portable Entwickler/Test-Umgebung in Sekunden: Dark Mode + essentielle Tools in einer Windows Sandbox.

_Version: 0.2.0_

</div>

Dieses Setup erstellt eine Windows Sandbox Konfiguration (.wsb), die beim Start:

1. Ein Startskript (`bootstrap.ps1`) ausführt, das
   - Dark Mode aktiviert (System + Apps)
   - Optional mehrere portable Tools für schnelles Testen installiert
2. Diesen Ordner als beschreibbares Mapping einbindet – nur hier bzw. im gemappten Ordner bleibt etwas erhalten (auf Host-Seite).

## Dateien
- `WindowsSandbox.wsb` – Sandbox Konfigurationsdatei (Start doppelklicken)
- `bootstrap.ps1` – PowerShell Script mit allen Installationslogiken und Schaltern

## Quick Start
1. Repo klonen oder ZIP herunterladen.
2. (Optional) In `bootstrap.ps1` Schalter anpassen.
3. `SandboxNotepadDark.wsb` doppelklicken.
4. Warten bis `--- Bootstrap fertig ---` erscheint.
5. Tools nutzen (PATH ist bereits gesetzt).

Abbruch jederzeit möglich – beim nächsten Start beginnt alles frisch (Sandbox ist flüchtig).

## Optionale Tools / Schalter
Im Kopf des Skripts:

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `$InstallNotepadPP` | `$true` | Notepad++ portable |
| `$InstallGitPortable` | `$true` | Git Portable (ohne Installer) |
| `$Install7Zip` | `$true` | 7-Zip portable (Entpacken weiterer Archive) |
| `$InstallSysinternals` | `$false` | Sysinternals Suite (Prozess-/Systemanalyse) |
| `$InstallPython` | `$true` | Python Embeddable (Basis; pip kann manuell ergänzt werden) |
| `$InstallNode` | `$true` | Node.js (ZIP) |
| `$InstallPester` | `$true` | PowerShell Test-Framework |

Anpassung: Auf `$false` setzen, falls nicht benötigt (spart Download-Zeit).

## Ergänzende Hinweise zu einzelnen Tools
- Python Embeddable: Standardmäßig kein `pip`. Um pip nachzurüsten:
   1. `Invoke-WebRequest https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py`
   2. `python get-pip.py`
- Git Portable: Konfiguration (Name/Email) bei Bedarf setzen: `git config --global user.name "Name"` / `git config --global user.email "mail@example.com"`.
- Node.js: `npm` ist enthalten. Bei Paket-Cache-Warnungen ggf. mit `npm config set fund false` unterdrücken.
- Sysinternals: Standardmäßig EULA akzeptieren durch ersten Start eines Tools – kann per `-accepteula` Parameter erfolgen.

## Pfad & Shortcuts
- Alle Tools landen unter `Desktop\Tools` in Unterordnern.
- Wichtige Binärverzeichnisse werden an den Benutzer-PATH (nur für Sandbox-Sitzung) vorn angefügt.
- Desktop-Verknüpfungen für wichtige GUI-Programme (z.B. Notepad++).

## Hinweise
- Sandbox ist flüchtig: Alles außerhalb gemappter Ordner verschwindet beim Schließen.
- Theme-Änderung wird durch Explorer-Neustart wirksam.
- Downloads benötigen Internetzugang; bei Proxy ggf. `-Proxy` Parameter anpassen.
- Speicher/RAM in `.wsb` via `<MemoryInMB>` anpassbar.

## Bekannte Limitierungen
- Keine permanente Installation in Systempfade (bewusst vermieden, portabel nur im Benutzerkontext).
- Python Embeddable hat eingeschränkte Standardbibliotheken (aber ausreichend für schnelle Skripte). Pip muss nachinstalliert werden.

## Erweiterungsideen (optional)
- VS Code (User Zip) automatisch hinzufügen.
- Chromium / Edge DevTools Skripte.
- Automatisierte Tests (z.B. kleine Pester Suites).

## Projektstruktur
```
WindowsSandboxNotepadDark/
 ├─ SandboxNotepadDark.wsb         # Sandbox Konfiguration (Mapped Folder + Autostart Script)
 ├─ bootstrap.ps1                  # Hauptskript (Install, Config, Logging)
 ├─ README.md
 ├─ CHANGELOG.md
 ├─ VERSION
 ├─ LICENSE (MIT)
 └─ .gitignore
```

## Lizenz
MIT – siehe `LICENSE`.

## Beitrag / Ideen
Issues / PRs willkommen: Weitere portable Tools, VS Code Integration, automatisierte Tests.

---
