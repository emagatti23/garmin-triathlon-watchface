import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Primary Watch Face View.
//! Renders all UI components using resolution-independent proportional coordinates
//! calibrated to match the original 260x260 layout geometry pixel-for-pixel.
class WatchFaceTRIView extends WatchUi.WatchFace {

    private var mIconFont as FontResource?;
    private var mIsSleepMode as Boolean = false;
    private var mRequiresBurnIn as Boolean = false;

    //! Constructor. Loads the custom 1-bit icon font resource and checks display properties.
    public function initialize() {
        WatchFace.initialize();
        if (Rez has :Fonts && Rez.Fonts has :GarminIcons) {
            mIconFont = WatchUi.loadResource(Rez.Fonts.GarminIcons) as FontResource;
        }
        var devSettings = System.getDeviceSettings();
        if (devSettings != null && (devSettings has :requiresBurnInProtection)) {
            mRequiresBurnIn = (devSettings.requiresBurnInProtection == true);
        }
    }

    //! Invoked when the watch enters low-power (Always-On) mode.
    public function onEnterSleep() as Void {
        mIsSleepMode = true;
        WatchUi.requestUpdate();
    }

    //! Invoked when the watch wakes up to full-power mode.
    public function onExitSleep() as Void {
        mIsSleepMode = false;
        WatchUi.requestUpdate();
    }

    //! Main rendering callback invoked by the Connect IQ display pipeline.
    //! @param dc The drawing context used to render graphics on screen.
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // =====================================================================
        // 0. AMOLED ALWAYS-ON DISPLAY (BURN-IN PROTECTION MODE)
        // =====================================================================
        if (mIsSleepMode && mRequiresBurnIn) {
            drawBurnInSafeClock(dc, cx, cy, h);
            return;
        }

        // =====================================================================
        // 1. TOP PROGRESS BAR & METRIC (Configurable via TopBarMetric setting)
        // =====================================================================
        var topMetricId = SettingsManager.getNumberProperty("TopBarMetric", SettingsManager.METRIC_STEPS);
        var topData = SensorProvider.getMetricData(topMetricId);
        drawTopProgressArc(dc, cx, cy, w, h, topData);

        // =====================================================================
        // 2. SECOND ROW: 3 CONFIGURABLE DATA SLOTS (Left, Center, Right)
        // =====================================================================
        var row2Y = scalePx(48, h);
        var leftMetricId   = SettingsManager.getNumberProperty("SlotLeftMetric",   SettingsManager.METRIC_FLOORS);
        var centerMetricId = SettingsManager.getNumberProperty("SlotCenterMetric", SettingsManager.METRIC_HEART_RATE);
        var rightMetricId  = SettingsManager.getNumberProperty("SlotRightMetric",  SettingsManager.METRIC_BODY_BATTERY);

        drawSlotLeftAligned(dc, scalePx(48, w), row2Y, SensorProvider.getMetricData(leftMetricId));
        drawSlotCentered(dc, cx, row2Y, SensorProvider.getMetricData(centerMetricId));
        drawSlotLeftAligned(dc, scalePx(176, w), row2Y, SensorProvider.getMetricData(rightMetricId));

        // =====================================================================
        // 3. THIRD ROW: DATE + DYNAMIC WEATHER ICON + TEMPERATURE
        // =====================================================================
        var row3Y = scalePx(71, h);
        drawDateAndWeatherRow(dc, cx, row3Y);

        // =====================================================================
        // 4. MAIN CLOCK DISPLAY (Supports Auto, 24h, and 12h formats)
        // =====================================================================
        var clock = System.getClockTime();
        var timeStr = SettingsManager.formatTime(clock.hour, clock.min);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, scalePx(82, h), Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // =====================================================================
        // 5. CONFIGURABLE DISCIPLINE RINGS (Left, Center, Right)
        // =====================================================================
        var ringY = scalePx(202, h);
        var leftSportId   = SettingsManager.getNumberProperty("RingLeftSport",   SettingsManager.SPORT_SWIM);
        var centerSportId = SettingsManager.getNumberProperty("RingCenterSport", SettingsManager.SPORT_BIKE);
        var rightSportId  = SettingsManager.getNumberProperty("RingRightSport",  SettingsManager.SPORT_RUN);

