import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function namesDrawFocusOutline(dc as Graphics.Dc, x as Number, y as Number, bw as Number, bh as Number) as Void {
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(x, y, x + bw, y);
    dc.drawLine(x, y + bh, x + bw, y + bh);
    dc.drawLine(x, y, x, y + bh);
    dc.drawLine(x + bw, y, x + bw, y + bh);
}

function namesHeaderBottom() as Number {
    return wsTopSafe();
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
        var bottomY = h - wsBottomSafe();
        var rowCount = st.playerCount + 1;
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var minRow = fhXt + 4;
        var rowH = wsListRowHeightInRange(topY, bottomY, rowCount, minRow, 40);
        var listTop = wsListTopYInRange(topY, bottomY, rowCount, rowH);
        _tapRowH = rowH;
        _tapListTop = listTop;

        var blockBottom = wsListBottomY(listTop, rowCount, rowH);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var fhSm = dc.getFontHeight(Graphics.FONT_SMALL);
        dc.drawText(mid, wsCenterY(4, topY, fhSm), Graphics.FONT_SMALL, "Names", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var left = wsListLeftX();
        var right = wsListRightX(dc);
        dc.drawLine(left, topY, right, topY);

        var i = 0;
        for (i = 0; i <= rowCount; i++) {
            var yy = listTop + i * rowH;
            dc.drawLine(left, yy, right, yy);
        }
        dc.drawLine(left, listTop, left, blockBottom);
        dc.drawLine(right, listTop, right, blockBottom);

        for (i = 0; i < st.playerCount; i++) {
            var rowTop = listTop + i * rowH;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, rowTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, st.playerNames[i], Graphics.TEXT_JUSTIFY_CENTER);
        }

        var nextTop = listTop + st.playerCount * rowH;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, nextTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, "Next", Graphics.TEXT_JUSTIFY_CENTER);

        var fr = st.namesRowFocus;
        if (fr < 0) {
            fr = 0;
        }
        if (fr > st.playerCount) {
            fr = st.playerCount;
        }
        namesDrawFocusOutline(dc, left + 2, listTop + fr * rowH, right - left - 4, rowH);

        // Intentionally no bottom helper text in names view.
    }
}

class WallStrikeNamesDelegate extends WatchUi.BehaviorDelegate {

    var _view as WallStrikeNamesView;

    function initialize(v as WallStrikeNamesView) {
        BehaviorDelegate.initialize();
        _view = v;
    }

    function namesActivateIndex(st as WallStrikeState, idx as Number) as Void {
        if (idx < st.playerCount) {
            var pv = new WallStrikeNamePickerSwipeView(idx);
            WatchUi.pushView(pv, new WallStrikeNamePickerSwipeDelegate(pv), WatchUi.SLIDE_LEFT);
            return;
        }
        st.setupComplete = true;
        st.startFitRecordingIfNeeded();
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_LEFT);
    }

    function onPreviousPage() as Boolean {
        var st = appWallState();
        var maxR = st.playerCount;
        st.namesRowFocus--;
        if (st.namesRowFocus < 0) {
            st.namesRowFocus = maxR;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var st = appWallState();
        var maxR = st.playerCount;
        st.namesRowFocus++;
        if (st.namesRowFocus > maxR) {
            st.namesRowFocus = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var st = appWallState();
        namesActivateIndex(st, st.namesRowFocus);
        return true;
    }

    function onBack() as Boolean {
        // Treat names input as part of setup wizard flow.
        var st = appWallState();
        st.wizardStep = 0;
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
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
        st.namesRowFocus = idx;
        namesActivateIndex(st, idx);
        return true;
    }
}

//! Do not call popView here: CIQ dismisses TextPicker after this returns; extra pop crashes.
class WallStrikePickNameDelegate extends WatchUi.TextPickerDelegate {

    var _index as Number;
    var _returnToNames as Boolean;

    function initialize(i as Number, returnToNames as Boolean) {
        TextPickerDelegate.initialize();
        _index = i;
        _returnToNames = returnToNames;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        var st = appWallState();
        st.playerNames[_index] = text;
        st.addConfiguredNameIfMissing(text);
        if (_returnToNames || st.returnToNamesAfterPicker) {
            st.returnToNamesAfterPicker = false;
            st.namesRowFocus = _index;
            // TextPicker auto-dismisses on true; this explicit pop closes the underlying picker view.
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.requestUpdate();
        return true;
    }
}
