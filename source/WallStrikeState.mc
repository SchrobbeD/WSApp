import Toybox.Lang;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.System;

//! Central session state for WallStrike / Muurkeklop.
class WallStrikeState {

    var wizardStep as Number;

    //! False until user picks boot screen (scoring vs sport only).
    var bootDone as Boolean = false;

    //! True = skip game/scores; hub is sport-focused only.
    var sportOnlyMode as Boolean = false;

    var setupComplete as Boolean;

    var playerCount as Number;
    var systemId as Number;
    var matchTotal as Number;
    var currentMatch as Number;

    var playerNames as Array<String>;
    var scores as Array<Number>;
    var lastMatchPoints as Array<Number>;
    var lastMatchOrderPoints as Array<Number>;
    var plannedScores as Array<Number>;
    var extraGamesRequested as Number;
    var eliminated as Array<Number>;

    var activeTab as Number;

    var matchesPlayed as Number;

    //! Lives setting used when systemId = 2 (Lives Elimination).
    var livesSetting as Number = 3;

    //! Tracks remaining lives per player for lives mode.
    var lives as Array<Number>;

    //! Elimination order for current match (first eliminated -> last eliminated).
    var eliminationOrder as Array<Number>;

    //! Action history stacks to support multi-step revert of eliminations/life hits.
    var historyIndex as Array<Number>;
    var historyPrevElim as Array<Number>;
    var historyPrevLives as Array<Number>;
    var historyTop as Number;

    //! Row display order for game list (contains player indices).
    var playOrder as Array<Number>;

    //! Shared FIT recording session for the whole app runtime.
    var fitSession as ActivityRecording.Session?;
    var fitPaused as Boolean = false;

    //! Restart carry-over data between finished series and next setup cycle.
    var restartPrefillNames as Array<String>;
    var restartSeedOrder as Array<Number>;
    var useRestartSeedOrder as Boolean = false;

    //! True when a round is active; false after finalization.
    var matchInProgress as Boolean = false;

    //! Button navigation (UP/DOWN = prev/next page, START = select) — see BehaviorDelegate.
    var hubBandFocus as Number = 0;
    var bootBandFocus as Number = 0;
    var namesRowFocus as Number = 0;
    var gameRowFocus as Number = 0;
    var returnToNamesAfterPicker as Boolean = false;
    var returnToNamesIndex as Number = 0;

    function initialize() {
        wizardStep = 0;
        bootDone = false;
        sportOnlyMode = false;
        setupComplete = false;
        playerCount = 4;
        systemId = 0;
        matchTotal = 8;
        currentMatch = 1;
        playerNames = [] as Array<String>;
        scores = [] as Array<Number>;
        lastMatchPoints = [] as Array<Number>;
        lastMatchOrderPoints = [] as Array<Number>;
        plannedScores = [] as Array<Number>;
        extraGamesRequested = 0;
        eliminated = [] as Array<Number>;
        activeTab = 0;
        matchesPlayed = 0;
        livesSetting = 3;
        lives = [] as Array<Number>;
        eliminationOrder = [] as Array<Number>;
        historyIndex = [] as Array<Number>;
        historyPrevElim = [] as Array<Number>;
        historyPrevLives = [] as Array<Number>;
        historyTop = 0;
        playOrder = [] as Array<Number>;
        fitSession = null;
        fitPaused = false;
        restartPrefillNames = [] as Array<String>;
        restartSeedOrder = [] as Array<Number>;
        useRestartSeedOrder = false;
        matchInProgress = false;
        hubBandFocus = 0;
        bootBandFocus = 0;
        namesRowFocus = 0;
        gameRowFocus = 0;
        returnToNamesAfterPicker = false;
        returnToNamesIndex = 0;
    }

