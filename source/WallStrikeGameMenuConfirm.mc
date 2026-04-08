import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class WallStrikeGameMenuConfirmView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var st = appWallState();

        var headerH = wsTopSafe();
        var footerH = wsBottomSafe();
        var fhTitle = dc.getFontHeight(Graphics.FONT_SMALL);
        var titleGap = 6;
        var listTop = headerH + fhTitle + titleGap;
        var listBottom = h - footerH;
        var rowCount = 3;
        var rowH = wsListRowHeightInRange(listTop, listBottom, rowCount, 18, 40);
        var top = wsListTopYInRange(listTop, listBottom, rowCount, rowH);
        var left = wsListLeftX();
        var right = wsListRightX(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, headerH + 2, Graphics.FONT_SMALL, "Game menu", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i <= rowCount; i++) {
            var y = top + i * rowH;
            dc.drawLine(left, y, right, y);
        }
        dc.drawLine(left, top, left, top + rowCount * rowH);
        dc.drawLine(right, top, right, top + rowCount * rowH);

        var labels = ["Reset scoring setup", "Reset names to defaults", "Cancel"] as Array<String>;
        var colors = [Graphics.COLOR_ORANGE, Graphics.COLOR_RED, Graphics.COLOR_LT_GRAY] as Array<Number>;
        var fh = dc.getFontHeight(Graphics.FONT_XTINY);
        for (var j = 0; j < rowCount; j++) {
            dc.setColor(colors[j], Graphics.COLOR_TRANSPARENT);
            var ty = top + j * rowH + (rowH - fh) / 2;
            dc.drawText(mid, ty, Graphics.FONT_XTINY, labels[j], Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (st.gameRowFocus < 0 || st.gameRowFocus >= rowCount) {
            st.gameRowFocus = 0;
        }
        var fy = top + st.gameRowFocus * rowH;
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left + 2, fy, right - 2, fy);
        dc.drawLine(left + 2, fy + rowH, right - 2, fy + rowH);
        dc.drawLine(left + 2, fy, left + 2, fy + rowH);
        dc.drawLine(right - 2, fy, right - 2, fy + rowH);
    }
}

class WallStrikeGameMenuConfirmDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function selectedIndex() as Number {
        var st = appWallState();
        if (st.gameRowFocus < 0) {
            st.gameRowFocus = 0;
        }
        if (st.gameRowFocus > 2) {
            st.gameRowFocus = 2;
        }
        return st.gameRowFocus;
    }

    function doAction() as Boolean {
        var st = appWallState();
        var idx = selectedIndex();
        if (idx == 0) {
            st.resetForFreshSetupKeepNames();
            st.namesRowFocus = 0;
            WatchUi.switchToView(new WallStrikeWizardView(), new WallStrikeWizardDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (idx == 1) {
            st.resetKnownNamesToDefaults();
            st.resetForFreshSetupKeepNames();
            st.namesRowFocus = 0;
            WatchUi.switchToView(new WallStrikeWizardView(), new WallStrikeWizardDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onPreviousPage() as Boolean {
        var st = appWallState();
        st.gameRowFocus--;
        if (st.gameRowFocus < 0) {
            st.gameRowFocus = 2;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var st = appWallState();
        st.gameRowFocus++;
        if (st.gameRowFocus > 2) {
            st.gameRowFocus = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        return doAction();
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var y = clickEvent.getCoordinates()[1];
        var h = System.getDeviceSettings().screenHeight;
        var headerH = wsTopSafe();
        var footerH = wsBottomSafe();
        var titleH = Graphics.getFontHeight(Graphics.FONT_SMALL);
        var listStart = headerH + titleH + 6;
        var listEnd = h - footerH;
        var rowH = wsListRowHeightInRange(listStart, listEnd, 3, 18, 40);
        var listTop = wsListTopYInRange(listStart, listEnd, 3, rowH);
        if (y < listTop || y >= listTop + 3 * rowH) {
            return true;
        }
        var st = appWallState();
        st.gameRowFocus = (y - listTop) / rowH;
        return doAction();
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
