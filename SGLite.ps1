# SGLite v1.0.0
# Lightweight SG Pinyin optimizer - removes bloatware, keeps IME core
# https://github.com/your-username/SGLite
# License: MIT

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'
$Version = '1.0.1'

# --- Configuration ---
# Note: 'SogouInput' is the actual installation directory name on disk
$SGBase = 'C:\Program Files (x86)\SogouInput'
$SGAppData = $env:LOCALAPPDATA
$ProgramData = $env:ProgramData

$ExtraExeNames = @(
    'SGTool.exe', 'SGDownload.exe', 'SGWangzai.exe', 'SGWebRender.exe',
    'SGWizard.exe', 'SGKaomoji.exe', 'SGIGuideHelper.exe', 'SogouCloud.exe',
    'SGSmartAssistant.exe', 'screencapture.exe', 'sgfeedbackhelper.exe',
    'userNetSchedule.exe', 'PinyinUp.exe', 'SGBizLauncher.exe',
    'SogouToolkits.exe', 'crashrpt.exe',
    'SGGameCenter.exe', 'SGBizCenter.exe', 'SGCleaner.exe'
)

$ExtraPluginDirs = @(
    'AppBox', 'IChat', 'PicFace', 'SGDeskControl', 'SkinBox',
    'SogouFlash', 'Theme', 'VoiceInput', 'WriteSpirit',
    'biz_center', 'biz_pdf', 'game_center', 'isgpet', 'systembeautify'
)

$BundledAppDataDirs = @(
    'fastpdf_sogou', 'kdiskmgr_sogou', 'kfastpic_sogou',
    'kzip_sogou', 'sogoupdf', 'sogousdk'
)

$BundledTempDirs = @(
    'kdiskmgr_sogou', 'kfastpic_sogou', 'kwallpaper_sogou', 'kzip_sogou'
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

    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '^Sogou' -or $_.Name -match '^SG[A-Z]'
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

function Stop-ExtraProcesses {
    Write-Host '  Stopping extra processes...' -ForegroundColor Yellow
    $count = 0
    $procNames = $ExtraExeNames | ForEach-Object { $_ -replace '\.exe$', '' }
    foreach ($name in $procNames) {
        try {
            $killed = Stop-Process -Name $name -Force -PassThru -ErrorAction Stop
            foreach ($k in $killed) {
                Write-Host "    [OK] $($k.Name).exe (PID: $($k.Id))" -ForegroundColor Green
                $count++
            }
        } catch {
            # Process not running, skip
        }
    }
    # Also stop SogouImeBroker and other Sogou processes that lock Components dir
    $sogouProcs = @('SogouImeBroker', 'SGWebRender', 'SogouCloud')
    foreach ($name in $sogouProcs) {
        try {
            $killed = Stop-Process -Name $name -Force -PassThru -ErrorAction Stop
            foreach ($k in $killed) {
                Write-Host "    [OK] $($k.Name).exe (PID: $($k.Id)) [lock-release]" -ForegroundColor Green
                $count++
            }
        } catch {
            # Not running
        }
    }
    if ($count -eq 0) {
        Write-Host '    No extra processes running.' -ForegroundColor Gray
    } else {
        Write-Host "    Stopped $count process(es)." -ForegroundColor Green
    }
    # Wait for file handles to release
    Start-Sleep -Milliseconds 2000
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
                # Take ownership (auto-confirm with /D Y)
                $null = & takeown /F "$path" /D Y 2>&1
                $null = & icacls "$path" /grant "*S-1-5-32-544:F" /Q 2>&1
                # Try PowerShell rename again
                try {
                    Rename-Item -Path $path -NewName "$exe.disabled" -Force -ErrorAction Stop
                } catch {
                    # Last resort: cmd rename
                    $null = & cmd /c ren "$path" "$exe.disabled" 2>&1
                    if (-not (Test-Path $disabledPath)) {
                        throw $_.Exception
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

        try {
            # Try rename first, escalate permissions only if needed
            try {
                Rename-Item -Path $path -NewName "$plugin.disabled" -Force -ErrorAction Stop
            } catch {
                # Stop any Sogou process that might lock files in this dir
                foreach ($lockProc in @('SogouImeBroker','SGWebRender','SogouCloud','SGTool')) {
                    Stop-Process -Name $lockProc -Force -ErrorAction SilentlyContinue
                }
                Start-Sleep -Milliseconds 500
                # Take ownership recursively (auto-confirm with /D Y)
                $null = & takeown /F "$path" /R /D Y 2>&1
                $null = & icacls "$path" /grant "*S-1-5-32-544:(OI)(CI)F" /T /C /Q 2>&1
                # Try PowerShell rename again
                try {
                    Rename-Item -Path $path -NewName "$plugin.disabled" -Force -ErrorAction Stop
                } catch {
                    # Last resort: cmd rename (handles some edge cases PowerShell can't)
                    $destPath = "$path.disabled"
                    $null = & cmd /c ren "$path" "$plugin.disabled" 2>&1
                    if (-not (Test-Path $destPath)) {
                        throw $_.Exception
                    }
                }
            }
            if (Test-Path $disabledPath) {
                Write-Host "    [OK] $plugin/" -ForegroundColor Green
                $ok++
            } else {
                Write-Host "    [FAIL] $plugin/" -ForegroundColor Red
                $fail++
            }
        } catch {
            Write-Host "    [FAIL] $plugin/ - $($_.Exception.Message)" -ForegroundColor Red
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
        $path = Join-Path $SGAppData $name
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                if (-not (Test-Path $path)) {
                    Write-Host "    [OK] $name" -ForegroundColor Green
                    $ok++
                } else {
                    Write-Host "    [FAIL] $name (still exists)" -ForegroundColor Red
                }
            } catch {
                Write-Host "    [FAIL] $name - $($_.Exception.Message)" -ForegroundColor Red
            }
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

# --- Full Cleanup ---

function Invoke-FullCleanup {
    param([hashtable]$Paths)

    Write-Host ''
    Write-Host '  +==========================================+' -ForegroundColor Cyan
    Write-Host '  |  Running full cleanup...                 |' -ForegroundColor Yellow
    Write-Host '  +==========================================+' -ForegroundColor Cyan
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
    Write-Host '  +==========================================+' -ForegroundColor Green
    Write-Host '  |  Cleanup complete! Reboot recommended.   |' -ForegroundColor Green
    Write-Host '  +==========================================+' -ForegroundColor Green
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
    Write-Host '    ---'
    Write-Host '    6. Restore all programs'
    Write-Host '    7. Restore all plugins'
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
        '6' { Enable-ExeFiles -ExeDir $Paths.ExeDir; Read-Host '  Press Enter to continue' }
        '7' { Enable-PluginDirs -PluginDir $Paths.PluginDir; Read-Host '  Press Enter to continue' }
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
