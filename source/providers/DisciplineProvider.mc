import Toybox.ActivityMonitor;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;

//! Data provider for the three bottom discipline rings.
//! Supports Swimming, Cycling, Running, Daily Steps, and Daily Calories.
//! Automatically aggregates last 7 days of activities from native Garmin UserProfile history,
//! while allowing external override via Application.Storage (if populated by the background service).
module DisciplineProvider {

    // Official Garmin FIT SDK Sport Type IDs (device-independent constants)
    const FIT_SPORT_RUNNING  = 1;
    const FIT_SPORT_CYCLING  = 2;
    const FIT_SPORT_SWIMMING = 5;

    //! Retrieves visual and metric attributes for a given ring discipline ID.
    //! @param sportId One of SettingsManager.SPORT_* constants.
    //! @return A 3-element tuple:
    //!         [0] ringColor      (Number) - Graphics.COLOR_* constant
    //!         [1] iconChar       (String) - Character in GarminIcons font
    //!         [2] formattedValue (String) - Formatted distance or volume string
    public function getRingAttributes(sportId as Number) as [Number, String, String] {
        if (sportId == SettingsManager.SPORT_SWIM) {
            var km = getDisciplineDistanceKm(SettingsManager.SPORT_SWIM, "weekly_swim_km");
            return [Graphics.COLOR_BLUE, "E", km.format("%.1f")];
        } else if (sportId == SettingsManager.SPORT_BIKE) {
            var km = getDisciplineDistanceKm(SettingsManager.SPORT_BIKE, "weekly_bike_km");
            return [Graphics.COLOR_DK_GREEN, "F", km.format("%.0f")];
        } else if (sportId == SettingsManager.SPORT_RUN) {
            var km = getDisciplineDistanceKm(SettingsManager.SPORT_RUN, "weekly_run_km");
            return [Graphics.COLOR_RED, "G", km.format("%.1f")];
        } else if (sportId == SettingsManager.SPORT_STEPS) {
            var actInfo = ActivityMonitor.getInfo();
            var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
            var stepStr = (steps >= 10000) ? ((steps / 1000.0).format("%.1f") + "k") : steps.toString();
            return [Graphics.COLOR_YELLOW, "A", stepStr];
        } else if (sportId == SettingsManager.SPORT_CALORIES) {
            var actInfo = ActivityMonitor.getInfo();
            var cals = (actInfo != null && actInfo.calories != null) ? actInfo.calories : 0;
            return [Graphics.COLOR_ORANGE, "O", cals.toString()];
        }
        return [Graphics.COLOR_BLUE, "E", "0.0"];
    }

    //! Resolves weekly distance (in km) for a triathlon discipline.
    //! Priority 1: External background sync value stored in Application.Storage.
    //! Priority 2: Native on-device calculation from UserProfile.getUserActivityHistory() over the last 7 days.
    //! @param sportId Discipline identifier.
    //! @param storageKey Key used in Application.Storage.
    //! @return Weekly distance in kilometers.
    public function getDisciplineDistanceKm(sportId as Number, storageKey as String) as Float {
        var stored = Storage.getValue(storageKey);
        if (stored instanceof Float || stored instanceof Number) {
            return stored.toFloat();
        }
        return calculateNativeWeeklyKm(sportId);
    }

    //! Iterates through the device's native activity history to sum distance over the rolling 7-day window.
    //! @param sportId Discipline identifier (SPORT_SWIM, SPORT_BIKE, SPORT_RUN).
    //! @return Total distance in kilometers as a Float.
    public function calculateNativeWeeklyKm(sportId as Number) as Float {
        var iter = UserProfile.getUserActivityHistory();
        if (iter == null) {
            return 0.0;
        }

        var totalMeters = 0.0;
        var nowVal = Time.now().value();
        var sevenDaysSec = 7 * 86400;

        var sample = iter.next();
        while (sample != null) {
            var startTime = sample.startTime;
            var distance = sample.distance;
            var actType = sample.type;

            if (startTime != null && distance != null && actType != null) {
                var ageSec = nowVal - startTime.value();
                if (ageSec >= 0 && ageSec <= sevenDaysSec) {
                    if (matchesSportType(sportId, actType as Number)) {
                        totalMeters += distance.toFloat();
                    }
                }
            }
            sample = iter.next();
        }

        return totalMeters / 1000.0;
    }

    //! Checks whether a Garmin FIT activity type constant matches the requested triathlon discipline.
    public function matchesSportType(sportId as Number, activityType as Number) as Boolean {
        if (sportId == SettingsManager.SPORT_SWIM) {
            return (activityType == FIT_SPORT_SWIMMING);
        } else if (sportId == SettingsManager.SPORT_BIKE) {
            return (activityType == FIT_SPORT_CYCLING);
        } else if (sportId == SettingsManager.SPORT_RUN) {
            return (activityType == FIT_SPORT_RUNNING);
        }
        return false;
    }
}