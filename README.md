# <img src="resources/drawables/launcher_icon.png" width="36" valign="middle"> Garmin Triathlon Training WatchFace

A lightweight, customizable multi-sport watch face developed in **Monkey C** for Garmin Connect IQ devices, designed to track rolling 7-day training volumes across the three triathlon disciplines (swimming, cycling, and running) alongside key daily physiological metrics.

## Table of Contents
1. [Project Overview](#project-overview)
   - [The Problem and Motivation](#the-problem-and-motivation)
   - [Technical Solution](#technical-solution)
   - [Built With](#built-with)
2. [Key Features](#key-features)
3. [Architecture and Engineering Choices](#architecture-and-engineering-choices)
4. [Getting Started](#getting-started)
   - [User Installation](#user-installation)
   - [Building from Source (Developers)](#building-from-source-developers)
   - [Generating the Custom Icon Font](#generating-the-custom-icon-font)
5. [Usage and Configuration](#usage-and-configuration)
6. [Supported Devices](#supported-devices)
7. [Repository Structure](#repository-structure)
8. [Contributing](#contributing)
9. [License](#license)

---

## Project Overview

<p align="center">
  <img src="resources/images/app_example.png" alt="WatchFace Screenshot" width="300">
</p>

### The Problem and Motivation
This project grew out of a personal need I ran into while training for a triathlon race. During the months of specific preparation, I wanted an easy way to keep track of the total volume accumulated in each discipline: how many kilometers I swam, rode, and ran over the course of the rolling 7-day window, much like single-sport runners often do.

While browsing the Garmin Connect IQ Store, I noticed that almost every existing watch face focuses exclusively on standard daily metrics (steps, 24-hour calories burned, heart rate, weather) or only displays weekly running mileage. For a triathlete, checking the totals across all three disciplines requires either digging through multiple watch submenus or opening the Garmin Connect app on a smartphone every single time.

I wanted a tool that cut out those steps: a clean, readable watch face that shows the work done so far at a glance. Beyond the practical utility, there is a strong motivational aspect to it: watching the distance counters across the three disciplines climb day after day gives an immediate and tangible sense of satisfaction for your consistency during the toughest training blocks. So I built the watch face I wished existed.

### Technical Solution
The software queries the internal activity database stored on the watch directly via the `Toybox.UserProfile` API (`getUserActivityHistory()`), filtering sessions over a rolling 7-day window by official Garmin FIT sport type IDs (`FIT_SPORT_SWIMMING = 5`, `FIT_SPORT_CYCLING = 2`, `FIT_SPORT_RUNNING = 1`) and aggregating distances locally. In addition, an optional background service (`Toybox.Background` + `Toybox.Communications`) allows power users to sync weekly totals from a custom external JSON endpoint.

The user interface is engineered to maximize contrast and readability both under direct sunlight (transflective MIP displays) and on AMOLED panels, while keeping RAM and battery impact to a minimum.

### Built With
* **Language:** [Monkey C](https://developer.garmin.com/connect-iq/monkey-c/) (Garmin's proprietary object-oriented language)
* **Framework / SDK:** [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (`minApiLevel="4.0.0"`)
* **Build System:** Monkey C Compiler (`monkeyc`) and target management via `monkey.jungle`
* **Asset Pipeline:** Custom Python 1-bit BMFont generator (`generate_font.py` powered by `Pillow`) for ultra-low memory icon rendering

---

## Key Features

* **Multi-Disciplinary 7-Day Tracking (Swim / Bike / Run):** Automatic on-device calculation of rolling 7-day training volume for swimming, cycling, and running extracted from `UserProfile.getUserActivityHistory()`, with optional cloud JSON override.
* **Configurable Top Progress Arc:** Track your choice of Daily Steps, Body Battery, Device Battery, Daily Calories, Floors Climbed, or Daily Distance (km), complete with a dynamic progress bar and semantic icon.
* **3 Customizable Middle Data Slots:** Independently configure the Left, Center, and Right middle slots with automatic icon and semantic color adaptation.
* **3 Configurable Bottom Sport Rings:** Assign Swimming (Blue), Cycling (Green), Running (Red), Daily Steps (Yellow), or Daily Calories (Orange) to any of the three bottom rings.
* **Live Weather & Date Row:** Displays the current day/month alongside a dynamic weather condition icon and live temperature via `Toybox.Weather`.
* **AMOLED Burn-In Protection:** Implements `onEnterSleep()` and `onExitSleep()` power-state listeners with a minimalist, 4-minute periodic pixel-shifting clock (`drawBurnInSafeClock`) when Always-On Display mode is active on AMOLED watches.

---

## Architecture and Engineering Choices

Developing for embedded wearable devices like Garmin sportwatches involves strict constraints in terms of available RAM and CPU cycles. The following software engineering practices were implemented:

1. **Code-First 1-Bit Icon Font (`GarminIcons`):** Instead of loading multiple individual bitmap images into memory, `generate_font.py` compiles 16 custom $16\times 16$ pixel-art matrices (`'A'` through `'P'`) into a single 1-bit bitmap font (`garmin_icons.fnt` + `garmin_icons.png`). This allows the rendering engine to draw crisp, dynamically colored icons using standard `dc.drawText()` calls at a fraction of the memory footprint.
2. **Modular Separation of Concerns:** Business logic, sensor hardware queries, and UI rendering are strictly decoupled into dedicated modules (`SettingsManager`, `SensorProvider`, `WeatherProvider`, `DisciplineProvider`, and `WatchFaceTRIView`).
3. **Proportional Resolution Scaling (`scalePx`):** All layout coordinates and radii are calibrated on a $260\times 260$ reference canvas and dynamically scaled at runtime via `scalePx(refVal, actualDim)` using `dc.getWidth()` and `dc.getHeight()`, supporting round MIP and compact/medium AMOLED displays seamlessly.
4. **Defensive Hardware & API Checks:** Every sensor and subsystem query is guarded by runtime `has` checks (e.g., `Toybox has :SensorHistory`, `Toybox has :Weather`, `devSettings has :requiresBurnInProtection`) and `try/catch` blocks to guarantee crash-free execution across different watch firmwares.
5. **Automated Unit Testing:** Includes a `RunNoEvil` unit test suite (`WatchFaceTRITests.mc`) validating 12h/24h time formatting, progress ratio clamping, and FIT sport type matching logic.

---

## Getting Started

### User Installation
1. **Via Connect IQ Store (Recommended):** Search for **Triathlon WatchFace** on the Garmin Connect IQ Store app and tap *Install*.
2. **Manual Installation (Sideloading):**
   * Connect your Garmin watch to your computer via USB cable.
   * Copy the compiled `.prg` file into the `/GARMIN/APPS/` folder on the watch's internal storage.
   * Disconnect the device: the watch face will be immediately available in the watch's *Watch Face* menu.

### Building from Source (Developers)
1. Clone this repository locally:
   ```sh
   git clone https://github.com/emagatti23/WatchFaceTRI.git
   cd WatchFaceTRI
   ```
2. Generate a developer signing key (if you don't already have one):
   ```sh
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
3. Compile the project for a target device (e.g., `fr255` or `fr165`) using the `monkeyc` compiler (or via the `Monkey C: Build for Device` command in VS Code):
   ```sh
   monkeyc -d fr255 -f monkey.jungle -o bin/WatchFaceTRI.prg -y /path/to/developer_key.der -w
   ```
4. Launch the Connect IQ simulator and run the executable (or run unit tests with `-t`):
   ```sh
   connectiq &
   monkeydo bin/WatchFaceTRI.prg fr255
   ```

### Generating the Custom Icon Font
If you wish to modify existing pixel-art icons or add new glyphs in `generate_font.py`, regenerate the bitmap font resources with:
```sh
pip install Pillow
python generate_font.py
```

---

## Usage and Configuration

Once installed, you can customize the watch face layout in real time via the **Garmin Connect IQ** smartphone app or **Garmin Express**:

1. Open the Connect IQ app, go to *My Device* -> *My Watch Faces*, and select **Triathlon WatchFace**.
2. Tap **Settings** to configure:
   * **Time Format:** `Device Default (Auto)`, `Force 24-Hour`, or `Force 12-Hour`.
   * **Top Progress Bar & Metric:** Choose between *Daily Steps*, *Body Battery (%)*, *Device Battery (%)*, *Daily Calories (kcal)*, *Floors Climbed*, or *Daily Distance (km)*.
   * **Middle Row (Left, Center, Right Slots):** Independently assign *Floors Climbed*, *Daily Steps*, *Heart Rate (bpm)*, *Body Battery (%)*, *Daily Calories (kcal)*, *Device Battery (%)*, or *Daily Distance (km)*.
   * **Bottom Rings (Left, Center, Right Sport):** Independently assign *Swimming (Blue)*, *Cycling (Green)*, *Running (Red)*, *Daily Steps (Yellow)*, or *Daily Calories (Orange)*.
   * **Custom Weekly Sync API URL (Optional):** Leave blank to use native on-device Garmin activity history, or provide a custom JSON endpoint returning `{"swim": 3.8, "bike": 120.0, "run": 24.5}`.
3. Save your settings: the watch face will immediately redraw with your new configuration.

---

## Supported Devices

The watch face supports 27 round MIP and compact/medium AMOLED Garmin smartwatches (Connect IQ API Level 4.0.0+):

* **Forerunner Series:** Forerunner 165 / 165 Music, Forerunner 255 / 255 Music / 255S / 255S Music, Forerunner 265S, Forerunner 955
* **Fēnix & Enduro Series:** Fēnix 7 / 7S / 7X (Standard, Pro, No-WiFi), Fēnix 8 Solar (47mm / 51mm), Fēnix E, Enduro 3, Enduro 4
* **Venu & Vívoactive Series:** Venu 2S, Venu 3S, Vívoactive 5, Vívoactive 6
* **Instinct & Approach Series:** Instinct 3 Solar (45mm), Approach S50

---

## Repository Structure

```text
├── generate_font.py                         # 1-bit BMFont generator for custom icons ('A'..'P')
├── manifest.xml                             # Device targets, app ID & permissions
├── monkey.jungle                            # Build configuration
├── README.md                                # Project documentation
├── resources/
│   ├── drawables/                           # Launcher icon & preview assets
│   ├── fonts/                               # Custom GarminIcons bitmap font (.fnt + .png)
│   ├── settings/
│   │   ├── properties.xml                   # Default configuration values
│   │   └── settings.xml                     # Garmin Connect IQ user settings schema
│   └── strings/
│       └── strings.xml                      # UI and settings localization strings
└── source/
    ├── WatchFaceTRIApp.mc                   # Application entry point & settings listener
    ├── services/
    │   └── WatchFaceTRIBgService.mc         # Optional background JSON sync service
    ├── providers/
    │   ├── SettingsManager.mc               # Type-safe configuration & time formatting
    │   ├── SensorProvider.mc                # Health/system metrics extraction & normalization
    │   ├── WeatherProvider.mc               # Weather condition mapping ('H'..'N')
    │   └── DisciplineProvider.mc            # Multi-sport ring data & 7-day history aggregation
    ├── views/
    │   └── WatchFaceTRIView.mc              # Proportional UI rendering & AMOLED burn-in protection
    └── tests/
        └── WatchFaceTRITests.mc             # RunNoEvil unit test suite
```

---

## Contributing

Any contribution, memory optimization suggestion, or bug report on specific watch models is welcome:
1. Fork the project.
2. Create a dedicated branch for your changes (`git checkout -b feature/NewFeature`).
3. Commit your changes, making sure the code compiles without warnings and passes unit tests (`git commit -m 'Add support for new metric'`).
4. Push to your branch (`git push origin feature/NewFeature`).
5. Open a Pull Request describing the changes in detail and the devices tested.

---

## License

Distributed under the MIT License. See the `LICENSE` file for more information.