package  {
	
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;	

	import flash.utils.getTimer;

	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;	
	import flash.events.*;
	
	import flash.utils.Timer;
	import flash.errors.IOError;
	import flash.media.Sound;
	import flash.geom.Matrix;
	
	public class int_2012_video extends MovieClip {
		
		public function int_2012_video(Z:*) {
			
			this.mouseEnabled = false;
			this.mouseChildren = false;
			
//			var waitSeek:Boolean = false;
			var running:Boolean = false;
			Z.autoReady = false;
			
			var url:String = Z.buildAssetURLRequest(Z.parameters.asset).url;
			
			var preload = "" + Z.parameters.preload != "false";
			var bufferTime = "" + Z.parameters.bufferTime != "" ? 0 + Z.parameters.bufferTime : 1;
			var loop = "" + Z.parameters.loop == "true";
			var paused = "" + Z.parameters.paused == "true";
			var volume = "" + Z.parameters.volumeValue != "" ? Z.hat.magicast_resolveAndGetValue(Z.parameters.volumeValue[0]) : null;
			if (volume === null) volume = 1;
			else if (isNaN(volume)) volume = 0;
			else volume = volume / 100
			
			var cues = new Array();
			var cueIndex:int = 0;
			for (var i=0 ; i<Z.parameters.cue.length() ; i++) {
				var cue = Z.parameters.cue[i];
				// OLD SYNTAX
				// NEW SYNTAX
				cues.push({time: parseFloat("" + cue.time), eventName: "" + cue.eventName, name: "" + cue.name});
			}
			var waitLoop:Boolean = false;
			var metaDataReceived:Boolean = false;
			var startReceived:Boolean = false;
			var frameReceived:Boolean = false;
			var seekNotified:Boolean = false;
			var framerate:Number;
			var duration:Number;
			
			var lastTime:Number = 0;
			var stuckGetTimer:Number = 0;
			
			var testBmd:BitmapData;
			
			var completeTriggered:Boolean = false;
			
			var loadRetry:Boolean = true;
			var retryTime:Number = 5;
			var retryTimer:Timer;
			
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
				
				var rect:Rectangle;
				var m:Matrix;
				   
				if (!running) {
					
					if (!frameReceived) {
						if (!testBmd) {
							testBmd = new BitmapData(vid.width, vid.height, true, 0x00000000);
						}
						m = new Matrix();
						m.scale(vid.width / 320, vid.height / 240);
						testBmd.draw(vid, m);
						rect = testBmd.getColorBoundsRect(0xffffffff, 0x00000000, false);
						if (rect.width && rect.height) {
							testBmd.dispose();
							testBmd = null;
							frameReceived = true;
							ns.pause();
						}
					}
					
					if (frameReceived && metaDataReceived) {
						if (preload) {
							if (ns.bytesLoaded > 0 && ns.bytesLoaded == ns.bytesTotal) {
								Z.ready();
							}
						} else {
							Z.ready();
						}
					}
					
				} else {
										
//					trace("bytes: " + ns.bytesLoaded + " / " + ns.bytesTotal + " fps: " + ns.currentFPS + " time: " + ns.time + " duration: " + duration + " bufferTime: " + ns.bufferTime + " bufferLength: " + ns.bufferLength + " fromStuckGetTimer: " + fromStuckGetTimer);

					if (!paused &&
						ns.bytesLoaded > 0 &&
						ns.bytesLoaded == ns.bytesTotal) {

						checkCues(ns.time);
							
						var tempGetTimer:int = getTimer();
						if (ns.time != lastTime) {
							stuckGetTimer = tempGetTimer;
						}
						var fromStuckGetTimer:Number = stuckGetTimer > 0 ? (tempGetTimer - stuckGetTimer) / 1000 : 0;
						lastTime = ns.time;
						
						if (loop) {
							if ((ns.time + fromStuckGetTimer) >= duration) {
								if (!waitLoop) {
									waitLoop = true;
									seekNotified = false;
									var bmd:BitmapData = new BitmapData(vid.videoWidth, vid.videoHeight, true, 0x00000000);
									m = new Matrix();
									m.scale(vid.width / 320, vid.height / 240);
									bmd.draw(vid, m);
									bm.bitmapData = bmd;
									bm.smoothing = true;
									bm.width = vid.width;
									bm.height = vid.height
									bm.visible = true;
									vid.visible = false;
									checkCues(duration);
									cueIndex = 0;									
									ns.play(url, 0);
								}
							} else {
								if (waitLoop) {
									if (!testBmd) {
										testBmd = new BitmapData(vid.width, vid.height, true, 0x00000000);
									}
									m = new Matrix();
									m.scale(vid.width / 320, vid.height / 240);
									testBmd.draw(vid, m);
									rect = testBmd.getColorBoundsRect(0xffffffff, 0x00000000, false);
									if (rect.width && rect.height) {
//										var diffBmpData:BitmapData = testBmd.compare(bm.bitmapData);
//										rect = diffBmpData.getColorBoundsRect(0xffffffff, 0x00000000, false);
//										if (rect.width && rect.height) {
											testBmd.dispose();
											testBmd = null;
											bm.visible = false;
											vid.visible = true;
											waitLoop = false;
											Z.hat.magicast_triggerEvent("loop");
//										}
									}
								}
							}
						} else {
							if ((ns.time + fromStuckGetTimer) >= duration) {
								if (!completeTriggered) {
									completeTriggered = true;
									checkCues(duration);
									Z.hat.magicast_triggerEvent("complete");
								}
							}			
						}
						
					}
					
				}
			}));

			Z.hat.magicast_run = function() {
				ns.soundTransform = st;
				vid.visible = true;
				running = true;
				if (!paused) {
					ns.resume();
				}
			};
			
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
//				trace("video.swf action " + name + " / " + parameters);   
				switch (name) {
					case "play":
						cueIndex = 0;
						completeTriggered = false;
						paused = false;
						ns.seek(0);
						ns.resume();
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
						completeTriggered = false;
						ns.seek(time);
						break;
					case "stop":
						cueIndex = 0;
						completeTriggered = false;
						paused = false;
						ns.seek(0);
						ns.pause();
						break;
					case "pause":
						paused = true;
						ns.pause();
						break;
					case "resume":
						paused = false;
						ns.resume();
						break;
					case "setVolume":
						volume = Z.hat.magicast_resolveAndGetValue(parameters.value[0]) / 100;
						if (running) {
							st.volume = volume;
							ns.soundTransform = st;
						}
						break;
				}
			};

			function onNetStatus(event:NetStatusEvent) {
//				trace(event.currentTarget == ns_loop);
//				trace("netStatus: " + event.info.code);
				switch (event.info.code) {
					case "NetStream.Play.StreamNotFound":
						if (loadRetry) {
							if (retryTimer == null) {
								retryTimer = new Timer(retryTime * 1000, 1);
								retryTimer.addEventListener(TimerEvent.TIMER, onTimer);
							}
							retryTimer.start();
						} else {
							Z.ready();
						}
						break;
					case "NetStream.Buffer.Empty":
						break;
					case "NetStream.Buffer.Full":
						break;
					case "NetStream.Play.Start":
						break;
					case "NetStream.Unpause.Notify":
						break;
					case "NetStream.Play.Stop":
						break;
					case "NetStream.Play.Complete":
						break;
					case "NetStream.Seek.Notify":
						seekNotified = true;
						break;
				}
			}
			function onIOError(e:IOErrorEvent) {
			}
			function onTimer(e:TimerEvent) {
				ns.play(url, 0);
			}
			
			var customClient = new Object();
			customClient.onMetaData = function(infoObject:Object):void {
				/*
				var i, j;
				for (i in infoObject) {
					trace(i + " = " + infoObject[i]);
				}
				for (i in infoObject['seekpoints']) {
					trace("seekpoint " + i + " = " + infoObject['seekpoints'][i]);
					for (j in infoObject['seekpoints'][i]) {
						trace(j + " = " + infoObject['seekpoints'][i][j]);
					}
				}
				for (i in infoObject['trackinfo']) {
					trace("trackinfo " + i + " = " + infoObject['trackinfo'][i]);
					for (j in infoObject['trackinfo'][i]) {
						trace(j + " = " + infoObject['trackinfo'][i][j]);
					}
				}
				/**/
				vid.width = infoObject['width'];
				vid.height = infoObject['height'];
				Z.hat.magicast_setBounds(new Rectangle(0, 0, vid.width, vid.height));
				duration = infoObject['duration'];
				framerate = infoObject['videoframerate'];
				if (!metaDataReceived) {
					metaDataReceived = true;
				}
			};
			customClient.asyncError = function(infoObject:Object):void {
			};
			customClient.ioError = function(infoObject:Object):void {
			};
			customClient.netStatus = function(infoObject:Object):void {
			};
			customClient.onCuePoint = function(infoObject:Object):void {
			};
			customClient.onImageData = function(infoObject:Object):void {
			};
			customClient.onPlayStatus = function(infoObject:Object):void {
			};
			customClient.onTextData = function(infoObject:Object):void {
			};
			
			var nc:NetConnection = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			nc.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			nc.connect(null);

			var ns:NetStream = new NetStream(nc);
			ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			ns.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			ns.client = customClient;
			
			ns.bufferTime = bufferTime;
			
			var st:SoundTransform = new SoundTransform();
			st.volume = volume;
			
			var st_mute:SoundTransform = new SoundTransform();
			st_mute.volume = 0;
			ns.soundTransform = st_mute;

			var vid:Video = new Video();
			vid.visible = false;
			vid.smoothing = "" + Z.parameters.smoothing != "false";
			addChild(vid);
			vid.attachNetStream(ns);
			ns.play(url, 0);
			var bm:Bitmap = new Bitmap();
			bm.visible = false;
			addChild(bm);

			Z.bind("destroy", Z.wrap(function() {
				cues = null;
				nc.close();
				nc.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				nc.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				nc = null;
				ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				ns.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				customClient = null;
				ns.client = new Object();
				ns.pause();
				ns = null;
				vid.attachNetStream(null);
				removeChild(vid);
				vid = null;
				st = null;	
				st_mute = null;
				if (bm.bitmapData) {
					bm.bitmapData.dispose();
				}
				bm = null;
				if (testBmd) {
					testBmd.dispose();
					testBmd = null;
				}
				if (retryTimer) {
					retryTimer.removeEventListener(TimerEvent.TIMER, onTimer);
					retryTimer.stop();
					retryTimer = null;
				}
			}));
		}
	}
	
}