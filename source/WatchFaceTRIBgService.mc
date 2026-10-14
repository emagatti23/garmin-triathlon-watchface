import Toybox.Background;
import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;


(:background)
class WatchFaceTRIBgService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var url = "https://tuo-endpoint.com/api/weekly-totals"; // Sostituisci con il tuo endpoint
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, method(:onReceiveData));
    }

    function onReceiveData(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary) {
            // data deve essere nel formato: {"swim": 3.5, "bike": 85.0, "run": 22.4}
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }
}