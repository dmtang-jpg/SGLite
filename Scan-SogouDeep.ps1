# Sogou Deep Scanner v2 - Comprehensive Sogou registry and system scan
# Run as Administrator
# Scans: ShellExt, Shell, CLSID, Approved, Tasks, Services, Startup, Hosts, Firewall, Deep Registry

# Create HKCR drive if needed
if (-not (Test-Path 'HKCR:')) {
    New-PSDrive -PSProvider Registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue | Out-Null
}

$ErrorActionPreference = 'SilentlyContinue'
$found = @()
$totalScanned = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sogou Deep Scanner v2" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# 1. Shell Extension Context Menu Handlers
# ========================================
Write-Host "[1/10] Shell Extension Context Menu Handlers..." -ForegroundColor Cyan
$shellexPaths = @(
    'HKCR:\*\shellex\ContextMenuHandlers',
    'HKCR:\Directory\shellex\ContextMenuHandlers',
    'HKCR:\Directory\Background\shellex\ContextMenuHandlers',
    'HKCR:\Folder\shellex\ContextMenuHandlers',
    'HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers',
    'HKCR:\Drive\shellex\ContextMenuHandlers',
    'HKCR:\LibraryFolder\shellex\ContextMenuHandlers',
    'HKCR:\LibraryLocation\shellex\ContextMenuHandlers'
)
foreach ($sp in $shellexPaths) {
    if (-not (Test-Path -LiteralPath $sp)) { continue }
    Get-ChildItem -LiteralPath $sp -ErrorAction SilentlyContinue | ForEach-Object {
        $totalScanned++
        $name = $_.PSChildName
        if ($name -match '(?i)sogou|kzip|kuaizip|sgsearch|sgzip|sgcompress|sgtranslate|sgkaomoji|sgdesk|sgbiz|sggame|sgwangzai|sgsmart|sgskin|sgwallpaper|sginstaller|sgweb|sgwizard|sgbrowser|sgclean|sgfeedback|sgdisk|sgfastpic|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite') {
            $found += [PSCustomObject]@{
                Category = "ShellExt"
                Path = "$sp\$name"
                Name = $name
            }
        }
    }
}

# ========================================
# 2. Shell Menu Handlers
# ========================================
Write-Host "[2/10] Shell Menu Handlers..." -ForegroundColor Cyan
$shellPaths = @(
    'HKCR:\*\shell',
    'HKCR:\Directory\shell',
    'HKCR:\Directory\Background\shell',
    'HKCR:\Folder\shell',
    'HKCR:\AllFilesystemObjects\shell',
    'HKCR:\Drive\shell'
)
foreach ($sp in $shellPaths) {
    if (-not (Test-Path -LiteralPath $sp)) { continue }
    Get-ChildItem -LiteralPath $sp -ErrorAction SilentlyContinue | ForEach-Object {
        $totalScanned++
        $name = $_.PSChildName
        if ($name -match '(?i)sogou|kzip|kuaizip|sgsearch|sgzip|sgcompress|sgtranslate|sgkaomoji|sgdesk|sgbiz|sggame|sgwangzai|sgsmart|sgskin|sgwallpaper|sginstaller|sgweb|sgwizard|sgbrowser|sgclean|sgfeedback|sgdisk|sgfastpic|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite') {
            $found += [PSCustomObject]@{
                Category = "Shell"
                Path = "$sp\$name"
                Name = $name
            }
        }
    }
}

# ========================================
# 3. CLSID Entries
# ========================================
Write-Host "[3/10] CLSID Entries..." -ForegroundColor Cyan
$clsidPath = 'HKCR:\CLSID'
if (Test-Path $clsidPath) {
    Get-ChildItem -LiteralPath $clsidPath -ErrorAction SilentlyContinue | ForEach-Object {
        $totalScanned++
        $clsid = $_.PSChildName
        $default = (Get-ItemProperty -Path "HKCR:\CLSID\$clsid" -Name '(default)' -ErrorAction SilentlyContinue).'(default)'
        if ($default -match '(?i)sogou|kzip|kuaizip') {
            $found += [PSCustomObject]@{
                Category = "CLSID"
                Path = "HKCR:\CLSID\$clsid"
                Name = "$clsid ($default)"
            }
        }
    }
}

# ========================================
# 4. Approved Shell Extensions
# ========================================
Write-Host "[4/10] Approved Shell Extensions..." -ForegroundColor Cyan
$approvedPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved'
if (Test-Path $approvedPath) {
    Get-ChildItem -Path $approvedPath -ErrorAction SilentlyContinue | ForEach-Object {
        $totalScanned++
        $name = $_.PSChildName
        $val = Get-ItemProperty -Path $approvedPath -Name $name -ErrorAction SilentlyContinue
        if ($val -and ($val.$name -match '(?i)sogou|kzip|kuaizip')) {
            $found += [PSCustomObject]@{
                Category = "Approved"
                Path = "$approvedPath\$name"
                Name = "$name ($($val.$name))"
            }
        }
    }
}

# ========================================
# 5. Scheduled Tasks
# ========================================
Write-Host "[5/10] Scheduled Tasks..." -ForegroundColor Cyan
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -match '(?i)sogou|sgsmart|sggame|sgbiz|sgflash|sgskin|sgguard|sgwallpaper|sginstaller|sgupdate|sgcloud|sgdesk|sgwangzai|sgtranslate|sgkaomoji|sgfeedback|sgclean|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite'
}
foreach ($task in $tasks) {
    $totalScanned++
    $found += [PSCustomObject]@{
        Category = "Task"
        Path = "ScheduledTask"
        Name = $task.TaskName
    }
}

