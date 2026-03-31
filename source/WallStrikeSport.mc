import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Timer;
import Toybox.UserProfile;
import Toybox.WatchUi;

class WallStrikeSportView extends WatchUi.View {

    var _session as ActivityRecording.Session?;
    var _tick as Timer.Timer?;

    function initialize() {
        View.initialize();
        _session = null;
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
        if (_session != null) {
            return _session.isRecording();
        }
        return false;
    }

    function toggleRecording() as Void {
        if ((Toybox has :ActivityRecording) == false) {
            return;
        }
        if (!isRecording()) {
            _session = ActivityRecording.createSession({
                :name => "WallStrike",
                :sport => Activity.SPORT_GENERIC,
            });
            _session.start();
        } else if (_session != null) {
            _session.stop();
            _session.save();
            _session = null;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var footH = 46;
        var footTop = h - footH;
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var fhMd = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var sparkH = 32;
        var blockH = fhXt + 4 + fhMd + 2 + fhXt + 2 + fhXt + 8 + sparkH;
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

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var y = contentTop;
        dc.drawText(mid, y, Graphics.FONT_XTINY, "Sport", Graphics.TEXT_JUSTIFY_CENTER);
        y += fhXt + 4;
        dc.drawText(mid, y, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhMd + 2;
        dc.drawText(mid, y, Graphics.FONT_XTINY, "HR " + hrStr + "  Z" + zoneStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhXt + 2;
        dc.drawText(mid, y, Graphics.FONT_XTINY, "kcal " + calStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += fhXt + 8;
        drawHrSparkline(dc, y, w - 20, sparkH);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, footTop, w - 4, footTop);
        dc.drawLine(4, footTop, 4, h - 4);
        dc.drawLine(w - 4, footTop, w - 4, h - 4);
        dc.drawLine(4, h - 4, w - 4, h - 4);

        var menuLine = "MENU: start FIT";
        if (isRecording()) {
            menuLine = "MENU: stop & save";
        }
        var fy = footTop + (footH - 2 * fhXt - 4) / 2;
        if (isRecording()) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(mid, fy, Graphics.FONT_XTINY, menuLine, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, fy + fhXt + 2, Graphics.FONT_XTINY, "BACK: hub", Graphics.TEXT_JUSTIFY_CENTER);
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

    function drawHrSparkline(dc as Graphics.Dc, yTop as Number, barW as Number, barH as Number) as Void {
        var x0 = 10;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x0, yTop, barW, barH);
        var it = SensorHistory.getHeartRateHistory({:period => 120, :order => SensorHistory.ORDER_OLDEST_FIRST});
        var samples = [] as Array<Number>;
        var s = it.next();
        while (s != null) {
            if (s.data != null) {
                samples.add(s.data.toNumber());
            }
            s = it.next();
        }
        var n = samples.size();
        if (n < 2) {
            return;
        }
        var minHr = 50;
        var maxHr = 180;
        var span = maxHr - minHr;
        if (span <= 0) {
            span = 1;
        }
        var i = 0;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        for (i = 1; i < n; i++) {
            var xa = x0 + (i - 1) * (barW - 1) / (n - 1);
            var xb = x0 + i * (barW - 1) / (n - 1);
            var ha = barH - 1 - ((samples[i - 1] - minHr) * (barH - 2) / span);
            var hb = barH - 1 - ((samples[i] - minHr) * (barH - 2) / span);
            if (ha < 0) {
                ha = 0;
            }
            if (hb < 0) {
                hb = 0;
            }
            if (ha > barH - 1) {
                ha = barH - 1;
            }
            if (hb > barH - 1) {
                hb = barH - 1;
            }
            dc.drawLine(xa, yTop + ha, xb, yTop + hb);
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
        _view.toggleRecording();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }
}