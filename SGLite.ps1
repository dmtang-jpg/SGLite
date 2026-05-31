# SGLite v2.1.1
# Lightweight SG Pinyin optimizer - removes bloatware, keeps IME core
# https://github.com/dmtang-jpg/SGLite
# License: MIT

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'
$Version = '2.1.1'

# --- UTF-8 Encoding (fix Chinese display on Windows) ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}

# --- Create HKCR PSDrive (not available by default) ---
if (-not (Test-Path 'HKCR:')) {
    New-PSDrive -PSProvider Registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue | Out-Null
}

# --- Configuration ---
# Note: 'SogouInput' is the actual installation directory name on disk
$SGBase = 'C:\Program Files (x86)\SogouInput'
$SGAppData = $env:LOCALAPPDATA
$SGAppDataRoaming = $env:APPDATA
$ProgramData = $env:ProgramData

# === ALL non-IME executables ===
$ExtraExeNames = @(
    # Toolbox & Updater
    'SGTool.exe', 'SGDownload.exe', 'PinyinUp.exe', 'SogouToolkits.exe',
    # Assistant & Cloud
    'SGWangzai.exe', 'SGSmartAssistant.exe', 'SogouCloud.exe',
    # Web & Browser
    'SGWebRender.exe', 'SGWizard.exe', 'SGBrowserProtect.exe',
    # Screenshots & Media
    'screencapture.exe', 'SGKaomoji.exe', 'SGIGuideHelper.exe',
    # Business & Game
    'SGBizLauncher.exe', 'SGBizCenter.exe', 'SGGameCenter.exe',
    # Desktop & Wallpaper
    'SGDeskControl.exe', 'SGWallPaper.exe',
    # Feedback & Crash
    'sgfeedbackhelper.exe', 'userNetSchedule.exe', 'crashrpt.exe',
    # Bundled Software
    'SGCleaner.exe', 'SGSkinBox.exe',
    # Compression service
    'kzip_sogou.exe', 'kzipmgr_sogou.exe',
    # Picture viewer & disk manager
    'kfastpic_sogou.exe', 'kdiskmgr_sogou.exe'
)

# === ALL non-IME plugin directories (in Components/) ===
$ExtraPluginDirs = @(
    # Original
    'AppBox', 'IChat', 'PicFace', 'SGDeskControl', 'SkinBox',
    'SogouFlash', 'Theme', 'VoiceInput', 'WriteSpirit',
    # Business & Game
    'biz_center', 'biz_pdf', 'game_center',
    # Desktop & System
    'isgpet', 'systembeautify', 'wallpaper',
    # Compression & PDF
    'kzip', 'pdf_module', 'screenshot',
    # Browser & Web
    'browser_protect', 'sgbrowser', 'web_helper',
    # Translation & Dictionary
    'sgtranslate', 'sgdict',
    # Skin & Emoji
    'kaomoji', 'emoji_panel', 'skin_center'
)

# === Bundled software in AppData ===
$BundledAppDataDirs = @(
    'fastpdf_sogou', 'kdiskmgr_sogou', 'kfastpic_sogou',
    'kzip_sogou', 'sogoupdf', 'sogousdk',
    'SogouWBInput', 'SogouPY.userscheme'
)

$BundledTempDirs = @(
    'kdiskmgr_sogou', 'kfastpic_sogou', 'kwallpaper_sogou', 'kzip_sogou',
    'sogou_install', 'sogou_update', 'SogouPY'
)

# === Windows Scheduled Tasks (Sogou creates many) ===
$SogouScheduledTasks = @(
    'SogouCloud', 'SGSmartAssistant*',
    'SogouUpdate*', 'SogouSkin*', 'SogouGuard*',
    'SGGameCenter*', 'SGBizCenter*', 'SogouInstaller*',
    'SogouFlash*', 'SogouWallpaper*'
)

# === Registry Shell Extensions (right-click menu) ===
$SogouShellExtKeys = @(
    'HKCR:\CLSID\{37A45932-6FE4-4E69-9545-D2B3B5901B2E}',  # 搜狗压缩
    'HKCR:\CLSID\{978AA259-4E1A-4C81-9247-0B051B17A565}',  # 搜狗快译
    'HKCR:\*\shellex\ContextMenuHandlers\SogouZip',
    'HKCR:\*\shellex\ContextMenuHandlers\SogouKuaizip',
    'HKCR:\*\shellex\ContextMenuHandlers\SGTranslate',
    'HKCR:\Directory\shellex\ContextMenuHandlers\SogouZip',
    'HKCR:\Directory\shellex\ContextMenuHandlers\SogouKuaizip',
    'HKCR:\Directory\Background\shellex\ContextMenuHandlers\SogouZip',
    'HKCR:\Folder\shellex\ContextMenuHandlers\SogouZip',
    'HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\SogouZip',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved\{37A45932-6FE4-4E69-9545-D2B3B5901B2E}'
)