# ========================================
# 6. Windows Services
# ========================================
Write-Host "[6/10] Windows Services..." -ForegroundColor Cyan
$services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '(?i)sogou|sgsmart|sggame|sgbiz|sgflash|sgskin|sgguard|sgwallpaper|sginstaller|sgupdate|sgcloud|sgdesk|sgwangzai|sgtranslate|sgkaomoji|sgfeedback|sgclean|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite'
}
foreach ($svc in $services) {
    $totalScanned++
    $found += [PSCustomObject]@{
        Category = "Service"
        Path = "Service"
        Name = "$($svc.Name) ($($svc.Status))"
    }
}

# ========================================
# 7. Startup Entries
# ========================================
Write-Host "[7/10] Startup Entries..." -ForegroundColor Cyan
$startupPaths = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)
foreach ($sp in $startupPaths) {
    if (-not (Test-Path $sp)) { continue }
    $props = Get-ItemProperty -Path $sp -ErrorAction SilentlyContinue
    if ($props) {
        $props.PSObject.Properties | ForEach-Object {
            $totalScanned++
            $name = $_.Name
            $val = $_.Value
            if ($name -match '(?i)sogou|sgsmart|sgdesk|sggame|sgbiz|sgbrowser|sgwallpaper|sginstaller|sgskin|sgupdate|sgcloud|sgwangzai|sgtranslate|sgkaomoji|sgfeedback|sgclean|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite') {
                $found += [PSCustomObject]@{
                    Category = "Startup"
                    Path = $sp
                    Name = "$name = $val"
                }
            }
        }
    }
}

# ========================================
# 8. Hosts File
# ========================================
Write-Host "[8/10] Hosts File..." -ForegroundColor Cyan
$hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
if (Test-Path $hostsPath) {
    $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
    foreach ($line in $hostsContent) {
        $totalScanned++
        if ($line -match '(?i)sogou|pinyin\.sogou|update\.sogou|down\.sogou|cdn\.pinyin') {
            $found += [PSCustomObject]@{
                Category = "Hosts"
                Path = $hostsPath
                Name = $line.Trim()
            }
        }
    }
}

# ========================================
# 9. Firewall Rules
# ========================================
Write-Host "[9/10] Firewall Rules..." -ForegroundColor Cyan
$fwRules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match '(?i)sogou|sglite|sgsearch|sgzip|sgcompress|sgtranslate|sgkaomoji|sgdesk|sgbiz|sggame|sgwangzai|sgsmart|sgskin|sgwallpaper|sginstaller|sgweb|sgwizard|sgbrowser|sgclean|sgfeedback|sgdisk|sgfastpic|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite'
}
foreach ($rule in $fwRules) {
    $totalScanned++
    $found += [PSCustomObject]@{
        Category = "Firewall"
        Path = "FirewallRule"
        Name = "$($rule.DisplayName) (Enabled: $($rule.Enabled))"
    }
}

# ========================================
# 10. Deep Registry Scan
# ========================================
Write-Host "[10/10] Deep Registry Scan..." -ForegroundColor Cyan
$deepRegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths',
    'HKCU:\SOFTWARE\Microsoft\Internet Explorer\SearchScopes',
    'HKLM:\SOFTWARE\Microsoft\Internet Explorer\SearchScopes',
    'HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main',
    'HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjects',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\ShellServiceObjects',
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellExecuteHooks',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellExecuteHooks',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SharedTaskScheduler',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\SharedTaskScheduler',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellExecuteHooks',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellExecuteHooks',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SharedTaskScheduler',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SharedTaskScheduler'
)
foreach ($sp in $deepRegPaths) {
    if (-not (Test-Path $sp)) { continue }
    Get-ChildItem -Path $sp -ErrorAction SilentlyContinue | ForEach-Object {
        $totalScanned++
        $name = $_.PSChildName
        if ($name -match '(?i)sogou|kzip|kuaizip|sgsearch|sgzip|sgcompress|sgtranslate|sgkaomoji|sgdesk|sgbiz|sggame|sgwangzai|sgsmart|sgskin|sgwallpaper|sginstaller|sgweb|sgwizard|sgbrowser|sgclean|sgfeedback|sgdisk|sgfastpic|sgpdf|sgscreenshot|sgemoji|sgtheme|sgvoice|sgwrite') {
            $found += [PSCustomObject]@{
                Category = "DeepRegistry"
                Path = $sp
                Name = $name
            }
        }
    }
}

# ========================================
# Results Summary
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SCAN RESULTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total items scanned: $totalScanned" -ForegroundColor White
Write-Host "Sogou entries found: $($found.Count)" -ForegroundColor $(if ($found.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

if ($found.Count -gt 0) {
    Write-Host "[FOUND] Entries:" -ForegroundColor Red
    Write-Host ""
    
    # Group by category
    $grouped = $found | Group-Object Category
    foreach ($group in $grouped) {
        Write-Host "--- $($group.Name) ($($group.Count) entries) ---" -ForegroundColor Yellow
        foreach ($item in $group.Group) {
            Write-Host "  [FOUND] $($item.Path)" -ForegroundColor Red
            if ($item.Name -ne $item.Path) {
                Write-Host "          $($item.Name)" -ForegroundColor DarkRed
            }
        }
        Write-Host ""
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Send these [FOUND] entries to me." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Host "  CLEAN! No Sogou entries found." -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
