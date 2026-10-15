import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;

//! Data provider for device health, activity, and system sensors.
//! Decouples sensor hardware APIs and null-safety checks from UI rendering.
module SensorProvider {

    //! Retrieves normalized data for any user-selectable metric.
    //! @param metricId One of SettingsManager.METRIC_* constants.
    //! @return A 4-element tuple:
    //!         [0] displayValue (String)  - Formatted metric string (e.g., "8420", "62", "85%")
    //!         [1] progress     (Float)   - Normalized [0.0 .. 1.0] ratio for progress bars
    //!         [2] iconChar     (String)  - Character mapped in GarminIcons font ('A'..'P')
    //!         [3] iconColor    (Number)  - Semantic Graphics.COLOR_* constant
    public function getMetricData(metricId as Number) as [String, Float, String, Number] {
        var actInfo = ActivityMonitor.getInfo();

        switch (metricId) {
            case SettingsManager.METRIC_FLOORS:
                return getFloorsData(actInfo);

            case SettingsManager.METRIC_HEART_RATE:
                return getHeartRateData();

            case SettingsManager.METRIC_BODY_BATTERY:
                return getBodyBatteryData();

            case SettingsManager.METRIC_CALORIES:
                return getCaloriesData(actInfo);

            case SettingsManager.METRIC_DEVICE_BATTERY:
                return getDeviceBatteryData();

            case SettingsManager.METRIC_DAILY_DIST_KM:
                return getDailyDistanceData(actInfo);

            case SettingsManager.METRIC_STEPS:
            default:
                return getStepsData(actInfo);
        }
    }

    //! Extracts daily steps and step goal progress.
    public function getStepsData(actInfo as ActivityMonitor.Info?) as [String, Float, String, Number] {
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        var goal = (actInfo != null && actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;
        var ratio = clampProgress(steps.toFloat() / goal.toFloat());
        return [steps.toString(), ratio, "A", Graphics.COLOR_BLUE];
    }

    //! Extracts daily floors climbed and floor goal progress.
    public function getFloorsData(actInfo as ActivityMonitor.Info?) as [String, Float, String, Number] {
        var floors = 0;
        var goal = 10;
        if (actInfo != null) {
            if (actInfo has :floorsClimbed && actInfo.floorsClimbed != null) {
                floors = actInfo.floorsClimbed;
            }
            if (actInfo has :floorsClimbedGoal && actInfo.floorsClimbedGoal != null && actInfo.floorsClimbedGoal > 0) {
                goal = actInfo.floorsClimbedGoal;
            }
        }
        var ratio = clampProgress(floors.toFloat() / goal.toFloat());
        return [floors.toString(), ratio, "B", Graphics.COLOR_YELLOW];
    }

    //! Extracts current heart rate with fallback to recent heart rate history.
    public function getHeartRateData() as [String, Float, String, Number] {
        var hr = 0;
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            hr = act.currentHeartRate;
        } else if (ActivityMonitor has :getHeartRateHistory) {
            var hrIter = ActivityMonitor.getHeartRateHistory(1, true);
            if (hrIter != null) {
                var sample = hrIter.next();
                if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE && sample.heartRate != null) {
                    hr = sample.heartRate;
                }
            }
        }

        var hrStr = (hr > 0) ? hr.toString() : "--";
        // Normalize HR between 40 bpm (0.0) and 190 bpm (1.0) for bar visualization
        var ratio = (hr > 40) ? clampProgress((hr - 40).toFloat() / 150.0) : 0.0;
        return [hrStr, ratio, "C", Graphics.COLOR_RED];
    }

    //! Extracts Garmin Body Battery level (0..100).
    public function getBodyBatteryData() as [String, Float, String, Number] {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
            var bbIter = SensorHistory.getBodyBatteryHistory({:period => 1});
            if (bbIter != null) {
                var sample = bbIter.next();
                if (sample != null && sample.data != null) {
                    var val = sample.data.toNumber();
                    var ratio = clampProgress(val.toFloat() / 100.0);
                    return [val.toString(), ratio, "D", Graphics.COLOR_BLUE];
                }
            }
        }
        return ["--", 0.0, "D", Graphics.COLOR_BLUE];
    }

    //! Extracts daily burned kilocalories.
    public function getCaloriesData(actInfo as ActivityMonitor.Info?) as [String, Float, String, Number] {
        var cals = (actInfo != null && actInfo.calories != null) ? actInfo.calories : 0;
        var ratio = clampProgress(cals.toFloat() / 2500.0);
        return [cals.toString(), ratio, "O", Graphics.COLOR_ORANGE];
    }

    //! Extracts system battery percentage.
    public function getDeviceBatteryData() as [String, Float, String, Number] {
        var level = getBatteryLevel();
        var ratio = clampProgress(level.toFloat() / 100.0);
        var color = (level > 20) ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_RED;
        return [level.toString() + "%", ratio, "P", color];
    }

    //! Extracts daily distance in kilometers from ActivityMonitor (centimeters -> kilometers).
    public function getDailyDistanceData(actInfo as ActivityMonitor.Info?) as [String, Float, String, Number] {
        var distCm = (actInfo != null && actInfo.distance != null) ? actInfo.distance : 0;
        var distKm = distCm.toFloat() / 100000.0;
        var ratio = clampProgress(distKm / 10.0);
        return [distKm.format("%.1f"), ratio, "G", Graphics.COLOR_DK_GREEN];
    }

    //! Helper returning integer system battery percentage (0..100).
    public function getBatteryLevel() as Number {
        var sysStats = System.getSystemStats();
        return (sysStats != null && sysStats.battery != null) ? sysStats.battery.toNumber() : 0;
    }

    //! Clamps a floating-point progress ratio to the [0.0, 1.0] interval.
    public function clampProgress(val as Float) as Float {
        if (val < 0.0) { return 0.0; }
        if (val > 1.0) { return 1.0; }
        return val;
    }
}
