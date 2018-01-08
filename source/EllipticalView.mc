using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian; 
using Toybox.Application;
using Toybox.Math;
using Toybox.System;
using Toybox.Attention;
using Toybox.System as Sys;

var timer1 = null;
var stepsCount = 0;
var accel = null;

var SENSITIVITY = 450;
//var SAMPLES_NUM = 20;
var current_direction = 0;
//var samples = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0 ,0, 0, 0, 0, 0, 0];
var samples_recorded = 0;
var mean_sum = 0;
var ready_to_save = false;
var last_maximum = 0;
var last_minimum = 0;

var counter = 0;
var buffer = "";

class EllipticalView extends Ui.View {
    
    function secondPassedEvent(){
    	var info = Sensor.getInfo();
    	
    	accel = info.accel;
    	
    	
	    	if (info has :accel && info.accel != null) {
		    	var x_accel = accel[0];
		    	var y_accel = accel[1];
		    	var z_accel = accel[2];		    	 
		    	
		    	
		    	
		    	var samples_sum = 0;
		    	
		    	/*for(var i=0; i<SAMPLES_NUM; i++){
		    		samples_sum += samples[i];
		    	}*/
		    	
		    	//var mean = samples_sum/SAMPLES_NUM;
		    	++samples_recorded;
		    	mean_sum = mean_sum + x_accel;
		    	var mean = mean_sum/samples_recorded;
		    	
		    	counter++;
		    	if(counter>100){		    		
		    		System.println(buffer);
		    		buffer = "";
		    	}		 
		    	
		    	buffer+=(Sys.getTimer()+";"+stepsCount+";"+current_direction+";"+x_accel+";"+y_accel+";"+mean+";"+last_maximum+";"+last_minimum+"#");
		    	
		    	if(current_direction == 0){
		    		current_direction = direction(x_accel - mean);
		    	}else if(current_direction != direction(x_accel - mean)){
		    		current_direction = direction(x_accel - mean); //direction changed, record new direction
		    		ready_to_save = true;
		    		
		    		if(current_direction < 0){
		    			last_minimum = 0; //reset minimum to record latest fresh minimum values
		    		}else{
		    			last_maximum = 0; //reset maximum to record latest fresh minimum values
		    		}
		    		
		    	}
		    	
		    	if(ready_to_save == true){
		    		/* only increment step count if significant change detected*/
		    		if(current_direction < 0){
		    			if(last_maximum - x_accel > SENSITIVITY){
			    			stepsCount++;
			    			ready_to_save = false;
		    			}		    			
		    		}else if(current_direction > 0){
		    			if(x_accel - last_minimum > SENSITIVITY){
			    			stepsCount++;
			    			ready_to_save = false;
		    			}		    			
		    		}
		    	}
		    	
		    	/**recording history values, mean and maximums**/
		    	/*for(var i=0; i<SAMPLES_NUM-1; i++){
		    		samples[i] = samples[i+1];
		    	}*
		    	
		    	samples[SAMPLES_NUM-1] = x_accel;*/		    	
		    	
		    	if(current_direction < 0){
		    		if(x_accel < last_minimum){
		    			last_minimum = x_accel; //lower minimum value detected
		    		}
		    	}else if(current_direction > 0){
		    		if(x_accel > last_maximum){
		    			last_maximum = x_accel; //higher maximum value detected
		    		}
		    	}
	    	}
	    
	    
		Ui.requestUpdate();
	}
	
	function abs(input){
		if(input < 0){
			return -1*input;
		}else{
			return input;
		}
	}
	
	function direction(input){
		if(input >= 0){
			return 1;
		}else{
			return -1;
		}
	}
	
	function initialize() {
        View.initialize();
    }
    
    /*function getDebugData(){
    	
    		return last_x+", "+last_y+", "+last_z;
    	
    }*/
	

    // Load your resources here
    function onLayout(dc) {
    
    	vibrate();
        setLayout(Rez.Layouts.MainLayout(dc));
        
        if(timer1 == null){
	    	//System.println("start timer");
	    	timer1 = new Timer.Timer();
        	timer1.start(method(:secondPassedEvent), 50, true);
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE  );
        dc.clear();
        dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
        
        dc.drawText( dc.getWidth()/2, (dc.getHeight() / 2) - 20, Gfx.FONT_LARGE, stepsCount, Gfx.TEXT_JUSTIFY_CENTER );
        //dc.drawText( dc.getWidth()/2, (dc.getHeight() / 2)+10, Gfx.FONT_SMALL, getDebugData(), Gfx.TEXT_JUSTIFY_CENTER );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

	function vibrate(){
  		if (Attention has :playTone) {
	    	Attention.playTone(Attention.TONE_LOUD_BEEP);
		}
	}
}
