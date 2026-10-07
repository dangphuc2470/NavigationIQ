# =============================================================================
# NavigationIQ - Automated Headless Fleet Preview & Screen Capture Script
# =============================================================================

param (
    [int]$WaitSeconds = 6,              # Thời gian chờ (giây) để app render UI trước khi chụp
    [string[]]$DeviceList = @(),        # Danh sách thiết bị cụ thể (nếu để trống sẽ chạy dàn mặc định)
    [switch]$KeepSimulatorOpen = $false # Giữ simulator mở sau khi chạy xong hay đóng lại
)

$ErrorActionPreference = "Stop"

# 1. Cấu hình môi trường Java & Garmin SDK
$JavaBin = "C:\Program Files\Android\Android Studio\jbr\bin"
if (Test-Path "$JavaBin\java.exe") {
    $env:Path = "$JavaBin;" + $env:Path
}

$SdkBin = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin"
$Key = Join-Path $PSScriptRoot "developer_key.der"
$Jungle = Join-Path $PSScriptRoot "monkey.jungle"
$OutDir = Join-Path $PSScriptRoot "screenshots"

if (!(Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# 2. Khai báo Win32 PrintWindow Background Capture Helper
$csharpCode = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class ScreenCaptureHelper {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdcBmp, uint nFlags);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public static IntPtr FindVisibleWindow(int pid) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((hWnd, lParam) => {
            uint procId;
            GetWindowThreadProcessId(hWnd, out procId);
            if (procId == pid && IsWindowVisible(hWnd)) {
                RECT r;
                GetWindowRect(hWnd, out r);
                int w = r.Right - r.Left;
                int h = r.Bottom - r.Top;
                if (w > 100 && h > 100) {
                    found = hWnd;
                    return false;
                }
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    public static bool CaptureSimulator(int pid, string filePath) {
        IntPtr hWnd = FindVisibleWindow(pid);
        if (hWnd == IntPtr.Zero) return false;

        RECT rect;
        if (!GetWindowRect(hWnd, out rect)) return false;

        int width = rect.Right - rect.Left;
        int height = rect.Bottom - rect.Top;
        if (width <= 50 || height <= 50) return false;

        using (Bitmap bmp = new Bitmap(width, height)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                IntPtr hdc = g.GetHdc();
                try {
                    PrintWindow(hWnd, hdc, 2); // 2 = PW_RENDERFULLCONTENT
                } finally {
                    g.ReleaseHdc(hdc);
                }
            }
            bmp.Save(filePath, ImageFormat.Png);
        }
        return true;
    }
}
"@

if (-not ([System.Management.Automation.PSTypeName]'ScreenCaptureHelper').Type) {
    Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies System.Drawing, System.Windows.Forms
}

# 3. Dàn thiết bị đại diện tiêu biểu (phủ trọn mọi kích thước màn hình)
$DefaultFleet = @(
    "venusq2",           # 1. Vuông AMOLED 320x360 (Venu Sq 2)
    "venu2",             # 2. Tròn AMOLED 416x416 chuẩn (Venu 2, Venu 3, FR265)
    "fr965",             # 3. Tròn AMOLED 454x454 siêu lớn (Forerunner 965, Epix Pro 51mm)
    "fr165",             # 4. Tròn AMOLED 390x390 gọn gàng (FR165, FR265s, Venu 3s)
    "fenix7",            # 5. Tròn MIP 260x260 kinh điển (Fenix 7, FR255, FR955)
    "fenix7x",           # 6. Tròn MIP 280x280 cỡ đại (Fenix 7X, Enduro 2)
    "fr55",              # 7. Tròn MIP 240x240 cỡ nhỏ (Forerunner 55)
    "fenix847mm",        # 8. Flagship AMOLED mới nhất (Fenix 8 47mm)
    "instinct2",         # 9. Đơn sắc 176x176 có sub-screen tròn góc (Instinct 2)
    "instinctcrossover"  # 10. Hybrid cơ học 176x176 (Instinct Crossover)
)

$Devices = if ($DeviceList.Count -gt 0) { 
    ($DeviceList | ForEach-Object { $_ -split ',' }).Trim() | Where-Object { $_ -ne "" } 
} else { 
    $DefaultFleet 
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " TU DONG CHAY PREVIEW & CHUP ANH TOAN BO DAN THIET BI GARMIN" -ForegroundColor Cyan
Write-Host " Tong cong: $($Devices.Count) thiet bi" -ForegroundColor Cyan
Write-Host " Thu muc anh dau ra: $OutDir" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 4. Đảm bảo Simulator đã được bật
$simProc = Get-Process "simulator" -ErrorAction SilentlyContinue | Select-Object -First 1
if (!$simProc) {
    Write-Host "[1/2] Khoi dong Garmin Connect IQ Simulator..." -ForegroundColor Yellow
    $simProc = Start-Process "$SdkBin\simulator.exe" -PassThru
    Start-Sleep -Seconds 4
} else {
    Write-Host "[1/2] Simulator da san sang (PID: $($simProc.Id))." -ForegroundColor Gray
}

# 5. Duyệt qua từng thiết bị để build, nạp và chụp ảnh
$binDir = Join-Path $PSScriptRoot "bin"
if (!(Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }

$idx = 1
$successCount = 0

foreach ($dev in $Devices) {
    Write-Host "`n[$idx/$($Devices.Count)] Dang xu ly: $dev" -ForegroundColor Cyan
    $prg = Join-Path $binDir "fleet_$dev.prg"
    $shotPath = Join-Path $OutDir "$($dev)_preview.png"

    # A. Biên dịch
    Write-Host "  -> Bien dich app cho $dev..." -ForegroundColor Gray
    & "$SdkBin\monkeyc.bat" -o $prg -f $Jungle -y $Key -d $dev 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0 -or !(Test-Path $prg)) {
        Write-Host "  [X] Loi bien dich cho $dev" -ForegroundColor Red
        $idx++
        continue
    }

    # B. Nạp vào Simulator
    Write-Host "  -> Nap vao Simulator va render Preview HUD..." -ForegroundColor Gray
    $doProc = Start-Process -FilePath "$SdkBin\monkeydo.bat" -ArgumentList "`"$prg`"", "$dev" -PassThru -WindowStyle Hidden

    # C. Đợi simulator nạp và chạy qua các bước điều hướng
    Start-Sleep -Seconds $WaitSeconds

    # D. Chụp ảnh nền qua PrintWindow API
    $currentSim = Get-Process "simulator" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($currentSim) {
        $captured = [ScreenCaptureHelper]::CaptureSimulator($currentSim.Id, $shotPath)
        if ($captured -and (Test-Path $shotPath)) {
            Write-Host "  [V] Da chup thanh cong: $shotPath" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  [!] Khong the chup cua so cho $dev" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [!] Khong tim thay process simulator" -ForegroundColor Yellow
    }

    # E. Dừng monkeydo tiến trình vừa rồi
    if ($doProc -and !$doProc.HasExited) {
        Stop-Process -Id $doProc.Id -Force -ErrorAction SilentlyContinue
    }

    $idx++
}

# 6. Dọn dẹp simulator nếu không yêu cầu giữ mở
if (!$KeepSimulatorOpen) {
    Get-Process "simulator" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "`n[Duy tri tai nguyen] Da dong Simulator sau khi chup xong." -ForegroundColor Gray
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " HOAN TAT! Da chup thanh cong $successCount/$($Devices.Count) thiet bi." -ForegroundColor Green
Write-Host " Thu muc chua anh: $OutDir" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
