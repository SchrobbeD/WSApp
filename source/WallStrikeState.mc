import Toybox.Lang;
import Toybox.Activity;
import Toybox.ActivityRecording;
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
    }

    function resetGameArrays() as Void {
        playerNames = [] as Array<String>;
        scores = [] as Array<Number>;
        lastMatchPoints = [] as Array<Number>;
        lastMatchOrderPoints = [] as Array<Number>;
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

    function systemNeedsMatchCount() as Boolean {
        return true;
    }

    // Temporary compatibility shim while migrating old call sites.
    function applyStubMatchScoring() as Void {
        applyMatchScoringBySystem();
    }
}