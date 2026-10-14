import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.SensorHistory;
import Toybox.Application.Storage;

class WatchFaceTRIView extends WatchUi.WatchFace {

    private var mIconFont as FontResource?;

    function initialize() {
        WatchFace.initialize();
        if (Rez has :Fonts && Rez.Fonts has :GarminIcons) {
            mIconFont = WatchUi.loadResource(Rez.Fonts.GarminIcons) as FontResource;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = 130;
        var cy = 130;

        var actInfo = ActivityMonitor.getInfo();
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        var stepGoal = (actInfo != null && actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;

        // ==========================================
        // 1. ARCO SUPERIORE PROGRESSO PASSI
        // ==========================================
        var arcR = 124;
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, 135, 45);

        var stepProgress = steps.toFloat() / stepGoal.toFloat();
        if (stepProgress > 1.0) { stepProgress = 1.0; }
        if (stepProgress > 0.0) {
            var currentAngle = 135.0 - (90.0 * stepProgress);
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, 135, currentAngle.toNumber());
        }

        // ==========================================
        // 2. ICONA PASSI ('A') + NUMERO PASSI
        // ==========================================
        var stepsY = 16;
        var stepStr = steps.toString();
        var stepTextW = dc.getTextDimensions(stepStr, Graphics.FONT_XTINY)[0];
        var totalStepW = 16 + 4 + stepTextW;
        var startStepX = cx - (totalStepW / 2);

        if (mIconFont != null) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startStepX, stepsY, mIconFont, "A", Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startStepX + 20, stepsY - 1, Graphics.FONT_XTINY, stepStr, Graphics.TEXT_JUSTIFY_LEFT);

        
        // ==========================================
        // 3. SECONDA RIGA: PIANI ('B'), HR ('C'), BODY BATTERY ('D')
        // Abbassata a y = 48 per non toccare le code dell'arco
        // ==========================================
        var row2Y = 48;

