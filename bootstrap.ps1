<#
  Bootstrap Script inside Windows Sandbox
  - Setzt Dark Mode
  - Installiert optional eine Reihe portabler Test-/Dev-Tools ohne System-MSI (alles in Desktop\Tools)

  Anpassung: Schalter am Kopf setzen.
  Hinweis: Sandbox ist flüchtig – alles außerhalb gemappter Ordner geht verloren.
#>

$ErrorActionPreference = 'Stop'

# Ob am Ende auf Enter gewartet werden soll (damit Fenster nicht sofort schließt)
$PauseAtEnd = $true

# Logging / Transcript
$LogRoot = "$env:USERPROFILE\Desktop\WindowsSandboxNotepadDark\logs"
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$TranscriptPath = Join-Path $LogRoot "bootstrap-$Timestamp.log"
Start-Transcript -Path $TranscriptPath -Append | Out-Null

# Globaler Fehlerindikator
$global:ScriptFailed = $false

trap {
    $global:ScriptFailed = $true
    Write-Host "[TRAP] Unerwarteter Fehler: $($_.Exception.GetType().Name): $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Siehe Log: $TranscriptPath" -ForegroundColor Yellow
    # Kein break -> Script läuft bis zum Ende weiter und pausiert dort.
}

# ==== Schalter ====
$InstallNotepadPP = $true       # Notepad++ portable
$InstallGitPortable = $true     # Git Portable (Git for Windows Portable-Variante)
$Install7Zip = $true            # 7-Zip portable
$InstallSysinternals = $false   # Sysinternals Suite
$InstallPython = $true          # Python Embeddable (nur Basis, kein pip vorinstalliert – pip kann nachgezogen werden)
$InstallNode = $true            # Node.js (zip)
$InstallPester = $true          # PowerShell Pester Modul für Tests

# ==== Versionen / URLs ====
$NotepadPPVersion = '8.6.9'
$NotepadPPUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$NotepadPPVersion/npp.$NotepadPPVersion.portable.x64.zip"

# Git Portable – Quelle: PortableGit von Git for Windows Release (angepasste Version falls neue Version, ggf. aktualisieren)
$GitVersion = '2.45.2'
$GitPortableUrl = "https://github.com/git-for-windows/git/releases/download/v$GitVersion.windows.1/PortableGit-$GitVersion-64-bit.7z.exe"

# 7-Zip
$SevenZipVersion = '24.07'
$SevenZipUrl = "https://www.7-zip.org/a/7z$($SevenZipVersion -replace '\.', '')-x64.zip"  # 24.07 -> 2407

# Sysinternals Suite
$SysinternalsUrl = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'

# Python Embeddable (Achtung: Version ggf. anpassen)
$PythonVersion = '3.12.4'
$PythonEmbedUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-embed-amd64.zip"

# Node.js (ZIP) – LTS bevorzugt
$NodeVersion = '20.16.0'
$NodeZipUrl = "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-win-x64.zip"

# Verzeichnisse
$ToolsRoot = "$env:USERPROFILE\Desktop\Tools"
New-Item -ItemType Directory -Path $ToolsRoot -Force | Out-Null
$BinDir = Join-Path $ToolsRoot 'bin'
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

# ==== Helper Funktionen ====
function Write-Section($title) { Write-Host "`n==== $title ====\n" -ForegroundColor Cyan }

function Download-File {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination
    )
    Write-Host "[DL] $Url -> $Destination"
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
}

function Expand-Zip {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$Destination
    )
    Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force
}

function Add-ToPathFront {
    param([string]$PathToAdd)
    if (-not (Test-Path $PathToAdd)) { return }
    $current = [Environment]::GetEnvironmentVariable('Path','User')
    if ($current -notmatch [Regex]::Escape($PathToAdd)) {
        [Environment]::SetEnvironmentVariable('Path', "$PathToAdd;" + $current,'User')
    }
    $env:Path = "$PathToAdd;" + $env:Path
}

