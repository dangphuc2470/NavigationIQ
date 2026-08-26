# 🧭 Navigation IQ (NavIQ)

> **Navigation IQ** là giải pháp cầu nối điều hướng thông minh giữa điện thoại **Android (Kotlin)** và đồng hồ thông minh **Garmin (Monkey C - Connect IQ)**, đặc biệt tối ưu cho màn hình AMOLED của dòng **Garmin Venu Sq 2**.

---

## 🌟 Tổng quan Dự án

App kết hợp 2 sức mạnh cốt lõi:
1. **HUD Navigation Relay (Kế thừa từ HeadUpNav):** Tự động "bắt" (intercept) thông báo chỉ đường thời gian thực từ Google Maps / OsmAnd trên điện thoại và bắn các chỉ dẫn rẽ (mũi tên, số mét, tên đường, ETA) sang mặt đồng hồ Garmin.
2. **Offline Maps Engine (Nâng cấp độc quyền):** Render trực tiếp các mảnh bản đồ ngoại tuyến (Offline Map Tiles từ dữ liệu OpenStreetMap) trên CPU/GPU điện thoại rồi truyền tải siêu tốc sang Garmin Venu Sq 2, hoạt động 100% không cần 4G/Internet.

---

## 🔍 Phương Pháp Phát Triển (Side-by-Side Reverse Engineering)

Dự án áp dụng phương pháp **đối chiếu song song 1:1 (Side-by-Side)** giữa mã nguồn Java đã dịch ngược từ app gốc và mã nguồn Kotlin mới:

### Bảng Ánh Xạ Mã Nguồn (1:1 Source Mapping)

| File Java Gốc (`headupnav_wear\jadx_out\`) | File Kotlin Mới (`NavigationIQ\app\src\main\java\com\phucdnh\navigationiq\`) | Logic Cốt Lõi & Nhiệm Vụ |
| :--- | :--- | :--- |
| [`NotificationService.java`](file:///d:/Project/APKMod/headupnav_wear/jadx_out/sources/com/navigationparser/lib/NotificationService.java) | [`service/NavNotificationService.kt`](file:///D:/Project/APKMod/NavigationIQ/app/src/main/java/com/phucdnh/navigationiq/service/NavNotificationService.kt) | Lắng nghe `onNotificationPosted` và `onNotificationRemoved` từ Google Maps / OsmAnd |
| [`NotificationParser.java`](file:///d:/Project/APKMod/headupnav_wear/jadx_out/sources/com/navigationparser/lib/Parsing/NotificationParser.java) | [`parser/NotificationParser.kt`](file:///D:/Project/APKMod/NavigationIQ/app/src/main/java/com/phucdnh/navigationiq/parser/NotificationParser.kt) | Inflate và bóc tách View Hierarchy từ `RemoteViews` & `Notification.extras` |
| [`ParserMaps.java`](file:///d:/Project/APKMod/headupnav_wear/jadx_out/sources/com/navigationparser/lib/Parsing/Maps/ParserMaps.java) | [`parser/GoogleMapsParser.kt`](file:///D:/Project/APKMod/NavigationIQ/app/src/main/java/com/phucdnh/navigationiq/parser/GoogleMapsParser.kt) | Trích xuất Regex cho: Mét/Km, tên đường, hướng rẽ, ETA, thời gian đến |
| [`NavigationInfo.java`](file:///d:/Project/APKMod/headupnav_wear/jadx_out/sources/com/navigationparser/lib/Parsing/NavigationInfo.java) | [`model/NavigationInfo.kt`](file:///D:/Project/APKMod/NavigationIQ/app/src/main/java/com/phucdnh/navigationiq/model/NavigationInfo.kt) | Data model lưu trữ toàn bộ trạng thái chỉ đường, icon mũi tên và phương thức nén dữ liệu |
| [`ConnectIQManager.java`](file:///d:/Project/APKMod/headupnav_wear/jadx_out/sources/com/headupnav/navigationwear/ConnectIQManager.java) | [`garmin/GarminManager.kt`](file:///D:/Project/APKMod/NavigationIQ/app/src/main/java/com/phucdnh/navigationiq/garmin/GarminManager.kt) | Kết nối Garmin ConnectIQ Mobile SDK, nén ảnh RLE `85x85`, cơ chế cache & gửi gói tin qua BLE |

---

## 📂 Cấu trúc Thư mục Dự án

```text
NavigationIQ/
├── README.md                                    # Tài liệu kiến trúc & kế hoạch dự án
├── build.gradle.kts
├── settings.gradle.kts
└── app/                                         # Android Studio Kotlin Module
    ├── build.gradle.kts                         # Cấu hình Compose & dependencies
    └── src/main/
        ├── AndroidManifest.xml                  # Khai báo Service & Permissions
        └── java/
            ├── com/garmin/android/connectiq/    # Garmin ConnectIQ Mobile SDK
            └── com/phucdnh/navigationiq/
                ├── MainActivity.kt              # Jetpack Compose UI
                ├── model/
                │   └── NavigationInfo.kt        # Data model chỉ đường & RLE encoder
                ├── parser/
                │   ├── NotificationValues.kt
                │   ├── NotificationParser.kt    # Bóc tách RemoteViews
                │   ├── MapsUtils.kt
                │   └── GoogleMapsParser.kt      # Trích xuất dữ liệu Google Maps
                ├── garmin/
                │   ├── GarminMessage.kt         # Diff cache & serialization
                │   └── GarminManager.kt         # Quản lý ConnectIQ SDK
                └── service/
                    └── NavNotificationService.kt# NotificationListenerService
```