        // Piani saliti ('B' - Giallo/Arancio)
        var floors = (actInfo != null && actInfo.floorsClimbed != null) ? actInfo.floorsClimbed : 0;
        if (mIconFont != null) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(48, row2Y, mIconFont, "B", Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(66, row2Y - 1, Graphics.FONT_XTINY, floors.toString(), Graphics.TEXT_JUSTIFY_LEFT);

        // Battito cardiaco ('C' - Rosso)
        var hrStr = getHeartRate();
        var hrTextW = dc.getTextDimensions(hrStr, Graphics.FONT_XTINY)[0];
        var hrStartX = cx - ((16 + 4 + hrTextW) / 2);
        if (mIconFont != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hrStartX, row2Y, mIconFont, "C", Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hrStartX + 20, row2Y - 1, Graphics.FONT_XTINY, hrStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Body Battery ('D' - Blu/Azzurro)
        var bbVal = getBodyBattery();
        if (mIconFont != null) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(176, row2Y, mIconFont, "D", Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(194, row2Y - 1, Graphics.FONT_XTINY, bbVal, Graphics.TEXT_JUSTIFY_LEFT);

        // ==========================================
        // 4. TERZA RIGA: DATA + METEO DINAMICO ('H'..'N') + TEMP
        // Abbassata a y = 71
        // ==========================================
        var row3Y = 71;
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$ $3$", [
            dateInfo.day_of_week.toUpper(),
            dateInfo.day,
            dateInfo.month.toUpper()
        ]);
        
        var weatherData = getWeather(); // [charIcon, tempStr]
        var weatherChar = weatherData[0] as String;
        var tempStr = weatherData[1] as String;

        var dateW = dc.getTextDimensions(dateStr, Graphics.FONT_XTINY)[0];
        var tempW = dc.getTextDimensions(tempStr, Graphics.FONT_XTINY)[0];
        var blockTotalW = dateW + 8 + 16 + 4 + tempW;
        var blockStartX = cx - (blockTotalW / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockStartX, row3Y - 1, Graphics.FONT_XTINY, dateStr, Graphics.TEXT_JUSTIFY_LEFT);

        var weatherIconX = blockStartX + dateW + 8;
        if (mIconFont != null) {
            dc.drawText(weatherIconX, row3Y, mIconFont, weatherChar, Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.drawText(weatherIconX + 20, row3Y - 1, Graphics.FONT_XTINY, tempStr, Graphics.TEXT_JUSTIFY_LEFT);

        // ==========================================
        // 5. ORA IN GRANDE (y = 82)
        // ==========================================
        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [
            clock.hour.format("%02d"),
            clock.min.format("%02d")
        ]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 82, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // ==========================================
        // 6. I TRE CERCHI TRIATHLON ('E' Swim, 'F' Bike, 'G' Run)
        // ==========================================
        var sKm = Storage.getValue("weekly_swim_km");
        var bKm = Storage.getValue("weekly_bike_km");
        var rKm = Storage.getValue("weekly_run_km");

        var swimVal = (sKm != null) ? (sKm as Float).format("%.1f") : "3.8";
        var bikeVal = (bKm != null) ? (bKm as Float).format("%.0f") : "120";
        var runVal  = (rKm != null)  ? (rKm as Float).format("%.1f")  : "24.5";

        var ringY = 202;

        drawTriathlonRing(dc, 60,  ringY, 21, Graphics.COLOR_BLUE,     "E", swimVal);
        drawTriathlonRing(dc, 130, ringY, 25, Graphics.COLOR_DK_GREEN, "F", bikeVal);
        drawTriathlonRing(dc, 200, ringY, 21, Graphics.COLOR_RED,      "G", runVal);

        // ==========================================
        // 7. BATTERIA DISPOSITIVO ALLINEATA AL TESTO (y = 245)
        // ==========================================
        var battY = 245;
        var sysStats = System.getSystemStats();
        var battLevel = (sysStats != null) ? sysStats.battery.toNumber() : 0;
        
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
        dc.drawText(battStartX + battBoxW + spacing, battY - (battTextH / 2), Graphics.FONT_XTINY, battStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ========================================================
    // METEO DINAMICO E SENSORI
    // ========================================================

    private function getWeather() as [String, String] {
        if ((Toybox has :Weather) && (Weather has :getCurrentConditions)) {
            var cond = Weather.getCurrentConditions();
            if (cond != null) {
                var tempStr = (cond.temperature != null) ? (cond.temperature.toNumber().toString() + "°") : "--°";
                var iconChar = mapWeatherConditionToChar(cond.condition);
                return [iconChar, tempStr];
            }
        }
        return ["I", "--°"]; // Default: parzialmente nuvoloso
    }

    private function mapWeatherConditionToChar(code as Number?) as String {
        if (code == null) { return "I"; }
        switch (code) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_MOSTLY_CLEAR:
                return "H"; // Sole

            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
                return "I"; // Sole + Nuvola

            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
                return "J"; // Nuvoloso

            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
                return "K"; // Pioggia

            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
            case Weather.CONDITION_TROPICAL_STORM:
            case Weather.CONDITION_HURRICANE:
            case Weather.CONDITION_TORNADO:
                return "L"; // Temporale

            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_ICE_SNOW:
            case Weather.CONDITION_WINTRY_MIX:
            case Weather.CONDITION_HAIL:
                return "M"; // Neve / Ghiaccio

            case Weather.CONDITION_FOG:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_HAZE:
            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_DUST:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_SAND:
                return "N"; // Nebbia / Vento

            default:
                return "I";
        }
    }

    private function getHeartRate() as String {
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            return act.currentHeartRate.toString();
        }
        var hrIter = ActivityMonitor.getHeartRateHistory(1, true);
        var sample = hrIter.next();
        if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
            return sample.heartRate.toString();
        }
        return "--";
    }

    private function getBodyBattery() as String {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
            var bbIter = SensorHistory.getBodyBatteryHistory({:period => 1});
            var sample = bbIter.next();
            if (sample != null && sample.data != null) {
                return sample.data.toNumber().toString();
            }
        }
        return "--";
    }

    // ========================================================
    // ANELLI TRIATHLON & BATTERIA
    // ========================================================

    private function drawTriathlonRing(dc as Dc, cx as Number, cy as Number, r as Number, color as Number, iconChar as String, kmStr as String) as Void {
        dc.setPenWidth(3);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 60, 120);

        if (mIconFont != null) {
            var iconY = cy - r - 8;
            dc.drawText(cx, iconY, mIconFont, iconChar, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 8, Graphics.FONT_XTINY, kmStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawGarminBatteryAligned(dc as Dc, x as Number, centerY as Number, w as Number, h as Number, percent as Number) as Void {
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
}