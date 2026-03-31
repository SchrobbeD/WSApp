import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Pixels reserved for title + match line (tap in this strip still opens Sport).
function hubHeaderHeight() as Number {
    return wsTopSafe();
}

function hubDividerY1(screenH as Number) as Number {
    var hb = hubHeaderHeight();
    var band = (screenH - wsBottomSafe() - hb) / 3;
    return hb + band;
}

function hubDividerY2(screenH as Number) as Number {
    var hb = hubHeaderHeight();
    var band = (screenH - wsBottomSafe() - hb) / 3;
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

function hubMaxBand(st as WallStrikeState) as Number {
    if (st.sportOnlyMode) {
        return 0;
    }
    return 2;
}

function drawFocusOutline(dc as Graphics.Dc, x as Number, y as Number, bw as Number, bh as Number) as Void {
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(x, y, x + bw, y);
    dc.drawLine(x, y + bh, x + bw, y + bh);
    dc.drawLine(x, y, x, y + bh);
    dc.drawLine(x + bw, y, x + bw, y + bh);
}

function drawBandLabel(dc as Graphics.Dc, mid as Number, yTop as Number, yBottom as Number, title as String, titleColor as Number) as Void {
    var fhTitle = dc.getFontHeight(Graphics.FONT_SMALL);
    var y = textYCenteredInBand(yTop, yBottom, fhTitle);
    dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
    dc.drawText(mid, y, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
}

class WallStrikeHubView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        var st = appWallState();
        var maxB = hubMaxBand(st);
        if (st.hubBandFocus > maxB) {
            st.hubBandFocus = maxB;
        }
        if (st.hubBandFocus < 0) {
            st.hubBandFocus = 0;
        }
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

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var yTitle = textYCenteredInBand(2, hb - 2, dc.getFontHeight(Graphics.FONT_SMALL));
        dc.drawText(mid, yTitle, Graphics.FONT_SMALL, "WallStrike", Graphics.TEXT_JUSTIFY_CENTER);

        drawUiDivider(dc, y1);
        drawUiDivider(dc, y2);

        drawBandLabel(dc, mid, hb, y1, "SPORT", Graphics.COLOR_BLUE);

        if (st.sportOnlyMode) {
            drawBandLabel(dc, mid, y1, y2, "GAME", Graphics.COLOR_DK_GRAY);
            drawBandLabel(dc, mid, y2, h - wsBottomSafe(), "STANDINGS", Graphics.COLOR_DK_GRAY);
        } else {
            drawBandLabel(dc, mid, y1, y2, "GAME", Graphics.COLOR_GREEN);
            drawBandLabel(dc, mid, y2, h - wsBottomSafe(), "STANDINGS", Graphics.COLOR_YELLOW);
        }

        var fb = st.hubBandFocus;
        if (fb == 0) {
            drawFocusOutline(dc, 6, hb, w - 12, y1 - hb);
        } else if (fb == 1 && !st.sportOnlyMode) {
            drawFocusOutline(dc, 6, y1, w - 12, y2 - y1);
        } else if (fb == 2 && !st.sportOnlyMode) {
            drawFocusOutline(dc, 6, y2, w - 12, h - wsBottomSafe() - y2);
        }

        // Bottom helper text intentionally removed.
    }
}

class WallStrikeHubDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function hubActivateBand(st as WallStrikeState, band as Number) as Void {
        if (band == 0) {
            var sv = new WallStrikeSportView();
            WatchUi.switchToView(sv, new WallStrikeSportDelegate(sv), WatchUi.SLIDE_LEFT);
            return;
        }
        if (st.sportOnlyMode) {
            return;
        }
        if (band == 1) {
            var gv = new WallStrikeGameView();
            WatchUi.switchToView(gv, new WallStrikeGameDelegate(gv), WatchUi.SLIDE_LEFT);
            return;
        }
        var tv = new WallStrikeStandingsView();
        WatchUi.switchToView(tv, new WallStrikeStandingsDelegate(tv), WatchUi.SLIDE_LEFT);
    }

    function onPreviousPage() as Boolean {
        var st = appWallState();
        var maxB = hubMaxBand(st);
        st.hubBandFocus--;
        if (st.hubBandFocus < 0) {
            st.hubBandFocus = maxB;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var st = appWallState();
        var maxB = hubMaxBand(st);
        st.hubBandFocus++;
        if (st.hubBandFocus > maxB) {
            st.hubBandFocus = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var st = appWallState();
        hubActivateBand(st, st.hubBandFocus);
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        var y = xy[1];
        var h = System.getDeviceSettings().screenHeight;
        var y1 = hubDividerY1(h);
        var y2 = hubDividerY2(h);
        var st = appWallState();
        if (y < y1) {
            hubActivateBand(st, 0);
            return true;
        }
        if (st.sportOnlyMode) {
            return true;
        }
        if (y < y2) {
            hubActivateBand(st, 1);
            return true;
        }
        hubActivateBand(st, 2);
        return true;
    }

    function onBack() as Boolean {
        return false;
    }
}