    function resetGameArrays() as Void {
        playerNames = [] as Array<String>;
        scores = [] as Array<Number>;
        lastMatchPoints = [] as Array<Number>;
        lastMatchOrderPoints = [] as Array<Number>;
        plannedScores = [] as Array<Number>;
        extraGamesRequested = 0;
        eliminated = [] as Array<Number>;
        for (var i = 0; i < playerCount; i++) {
            if (i < restartPrefillNames.size()) {
                playerNames.add(restartPrefillNames[i]);
            } else {
                playerNames.add("P" + (i + 1));
            }
            scores.add(0);
            lastMatchPoints.add(0);
            lastMatchOrderPoints.add(0);
            eliminated.add(0);
        }
        initializeFirstGameOrder();
        startMatchRound();
    }

    function maxGamesAllowed() as Number {
        return matchTotal + extraGamesRequested;
    }

    function hasFinishedAllGames() as Boolean {
        return matchesPlayed >= maxGamesAllowed();
    }

    function requestOneExtraGame() as Void {
        extraGamesRequested++;
        startMatchRound();
        gameRowFocus = 0;
    }

    function capturePlannedScoresIfNeeded() as Void {
        if (plannedScores.size() != 0) {
            return;
        }
        if (matchesPlayed < matchTotal) {
            return;
        }
        plannedScores = [] as Array<Number>;
        for (var i = 0; i < scores.size(); i++) {
            plannedScores.add(scores[i]);
        }
    }

    function clearEliminationsForNewMatch() as Void {
        startMatchRound();
    }

    function toggleEliminated(index as Number) as Void {
        if (index < 0 || index >= playerCount) {
            return;
        }
        eliminated[index] = eliminated[index] ? 0 : 1;
    }

    function startMatchRound() as Void {
        eliminated = [] as Array<Number>;
        lives = [] as Array<Number>;
        eliminationOrder = [] as Array<Number>;
        historyIndex = [] as Array<Number>;
        historyPrevElim = [] as Array<Number>;
        historyPrevLives = [] as Array<Number>;
        historyTop = 0;
        var i = 0;
        for (i = 0; i < playerCount; i++) {
            eliminated.add(0);
            lives.add(livesSetting);
        }
        matchInProgress = true;
        if (gameRowFocus >= playerCount) {
            gameRowFocus = 0;
        }
    }

    function ensurePlayOrder() as Void {
        if (playOrder.size() == playerCount) {
            return;
        }
        playOrder = [] as Array<Number>;
        for (var i = 0; i < playerCount; i++) {
            playOrder.add(i);
        }
    }

    function randomizeFirstOrder() as Void {
        ensurePlayOrder();
        if (playOrder.size() <= 1) {
            return;
        }
        var seed = System.getTimer();
        var i = playOrder.size() - 1;
        while (i > 0) {
            // Keep j safely within [0..i] to avoid OOB on platforms where modulo can be negative.
            seed = seed + (i * 37) + 17;
            var j = seed % (i + 1);
            if (j < 0) {
                j = j + (i + 1);
            }
            var tmp = playOrder[i];
            playOrder[i] = playOrder[j];
            playOrder[j] = tmp;
            i--;
        }
    }

    function applyRestartSeedOrder() as Void {
        if (restartSeedOrder.size() != playerCount) {
            randomizeFirstOrder();
            return;
        }
        playOrder = [] as Array<Number>;
        for (var i = 0; i < restartSeedOrder.size(); i++) {
            playOrder.add(restartSeedOrder[i]);
        }
    }

    function initializeFirstGameOrder() as Void {
        if (useRestartSeedOrder) {
            applyRestartSeedOrder();
            useRestartSeedOrder = false;
        } else {
            randomizeFirstOrder();
        }
    }

    function rankOrderFromScores() as Array<Number> {
        return rankOrderFromVector(scores);
    }

    function rankOrderFromVector(points as Array<Number>) as Array<Number> {
        var order = [] as Array<Number>;
        // Preserve current play order as stable tie-break basis.
        if (playOrder.size() == playerCount) {
            for (var p = 0; p < playOrder.size(); p++) {
                order.add(playOrder[p]);
            }
        } else {
            for (var i = 0; i < playerCount; i++) {
                order.add(i);
            }
        }
        var a = 0;
        for (a = 0; a < order.size(); a++) {
            var best = a;
            var b = a + 1;
            while (b < order.size()) {
                var idxBest = order[best];
                var idxB = order[b];
                if (points[idxB] > points[idxBest]) {
                    best = b;
                }
                b++;
            }
            if (best != a) {
                var tmp = order[a];
                order[a] = order[best];
                order[best] = tmp;
            }
        }
        return order;
    }

