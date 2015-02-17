package  {
	
	import flash.display.MovieClip;
	import flash.events.ActivityEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.media.MicrophoneEnhancedOptions;
	import flash.media.MicrophoneEnhancedMode;
	import flash.media.SoundTransform;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	public class int_2013_microphone extends MovieClip {
		
		public function int_2013_microphone(Z:*) { 
			
			// from Leimu
			var lastLevelTimer:int = -1000;
			var history:Array = new Array();
			var min:Number = 101;
			var max:Number = -1;
			var avg:Number = 0;
			var globalMin:Number = 101;
			var globalMax:Number = -1;
			var globalMaxKikka:Number = 100;
			var accCount:Number = 0;
			var accSum:Number = 0;
			var accMin:Number = 101;
			var accMax:Number = -1;
			var norm:Number = 0;
			
			var gain:Number = 0;
					
			var volume = "" + Z.parameters.volumeValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.volumeValue[0]) : null;
			if (volume === null) volume = 1;
			else if (isNaN(volume)) volume = 0;
			else volume = volume / 100
			var loopBack:Boolean = "" + Z.parameters.loopBack == "true";
			var echoSuppression:Boolean = "" + Z.parameters.echoSuppression == "true";
			
			var enhanced:Boolean = false;
//			var mic:Microphone;
			var mic:Microphone = Microphone.getEnhancedMicrophone();
			if (!mic) {
				mic = Microphone.getMicrophone();
			} else {
				enhanced = true;
			}
			
			// mic must be muted until magicast_run is called
			if (mic!=null) {
				var st:SoundTransform = new SoundTransform(0);
				mic.soundTransform = st;
			}
			
			var lastThresholdEventName:String = "";
			var thresholds:Array = new Array();
			for (var i:int=0 ; i<Z.parameters.threshold.length() ; i++) {
				thresholds.push({value: parseFloat(Z.parameters.threshold[i].value), name: "" + Z.parameters.threshold[i].name});
			}
			
			function update() {
				if (mic!=null) {
					var st:SoundTransform = new SoundTransform(loopBack ? volume : 0);
					mic.soundTransform = st;
					if (!enhanced) {
						mic.setUseEchoSuppression(echoSuppression);
					} else {
						var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
						options.mode = echoSuppression ? MicrophoneEnhancedMode.FULL_DUPLEX : MicrophoneEnhancedMode.OFF;
						mic.enhancedOptions = options;					
					}
				}
			}

			Z.hat.magicast_run = function() {
				
				if (mic) {
					mic.gain = 50;
					mic.setSilenceLevel(0);
					mic.setLoopBack(true);
					Z.wrapEventListener(mic, ActivityEvent.ACTIVITY, function(event:ActivityEvent) {
					});
					Z.wrapEventListener(mic, StatusEvent.STATUS, function(event:StatusEvent) {
						switch (event.code) {
							case "Microphone.Unmuted":
								Z.hat.magicast_triggerEvent("changeUnmuted");
								break;
							case "Microphone.Muted":
								Z.hat.magicast_triggerEvent("changeMuted");
								break;
						}									
					});
					update();
				}
				
				var firstTick:Boolean = true;
				Z.bind("tick", function(time:Number) {
									
					if (firstTick) {
						if (mic==null) {
							Z.hat.magicast_triggerEvent("beginNull");					
						} else {	
							if (mic.muted) {
								Z.hat.magicast_triggerEvent("beginMuted");
							} else {
								Z.hat.magicast_triggerEvent("beginUnmuted");
							}
						}
						firstTick = false;
					}
					
					if (mic != null) {

						// slowly decrease the globalMaxKikka
						globalMaxKikka = globalMaxKikka - (time * (100 / 300)) ; // 300 seconds

						var i:int;

						// from Leimu
						var al = mic.activityLevel;						
						if (al>-1) {		
							// reset if gain has been changed manually
							if (mic.gain != gain) {
								gain = mic.gain;
								globalMin = 101;
								globalMax = -1;
								avg = 0;
							}
							accCount = accCount + 1;
							accSum = accSum + al;
							if (al<accMin) accMin = al;
							if (al>accMax) accMax = al;	
							var timer:Number = getTimer();
							if (timer - lastLevelTimer > 100) {
								lastLevelTimer = timer;
								history.push({avg: accSum, count: accCount, min: accMin, max: accMax});
								if (history.length > 100) { // 10 seconds
									history.shift();
								}
								avg = 0;
								min = 101;
								max = -1;
								var count = 0;
								for (i=0 ; i<history.length ; i++) {
									avg = avg + history[i].avg;
									count = count + history[i].count;
									if (history[i].min < min) min = history[i].min;
									if (history[i].max > max) max = history[i].max;
								}
								avg = avg / count;
								accCount = 0;
								accSum = 0;
								accMin = 101;
								accMax = -1;
							}
							if (al<globalMin) globalMin = al;
							if (al>globalMax) globalMax = al;
							var tmpMin:Number = (globalMin + min) / 2;
							var tmpMax:Number = (Math.max(globalMaxKikka, globalMax) + max) / 2;
							var tmpAvg:Number = (avg + (tmpMin + tmpMax) / 2) / 2;
							if (al<=tmpAvg) {
								if ((tmpAvg - tmpMin)==0) norm = 0;
								else norm = (al - tmpMin) / (tmpAvg - tmpMin);
								norm = norm / 2;
							} else {
								if ((tmpMax - tmpAvg)==0) norm = 1;
								else norm = (al - tmpAvg) / (tmpMax - tmpAvg);
								norm = 0.5 + norm / 2;
							}
						} else {
							norm = 0;
						}
						
//						trace(mic.muted + " / " + mic.activityLevel + " -> " + norm);
						
						if (thresholds.length>0) {
							var eventName:String = "threshold_";
							for (i=0 ; i<thresholds.length ; i++) {
								if (norm > thresholds[i].value) {
									eventName = "threshold_" + thresholds[i].name;
								}
							}
							if (eventName && eventName != lastThresholdEventName) {
								Z.hat.magicast_triggerEvent(eventName);
							}
							lastThresholdEventName = eventName;
						}
					}
				});
			};
						
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				switch (name) {
					case "setLoopBack":
						loopBack = "" + Z.hat.magicast_resolveAndGetValue(parameters.value.children()) == "true";
						update();
						break;
					case "setEchoSuppression":
						echoSuppression = "" + Z.hat.magicast_resolveAndGetValue(parameters.value.children()) == "true";
						update();
						break;
					case "setVolume":
						volume = Z.hat.magicast_resolveAndGetValue(parameters.value.children()) / 100;
						update();
						break;
				}
			};			
			
		}
	}
}