function Create-Shortcut {
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$LinkPath,
        [string]$Arguments,
        [string]$WorkingDir,
        [string]$IconPath
    )
    $wsh = New-Object -ComObject WScript.Shell
    $sc = $wsh.CreateShortcut($LinkPath)
    $sc.TargetPath = $Target
    if ($Arguments) { $sc.Arguments = $Arguments }
    if ($WorkingDir) { $sc.WorkingDirectory = $WorkingDir }
    if ($IconPath) { $sc.IconLocation = $IconPath }
    $sc.Save()
}

Write-Section 'Dark Mode aktivieren'
Write-Host "[INFO] Setze Dark Mode..."
# Dark Mode Registry Keys
$regPaths = @(
    'HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
)
foreach ($p in $regPaths) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    New-ItemProperty -Path $p -Name AppsUseLightTheme -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $p -Name SystemUsesLightTheme -Value 0 -PropertyType DWord -Force | Out-Null
}

# Explorer neustarten, damit Theme greift
Write-Host "[INFO] Starte Explorer neu..."
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Section 'Tool Installationen'
$summary = @()

if ($InstallNotepadPP) {
    try {
        $toolDir = Join-Path $ToolsRoot 'notepadpp'
        New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        $zip = Join-Path $env:TEMP 'npp.zip'
        Download-File -Url $NotepadPPUrl -Destination $zip
        Expand-Zip -ZipPath $zip -Destination $toolDir
        $exe = Get-ChildItem -Path $toolDir -Filter 'notepad++.exe' -Recurse | Select-Object -First 1
        if ($exe) {
            Create-Shortcut -Target $exe.FullName -LinkPath "$env:USERPROFILE\Desktop\Notepad++.lnk" -WorkingDir $exe.DirectoryName -IconPath $exe.FullName
            Add-ToPathFront $exe.DirectoryName
            $summary += 'Notepad++'
            Write-Host "[OK] Notepad++ installiert." -ForegroundColor Green
        }
    } catch { Write-Warning "[FAIL] Notepad++: $_" }
} else { Write-Host "[SKIP] Notepad++" }

if ($Install7Zip) {
    try {
        $toolDir = Join-Path $ToolsRoot '7zip'
        New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        $zip = Join-Path $env:TEMP '7zip.zip'
        Download-File -Url $SevenZipUrl -Destination $zip
        Expand-Zip -ZipPath $zip -Destination $toolDir
        $exe = Get-ChildItem -Path $toolDir -Filter '7z.exe' -Recurse | Select-Object -First 1
        if ($exe) { Add-ToPathFront $exe.DirectoryName; $summary += '7-Zip'; Write-Host "[OK] 7-Zip" -ForegroundColor Green }
    } catch { Write-Warning "[FAIL] 7-Zip: $_" }
} else { Write-Host "[SKIP] 7-Zip" }

if ($InstallGitPortable) {
    try {
        $toolDir = Join-Path $ToolsRoot 'git'
        New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        $arch = Join-Path $env:TEMP 'git-portable.7z.exe'
        Download-File -Url $GitPortableUrl -Destination $arch
        # PortableGit ist ein selbstentpackendes 7z – /VERYSILENT funktioniert hier nicht, daher 7z entpacken wenn 7z vorhanden, sonst Start-Process -> extrahiert in Unterordner
        # Wir versuchen zuerst mit bereits installiertem 7-Zip (falls Reihenfolge 7-Zip vorher) ansonsten führen wir aus und warten.
        if (Get-Command 7z.exe -ErrorAction SilentlyContinue) {
            & 7z.exe x $arch -o$toolDir -y | Out-Null
        } else {
            Start-Process -FilePath $arch -ArgumentList "-y" -Wait
            # Fallback: Sucht nach PortableGit-* im TEMP und verschiebt
            $pg = Get-ChildItem -Path $env:TEMP -Directory -Filter 'PortableGit*' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($pg) { Copy-Item -Path $pg.FullName\* -Destination $toolDir -Recurse -Force }
        }
        $gitExe = Get-ChildItem -Path $toolDir -Filter 'git.exe' -Recurse | Where-Object { $_.DirectoryName -match 'cmd$' } | Select-Object -First 1
        if ($gitExe) {
            Add-ToPathFront $gitExe.DirectoryName
            $summary += 'Git'
            Write-Host "[OK] Git Portable" -ForegroundColor Green
        }
    } catch { Write-Warning "[FAIL] Git: $_" }
} else { Write-Host "[SKIP] Git" }