    function splitPlayOrderForLives(index as Number, keepIndexActive as Boolean) as Array<Array<Number>> {
        var active = [] as Array<Number>;
        var out = [] as Array<Number>;
        ensurePlayOrder();
        for (var i = 0; i < playOrder.size(); i++) {
            var p = playOrder[i];
            if (keepIndexActive && p == index) {
                active.add(p);
                continue;
            }
            if (eliminated[p] != 0 || lives[p] <= 0) {
                out.add(p);
            } else {
                active.add(p);
            }
        }
        return [active, out];
    }

    function reorderForLivesLifeEvent(index as Number, eliminatedNow as Boolean) as Void {
        var split = splitPlayOrderForLives(index, eliminatedNow);
        var active = split[0];
        var out = split[1];
        var pos = -1;
        for (var i = 0; i < active.size(); i++) {
            if (active[i] == index) {
                pos = i;
                break;
            }
        }
        if (pos < 0) {
            return;
        }

        var hasPrev = active.size() > 1;
        var prev = index;
        if (hasPrev) {
            prev = active[(pos - 1 + active.size()) % active.size()];
        }

        var newActive = [] as Array<Number>;
        if (!eliminatedNow) {
            // Life lost: loser starts, player in front second, others unchanged.
            newActive.add(index);
            if (hasPrev) {
                newActive.add(prev);
            }
            // Add remaining active players in circular order after the loser.
            var j = (pos + 1) % active.size();
            while (j != pos) {
                var p = active[j];
                if (p != prev) {
                    newActive.add(p);
                }
                j = (j + 1) % active.size();
            }
            playOrder = [] as Array<Number>;
            for (var a = 0; a < newActive.size(); a++) {
                playOrder.add(newActive[a]);
            }
            for (var b = 0; b < out.size(); b++) {
                playOrder.add(out[b]);
            }
            return;
        }

        // Eliminated: player in front starts; eliminated player moves to eliminated block.
        if (hasPrev) {
            newActive.add(prev);
        }
        // Add remaining active players in circular order after eliminated player.
        var k = (pos + 1) % active.size();
        while (k != pos) {
            var q = active[k];
            if (q != prev) {
                newActive.add(q);
            }
            k = (k + 1) % active.size();
        }
        playOrder = [] as Array<Number>;
        for (var c = 0; c < newActive.size(); c++) {
            playOrder.add(newActive[c]);
        }
        playOrder.add(index);
        for (var d = 0; d < out.size(); d++) {
            playOrder.add(out[d]);
        }
    }

    function reorderForNextRoundByScores() as Void {
        if (systemId != 0 && systemId != 1) {
            return;
        }
        // Between games, ordering follows previous-game result (winner first).
        playOrder = rankOrderFromVector(lastMatchOrderPoints);
    }

    function isXDownAllowed() as Boolean {
        return playerCount >= 3;
    }

    function getXDownModeFromPlayerCount() as Number {
        if (playerCount == 8) {
            return 10;
        }
        if (playerCount == 7) {
            return 9;
        }
        if (playerCount == 6) {
            return 8;
        }
        if (playerCount == 5) {
            return 7;
        }
        if (playerCount == 4) {
            return 5;
        }
        if (playerCount == 3) {
            return 4;
        }
        return 0;
    }

    function getXDownModeLabel() as String {
        var mode = getXDownModeFromPlayerCount();
        if (mode <= 0) {
            return "invalid";
        }
        return mode + "-down";
    }

    function getSystemLabel() as String {
        if (systemId == 0) {
            return "Ascending";
        }
        if (systemId == 1) {
            return "X-Down";
        }
        return "Lives";
    }

    function getSystemDetailLabel() as String {
        if (systemId == 1) {
            return getXDownModeLabel();
        }
        if (systemId == 2) {
            return livesSetting + " lives";
        }
        return "";
    }

