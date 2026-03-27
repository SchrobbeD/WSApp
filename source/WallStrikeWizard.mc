import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.WatchUi;

function wizardThirdY1(h as Number) as Number {
    return h / 3;
}

function wizardThirdY2(h as Number) as Number {
    return 2 * h / 3;
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

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, yA, w - 4, yA);
        dc.drawLine(4, yB, w - 4, yB);

        var fhSm = dc.getFontHeight(Graphics.FONT_SMALL);
        var fhMd = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, wizardTextYCenteredInBand(4, yA - 2, fhXt), Graphics.FONT_XTINY, "TOP: more +", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, wizardTextYCenteredInBand(yB + 2, h - 4, fhXt), Graphics.FONT_XTINY, "BOTTOM: less -", Graphics.TEXT_JUSTIFY_CENTER);

        var midTitle = "";
        var midValue = "";
        var midHint = "";
        if (st.wizardStep == 0) {
            midTitle = "Players";
            midValue = st.playerCount.toString();
            midHint = "CENTER: next";
        } else if (st.wizardStep == 1) {
            midTitle = "Game system";
            midValue = "Sys " + st.getSystemLabel();
            midHint = "CENTER: next";
        } else if (st.wizardStep == 2) {
            midTitle = "Matches";
            midValue = st.matchTotal.toString();
            midHint = "CENTER: names list";
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

class WallStrikeWizardDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var st = appWallState();
        var xy = clickEvent.getCoordinates();
        var y = xy[1];
        var h = System.getDeviceSettings().screenHeight;
        var yA = wizardThirdY1(h);
        var yB = wizardThirdY2(h);
        if (y < yA) {
            if (st.wizardStep == 0) {
                st.playerCount++;
                if (st.playerCount > 8) {
                    st.playerCount = 2;
                }
            } else if (st.wizardStep == 1) {
                st.systemId = (st.systemId + 1) % 3;
            } else if (st.wizardStep == 2) {
                st.matchTotal++;
                if (st.matchTotal > 20) {
                    st.matchTotal = 1;
                }
            }
            WatchUi.requestUpdate();
            return true;
        }
        if (y > yB) {
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
                st.matchTotal--;
                if (st.matchTotal < 1) {
                    st.matchTotal = 20;
                }
            }
            WatchUi.requestUpdate();
            return true;
        }
        if (st.wizardStep < 2) {
            st.wizardStep++;
            WatchUi.requestUpdate();
            return true;
        }
        st.resetGameArrays();
        var nv = new WallStrikeNamesView();
        WatchUi.switchToView(nv, new WallStrikeNamesDelegate(nv), WatchUi.SLIDE_LEFT);
        return true;
    }
}
