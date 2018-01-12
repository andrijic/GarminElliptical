using Toybox.WatchUi as Ui;

class EllipticalDelegate extends Ui.BehaviorDelegate {
	var dialog;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), new EllipticalMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
    
    function onBack(){    	
    	    	    	
    	dialog = new Ui.Confirmation("Save activity?");
    	
        Ui.pushView(dialog, new FitSaveConfirmationDialog(), WatchUi.SLIDE_DOWN);    
        return true;    
	}
}