    function registerEliminationEvent(index as Number) as Void {
        if (index < 0 || index >= playerCount) {
            return;
        }
        if (!matchInProgress) {
            return;
        }
        if (systemId == 2) {
            if (lives[index] <= 0) {
                return;
            }
            if (historyTop < historyIndex.size()) {
                historyIndex[historyTop] = index;
                historyPrevElim[historyTop] = eliminated[index];
                historyPrevLives[historyTop] = lives[index];
            } else {
                historyIndex.add(index);
                historyPrevElim.add(eliminated[index]);
                historyPrevLives.add(lives[index]);
            }
            historyTop++;
            lives[index] = lives[index] - 1;
            if (lives[index] <= 0 && eliminated[index] == 0) {
                eliminated[index] = 1;
                eliminationOrder.add(index);
                reorderForLivesLifeEvent(index, true);
            } else {
                reorderForLivesLifeEvent(index, false);
            }
            return;
        }
        if (eliminated[index] != 0) {
            return;
        }
        if (historyTop < historyIndex.size()) {
            historyIndex[historyTop] = index;
            historyPrevElim[historyTop] = eliminated[index];
            historyPrevLives[historyTop] = 0;
        } else {
            historyIndex.add(index);
            historyPrevElim.add(eliminated[index]);
            historyPrevLives.add(0);
        }
        historyTop++;
        eliminated[index] = 1;
        eliminationOrder.add(index);
    }

    function canRevertLastElimination() as Boolean {
        return historyTop > 0;
    }

    function revertLastElimination() as Void {
        if (!canRevertLastElimination()) {
            return;
        }
        var hPos = historyTop - 1;
        var idx = historyIndex[hPos];
        var prevElim = historyPrevElim[hPos];
        var prevLives = historyPrevLives[hPos];
        historyTop = hPos;

        // If this action created a final elimination, remove that ranking entry.
        if (eliminated[idx] != 0 && prevElim == 0) {
            var eoPos = eliminationOrder.size() - 1;
            while (eoPos >= 0) {
                if (eliminationOrder[eoPos] == idx) {
                    var newOrder = [] as Array<Number>;
                    for (var k = 0; k < eliminationOrder.size(); k++) {
                        if (k != eoPos) {
                            newOrder.add(eliminationOrder[k]);
                        }
                    }
                    eliminationOrder = newOrder;
                    break;
                }
                eoPos--;
            }
        }

        eliminated[idx] = prevElim;
        if (systemId == 2) {
            lives[idx] = prevLives;
        }
    }

    function activePlayersCount() as Number {
        var c = 0;
        for (var i = 0; i < playerCount; i++) {
            if (systemId == 2) {
                if (lives[i] > 0) {
                    c++;
                }
            } else if (eliminated[i] == 0) {
                c++;
            }
        }
        return c;
    }

    function isMatchComplete() as Boolean {
        return activePlayersCount() <= 1;
    }

    function finalizeRankingOrder() as Array<Number> {
        var ranking = [] as Array<Number>;
        for (var i = 0; i < eliminationOrder.size(); i++) {
            ranking.add(eliminationOrder[i]);
        }
        for (var j = 0; j < playerCount; j++) {
            var isAlive = false;
            if (systemId == 2) {
                isAlive = lives[j] > 0;
            } else {
                isAlive = eliminated[j] == 0;
            }
            if (isAlive) {
                ranking.add(j);
            }
        }
        return ranking;
    }

    function getXDownPointsVector() as Array<Number> {
        var mode = getXDownModeFromPlayerCount();
        if (mode == 10) {
            return [10, 8, 6, 5, 4, 3, 2, 1];
        }
        if (mode == 9) {
            return [9, 7, 5, 4, 3, 2, 1];
        }
        if (mode == 8) {
            return [8, 6, 4, 3, 2, 1];
        }
        if (mode == 7) {
            return [7, 5, 3, 2, 1];
        }
        if (mode == 5) {
            return [5, 3, 2, 1];
        }
        if (mode == 4) {
            return [4, 2, 1];
        }
        return [] as Array<Number>;
    }

