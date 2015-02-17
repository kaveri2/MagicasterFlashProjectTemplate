package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.media.Camera;
	import flash.media.CameraPosition;
	import flash.media.Video;
	import flash.events.ActivityEvent;
	import flash.events.StatusEvent;
	import flash.utils.setTimeout;
	
	public class int_2013_camera extends MovieClip {
		
		public function int_2013_camera(Z:*) { 
		
			var i:int;
		
 			var vid:Video = new Video();
			
			var cam:Camera;
			
//			var quality:int = "" + Z.parameters.quality != "" ? 0 + Z.parameters.quality : 80;
			var fps:int = "" + Z.parameters.fps != "" ? 0 + Z.parameters.fps : 25;
			var w:int = "" + Z.parameters.width != "" ? 0 + Z.parameters.width : 320;
			var h:int = "" + Z.parameters.height != "" ? 0 + Z.parameters.height : 240;
			var position:String = "" + Z.parameters.position;
			
			var lastThresholdEvent:String = "";
			var thresholds:Array = new Array();
			for (i=0 ; i<Z.parameters.threshold.length() ; i++) {
				thresholds.push({value: parseFloat(Z.parameters.threshold[i].value), name: "" + Z.parameters.threshold[i].name});
			}			
 			
			var bmd:BitmapData;
			var bm:Bitmap;

			bmd = new BitmapData(w, h, false, 0x000000);
			bm = new Bitmap(bmd);
			addChild(bm);
						
			Z.hat.magicast_run = function() {
				
				if (Camera.isSupported)
				{
					var found:Boolean = false;
					if (position) {
						for (i=0; i<Camera.names.length; i++) {
							cam = Camera.getCamera(String(i));
							if (cam) {
								try {
									if ((position == "front" && cam.position == CameraPosition.FRONT) || 
										(position == "back" && cam.position == CameraPosition.BACK)
										) {
										found = true;
										break;
									}
								} catch (e:Error) {
								}
							}
						}
					}
					
					if (!found) {
						cam = Camera.getCamera();
					}
					
					if (cam) {
						cam.setMotionLevel(0);
//						cam.setQuality(0, quality);
						cam.setMode(w, h, fps);
						
						bmd = new BitmapData(cam.width, cam.height);
						bm.bitmapData = bmd;
						Z.hat.magicast_setBounds();
//						bm.visible = false;

						vid = new Video(cam.width, cam.height);
						addChild(vid);
						vid.attachCamera(cam);
//						vid.visible = true;

						// required for activityLevel to be available
						Z.wrapEventListener(cam, ActivityEvent.ACTIVITY, function(event:ActivityEvent) {
						});
						Z.wrapEventListener(cam, StatusEvent.STATUS, function(event:StatusEvent) {
							switch (event.code) {
								case "Camera.Unmuted":
									Z.hat.magicast_triggerEvent("changeUnmuted");
									break;
								case "Camera.Muted":
									Z.hat.magicast_triggerEvent("changeMuted");
									break;
							}				
						});
						
				   }
				}
				
				var firstTick:Boolean = true;
				Z.bind("tick", function(time:Number) {
					
					if (firstTick) {
						if (cam==null) {
						Z.hat.magicast_triggerEvent("beginNull");					
						} else {	
							if (cam.muted) {
								Z.hat.magicast_triggerEvent("beginMuted");
							} else {
								Z.hat.magicast_triggerEvent("beginUnmuted");
							}
						}
						firstTick = false;
					}
					
					if (cam != null && paused==false) {
						if (thresholds.length>0) {
							var t:Number = cam.activityLevel / 100;
							var event:String = "threshold_";
							for (var i:int=0 ; i<thresholds.length ; i++) {
								if (t > thresholds[i].value) {
									event = "threshold_" + thresholds[i].name;
								}
							}
							if (event != lastThresholdEvent) {
								Z.hat.magicast_triggerEvent(event);
							}
							lastThresholdEvent = event;
						}
					} else {
						lastThresholdEvent = "";					
					}
				});
			};
			
			var paused:Boolean = false;
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				if (cam != null) {
					switch (name) {
						case "pause":
							paused = true;
							try {
								cam.drawToBitmapData(bmd);
							} catch (e:Error) {
								bmd.draw(vid);
							}
							vid.visible = false;
//							bm.visible = true;
							break;
						case "resume":
							paused = false;
							vid.visible = true;
//							bm.visible = false;
							break;
					}
				}
			};
		}
	}
}
