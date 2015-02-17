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
	import flash.events.SampleDataEvent;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
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
			
			// 8192 is buggy with iOS!
			var packetSize:int = 4096;
			
			var seek:Boolean = true;
			var empty:Boolean = false;
						
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
			var beginPaused = "" + Z.parameters.paused == "true";
			var accurate = "" + Z.parameters.accurate == "true";
			
			var volume = "" + Z.parameters.volumeValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.volumeValue[0]) : null;
			if (volume === null) volume = 100;
			else if (isNaN(volume)) volume = 0;
			Z.hat.magicast_properties["volume"] = volume;
			volume = volume / 100;
			var panning = "" + Z.parameters.panningValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.panningValue[0]) : null;
			if (panning === null) panning = 0;
			else if (isNaN(panning)) panning = 0;			
			Z.hat.magicast_properties["panning"] = panning;
			panning = panning / 100;
			
			var cues = new Array();
			var cueIndex:int = 0;
			for (i=0 ; i<xml.cue.length() ; i++) {
				var cue = xml.cue[i];
				cues.push({time: parseFloat("" + cue.time), eventName: "" + cue.eventName, name: "" + cue.name});
			}
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

			var pauseTime:Number = 0;
			
			if (accurate) {
				var accurateTime:Number = 0;
				var accurateTimeIncrease:Number;
				var onSampleDataTimer:int;
				var skip:uint = 576;
				var ba:ByteArray = new ByteArray();
				var s:Sound = new Sound();
				s.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				function onSampleData(e:SampleDataEvent):void {	
					onSampleDataTimer = getTimer();
					var samplesLeft:int = (ba.length - ba.position) / 8;					
					if (samplesLeft < packetSize) {
						ba.readBytes(e.data, 0, samplesLeft * 8);
						if (loop) {
							ba.position = skip * 8;
							ba.readBytes(e.data, samplesLeft * 8, (packetSize - samplesLeft) * 8);
						}
					} else {
						ba.readBytes(e.data, 0, packetSize * 8);
					}
					e.data.position = e.data.length;
					if (accurateTimeIncrease != -1) {
						accurateTime = accurateTime + accurateTimeIncrease;
					}
					accurateTimeIncrease = Number(e.data.length) / 44100 / 8;
				}
			}
			
			Z.bind("tick", Z.wrap(function(t:Number) {
				if (soundChannel) {
					volume = Z.hat.magicast_properties["volume"] / 100;
					panning = Z.hat.magicast_properties["panning"] / 100;
					soundChannel.soundTransform = new SoundTransform(volume, panning);
					var soundChannelTime:Number;
					if (accurate) {
						soundChannelTime = accurateTime;
						if (accurateTimeIncrease != -1) {
							soundChannelTime = soundChannelTime + (getTimer() - onSampleDataTimer) / 1000;
						}
					} else {
						soundChannelTime = soundChannel.position / 1000;
					}
					if (soundChannelTime > duration) {
						checkCues(duration);
						cueIndex = 0;
						if (loop) {
							checkCues(soundChannelTime - duration);
							Z.hat.magicast_triggerEvent("loop");
							if (accurate) {
								accurateTime = accurateTime - duration;
							}
						} else {
							Z.hat.magicast_triggerEvent("complete");
							soundStop();
						}
					} else {
						checkCues(soundChannelTime);
					}
				}
			}));		
			
			
			var soundChannel:SoundChannel;
			function onSoundComplete(e:Event) {
				checkCues(duration);
				cueIndex = 0;
				if (loop) {
					Z.hat.magicast_triggerEvent("loop");
					soundPlay(0);
				} else {
					Z.hat.magicast_triggerEvent("complete");
					soundStop();
				}
			}			
			function soundPlay(t:Number) {
				soundStop();
				if (accurate) {
					accurateTime = t;
					accurateTimeIncrease = -1;
					ba.position = (skip + (accurateTime * 44100)) * 8;
					soundChannel = s.play();
				} else {
					soundChannel = sound.play(t);
					soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				}
				volume = Z.hat.magicast_properties["volume"] / 100;
				panning = Z.hat.magicast_properties["panning"] / 100;
				soundChannel.soundTransform = new SoundTransform(volume, panning);
			}
			function soundStop() {
				if (soundChannel) {
					if (accurate) {
					} else {
						soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					}
					soundChannel.stop();
					soundChannel = null;
				}
			}
			
			Z.hat.magicast_run = function() {
				if (!beginPaused) {
					soundPlay(0);
				}
			};
			
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				switch (name) {
					case "play":
						soundPlay(0);
						break;
					case "seek":
						var time:Number;
						// OLD SYNTAX
						if ("" + parameters.time != "") {
							time = parseFloat("" + parameters.time);
						}
						// NEW SYNTAX
						if ("" + parameters.timeValue != "") {
							time = parseFloat(Z.hat.magicast_resolveAndGetValue(parameters.timeValue[0]));
						}
						for (var i:int=0 ; i<cues.length ; i++) {
							if (cues[i].time>time) {
								cueIndex = i;
								break;
							}
						}
						soundPlay(time);
						break;
					case "stop":
						pauseTime = 0;
						cueIndex = 0;
						soundStop();
						break;
					case "pause":
						pauseTime = soundChannel.position / 1000;
						if (accurate) {
							pauseTime = pauseTime + time;
						}
						soundStop();
						break;
					case "resume":
						soundPlay(pauseTime);
						break;
					case "setVolume":
						Z.hat.magicast_properties["volume"] = Z.hat.magicast_resolveAndGetValue(parameters.value[0]);
						volume = Z.hat.magicast_properties["volume"] / 100;
						if (soundChannel) {
							soundChannel.soundTransform = new SoundTransform(volume, panning);
						}
						break;
					case "setPanning":
						Z.hat.magicast_properties["panning"] = Z.hat.magicast_resolveAndGetValue(parameters.value[0]) / 100;
						panning = Z.hat.magicast_properties["panning"] / 100;
						if (soundChannel) {
							soundChannel.soundTransform = new SoundTransform(volume, panning);
						}
						break;
				}
			};
			
			var duration:Number = 0;
			var sound:Sound = new Sound();
			sound.load(urlRequest);
			sound.addEventListener(Event.COMPLETE, onComplete);
			sound.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			function onComplete(e:Event) {
				sound.removeEventListener(Event.COMPLETE, onComplete);
				sound.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				duration = sound.length / 1000;
				if (accurate) {
					sound.extract(ba, sound.length * 44.1);
					duration = (ba.length / 8 - skip) / 44100;
					sound = null;
				}
				Z.ready();
			}
			function onIOError(e:IOErrorEvent) { 
				if (loadRetry) {
					if (retryTimer == null) {
						retryTimer = new Timer(retryTime * 1000, 1);
						retryTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimer);
					}
					retryTimer.start();
				} else {
					Z.ready();
				}
			}
			function onTimer(e:TimerEvent) {
				sound.load(urlRequest);
			}
			
			Z.bind("destroy", function() {
				if (ba) {
					ba.clear();
					ba = null;
				}
				if (s) {
					s.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
					s = null;
				}
				if (sound) {
					sound.removeEventListener(Event.COMPLETE, onComplete);
					sound.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
					sound = null;
				}
				soundStop();
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