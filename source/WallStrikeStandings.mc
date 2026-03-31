import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function standingsFooterHeight() as Number {
    return 40;
}

class WallStrikeStandingsView extends WatchUi.View {

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
        var footH = standingsFooterHeight();
        var footTop = h - footH;
        var headerH = wsTopSafe();

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 10, Graphics.FONT_SMALL, "Scores", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 10 + dc.getFontHeight(Graphics.FONT_SMALL) + 2, Graphics.FONT_XTINY, st.getSystemLabel() + " " + st.getSystemDetailLabel(), Graphics.TEXT_JUSTIFY_CENTER);
        var showPlannedAll = st.matchesPlayed > st.matchTotal && st.plannedScores.size() == st.playerCount;
        if (showPlannedAll) {
            dc.drawText(mid, 10 + dc.getFontHeight(Graphics.FONT_SMALL) + dc.getFontHeight(Graphics.FONT_XTINY) + 4, Graphics.FONT_XTINY, "planned / all", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var indices = [] as Array<Number>;
        var i = 0;
        for (i = 0; i < st.playerCount; i++) {
            indices.add(i);
        }
        var a = 0;
        for (a = 0; a < st.playerCount; a++) {
            var b = 0;
            for (b = a + 1; b < st.playerCount; b++) {
                if (st.scores[indices[b]] > st.scores[indices[a]]) {
                    var tmp = indices[a];
                    indices[a] = indices[b];
                    indices[b] = tmp;
                }
            }
        }

        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var rowH = fhXt + 3;
        var listH = st.playerCount * rowH;
        var listTop = headerH + (footTop - headerH - listH) / 2;
        if (listTop < headerH + 4) {
            listTop = headerH + 4;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (i = 0; i < st.playerCount; i++) {
            var idx = indices[i];
            var line = st.playerNames[idx] + "  " + st.scores[idx].toString();
            if (showPlannedAll) {
                var planned = st.plannedScores[idx];
                line = st.playerNames[idx] + "  " + planned.toString() + " / " + st.scores[idx].toString();
            }
            if (st.systemId == 2 && st.matchInProgress) {
                line = line + "  L" + st.lives[idx];
            }
            dc.drawText(mid, listTop + i * rowH, Graphics.FONT_XTINY, line, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, footTop, w - 4, footTop);
        dc.drawLine(4, footTop, 4, h - 4);
        dc.drawLine(w - 4, footTop, w - 4, h - 4);
        dc.drawLine(4, h - 4, w - 4, h - 4);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var fy = footTop + (footH - fhXt) / 2;
        dc.drawText(mid, fy, Graphics.FONT_XTINY, "BACK: hub", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WallStrikeStandingsDelegate extends WatchUi.BehaviorDelegate {

    var _view as WallStrikeStandingsView;

    function initialize(view as WallStrikeStandingsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onBack() as Boolean {
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }
}
