import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Attention;
import Toybox.Timer;
import Toybox.WatchUi;

var WS_ALPHABET = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
] as Array<String>;

function wsAlphabet() as Array<String> {
    return WS_ALPHABET;
}

class WallStrikeNamePickerSwipeView extends WatchUi.View {

    var _playerIndex as Number;
    var _letterIndex as Number;
    var _letterPos as Number;
    var _focusRow as Number;
    var _scrollTop as Number;
    var _names as Array<String>;
    var _tapRowH as Number;
    var _tapListTop as Number;
    var _tapHeaderBottom as Number;
    var _tapNewBottom as Number;

    function initialize(playerIndex as Number) {
        View.initialize();
        _playerIndex = playerIndex;
        _letterIndex = 0;
        _letterPos = 0;
        _focusRow = 0;
        _scrollTop = 0;
        _names = [] as Array<String>;
        _tapRowH = 20;
        _tapListTop = wsTopSafe();
        _tapHeaderBottom = wsTopSafe();
        _tapNewBottom = wsTopSafe();
        syncLetterToCurrentName();
        reloadNames();
    }

    function onShow() as Void {
    }

    function tapRowH() as Number {
        return _tapRowH;
    }

    function tapListTop() as Number {
        return _tapListTop;
    }

    function tapHeaderBottom() as Number {
        return _tapHeaderBottom;
    }

    function tapNewBottom() as Number {
        return _tapNewBottom;
    }

    function playerIndex() as Number {
        return _playerIndex;
    }

    function letter() as String {
        return wsAlphabet()[_letterIndex];
    }

    function letterPos() as Number {
        return _letterPos;
    }

    function wrappedIndex(i as Number) as Number {
        var n = wsAlphabet().size();
        var out = i % n;
        if (out < 0) {
            out = out + n;
        }
        return out;
    }

    function setLetterPos(pos as Number) as Void {
        var span = wsAlphabet().size() * 1000;
        var p = pos % span;
        if (p < 0) {
            p = p + span;
        }
        _letterPos = p;
        var idx = (_letterPos + 500) / 1000;
        idx = wrappedIndex(idx);
        if (idx != _letterIndex) {
            _letterIndex = idx;
            reloadNames();
        }
    }

    function snapToNearestLetter() as Void {
        setLetterPos(((_letterPos + 500) / 1000) * 1000);
    }

    function letterAtIndex(idx as Number) as String {
        return wsAlphabet()[wrappedIndex(idx)];
    }

    function letterAtOffset(delta as Number) as String {
        return letterAtIndex(_letterIndex + delta);
    }

    function totalRows() as Number {
        return _names.size();
    }

    function nameAtRow(row as Number) as String {
        var idx = row;
        if (idx < 0 || idx >= _names.size()) {
            return "";
        }
        return _names[idx];
    }

    function playedAtRow(row as Number) as Number {
        return 0;
    }

    function focusedRow() as Number {
        return _focusRow;
    }

    function setFocusedRow(row as Number) as Void {
        if (row < -2) {
            row = -2;
        }
        var maxR = totalRows() - 1;
        if (row > maxR) {
            row = maxR;
        }
        _focusRow = row;
    }

    function shiftLetter(delta as Number) as Void {
        setLetterPos(_letterPos + (delta * 1000));
    }

    function syncLetterToCurrentName() as Void {
        var st = appWallState();
        if (_playerIndex < 0 || _playerIndex >= st.playerNames.size()) {
            return;
        }
        var n = st.playerNames[_playerIndex];
        if (n == null || n.length() == 0) {
            return;
        }
        var c = n.substring(0, 1).toUpper();
        for (var i = 0; i < wsAlphabet().size(); i++) {
            if (wsAlphabet()[i] == c) {
                _letterIndex = i;
                _letterPos = i * 1000;
                return;
            }
        }
    }

