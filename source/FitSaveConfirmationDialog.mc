using Toybox.WatchUi as Ui;
using Toybox.System;

class FitSaveConfirmationDialog extends Ui.ConfirmationDelegate{
	 function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == 0) {
            System.println("Cancel fit save");
            mSession.discard();
        } else {
            System.println("Saving fit");            
            mSession.save();
        }
        
        System.exit();
    }
}