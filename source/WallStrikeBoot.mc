import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function bootDividerY(h as Number) as Number {
    return wsTopSafe() + (h - wsTopSafe() - wsBottomSafe()) / 2;
}

function bootTextYCenter(yTop as Number, yBottom as Number, fontH as Number) as Number {
    var band = yBottom - yTop;
    var y = yTop + (band - fontH) / 2;
    if (y < yTop) {
        y = yTop;
    }
    return y;
}

function bootDrawFocusOutline(dc as Graphics.Dc, x as Number, y as Number, bw as Number, bh as Number) as Void {
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(x, y, x + bw, y);
    dc.drawLine(x, y + bh, x + bw, y + bh);
    dc.drawLine(x, y, x, y + bh);
    dc.drawLine(x + bw, y, x + bw, y + bh);
}

class WallStrikeBootView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        var st = appWallState();
        if (st.bootBandFocus < 0) {
            st.bootBandFocus = 0;
        }
        if (st.bootBandFocus > 1) {
            st.bootBandFocus = 1;
        }
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

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var yScoring = bootTextYCenter(wsTopSafe() + 2, yDiv - 4, fhS);
        dc.drawText(mid, yScoring, Graphics.FONT_SMALL, "Scoring setup", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        var ySport = bootTextYCenter(yDiv + 4, h - wsBottomSafe(), fhS);
        dc.drawText(mid, ySport, Graphics.FONT_SMALL, "Sport only", Graphics.TEXT_JUSTIFY_CENTER);

        var st = appWallState();
        if (st.bootBandFocus == 0) {
            bootDrawFocusOutline(dc, 6, wsTopSafe() + 2, w - 12, yDiv - (wsTopSafe() + 2));
        } else {
            bootDrawFocusOutline(dc, 6, yDiv, w - 12, h - wsBottomSafe() - yDiv);
        }
        // Bottom helper text intentionally removed.
    }
}

class WallStrikeBootDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function bootApplyChoice(st as WallStrikeState) as Void {
        st.bootDone = true;
        if (st.bootBandFocus == 0) {
            st.sportOnlyMode = false;
            WatchUi.switchToView(new WallStrikeWizardView(), new WallStrikeWizardDelegate(), WatchUi.SLIDE_LEFT);
        } else {
            st.sportOnlyMode = true;
            st.setupComplete = true;
            st.playerCount = 2;
            st.resetGameArrays();
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    function onPreviousPage() as Boolean {
        var st = appWallState();
        st.bootBandFocus--;
        if (st.bootBandFocus < 0) {
            st.bootBandFocus = 1;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var st = appWallState();
        st.bootBandFocus++;
        if (st.bootBandFocus > 1) {
            st.bootBandFocus = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var st = appWallState();
        bootApplyChoice(st);
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var st = appWallState();
        var y = clickEvent.getCoordinates()[1];
        var h = System.getDeviceSettings().screenHeight;
        var yDiv = bootDividerY(h);
        st.bootBandFocus = y < yDiv ? 0 : 1;
        bootApplyChoice(st);
        return true;
    }
}
