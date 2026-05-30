# SGLite v2.0.0
# Lightweight SG Pinyin optimizer - removes bloatware, keeps IME core
# https://github.com/dmtang-jpg/SGLite
# License: MIT

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Version = '2.0.0'

# --- Configuration ---
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

# --- Logging ---

$LogFile = Join-Path $env:TEMP "SGLite_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format 'HH:mm:ss'
    $line = "[$ts] $Message"
    try { Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue } catch {}
}

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

function Invoke-WithTimeout {
    param(
        [string]$Description,
        [scriptblock]$ScriptBlock,
        [int]$TimeoutSec = 5
    )
    $job = Start-Job -ScriptBlock $ScriptBlock
    $finished = Wait-Job $job -Timeout $TimeoutSec
    if ($finished) {
        $output = Receive-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        return $output
    } else {
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Log "[WARN] $Description timed out after ${TimeoutSec}s"
        return $null
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

    if ($runningNames -contains 'SogouImeBroker') {
        Write-Host '    IME Core:          ' -NoNewline
        Write-Host 'Running' -ForegroundColor Green
    } else {
        Write-Host '    IME Core:          ' -NoNewline
        Write-Host 'Not Running' -ForegroundColor Red
    }

    Write-Host "    Version:           $($Paths.Version)"

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
    Write-Host "    Log File:          $LogFile"
    Write-Host ''
}

# --- Core Operations ---

function Stop-ExtraProcesses {
    Write-Host '  Stopping extra processes...' -ForegroundColor Yellow
    Write-Log 'Stop-ExtraProcesses: starting'
    $count = 0
    $procNames = $ExtraExeNames | ForEach-Object { $_ -replace '\.exe$', '' }

    # Round 1: PowerShell Stop-Process
    foreach ($name in $procNames) {
        try {
            $killed = Stop-Process -Name $name -Force -PassThru -ErrorAction Stop
            foreach ($k in $killed) {
                Write-Host "    [OK] $($k.Name).exe (PID: $($k.Id))" -ForegroundColor Green
                Write-Log "  Killed: $($k.Name).exe PID=$($k.Id)"
                $count++
            }
        } catch {}
    }

    # Round 2: Also stop Sogou processes that lock Components dir
    $sogouProcs = @('SogouImeBroker', 'SGWebRender', 'SogouCloud')
    foreach ($name in $sogouProcs) {
        try {
            $killed = Stop-Process -Name $name -Force -PassThru -ErrorAction Stop
            foreach ($k in $killed) {
                Write-Host "    [OK] $($k.Name).exe (PID: $($k.Id)) [lock-release]" -ForegroundColor Green
                Write-Log "  Killed lock-holder: $($k.Name).exe PID=$($k.Id)"
                $count++
            }
        } catch {}
    }

    # Round 3: taskkill with timeout
    foreach ($name in ($procNames + $sogouProcs)) {
        Invoke-WithTimeout -Description "taskkill $name" -TimeoutSec 3 -ScriptBlock {
            & taskkill /F /IM "$($using:name).exe" 2>&1
        }
    }

    if ($count -eq 0) {
        Write-Host '    No extra processes running.' -ForegroundColor Gray
    } else {
        Write-Host "    Stopped $count process(es)." -ForegroundColor Green
    }
    Start-Sleep -Milliseconds 2000
}

function Disable-ExeFiles {
    param([string]$ExeDir)
    Require-Administrator

    Write-Host '  Disabling extra programs...' -ForegroundColor Yellow
    Write-Log "Disable-ExeFiles: ExeDir=$ExeDir"
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
                # Take ownership with timeout
                Invoke-WithTimeout -Description "takeown $exe" -TimeoutSec 5 -ScriptBlock {
                    & takeown /F "$($using:path)" /D Y 2>&1
                }
                Invoke-WithTimeout -Description "icacls $exe" -TimeoutSec 5 -ScriptBlock {
                    & icacls "$($using:path)" /grant "*S-1-5-32-544:F" /Q 2>&1
                }
                # Try PowerShell rename again
                try {
                    Rename-Item -Path $path -NewName "$exe.disabled" -Force -ErrorAction Stop
                } catch {
                    # Last resort: cmd rename
                    $null = Invoke-WithTimeout -Description "cmd ren $exe" -TimeoutSec 3 -ScriptBlock {
                        & cmd /c ren "$($using:path)" "$($exe).disabled" 2>&1
                    }
                    if (-not (Test-Path $disabledPath)) {
                        throw $_.Exception
                    }
                }
            }
            if (Test-Path $disabledPath) {
                Write-Host "    [OK] $exe" -ForegroundColor Green
                Write-Log "  Disabled: $exe"
                $ok++
            } else {
                Write-Host "    [FAIL] $exe" -ForegroundColor Red
                Write-Log "  FAIL: $exe"
                $fail++
            }
        } catch {
            Write-Host "    [FAIL] $exe - $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "  FAIL: $exe - $($_.Exception.Message)"
            $fail++
        }
    }

    $color = if ($fail -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host "    Done: $ok disabled, $skip skipped, $fail failed" -ForegroundColor $color
    Write-Log "Disable-ExeFiles: ok=$ok skip=$skip fail=$fail"
}