    function applyMatchScoringBySystem() as Void {
        var matchPoints = [] as Array<Number>;
        var orderPoints = [] as Array<Number>;
        for (var m = 0; m < playerCount; m++) {
            matchPoints.add(0);
            orderPoints.add(0);
        }
        var ranking = finalizeRankingOrder();
        var n = ranking.size();
        if (n <= 0) {
            return;
        }
        var xdown = getXDownPointsVector();
        for (var i = 0; i < n; i++) {
            var idx = ranking[i];
            var place = i + 1;
            var pts = 0;
            if (systemId == 1) {
                if (i < xdown.size()) {
                    pts = xdown[i];
                }
            } else {
                // Ascending + Lives: place points (1..N) by elimination order.
                pts = place;
            }
            scores[idx] = scores[idx] + pts;
            matchPoints[idx] = pts;
            orderPoints[idx] = place;
        }
        lastMatchPoints = matchPoints;
        lastMatchOrderPoints = orderPoints;
        matchInProgress = false;
    }

    function isFitRecording() as Boolean {
        if (fitSession == null) {
            return false;
        }
        return fitSession.isRecording();
    }

    function isFitPaused() as Boolean {
        return fitSession != null && fitPaused;
    }

    function startFitRecordingIfNeeded() as Void {
        if ((Toybox has :ActivityRecording) == false) {
            return;
        }
        if (fitSession != null) {
            if (fitPaused) {
                fitSession.start();
                fitPaused = false;
            }
            return;
        }
        fitSession = ActivityRecording.createSession({
            :name => "WallStrike",
            :sport => Activity.SPORT_GENERIC,
        });
        fitSession.start();
        fitPaused = false;
    }

    function pauseFitRecordingIfNeeded() as Void {
        if (fitSession == null) {
            return;
        }
        if (fitSession.isRecording()) {
            fitSession.stop();
            fitPaused = true;
        }
    }

    function resumeFitRecordingIfPaused() as Void {
        if (fitSession == null || !fitPaused) {
            return;
        }
        fitSession.start();
        fitPaused = false;
    }

    function toggleFitPauseResume() as Void {
        if (fitSession == null) {
            startFitRecordingIfNeeded();
            return;
        }
        if (fitPaused) {
            resumeFitRecordingIfPaused();
        } else {
            pauseFitRecordingIfNeeded();
        }
    }

    function stopFitRecordingIfNeeded() as Void {
        if (fitSession == null) {
            return;
        }
        if (fitSession.isRecording()) {
            fitSession.stop();
        }
        fitSession.save();
        fitSession = null;
        fitPaused = false;
    }

    function discardFitRecordingIfNeeded() as Void {
        if (fitSession == null) {
            return;
        }
        if (fitSession.isRecording()) {
            fitSession.stop();
        }
        fitSession.discard();
        fitSession = null;
        fitPaused = false;
    }

    function prepareRestartWithSamePlayers() as Void {
        restartPrefillNames = [] as Array<String>;
        for (var i = 0; i < playerNames.size(); i++) {
            restartPrefillNames.add(playerNames[i]);
        }
        restartSeedOrder = rankOrderFromScores();
        useRestartSeedOrder = true;
        setupComplete = false;
        wizardStep = 0;
        matchesPlayed = 0;
        gameRowFocus = 0;
    }

    function resetForFreshSetupKeepNames() as Void {
        restartPrefillNames = [] as Array<String>;
        for (var i = 0; i < playerNames.size(); i++) {
            restartPrefillNames.add(playerNames[i]);
        }
        restartSeedOrder = [] as Array<Number>;
        useRestartSeedOrder = false;

        // Reset full setup/runtime defaults except names prefill.
        setupComplete = false;
        wizardStep = 0;
        systemId = 0;
        matchTotal = 8;
        livesSetting = 3;
        matchesPlayed = 0;
        gameRowFocus = 0;
        hubBandFocus = 0;
        plannedScores = [] as Array<Number>;
        extraGamesRequested = 0;

        // Clear current runtime arrays so old series data cannot leak.
        scores = [] as Array<Number>;
        lastMatchPoints = [] as Array<Number>;
        lastMatchOrderPoints = [] as Array<Number>;
        eliminated = [] as Array<Number>;
        eliminationOrder = [] as Array<Number>;
        historyIndex = [] as Array<Number>;
        historyPrevElim = [] as Array<Number>;
        historyPrevLives = [] as Array<Number>;
        historyTop = 0;
        playOrder = [] as Array<Number>;
        lives = [] as Array<Number>;
        matchInProgress = false;
    }

