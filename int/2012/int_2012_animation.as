package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	
	public class int_2012_animation extends MovieClip {
		
		public function int_2012_animation(Z:*) {

			this.mouseEnabled = false;
			this.mouseChildren = false;			

			Z.getBytesLoaded = function() {
				return content.getBytesLoaded();
			}
			
			Z.getBytesTotal = function() {
				return content.getBytesTotal();				
			}

			var completeTriggered:Boolean = false;
			var time:Number = 0;
			var paused:Boolean = false;
			var fps:Number = 60;
			var style:XMLList;
			var loop:Boolean = true;
			var cues = new Array();
			var cueIndex:int = 0;
			if ("" + Z.parameters != "") {
				style = Z.parameters.style.children();
				if ("" + Z.parameters.fps != "") {
					fps = parseFloat("" + Z.parameters.fps);
				}
				if ("" + Z.parameters.bounds != "") {
					bounds = new Rectangle(parseFloat("" + Z.parameters.x), parseFloat("" + Z.parameters.y), parseFloat("" + Z.parameters.width), parseFloat("" + Z.parameters.height));
				}
				loop = "" + Z.parameters.loop != "false";
				paused = "" + Z.parameters.paused == "true";
				for (var i=0 ; i<Z.parameters.cue.length() ; i++) {
					var cue = Z.parameters.cue[i];
					// OLD SYNTAX
					// NEW SYNTAX
					cues.push({time: parseFloat("" + cue.time), eventName: "" + cue.eventName, name: "" + cue.name});
				}
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
			
			Z.hat.magicast_run = function() {
				Z.bind("tick", Z.wrap(function(t:Number) {
					if (mc) {
						var lastFrame:int = mc.currentFrame;
						var totalTime:Number = mc.totalFrames / fps;
						if (!paused) {
							time = time + t;
							checkCues(Math.min(time, totalTime));
							if (time > totalTime) {
								cueIndex = 0;
								if (loop) {
									while (time > totalTime) {
										time = time - totalTime;
									}
									Z.hat.magicast_triggerEvent("loop");
								} else {
									time = totalTime;
									if (!completeTriggered) {
										completeTriggered = true;
										Z.hat.magicast_triggerEvent("complete");
									}
								}
							}
						}
						var frame:int = 1 + Math.round((time / totalTime) * (mc.totalFrames - 1));
						mc.gotoAndStop(frame);
						if (frame != lastFrame) {
							renderedData = "";
						}
					}
				}));
			};
			
			Z.hat.magicast_runAction = function(method:String, parameters:XML) {
				// OLD SYNTAX
				// NEW SYNTAX
				if (method=="changeStyle" || method=="setStyle") {
					if ("" + parameters.style != "") {
						style = parameters.style[0];
					} else {
						style = null;
					}
					renderedData = "";
				}
				if (method=="changeAsset") {
					if ("" + Z.parameters.asset) {
						var newContent = Z.create(parameters.asset.children());
						newContent.bind("ready", Z.wrap(function() {
							mc = newContent.content as MovieClip;
							mc.gotoAndStop(0);
							try {
								container.removeChild(styled);
							} catch (e:Error) {
							}
							styled = null;
							content = newContent;
							bounds = content.getBounds(null);
							Z.hat.magicast_setBounds(bounds);
							renderedData = "";
						}));
					}
				}
				// OLD SYNTAX
				if (method=="changeFps") {
					fps = parseFloat("" + parameters.fps);
					time = mc.totalFrames / fps;
				}			
				// NEW SYNTAX
				if (method=="setFps") {
					fps = parseFloat(Z.hat.magicast_resolveAndGetValue(parameters.value[0]));
					time = mc.totalFrames / fps;
				}				
				if (method=="play") {
					cueIndex = 0;
					time = 0;
					paused = false;
					completeTriggered = false;
				}				
				if (method=="seek") {
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
				}	
				if (method=="pause") {
					paused = true;
				}				
				if (method=="resume") {
					paused = false;
				}				
				if (method=="stop") {
					cueIndex = 0;
					time = 0;
					paused = true;
					completeTriggered = false;
				}				
			};

			var renderedData:String = "";
			Z.hat.magicast_render = function() {			
				var calculations:* = Z.hat.magicast_calculations;
				
				container.x = calculations.x;
				container.y = calculations.y;
				container.alpha = calculations.alpha;
				container.scaleX = calculations.scaleX;
				container.scaleY = calculations.scaleY;
				
				var data:String = "." + calculations.width + "." + calculations.height + "." + calculations.rotation;
				if (renderedData != data) {
					content.setReferencePoint(bounds.x + calculations.referenceX, bounds.y + calculations.referenceY);
					if (bounds.width) {
						content.scaleX = calculations.width / bounds.width;
					}
					if (bounds.height) {
						content.scaleY = calculations.height / bounds.height;
					}
					content.rotation = calculations.rotation;
					if (styled) {
						Z.styler.update(styled, content, style);
					} else {
						styled = Z.styler.create(content, style);
						container.addChild(styled);
					}
					renderedData = data;
				}
			}
			
			var type:String = "";
			if (Z.parameters.type != undefined) {
				type = Z.parameters.type;
			}
			
			var container = new Sprite();
			addChild(container);
			var styled:*;			
			var content:*;
			var mc:MovieClip;
								
			var bounds:Rectangle;
								
			if ("" + Z.parameters.asset) {
				content = Z.create(Z.parameters.asset.children());
				content.bind("loadComplete", Z.wrap(function() {
					mc = content.content as MovieClip;
					mc.gotoAndStop(0);
					bounds = content.getBounds(null);
					Z.hat.magicast_setBounds(bounds);
					Z.ready();
				}));
				Z.autoReady = false;
			}
			
			/*
			Z.bind("destroy", Z.wrap(function() {
			});
			*/
		}
	}
	
}
