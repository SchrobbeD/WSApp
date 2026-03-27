import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Pixels reserved for title + match line (tap in this strip still opens Sport).
function hubHeaderHeight() as Number {
    return 52;
}

function hubDividerY1(screenH as Number) as Number {
    var hb = hubHeaderHeight();
    var band = (screenH - hb) / 3;
    return hb + band;
}

function hubDividerY2(screenH as Number) as Number {
    var hb = hubHeaderHeight();
    var band = (screenH - hb) / 3;
    return hb + 2 * band;
}

function drawUiDivider(dc as Graphics.Dc, y as Number) as Void {
    var w = dc.getWidth();
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(4, y, w - 4, y);
}

//! Vertical center of text band [yTop, yBottom) for given font height.
function textYCenteredInBand(yTop as Number, yBottom as Number, fontH as Number) as Number {
    var band = yBottom - yTop;
    var y = yTop + (band - fontH) / 2;
    if (y < yTop) {
        y = yTop;
    }
    return y;
}

class WallStrikeHubView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = System.getDeviceSettings().screenHeight;
        var mid = w / 2;
        var hb = hubHeaderHeight();
        var y1 = hubDividerY1(h);
        var y2 = hubDividerY2(h);
        var st = appWallState();

        var line = "Match ";
        if (st.sportOnlyMode) {
            line = "Sport only";
        } else if (st.matchesPlayed >= st.matchTotal) {
            line = line + "done";
        } else {
            line = line + (st.matchesPlayed + 1) + "/" + st.matchTotal;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var fhS = dc.getFontHeight(Graphics.FONT_SMALL);
        var fhX = dc.getFontHeight(Graphics.FONT_XTINY);
        var headerBlock = fhS + 4 + fhX;
        var yTitle = textYCenteredInBand(2, hb - 2, headerBlock);
        dc.drawText(mid, yTitle, Graphics.FONT_SMALL, "WallStrike", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(mid, yTitle + fhS + 4, Graphics.FONT_XTINY, line, Graphics.TEXT_JUSTIFY_CENTER);

        drawUiDivider(dc, y1);
        drawUiDivider(dc, y2);

        var fhRow = dc.getFontHeight(Graphics.FONT_SMALL);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            mid,
            textYCenteredInBand(hb, y1, fhRow),
            Graphics.FONT_SMALL,
            "SPORT",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            mid,
            textYCenteredInBand(hb, y1, fhRow) + fhRow + 2,
            Graphics.FONT_XTINY,
            "FIT / stats",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (st.sportOnlyMode) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, textYCenteredInBand(y1, y2, fhRow), Graphics.FONT_SMALL, "GAME", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(mid, textYCenteredInBand(y1, y2, fhRow) + fhRow + 2, Graphics.FONT_XTINY, "off", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(mid, textYCenteredInBand(y2, h - 4, fhRow), Graphics.FONT_SMALL, "SCORES", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(mid, textYCenteredInBand(y2, h - 4, fhRow) + fhRow + 2, Graphics.FONT_XTINY, "off", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                mid,
                textYCenteredInBand(y1, y2, fhRow),
                Graphics.FONT_SMALL,
                "GAME",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                mid,
                textYCenteredInBand(y1, y2, fhRow) + fhRow + 2,
                Graphics.FONT_XTINY,
                "eliminate",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                mid,
                textYCenteredInBand(y2, h - 4, fhRow),
                Graphics.FONT_SMALL,
                "SCORES",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                mid,
                textYCenteredInBand(y2, h - 4, fhRow) + fhRow + 2,
                Graphics.FONT_XTINY,
                "standings",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }
}

class WallStrikeHubDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        var y = xy[1];
        var h = System.getDeviceSettings().screenHeight;
        var y1 = hubDividerY1(h);
        var y2 = hubDividerY2(h);
        var st = appWallState();
        if (y < y1) {
            var sv = new WallStrikeSportView();
            WatchUi.switchToView(sv, new WallStrikeSportDelegate(sv), WatchUi.SLIDE_LEFT);
            return true;
        }
        if (st.sportOnlyMode) {
            return true;
        }
        if (y < y2) {
            var gv = new WallStrikeGameView();
            WatchUi.switchToView(gv, new WallStrikeGameDelegate(gv), WatchUi.SLIDE_LEFT);
            return true;
        }
        var tv = new WallStrikeStandingsView();
        WatchUi.switchToView(tv, new WallStrikeStandingsDelegate(tv), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onBack() as Boolean {
        return false;
    }
}