    function reloadNames() as Void {
        var st = appWallState();
        var stats = st.loadLocalPlayerStats();
        var knownNames = stats[0];
        var knownCounts = stats[1];
        var wanted = letter();
        var idxs = [] as Array<Number>;
        for (var i = 0; i < knownNames.size() && i < knownCounts.size(); i++) {
            var n = knownNames[i].toString();
            if (n.length() > 0 && n.substring(0, 1).toUpper().compareTo(wanted) == 0) {
                idxs.add(i);
            }
        }
        if (idxs.size() == 0) {
            // Fallback: when no names for this letter, show full known list.
            for (var j = 0; j < knownNames.size() && j < knownCounts.size(); j++) {
                idxs.add(j);
            }
        }
        // Sort by games played desc (small lists; in-place selection sort to avoid extra allocations).
        for (var a = 0; a < idxs.size(); a++) {
            var best = a;
            for (var b = a + 1; b < idxs.size(); b++) {
                var ia = idxs[best];
                var ib = idxs[b];
                if ((knownCounts[ib] as Number) > (knownCounts[ia] as Number)) {
                    best = b;
                }
            }
            if (best != a) {
                var t = idxs[a];
                idxs[a] = idxs[best];
                idxs[best] = t;
            }
        }
        _names = [] as Array<String>;
        for (var k = 0; k < idxs.size(); k++) {
            _names.add(knownNames[idxs[k]].toString());
        }
        // Start with no selection. User can swipe up to select "New".
        _focusRow = -2;
        _scrollTop = 0;
    }

    function ensureVisibleRows(visibleRows as Number) as Void {
        if (_focusRow < 0) {
            _scrollTop = 0;
            return;
        }
        if (_focusRow < _scrollTop) {
            _scrollTop = _focusRow;
        }
        if (_focusRow >= _scrollTop + visibleRows) {
            _scrollTop = _focusRow - visibleRows + 1;
        }
        var maxTop = totalRows() - visibleRows;
        if (maxTop < 0) {
            maxTop = 0;
        }
        if (_scrollTop > maxTop) {
            _scrollTop = maxTop;
        }
        if (_scrollTop < 0) {
            _scrollTop = 0;
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var headerTop = wsTopSafe();
        var footerBottom = h - wsBottomSafe();
        var fhSm = dc.getFontHeight(Graphics.FONT_SMALL);
        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);

        var titleH = fhSm + 4;
        var letterH = fhSm + 6;
        var headerBottom = headerTop + titleH + letterH + 8;
        _tapHeaderBottom = headerBottom;
        _tapNewBottom = headerTop + titleH;
        var listTop = headerBottom;
        var rowH = wsListRowHeightInRange(listTop, footerBottom, totalRows(), fhXt + 4, 40);
        _tapRowH = rowH;
        _tapListTop = listTop;

        var left = wsListLeftX();
        var right = wsListRightX(dc);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, headerTop + 2, Graphics.FONT_SMALL, "New", Graphics.TEXT_JUSTIFY_CENTER);
        var letterY = headerTop + titleH;
        var step = w / 6;
        var base = _letterPos / 1000;
        var frac = _letterPos % 1000;
        var slide = (frac * step) / 1000;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid - 2 * step - slide, letterY, Graphics.FONT_XTINY, letterAtIndex(base - 2), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid - step - slide, letterY, Graphics.FONT_SMALL, letterAtIndex(base - 1), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid - slide, letterY, Graphics.FONT_SMALL, letterAtIndex(base), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid + step - slide, letterY, Graphics.FONT_SMALL, letterAtIndex(base + 1), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid + 2 * step - slide, letterY, Graphics.FONT_XTINY, letterAtIndex(base + 2), Graphics.TEXT_JUSTIFY_CENTER);

        var listH = footerBottom - listTop;
        var visibleRows = listH / rowH;
        if (visibleRows < 1) {
            visibleRows = 1;
        }
        ensureVisibleRows(visibleRows);

        var drawRows = visibleRows;
        if (drawRows > totalRows()) {
            drawRows = totalRows();
        }
        var drawBottom = listTop + drawRows * rowH;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i <= drawRows; i++) {
            var y = listTop + i * rowH;
            dc.drawLine(left, y, right, y);
        }
        dc.drawLine(left, listTop, left, drawBottom);
        dc.drawLine(right, listTop, right, drawBottom);

        for (var i = 0; i < drawRows; i++) {
            var row = _scrollTop + i;
            var rowTop = listTop + i * rowH;
            var player = nameAtRow(row);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, rowTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, player, Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (_focusRow < 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(left + 2, headerTop + 1, right - 2, headerTop + 1);
            dc.drawLine(left + 2, _tapNewBottom, right - 2, _tapNewBottom);
            dc.drawLine(left + 2, headerTop + 1, left + 2, _tapNewBottom);
            dc.drawLine(right - 2, headerTop + 1, right - 2, _tapNewBottom);
        }
        var focusY = listTop + (_focusRow - _scrollTop) * rowH;
        if (_focusRow >= 0 && focusY >= listTop && focusY < drawBottom) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(left + 2, focusY, right - 2, focusY);
            dc.drawLine(left + 2, focusY + rowH, right - 2, focusY + rowH);
            dc.drawLine(left + 2, focusY, left + 2, focusY + rowH);
            dc.drawLine(right - 2, focusY, right - 2, focusY + rowH);
        }
    }
}

