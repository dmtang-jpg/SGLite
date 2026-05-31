@echo off
:: Sogou Context Menu Scanner - Auto-elevate to Administrator

:: Self-elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WorkingDirectory '%~dp0'"
    exit /b
)

echo.
echo ========================================
echo   Sogou Context Menu Scanner v1.0
echo ========================================
echo.
echo Scanning for Sogou registry entries...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "if(-not(Test-Path HKCR:)){New-PSDrive -PSProvider Registry -Root HKEY_CLASSES_ROOT -Name HKCR -EA 0|Out-Null};" ^
    "$f=@();" ^
    "$sp=@('HKCR:\*\shellex\ContextMenuHandlers','HKCR:\Directory\shellex\ContextMenuHandlers','HKCR:\Directory\Background\shellex\ContextMenuHandlers','HKCR:\Folder\shellex\ContextMenuHandlers','HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers','HKCR:\*\shell','HKCR:\Directory\shell','HKCR:\Directory\Background\shell','HKCR:\Folder\shell');" ^
    "foreach($s in $sp){if(Test-Path -LiteralPath $s){Get-ChildItem -LiteralPath $s -EA 0|%%{$n=$_.PSChildName;if($n-match'(?i)sogou|kzip|kuaizip|sgsearch|sgzip|sgcompress|sgtranslate'){$f+=$s+'\'+$n}}}};" ^
    "Write-Host '--- Context Menu Handlers ---' -Fore Cyan;" ^
    "if($f){$f|%%{Write-Host '[FOUND]'$_ -Fore Red}}else{Write-Host '  Clean!' -Fore Green};" ^
    "Write-Host '';" ^
    "Write-Host '--- CLSID ---' -Fore Cyan;" ^
    "$found=$false;" ^
    "Get-ChildItem HKCR:\CLSID -EA 0|%%{$c=$_.PSChildName;$d=(Get-ItemProperty ('HKCR:\CLSID\'+$c) -Name '(default)' -EA 0).'(default)';if($d-match'(?i)sogou|kzip'){$found=$true;Write-Host '[FOUND] CLSID:'$c '('+$d+')' -Fore Red}};" ^
    "if(-not $found){Write-Host '  Clean!' -Fore Green};" ^
    "Write-Host '';" ^
    "Write-Host '--- Scheduled Tasks ---' -Fore Cyan;" ^
    "$found=$false;" ^
    "Get-ScheduledTask -EA 0|?{$_.TaskName-match'(?i)sogou|sgsmart|sggame|sgbiz|sgflash|sgskin|sgguard|sgwallpaper|sginstaller'}|%%{$found=$true;Write-Host '[FOUND] Task:'$_.TaskName -Fore Red};" ^
    "if(-not $found){Write-Host '  Clean!' -Fore Green};" ^
    "Write-Host '';" ^
    "Write-Host '--- Services ---' -Fore Cyan;" ^
    "$found=$false;" ^
    "Get-Service -EA 0|?{$_.Name-match'(?i)sogou'}|%%{$found=$true;Write-Host '[FOUND] Service:'$_.Name '('+$_.Status+')' -Fore Red};" ^
    "if(-not $found){Write-Host '  Clean!' -Fore Green};" ^
    "Write-Host '';" ^
    "Write-Host '--- Startup Entries ---' -Fore Cyan;" ^
    "$found=$false;" ^
    "$rk=@('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce');" ^
    "foreach($r in $rk){if(Test-Path $r){Get-ItemProperty -Path $r -EA 0|Get-Member -MemberType NoteProperty|%%{$n=$.Name;if($n-match'(?i)sogou|sgsmart|sgdesk|sggame|sgbiz|sgbrowser|sgwallpaper|sginstaller|sgskin|sgupdate'){$v=(Get-ItemProperty -Path $r -Name $n -EA 0).$n;if($v){$found=$true;Write-Host '[FOUND] '$r'\'$n '=' $v -Fore Red}}}}};" ^
    "if(-not $found){Write-Host '  Clean!' -Fore Green};" ^
    "Write-Host '';" ^
    "Write-Host '--- Firewall Rules ---' -Fore Cyan;" ^
    "$found=$false;" ^
    "Get-NetFirewallRule -EA 0|?{$_.DisplayName-match'(?i)sogou|sglite'}|%%{$found=$true;Write-Host '[FOUND] Rule:'$_.DisplayName '('+$_.Enabled+')' -Fore Red};" ^
    "if(-not $found){Write-Host '  Clean!' -Fore Green};" ^
    "Write-Host '';" ^
    "Write-Host '========================================' -Fore Cyan;" ^
    "Write-Host 'Scan complete!' -Fore Green;" ^
    "Write-Host 'Send the [FOUND] entries to me.' -Fore Yellow;" ^
    "Write-Host '========================================' -Fore Cyan"

echo.
echo Press any key to exit...
pause >nul
