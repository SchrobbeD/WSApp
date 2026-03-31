import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.WatchUi;

function wizardThirdY1(h as Number) as Number {
    var t = wsTopSafe();
    var b = h - wsBottomSafe();
    return t + (b - t) / 3;
}

function wizardThirdY2(h as Number) as Number {
    var t = wsTopSafe();
    var b = h - wsBottomSafe();
    return t + 2 * (b - t) / 3;
}

function wizardTextYCenteredInBand(yTop as Number, yBottom as Number, fontH as Number) as Number {
    var band = yBottom - yTop;
    var y = yTop + (band - fontH) / 2;
    if (y < yTop) {
        y = yTop;
    }
    return y;
}

class WallStrikeWizardView extends WatchUi.View {

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
        var yA = wizardThirdY1(h);
        var yB = wizardThirdY2(h);

        var fhSm = dc.getFontHeight(Graphics.FONT_SMALL);
        var fhMd = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);

        var midTitle = "";
        var midValue = "";
        var midHint = "";
        if (st.wizardStep == 0) {
            midTitle = "Players";
            midValue = st.playerCount.toString();
        } else if (st.wizardStep == 1) {
            midTitle = "Game system";
            midValue = st.getSystemLabel();
        } else if (st.wizardStep == 2) {
            if (st.systemId == 2) {
                midTitle = "Lives";
                midValue = st.livesSetting.toString();
            } else {
                midTitle = "Matches";
                midValue = st.matchTotal.toString();
            }
        }

        if (st.wizardStep == 1 && st.systemId == 1 && !st.isXDownAllowed()) {
            midHint = "Need 3+ players";
        }

        var midBlock = fhSm + 6 + fhMd + 6 + fhXt;
        var yMid = wizardTextYCenteredInBand(yA + 2, yB - 2, midBlock);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, yMid, Graphics.FONT_SMALL, midTitle, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(mid, yMid + fhSm + 6, Graphics.FONT_MEDIUM, midValue, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, yMid + fhSm + 6 + fhMd + 6, Graphics.FONT_XTINY, midHint, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WallStrikeWizardDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function wizardDoTop() as Void {
        var st = appWallState();
        if (st.wizardStep == 0) {
            st.playerCount++;
            if (st.playerCount > 8) {
                st.playerCount = 2;
            }
        } else if (st.wizardStep == 1) {
            st.systemId = (st.systemId + 1) % 3;
        } else if (st.wizardStep == 2) {
            if (st.systemId == 2) {
                st.livesSetting++;
                if (st.livesSetting > 10) {
                    st.livesSetting = 2;
                }
            } else {
                st.matchTotal++;
                if (st.matchTotal > 20) {
                    st.matchTotal = 1;
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function wizardDoBottom() as Void {
        var st = appWallState();
        if (st.wizardStep == 0) {
            st.playerCount--;
            if (st.playerCount < 2) {
                st.playerCount = 8;
            }
        } else if (st.wizardStep == 1) {
            st.systemId = st.systemId - 1;
            if (st.systemId < 0) {
                st.systemId = 2;
            }
        } else if (st.wizardStep == 2) {
            if (st.systemId == 2) {
                st.livesSetting--;
                if (st.livesSetting < 2) {
                    st.livesSetting = 10;
                }
            } else {
                st.matchTotal--;
                if (st.matchTotal < 1) {
                    st.matchTotal = 20;
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function wizardDoCenter() as Void {
        var st = appWallState();
        if (st.wizardStep == 1 && st.systemId == 1 && !st.isXDownAllowed()) {
            WatchUi.requestUpdate();
            return;
        }

        var lastStep = 2;

        if (st.wizardStep < lastStep) {
            st.wizardStep++;
            WatchUi.requestUpdate();
            return;
        }
        if (st.systemId == 2) {
            // Lives mode is one continuous game; match count input is skipped.
            st.matchTotal = 1;
        }
        st.resetGameArrays();
        st.namesRowFocus = 0;
        var nv = new WallStrikeNamesView();
        WatchUi.switchToView(nv, new WallStrikeNamesDelegate(nv), WatchUi.SLIDE_LEFT);
    }

    function onPreviousPage() as Boolean {
        wizardDoTop();
        return true;
    }

    function onNextPage() as Boolean {
        wizardDoBottom();
        return true;
    }

    function onSelect() as Boolean {
        wizardDoCenter();
        return true;
    }

    function onBack() as Boolean {
        // Prevent app exit when backing out of setup.
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        var y = xy[1];
        var h = System.getDeviceSettings().screenHeight;
        var yA = wizardThirdY1(h);
        var yB = wizardThirdY2(h);
        if (y < yA) {
            wizardDoTop();
            return true;
        }
        if (y > yB) {
            wizardDoBottom();
            return true;
        }
        wizardDoCenter();
        return true;
    }
}
