import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;

//! Background Service Delegate.
//! Executes periodic HTTP GET requests to an optional user-configured JSON endpoint
//! to fetch external weekly training totals without hardcoding personal URLs.
(:background)
class WatchFaceTRIBgService extends System.ServiceDelegate {

    //! Constructor. Initializes the system service delegate.
    public function initialize() {
        ServiceDelegate.initialize();
    }

    //! Invoked periodically by the system temporal scheduler.
    //! Reads the user-defined 'SyncUrl' property; exits cleanly if left blank.
    public function onTemporalEvent() as Void {
        var url = "";
        try {
            var propVal = Application.Properties.getValue("SyncUrl");
            if (propVal instanceof String) {
                url = propVal;
            }
        } catch (ex) {
            url = "";
        }

        if (url.length() == 0) {
            Background.exit(null);
            return;
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, null, options, method(:onReceiveData));
    }

    //! Handles the asynchronous HTTP response from the external training endpoint.
    //! Expected JSON payload format: {"swim": 3.8, "bike": 120.0, "run": 24.5}
    //! @param responseCode HTTP status code.
    //! @param data Parsed JSON dictionary or raw response string.
    public function onReceiveData(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary) {
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }
}
