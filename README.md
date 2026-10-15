# Triathlon WatchFace for Garmin Connect IQ

A lightweight, customizable, multi-sport watch face for Garmin smartwatches built with **Monkey C** (Connect IQ SDK 4.0+). Designed with software engineering best practices, modular separation of concerns, and a custom 1-bit pixel-art icon font for ultra-low memory consumption.

## Features

- **Customizable Time Format**: Follow device system settings automatically, or force **12-hour** / **24-hour** display.
- **Configurable Top Progress Arc**: Track your choice of Daily Steps, Body Battery, Device Battery, Daily Calories, Floors Climbed, or Daily Distance, complete with dynamic semantic icons.
- **3 Customizable Data Slots**: Independently configure the Left, Center, and Right middle slots with automatic icon and color adaptation.
- **3 Configurable Sport Rings**: Assign Swimming, Cycling, Running, Steps, or Calories to any of the three bottom rings.
- **Native + Cloud Activity Aggregation**: Automatically computes rolling 7-day volume from on-device Garmin activity history (`UserProfile`), with optional background JSON endpoint sync.
- **Resolution-Independent Geometry**: Proportional coordinate scaling supports 70+ Garmin MIP and AMOLED devices.

## Project Architecture

    ├── generate_font.py                         # 1-bit BMFont generator for custom icons ('A'..'P')
    ├── manifest.xml                             # Device targets & permissions
    ├── monkey.jungle                            # Build configuration
    ├── resources/
    │   ├── drawables/                           # Launcher icon assets
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
        │   ├── WeatherProvider.mc               # Weather condition mapping
        │   └── DisciplineProvider.mc            # Multi-sport ring data & 7-day history aggregation
        └── views/
            └── WatchFaceTRIView.mc              # Proportional UI rendering engine

## Building the Icon Font

If you modify or add icons in `generate_font.py`, regenerate the bitmap font resources with:

    pip install Pillow
    python generate_font.py
