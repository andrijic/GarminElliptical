using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian; 
using Toybox.Application;
using Toybox.Math;
using Toybox.System;
using Toybox.Attention;
using Toybox.System as Sys;
using Toybox.FitContributor as FitContributor;
using Toybox.ActivityRecording;

var timer1 = null;
var stepsCount = 0;
var accel = null;

var STEP_LENGTH = 0.95; //users walking step length
var SENSITIVITY = 0.1; //percent of the variance that signal is over signal's mean+variance
var BETA = 0.01; //low pass filter coeficient

//fit logging and session
var mLogger = null;
var fitField_distance = null;
var mSession = null;

var current_direction = 0;
var MAX_SAMPLES = 8;
var x_history = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
var records_recorded = 0;
var x_filtered = new[MAX_SAMPLES];
var mean;
var variance;

var last_maximum = 0;
var last_minimum = 0;

//for System.println logging variables
var counter = 0;
var buffer = "";

class EllipticalView extends Ui.View {
    
    function secondPassedEvent(){
    	countSteps();
	    updateFitData();
	    	    
		Ui.requestUpdate();
	}
	
	function updateFitData(){
		fitField_distance.setData(stepsCount * STEP_LENGTH);
	}
	
	function countSteps(){
		var info = Sensor.getInfo();
    	
    	accel = info.accel;
    	
    	
	    	//if (info has :accel && info.accel != null) {
	    	{
		    	/*var x_accel = accel[0];
		    	var y_accel = accel[1];
		    	var z_accel = accel[2];	*/	    	 
		    	
		    	var x_accel = Math.sin(counter);
		    	
		    	var filtered_x_accel = store_x_and_calc(x_accel);
		    			    			    	
		    				    	
		    	var new_direction = direction(current_direction, filtered_x_accel, mean, variance);
		    	
		    	if(new_direction != current_direction && new_direction != 0){
		    		stepsCount++;
		    		
		    		if(new_direction < 0){
		    			last_minimum = 0; //reset minimum to record latest fresh minimum values
		    		}else{
		    			last_maximum = 0; //reset maximum to record latest fresh minimum values
		    		}		    		
		    	}
		    			    	    	
		    	if(new_direction < 0){
		    		if(filtered_x_accel < last_minimum){
		    			last_minimum = filtered_x_accel; //lower minimum value detected
		    		}
		    	}else if(new_direction > 0){
		    		if(filtered_x_accel > last_maximum){
		    			last_maximum = filtered_x_accel; //higher maximum value detected
		    		}
		    	}
		    	
		    	current_direction = new_direction;
		    	
		    	counter++;
		    	if(counter>100){		    		
		    		System.println(buffer);
		    		buffer = "";
		    	}		 
		    	
		    	buffer+=(Sys.getTimer()+";"+stepsCount+";"+current_direction+";"+x_accel+";"+filtered_x_accel+";"+mean+";"+";"+variance+";"+last_maximum+";"+last_minimum+"#");
		    
	    	}
	}
	
	function store_x_and_calc(x){
		if(records_recorded < MAX_SAMPLES){
			x_history[records_recorded] = x;
		}else{
			for(var i=0;i<MAX_SAMPLES-1;i++){
				x_history[i]=x_history[i+1];
			}
			x_history[MAX_SAMPLES-1] = x;
		}
		records_recorded++;
		
		var max = MAX_SAMPLES;
		if(records_recorded < MAX_SAMPLES){
			max = records_recorded;
		}
		
		x_filtered = filter_lowpass(x_history, max);
		
		
		
		mean = calc_mean(x_filtered, max);
		variance = calc_variance(x_filtered, mean, max);	
		
		/*buffer="";
		System.println("#"+max+", mean="+mean+", variance="+variance);
		for(var j=0;j<MAX_SAMPLES;j++){
			buffer=""+x_history[j]+";"+x_filtered[j];
			System.println(buffer);
		}*/
		
		
		return x_filtered[max-1];	
	}
	
	function filter_lowpass(records, max){
		var filt = new [MAX_SAMPLES];
		
		if(max == 1){
			filt[0] = records[0];
		}else{
			filt[0] = records[0];
			for(var i=1;i<max;i++){
				filt[i] = records[i-1]*BETA + records[i]*(1 - BETA);
			}
		}
		
		return filt;
	}
	
	function calc_mean(records, max){
		
		var sum = 0;
		for(var i=0;i<max;i++){
			sum += records[i];
		}
		
		return sum/max;
	}
	
	function calc_variance(records, mean_input, max){
		
		
		var sum = 0;
		for(var i=0;i<max;i++){
			sum += Math.pow(mean_input - records[i], 2);
		}
		
		return Math.sqrt(sum)/max;
	}
	
	function abs(input){
		if(input < 0){
			return -1*input;
		}else{
			return input;
		}
	}
	
	function direction(current_direction, x_accel, mean, variance){
		if(x_accel - (variance + mean) > SENSITIVITY * variance){
				return 1;			
		}if(x_accel- (variance - mean) < -1 * SENSITIVITY * variance){
				return -1;
		}else{		
			return 0;
		}
	}
	
	function initialize() {
        View.initialize();
        
        //mLogger = new SensorLogging.SensorLogger({:enableAccelerometer => true});
        mSession = ActivityRecording.createSession({
        	:name=>"myElliptical", 
        	:sport=>ActivityRecording.SPORT_GENERIC ,
        	:subSport=>ActivityRecording.SUB_SPORT_ELLIPTICAL
        	});
                       
        fitField_distance = mSession.createField("elliptical", 0, FitContributor.DATA_TYPE_FLOAT,  
        { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"m" });//, :nativeNum=>5}); //5 ili 9
    }
    
  	function startLogging() {
    	mSession.start();
	}

	function stopLogging() {
    	mSession.stop();
	}

	function saveLogging() {
    	mSession.save();
	}
    
    /*function getDebugData(){
    	
    		return last_x+", "+last_y+", "+last_z;
    	
    }*/
	

    // Load your resources here
    function onLayout(dc) {
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
    	startLogging();
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
    	stopLogging();
    	//saveLogging();
    }

	function vibrate(){
  		if (Attention has :playTone) {
	    	Attention.playTone(Attention.TONE_LOUD_BEEP);
		}
	}
}
