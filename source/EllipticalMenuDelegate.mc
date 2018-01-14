using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Math;

class EllipticalMenuDelegate extends Ui.MenuInputDelegate {

	var myPicker;
	
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :item_1) {
        	if(Ui has :NumberPicker){
            	myPicker = new Ui.NumberPicker(
                				Ui.NUMBER_PICKER_DISTANCE,
               					 0);
            	Ui.pushView(
               		myPicker,
                	new SensitivitNumberPicker(),
                	Ui.SLIDE_IMMEDIATE);
            }
        } else if (item == :item_2) {
            if(Ui has :NumberPicker){
            	myPicker = new Ui.NumberPicker(
                				Ui.NUMBER_PICKER_DISTANCE,
               					 0);
            	Ui.pushView(
               		myPicker,
                	new MaxSamplesNumberPicker(),
                	Ui.SLIDE_IMMEDIATE);
             }
        }
    }

}

class MaxSamplesNumberPicker extends Ui.NumberPickerDelegate{
	function initialize() {
        NumberPickerDelegate.initialize();
    }

    function onNumberPicked(value) {
        MAX_SAMPLES = Math.floor(value/1000); // e.g. 1000f
        System.println("new samples value: "+MAX_SAMPLES);
    }
}

class SensitivitNumberPicker extends Ui.NumberPickerDelegate{
	function initialize() {
        NumberPickerDelegate.initialize();
    }

    function onNumberPicked(value) {
        SENSITIVITY = Math.floor(value/10); // e.g. 1000f
        System.println("new sensitivity value: "+ SENSITIVITY);        
    }
}