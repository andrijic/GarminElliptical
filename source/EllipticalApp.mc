using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class EllipticalApp extends App.AppBase {

	var mView = null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	mView = new EllipticalView();
        return [ mView, new EllipticalDelegate() ];
    }
    
    function onSettingsChanged(){
    	mView.handleSettingsChanged();
    }

}
