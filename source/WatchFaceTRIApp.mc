import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Lang;

//! Main Application Entry Point.
//! Coordinates lifecycle events, background service registration, and runtime settings updates.
(:background)
class WatchFaceTRIApp extends Application.AppBase {

    //! Constructor. Initializes the base Connect IQ application.
    public function initialize() {
        AppBase.initialize();
    }

    //! Invoked when the application starts.
    //! Registers the hourly background temporal event if not already active.
    //! @param state Optional dictionary containing application startup state.
    public function onStart(state as Dictionary?) as Void {
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(3600));
        }
    }

    //! Invoked when the application stops.
    //! @param state Optional dictionary containing application termination state.
    public function onStop(state as Dictionary?) as Void {
    }

    //! Returns the main watch face view instance.
    //! @return Array containing the primary WatchFaceTRIView.
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new WatchFaceTRIView() ];
    }

    //! Triggered automatically when the user modifies settings in Garmin Connect IQ mobile/express.
    //! Forces an immediate UI redraw to reflect the new configuration.
    public function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    //! Callback invoked when the background service returns synchronized training data.
    //! @param data Dictionary containing optional "swim", "bike", and "run" weekly kilometer totals.
    public function onBackgroundData(data) as Void {
        if (data instanceof Dictionary) {
            if (data.hasKey("swim")) { Application.Storage.setValue("weekly_swim_km", data["swim"]); }
            if (data.hasKey("bike")) { Application.Storage.setValue("weekly_bike_km", data["bike"]); }
            if (data.hasKey("run"))  { Application.Storage.setValue("weekly_run_km",  data["run"]); }
            WatchUi.requestUpdate();
        }
    }

    //! Returns the background service delegate responsible for periodic web synchronization.
    //! @return Array containing the WatchFaceTRIBgService instance.
    public function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new WatchFaceTRIBgService() ];
    }
}
