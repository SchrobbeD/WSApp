import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function gameHeaderBottom() as Number {
    return wsTopSafe();
}

function gameFooterHeight() as Number {
    return wsBottomSafe();
}

function gameRowHeight(screenH as Number, playerCount as Number) as Number {
    var top = gameHeaderBottom();
    var foot = gameFooterHeight();
    var st = appWallState();
    var rows = gameRowCount(st);
    return wsListRowHeightInRange(top, screenH - foot, rows, 16, 40);
}

function gameListTopY(screenH as Number, rowCount as Number, rowH as Number) as Number {
    var top = gameHeaderBottom();
    var foot = gameFooterHeight();
    return wsListTopYInRange(top, screenH - foot, rowCount, rowH);
}

function gameHasRevertRow(st as WallStrikeState) as Boolean {
    return st.canRevertLastElimination();
}

function gameHasNextRow(st as WallStrikeState) as Boolean {
    return st.isMatchComplete();
}

function gameRowCount(st as WallStrikeState) as Number {
    var rows = st.playerCount;
    if (gameHasRevertRow(st)) {
        rows++;
    }
    if (gameHasNextRow(st)) {
        rows++;
    }
    return rows;
}

function gameRevertRowIndex(st as WallStrikeState) as Number {
    if (!gameHasRevertRow(st)) {
        return -1;
    }
    var idx = st.playerCount;
    if (gameHasNextRow(st)) {
        idx++;
    }
    return idx;
}

function gameNextRowIndex(st as WallStrikeState) as Number {
    if (!gameHasNextRow(st)) {
        return -1;
    }
    return st.playerCount;
}

function gameRowToPlayerIndex(st as WallStrikeState, row as Number) as Number {
    st.ensurePlayOrder();
    if (row < 0 || row >= st.playerCount) {
        return -1;
    }
    return st.playOrder[row];
}

