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
using Toybox.Activity;

var timer1 = null;
var stepsCount = 0;
var accel = null;

var stride_length = 0; //length of walked steps in meters
var STEP_LENGTH = 0.95; //users walking step length in meters
var SENSITIVITY = 150; //minimum absolute value deviation from the mean+deviation
var BETA = 0.01; //low pass filter coeficient

//fit logging and session
var mLogger = null;
var fitField_distance = null;
var fitField_speed = null;
var fitField_cadence = null;
var mSession = null;

var current_direction = 0;
var MAX_SAMPLES = 20;
var x_history = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var records_recorded = 0;
var x_filtered = new[MAX_SAMPLES];
var mean;
var variance;

var MAX_IDLE_TIME = 1500; //1.5 seconds idle time max
var laststep_time = null;

var last_maximum = 0;
var last_minimum = 0;


var last_recorded_speed_steps = 0;
var last_recorded_speed_time = Sys.getTimer();
var last_recorded_cadence = 0;
var last_recorded_speed = 0;
var SPEED_RECORDING_STEP = 2000;

//for System.println logging variables
var counter = 0;
var buffer = "";

class EllipticalView extends Ui.View {

	function handleSettingsChanged(){
		SENSITIVITY = Application.getApp().getProperty("sensitivity_prop");
		MAX_SAMPLES = Application.getApp().getProperty("samples_prop");
	}
	    
    function secondPassedEvent(){
    	countSteps();
    	
    	stride_length = stepsCount * STEP_LENGTH;
    	calc_speed_and_cadence();
    	  
	    updateFitData();
	    	    
		Ui.requestUpdate();
	}
	
	function calc_speed_and_cadence(){
		var delta = Sys.getTimer() - last_recorded_speed_time;
		
		if(delta > SPEED_RECORDING_STEP){
			last_recorded_speed = ((stepsCount-last_recorded_speed_steps) * STEP_LENGTH*1000)/delta; //m/s
			last_recorded_cadence = ((stepsCount - last_recorded_speed_steps)/delta)*60000; //rpm
			
			last_recorded_speed_steps = stepsCount;
			last_recorded_speed_time = Sys.getTimer();
		}
	}
	
	function updateFitData(){
		
		fitField_distance.setData(stride_length);
		fitField_speed.setData(last_recorded_speed);
		fitField_cadence.setData(last_recorded_cadence);
	}
	
	function countSteps(){
		var info = Sensor.getInfo();
    	
    	accel = info.accel;
    	
    	
	    	if (info has :accel && info.accel != null) {	    	
		    	var x_accel = accel[0];
		    	var y_accel = accel[1];
		    	var z_accel = accel[2];		    	 
		    	
		    	
		    //	{var x_accel = Math.sin(counter);
		    	
		    	var filtered_x_accel = store_x_and_calc(x_accel);
		    			    			    	
		    				    	
		    	var new_direction = direction(current_direction, filtered_x_accel, mean, variance);
		    	
		    	if(new_direction != current_direction && new_direction != 0){
		    		if(laststep_time != null &&
		    			Sys.getTimer() - laststep_time < MAX_IDLE_TIME){
		    			stepsCount++;
		    		}else{
		    			/*ommit this step increment because MAX_IDLE_TIME expired,
			    		previous step shouldn't have been counted*/
			    		System.println("ommiting last step");
		    		}
		    		
		    		laststep_time = Sys.getTimer(); 
		    		
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
		if(x_accel - (variance + mean) > SENSITIVITY){
				return 1;			
		}if(x_accel- (variance - mean) < -1 * SENSITIVITY){
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
        	:sport=>ActivityRecording.SPORT_RUNNING,
        	:subSport=>ActivityRecording.SUB_SPORT_GENERIC 
        	});
                       
        fitField_distance = mSession.createField("distance", 0, FitContributor.DATA_TYPE_FLOAT,  
        { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"m", :nativeNum=>5}); 
        
        fitField_speed = mSession.createField("speed", 1, FitContributor.DATA_TYPE_FLOAT,  
        { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"m/s", :nativeNum=>6}); 
        
         fitField_cadence = mSession.createField("cadence", 2, FitContributor.DATA_TYPE_FLOAT,  
        { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"rpm", :nativeNum=>4}); 
        
        handleSettingsChanged(); //load properties
    }
    
  	function startLogging() {
    	mSession.start();
	}
	
	function saveLogging() {
    	mSession.save();
	}
		
	function stopLogging() {
    	mSession.stop();
	}

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
        
        var pom = stride_length.format("%2d")+"m";
        dc.drawText( dc.getWidth()/2, (dc.getHeight() / 2) + 20, Gfx.FONT_SYSTEM_LARGE, pom, Gfx.TEXT_JUSTIFY_CENTER );
        
        var info = Activity.getActivityInfo();
        var calories = "";        
        
        if(info != null){
        	calories = info.calories;
        	if(calories == null){
        		calories = 0;
        	}
        }
        dc.drawText( dc.getWidth()/2, (dc.getHeight() / 2) + -60, Gfx.FONT_SYSTEM_LARGE, calories, Gfx.TEXT_JUSTIFY_CENTER );
        
        dc.drawText( dc.getWidth()/2, (dc.getHeight() / 2) + -100, Gfx.FONT_SYSTEM_LARGE, last_recorded_speed, Gfx.TEXT_JUSTIFY_CENTER );
        //dc.drawText( dc.getWidth()/2, (dc.getHeight() / 2)+10, Gfx.FONT_SMALL, getDebugData(), Gfx.TEXT_JUSTIFY_CENTER );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    	stopLogging();    	
    }

	function vibrate(){
  		if (Attention has :playTone) {
	    	Attention.playTone(Attention.TONE_LOUD_BEEP);
		}
	}
}
