# =============================================================================
# NavigationIQ - Automated Fleet Preview & Screen Capture Script
# =============================================================================

param (
    [switch]$Interactive = $false, # Dừng lại chờ người dùng bấm phím Enter sau mỗi máy
    [int]$WaitSeconds = 5,         # Thời gian chờ (giây) để app load và chạy Preview Mode
    [string[]]$DeviceList = @()    # Tùy chọn chỉ định danh sách thiết bị cụ thể (ví dụ: -DeviceList fr965, fenix7)
)

$ErrorActionPreference = "Stop"

# 1. Cấu hình môi trường
$JavaBin = "C:\Program Files\Android\Android Studio\jbr\bin"
if (Test-Path "$JavaBin\java.exe") {
    $env:Path = "$JavaBin;" + $env:Path
}

$SdkBin = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin"
$Key = "developer_key.der"
$Jungle = "monkey.jungle"
$OutDir = Join-Path $PSScriptRoot "screenshots"

if (!(Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# 2. Dàn thiết bị đại diện cho toàn bộ các phân khúc màn hình trong manifest.xml
$DefaultFleet = @(
    "venusq2",           # 1. Vuông AMOLED 320x360 (Venu Sq 2)
    "venu2",             # 2. Tròn AMOLED 416x416 chuẩn (Venu 2/3, FR265)
    "fr965",             # 3. Tròn AMOLED 454x454 siêu lớn (Forerunner 965, Epix Pro 51mm)
    "fr165",             # 4. Tròn AMOLED 390x390 gọn gàng (FR165, FR265s, Venu 3s)
    "fenix7",            # 5. Tròn MIP 260x260 kinh điển (Fenix 7, FR255, FR955)
    "fenix7x",           # 6. Tròn MIP 280x280 cỡ đại (Fenix 7X, Enduro 2)
    "fr55",              # 7. Tròn MIP 240x240 cỡ nhỏ (Forerunner 55)
    "fenix847mm",        # 8. Flagship AMOLED mới nhất (Fenix 8 47mm)
    "instinct2",         # 9. Đơn sắc 176x176 có sub-screen tròn góc (Instinct 2)
    "instinctcrossover"  # 10. Hybrid cơ học 176x176 (Instinct Crossover)
)

$Devices = if ($DeviceList.Count -gt 0) { $DeviceList } else { $DefaultFleet }

# 3. Khai báo Win32 API để định vị cửa sổ Simulator và chụp ảnh màn hình
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
if (-not ([System.Management.Automation.PSTypeName]'WinApi').Type) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WinApi {
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }
    }
"@
}

function Capture-SimulatorWindow([string]$SavePath) {
    $simProc = Get-Process "simulator" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if (!$simProc) {
        Write-Warning "Khong tim thay handle cua so Simulator de chup anh."
        return
    }

    [WinApi]::SetForegroundWindow($simProc.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 400

    $rect = New-Object WinApi+RECT
    [WinApi]::GetWindowRect($simProc.MainWindowHandle, [ref]$rect) | Out-Null

    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top

    if ($width -gt 50 -and $height -gt 50) {
        $bitmap = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size($width, $height)))
        $bitmap.Save($SavePath, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()
        Write-Host " [V] Da chup anh luu vao: $SavePath" -ForegroundColor Green
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BAT DAU CHAY PREVIEW FULL THIET BI NAVIGATION IQ " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 4. Đảm bảo Simulator đã được bật
$sim = Get-Process "simulator" -ErrorAction SilentlyContinue
if (!$sim) {
    Write-Host "[1/3] Khoi dong Garmin Connect IQ Simulator..." -ForegroundColor Yellow
    Start-Process "$SdkBin\simulator.exe"
    Start-Sleep -Seconds 4
} else {
    Write-Host "[1/3] Simulator da duoc mo san sang." -ForegroundColor Gray
}

# 5. Duyệt qua từng thiết bị
$binDir = Join-Path $PSScriptRoot "bin"
if (!(Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }

$idx = 1
foreach ($dev in $Devices) {
    Write-Host "`n[$idx/$($Devices.Count)] Dang xu ly thiet bi: $dev" -ForegroundColor Cyan
    $prg = Join-Path $binDir "preview_$dev.prg"

    Write-Host "  -> Dang bien dich app cho $dev..." -ForegroundColor Gray
    & "$SdkBin\monkeyc.bat" -o $prg -f $Jungle -y $Key -d $dev
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [X] Loi bien dich cho $dev" -ForegroundColor Red
        continue
    }

    Write-Host "  -> Nap app vao Simulator..." -ForegroundColor Gray
    $doProc = Start-Process -FilePath "$SdkBin\monkeydo.bat" -ArgumentList "`"$prg`"", "$dev" -PassThru -WindowStyle Hidden
    
    Write-Host "  -> Dang doi $WaitSeconds giay de PreviewManager hien thi UI..." -ForegroundColor Yellow
    Start-Sleep -Seconds $WaitSeconds

    $shotPath = Join-Path $OutDir "$($dev)_preview.png"
    Capture-SimulatorWindow -SavePath $shotPath

    if ($Interactive) {
        Read-Host "  [?] Nhan Enter de chuyen qua thiet bi ke tiep..."
    }

    # Dung tien trinh monkeydo cu truoc khi chuyen sang device tiep theo
    if ($doProc -and !$doProc.HasExited) {
        Stop-Process -Id $doProc.Id -Force -ErrorAction SilentlyContinue
    }

    $idx++
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " HOAN TAT KIEM TRA FULL THIET BI!" -ForegroundColor Green
Write-Host " Tat ca anh man hinh da duoc luu tai: $OutDir" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
