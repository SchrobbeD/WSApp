import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.UserProfile;
import Toybox.WatchUi;

class WallStrikeSportView extends WatchUi.View {

    var _tick as Timer.Timer?;

    function initialize() {
        View.initialize();
        _tick = null;
    }

    function onShow() as Void {
        if (_tick == null) {
            _tick = new Timer.Timer();
            _tick.start(method(:onTick), 1000, true);
        }
    }

    function onHide() as Void {
        if (_tick != null) {
            _tick.stop();
            _tick = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function isRecording() as Boolean {
        return appWallState().isFitRecording();
    }

    function isPaused() as Boolean {
        return appWallState().isFitPaused();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var footH = 52;
        var footTop = h - footH;
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var fhMd = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var fhSm = dc.getFontHeight(Graphics.FONT_SMALL);
        var zoneH = 12;
        var blockH = zoneH + 6 + fhMd + 2 + fhSm + 2 + fhXt + 2 + fhXt;
        var contentTop = (footTop - wsTopSafe() - blockH) / 2 + wsTopSafe();
        if (contentTop < wsTopSafe()) {
            contentTop = wsTopSafe();
        }

        var ainfo = Activity.getActivityInfo();
        var hrStr = "--";
        var calStr = "--";
        var timeStr = "--:--";
        var zoneStr = "-";
        if (ainfo != null) {
            if (ainfo.currentHeartRate != null) {
                hrStr = ainfo.currentHeartRate.toString();
                zoneStr = zoneLabel(ainfo.currentHeartRate);
            }
            if (ainfo.calories != null) {
                calStr = ainfo.calories.toString();
            }
            if (ainfo.timerTime != null) {
                timeStr = formatMs(ainfo.timerTime);
            }
        }

        var y = contentTop;
        drawZoneBar(dc, y, w - 24, zoneStr);
        y += zoneH + 6;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, y, Graphics.FONT_MEDIUM, "HR " + hrStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhMd + 2;
        dc.drawText(mid, y, Graphics.FONT_SMALL, "Zone " + zoneStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhSm + 2;
        dc.drawText(mid, y, Graphics.FONT_XTINY, "kcal " + calStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhXt + 2;
        dc.drawText(mid, y, Graphics.FONT_XTINY, "Timer " + timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhXt + 8;
        dc.drawText(mid, y, Graphics.FONT_XTINY, "Time " + formatClock(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, footTop, w - 4, footTop);
        dc.drawLine(4, footTop, 4, h - 4);
        dc.drawLine(w - 4, footTop, w - 4, h - 4);
        dc.drawLine(4, h - 4, w - 4, h - 4);

        var menuLine = "Activity tracked";
        if (isPaused()) {
            menuLine = "Activity paused";
        }
        var fy = footTop + 4;
        if (!isPaused()) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(mid, fy, Graphics.FONT_XTINY, menuLine, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function formatMs(ms as Number) as String {
        var totalSec = ms / 1000;
        var m = totalSec / 60;
        var s = totalSec % 60;
        var pad = "";
        if (s < 10) {
            pad = "0";
        }
        return m + ":" + pad + s;
    }

    function formatClock() as String {
        var now = System.getClockTime();
        var h = now.hour;
        var m = now.min;
        var mm = "";
        if (m < 10) {
            mm = "0" + m;
        } else {
            mm = m.toString();
        }
        return h + ":" + mm;
    }

    function zoneLabel(hr as Number) as String {
        if ((Toybox has :UserProfile) == false) {
            return "?";
        }
        var z = UserProfile.getHeartRateZones2(Activity.SPORT_GENERIC);
        if (z == null || z.size() == 0) {
            return "?";
        }
        var i = 0;
        for (i = 0; i < z.size(); i++) {
            if (hr <= z[i]) {
                return (i + 1).toString();
            }
        }
        return z.size().toString();
    }

    function drawZoneBar(dc as Graphics.Dc, yTop as Number, barW as Number, zoneStr as String) as Void {
        var x0 = (dc.getWidth() - barW) / 2;
        var zone = 1;
        if (zoneStr != "?" && zoneStr != "-") {
            var parsed = zoneStr.toNumber();
            if (parsed != null) {
                zone = parsed;
            }
        }
        var segmentW = barW / 5;
        var i = 0;
        for (i = 0; i < 5; i++) {
            var c = Graphics.COLOR_DK_GRAY;
            if (i == 0) { c = Graphics.COLOR_BLUE; }
            if (i == 1) { c = Graphics.COLOR_LT_GRAY; }
            if (i == 2) { c = Graphics.COLOR_GREEN; }
            if (i == 3) { c = Graphics.COLOR_YELLOW; }
            if (i == 4) { c = Graphics.COLOR_RED; }
            dc.setColor(c, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x0 + i * segmentW, yTop, x0 + (i + 1) * segmentW - 2, yTop);
            dc.drawLine(x0 + i * segmentW, yTop + 1, x0 + (i + 1) * segmentW - 2, yTop + 1);
            dc.drawLine(x0 + i * segmentW, yTop + 2, x0 + (i + 1) * segmentW - 2, yTop + 2);
            dc.drawLine(x0 + i * segmentW, yTop + 3, x0 + (i + 1) * segmentW - 2, yTop + 3);
        }
        if (zone >= 1 && zone <= 5) {
            var zx = x0 + (zone - 1) * segmentW + segmentW / 2;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(zx - 2, yTop + 6, zx + 2, yTop + 6);
            dc.drawLine(zx - 1, yTop + 7, zx + 1, yTop + 7);
        }
    }
}

class WallStrikeSportDelegate extends WatchUi.BehaviorDelegate {

    var _view as WallStrikeSportView;

    function initialize(v as WallStrikeSportView) {
        BehaviorDelegate.initialize();
        _view = v;
    }

    function onMenu() as Boolean {
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var st = appWallState();
        st.toggleFitPauseResume();
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }
}