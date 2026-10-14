import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Lang;


(:background)
class WatchFaceTRIApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // --- VALORI FITTIZI DI TEST PER I 3 CERCHI ---
        if (Application.Storage.getValue("weekly_swim_km") == null) {
            Application.Storage.setValue("weekly_swim_km", 3.8); // Es. 3.8 km di nuoto
        }
        if (Application.Storage.getValue("weekly_bike_km") == null) {
            Application.Storage.setValue("weekly_bike_km", 120.0); // Es. 120 km di bici
        }
        if (Application.Storage.getValue("weekly_run_km") == null) {
            Application.Storage.setValue("weekly_run_km", 24.5); // Es. 24.5 km di corsa
        }

        // Registra il temporal event per il background
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(3600));
        }
    }

    function onStop(state as Dictionary?) as Void {}

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new WatchFaceTRIView() ];
    }

    // Riceve i dati dal background service
    function onBackgroundData(data) as Void {
        if (data instanceof Dictionary) {
            if (data.hasKey("swim")) { Application.Storage.setValue("weekly_swim_km", data["swim"]); }
            if (data.hasKey("bike")) { Application.Storage.setValue("weekly_bike_km", data["bike"]); }
            if (data.hasKey("run"))  { Application.Storage.setValue("weekly_run_km",  data["run"]); }
            WatchUi.requestUpdate();
        }
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new WatchFaceTRIBgService() ];
    }
}