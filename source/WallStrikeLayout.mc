import Toybox.Graphics;
import Toybox.Lang;

//! Shared vertical safe zones to prevent text overlap.
function wsTopSafe() as Number {
    return 42;
}

function wsBottomSafe() as Number {
    return 24;
}

function wsContentTop() as Number {
    return wsTopSafe();
}

function wsContentBottom(dc as Graphics.Dc) as Number {
    return dc.getHeight() - wsBottomSafe();
}

function wsCenterY(yTop as Number, yBottom as Number, blockH as Number) as Number {
    var y = yTop + (yBottom - yTop - blockH) / 2;
    if (y < yTop) {
        y = yTop;
    }
    return y;
}

//! Shared list geometry helpers (used by Names and Game views).
function wsListLeftPadding() as Number {
    return 4;
}

function wsListRightPadding() as Number {
    return 4;
}

function wsListTopPadding() as Number {
    return 0;
}

function wsListBottomPadding() as Number {
    return 0;
}

function wsListLeftX() as Number {
    return wsListLeftPadding();
}

function wsListRightX(dc as Graphics.Dc) as Number {
    return dc.getWidth() - wsListRightPadding();
}

function wsListRowHeightInRange(yTop as Number, yBottom as Number, rowCount as Number, minRow as Number, maxRow as Number) as Number {
    var rows = rowCount;
    if (rows < 1) {
        rows = 1;
    }
    var rowH = (yBottom - yTop) / rows;
    if (rowH < minRow) {
        rowH = minRow;
    }
    if (maxRow > 0 && rowH > maxRow) {
        rowH = maxRow;
    }
    return rowH;
}

function wsListTopYInRange(yTop as Number, yBottom as Number, rowCount as Number, rowH as Number) as Number {
    var rows = rowCount;
    if (rows < 1) {
        rows = 1;
    }
    var blockH = rows * rowH;
    return yTop + (yBottom - yTop - blockH) / 2;
}

function wsListBottomY(listTop as Number, rowCount as Number, rowH as Number) as Number {
    return listTop + rowCount * rowH;
}
