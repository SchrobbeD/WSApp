import Toybox.Lang;

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
    var eliminated as Array<Number>;

    var activeTab as Number;

    var matchesPlayed as Number;

    function initialize() {
        wizardStep = 0;
        bootDone = false;
        sportOnlyMode = false;
        setupComplete = false;
        playerCount = 4;
        systemId = 0;
        matchTotal = 3;
        currentMatch = 1;
        playerNames = [] as Array<String>;
        scores = [] as Array<Number>;
        eliminated = [] as Array<Number>;
        activeTab = 0;
        matchesPlayed = 0;
    }

    function resetGameArrays() as Void {
        playerNames = [] as Array<String>;
        scores = [] as Array<Number>;
        eliminated = [] as Array<Number>;
        for (var i = 0; i < playerCount; i++) {
            playerNames.add("P" + (i + 1));
            scores.add(0);
            eliminated.add(0);
        }
    }

    function clearEliminationsForNewMatch() as Void {
        for (var i = 0; i < playerCount; i++) {
            eliminated[i] = 0;
        }
    }

    function toggleEliminated(index as Number) as Void {
        if (index < 0 || index >= playerCount) {
            return;
        }
        eliminated[index] = eliminated[index] ? 0 : 1;
    }

    function applyStubMatchScoring() as Void {
        var survivors = [] as Array<Number>;
        var i = 0;
        for (i = 0; i < playerCount; i++) {
            if (eliminated[i] == 0) {
                survivors.add(i);
            }
        }
        var n = survivors.size();
        if (n == 0) {
            return;
        }
        var place = 1;
        for (var s = 0; s < n; s++) {
            var idx = survivors[s];
            var pts = (n - place + 1) * 3;
            scores[idx] = scores[idx] + pts;
            place++;
        }
    }

    function systemNeedsMatchCount() as Boolean {
        return true;
    }

    function getSystemLabel() as String {
        if (systemId == 0) {
            return "A";
        }
        if (systemId == 1) {
            return "B";
        }
        return "C";
    }
}