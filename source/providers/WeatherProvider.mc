import Toybox.Lang;
import Toybox.Weather;

//! Data provider for current meteorological conditions.
//! Maps Garmin Weather condition codes to custom 1-bit icon font characters ('H'..'N').
module WeatherProvider {

    //! Retrieves the current weather icon character and formatted temperature string.
    //! @return A 2-element tuple: [iconChar (String), temperatureString (String)]
    public function getCurrentWeather() as [String, String] {
        if ((Toybox has :Weather) && (Weather has :getCurrentConditions)) {
            var cond = Weather.getCurrentConditions();
            if (cond != null) {
                var tempStr = (cond.temperature != null)
                    ? (cond.temperature.toNumber().toString() + "°")
                    : "--°";
                var iconChar = mapWeatherConditionToChar(cond.condition);
                return [iconChar, tempStr];
            }
        }
        return ["I", "--°"];
    }

    //! Maps a Toybox.Weather.CONDITION_* constant to its corresponding GarminIcons character.
    //! @param code Weather condition integer constant or null.
    //! @return Single-character string ('H' through 'N').
    public function mapWeatherConditionToChar(code as Number?) as String {
        if (code == null) { return "I"; }

        switch (code) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_MOSTLY_CLEAR:
                return "H"; // Clear / Sunny

            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
                return "I"; // Partly Cloudy

            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
                return "J"; // Cloudy

            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
                return "K"; // Rain / Showers

            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
            case Weather.CONDITION_TROPICAL_STORM:
            case Weather.CONDITION_HURRICANE:
            case Weather.CONDITION_TORNADO:
                return "L"; // Thunderstorm / Severe

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
                return "M"; // Snow / Ice

            case Weather.CONDITION_FOG:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_HAZE:
            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_DUST:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_SAND:
                return "N"; // Fog / Wind / Atmosphere

            default:
                return "I";
        }
    }
}
