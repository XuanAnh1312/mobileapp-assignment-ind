param([switch]$ResumeGradleCopy)
$ErrorActionPreference = 'Stop'
$cacheRoot = 'D:\DevCache'
New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null
$reportRoot = Join-Path $cacheRoot ('migration-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $reportRoot | Out-Null
$envNames = @('GRADLE_USER_HOME', 'PUB_CACHE', 'ANDROID_AVD_HOME', 'TEMP', 'TMP', 'Path')
$envBackup = foreach ($name in $envNames) {
    [pscustomobject]@{ Name = $name; Value = [Environment]::GetEnvironmentVariable($name, 'User') }
}
$envBackup | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $reportRoot 'environment-before.json')

# Stop only processes using the caches being migrated, never unrelated Java apps.
$cacheProcesses = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq 'java.exe' -and $_.CommandLine -like "*$env:USERPROFILE\.gradle\*" -and
    ($_.CommandLine -match 'GradleDaemon|KotlinCompileDaemon')
}
foreach ($cacheProcess in $cacheProcesses) {
    Write-Output "Stopping cache process $($cacheProcess.ProcessId)"
    Stop-Process -Id $cacheProcess.ProcessId -Force -ErrorAction SilentlyContinue
}
$emulators = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -in @('emulator.exe', 'qemu-system-x86_64.exe', 'qemu-system-aarch64.exe')
}
if ($emulators) {
    & 'D:\avd-androi\platform-tools\adb.exe' emu kill
    Start-Sleep -Seconds 4
    $remainingEmulators = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -in @('qemu-system-x86_64.exe', 'qemu-system-aarch64.exe')
    }
    if ($remainingEmulators) { throw 'Emulator did not shut down. Migration stopped before copying.' }
}

