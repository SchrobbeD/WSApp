import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function gameHeaderBottom() as Number {
    return 42;
}

function gameFooterHeight() as Number {
    return 44;
}

function gameRowHeight(screenH as Number, playerCount as Number) as Number {
    var top = gameHeaderBottom();
    var foot = gameFooterHeight();
    var rowH = (screenH - top - foot) / playerCount;
    if (rowH < 16) {
        rowH = 16;
    }
    return rowH;
}

class WallStrikeGameView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var st = appWallState();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var topY = gameHeaderBottom();
        var footH = gameFooterHeight();
        var rowH = gameRowHeight(h, st.playerCount);
        var playBottom = topY + st.playerCount * rowH;
        var footTop = h - footH;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 8, Graphics.FONT_SMALL, "Game", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, topY, w - 4, topY);

        if (st.matchesPlayed >= st.matchTotal) {
            var msgH = dc.getFontHeight(Graphics.FONT_XTINY) * 2 + 8;
            var cy = (h - msgH) / 2;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, cy, Graphics.FONT_XTINY, "All matches done", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, cy + dc.getFontHeight(Graphics.FONT_XTINY) + 6, Graphics.FONT_XTINY, "BACK: hub", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var i = 0;
        for (i = 0; i <= st.playerCount; i++) {
            var yy = topY + i * rowH;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(4, yy, w - 4, yy);
        }
        dc.drawLine(4, topY, 4, playBottom);
        dc.drawLine(w - 4, topY, w - 4, playBottom);

        for (i = 0; i < st.playerCount; i++) {
            var rowTop = topY + i * rowH;
            var label = st.playerNames[i];
            if (st.eliminated[i] != 0) {
                label = label + " [OUT]";
            }
            var c = Graphics.COLOR_LT_GRAY;
            if (st.eliminated[i] != 0) {
                c = Graphics.COLOR_DK_RED;
            }
            dc.setColor(c, Graphics.COLOR_TRANSPARENT);
            var ty = rowTop + (rowH - fhXt) / 2;
            dc.drawText(mid, ty, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, footTop, w - 4, footTop);
        dc.drawLine(4, footTop, 4, h - 4);
        dc.drawLine(w - 4, footTop, w - 4, h - 4);
        dc.drawLine(4, h - 4, w - 4, h - 4);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var fy = footTop + (footH - 2 * fhXt - 4) / 2;
        dc.drawText(mid, fy, Graphics.FONT_XTINY, "Rows: tap = OUT", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(mid, fy + fhXt + 2, Graphics.FONT_XTINY, "MENU: end match", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WallStrikeGameDelegate extends WatchUi.BehaviorDelegate {

    var _view as WallStrikeGameView;

    function initialize(view as WallStrikeGameView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var st = appWallState();
        if (st.sportOnlyMode) {
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (st.matchesPlayed >= st.matchTotal) {
            return true;
        }
        var xy = clickEvent.getCoordinates();
        var y = xy[1];
        var h = System.getDeviceSettings().screenHeight;
        var topY = gameHeaderBottom();
        var footTop = h - gameFooterHeight();
        if (y < topY || y >= footTop) {
            return true;
        }
        var rowH = gameRowHeight(h, st.playerCount);
        var idx = (y - topY) / rowH;
        if (idx < 0) {
            idx = 0;
        }
        if (idx >= st.playerCount) {
            return true;
        }
        st.toggleEliminated(idx);
        WatchUi.requestUpdate();
        return true;
    }

    function onMenu() as Boolean {
        var st = appWallState();
        if (st.sportOnlyMode) {
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (st.matchesPlayed >= st.matchTotal) {
            return true;
        }
        st.applyStubMatchScoring();
        st.matchesPlayed++;
        st.clearEliminationsForNewMatch();
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }
}