# === Registry Startup Entries ===
$SogouStartupKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
)
$SogouStartupNames = @(
    'SogouCloud', 'SGSmartAssistant',
    'SogouSkin', 'SogouUpdate', 'SGDeskControl',
    'SGGameCenter', 'SGBizCenter', 'SGBrowserProtect',
    'SogouWallpaper', 'SogouInstaller', 'SogouPY'
)

# === Windows Services ===
# Note: SogouImeBroker is the core IME service - do NOT disable it!
$SogouServices = @('SogouSvc')

# === Auto-Update Blocking ===
# Registry keys to disable auto-update
$SogouUpdateRegKeys = @(
    @{ Path = 'HKCU:\SOFTWARE\SogouInput'; Name = 'UpUseBT'; Value = 0 },           # Disable BitTorrent updates
    @{ Path = 'HKCU:\SOFTWARE\SogouInput'; Name = 'PatchFlag'; Value = 0 },          # Disable auto-patching
    @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\SogouInput'; Name = 'PatchFlag'; Value = 0 },
    @{ Path = 'HKCU:\SOFTWARE\SogouInput'; Name = 'AutoUpdate'; Value = 0 },         # Disable auto-update check
    @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\SogouInput'; Name = 'AutoUpdate'; Value = 0 }
)

# Sogou update server domains to block in hosts file
$SogouUpdateDomains = @(
    'pinyin.sogou.com',
    'update.sogou.com',
    'down.sogou.com',
    'cdn.pinyin.sogou.com'
)

# --- Utility Functions ---

function Write-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '  +==============================================+' -ForegroundColor Cyan
    Write-Host "  |         SGLite v$Version                     |" -ForegroundColor Yellow
    Write-Host '  |   Remove bloatware, keep IME core only       |' -ForegroundColor Gray
    Write-Host '  +==============================================+' -ForegroundColor Cyan
    Write-Host ''
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Require-Administrator {
    if (-not (Test-Administrator)) {
        Write-Host '  [ERROR] Administrator privileges required.' -ForegroundColor Red
        Write-Host '  Right-click this script and select "Run as Administrator".' -ForegroundColor Yellow
        Write-Host ''
        Read-Host '  Press Enter to exit'
        exit 1
    }
}

function Find-SGVersion {
    if (-not (Test-Path $SGBase)) {
        return $null
    }
    $versionDir = Get-ChildItem $SGBase -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+' } |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1
    return $versionDir
}

function Get-SGPaths {
    $versionDir = Find-SGVersion
    if (-not $versionDir) {
        return $null
    }
    return @{
        ExeDir     = $versionDir.FullName
        PluginDir  = Join-Path $SGBase 'Components'
        BaseDir    = $SGBase
        Version    = $versionDir.Name
    }
}

# --- Status ---

function Show-Status {
    param([hashtable]$Paths)

    # Check all known ExtraExeNames + SogouImeBroker
    $knownNames = @('SogouImeBroker') + ($ExtraExeNames | ForEach-Object { $_ -replace '\.exe$', '' })
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $knownNames -contains $_.Name
    }
    $runningNames = $procs | ForEach-Object { $_.Name }

    Write-Host '  [Status]' -ForegroundColor White
    Write-Host ''

    # IME Core (SogouImeBroker is the actual process name)
    if ($runningNames -contains 'SogouImeBroker') {
        Write-Host '    IME Core:          ' -NoNewline
        Write-Host 'Running' -ForegroundColor Green
    } else {
        Write-Host '    IME Core:          ' -NoNewline
        Write-Host 'Not Running' -ForegroundColor Red
    }

    # Version
    Write-Host "    Version:           $($Paths.Version)"

    # Extra processes
    $extraRunning = @()
    foreach ($exe in $ExtraExeNames) {
        $name = $exe -replace '\.exe$', ''
        if ($runningNames -contains $name) {
            $extraRunning += $exe
        }
    }
    if ($extraRunning.Count -gt 0) {
        Write-Host "    Extra Processes:   " -NoNewline
        Write-Host "$($extraRunning.Count) running" -ForegroundColor Yellow
        foreach ($ex in $extraRunning) {
            Write-Host "                       - $ex" -ForegroundColor DarkGray
        }
    } else {
        Write-Host '    Extra Processes:   ' -NoNewline
        Write-Host 'Clean' -ForegroundColor Green
    }

    # Disabled count
    $disabledExe = @()
    if (Test-Path $Paths.ExeDir) {
        $disabledExe = Get-ChildItem "$($Paths.ExeDir)\*.exe.disabled" -ErrorAction SilentlyContinue
        $disabledExe += @(Get-ChildItem "$($Paths.ExeDir)\*.exe.disabled.bak" -ErrorAction SilentlyContinue)
    }
    $disabledPlugins = @()
    foreach ($dp in $ExtraPluginDirs) {
        if (Test-Path "$($Paths.PluginDir)\$dp.disabled") {
            $disabledPlugins += $dp
        } elseif (Test-Path "$($Paths.PluginDir)\$dp.disabled.bak") {
            $disabledPlugins += $dp
        }
    }
    Write-Host "    Disabled Exe:      $($disabledExe.Count) / $($ExtraExeNames.Count)"
    Write-Host "    Disabled Plugins:  $($disabledPlugins.Count) / $($ExtraPluginDirs.Count)"
    Write-Host ''
}