if ($InstallSysinternals) {
    try {
        $toolDir = Join-Path $ToolsRoot 'sysinternals'
        New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        $zip = Join-Path $env:TEMP 'sysinternals.zip'
        Download-File -Url $SysinternalsUrl -Destination $zip
        Expand-Zip -ZipPath $zip -Destination $toolDir
        Add-ToPathFront $toolDir
        $summary += 'Sysinternals'
        Write-Host "[OK] Sysinternals" -ForegroundColor Green
    } catch { Write-Warning "[FAIL] Sysinternals: $_" }
} else { Write-Host "[SKIP] Sysinternals" }

if ($InstallPython) {
    try {
        $toolDir = Join-Path $ToolsRoot 'python'
        New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        $zip = Join-Path $env:TEMP 'python-embed.zip'
        Download-File -Url $PythonEmbedUrl -Destination $zip
        Expand-Zip -ZipPath $zip -Destination $toolDir
        # Aktiviert site import (pyvenv.cfg ist nicht vorhanden in embed; für pip müssen wir später ensurepip holen)
        # Entferne eventuell vorhandene pythonXY._pth Einschränkung (kommentiere import site ein)
        Get-ChildItem $toolDir -Filter 'python*.pth' | ForEach-Object {
            (Get-Content $_.FullName) -replace '^#(import site)$','$1' | Set-Content $_.FullName -Encoding ASCII
        }
        $pythonExe = Join-Path $toolDir 'python.exe'
        if (Test-Path $pythonExe) {
            Add-ToPathFront $toolDir
            $summary += 'Python'
            Write-Host "[OK] Python Embeddable" -ForegroundColor Green
        }
    } catch { Write-Warning "[FAIL] Python: $_" }
} else { Write-Host "[SKIP] Python" }

if ($InstallNode) {
    try {
        $toolDir = Join-Path $ToolsRoot 'node'
        New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
        $zip = Join-Path $env:TEMP 'node.zip'
        Download-File -Url $NodeZipUrl -Destination $zip
        Expand-Zip -ZipPath $zip -Destination $toolDir
        $inner = Get-ChildItem -Path $toolDir -Directory -Filter "node-v$NodeVersion-win-x64" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($inner) {
            Get-ChildItem $inner.FullName | ForEach-Object { Move-Item $_.FullName -Destination $toolDir -Force }
            Remove-Item $inner.FullName -Recurse -Force
        }
        $nodeExe = Join-Path $toolDir 'node.exe'
        if (Test-Path $nodeExe) {
            Add-ToPathFront $toolDir
            $summary += 'Node.js'
            Write-Host "[OK] Node.js" -ForegroundColor Green
        }
    } catch { Write-Warning "[FAIL] Node.js: $_" }
} else { Write-Host "[SKIP] Node.js" }

if ($InstallPester) {
    try {
        Write-Host "[INFO] Installiere Pester (PowerShell Gallery)..."
        # Gallery TLS kann in Sandbox manchmal Policies brauchen
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
        $summary += 'Pester'
        Write-Host "[OK] Pester" -ForegroundColor Green
    } catch { Write-Warning "[FAIL] Pester: $_" }
} else { Write-Host "[SKIP] Pester" }

Write-Section 'Zusammenfassung'
Write-Host ('Installiert: ' + ($summary -join ', '))
Write-Host "Path: $env:Path" | Out-Null

Write-Host "`n[DONE] Setup abgeschlossen." -ForegroundColor Cyan
Write-Host "Log-Datei: $TranscriptPath" -ForegroundColor DarkCyan
if ($PauseAtEnd) {
    if ($global:ScriptFailed) {
        Write-Host 'Es gab Fehler. Log prüfen. Enter zum Schließen...' -ForegroundColor Red
    } else {
        Write-Host 'Alles fertig. Enter zum Schließen...' -ForegroundColor Green
    }
    Read-Host | Out-Null
}
Stop-Transcript | Out-Null