class WallStrikeGameView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        var st = appWallState();
        st.ensurePlayOrder();
        if (!st.matchInProgress) {
            st.startMatchRound();
        }
        if (st.playerCount <= 0) {
            st.gameRowFocus = 0;
            return;
        }
        if (st.gameRowFocus < 0) {
            st.gameRowFocus = 0;
        }
        var rowCount = gameRowCount(st);
        if (st.gameRowFocus >= rowCount) {
            st.gameRowFocus = rowCount - 1;
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var st = appWallState();
        st.ensurePlayOrder();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = w / 2;
        var topY = gameHeaderBottom();
        var footH = gameFooterHeight();
        var rowH = gameRowHeight(h, st.playerCount);
        var rowCount = gameRowCount(st);
        var listTop = gameListTopY(h, rowCount, rowH);
        var playBottom = listTop + rowCount * rowH;
        var footTop = h - footH;
        var gameNo = st.matchesPlayed + 1;
        if (gameNo > st.matchTotal) {
            gameNo = st.matchTotal;
        }
        var gameTitle = "Game " + gameNo + "/" + st.matchTotal;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mid, 8, Graphics.FONT_SMALL, gameTitle, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var left = wsListLeftX();
        var right = wsListRightX(dc);
        dc.drawLine(left, topY, right, topY);

        if (st.matchesPlayed >= st.matchTotal) {
            var msgH = dc.getFontHeight(Graphics.FONT_XTINY) * 3 + 12;
            var cy = (h - msgH) / 2;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, cy, Graphics.FONT_XTINY, "All matches done", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, cy + dc.getFontHeight(Graphics.FONT_XTINY) + 6, Graphics.FONT_XTINY, "MENU: restart same players", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(mid, cy + 2 * dc.getFontHeight(Graphics.FONT_XTINY) + 10, Graphics.FONT_XTINY, "BACK: hub", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var fhXt = dc.getFontHeight(Graphics.FONT_XTINY);
        var i = 0;
        for (i = 0; i <= rowCount; i++) {
            var yy = listTop + i * rowH;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(left, yy, right, yy);
        }
        dc.drawLine(left, listTop, left, playBottom);
        dc.drawLine(right, listTop, right, playBottom);

        for (i = 0; i < st.playerCount; i++) {
            var rowTop = listTop + i * rowH;
            var pIdx = gameRowToPlayerIndex(st, i);
            var label = st.playerNames[pIdx];
            if (st.systemId == 2) {
                label = label + " (" + st.lives[pIdx] + "L)";
            }
            if (st.eliminated[pIdx] != 0 || (st.systemId == 2 && st.lives[pIdx] <= 0)) {
                label = label + " [OUT]";
            }
            var c = Graphics.COLOR_LT_GRAY;
            if (st.eliminated[pIdx] != 0 || (st.systemId == 2 && st.lives[pIdx] <= 0)) {
                c = Graphics.COLOR_DK_RED;
            }
            dc.setColor(c, Graphics.COLOR_TRANSPARENT);
            var ty = rowTop + (rowH - fhXt) / 2;
            dc.drawText(mid, ty, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var revertRow = gameRevertRowIndex(st);
        if (revertRow >= 0) {
            var revTop = listTop + revertRow * rowH;
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, revTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, "Revert", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var nextRow = gameNextRowIndex(st);
        if (nextRow >= 0) {
            var nextTop = listTop + nextRow * rowH;
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mid, nextTop + (rowH - fhXt) / 2, Graphics.FONT_XTINY, "Next", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var gf = st.gameRowFocus;
        if (gf >= 0 && gf < rowCount) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var grTop = listTop + gf * rowH;
            dc.drawLine(left + 2, grTop, right - 2, grTop);
            dc.drawLine(left + 2, grTop + rowH, right - 2, grTop + rowH);
            dc.drawLine(left + 2, grTop, left + 2, grTop + rowH);
            dc.drawLine(right - 2, grTop, right - 2, grTop + rowH);
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(4, footTop, w - 4, footTop);
        dc.drawLine(4, footTop, 4, h - 4);
        dc.drawLine(w - 4, footTop, w - 4, h - 4);
        dc.drawLine(4, h - 4, w - 4, h - 4);
        // Bottom helper text intentionally removed for cleaner UI.
    }
}

class WallStrikeGameDelegate extends WatchUi.BehaviorDelegate {

    var _view as WallStrikeGameView;

    function initialize(view as WallStrikeGameView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function restartFinishedSeries(st as WallStrikeState) as Void {
        st.prepareRestartWithSamePlayers();
        st.namesRowFocus = 0;
        WatchUi.switchToView(new WallStrikeWizardView(), new WallStrikeWizardDelegate(), WatchUi.SLIDE_RIGHT);
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var st = appWallState();
        st.ensurePlayOrder();
        if (st.sportOnlyMode) {
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (st.matchesPlayed >= st.matchTotal) {
            restartFinishedSeries(st);
            return true;
        }
        var xy = clickEvent.getCoordinates();
        var y = xy[1];
        var h = System.getDeviceSettings().screenHeight;
        var topY = gameHeaderBottom();
        var footTop = h - gameFooterHeight();
        if (y < topY || y >= footTop) {
            return true;
        }
        var rowCount = gameRowCount(st);
        var rowH = gameRowHeight(h, st.playerCount);
        var listTop = gameListTopY(h, rowCount, rowH);
        if (y < listTop || y >= listTop + rowCount * rowH) {
            return true;
        }
        var idx = (y - listTop) / rowH;
        if (idx < 0) {
            idx = 0;
        }
        var revertRow = gameRevertRowIndex(st);
        if (idx == revertRow) {
            st.revertLastElimination();
            var newRevertRow = gameRevertRowIndex(st);
            if (newRevertRow >= 0) {
                st.gameRowFocus = newRevertRow;
            } else {
                st.gameRowFocus = st.playerCount - 1;
            }
            WatchUi.requestUpdate();
            return true;
        }
        var nextRow = gameNextRowIndex(st);
        if (idx == nextRow) {
            st.gameRowFocus = idx;
            st.applyMatchScoringBySystem();
            st.matchesPlayed++;
            st.reorderForNextRoundByScores();
            st.startMatchRound();
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (idx >= st.playerCount) {
            return true;
        }
        st.gameRowFocus = idx;
        var pIdx = gameRowToPlayerIndex(st, idx);
        if (pIdx >= 0) {
            st.registerEliminationEvent(pIdx);
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        var st = appWallState();
        st.ensurePlayOrder();
        var rowCount = gameRowCount(st);
        if (st.sportOnlyMode || st.matchesPlayed >= st.matchTotal || rowCount <= 0) {
            return true;
        }
        st.gameRowFocus--;
        if (st.gameRowFocus < 0) {
            st.gameRowFocus = rowCount - 1;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var st = appWallState();
        st.ensurePlayOrder();
        var rowCount = gameRowCount(st);
        if (st.sportOnlyMode || st.matchesPlayed >= st.matchTotal || rowCount <= 0) {
            return true;
        }
        st.gameRowFocus++;
        if (st.gameRowFocus >= rowCount) {
            st.gameRowFocus = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var st = appWallState();
        st.ensurePlayOrder();
        if (st.sportOnlyMode || st.matchesPlayed >= st.matchTotal || st.playerCount <= 0) {
            if (st.matchesPlayed >= st.matchTotal) {
                restartFinishedSeries(st);
            }
            return true;
        }
        var revertRow = gameRevertRowIndex(st);
        if (st.gameRowFocus == revertRow) {
            st.revertLastElimination();
            var newRevertRow = gameRevertRowIndex(st);
            if (newRevertRow >= 0) {
                st.gameRowFocus = newRevertRow;
            } else {
                st.gameRowFocus = st.playerCount - 1;
            }
            WatchUi.requestUpdate();
            return true;
        }
        var nextRow = gameNextRowIndex(st);
        if (st.gameRowFocus == nextRow) {
            st.applyMatchScoringBySystem();
            st.matchesPlayed++;
            st.reorderForNextRoundByScores();
            st.startMatchRound();
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        var pIdx = gameRowToPlayerIndex(st, st.gameRowFocus);
        if (pIdx >= 0) {
            st.registerEliminationEvent(pIdx);
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onMenu() as Boolean {
        var st = appWallState();
        st.ensurePlayOrder();
        if (st.sportOnlyMode) {
            WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
            return true;
        }
        st.setupComplete = false;
        st.wizardStep = 0;
        WatchUi.switchToView(new WallStrikeWizardView(), new WallStrikeWizardDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.switchToView(new WallStrikeHubView(), new WallStrikeHubDelegate(), WatchUi.SLIDE_RIGHT);
        return true;
    }
}