$mappings = @(
    @{ Source = "$env:USERPROFILE\.gradle"; Destination = "$cacheRoot\Gradle"; Variable = 'GRADLE_USER_HOME' },
    @{ Source = "$env:LOCALAPPDATA\Pub\Cache"; Destination = "$cacheRoot\Pub"; Variable = 'PUB_CACHE' },
    @{ Source = "$env:USERPROFILE\.android\avd"; Destination = "$cacheRoot\avd"; Variable = 'ANDROID_AVD_HOME' }
)
$completed = @()
foreach ($mapping in $mappings) {
    $source = [IO.Path]::GetFullPath($mapping.Source)
    $destination = [IO.Path]::GetFullPath($mapping.Destination)
    if (!$destination.StartsWith('D:\DevCache\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected destination' }
    if (!(Test-Path -LiteralPath $source)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        [Environment]::SetEnvironmentVariable($mapping.Variable, $destination, 'User')
        continue
    }
    $sourceItem = Get-Item -LiteralPath $source -Force
    if ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Source already has a link: $source" }
    $resumeThisCopy = $ResumeGradleCopy -and $mapping.Variable -eq 'GRADLE_USER_HOME' -and (Test-Path -LiteralPath $destination)
    if ((Test-Path -LiteralPath $destination) -and !$resumeThisCopy) { throw "Destination already exists; inspect before merging: $destination" }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $logPath = Join-Path $reportRoot ($mapping.Variable + '-copy.log')
    Write-Output "COPY $source -> $destination"
    if (!$resumeThisCopy) {
        & robocopy.exe $source $destination /E /COPY:DAT /DCOPY:DAT /XJ /R:1 /W:1 /MT:8 /NP /NFL /NDL "/LOG:$logPath"
        if ($LASTEXITCODE -ge 8) { throw "Copy failed; source retained. See $logPath" }
    }
    $verifyLog = Join-Path $reportRoot ($mapping.Variable + '-verify.log')
    & robocopy.exe $source $destination /E /L /COPY:DAT /DCOPY:DAT /XJ /R:0 /W:0 /NP /NDL "/LOG:$verifyLog"
    $verifyExit = $LASTEXITCODE
    if ($verifyExit -eq 1) {
        # Timestamp-only differences are accepted only after SHA256 verification.
        $verificationText = Get-Content -LiteralPath $verifyLog -Raw
        $fileSummary = [regex]::Match($verificationText, '(?m)^\s*Files\s*:\s*\d+\s+(\d+)\s+')
        $differentFiles = [regex]::Matches($verificationText, '(?m)^\s*(?:Newer|Older|Changed|New File|Tweaked)\s+\S+\s+([A-Za-z]:\\[^\r\n]+)')
        if (!$fileSummary.Success -or $differentFiles.Count -ne [int]$fileSummary.Groups[1].Value -or $differentFiles.Count -eq 0) { throw 'Cannot account for every comparison difference; source retained' }
        foreach ($difference in $differentFiles) {
            $sourceFile = $difference.Groups[1].Value.Trim()
            if (!$sourceFile.StartsWith($source + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected comparison path' }
            $destinationFile = Join-Path $destination $sourceFile.Substring($source.Length + 1)
            if ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $destinationFile -Algorithm SHA256).Hash) { throw "Content mismatch; source retained: $sourceFile" }
        }
        Write-Output "SHA256_VERIFIED_TIMESTAMP_DIFFERENCES=$($differentFiles.Count)"
    } elseif ($verifyExit -ne 0) {
        throw "Copy comparison differs; source retained. See $verifyLog"
    }
    $backup = $source + '.before-drive-d-migration'
    if (Test-Path -LiteralPath $backup) { throw "Backup already exists: $backup" }
    # Validate every absolute source and backup before renaming/deleting directories.
    $allowedSources = @("$env:USERPROFILE\.gradle", "$env:LOCALAPPDATA\Pub\Cache", "$env:USERPROFILE\.android\avd")
    if ($source -notin $allowedSources -or $backup -ne ($source + '.before-drive-d-migration')) { throw 'Unexpected source path' }
    Move-Item -LiteralPath $source -Destination $backup
    try {
        New-Item -ItemType Junction -Path $source -Target $destination | Out-Null
        [Environment]::SetEnvironmentVariable($mapping.Variable, $destination, 'User')
    } catch {
        if (!(Test-Path -LiteralPath $source)) { Move-Item -LiteralPath $backup -Destination $source }
        throw
    }
    $completed += [pscustomobject]@{ Source = $source; Destination = $destination; Backup = $backup; Variable = $mapping.Variable }
    ConvertTo-Json -InputObject @($completed) | Set-Content -LiteralPath (Join-Path $reportRoot 'mappings.json')
    Write-Output "VERIFIED_AND_LINKED $source"
}

$newPubBin = "$cacheRoot\Pub\bin"
$oldPubBin = "$env:LOCALAPPDATA\Pub\Cache\bin"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = @($userPath -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ine $oldPubBin.TrimEnd('\') -and $_.TrimEnd('\') -ine $newPubBin.TrimEnd('\') })
$pathEntries += $newPubBin
[Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')
New-Item -ItemType Directory -Path "$cacheRoot\Temp" -Force | Out-Null
[Environment]::SetEnvironmentVariable('TEMP', "$cacheRoot\Temp", 'User')
[Environment]::SetEnvironmentVariable('TMP', "$cacheRoot\Temp", 'User')

# AVDs may contain absolute paths in their small descriptor files.
Get-ChildItem -LiteralPath "$cacheRoot\avd" -Filter '*.ini' -File | ForEach-Object {
    $iniText = [IO.File]::ReadAllText($_.FullName)
    $iniText = $iniText.Replace("$env:USERPROFILE\.android\avd\", "$cacheRoot\avd\")
    [IO.File]::WriteAllText($_.FullName, $iniText, (New-Object Text.UTF8Encoding($false)))
}
Write-Output "MIGRATION_REPORT=$reportRoot"
Write-Output 'Copies verified. Backups retained until tool validation.'
