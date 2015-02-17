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
			
			var volume = "" + Z.parameters.volumeValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.volumeValue[0]) : null;
			if (volume === null) volume = 1;
			else if (isNaN(volume)) volume = 0;
			else volume = volume / 100
			var panning = "" + Z.parameters.panningValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.panningValue[0]) : null;
			if (panning === null) panning = 0;
			else if (isNaN(panning)) panning = 0;
			else panning = panning / 100
			
			var skip:uint = 576;
			
			var cues = new Array();
			var cueIndex:int = 0;
			for (i=0 ; i<xml.cue.length() ; i++) {
				var cue = xml.cue[i];
				cues.push({time: parseFloat("" + cue.time), eventName: "" + cue.eventName, name: "" + cue.name});
			}
			
			var time:Number = 0;
			
			var ba:ByteArray = new ByteArray();
			
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
			
			Z.bind("tick", Z.wrap(function(t:Number) {
				if (soundChannel) {
					if (Z.hat.magicast_properties["volume"] != null) {
						volume = Z.hat.magicast_properties["volume"] / 100;
					}
					if (Z.hat.magicast_properties["panning"] != null) {
						panning = Z.hat.magicast_properties["panning"] / 100;
					}
					soundChannel.soundTransform = new SoundTransform(volume, panning)
					var soundChannelTime:Number = time + soundChannel.position / 1000;
					if (soundChannelTime > duration) {
						checkCues(duration);
						cueIndex = 0;
						soundChannelTime = soundChannelTime - duration;
						if (loop) {
							checkCues(soundChannelTime);
							Z.hat.magicast_triggerEvent("loop");
						} else {
							Z.hat.magicast_triggerEvent("complete");
							soundChannel.stop();
							soundChannel = null;
						}
					} else {
						checkCues(soundChannelTime);
					}
				}
			}));
			
			var soundChannel:SoundChannel;
			function soundPlay(t:Number) {
				time = t;
				ba.position = (skip + (time * 44100)) * 8;
				soundChannel = s.play();
				soundChannel.soundTransform = new SoundTransform(volume, panning);
			}
			
			Z.hat.magicast_run = function() {
				if (!beginPaused) {
					soundPlay(0);
				}
			};
			
			var pauseTime:Number = 0;
			
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
						cueIndex = 0;
						soundChannel.stop();
						soundChannel = null;
						break;
					case "pause":
						pauseTime = time + soundChannel.position / 1000;
						soundChannel.stop();
						soundChannel = null;
						break;
					case "resume":
						soundPlay(pauseTime);
						break;
					case "setVolume":
						volume = Z.hat.magicast_resolveAndGetValue(parameters.value[0]) / 100;
						if (soundChannel) {
							soundChannel.soundTransform = new SoundTransform(volume, panning);
						}
						break;
					case "setPanning":
						panning = Z.hat.magicast_resolveAndGetValue(parameters.value[0]) / 100;
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
				duration = sound.length / 1000;
				sound.extract(ba, sound.length * 44.1, 0);
				sound.removeEventListener(Event.COMPLETE, onComplete);
				sound.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				sound = null;
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
			
			var s:Sound = new Sound();
			Z.wrapEventListener(s, SampleDataEvent.SAMPLE_DATA, function(e:SampleDataEvent):void {
				
				var samplesLeft:int = (ba.length - ba.position) / 8;
				
				if (samplesLeft < 8192) {
					ba.readBytes(e.data, 0, samplesLeft * 8);
					if (loop) {
						ba.position = skip * 8;
						ba.readBytes(e.data, samplesLeft * 8, (8192 - samplesLeft) * 8);
					}
				} else {
					ba.readBytes(e.data, 0, 8192 * 8);
				}
				
				e.data.position = e.data.length;
			});
			
			Z.bind("destroy", function() {
				ba.clear();
				ba = null;
				if (sound) {
					sound.removeEventListener(Event.COMPLETE, onComplete);
					sound.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
					sound = null;
				}
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