        var leftRing   = DisciplineProvider.getRingAttributes(leftSportId);
        var centerRing = DisciplineProvider.getRingAttributes(centerSportId);
        var rightRing  = DisciplineProvider.getRingAttributes(rightSportId);

        drawTriathlonRing(dc, scalePx(60, w),  ringY, scalePx(21, w), leftRing[0],   leftRing[1],   leftRing[2]);
        drawTriathlonRing(dc, cx,              ringY, scalePx(25, w), centerRing[0], centerRing[1], centerRing[2]);
        drawTriathlonRing(dc, scalePx(200, w), ringY, scalePx(21, w), rightRing[0],  rightRing[1],  rightRing[2]);

        // =====================================================================
        // 6. BOTTOM DEVICE BATTERY INDICATOR
        // =====================================================================
        drawBottomBatteryFooter(dc, cx, scalePx(245, h));
    }

    //! Converts a coordinate from the 260x260 reference canvas to the active screen dimension.
    //! @param refVal Coordinate or radius on a 260px reference display.
    //! @param actualDim Actual width or height of the current device display.
    //! @return Proportionally scaled pixel value.
    private function scalePx(refVal as Number, actualDim as Number) as Number {
        return ((refVal * actualDim) + 130) / 260;
    }

    //! Renders the top circular progress bar, dynamic icon, and value string.
    private function drawTopProgressArc(
        dc as Dc,
        cx as Number,
        cy as Number,
        w as Number,
        h as Number,
        metricData as [String, Float, String, Number]
    ) as Void {
        var valStr   = metricData[0];
        var progress = metricData[1];
        var iconChar = metricData[2];
        var iconCol  = metricData[3];

        var arcR = (w / 2) - scalePx(6, w);
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, 135, 45);

        if (progress > 0.0) {
            var currentAngle = 135.0 - (90.0 * progress);
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, 135, currentAngle.toNumber());
        }

        var topY = scalePx(16, h);
        var textW = dc.getTextDimensions(valStr, Graphics.FONT_XTINY)[0];
        var totalW = 16 + 4 + textW;
        var startX = cx - (totalW / 2);

        if (mIconFont != null) {
            dc.setColor(iconCol, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startX, topY, mIconFont, iconChar, Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 20, topY - 1, Graphics.FONT_XTINY, valStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Renders a left-anchored metric slot (icon + text).
    private function drawSlotLeftAligned(
        dc as Dc,
        startX as Number,
        y as Number,
        metricData as [String, Float, String, Number]
    ) as Void {
        var valStr   = metricData[0];
        var iconChar = metricData[2];
        var iconCol  = metricData[3];

        if (mIconFont != null) {
            dc.setColor(iconCol, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startX, y, mIconFont, iconChar, Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 18, y - 1, Graphics.FONT_XTINY, valStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Renders a horizontally centered metric slot (icon + text).
    private function drawSlotCentered(
        dc as Dc,
        centerX as Number,
        y as Number,
        metricData as [String, Float, String, Number]
    ) as Void {
        var valStr   = metricData[0];
        var iconChar = metricData[2];
        var iconCol  = metricData[3];

        var textW = dc.getTextDimensions(valStr, Graphics.FONT_XTINY)[0];
        var startX = centerX - ((16 + 4 + textW) / 2);

        if (mIconFont != null) {
            dc.setColor(iconCol, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startX, y, mIconFont, iconChar, Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 20, y - 1, Graphics.FONT_XTINY, valStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Renders the centered date and live weather condition row.
    private function drawDateAndWeatherRow(dc as Dc, cx as Number, rowY as Number) as Void {
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$ $3$", [
            dateInfo.day_of_week.toUpper(),
            dateInfo.day,
            dateInfo.month.toUpper()
        ]);

        var weatherData = WeatherProvider.getCurrentWeather();
        var weatherChar = weatherData[0];
        var tempStr     = weatherData[1];

        var dateW = dc.getTextDimensions(dateStr, Graphics.FONT_XTINY)[0];
        var tempW = dc.getTextDimensions(tempStr, Graphics.FONT_XTINY)[0];
        var blockTotalW = dateW + 8 + 16 + 4 + tempW;
        var blockStartX = cx - (blockTotalW / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockStartX, rowY - 1, Graphics.FONT_XTINY, dateStr, Graphics.TEXT_JUSTIFY_LEFT);

        var weatherIconX = blockStartX + dateW + 8;
        if (mIconFont != null) {
            dc.drawText(weatherIconX, rowY, mIconFont, weatherChar, Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.drawText(weatherIconX + 20, rowY - 1, Graphics.FONT_XTINY, tempStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Renders a single sport ring with an open top gap housing its sport icon and central metric value.
    private function drawTriathlonRing(
        dc as Dc,
        cx as Number,
        cy as Number,
        r as Number,
        color as Number,
        iconChar as String,
        valueStr as String
    ) as Void {
        dc.setPenWidth(3);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 60, 120);

        if (mIconFont != null) {
            var iconY = cy - r - 8;
            dc.drawText(cx, iconY, mIconFont, iconChar, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 8, Graphics.FONT_XTINY, valueStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Renders the bottom battery icon and percentage label aligned horizontally.
    private function drawBottomBatteryFooter(dc as Dc, cx as Number, battY as Number) as Void {
        var battLevel = SensorProvider.getBatteryLevel();
        var battStr = battLevel.toString() + "%";
        var textDim = dc.getTextDimensions(battStr, Graphics.FONT_XTINY);
        var battTextW = textDim[0];
        var battTextH = textDim[1];

        var battBoxW = 22;
        var spacing = 6;
        var totalBattW = battBoxW + spacing + battTextW;
        var battStartX = cx - (totalBattW / 2);

        drawGarminBatteryAligned(dc, battStartX, battY, battBoxW, 10, battLevel);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            battStartX + battBoxW + spacing,
            battY - (battTextH / 2),
            Graphics.FONT_XTINY,
            battStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    //! Renders the graphical battery outline and dynamic level fill bar.
    private function drawGarminBatteryAligned(
        dc as Dc,
        x as Number,
        centerY as Number,
        w as Number,
        h as Number,
        percent as Number
    ) as Void {
        var topY = centerY - (h / 2);
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, topY, w - 2, h, 1);
        dc.fillRectangle(x + w - 2, centerY - 2, 2, 4);

        var innerMaxW = w - 6;
        var fillW = (innerMaxW * (percent / 100.0)).toNumber();
        if (fillW > 0) {
            dc.setColor((percent > 20) ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + 2, topY + 2, fillW, h - 4);
        }
    }

    //! Renders a minimalist, pixel-shifting clock for AMOLED low-power Always-On mode.
    //! Shifts coordinates on a 4-minute cycle to prevent static pixel burn-in.
    private function drawBurnInSafeClock(dc as Dc, cx as Number, cy as Number, h as Number) as Void {
        var clock = System.getClockTime();
        var timeStr = SettingsManager.formatTime(clock.hour, clock.min);

        // Pixel shifting (-4px / +4px) basato sul minuto corrente
        var shiftX = ((clock.min % 2) == 0) ? -4 : 4;
        var shiftY = (((clock.min / 2) % 2) == 0) ? -4 : 4;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx + shiftX,
            cy + shiftY,
            Graphics.FONT_NUMBER_MILD,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
