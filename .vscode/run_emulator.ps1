param(
    [string]$AvdName = "",
    [switch]$Garmin = $false
)

$ErrorActionPreference = "Stop"

if ($Garmin) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Launching Garmin Connect IQ Simulator" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $sdkCfg = "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
    $sdkPath = $null
    if (Test-Path $sdkCfg) {
        $sdkPath = (Get-Content $sdkCfg -Raw).Trim()
    }

    if (-not $sdkPath -or -not (Test-Path $sdkPath)) {
        $candidatePaths = Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($candidatePaths.Count -gt 0) {
            $sdkPath = $candidatePaths[0].FullName
        }
    }

    if (-not $sdkPath) {
        Write-Error "Garmin Connect IQ SDK path not found!"
        exit 1
    }

    $simBat = Join-Path $sdkPath "bin\connectiq.bat"
    if (-not (Test-Path $simBat)) {
        Write-Error "connectiq.bat not found at $simBat"
        exit 1
    }

    # Forward ADB port 7381 if adb exists
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) {
        adb forward tcp:7381 tcp:7381 2>$null | Out-Null
    } elseif ($env:LOCALAPPDATA -and (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe")) {
        & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" forward tcp:7381 tcp:7381 2>$null | Out-Null
    }

    Write-Host "Starting Garmin Simulator from $simBat..." -ForegroundColor Green
    cmd /c start "" "$simBat"
    Write-Host "Garmin Simulator launched in background!" -ForegroundColor Green
    exit 0
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Launching Android Emulator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Resolve Android SDK path
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$localProp = Join-Path $ProjectRoot "local.properties"
$sdkDir = $null

if (Test-Path $localProp) {
    $match = Get-Content $localProp | Where-Object { $_ -match '^sdk\.dir=(.+)' }
    if ($match) {
        $sdkDir = ($match -replace '^sdk\.dir=', '').Replace('\\', '\').Trim()
    }
}

if (-not $sdkDir -or -not (Test-Path $sdkDir)) {
    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
        $sdkDir = $env:ANDROID_HOME
    } elseif ($env:LOCALAPPDATA -and (Test-Path "$env:LOCALAPPDATA\Android\Sdk")) {
        $sdkDir = "$env:LOCALAPPDATA\Android\Sdk"
    } else {
        Write-Error "Android SDK directory not found!"
        exit 1
    }
}

$emulatorExe = Join-Path $sdkDir "emulator\emulator.exe"
if (-not (Test-Path $emulatorExe)) {
    Write-Error "emulator.exe not found at $emulatorExe"
    exit 1
}

# 2. Check ADB & running emulators
$adbExe = Join-Path $sdkDir "platform-tools\adb.exe"
if (Test-Path $adbExe) {
    $runningEmulators = @(& $adbExe devices | Where-Object { $_ -match '^emulator-\d+\s+device' })
    if ($runningEmulators.Count -gt 0) {
        Write-Host "An Android emulator is already running: $($runningEmulators -join ', ')" -ForegroundColor Yellow
        Write-Host "Forwarding Garmin Connect IQ port 7381..." -ForegroundColor Yellow
        & $adbExe forward tcp:7381 tcp:7381 2>$null | Out-Null
        Write-Host "Port 7381 forwarded. Skipping launch (already running)." -ForegroundColor Green
        exit 0
    }
}

# 3. Determine AVD to run
if (-not $AvdName) {
    $availableAvds = @(& $emulatorExe -list-avds)
    if ($availableAvds.Count -eq 0) {
        Write-Error "No Android Virtual Devices (AVD) found! Please create one in Android Studio."
        exit 1
    }

    if ($availableAvds -contains "Pixel_10_Pro_Fold") {
        $AvdName = "Pixel_10_Pro_Fold"
    } else {
        $AvdName = $availableAvds[0]
    }
}

Write-Host "Starting AVD: $AvdName in background..." -ForegroundColor Green
Start-Process -FilePath $emulatorExe -ArgumentList "-avd", $AvdName
Write-Host "Emulator '$AvdName' started successfully!" -ForegroundColor Green
