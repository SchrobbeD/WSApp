import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function bootDividerY(h as Number) as Number {
    return h / 2;
}

function bootTextYCenter(yTop as Number, yBottom as Number, fontH as Number) as Number {
    var band = yBottom - yTop;
    var y = yTop + (band - fontH) / 2;
    if (y < yTop) {
        y = yTop;
    }
    return y;
}

class WallStrikeBootView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var yDiv = bootDividerY(h);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, yDiv, w - 4, yDiv);

        var fhS = dc.getFontHeight(Graphics.FONT_SMALL);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 12, Graphics.FONT_SMALL, "WallStrike", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 12 + fhS + 4, Graphics.FONT_XTINY, "Choose mode", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var yScoring = bootTextYCenter(44, yDiv - 4, fhS);
        dc.drawText(mid, yScoring, Graphics.FONT_SMALL, "Scoring setup", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, yScoring + fhS + 2, Graphics.FONT_XTINY, "players, game, names", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        var ySport = bootTextYCenter(yDiv + 4, h - 6, fhS);
        dc.drawText(mid, ySport, Graphics.FONT_SMALL, "Sport only", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, ySport + fhS + 2, Graphics.FONT_XTINY, "FIT / activity", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WallStrikeBootDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var st = appWallState();
        var y = clickEvent.getCoordinates()[1];
        var h = System.getDeviceSettings().screenHeight;
        var yDiv = bootDividerY(h);
        st.bootDone = true;
        if (y < yDiv) {
            st.sportOnlyMode = false;
            WatchUi.switchToView(new WallStrikeWizardView(), new WallStrikeWizardDelegate(), WatchUi.SLIDE_LEFT);
            return true;
        }
        st.sportOnlyMode = true;
        st.setupComplete = true;
        st.playerCount = 2;
        st.resetGameArrays();
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }
}