# --- Core Operations ---

# Helper: Run external command with timeout (prevents hanging)
function Invoke-WithTimeout {
    param([string]$Command, [int]$TimeoutSec = 5)
    $job = Start-Job -ScriptBlock { param($cmd) Invoke-Expression $cmd } -ArgumentList $Command
    $result = Wait-Job $job -Timeout $TimeoutSec | Receive-Job
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    return $result
}

function Stop-ExtraProcesses {
    Write-Host '  Stopping extra processes...' -ForegroundColor Yellow
    $count = 0

    # Kill ALL Sogou-related processes (one round, with timeout)
    # Note: Do NOT include SogouImeBroker here - it's the core IME process
    $lockProcs = @('SGWebRender','SogouCloud','SGTool','SGBizCenter','SGGameCenter','SGSmartAssistant','SGWangzai')
    foreach ($proc in $lockProcs) {
        try {
            $killed = Stop-Process -Name $proc -Force -PassThru -ErrorAction Stop
            foreach ($k in $killed) {
                Write-Host "    [OK] $($k.Name).exe (PID: $($k.Id))" -ForegroundColor Green
                $count++
            }
        } catch {}
    }
    # taskkill with timeout (prevents hang)
    foreach ($proc in $lockProcs) {
        Invoke-WithTimeout "taskkill /F /IM `"$proc.exe`"" 3 | Out-Null
    }

    if ($count -eq 0) {
        Write-Host '    No extra processes running.' -ForegroundColor Gray
    } else {
        Write-Host "    Stopped $count item(s)." -ForegroundColor Green
    }
    Start-Sleep -Milliseconds 1000
}

# Re-enable Sogou services after cleanup (user may want IME to work after reboot)
function Restore-SogouServices {
    Write-Host '  Restoring Sogou services...' -ForegroundColor Yellow
    $ok = 0
    $sogouServices = @('SogouImeBroker', 'SogouSvc')
    foreach ($svcName in $sogouServices) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc) {
                & sc.exe config $svcName start= auto 2>&1 | Out-Null
                Start-Service -Name $svcName -ErrorAction SilentlyContinue
                Write-Host "    [OK] $svcName (set to auto + started)" -ForegroundColor Green
                $ok++
            } else {
                Write-Host "    [SKIP] $svcName (not found)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    [FAIL] $svcName - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    if ($ok -eq 0) {
        Write-Host '    No Sogou services found.' -ForegroundColor Gray
    } else {
        Write-Host "    Restored $ok service(s)." -ForegroundColor Green
    }
}

function Disable-ExeFiles {
    param([string]$ExeDir)
    Require-Administrator

    Write-Host '  Disabling extra programs...' -ForegroundColor Yellow
    $ok = 0; $skip = 0; $fail = 0

    foreach ($exe in $ExtraExeNames) {
        $path = Join-Path $ExeDir $exe
        if (-not (Test-Path $path)) {
            $skip++
            continue
        }
        $disabledPath = "$path.disabled"

        # Handle existing .disabled from previous run
        if (Test-Path $disabledPath) {
            $backupPath = "$disabledPath.bak"
            if (Test-Path $backupPath) {
                Remove-Item $backupPath -Force -ErrorAction SilentlyContinue
            }
            try {
                Rename-Item -Path $disabledPath -NewName "$exe.disabled.bak" -Force -ErrorAction Stop
            } catch {
                Write-Host "    [WARN] Could not backup old $exe.disabled, skipping." -ForegroundColor Yellow
                continue
            }
        }

        try {
            # Try rename first, escalate permissions only if needed
            try {
                Rename-Item -Path $path -NewName "$exe.disabled" -Force -ErrorAction Stop
            } catch {
                # Take ownership (Administrators group, auto-confirm)
                $null = & takeown /F "$path" /A 2>&1
                $null = & icacls "$path" /grant "*S-1-5-32-544:F" /Q 2>&1
                # Try PowerShell rename again
                try {
                    Rename-Item -Path $path -NewName "$exe.disabled" -Force -ErrorAction Stop
                } catch {
                    # Last resort: cmd rename
                    $null = & cmd /c ren "$path" "$exe.disabled" 2>&1
                    if (-not (Test-Path $disabledPath)) {
                        throw "All rename methods failed for $exe"
                    }
                }
            }
            if (Test-Path $disabledPath) {
                Write-Host "    [OK] $exe" -ForegroundColor Green
                $ok++
            } else {
                Write-Host "    [FAIL] $exe" -ForegroundColor Red
                $fail++
            }
        } catch {
            Write-Host "    [FAIL] $exe - $($_.Exception.Message)" -ForegroundColor Red
            $fail++
        }
    }

    $color = if ($fail -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host "    Done: $ok disabled, $skip skipped, $fail failed" -ForegroundColor $color
}

function Enable-ExeFiles {
    param([string]$ExeDir)
    Require-Administrator

    Write-Host '  Restoring extra programs...' -ForegroundColor Yellow
    $ok = 0

    foreach ($exe in $ExtraExeNames) {
        $disabledPath = Join-Path $ExeDir "$exe.disabled"
        $bakPath = Join-Path $ExeDir "$exe.disabled.bak"

        # Prefer .disabled, fall back to .disabled.bak
        $restoreFrom = $null
        if (Test-Path $disabledPath) {
            $restoreFrom = $disabledPath
        } elseif (Test-Path $bakPath) {
            $restoreFrom = $bakPath
        }
        if (-not $restoreFrom) { continue }

        try {
            # If original exe already exists, remove it first
            $originalPath = Join-Path $ExeDir $exe
            if (Test-Path $originalPath) {
                Remove-Item $originalPath -Force -ErrorAction SilentlyContinue
            }
            Rename-Item -Path $restoreFrom -NewName $exe -Force -ErrorAction Stop
            if (Test-Path $originalPath) {
                $suffix = if ($restoreFrom -eq $bakPath) { " (from backup)" } else { "" }
                Write-Host "    [OK] $exe$suffix" -ForegroundColor Green
                $ok++
            }
        } catch {
            Write-Host "    [FAIL] $exe - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "    Restored $ok program(s)." -ForegroundColor Green
}

function Disable-PluginDirs {
    param([string]$PluginDir)
    Require-Administrator

    Write-Host '  Disabling extra plugins...' -ForegroundColor Yellow
    $ok = 0; $skip = 0; $fail = 0

    # Kill locking processes ONCE before the loop (with timeout to prevent hang)
    # Note: Do NOT include SogouImeBroker here - it's the core IME process
    $lockProcs = @('SGWebRender','SogouCloud','SGTool','SGBizCenter','SGGameCenter')
    foreach ($proc in $lockProcs) {
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
        Invoke-WithTimeout "taskkill /F /IM `"$proc.exe`"" 3 | Out-Null
    }
    Start-Sleep -Milliseconds 500

    # Pre-takeown the entire Components directory (one shot, with timeout)
    Invoke-WithTimeout "takeown /F `"$PluginDir`" /R /A" 10 | Out-Null
    Invoke-WithTimeout "icacls `"$PluginDir`" /grant *S-1-5-32-544:(OI)(CI)F /T /C /Q" 15 | Out-Null

    foreach ($plugin in $ExtraPluginDirs) {
        $path = Join-Path $PluginDir $plugin
        if (-not (Test-Path $path)) {
            $skip++
            continue
        }
        $disabledPath = "$path.disabled"

        # Handle existing .disabled from previous run
        if (Test-Path $disabledPath) {
            $backupPath = "$disabledPath.bak"
            if (Test-Path $backupPath) {
                Remove-Item $backupPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            try {
                Rename-Item -Path $disabledPath -NewName "$plugin.disabled.bak" -Force -ErrorAction Stop
            } catch {
                Write-Host "    [WARN] Could not backup old $plugin.disabled, skipping." -ForegroundColor Yellow
                continue
            }
        }

        # Try 1: Direct PowerShell rename
        $renamed = $false
        try {
            Rename-Item -Path $path -NewName "$plugin.disabled" -Force -ErrorAction Stop
            $renamed = $true
        } catch {}

        # Try 2: cmd /c ren (handles some PS rename failures)
        if (-not $renamed) {
            Invoke-WithTimeout "cmd /c ren `"$path`" `"$plugin.disabled`"" 5 | Out-Null
            if (Test-Path $disabledPath) { $renamed = $true }
        }

        # Try 3: Kill processes again + takeown + cmd ren
        if (-not $renamed) {
            foreach ($proc in $lockProcs) {
                Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
                Invoke-WithTimeout "taskkill /F /IM `"$proc.exe`"" 3 | Out-Null
            }
            Start-Sleep -Milliseconds 300
            Invoke-WithTimeout "takeown /F `"$path`" /R /A" 5 | Out-Null
            Invoke-WithTimeout "icacls `"$path`" /grant *S-1-5-32-544:(OI)(CI)F /T /C /Q" 10 | Out-Null
            Invoke-WithTimeout "cmd /c ren `"$path`" `"$plugin.disabled`"" 5 | Out-Null
            if (Test-Path $disabledPath) { $renamed = $true }
        }

        if ($renamed) {
            Write-Host "    [OK] $plugin/" -ForegroundColor Green
            $ok++
        } else {
            # Show diagnostic: what process has the directory locked?
            $lockingProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
                try { $_.Modules.FileName -like "$path*" } catch { $false }
            }
            $diag = if ($lockingProcs) { "locked by: $($lockingProcs.Name -join ', ')" } else { "permission denied" }
            Write-Host "    [FAIL] $plugin/ ($diag)" -ForegroundColor Red
            $fail++
        }
    }

    $color = if ($fail -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host "    Done: $ok disabled, $skip skipped, $fail failed" -ForegroundColor $color
}

function Enable-PluginDirs {
    param([string]$PluginDir)
    Require-Administrator

    Write-Host '  Restoring extra plugins...' -ForegroundColor Yellow
    $ok = 0

    foreach ($plugin in $ExtraPluginDirs) {
        $disabledPath = Join-Path $PluginDir "$plugin.disabled"
        $bakPath = Join-Path $PluginDir "$plugin.disabled.bak"

        # Prefer .disabled, fall back to .disabled.bak
        $restoreFrom = $null
        if (Test-Path $disabledPath) {
            $restoreFrom = $disabledPath
        } elseif (Test-Path $bakPath) {
            $restoreFrom = $bakPath
        }
        if (-not $restoreFrom) { continue }

        try {
            # If original dir already exists, remove it first
            $originalPath = Join-Path $PluginDir $plugin
            if (Test-Path $originalPath) {
                Remove-Item $originalPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            Rename-Item -Path $restoreFrom -NewName $plugin -Force -ErrorAction Stop
            if (Test-Path $originalPath) {
                $suffix = if ($restoreFrom -eq $bakPath) { " (from backup)" } else { "" }
                Write-Host "    [OK] $plugin/$suffix" -ForegroundColor Green
                $ok++
            }
        } catch {
            Write-Host "    [FAIL] $plugin/ - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "    Restored $ok plugin(s)." -ForegroundColor Green
}

function Remove-BundledSoftware {
    Write-Host '  Cleaning bundled software...' -ForegroundColor Yellow
    $ok = 0

    foreach ($name in $BundledAppDataDirs) {
        $found = $false
        foreach ($basePath in @($SGAppData, $SGAppDataRoaming)) {
            $path = Join-Path $basePath $name
            if (Test-Path $path) {
                try {
                    Remove-Item $path -Recurse -Force -ErrorAction Stop
                    if (-not (Test-Path $path)) {
                        $found = $true
                    } else {
                        Write-Host "    [FAIL] $name (still exists)" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "    [FAIL] $name - $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        if ($found) {
            Write-Host "    [OK] $name" -ForegroundColor Green
            $ok++
        }
    }

    foreach ($name in $BundledTempDirs) {
        $path = Join-Path $SGAppData "Temp\$name"
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                Write-Host "    [OK] Temp/$name" -ForegroundColor Green
                $ok++
            } catch {
                Write-Host "    [FAIL] Temp/$name - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # ProgramData cleanup
    $sgDataDir = Join-Path $ProgramData 'SogouInput'
    if (Test-Path $sgDataDir) {
        $cleanDirs = @('SGSmartAssistant', 'SGCefCache', 'wangzairootdir', 'wrizardrootdir')
        foreach ($d in $cleanDirs) {
            $p = Join-Path $sgDataDir $d
            if (Test-Path $p) {
                try {
                    Remove-Item $p -Recurse -Force -ErrorAction Stop
                    Write-Host "    [OK] ProgramData/$d" -ForegroundColor Green
                    $ok++
                } catch {
                    # Ignore locked files
                }
            }
        }
    }

    Write-Host "    Cleaned $ok item(s)." -ForegroundColor Green
}

function Remove-ScheduledTasks {
    Write-Host '  Removing Sogou scheduled tasks...' -ForegroundColor Yellow
    $ok = 0
    foreach ($taskPattern in $SogouScheduledTasks) {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like $taskPattern }
        foreach ($task in $tasks) {
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
                Write-Host "    [OK] $($task.TaskName)" -ForegroundColor Green
                $ok++
            } catch {
                Write-Host "    [FAIL] $($task.TaskName) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    if ($ok -eq 0) {
        Write-Host '    No Sogou scheduled tasks found.' -ForegroundColor Gray
    } else {
        Write-Host "    Removed $ok task(s)." -ForegroundColor Green
    }
}

function Remove-ShellExtensions {
    Write-Host '  Removing Sogou right-click menu entries...' -ForegroundColor Yellow
    Require-Administrator
    $ok = 0
    foreach ($key in $SogouShellExtKeys) {
        if (Test-Path -LiteralPath $key) {
            try {
                Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction Stop
                Write-Host "    [OK] $key" -ForegroundColor Green
                $ok++
            } catch {
                Write-Host "    [FAIL] $key - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    # Also search for any Sogou-related context menu handlers dynamically
    $cmPaths = @(
        'HKCR:\*\shellex\ContextMenuHandlers',
        'HKCR:\Directory\shellex\ContextMenuHandlers',
        'HKCR:\Folder\shellex\ContextMenuHandlers',
        'HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers'
    )
    foreach ($cmPath in $cmPaths) {
        if (Test-Path -LiteralPath $cmPath) {
            Get-ChildItem -LiteralPath $cmPath -ErrorAction SilentlyContinue | ForEach-Object {
                $name = $_.PSChildName
                if ($name -match 'Sogou|kzip|kuaizip') {
                    try {
                        Remove-Item -LiteralPath $_.PSPath -Recurse -Force -ErrorAction Stop
                        Write-Host "    [OK] $cmPath\$name" -ForegroundColor Green
                        $ok++
                    } catch {}
                }
            }
        }
    }
    if ($ok -eq 0) {
        Write-Host '    No Sogou shell extensions found.' -ForegroundColor Gray
    } else {
        Write-Host "    Removed $ok shell extension(s)." -ForegroundColor Green
    }
}

function Remove-StartupEntries {
    Write-Host '  Removing Sogou startup entries...' -ForegroundColor Yellow
    $ok = 0
    foreach ($regPath in $SogouStartupKeys) {
        if (-not (Test-Path $regPath)) { continue }
        foreach ($name in $SogouStartupNames) {
            $val = Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue
            if ($val) {
                try {
                    Remove-ItemProperty -Path $regPath -Name $name -Force -ErrorAction Stop
                    Write-Host "    [OK] $regPath\$name" -ForegroundColor Green
                    $ok++
                } catch {
                    Write-Host "    [FAIL] $name - $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
    if ($ok -eq 0) {
        Write-Host '    No Sogou startup entries found.' -ForegroundColor Gray
    } else {
        Write-Host "    Removed $ok startup entry/ies." -ForegroundColor Green
    }
}

function Remove-SogouServices {
    Write-Host '  Disabling Sogou Windows services...' -ForegroundColor Yellow
    Require-Administrator
    $ok = 0
    foreach ($svcName in $SogouServices) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc) {
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                & sc.exe config $svcName start= disabled 2>&1 | Out-Null
                Write-Host "    [OK] $svcName (stopped + disabled)" -ForegroundColor Green
                $ok++
            }
        } catch {}
    }
    if ($ok -eq 0) {
        Write-Host '    No Sogou services found.' -ForegroundColor Gray
    } else {
        Write-Host "    Disabled $ok service(s)." -ForegroundColor Green
    }
}

function Block-AutoUpdate {
    Write-Host '  Blocking Sogou auto-update...' -ForegroundColor Yellow
    Require-Administrator
    $ok = 0

    # 1. Set registry keys to disable auto-update
    foreach ($reg in $SogouUpdateRegKeys) {
        try {
            if (-not (Test-Path $reg.Path)) {
                New-Item -Path $reg.Path -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type DWord -Force -ErrorAction Stop
            Write-Host "    [OK] $($reg.Path)\$($reg.Name) = $($reg.Value)" -ForegroundColor Green
            $ok++
        } catch {
            Write-Host "    [FAIL] $($reg.Path)\$($reg.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 2. Block update servers in hosts file
    $hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
    $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
    $hostsModified = $false

    foreach ($domain in $SogouUpdateDomains) {
        $entry = "127.0.0.1 $domain"
        $existingEntry = $hostsContent | Where-Object { $_ -match "^\s*\d+\.\d+\.\d+\.\d+\s+$([regex]::Escape($domain))\s*$" }
        if (-not $existingEntry) {
            try {
                Add-Content -Path $hostsPath -Value $entry -Force -ErrorAction Stop
                Write-Host "    [OK] hosts: $domain blocked" -ForegroundColor Green
                $ok++
                $hostsModified = $true
            } catch {
                Write-Host "    [FAIL] hosts: $domain - $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "    [SKIP] hosts: $domain already blocked" -ForegroundColor Gray
        }
    }

    # Flush DNS cache after hosts modification
    if ($hostsModified) {
        & ipconfig /flushdns 2>&1 | Out-Null
        Write-Host "    [OK] DNS cache flushed" -ForegroundColor Green
    }

    # 3. Create Windows Firewall rules to block update executables
    $updateExes = @('PinyinUp.exe', 'SGDownload.exe', 'SogouToolkits.exe')
    $exeDir = (Find-SGVersion).FullName
    if ($exeDir) {
        foreach ($exe in $updateExes) {
            $exePath = Join-Path $exeDir $exe
            if (Test-Path $exePath) {
                $ruleName = "SGLite Block $exe"
                $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                if (-not $existingRule) {
                    try {
                        New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -Program $exePath -Enabled True -ErrorAction Stop | Out-Null
                        Write-Host "    [OK] Firewall: $exe blocked" -ForegroundColor Green
                        $ok++
                    } catch {
                        Write-Host "    [FAIL] Firewall: $exe - $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "    [SKIP] Firewall: $exe already blocked" -ForegroundColor Gray
                }
            }
        }
    }

    if ($ok -eq 0) {
        Write-Host '    No update blocking needed.' -ForegroundColor Gray
    } else {
        Write-Host "    Blocked $ok update mechanism(s)." -ForegroundColor Green
    }
}

function Restore-AutoUpdate {
    Write-Host '  Restoring Sogou auto-update...' -ForegroundColor Yellow
    Require-Administrator
    $ok = 0

    # 1. Remove registry keys (restore to default)
    foreach ($reg in $SogouUpdateRegKeys) {
        try {
            if (Test-Path $reg.Path) {
                Remove-ItemProperty -Path $reg.Path -Name $reg.Name -Force -ErrorAction SilentlyContinue
                Write-Host "    [OK] $($reg.Path)\$($reg.Name) removed" -ForegroundColor Green
                $ok++
            }
        } catch {
            Write-Host "    [FAIL] $($reg.Path)\$($reg.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 2. Remove hosts file entries
    $hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
    $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
    $newContent = @()
    $removedCount = 0

    foreach ($line in $hostsContent) {
        $shouldKeep = $true
        foreach ($domain in $SogouUpdateDomains) {
            if ($line -match "^\s*\d+\.\d+\.\d+\.\d+\s+$([regex]::Escape($domain))\s*$") {
                $shouldKeep = $false
                $removedCount++
                break
            }
        }
        if ($shouldKeep) { $newContent += $line }
    }

    if ($removedCount -gt 0) {
        try {
            Set-Content -Path $hostsPath -Value $newContent -Force -ErrorAction Stop
            Write-Host "    [OK] hosts: removed $removedCount entry(ies)" -ForegroundColor Green
            $ok += $removedCount
            & ipconfig /flushdns 2>&1 | Out-Null
        } catch {
            Write-Host "    [FAIL] hosts: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 3. Remove firewall rules
    $updateExes = @('PinyinUp.exe', 'SGDownload.exe', 'SogouToolkits.exe')
    foreach ($exe in $updateExes) {
        $ruleName = "SGLite Block $exe"
        try {
            $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            if ($existingRule) {
                Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
                Write-Host "    [OK] Firewall: $exe unblocked" -ForegroundColor Green
                $ok++
            }
        } catch {
            Write-Host "    [FAIL] Firewall: $exe - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($ok -eq 0) {
        Write-Host '    No update blocking to restore.' -ForegroundColor Gray
    } else {
        Write-Host "    Restored $ok mechanism(s)." -ForegroundColor Green
    }
}

# --- Full Cleanup ---

function Invoke-FullCleanup {
    param([hashtable]$Paths)

    Write-Host ''
    Write-Host '  +==============================================+' -ForegroundColor Cyan
    Write-Host '  |  Running FULL cleanup (all bloatware)...    |' -ForegroundColor Yellow
    Write-Host '  +==============================================+' -ForegroundColor Cyan
    Write-Host ''

    Stop-ExtraProcesses
    Start-Sleep -Milliseconds 500
    Write-Host ''

    Disable-ExeFiles -ExeDir $Paths.ExeDir
    Write-Host ''

    Disable-PluginDirs -PluginDir $Paths.PluginDir
    Write-Host ''

    Remove-BundledSoftware
    Write-Host ''

    Remove-ScheduledTasks
    Write-Host ''

    Remove-ShellExtensions
    Write-Host ''

    Remove-StartupEntries
    Write-Host ''

    Remove-SogouServices
    Write-Host ''

    Block-AutoUpdate
    Write-Host ''

    Write-Host ''
    Write-Host '  +==============================================+' -ForegroundColor Green
    Write-Host '  |  Cleanup complete! Reboot recommended.       |' -ForegroundColor Green
    Write-Host '  |  IME core preserved - input method works.    |' -ForegroundColor Green
    Write-Host '  +==============================================+' -ForegroundColor Green
}

# --- Disclaimer ---

function Show-Disclaimer {
    Clear-Host
    Write-Host ''
    Write-Host '  +==============================================+' -ForegroundColor Cyan
    Write-Host "  |         SGLite v$Version                     |" -ForegroundColor Yellow
    Write-Host '  +==============================================+' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  DISCLAIMER / 免责声明' -ForegroundColor Red
    Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  This software is provided "AS IS" without warranty' -ForegroundColor White
    Write-Host '  of any kind. The author is NOT responsible for:' -ForegroundColor White
    Write-Host ''
    Write-Host '    - Damage to your input method installation' -ForegroundColor Gray
    Write-Host '    - Loss of input method functionality' -ForegroundColor Gray
    Write-Host '    - Issues after input method software updates' -ForegroundColor Gray
    Write-Host '    - Any data loss or system instability' -ForegroundColor Gray
    Write-Host '    - Consequences of using this software' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  This tool modifies files in Program Files.' -ForegroundColor Yellow
    Write-Host '  A system restore point is recommended.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  All changes are reversible via the Restore options.' -ForegroundColor Green
    Write-Host ''
    Write-Host '  By continuing, you accept full responsibility.' -ForegroundColor White
    Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''

    $choice = Read-Host '  Accept and continue? (Y/N)'
    if ($choice -notin @('Y', 'y')) {
        Write-Host ''
        Write-Host '  Exiting...' -ForegroundColor Gray
        Start-Sleep -Seconds 1
        exit 0
    }
}

# --- Main ---

Show-Disclaimer

# Check installation
$Paths = Get-SGPaths
if (-not $Paths) {
    Write-Host ''
    Write-Host '  [ERROR] SG Pinyin not found.' -ForegroundColor Red
    Write-Host "  Expected location: $SGBase" -ForegroundColor Yellow
    Write-Host ''
    Read-Host '  Press Enter to exit'
    exit 1
}

while ($true) {
    Write-Banner
    Write-Host "  Detected: SG Pinyin $($Paths.Version)" -ForegroundColor Green
    Write-Host ''
    Show-Status -Paths $Paths

    Write-Host '  [Menu]' -ForegroundColor White
    Write-Host ''
    Write-Host '    1. ' -NoNewline
    Write-Host 'Full Cleanup' -ForegroundColor Yellow -NoNewline
    Write-Host ' (Recommended)'
    Write-Host '    2. Stop extra processes only'
    Write-Host '    3. Disable extra programs only'
    Write-Host '    4. Disable extra plugins only'
    Write-Host '    5. Clean bundled software only'
    Write-Host '    6. Remove Sogou scheduled tasks'
    Write-Host '    7. Remove Sogou right-click menu'
    Write-Host '    8. Remove Sogou startup entries'
    Write-Host '    9. Disable Sogou services'
    Write-Host '    10. Block Sogou auto-update'
    Write-Host '    ---'
    Write-Host '    R1. Restore all programs'
    Write-Host '    R2. Restore all plugins'
    Write-Host '    R3. Restore Sogou services'
    Write-Host '    R4. Restore Sogou auto-update'
    Write-Host '    0. Exit'
    Write-Host ''
    Write-Host '  [!] Changes require Administrator privileges.' -ForegroundColor DarkGray
    Write-Host ''

    $choice = Read-Host '  Select option'

    switch ($choice) {
        '1' { Invoke-FullCleanup -Paths $Paths; Read-Host '  Press Enter to continue' }
        '2' { Stop-ExtraProcesses; Read-Host '  Press Enter to continue' }
        '3' { Disable-ExeFiles -ExeDir $Paths.ExeDir; Read-Host '  Press Enter to continue' }
        '4' { Disable-PluginDirs -PluginDir $Paths.PluginDir; Read-Host '  Press Enter to continue' }
        '5' { Remove-BundledSoftware; Read-Host '  Press Enter to continue' }
        '6' { Remove-ScheduledTasks; Read-Host '  Press Enter to continue' }
        '7' { Remove-ShellExtensions; Read-Host '  Press Enter to continue' }
        '8' { Remove-StartupEntries; Read-Host '  Press Enter to continue' }
        '9' { Remove-SogouServices; Read-Host '  Press Enter to continue' }
        '10' { Block-AutoUpdate; Read-Host '  Press Enter to continue' }
        'R1' { Enable-ExeFiles -ExeDir $Paths.ExeDir; Read-Host '  Press Enter to continue' }
        'R2' { Enable-PluginDirs -PluginDir $Paths.PluginDir; Read-Host '  Press Enter to continue' }
        'R3' { Restore-SogouServices; Read-Host '  Press Enter to continue' }
        'R4' { Restore-AutoUpdate; Read-Host '  Press Enter to continue' }
        '0' {
            Write-Host ''
            Write-Host '  Goodbye!' -ForegroundColor Gray
            Start-Sleep -Seconds 1
            exit 0
        }
        default {
            Write-Host '  Invalid option.' -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
