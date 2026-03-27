using Toybox.Graphics as Gfx;
using Toybox.WatchUi as WatchUi;

class WSAppView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(w / 2, h / 2, Gfx.FONT_XTINY, "WSApp (CIQ)", Gfx.TEXT_JUSTIFY_CENTER);
    }
}

