import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

//! Centralized configuration manager.
//! Provides type-safe access to user preferences defined in properties.xml and settings.xml,
//! along with enumerations for metrics, sports, and time formats.
module SettingsManager {

    // Time Format Options
    enum {
        TIME_FORMAT_AUTO = 0,
        TIME_FORMAT_24H  = 1,
        TIME_FORMAT_12H  = 2
    }

    // Customizable Health & System Metrics
    enum {
        METRIC_STEPS          = 0,
        METRIC_FLOORS         = 1,
        METRIC_HEART_RATE     = 2,
        METRIC_BODY_BATTERY   = 3,
        METRIC_CALORIES       = 4,
        METRIC_DEVICE_BATTERY = 5,
        METRIC_DAILY_DIST_KM  = 6
    }

    // Customizable Ring Disciplines
    enum {
        SPORT_SWIM     = 0,
        SPORT_BIKE     = 1,
        SPORT_RUN      = 2,
        SPORT_STEPS    = 3,
        SPORT_CALORIES = 4
    }

    //! Safely retrieves an integer property from Application.Properties.
    //! @param key Property identifier string.
    //! @param defaultVal Fallback value if property is missing or invalid.
    //! @return The configured integer value.
    public function getNumberProperty(key as String, defaultVal as Number) as Number {
        try {
            var val = Application.Properties.getValue(key);
            if (val instanceof Number) {
                return val;
            } else if (val != null && val has :toNumber) {
                var num = val.toNumber();
                return (num != null) ? num : defaultVal;
            }
        } catch (ex) {
            // Fallback silently on property access error
        }
        return defaultVal;
    }

    //! Determines whether the watch face should render time in 24-hour format
    //! based on user override or device system settings.
    //! @return true for 24-hour format, false for 12-hour format.
    public function is24HourFormat() as Boolean {
        var mode = getNumberProperty("TimeFormat", TIME_FORMAT_AUTO);
        if (mode == TIME_FORMAT_24H) {
            return true;
        } else if (mode == TIME_FORMAT_12H) {
            return false;
        }
        var devSettings = System.getDeviceSettings();
        return (devSettings != null && devSettings.is24Hour != null) ? devSettings.is24Hour : true;
    }

    //! Formats the given hour and minute according to the active 12h/24h preference.
    //! @param hour Hour of day (0..23).
    //! @param min Minute of hour (0..59).
    //! @return Formatted time string (e.g., "14:05" or "02:05").
    public function formatTime(hour as Number, min as Number) as String {
        var displayHour = hour;
        if (!is24HourFormat()) {
            displayHour = hour % 12;
            if (displayHour == 0) {
                displayHour = 12;
            }
        }
        return Lang.format("$1$:$2$", [
            displayHour.format("%02d"),
            min.format("%02d")
        ]);
    }
}
