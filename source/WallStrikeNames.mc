import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function namesHeaderBottom() as Number {
    return 36;
}

class WallStrikeNamesView extends WatchUi.View {

    //! Synced each onUpdate for hit-testing in the delegate (same geometry as drawing).
    var _tapRowH as Number;
    var _tapListTop as Number;

    function initialize() {
        View.initialize();
        _tapRowH = 22;
        _tapListTop = namesHeaderBottom() + 4;
    }

    function tapRowH() as Number {
        return _tapRowH;
    }

    function tapListTop() as Number {
        return _tapListTop;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var st = appWallState();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var topY = namesHeaderBottom();
        var rowCount = st.playerCount + 1;
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var minRow = fhXt + 6;
        var ideal = (h - topY) / rowCount;
        var rowH = ideal;
        if (rowH < minRow) {
            rowH = minRow;
        }
        var blockH = rowCount * rowH;
        var listTop = topY + (h - topY - blockH) / 2;
        _tapRowH = rowH;
        _tapListTop = listTop;

        var blockBottom = listTop + rowCount * rowH;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 8, Graphics.FONT_SMALL, "Names", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, topY, w - 4, topY);

        var i = 0;
        for (i = 0; i <= rowCount; i++) {
            var yy = listTop + i * rowH;
            dc.drawLine(4, yy, w - 4, yy);
        }
        dc.drawLine(4, listTop, 4, blockBottom);
        dc.drawLine(w - 4, listTop, w - 4, blockBottom);

        for (i = 0; i < st.playerCount; i++) {
            var rowTop = listTop + i * rowH;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, rowTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, st.playerNames[i], Graphics.TEXT_JUSTIFY_CENTER);
        }

        var nextTop = listTop + st.playerCount * rowH;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, nextTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, "Next", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WallStrikeNamesDelegate extends WatchUi.InputDelegate {

    var _view as WallStrikeNamesView;

    function initialize(v as WallStrikeNamesView) {
        InputDelegate.initialize();
        _view = v;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var st = appWallState();
        var y = clickEvent.getCoordinates()[1];
        var topY = namesHeaderBottom();
        if (y < topY) {
            return true;
        }
        var rowCount = st.playerCount + 1;
        var rowH = _view.tapRowH();
        var listTop = _view.tapListTop();
        if (rowH <= 0) {
            return true;
        }
        if (y < listTop || y >= listTop + rowCount * rowH) {
            return true;
        }
        var idx = (y - listTop) / rowH;
        if (idx < 0) {
            idx = 0;
        }
        if (idx >= rowCount) {
            return true;
        }
        if (idx < st.playerCount) {
            if ((WatchUi has :TextPicker)) {
                WatchUi.pushView(
                    new WatchUi.TextPicker(st.playerNames[idx]),
                    new WallStrikePickNameDelegate(idx),
                    WatchUi.SLIDE_DOWN
                );
            }
            return true;
        }
        st.setupComplete = true;
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }
}

//! Do not call popView here: CIQ dismisses TextPicker after this returns; extra pop crashes.
class WallStrikePickNameDelegate extends WatchUi.TextPickerDelegate {

    var _index as Number;

    function initialize(i as Number) {
        TextPickerDelegate.initialize();
        _index = i;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        var st = appWallState();
        st.playerNames[_index] = text;
        WatchUi.requestUpdate();
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.requestUpdate();
        return true;
    }
}
