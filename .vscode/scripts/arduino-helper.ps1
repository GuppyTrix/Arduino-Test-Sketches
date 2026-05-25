# Arduino smart task helper.
# Resolves a target .ino sketch, derives board context from its folder,
# merges optional board-level arduino.json overrides into the workspace
# .vscode/arduino.json (excluding port), and triggers the Arduino
# Community Edition extension's verify or upload command.

[CmdletBinding()]
param(
    [string]$SketchFile = '',
    [Parameter(Mandatory = $true)]
    [ValidateSet('verify', 'upload')]
    [string]$Action,
    [switch]$ForceSelect
)

$ErrorActionPreference = 'Stop'

# --- Board folder -> FQBN map. Add new boards here. ---
$BoardMap = @{
    'ESP32-S3-WROOM-1' = 'esp32:esp32:esp32s3'
    'arduino-uno'      = 'arduino:avr:uno'
}

# --- Resolve workspace root (two levels up from this script: .vscode/scripts/.. /..) ---
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$WorkspaceCfg  = Join-Path $WorkspaceRoot '.vscode\arduino.json'

function Write-Info  ($msg) { Write-Host "[arduino-helper] $msg" -ForegroundColor Cyan }
function Write-Warn2 ($msg) { Write-Host "[arduino-helper] $msg" -ForegroundColor Yellow }
function Write-Err2  ($msg) { Write-Host "[arduino-helper] $msg" -ForegroundColor Red }