class WallStrikeNamePickerSwipeDelegate extends WatchUi.BehaviorDelegate {

    var _view as WallStrikeNamePickerSwipeView;
    var _lastSwipeMs as Number;
    var _dragging as Boolean;
    var _lastDragX as Number;
    var _lastDragMs as Number;
    var _animPos as Number;
    var _animVel as Number;
    var _animTarget as Number;
    var _animActive as Boolean;
    var _animTimer as Timer.Timer?;
    var _lastTickMs as Number;
    var _lastFrameMs as Number;
    var _frameIntervalMs as Number;

    function initialize(view as WallStrikeNamePickerSwipeView) {
        BehaviorDelegate.initialize();
        _view = view;
        _lastSwipeMs = 0;
        _dragging = false;
        _lastDragX = 0;
        _lastDragMs = 0;
        _animPos = _view.letterPos();
        _animVel = 0;
        _animTarget = _animPos;
        _animActive = false;
        _animTimer = null;
        _lastTickMs = 0;
        _lastFrameMs = 0;
        _frameIntervalMs = 66; // ~15 FPS cap for stable watch performance.
    }

    function activateFocused() as Boolean {
        var st = appWallState();
        var pIdx = _view.playerIndex();
        if (pIdx < 0 || pIdx >= st.playerNames.size()) {
            return true;
        }
        var row = _view.focusedRow();
        if (row < 0) {
            if ((WatchUi has :TextPicker)) {
                st.returnToNamesAfterPicker = true;
                st.returnToNamesIndex = pIdx;
                WatchUi.pushView(
                    new WatchUi.TextPicker(st.playerNames[pIdx]),
                    new WallStrikePickNameDelegate(pIdx, true),
                    WatchUi.SLIDE_DOWN
                );
            }
            return true;
        }
        var selected = _view.nameAtRow(row);
        if (selected.length() > 0) {
            st.playerNames[pIdx] = selected;
            st.addConfiguredNameIfMissing(selected);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        WatchUi.requestUpdate();
        return true;
    }

    function buzzStep() as Void {
        if ((Toybox has :Attention) && (Attention has :vibrate) && (Attention has :VibeProfile)) {
            try {
                Attention.vibrate([new Attention.VibeProfile(50, 40)]);
            } catch (e) {
            }
        }
    }

    function shiftLettersWithBuzz(step as Number, hops as Number) as Void {
        var count = hops;
        if (count < 1) {
            count = 1;
        }
        _animPos = _view.letterPos();
        _animTarget = _animPos + (step * count * 1000);
        _animVel = step * 12000;
        _animActive = true;
        buzzStep();
        ensureAnimTimerRunning();
    }

    function absNum(v as Number) as Number {
        if (v < 0) {
            return -v;
        }
        return v;
    }

    function stopAnimTimer() as Void {
        if (_animTimer != null) {
            _animTimer.stop();
            _animTimer = null;
        }
    }

    function ensureAnimTimerRunning() as Void {
        if (_animTimer != null) {
            return;
        }
        _lastTickMs = System.getTimer();
        _lastFrameMs = _lastTickMs;
        _animTimer = new Timer.Timer();
        _animTimer.start(method(:onAnimTick), 40, true);
    }

    function updateAnimation(now as Number) as Boolean {
        if (!_animActive) {
            return false;
        }
        var dtMs = now - _lastTickMs;
        _lastTickMs = now;
        if (dtMs <= 0) {
            dtMs = 1;
        } else if (dtMs > 120) {
            dtMs = 120;
        }
        var dist = _animTarget - _animPos;
        var accel = (dist * 30) / 100;
        _animVel = ((_animVel * 82) / 100) + accel;
        _animPos = _animPos + ((_animVel * dtMs) / 1000);
        if (absNum(dist) < 12 && absNum(_animVel) < 120) {
            _animPos = _animTarget;
            _animVel = 0;
            _animActive = false;
        }
        _view.setLetterPos(_animPos);
        return true;
    }

    function onAnimTick() as Void {
        var now = System.getTimer();
        var changed = updateAnimation(now);
        if (!_animActive && !_dragging) {
            stopAnimTimer();
            _view.snapToNearestLetter();
            WatchUi.requestUpdate();
            return;
        }
        if (changed && (now - _lastFrameMs >= _frameIntervalMs)) {
            _lastFrameMs = now;
            WatchUi.requestUpdate();
        }
    }

    function onPreviousPage() as Boolean {
        var row = _view.focusedRow();
        if (row == -2) {
            _view.setFocusedRow(-1);
        } else if (row > 0) {
            _view.setFocusedRow(row - 1);
        } else if (row == 0) {
            _view.setFocusedRow(-1); // Up from first name => New
        } else {
            // From New, wrap to bottom of current letter list (if any)
            _view.setFocusedRow(_view.totalRows() - 1);
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var row = _view.focusedRow();
        if (row == -2) {
            if (_view.totalRows() > 0) {
                _view.setFocusedRow(0);
            } else {
                _view.setFocusedRow(-1);
            }
        } else if (row < 0) {
            if (_view.totalRows() > 0) {
                _view.setFocusedRow(0);
            } else {
                _view.setFocusedRow(-1);
            }
        } else if (row < _view.totalRows() - 1) {
            _view.setFocusedRow(row + 1);
        } else {
            // From last name, wrap back to New
            _view.setFocusedRow(-1);
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var now = System.getTimer();
        var dt = now - _lastSwipeMs;
        _lastSwipeMs = now;
        var hops = 2;
        if (dt > 0 && dt < 180) {
            hops = 7;
        } else if (dt > 0 && dt < 300) {
            hops = 5;
        } else if (dt > 0 && dt < 500) {
            hops = 3;
        }
        var dir = swipeEvent.getDirection();
        if (dir == WatchUi.SWIPE_LEFT) {
            shiftLettersWithBuzz(1, hops);
            return true;
        }
        if (dir == WatchUi.SWIPE_RIGHT) {
            shiftLettersWithBuzz(-1, hops);
            return true;
        }
        return false;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var x = dragEvent.getCoordinates()[0];
        var now = System.getTimer();
        var stepPx = System.getDeviceSettings().screenWidth / 6;
        if (stepPx <= 0) {
            stepPx = 40;
        }
        if (!_dragging) {
            _dragging = true;
            _lastDragX = x;
            _lastDragMs = now;
            _animVel = 0;
            _animActive = false;
            _animPos = _view.letterPos();
            _animTarget = _animPos;
            stopAnimTimer();
            return true;
        }
        var dx = x - _lastDragX;
        var dtMs = now - _lastDragMs;
        if (dtMs <= 0) {
            dtMs = 1;
        }
        var dLetters = -((dx * 1000) / stepPx);
        _animPos = _view.letterPos() + dLetters;
        _view.setLetterPos(_animPos);
        _animVel = (dLetters * 1000) / dtMs;
        _lastDragX = x;
        _lastDragMs = now;
        if (now - _lastFrameMs >= _frameIntervalMs) {
            _lastFrameMs = now;
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onRelease(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (!_dragging) {
            return false;
        }
        _dragging = false;
        _animPos = _view.letterPos();
        if (absNum(_animVel) > 300) {
            _animTarget = _animPos + (_animVel / 3);
            _animActive = true;
            ensureAnimTimerRunning();
        } else {
            _view.snapToNearestLetter();
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var y = clickEvent.getCoordinates()[1];
        var x = clickEvent.getCoordinates()[0];
        var w = System.getDeviceSettings().screenWidth;

        if (y < _view.tapHeaderBottom()) {
            if (y <= _view.tapNewBottom()) {
                _view.setFocusedRow(-1);
                return activateFocused();
            }
            if (x < w / 2) {
                shiftLettersWithBuzz(-1, 1);
            } else {
                shiftLettersWithBuzz(1, 1);
            }
            WatchUi.requestUpdate();
            return true;
        }

        var rowH = _view.tapRowH();
        var listTop = _view.tapListTop();
        if (rowH <= 0 || y < listTop) {
            return true;
        }
        var idx = (y - listTop) / rowH;
        if (idx < 0) {
            idx = 0;
        }
        _view.setFocusedRow(idx);
        return activateFocused();
    }

    function onSelect() as Boolean {
        return activateFocused();
    }

    function onBack() as Boolean {
        // Consume touchscreen back gesture; keep horizontal swipe for carousel.
        return true;
    }
}
