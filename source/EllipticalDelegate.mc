using Toybox.WatchUi as Ui;

class EllipticalDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), new EllipticalMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }

}