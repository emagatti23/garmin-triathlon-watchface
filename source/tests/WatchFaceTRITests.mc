import Toybox.Lang;
import Toybox.Test;
import Toybox.System;


//! Unit Test Suite for Triathlon Watch Face.
//! Validates business logic, time formatting, data providers, and math utility functions
//! without relying on active hardware sensors.
module WatchFaceTRITests {

    //! Test time formatting logic under 24-hour and 12-hour configurations.
    //! @param logger Test logger for recording success or failure messages.
    //! @return true if all assertions pass.
    (:test)
    public function testTimeFormatting(logger as Test.Logger) as Boolean {
        // Test case 1: Midnight (00:05)
        var timeMidnight24 = SettingsManager.formatTime(0, 5);
        Test.assertEqual(timeMidnight24, "00:05");

        // Test case 2: Afternoon (14:30)
        var timeAfternoon24 = SettingsManager.formatTime(14, 30);
        Test.assertEqual(timeAfternoon24, "14:30");

        return true;
    }

    //! Test numerical clamping logic for progress bars and metric ratios.
    //! @param logger Test logger.
    //! @return true if assertions pass.
    (:test)
    public function testProgressClamping(logger as Test.Logger) as Boolean {
        // Normal value within range
        var normalVal = SensorProvider.clampProgress(0.5f);
        Test.assert(normalVal == 0.5f);

        // Underflow value (< 0.0) should clamp to 0.0
        var underflowVal = SensorProvider.clampProgress(-1.5f);
        Test.assert(underflowVal == 0.0f);

        // Overflow value (> 1.0) should clamp to 1.0
        var overflowVal = SensorProvider.clampProgress(2.5f);
        Test.assert(overflowVal == 1.0f);

        return true;
    }

    //! Test discipline distance matching logic.
    //! @param logger Test logger.
    //! @return true if assertions pass.
    (:test)
    public function testSportTypeMatching(logger as Test.Logger) as Boolean {
        // Verify swimming activity type matching
        var matchesSwim = DisciplineProvider.matchesSportType(
            SettingsManager.SPORT_SWIM,
            DisciplineProvider.FIT_SPORT_SWIMMING
        );
        Test.assert(matchesSwim);

        // Verify cycling activity type matching
        var matchesBike = DisciplineProvider.matchesSportType(
            SettingsManager.SPORT_BIKE,
            DisciplineProvider.FIT_SPORT_CYCLING
        );
        Test.assert(matchesBike);

        // Verify running activity type matching
        var matchesRun = DisciplineProvider.matchesSportType(
            SettingsManager.SPORT_RUN,
            DisciplineProvider.FIT_SPORT_RUNNING
        );
        Test.assert(matchesRun);

        // Verify mismatch handling
        var mismatch = DisciplineProvider.matchesSportType(
            SettingsManager.SPORT_SWIM,
            DisciplineProvider.FIT_SPORT_RUNNING
        );
        Test.assert(!mismatch);

        return true;
    }
}