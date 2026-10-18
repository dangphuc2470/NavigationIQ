# =============================================================================
# NavigationIQ - Automated Headless Fleet Preview & Screen Capture Script
# =============================================================================

param (
    [string]$Mode = "both",             # "both", "normal", hoặc "toast"
    [int]$WaitSeconds = 3,              # Thời gian chờ (giây) để app render UI trước khi chụp
    [string[]]$DeviceList = @(),        # Danh sách thiết bị cụ thể (nếu để trống sẽ chạy dàn mặc định)
    [switch]$KeepSimulatorOpen = $false # Giữ simulator mở sau khi chạy xong hay đóng lại
)

$ErrorActionPreference = "Continue"

# 1. Cấu hình môi trường Java & Garmin SDK
$JavaBin = "C:\Program Files\Android\Android Studio\jbr\bin"
if (Test-Path "$JavaBin\java.exe") {
    $env:Path = "$JavaBin;" + $env:Path
}

$SdkBin = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin"
$Key = Join-Path $PSScriptRoot "developer_key.der"
$Jungle = Join-Path $PSScriptRoot "monkey.jungle"
$BaseOutDir = Join-Path $PSScriptRoot "screenshots"
$PreviewManagerFile = Join-Path $PSScriptRoot "source\PreviewManager.mc"

if (!(Test-Path $BaseOutDir)) {
    New-Item -ItemType Directory -Path $BaseOutDir -Force | Out-Null
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

# 3. Dàn thiết bị đại diện tiêu biểu (phủ trọn 100% form factors & độ phân giải)
$DefaultFleet = @(
    "venusq2",           # 1. Vuông AMOLED 320x360 (Venu Sq 2, Sq 2 Music)
    "venu2",             # 2. Tròn AMOLED 416x416 chuẩn (Venu 2, Venu 3, FR265, Vivoactive 5)
    "venu2s",            # 3. Tròn AMOLED 360x360 gọn (Venu 2s, Venu 3s, FR265s)
    "fr965",             # 4. Tròn AMOLED 454x454 siêu lớn (Forerunner 965, Epix Pro 51mm)
    "fr165",             # 5. Tròn AMOLED 390x390 gọn gàng (FR165, FR165m)
    "fenix847mm",        # 6. Flagship AMOLED mới nhất (Fenix 8 47mm, Fenix E)
    "fenix7",            # 7. Tròn MIP 260x260 kinh điển (Fenix 7, FR255, FR955)
    "fenix7s",           # 8. Tròn MIP 240x240 gọn (Fenix 7s, FR255s)
    "fenix7x",           # 9. Tròn MIP 280x280 cỡ đại (Fenix 7X, Enduro 2, Enduro 3)
    "fr55",              # 10. Tròn MIP 240x240 cơ bản (Forerunner 55)
    "instinct2",         # 11. Đơn sắc 176x176 có sub-screen tròn góc (Instinct 2, 2X, 2S)
    "instinctcrossover"  # 12. Hybrid cơ học 176x176 (Instinct Crossover)
)

$Devices = if ($DeviceList.Count -gt 0) { 
    ($DeviceList | ForEach-Object { $_ -split ',' }).Trim() | Where-Object { $_ -ne "" } 
} else { 
    $DefaultFleet 
}

# Xác định danh sách các pass chạy
$Passes = @()
if ($Mode -eq "both") {
    $Passes = @("normal", "toast")
} elseif ($Mode -eq "normal" -or $Mode -eq "toast") {
    $Passes = @($Mode)
} else {
    Write-Error "Mode khong hop le: $Mode. Vui long chon 'both', 'normal' hoac 'toast'."
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " TU DONG CHAY PREVIEW & CHUP ANH TOAN BO DAN THIET BI GARMIN" -ForegroundColor Cyan
Write-Host " Che do render: $Mode" -ForegroundColor Cyan
Write-Host " Tong cong: $($Devices.Count) thiet bi x $($Passes.Count) che do = $($Devices.Count * $Passes.Count) anh" -ForegroundColor Cyan
Write-Host " Thu muc anh dau ra: $BaseOutDir" -ForegroundColor Cyan
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

# 5. Duyệt qua từng pass (normal / toast) và từng thiết bị
$binDir = Join-Path $PSScriptRoot "bin"
if (!(Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }

function Set-ToastFlag([bool]$enable) {
    $strVal = if ($enable) { "true" } else { "false" }
    $content = [System.IO.File]::ReadAllText($PreviewManagerFile, [System.Text.Encoding]::UTF8)
    $newContent = [System.Text.RegularExpressions.Regex]::Replace(
        $content,
        "public static var enableToast as Boolean = (true|false);",
        "public static var enableToast as Boolean = $strVal;"
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($PreviewManagerFile, $newContent, $utf8NoBom)
}

$totalSuccess = 0
$totalTarget = $Devices.Count * $Passes.Count

try {
    foreach ($pass in $Passes) {
        $targetDir = Join-Path $BaseOutDir $pass
        if (!(Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

        $isToast = ($pass -eq "toast")
        Write-Host "`n>>> BAT DAU CHUYEN: [$($pass.ToUpper()) HUD] (Toast=$isToast) <<<" -ForegroundColor Magenta
        Set-ToastFlag -enable $isToast

        $idx = 1
        foreach ($dev in $Devices) {
            Write-Host "  [$idx/$($Devices.Count)] ($pass) Dang xu ly: $dev" -ForegroundColor Cyan
            $prg = Join-Path $binDir "fleet_${pass}_$dev.prg"
            $shotPath = Join-Path $targetDir "$($dev).png"

            # A. Biên dịch
            & "$SdkBin\monkeyc.bat" -o $prg -f $Jungle -y $Key -d $dev 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0 -or !(Test-Path $prg)) {
                Write-Host "    [X] Loi bien dich cho $dev" -ForegroundColor Red
                $idx++
                continue
            }

            # B. Nạp vào Simulator
            $doProc = Start-Process -FilePath "$SdkBin\monkeydo.bat" -ArgumentList "`"$prg`"", "$dev" -PassThru -WindowStyle Hidden

            # C. Đợi simulator render
            Start-Sleep -Seconds $WaitSeconds

            # D. Chụp ảnh nền qua PrintWindow API
            $currentSim = Get-Process "simulator" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($currentSim) {
                $captured = [ScreenCaptureHelper]::CaptureSimulator($currentSim.Id, $shotPath)
                if ($captured -and (Test-Path $shotPath)) {
                    Write-Host "    [V] Da chup: $shotPath" -ForegroundColor Green
                    $totalSuccess++
                } else {
                    Write-Host "    [!] Khong the chup cho $dev" -ForegroundColor Yellow
                }
            } else {
                Write-Host "    [!] Khong tim thay process simulator" -ForegroundColor Yellow
            }

            # E. Dừng monkeydo
            if ($doProc -and !$doProc.HasExited) {
                Stop-Process -Id $doProc.Id -Force -ErrorAction SilentlyContinue
            }

            $idx++
        }
    }
}
finally {
    # Luôn khôi phục enableToast = false
    Set-ToastFlag -enable $false
}

# 6. Dọn dẹp simulator nếu không yêu cầu giữ mở
if (!$KeepSimulatorOpen) {
    Get-Process "simulator" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "`n[Duy tri tai nguyen] Da dong Simulator sau khi chup xong." -ForegroundColor Gray
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " HOAN TAT! Da chup thanh cong $totalSuccess/$totalTarget anh." -ForegroundColor Green
Write-Host " Thu muc anh: $BaseOutDir" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
