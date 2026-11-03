# Navigation IQ (NavIQ)

> **Navigation IQ** is a smart turn-by-turn navigation bridge connecting **Android (Jetpack Compose + Kotlin)** smartphones with **Garmin (Monkey C - Connect IQ)** smartwatches, supporting diverse screen form factors ranging from Square AMOLED and Round AMOLED/MIP to Dual-Zone MIP displays.

[![Connect IQ Store](https://img.shields.io/badge/Garmin_Connect_IQ-Navigation_IQ-007ACC?logo=garmin&logoColor=white)](https://apps.garmin.com/apps/c2c48dd7-47e7-4fac-98e2-6762d57ff181)
[![GitHub Release](https://img.shields.io/github/v/release/dangphuc2470/NavigationIQ?logo=github)](https://github.com/dangphuc2470/NavigationIQ/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

![Navigation IQ Showcase Banner](screenshots/00_navigation_iq_showcase_banner.png)

---

## Project Overview

Navigation IQ integrates two core architectural pillars:
1. **HUD Navigation Relay:** Transmits real-time turn instructions (direction arrow icons, remaining distance, street names, ETA) to Garmin watch faces via Bluetooth Low Energy using the Garmin Connect IQ Mobile SDK.
2. **Screen-Adaptive Engine:** Dynamically detects display geometries (Square, Round, Instinct Dual-Zone) and applies tailored typography presets for optimal glanceability while in motion.

---

## Android App Showcase

The Android application is built with modern **Jetpack Compose**, delivering an intuitive, fluid, and minimalist user experience:

| Dashboard | Watch Studio |
| :---: | :---: |
| ![Dashboard](screenshots/05_android_tab_navigation.png) | ![Watch Studio](screenshots/06_android_tab_watch_studio.png) |
| **Tab 0: Dashboard & Simulator**<br>Monitor Garmin watch connection status, launch navigation, and simulate test routes | **Tab 1: Watch Studio**<br>Real-time Live HUD Preview and layout typography presets |

| System Settings | Console Logs |
| :---: | :---: |
| ![System Settings](screenshots/07_android_tab_settings.png) | ![Console Logs](screenshots/08_android_tab_logs.png) |
| **Tab 2: System Settings**<br>Manage Connect IQ SDK pairing, watch app installation, and background battery optimization | **Tab 3: System Logs**<br>Inspect BLE transmission packets and verify two-way diagnostics |

---

## Garmin Watch HUD Showcase (Adaptive Layouts)

The Connect IQ watch app is available on the [Garmin Connect IQ Store](https://apps.garmin.com/apps/c2c48dd7-47e7-4fac-98e2-6762d57ff181) and individually optimized for each Garmin hardware display category:

| Square AMOLED (Venu Sq 2) | Round AMOLED / MIP (FR965, Fenix 7) | Instinct Crossover (Dual-Zone MIP) |
| :---: | :---: | :---: |
| ![Venu Sq 2 Square HUD](screenshots/01_venu_sq2_square_hud.png) | ![Forerunner 965 Round HUD](screenshots/02_fr965_fenix7_round_hud.png) | ![Instinct Crossover Dual-Zone](screenshots/03_instinct_crossover_dualzone_hud.png) |
| Optimized for square aspect ratio with large, prominent distance typography | Symmetrical radial layout with center-focused readability for running and cycling | Dual-zone partitioning engineered to prevent physical watch hands obstruction |

### Destination Reached & Trip Summary

When you arrive at your destination, Navigation IQ automatically transitions to a dedicated trip summary screen displaying the destination address, travel duration, total distance covered, and average speed:

![Destination Reached Showcase](screenshots/arrived_showcase.png)

---

## Supported Garmin Hardware Fleet (By Series)

> Navigation IQ is actively compiled, tested, and individually pixel-tuned for **86 Garmin device targets** across all Standard, Music, Pro, Sapphire, LTE & Solar editions (showcasing 65 distinct hardware models across 5 series below).

<details>
<summary><b>Fenix, Epix & Enduro Series (Outdoor Multi-Sport Flagships) (18 Models)</b></summary>

*Premium multi-sport watches with adaptive solar MIP and ultra-bright AMOLED graphics.*

| Device | Display & Architecture | Live Navigation HUD |
| :--- | :--- | :---: |
| **fēnix 8 Pro 47mm**<br><code>fenix8pro47mm</code> | 454x454 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/fenix8pro47mm.png" alt="fēnix 8 Pro 47mm" width="160" /> |
| **fēnix 8 47mm**<br><code>fenix847mm</code> | 454x454 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/fenix847mm.png" alt="fēnix 8 47mm" width="160" /> |
| **fēnix 8 43mm**<br><code>fenix843mm</code> | 416x416 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/fenix843mm.png" alt="fēnix 8 43mm" width="160" /> |
| **fēnix 8 Solar 51mm**<br><code>fenix8solar51mm</code> | 280x280 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix8solar51mm.png" alt="fēnix 8 Solar 51mm" width="160" /> |
| **fēnix 8 Solar 47mm**<br><code>fenix8solar47mm</code> | 260x260 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix8solar47mm.png" alt="fēnix 8 Solar 47mm" width="160" /> |
| **fēnix E**<br><code>fenixe</code> | 416x416 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/fenixe.png" alt="fēnix E" width="160" /> |
| **Enduro 3**<br><code>enduro3</code> | 280x280 MIP | <img src="screenshots/gallery/fenix_epix_enduro/enduro3.png" alt="Enduro 3" width="160" /> |
| **epix Pro (Gen 2) 51mm**<br><code>epix2pro51mm</code> | 454x454 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/epix2pro51mm.png" alt="epix Pro (Gen 2) 51mm" width="160" /> |
| **epix Pro (Gen 2) 47mm**<br><code>epix2pro47mm</code> | 416x416 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/epix2pro47mm.png" alt="epix Pro (Gen 2) 47mm" width="160" /> |
| **epix Pro (Gen 2) 42mm**<br><code>epix2pro42mm</code> | 390x390 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/epix2pro42mm.png" alt="epix Pro (Gen 2) 42mm" width="160" /> |
| **epix (Gen 2)**<br><code>epix2</code> | 416x416 AMOLED | <img src="screenshots/gallery/fenix_epix_enduro/epix2.png" alt="epix (Gen 2)" width="160" /> |
| **fēnix 7X / 7X Pro (51mm)**<br><code>fenix7x</code> | 280x280 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix7x.png" alt="fēnix 7X / 7X Pro" width="160" /> |
| **fēnix 7 / 7 Pro (47mm)**<br><code>fenix7</code> | 260x260 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix7.png" alt="fēnix 7 / 7 Pro" width="160" /> |
| **fēnix 7S / 7S Pro (42mm)**<br><code>fenix7s</code> | 240x240 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix7s.png" alt="fēnix 7S / 7S Pro" width="160" /> |
| **Enduro**<br><code>enduro</code> | 280x280 MIP | <img src="screenshots/gallery/fenix_epix_enduro/enduro.png" alt="Enduro" width="160" /> |
| **fēnix 6X Pro / Sapphire (51mm)**<br><code>fenix6xpro</code> | 280x280 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix6xpro.png" alt="fēnix 6X Pro" width="160" /> |
| **fēnix 6 / 6 Pro (47mm)**<br><code>fenix6</code> | 260x260 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix6.png" alt="fēnix 6 / 6 Pro" width="160" /> |
| **fēnix 6S / 6S Pro (42mm)**<br><code>fenix6s</code> | 240x240 MIP | <img src="screenshots/gallery/fenix_epix_enduro/fenix6s.png" alt="fēnix 6S / 6S Pro" width="160" /> |

</details>

<details>
<summary><b>Forerunner Series (Running Flagships & Essentials) (11 Models)</b></summary>

*Optimized glanceability while running, high contrast distance numbers and turn alerts.*

| Device | Display & Architecture | Live Navigation HUD |
| :--- | :--- | :---: |
| **Forerunner 965**<br><code>fr965</code> | 454x454 AMOLED | <img src="screenshots/gallery/forerunner/fr965.png" alt="Forerunner 965" width="160" /> |
| **Forerunner 955**<br><code>fr955</code> | 260x260 MIP | <img src="screenshots/gallery/forerunner/fr955.png" alt="Forerunner 955" width="160" /> |
| **Forerunner 945 / 945 LTE**<br><code>fr945</code> | 240x240 MIP | <img src="screenshots/gallery/forerunner/fr945.png" alt="Forerunner 945" width="160" /> |
| **Forerunner 745**<br><code>fr745</code> | 240x240 MIP | <img src="screenshots/gallery/forerunner/fr745.png" alt="Forerunner 745" width="160" /> |
| **Forerunner 265**<br><code>fr265</code> | 416x416 AMOLED | <img src="screenshots/gallery/forerunner/fr265.png" alt="Forerunner 265" width="160" /> |
| **Forerunner 265S**<br><code>fr265s</code> | 360x360 AMOLED | <img src="screenshots/gallery/forerunner/fr265s.png" alt="Forerunner 265S" width="160" /> |
| **Forerunner 255 / 255 Music**<br><code>fr255</code> | 260x260 MIP | <img src="screenshots/gallery/forerunner/fr255.png" alt="Forerunner 255" width="160" /> |
| **Forerunner 255S / 255S Music**<br><code>fr255s</code> | 218x218 MIP | <img src="screenshots/gallery/forerunner/fr255s.png" alt="Forerunner 255S" width="160" /> |
| **Forerunner 245 / 245 Music**<br><code>fr245</code> | 240x240 MIP | <img src="screenshots/gallery/forerunner/fr245.png" alt="Forerunner 245" width="160" /> |
| **Forerunner 165 / 165 Music**<br><code>fr165</code> | 390x390 AMOLED | <img src="screenshots/gallery/forerunner/fr165.png" alt="Forerunner 165" width="160" /> |
| **Forerunner 55**<br><code>fr55</code> | 240x240 MIP | <img src="screenshots/gallery/forerunner/fr55.png" alt="Forerunner 55" width="160" /> |

</details>

<details>
<summary><b>Venu & vívoactive Series (Lifestyle, Square & Round) (12 Models)</b></summary>

*Tailored for daily commutes and urban rides with both Squircle and Round layouts.*

| Device | Display & Architecture | Live Navigation HUD |
| :--- | :--- | :---: |
| **Venu 3**<br><code>venu3</code> | 454x454 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venu3.png" alt="Venu 3" width="160" /> |
| **Venu 3S**<br><code>venu3s</code> | 390x390 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venu3s.png" alt="Venu 3S" width="160" /> |
| **Venu 2 Plus**<br><code>venu2plus</code> | 416x416 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venu2plus.png" alt="Venu 2 Plus" width="160" /> |
| **Venu 2**<br><code>venu2</code> | 416x416 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venu2.png" alt="Venu 2" width="160" /> |
| **Venu 2S**<br><code>venu2s</code> | 360x360 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venu2s.png" alt="Venu 2S" width="160" /> |
| **Venu Sq 2 / Sq 2 Music**<br><code>venusq2</code> | 320x360 AMOLED Square | <img src="screenshots/gallery/venu_vivoactive/venusq2.png" alt="Venu Sq 2" width="160" /> |
| **Venu Sq / Sq Music**<br><code>venusq</code> | 240x240 LCD Square | <img src="screenshots/gallery/venu_vivoactive/venusq.png" alt="Venu Sq" width="160" /> |
| **Venu / Mercedes-Benz**<br><code>venu</code> | 390x390 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venu.png" alt="Venu" width="160" /> |
| **Venu X1**<br><code>venux1</code> | 416x416 AMOLED | <img src="screenshots/gallery/venu_vivoactive/venux1.png" alt="Venu X1" width="160" /> |
| **vívoactive 5**<br><code>vivoactive5</code> | 390x390 AMOLED | <img src="screenshots/gallery/venu_vivoactive/vivoactive5.png" alt="vívoactive 5" width="160" /> |
| **vívoactive 4**<br><code>vivoactive4</code> | 260x260 MIP | <img src="screenshots/gallery/venu_vivoactive/vivoactive4.png" alt="vívoactive 4" width="160" /> |
| **vívoactive 4S**<br><code>vivoactive4s</code> | 218x218 MIP | <img src="screenshots/gallery/venu_vivoactive/vivoactive4s.png" alt="vívoactive 4S" width="160" /> |

</details>

<details>
<summary><b>Instinct Series (Rugged Monochrome & AMOLED) (10 Models)</b></summary>

*Built for extreme outdoors. Dual-zone layout with dedicated directional sub-window.*

| Device | Display & Architecture | Live Navigation HUD |
| :--- | :--- | :---: |
| **Instinct 3 AMOLED (50mm)**<br><code>instinct3amoled50mm</code> | 416x416 AMOLED | <img src="screenshots/gallery/instinct/instinct3amoled50mm.png" alt="Instinct 3 AMOLED (50mm)" width="160" /> |
| **Instinct 3 AMOLED (45mm)**<br><code>instinct3amoled45mm</code> | 390x390 AMOLED | <img src="screenshots/gallery/instinct/instinct3amoled45mm.png" alt="Instinct 3 AMOLED (45mm)" width="160" /> |
| **Instinct 3 Solar (45mm)**<br><code>instinct3solar45mm</code> | 176x176 1-bit MIP | <img src="screenshots/gallery/instinct/instinct3solar45mm.png" alt="Instinct 3 Solar (45mm)" width="160" /> |
| **Instinct Crossover AMOLED**<br><code>instinctcrossoveramoled</code> | 390x390 AMOLED Hybrid | <img src="screenshots/gallery/instinct/instinctcrossoveramoled.png" alt="Instinct Crossover AMOLED" width="160" /> |
| **Instinct Crossover (45mm)**<br><code>instinctcrossover</code> | 176x176 MIP Hybrid | <img src="screenshots/gallery/instinct/instinctcrossover.png" alt="Instinct Crossover (45mm)" width="160" /> |
| **Instinct 2X Solar (50mm)**<br><code>instinct2x</code> | 176x176 1-bit MIP | <img src="screenshots/gallery/instinct/instinct2x.png" alt="Instinct 2X Solar (50mm)" width="160" /> |
| **Instinct 2 (45mm)**<br><code>instinct2</code> | 176x176 1-bit MIP | <img src="screenshots/gallery/instinct/instinct2.png" alt="Instinct 2 (45mm)" width="160" /> |
| **Instinct 2S (40mm)**<br><code>instinct2s</code> | 156x156 1-bit MIP | <img src="screenshots/gallery/instinct/instinct2s.png" alt="Instinct 2S (40mm)" width="160" /> |
| **Instinct E (45mm)**<br><code>instincte45mm</code> | 176x176 1-bit MIP | <img src="screenshots/gallery/instinct/instincte45mm.png" alt="Instinct E (45mm)" width="160" /> |
| **Instinct E (40mm)**<br><code>instincte40mm</code> | 166x166 1-bit MIP | <img src="screenshots/gallery/instinct/instincte40mm.png" alt="Instinct E (40mm)" width="160" /> |

</details>

<details>
<summary><b>Specialty Series (Golf, Diving, Aviator & Luxury) (14 Models)</b></summary>

*Dedicated hardware adaptations for Approach golf watches, Descent dive computers, and D2 aviator models.*

| Device | Display & Architecture | Live Navigation HUD |
| :--- | :--- | :---: |
| **Approach S70 47mm (Golf)**<br><code>approachs7047mm</code> | 454x454 AMOLED | <img src="screenshots/gallery/specialty/approachs7047mm.png" alt="Approach S70 47mm (Golf)" width="160" /> |
| **Approach S70 42mm (Golf)**<br><code>approachs7042mm</code> | 390x390 AMOLED | <img src="screenshots/gallery/specialty/approachs7042mm.png" alt="Approach S70 42mm (Golf)" width="160" /> |
| **Descent Mk3i 51mm (Diving)**<br><code>descentmk351mm</code> | 454x454 AMOLED | <img src="screenshots/gallery/specialty/descentmk351mm.png" alt="Descent Mk3i 51mm (Diving)" width="160" /> |
| **Descent Mk3 43mm (Diving)**<br><code>descentmk343mm</code> | 390x390 AMOLED | <img src="screenshots/gallery/specialty/descentmk343mm.png" alt="Descent Mk3 43mm (Diving)" width="160" /> |
| **Descent Mk2 / Mk2S (Diving)**<br><code>descentmk2</code> | 280x280 MIP | <img src="screenshots/gallery/specialty/descentmk2.png" alt="Descent Mk2 (Diving)" width="160" /> |
| **Descent G2 (Diving)**<br><code>descentg2</code> | 390x390 AMOLED | <img src="screenshots/gallery/specialty/descentg2.png" alt="Descent G2 (Diving)" width="160" /> |
| **Descent G1 / Solar (Diving)**<br><code>descentg1</code> | 176x176 1-bit MIP | <img src="screenshots/gallery/specialty/descentg1.png" alt="Descent G1 / Solar (Diving)" width="160" /> |
| **D2 Mach 2 Pro (Aviator)**<br><code>d2mach2pro</code> | 454x454 AMOLED | <img src="screenshots/gallery/specialty/d2mach2pro.png" alt="D2 Mach 2 Pro (Aviator)" width="160" /> |
| **D2 Mach 2 (Aviator)**<br><code>d2mach2</code> | 454x454 AMOLED | <img src="screenshots/gallery/specialty/d2mach2.png" alt="D2 Mach 2 (Aviator)" width="160" /> |
| **D2 Mach 1 (Aviator)**<br><code>d2mach1</code> | 416x416 AMOLED | <img src="screenshots/gallery/specialty/d2mach1.png" alt="D2 Mach 1 (Aviator)" width="160" /> |
| **D2 Air X10 (Aviator)**<br><code>d2airx10</code> | 416x416 AMOLED | <img src="screenshots/gallery/specialty/d2airx10.png" alt="D2 Air X10 (Aviator)" width="160" /> |
| **MARQ (Gen 2) Aviator**<br><code>marq2aviator</code> | 390x390 AMOLED | <img src="screenshots/gallery/specialty/marq2aviator.png" alt="MARQ (Gen 2) Aviator" width="160" /> |
| **MARQ (Gen 2)**<br><code>marq2</code> | 390x390 AMOLED | <img src="screenshots/gallery/specialty/marq2.png" alt="MARQ (Gen 2)" width="160" /> |
| **MARQ Gen 1 Series**<br><code>marqathlete</code> | 240x240 MIP | <img src="screenshots/gallery/specialty/marqathlete.png" alt="MARQ Gen 1 Series" width="160" /> |

</details>

---

## Project Architecture & Directory Structure

```text
NavigationIQ/
├── README.md                                    # Architecture overview and documentation
├── screenshots/                                 # Showcase banner, exhibits, and fleet gallery
│   ├── 00_navigation_iq_showcase_banner.png
│   ├── 01_venu_sq2_square_hud.png
│   ├── 02_fr965_fenix7_round_hud.png
│   ├── 03_instinct_crossover_dualzone_hud.png
│   ├── 05_android_tab_navigation.png
│   ├── 06_android_tab_watch_studio.png
│   ├── 07_android_tab_settings.png
│   ├── 08_android_tab_logs.png
│   ├── arrived_showcase.png                     # Destination reached & trip summary showcase
│   └── gallery/                                 # Full fleet HUD screenshots (65 distinct hardware models / 86 device targets)
│       ├── fenix_epix_enduro/                   # Fenix 8/7, Epix, Enduro series
│       ├── forerunner/                          # Forerunner 965/955/265/255/165/55
│       ├── venu_vivoactive/                     # Venu 3/2, Venu Sq, vívoactive 5
│       ├── instinct/                            # Instinct 3, Instinct 2, Crossover, Instinct E
│       └── specialty/                           # Approach S70, Descent Mk3/G, D2 Mach, MARQ
├── app/                                         # Android App (Kotlin + Jetpack Compose)
│   ├── build.gradle.kts
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── java/
│           ├── com/garmin/android/connectiq/    # Garmin ConnectIQ Mobile SDK
│           └── com/phucdnh/navigationiq/
│               ├── MainActivity.kt              # Jetpack Compose UI (4 Tabs, Liquid Sliding Indicator)
│               ├── model/
│               │   └── NavigationInfo.kt        # Navigation data model & RLE encoder
│               └── garmin/
│                   ├── GarminMessage.kt         # Diff cache & packet serialization
│                   └── GarminManager.kt         # ConnectIQ SDK lifecycle management
└── garmin_app/                                  # Garmin Connect IQ Watch App (Monkey C)
    ├── manifest.xml
    └── source/
        ├── NavigationIQApp.mc                   # Lifecycle & Connect IQ App Entry
        ├── NavigationIQView.mc                  # Layout renderer (Adaptive Square / Round / Instinct)
        └── NavigationIQDelegate.mc              # Physical key and touch gesture handlers
```

---

## Installation & Developer Guide

### Quick Install (End Users)
1. **Garmin Smartwatch:** Install directly from the [Garmin Connect IQ Store](https://apps.garmin.com/apps/c2c48dd7-47e7-4fac-98e2-6762d57ff181).
2. **Android Phone:** Download and install the latest `NavigationIQ-v1.0.0.apk` from [GitHub Releases](https://github.com/dangphuc2470/NavigationIQ/releases).

### Developer Build Guide

#### 1. Android App
- Requirements: Android Studio Jellyfish or newer, JDK 17.
- Build & install via PowerShell script:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .vscode/run_android.ps1
  ```

#### 2. Garmin Watch App
- Requirements: Garmin Connect IQ SDK 7.x or newer.
- Supported devices: 50+ Garmin smartwatches across Fenix, Forerunner, Venu, Instinct, Approach, Descent, D2 & MARQ series.
- Build & run in simulator:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .vscode/run_garmin.ps1
  ```