    function systemNeedsMatchCount() as Boolean {
        return true;
    }

    function sanitizeNameEntry(raw as String) as String {
        var s = raw;
        s = trimStringSafe(s);
        while (s.length() >= 2 && s.substring(0, 1) == "\"" && s.substring(s.length() - 1, s.length()) == "\"") {
            s = s.substring(1, s.length() - 1);
            s = trimStringSafe(s);
        }
        s = normalizeNameToken(s);
        return trimStringSafe(s);
    }

    function trimStringSafe(s as String) as String {
        if (s.length() == 0) {
            return "";
        }
        var start = 0;
        var stop = s.length();
        while (start < stop) {
            var c1 = s.substring(start, start + 1);
            if (c1 != " " && c1 != "\t" && c1 != "\n" && c1 != "\r") {
                break;
            }
            start++;
        }
        while (stop > start) {
            var c2 = s.substring(stop - 1, stop);
            if (c2 != " " && c2 != "\t" && c2 != "\n" && c2 != "\r") {
                break;
            }
            stop--;
        }
        return s.substring(start, stop);
    }

    function strEq(a as String, b as String) as Boolean {
        if (a == null || b == null) {
            return false;
        }
        if (a.length() != b.length()) {
            return false;
        }
        return a.compareTo(b) == 0;
    }

    function isDigitChar(c as String) as Boolean {
        if (c == null || c.length() == 0) {
            return false;
        }
        return strEq(c, "0") || strEq(c, "1") || strEq(c, "2") || strEq(c, "3") || strEq(c, "4") || strEq(c, "5") || strEq(c, "6") || strEq(c, "7") || strEq(c, "8") || strEq(c, "9");
    }

    function isLetterChar(c as String) as Boolean {
        if (c == null || c.length() == 0) {
            return false;
        }
        var l = c.toLower();
        return l.compareTo("a") >= 0 && l.compareTo("z") <= 0;
    }

    function isStrictWholeNumber(raw as String) as Boolean {
        if (raw.length() == 0) {
            return false;
        }
        var i = 0;
        var first = raw.substring(0, 1);
        if (strEq(first, "+") || strEq(first, "-")) {
            if (raw.length() == 1) {
                return false;
            }
            i = 1;
        }
        while (i < raw.length()) {
            if (!isDigitChar(raw.substring(i, i + 1))) {
                return false;
            }
            i++;
        }
        return true;
    }

    function parseWholeNumberStrict(raw as String) as Number? {
        if (!isStrictWholeNumber(raw)) {
            return null;
        }
        var sign = 1;
        var i = 0;
        if (raw.length() > 0) {
            var first = raw.substring(0, 1);
            if (strEq(first, "-")) {
                sign = -1;
                i = 1;
            } else if (strEq(first, "+")) {
                i = 1;
            }
        }
        var v = 0;
        while (i < raw.length()) {
            var c = raw.substring(i, i + 1);
            var d = 0;
            if (strEq(c, "0")) { d = 0; }
            else if (strEq(c, "1")) { d = 1; }
            else if (strEq(c, "2")) { d = 2; }
            else if (strEq(c, "3")) { d = 3; }
            else if (strEq(c, "4")) { d = 4; }
            else if (strEq(c, "5")) { d = 5; }
            else if (strEq(c, "6")) { d = 6; }
            else if (strEq(c, "7")) { d = 7; }
            else if (strEq(c, "8")) { d = 8; }
            else if (strEq(c, "9")) { d = 9; }
            v = (v * 10) + d;
            i++;
        }
        return v * sign;
    }

