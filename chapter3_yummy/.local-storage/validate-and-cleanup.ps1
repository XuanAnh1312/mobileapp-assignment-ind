param([Parameter(Mandatory=$true)][string]$ReportRoot, [switch]$CleanupOnly)
$ErrorActionPreference = 'Stop'
$cacheRoot = 'D:\DevCache'
$mappingsPath = Join-Path $ReportRoot 'mappings.json'
$mappings = Get-Content -LiteralPath $mappingsPath -Raw | ConvertFrom-Json
foreach ($mapping in $mappings) {
    $link = Get-Item -LiteralPath $mapping.Source -Force
    if (!($link.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Missing compatibility link: $($mapping.Source)" }
    if (@($link.Target)[0].TrimEnd('\') -ine $mapping.Destination.TrimEnd('\')) { throw 'Unexpected junction target' }
    if ([Environment]::GetEnvironmentVariable($mapping.Variable, 'User') -ne $mapping.Destination) { throw 'User environment was not updated' }
}
$env:GRADLE_USER_HOME = "$cacheRoot\Gradle"
$env:PUB_CACHE = "$cacheRoot\Pub"
$env:ANDROID_AVD_HOME = "$cacheRoot\avd"
$env:TEMP = "$cacheRoot\Temp"
$env:TMP = "$cacheRoot\Temp"
$env:JAVA_HOME = 'D:\AVD\jbr'
if (!$CleanupOnly) {
Write-Output 'Checking Gradle distribution on D'
& .\android\gradlew.bat --version
if ($LASTEXITCODE -ne 0) { throw 'Gradle distribution validation failed' }
Write-Output 'Checking Dart packages on D'
& D:\flutter\bin\flutter.bat pub get
if ($LASTEXITCODE -ne 0) { throw 'Flutter package validation failed' }
Write-Output 'Checking emulator definitions on D'
$avds = @(& 'D:\avd-androi\emulator\emulator.exe' -list-avds)
if ($LASTEXITCODE -ne 0 -or $avds -notcontains 'Pixel_4') { throw 'Pixel_4 emulator definition is unavailable' }
$avds | Write-Output
$avdIni = Get-Content -LiteralPath "$cacheRoot\avd\Pixel_4.ini"
$avdPathLine = $avdIni | Where-Object { $_ -like 'path=*' } | Select-Object -First 1
$avdPath = $avdPathLine.Substring(5)
if (!$avdPath.StartsWith('D:\DevCache\avd\') -or !(Test-Path -LiteralPath (Join-Path $avdPath 'config.ini'))) { throw 'AVD data path is invalid' }
Write-Output 'Cold-booting relocated emulator for validation'
& 'D:\avd-androi\platform-tools\adb.exe' start-server
Start-Process -FilePath 'D:\avd-androi\emulator\emulator.exe' -ArgumentList '-avd','Pixel_4','-no-snapshot-load','-no-snapshot-save' -WindowStyle Hidden -RedirectStandardOutput (Join-Path $ReportRoot 'emulator.stdout.log') -RedirectStandardError (Join-Path $ReportRoot 'emulator.stderr.log') | Out-Null
$emulatorBooted = $false
for ($attempt = 1; $attempt -le 24; $attempt++) {
    Start-Sleep -Seconds 5
    $bootState = @()
    try { $bootState = & 'D:\avd-androi\platform-tools\adb.exe' -s emulator-5554 shell getprop sys.boot_completed 2>$null } catch { $bootState = @() }
    if ($LASTEXITCODE -eq 0 -and ($bootState -join '').Trim() -eq '1') { $emulatorBooted = $true; break }
    if ($attempt % 4 -eq 0) { Write-Output "Waiting for emulator boot: $($attempt * 5)s" }
}
if (!$emulatorBooted) { throw 'Relocated emulator did not boot in time; backups retained' }
Write-Output 'RELOCATED_EMULATOR_BOOTED'
'Gradle distribution, Dart packages, emulator cold boot and junctions verified.' | Set-Content -LiteralPath (Join-Path $ReportRoot 'validation.txt')
} elseif (!(Test-Path -LiteralPath (Join-Path $ReportRoot 'validation.txt'))) {
    throw 'Previous tool validation report is required before cleanup'
}

# Delete only verified migration backups at exact known source locations.
$allowedSources = @("$env:USERPROFILE\.gradle", "$env:LOCALAPPDATA\Pub\Cache", "$env:USERPROFILE\.android\avd")
foreach ($mapping in $mappings) {
    $source = [IO.Path]::GetFullPath($mapping.Source)
    $backup = [IO.Path]::GetFullPath($mapping.Backup)
    if ($source -notin $allowedSources -or $backup -ne ($source + '.before-drive-d-migration')) { throw "Refusing unexpected backup path: $backup" }
    $backupItem = Get-Item -LiteralPath $backup -Force
    if ($backupItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Backup is unexpectedly a link' }
    $extendedBackup = '\\?\' + $backup
    $nestedLinks = @(Get-ChildItem -LiteralPath $extendedBackup -Recurse -Force -Attributes ReparsePoint -ErrorAction Stop)
    if ($nestedLinks.Count -gt 0) { throw "Backup contains nested links; retain for inspection: $backup" }
    Write-Output "Removing verified backup: $backup"
    Remove-Item -LiteralPath $extendedBackup -Recurse -Force
    Write-Output "SOURCE_SPACE_RECLAIMED $source"
}

# Notify Explorer of persistent user environment changes without restarting apps.
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CacheMigrationEnvironment {
    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
}
'@
$broadcastResult = [UIntPtr]::Zero
[CacheMigrationEnvironment]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment', 2, 3000, [ref]$broadcastResult) | Out-Null
Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:' OR DeviceID='D:'" | Select-Object DeviceID,@{Name='FreeGB';Expression={[math]::Round($_.FreeSpace/1GB,2)}} | Format-Table -AutoSize
Write-Output 'MIGRATION_VALIDATED_AND_CLEANED'
