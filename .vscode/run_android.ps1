param(
    [string]$BuildType = "Debug",
    [ValidateSet("auto", "device", "emulator")]
    [string]$Target = "auto"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " NavigationIQ Android Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check ADB & SDK
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
    }
}

$adb = "adb"
$adbCmd = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbCmd -and $sdkDir) {
    $adbCandidate = Join-Path $sdkDir "platform-tools\adb.exe"
    if (Test-Path $adbCandidate) {
        $adb = $adbCandidate
    }
}

# 2. Check connected devices
Write-Host "Checking connected Android devices..." -ForegroundColor Yellow
$deviceLines = @(& $adb devices | Where-Object { $_ -match '\s+device$' })

if ($deviceLines.Count -eq 0) {
    Write-Host "No connected Android devices or emulators found." -ForegroundColor Yellow
    Write-Host "Automatically launching Android emulator..." -ForegroundColor Cyan

    $emuScript = Join-Path $PSScriptRoot "run_emulator.ps1"
    & powershell -ExecutionPolicy Bypass -File $emuScript

    Write-Host "Waiting for emulator to come online..." -ForegroundColor Yellow
    & $adb wait-for-device

    # Wait until boot completed
    $booted = $false
    for ($i = 0; $i -lt 30; $i++) {
        $status = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
        if ($status -eq "1") {
            $booted = $true
            break
        }
        Start-Sleep -Seconds 2
    }

    $deviceLines = @(& $adb devices | Where-Object { $_ -match '\s+device$' })
    if ($deviceLines.Count -eq 0) {
        Write-Error "Failed to detect emulator after launch."
        exit 1
    }
}

$emulatorLines = @($deviceLines | Where-Object { $_ -match '^emulator-' })
$physicalLines = @($deviceLines | Where-Object { $_ -notmatch '^emulator-' })

Write-Host "Connected devices:" -ForegroundColor Yellow
foreach ($line in $deviceLines) {
    $id = ($line.Trim() -split '\s+')[0]
    $kind = if ($id -match '^emulator-') { "emulator" } else { "phone/device" }
    $model = (& $adb -s $id shell getprop ro.product.model 2>$null).Trim()
    Write-Host ("  - {0} ({1}) model={2}" -f $id, $kind, $model)
}

switch ($Target) {
    "device" {
        if ($physicalLines.Count -eq 0) {
            Write-Error "No physical device connected. Use -Target emulator or plug in your phone."
            exit 1
        }
        $targetDevice = ($physicalLines[0].Trim() -split '\s+')[0]
    }
    "emulator" {
        if ($emulatorLines.Count -eq 0) {
            Write-Error "No emulator connected."
            exit 1
        }
        $targetDevice = ($emulatorLines[0].Trim() -split '\s+')[0]
    }
    default {
        if ($physicalLines.Count -gt 0) {
            $targetDevice = ($physicalLines[0].Trim() -split '\s+')[0]
        } elseif ($emulatorLines.Count -gt 0) {
            $targetDevice = ($emulatorLines[0].Trim() -split '\s+')[0]
        } else {
            $targetDevice = ($deviceLines[0].Trim() -split '\s+')[0]
        }
    }
}

$targetModel = (& $adb -s $targetDevice shell getprop ro.product.model 2>$null).Trim()
Write-Host ">>> TARGET DEVICE: $targetDevice ($targetModel) <<<" -ForegroundColor Magenta
$env:ANDROID_SERIAL = $targetDevice

# Forward Garmin Connect IQ port (7381)
Write-Host "Forwarding Garmin Connect IQ port 7381..." -ForegroundColor Yellow
& $adb -s $targetDevice forward tcp:7381 tcp:7381 | Out-Null

$appId = "com.phucdnh.navigationiq"
$activity = "$appId/.MainActivity"

# Force stop previous instance
Write-Host "Stopping existing $appId..." -ForegroundColor Yellow
& $adb -s $targetDevice shell am force-stop $appId | Out-Null

# 3. Build & Install via Gradle
$gradleTask = ":app:install$($BuildType)"
Write-Host "Running Gradle task: $gradleTask..." -ForegroundColor Yellow

$gradlew = Join-Path $ProjectRoot "gradlew.bat"
if (-not (Test-Path $gradlew)) {
    Write-Error "gradlew.bat not found at $gradlew"
    exit 1
}

& $gradlew $gradleTask
if ($LASTEXITCODE -ne 0) {
    Write-Host "Gradle build/install failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 4. Cold start MainActivity
Write-Host "Starting $activity on $targetDevice..." -ForegroundColor Yellow
& $adb -s $targetDevice shell am force-stop $appId | Out-Null
Start-Sleep -Milliseconds 400
& $adb -s $targetDevice shell am start -S -n $activity

if ($LASTEXITCODE -eq 0) {
    Write-Host "NavigationIQ started successfully on $targetDevice ($targetModel)" -ForegroundColor Green
} else {
    Write-Host "Failed to start activity: $activity" -ForegroundColor Red
    exit $LASTEXITCODE
}