function Enable-ExeFiles {
    param([string]$ExeDir)
    Require-Administrator

    Write-Host '  Restoring extra programs...' -ForegroundColor Yellow
    Write-Log "Enable-ExeFiles: ExeDir=$ExeDir"
    $ok = 0

    foreach ($exe in $ExtraExeNames) {
        $disabledPath = Join-Path $ExeDir "$exe.disabled"
        $bakPath = Join-Path $ExeDir "$exe.disabled.bak"

        $restoreFrom = $null
        if (Test-Path $disabledPath) {
            $restoreFrom = $disabledPath
        } elseif (Test-Path $bakPath) {
            $restoreFrom = $bakPath
        }
        if (-not $restoreFrom) { continue }

        try {
            $originalPath = Join-Path $ExeDir $exe
            if (Test-Path $originalPath) {
                Remove-Item $originalPath -Force -ErrorAction SilentlyContinue
            }
            Rename-Item -Path $restoreFrom -NewName $exe -Force -ErrorAction Stop
            if (Test-Path $originalPath) {
                $suffix = if ($restoreFrom -eq $bakPath) { " (from backup)" } else { "" }
                Write-Host "    [OK] $exe$suffix" -ForegroundColor Green
                Write-Log "  Restored: $exe$suffix"
                $ok++
            }
        } catch {
            Write-Host "    [FAIL] $exe - $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "  FAIL restore: $exe - $($_.Exception.Message)"
        }
    }

    Write-Host "    Restored $ok program(s)." -ForegroundColor Green
}

function Disable-PluginDirs {
    param([string]$PluginDir)
    Require-Administrator

    Write-Host '  Disabling extra plugins...' -ForegroundColor Yellow
    Write-Log "Disable-PluginDirs: PluginDir=$PluginDir"
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

        $renamed = $false

        # Multi-round strategy: kill processes → wait → try rename (repeat 3 times)
        for ($round = 1; $round -le 3; $round++) {
            try {
                Rename-Item -Path $path -NewName "$plugin.disabled" -Force -ErrorAction Stop
                $renamed = $true
                break
            } catch {
                Write-Log "  Round $round rename failed for $plugin: $($_.Exception.Message)"

                # Kill locking processes
                foreach ($lockProc in @('SogouImeBroker', 'SGWebRender', 'SogouCloud', 'SGTool')) {
                    Stop-Process -Name $lockProc -Force -ErrorAction SilentlyContinue
                }
                # Also taskkill with timeout
                Invoke-WithTimeout -Description "taskkill for $plugin r$round" -TimeoutSec 3 -ScriptBlock {
                    foreach ($lp in @('SogouImeBroker', 'SGWebRender', 'SogouCloud', 'SGTool')) {
                        & taskkill /F /IM "$lp.exe" 2>&1
                    }
                }
                Start-Sleep -Milliseconds 1000

                # Take ownership (only on first round to avoid repeated slow calls)
                if ($round -eq 1) {
                    Invoke-WithTimeout -Description "takeown $plugin" -TimeoutSec 5 -ScriptBlock {
                        & takeown /F "$($using:path)" /R /D Y 2>&1
                    }
                    Invoke-WithTimeout -Description "icacls $plugin" -TimeoutSec 10 -ScriptBlock {
                        & icacls "$($using:path)" /grant "*S-1-5-32-544:(OI)(CI)F" /T /C /Q 2>&1
                    }
                }
            }
        }

        # If PowerShell rename still failed, try cmd rename as last resort
        if (-not $renamed) {
            $null = Invoke-WithTimeout -Description "cmd ren $plugin" -TimeoutSec 3 -ScriptBlock {
                & cmd /c ren "$($using:path)" "$($plugin).disabled" 2>&1
            }
            if (Test-Path $disabledPath) {
                $renamed = $true
            }
        }

        if ($renamed -and (Test-Path $disabledPath)) {
            Write-Host "    [OK] $plugin/" -ForegroundColor Green
            Write-Log "  Disabled plugin: $plugin"
            $ok++
        } else {
            Write-Host "    [FAIL] $plugin/" -ForegroundColor Red
            Write-Log "  FAIL plugin: $plugin"
            $fail++
        }
    }

    $color = if ($fail -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host "    Done: $ok disabled, $skip skipped, $fail failed" -ForegroundColor $color
    Write-Log "Disable-PluginDirs: ok=$ok skip=$skip fail=$fail"
}

