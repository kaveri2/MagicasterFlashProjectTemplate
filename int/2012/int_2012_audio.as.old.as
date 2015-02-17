package  {
	
	import flash.display.MovieClip;	
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class int_2012_audio extends MovieClip {
		
		public function int_2012_audio(Z:*) {

			Z.getBytesLoaded = function() {
				return sound.bytesLoaded;
			}
			
			Z.getBytesTotal = function() {
				return sound.bytesTotal;				
			}

			var xml;
			var i:int;
			
			var loadRetry:Boolean = true;
			var retryTime:Number = 5;
			var retryTimer:Timer;			
						
			// NEW SYNTAX
			if ("" + Z.parameters.asset) {
				xml = Z.parameters;
				
			// OLD SYNTAX
			} else {
				var weight:Number;
				var totalWeight:Number = 0;
				for (i = 0 ; i<Z.parameters.randomOption.length() ; i++) {
					weight = Number(Z.parameters.randomOption[i].attribute("weight"));
					totalWeight = totalWeight + weight;
				}
				var randomWeight = Math.random() * totalWeight;
				for (i = 0 ; i<Z.parameters.randomOption.length() ; i++) {
					weight = Number(Z.parameters.randomOption[i].attribute("weight"));
					randomWeight = randomWeight - weight;
					if (randomWeight<=0) {
						xml = Z.parameters.randomOption[i];
						break;
					}
				}
			}

			var asset = XML(xml.asset);
			var urlRequest:URLRequest = Z.buildAssetURLRequest(asset);
			var loop = "" + Z.parameters.loop == "true";
			var paused = "" + Z.parameters.paused == "true";
			var volume = "" + Z.parameters.volumeValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.volumeValue[0]) : null;
			if (volume === null) volume = 1;
			else if (isNaN(volume)) volume = 0;
			else volume = volume / 100
			
			var cues = new Array();
			var cueIndex:int = 0;
			for (i=0 ; i<Z.parameters.cue.length() ; i++) {
				var cue = Z.parameters.cue[i];
				// OLD SYNTAX
				// NEW SYNTAX
				cues.push({time: parseFloat("" + cue.time), eventName: "" + cue.eventName, name: "" + cue.name});
			}
			
			var pausePosition:Number = 0;
			
			function checkCues(time:Number) {
				var found:Boolean = true;
				while (found) {
					found = false;
					if (cueIndex < cues.length) {
						if (time > cues[cueIndex].time) {
							// OLD SYNTAX
							if (cues[cueIndex].eventName) {
								Z.hat.magicast_triggerEvent(cues[cueIndex].eventName);
							}
							// NEW SYNTAX
							if (cues[cueIndex].name) {
								var o:Object = {
									time: cues[cueIndex].time,
									name: cues[cueIndex].name
								}
								Z.hat.magicast_triggerEvent("cue", o);
								Z.hat.magicast_triggerEvent("cue_" + cues[cueIndex].name, o);
							}							
							cueIndex++;
							found = true;
						}
					}
				}				
			}			
			
			Z.bind("tick", Z.wrap(function(time:Number) {
				checkCues();
			}));
			
			function soundPlay(position:Number) {
				if (soundChannel) {
					soundChannel.stop();
				}
				soundChannel = sound.play(position, loop ? -1 : 0, new SoundTransform(volume));
				Z.wrapEventListener(soundChannel, Event.SOUND_COMPLETE, function(e:Event) {
					checkCues(sound.length / 1000);
					cueIndex = 0;
					if (loop) {
						Z.hat.magicast_triggerEvent("loop");
						soundPlay(0);
					} else {
						soundChannel = null;
						Z.hat.magicast_triggerEvent("complete");
					}
				});
			}
			
			Z.hat.magicast_run = function() {
				if (!paused) {
					soundPlay(0);
				}
			};
			
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				switch (name) {
					case "play":
						cueIndex = 0;
						pausePosition = 0;
						soundPlay(0);
						break;
					case "seek":
						var time:Number;
						pausePosition = 0;
						// OLD SYNTAX
						if ("" + parameters.time != "") {
							time = parseFloat("" + parameters.time);
						}
						// NEW SYNTAX
						if ("" + parameters.timeValue != "") {
							time = parseFloat(Z.hat.magicast_resolveAndGetValue(parameters.timeValue[0]));
						}
						soundPlay(time * 1000);
						for (var i:int=0 ; i<cues.length ; i++) {
							if (cues[i].time>time) {
								cueIndex = i;
								break;
							}
						}
						break;
					case "stop":
						cueIndex = 0;
						pausePosition = 0;
						soundChannel.stop();
						break;
					case "pause":
						pausePosition = soundChannel.position;
						soundChannel.stop();
						break;
					case "resume":
						soundPlay(pausePosition);
						break;
					case "setVolume":
						volume = Z.hat.magicast_resolveAndGetValue(parameters.value[0]) / 100;
						if (soundChannel) {
							soundChannel.soundTransform = new SoundTransform(volume);
						}
						break;
				}
			};
			
			var sound:Sound = new Sound();
			sound.addEventListener(Event.COMPLETE, onComplete);
			sound.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			function onComplete(e:Event) {
				Z.ready();
			}
			function onIOError(e:IOErrorEvent) { 
				if (loadRetry) {
					if (retryTimer == null) {
						retryTimer = new Timer(retryTime * 1000, 1);
						retryTimer.addEventListener(TimerEvent.TIMER, onTimer);
					}
					retryTimer.start();
				} else {
					Z.ready();
				}
			}
			function onTimer(e:TimerEvent) {
				sound.load(urlRequest);
			}
			var soundChannel:SoundChannel;
			sound.load(urlRequest);
			
			Z.bind("destroy", function() {
				sound.removeEventListener(Event.COMPLETE, onComplete);
				sound.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				sound = null;
				if (soundChannel) {
					soundChannel.stop();
					soundChannel = null;
				}
				if (retryTimer) {
					retryTimer.removeEventListener(TimerEvent.TIMER, onTimer);
					retryTimer.stop();
					retryTimer = null;
				}
			});
			
			Z.autoReady = false;
		}
	}
}