    function isAlphaNumChar(c as String) as Boolean {
        return isDigitChar(c) || isLetterChar(c);
    }

    function normalizeNameToken(raw as String) as String {
        var n = trimStringSafe(raw);
        while (n.length() > 0) {
            var first = n.substring(0, 1);
            if (isAlphaNumChar(first)) {
                break;
            }
            n = trimStringSafe(n.substring(1, n.length()));
        }
        while (n.length() > 0) {
            var last = n.substring(n.length() - 1, n.length());
            if (isAlphaNumChar(last)) {
                break;
            }
            n = trimStringSafe(n.substring(0, n.length() - 1));
        }
        return n;
    }

    function canonicalName(raw as String) as String {
        return sanitizeNameEntry(raw);
    }

    function buildPlayerStatsRaw(names as Array<Lang.Object>, counts as Array<Lang.Object>) as String {
        var raw = "";
        for (var i = 0; i < names.size() && i < counts.size(); i++) {
            var n = canonicalName(names[i].toString());
            var c = counts[i];
            if (n.length() == 0) {
                continue;
            }
            if (raw.length() > 0) {
                raw = raw + ";";
            }
            raw = raw + n + ":" + c;
        }
        return raw;
    }

    function dedupeStats(names as Array<Lang.Object>, counts as Array<Lang.Object>) as Array<Array<Lang.Object>> {
        var outNames = [] as Array<Lang.Object>;
        var outCounts = [] as Array<Lang.Object>;
        for (var i = 0; i < names.size() && i < counts.size(); i++) {
            var n = canonicalName(names[i].toString());
            if (n.length() == 0) {
                continue;
            }
            var c = counts[i] as Number;
            var key = n.toLower();
            var idx = -1;
            for (var k = 0; k < outNames.size(); k++) {
                var existing = canonicalName(outNames[k].toString()).toLower();
                if (strEq(existing, key)) {
                    idx = k;
                    break;
                }
            }
            if (idx < 0) {
                outNames.add(n);
                outCounts.add(c);
            } else if (c > (outCounts[idx] as Number)) {
                // Keep the highest observed count when cleaning corrupted duplicates.
                outCounts[idx] = c;
            }
        }
        return [outNames, outCounts];
    }

    function loadLocalPlayerStats() as Array<Array<Lang.Object>> {
        var names = [] as Array<Lang.Object>;
        var counts = [] as Array<Lang.Object>;
        var raw = "";
        var defaultsRaw = "";
        try {
            var pDef = Application.Properties.getValue("playerStatsDefaults");
            if (pDef != null) {
                defaultsRaw = pDef.toString();
            }
        } catch (eDef) {
            defaultsRaw = "";
        }
        try {
            var p = Application.Properties.getValue("playerStats");
            if (p != null) {
                raw = p.toString();
            }
        } catch (e) {
            raw = "";
        }
        // If no runtime list exists yet, seed from defaults.
        if (raw.length() == 0 && defaultsRaw.length() > 0) {
            raw = defaultsRaw;
        }
        var parsedItems = 0;
        var i = 0;
        while (i <= raw.length()) {
            var entryStart = i;
            while (i < raw.length() && !strEq(raw.substring(i, i + 1), ";")) {
                i++;
            }
            var entry = trimStringSafe(raw.substring(entryStart, i));
            if (i < raw.length()) {
                i++; // skip ';'
            } else {
                i = i + 1; // end loop
            }
            if (entry.length() == 0) {
                continue;
            }

            var sep = -1;
            var j = entry.length() - 1;
            while (j >= 0) {
                if (strEq(entry.substring(j, j + 1), ":")) {
                    sep = j;
                    break;
                }
                j--;
            }
            if (sep <= 0 || sep >= entry.length() - 1) {
                continue;
            }

            var n = canonicalName(entry.substring(0, sep));
            var cRaw = trimStringSafe(entry.substring(sep + 1, entry.length()));
            var cNum = parseWholeNumberStrict(cRaw);
            if (n.length() == 0 || cRaw.length() == 0 || cNum == null) {
                continue;
            }
            var c = 0;
            c = cNum;
            if (n.length() > 0) {
                names.add(n);
                counts.add(c);
                parsedItems++;
            }
        }
        var deduped = dedupeStats(names, counts);
        names = deduped[0];
        counts = deduped[1];
        var canonicalRaw = buildPlayerStatsRaw(names, counts);
        if (raw.compareTo(canonicalRaw) != 0) {
            saveLocalPlayerStats(names, counts);
        }
        return [names, counts];
    }