function Enable-PluginDirs {
    param([string]$PluginDir)
    Require-Administrator

    Write-Host '  Restoring extra plugins...' -ForegroundColor Yellow
    Write-Log "Enable-PluginDirs: PluginDir=$PluginDir"
    $ok = 0

    foreach ($plugin in $ExtraPluginDirs) {
        $disabledPath = Join-Path $PluginDir "$plugin.disabled"
        $bakPath = Join-Path $PluginDir "$plugin.disabled.bak"

        $restoreFrom = $null
        if (Test-Path $disabledPath) {
            $restoreFrom = $disabledPath
        } elseif (Test-Path $bakPath) {
            $restoreFrom = $bakPath
        }
        if (-not $restoreFrom) { continue }

        try {
            $originalPath = Join-Path $PluginDir $plugin
            if (Test-Path $originalPath) {
                Remove-Item $originalPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            Rename-Item -Path $restoreFrom -NewName $plugin -Force -ErrorAction Stop
            if (Test-Path $originalPath) {
                $suffix = if ($restoreFrom -eq $bakPath) { " (from backup)" } else { "" }
                Write-Host "    [OK] $plugin/$suffix" -ForegroundColor Green
                Write-Log "  Restored plugin: $plugin$suffix"
                $ok++
            }
        } catch {
            Write-Host "    [FAIL] $plugin/ - $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "  FAIL restore plugin: $plugin - $($_.Exception.Message)"
        }
    }

    Write-Host "    Restored $ok plugin(s)." -ForegroundColor Green
}

function Remove-BundledSoftware {
    Write-Host '  Cleaning bundled software...' -ForegroundColor Yellow
    Write-Log 'Remove-BundledSoftware: starting'
    $ok = 0

    foreach ($name in $BundledAppDataDirs) {
        $path = Join-Path $SGAppData $name
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                if (-not (Test-Path $path)) {
                    Write-Host "    [OK] $name" -ForegroundColor Green
                    Write-Log "  Cleaned: $name"
                    $ok++
                } else {
                    Write-Host "    [FAIL] $name (still exists)" -ForegroundColor Red
                    Write-Log "  FAIL: $name (still exists)"
                }
            } catch {
                Write-Host "    [FAIL] $name - $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "  FAIL: $name - $($_.Exception.Message)"
            }
        }
    }

    foreach ($name in $BundledTempDirs) {
        $path = Join-Path $SGAppData "Temp\$name"
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                Write-Host "    [OK] Temp/$name" -ForegroundColor Green
                Write-Log "  Cleaned: Temp/$name"
                $ok++
            } catch {
                Write-Host "    [SKIP] Temp/$name (locked)" -ForegroundColor DarkGray
                Write-Log "  SKIP: Temp/$name (locked)"
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
                    Write-Log "  Cleaned: ProgramData/$d"
                    $ok++
                } catch {
                    Write-Host "    [SKIP] ProgramData/$d (locked)" -ForegroundColor DarkGray
                    Write-Log "  SKIP: ProgramData/$d (locked)"
                }
            }
        }
    }

    Write-Host "    Cleaned $ok item(s)." -ForegroundColor Green
    Write-Log "Remove-BundledSoftware: cleaned=$ok"
}

# --- Full Cleanup ---

function Invoke-FullCleanup {
    param([hashtable]$Paths)

    Write-Host ''
    Write-Host '  +==========================================+' -ForegroundColor Cyan
    Write-Host '  |  Running full cleanup...                 |' -ForegroundColor Yellow
    Write-Host '  +==========================================+' -ForegroundColor Cyan
    Write-Host ''
    Write-Log '=== Full Cleanup Started ==='

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
    Write-Log '=== Full Cleanup Finished ==='
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

Write-Log "SGLite v$Version started. SG Version: $($Paths.Version)"
Write-Log "ExeDir: $($Paths.ExeDir)"
Write-Log "PluginDir: $($Paths.PluginDir)"

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
            Write-Log 'SGLite exited'
            Start-Sleep -Seconds 1
            exit 0
        }
        default {
            Write-Host '  Invalid option.' -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
