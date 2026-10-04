import Toybox.Lang;
import Toybox.System;

// =============================================================================
// PREVIEW MANAGER & SCENARIO ENGINE
// =============================================================================

class PreviewManager {

    private static var _previewSteps as Array<Array<Object>> = [
        // 0. Đi thẳng (Straight) - Highway speed
        [
            DIR_STRAIGHT,
            "2,8 km",
            "Tiếp tục đi thẳng trên Quốc lộ 1A về hướng Cầu Cần Thơ",
            "17:48",
            0
        ],
        // 1. Rẽ phải (Turn Right) - Approaching junction
        [
            DIR_RIGHT,
            "250 m",
            "Rẽ phải vào đường Lê Lợi",
            "17:44",
            0
        ],
        // 2. Vòng xoay lối ra thứ 2 (Roundabout Exit 2)
        [
            DIR_ROUNDABOUT_2,
            "150 m",
            "Tại bùng binh, đi theo lối ra thứ 2 vào đường Nguyễn Huệ",
            "17:41",
            2
        ],
        // 3. Rẽ trái (Turn Left) - Immediate turn
        [
            DIR_LEFT,
            "80 m",
            "Rẽ trái vào đường Nam Kỳ Khởi Nghĩa",
            "17:38",
            0
        ],
        // 4. Quay đầu xe (U-Turn)
        [
            DIR_UTURN,
            "30 m",
            "Quay đầu xe tại điểm mở dải phân cách",
            "17:35",
            0
        ],
        // 5. Chếch sang phải (Slight Right) - Highway ramp
        [
            DIR_SLIGHT_RIGHT,
            "450 m",
            "Đi chếch sang phải vào đường gom cao tốc",
            "17:31",
            0
        ],
        // 6. Vòng xoay lối ra thứ 4 (Roundabout Exit 4) - Complex roundabout
        [
            DIR_ROUNDABOUT_4,
            "120 m",
            "Tại vòng xoay, đi theo lối ra thứ 4 vào đường Võ Văn Kiệt",
            "17:27",
            4
        ],
        // 7. Chếch sang trái (Slight Left) - Overpass
        [
            DIR_SLIGHT_LEFT,
            "350 m",
            "Đi chếch sang trái vào cầu vượt Hoàng Hoa Thám",
            "17:23",
            0
        ],
        // 8. Rẽ ngoặt sang phải (Sharp Right)
        [
            DIR_SHARP_RIGHT,
            "60 m",
            "Rẽ ngoặt sang phải vào hẻm 284 Hai Bà Trưng",
            "17:20",
            0
        ],
        // 9. Vòng xoay lối ra thứ 1 (Roundabout Exit 1)
        [
            DIR_ROUNDABOUT_1,
            "200 m",
            "Tại bùng binh, đi theo lối ra thứ nhất vào đường Trần Hưng Đạo",
            "17:16",
            1
        ]
    ];

    public static function getStepCount() as Number {
        return _previewSteps.size();
    }

    public static function applyStep(stepIndex as Number) as Void {
        var idx = stepIndex % _previewSteps.size();
        var step = _previewSteps[idx];

        CommManager.isActive = true;
        CommManager.direction = step[0] as Number;
        CommManager.distText = step[1] as String;
        CommManager.navText = step[2] as String;
        CommManager.etaText = step[3] as String;
        CommManager.exitNumber = step[4] as Number;
        CommManager.isWaitingImage = false;
        CommManager.rleBitmap = null;
    }
}