    function saveLocalPlayerStats(names as Array<Lang.Object>, counts as Array<Lang.Object>) as Void {
        var deduped = dedupeStats(names, counts);
        names = deduped[0];
        counts = deduped[1];
        var raw = buildPlayerStatsRaw(names, counts);
        try {
            Application.Properties.setValue("playerStats", raw);
        } catch (e) {
        }
    }

    function findKnownPlayerIndex(names as Array<Lang.Object>, name as String) as Number {
        var key = canonicalName(name).toLower();
        for (var i = 0; i < names.size(); i++) {
            if (canonicalName(names[i].toString()).toLower().compareTo(key) == 0) {
                return i;
            }
        }
        return -1;
    }

    function addConfiguredNameIfMissing(name as String) as Void {
        var clean = canonicalName(name);
        if (clean.length() == 0) {
            return;
        }
        var stats = loadLocalPlayerStats();
        var names = stats[0];
        var counts = stats[1];
        if (findKnownPlayerIndex(names, clean) >= 0) {
            return;
        }
        names.add(clean);
        counts.add(0);
        saveLocalPlayerStats(names, counts);
    }

    function incrementGamesForCurrentPlayers() as Void {
        var stats = loadLocalPlayerStats();
        var names = stats[0];
        var counts = stats[1];
        for (var i = 0; i < playerNames.size(); i++) {
            var clean = canonicalName(playerNames[i]);
            if (clean.length() == 0) {
                continue;
            }
            var idx = findKnownPlayerIndex(names, clean);
            if (idx < 0) {
                names.add(clean);
                counts.add(1);
            } else {
                counts[idx] = (counts[idx] as Number) + 1;
            }
        }
        saveLocalPlayerStats(names, counts);
    }

    function getGamesPlayedForKnownName(name as String) as Number {
        var clean = canonicalName(name);
        if (clean.length() == 0) {
            return 0;
        }
        var stats = loadLocalPlayerStats();
        var names = stats[0];
        var counts = stats[1];
        var idx = findKnownPlayerIndex(names, clean);
        if (idx < 0) {
            return 0;
        }
        return counts[idx] as Number;
    }

    function getConfiguredNamesByFirstLetter(letter as String) as Array<String> {
        var out = [] as Array<String>;
        if (letter == null || letter.length() == 0) {
            return out;
        }
        var wanted = letter.substring(0, 1).toUpper();
        var stats = loadLocalPlayerStats();
        var names = stats[0];
        var counts = stats[1];
        var idxs = [] as Array<Number>;
        for (var i = 0; i < names.size(); i++) {
            var n = names[i].toString();
            if (n.length() > 0 && n.substring(0, 1).toUpper().compareTo(wanted) == 0) {
                idxs.add(i);
            }
        }
        if (idxs.size() == 0) {
            // Fallback: show all known names when selected letter has none.
            for (var iAll = 0; iAll < names.size(); iAll++) {
                idxs.add(iAll);
            }
        }
        for (var a = 0; a < idxs.size(); a++) {
            var best = a;
            for (var b = a + 1; b < idxs.size(); b++) {
                var ia = idxs[best];
                var ib = idxs[b];
                if ((counts[ib] as Number) > (counts[ia] as Number)) {
                    best = b;
                }
            }
            if (best != a) {
                var t = idxs[a];
                idxs[a] = idxs[best];
                idxs[best] = t;
            }
        }
        for (var k = 0; k < idxs.size(); k++) {
            out.add(names[idxs[k]].toString());
        }
        return out;
    }

    // Temporary compatibility shim while migrating old call sites.
    function applyStubMatchScoring() as Void {
        applyMatchScoringBySystem();
    }
}