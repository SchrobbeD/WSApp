import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Return shared WallStrikeState from app instance.
function appWallState() as WallStrikeState {
    return (Application.getApp() as WSApp).wallState;
}

class WSApp extends Application.AppBase {

    var wallState as WallStrikeState;

    function initialize() {
        AppBase.initialize();
        wallState = new WallStrikeState();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var st = wallState;
        st.startFitRecordingIfNeeded();
        return [new WallStrikeHubView(), new WallStrikeHubDelegate()];
    }

    function onStop(state as Dictionary or Null) as Void {
        wallState.stopFitRecordingIfNeeded();
    }
}