function Select-SketchInteractive {
    Write-Info "Scanning workspace for .ino files..."
    $inoFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Filter '*.ino' -File `
        | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\\.git\\' } `
        | Sort-Object FullName

    if (-not $inoFiles -or $inoFiles.Count -eq 0) {
        Write-Err2 "No .ino files found in workspace."
        exit 1
    }

    Write-Host ""
    Write-Host "Available sketches:" -ForegroundColor Green
    for ($i = 0; $i -lt $inoFiles.Count; $i++) {
        $rel = $inoFiles[$i].FullName.Substring($WorkspaceRoot.Length).TrimStart('\','/')
        Write-Host ("  [{0}] {1}" -f ($i + 1), $rel)
    }
    Write-Host ""

    while ($true) {
        $answer = Read-Host "Select sketch number (1-$($inoFiles.Count))"
        if ($answer -match '^\d+$') {
            $idx = [int]$answer - 1
            if ($idx -ge 0 -and $idx -lt $inoFiles.Count) {
                return $inoFiles[$idx].FullName
            }
        }
        Write-Warn2 "Invalid selection."
    }
}

function Resolve-BoardFolder ($sketchFullPath) {
    $rel = $sketchFullPath.Substring($WorkspaceRoot.Length).TrimStart('\','/')
    $parts = $rel -split '[\\/]'
    if ($parts.Count -lt 2) {
        Write-Err2 "Sketch is not inside a board folder: $rel"
        exit 1
    }
    return $parts[0]
}

function Load-JsonFile ($path) {
    if (-not (Test-Path $path)) { return $null }
    $raw = Get-Content -Raw -Path $path
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return $raw | ConvertFrom-Json
}

function ConvertTo-Hashtable ($obj) {
    $ht = [ordered]@{}
    if ($null -eq $obj) { return $ht }
    foreach ($p in $obj.PSObject.Properties) {
        $ht[$p.Name] = $p.Value
    }
    return $ht
}

# --- 1. Resolve sketch ---
$useInteractive = $ForceSelect -or `
                  [string]::IsNullOrWhiteSpace($SketchFile) -or `
                  -not (Test-Path $SketchFile) -or `
                  ([System.IO.Path]::GetExtension($SketchFile)).ToLower() -ne '.ino'

if ($useInteractive) {
    Write-Err2 "Active file is not a valid .ino sketch. Open a sketch file and run the task again."
    exit 1
}

$SketchFile = (Resolve-Path $SketchFile).Path
Write-Info "Sketch: $SketchFile"

# --- 2. Board context ---
$boardFolder = Resolve-BoardFolder $SketchFile
if (-not $BoardMap.ContainsKey($boardFolder)) {
    Write-Err2 "No FQBN mapping for board folder '$boardFolder'. Add it to `$BoardMap in arduino-helper.ps1."
    exit 1
}
$fqbn = $BoardMap[$boardFolder]
Write-Info "Board folder: $boardFolder  ->  FQBN: $fqbn"

# --- 3. Load base + override configs ---
if (-not (Test-Path $WorkspaceCfg)) {
    Write-Err2 "Workspace arduino.json not found at $WorkspaceCfg"
    exit 1
}
$baseCfg = ConvertTo-Hashtable (Load-JsonFile $WorkspaceCfg)

$overridePathPreferred = Join-Path $WorkspaceRoot "$boardFolder\.vscode\arduino.json"
$overridePathFallback  = Join-Path $WorkspaceRoot "$boardFolder\arduino.json"
$overrideCfg = $null
$overrideUsed = $null
if (Test-Path $overridePathPreferred) {
    $overrideCfg  = ConvertTo-Hashtable (Load-JsonFile $overridePathPreferred)
    $overrideUsed = $overridePathPreferred
} elseif (Test-Path $overridePathFallback) {
    $overrideCfg  = ConvertTo-Hashtable (Load-JsonFile $overridePathFallback)
    $overrideUsed = $overridePathFallback
}

# --- 4. Merge override (port from override is ignored) ---
$merged = [ordered]@{}
foreach ($k in $baseCfg.Keys) { $merged[$k] = $baseCfg[$k] }

if ($overrideCfg) {
    Write-Info "Applying board override: $overrideUsed"
    foreach ($k in $overrideCfg.Keys) {
        if ($k -ieq 'port') {
            Write-Warn2 "Ignoring 'port' from board override (workspace port is authoritative)."
            continue
        }
        $merged[$k] = $overrideCfg[$k]
    }
}

# Ensure FQBN from board map wins unless override explicitly set 'board'
if (-not ($overrideCfg -and $overrideCfg.Contains('board'))) {
    $merged['board'] = $fqbn
}

# --- 5. Sketch + output paths (workspace-relative, backslash style) ---
$sketchRel = $SketchFile.Substring($WorkspaceRoot.Length).TrimStart('\','/')
$sketchRel = $sketchRel -replace '/', '\'
$sketchBase = [System.IO.Path]::GetFileNameWithoutExtension($SketchFile)
$outputRel  = "build\$boardFolder\$sketchBase-build"

$merged['sketch'] = $sketchRel
$merged['output'] = $outputRel

# Preserve original workspace port even if base lacked it (no-op if present)
if ($baseCfg.Contains('port')) {
    $merged['port'] = $baseCfg['port']
}

# --- 6. Persist merged config ---
$json = ($merged | ConvertTo-Json -Depth 20)
Set-Content -Path $WorkspaceCfg -Value $json -Encoding UTF8
Write-Info "Updated $WorkspaceCfg"
Write-Host $json -ForegroundColor DarkGray

# --- 7. Trigger Arduino extension via its own keyboard shortcut ---
# In this environment, VS Code supports neither `code --execute-command` nor
# external `vscode://command/...` URIs, and tasks cannot invoke extension
# commands directly. The reliable workaround on Windows is to focus VS Code
# and replay a custom non-printing keyboard shortcut bound by the user:
#   arduino.verify -> Ctrl+Alt+F9
#   arduino.upload -> Ctrl+Alt+F10

# Ensure the target sketch is the active editor in the existing window first.
$codeExe = Get-Command code -ErrorAction SilentlyContinue
if ($codeExe) {
    & code --reuse-window --goto "$SketchFile" | Out-Null
} else {
    Write-Warn2 "'code' CLI not found; relying on already-active editor."
}

$vkKey = if ($Action -eq 'upload') { 0x79 } else { 0x78 }   # F10 / F9
$cmdLabel = if ($Action -eq 'upload') { 'arduino.upload (Ctrl+Alt+F10)' } else { 'arduino.verify (Ctrl+Alt+F9)' }
Write-Info "Activating VS Code and sending $cmdLabel..."

if (-not ('NativeWin' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeWin {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
}
"@
}

# Find a VS Code window. Matches Code/Code - Insiders/etc., preferring the
# window whose title contains this workspace folder name.
$wsName = Split-Path -Leaf $WorkspaceRoot
$vsProc = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 -and $_.ProcessName -match '^Code' -and $_.MainWindowTitle } |
    Sort-Object @{ Expression = { if ($_.MainWindowTitle -like "*${wsName}*") { 0 } else { 1 } } }, StartTime |
    Select-Object -First 1

if (-not $vsProc) {
    Write-Err2 "Could not locate a VS Code window. Make sure VS Code is running."
    exit 1
}

if ([NativeWin]::IsIconic($vsProc.MainWindowHandle)) {
    [NativeWin]::ShowWindowAsync($vsProc.MainWindowHandle, 9) | Out-Null   # SW_RESTORE
}
[NativeWin]::SetForegroundWindow($vsProc.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 350

# Synthesize Ctrl+Alt+Fn using discrete key events. Function keys do not map to
# printable text, so they avoid AltGr/layout issues like the injected 'ú'.
$VK_CONTROL = [byte]0x11
$VK_MENU    = [byte]0x12   # Alt
$KEYDOWN    = 0x0000
$KEYUP      = 0x0002
$zero       = [UIntPtr]::Zero

[NativeWin]::keybd_event($VK_CONTROL, 0, $KEYDOWN, $zero)
[NativeWin]::keybd_event($VK_MENU,    0, $KEYDOWN, $zero)
[NativeWin]::keybd_event([byte]$vkKey, 0, $KEYDOWN, $zero)
Start-Sleep -Milliseconds 30
[NativeWin]::keybd_event([byte]$vkKey, 0, $KEYUP,   $zero)
[NativeWin]::keybd_event($VK_MENU,    0, $KEYUP,   $zero)
[NativeWin]::keybd_event($VK_CONTROL, 0, $KEYUP,   $zero)

Write-Info "Sent shortcut. Watch the Arduino output panel for compile/upload progress."
