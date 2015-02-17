package  {
	
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.events.Event;
		
	public class core_music extends MovieClip {
		
		public function core_music(Z:*) {
			Z.hat.plugin = function() {
				var extension:* = Z.createHat();
				Z.parent.registerExtension("music", extension);
							
				var stack:Array = new Array();
				
				// "master" volume & panning
				var t:SoundTransform = new SoundTransform(0.50, 0);
				
				extension.stop = function(layer:int) {
//					trace("music / stop: " + layer);
					
					// remove from stack
					if (stack[layer]) {
						if (stack[layer]["channel"]) {
							stack[layer]["channel"].removeEventListener(Event.SOUND_COMPLETE, stack[layer]["onSoundComplete"]);
							stack[layer]["onSoundComplete"] = null;
							stack[layer]["channel"].stop();
							stack[layer]["channel"] = null;
						}
						stack[layer] = null;
						refreshAudio();
					}
				};
				
				extension.play = function(id:String, layer:int) {
//					trace("music / play: " + id + " / " + layer);
					
					// if not playing already
					if (stack[layer] && stack[layer]["id"] == id) {
						return;
					}
				
					stack[layer] = new Array();
					stack[layer]["id"] = id;
					stack[layer]["position"] = 0;
					
					if (id == "silence") {
						stack[layer]["sound"] = null;
						stack[layer]["channel"] = null;	
					} else {
						stack[layer]["sound"] = new Sound();
						stack[layer]["channel"] = null;
					}
				
					switch (id) {
						case "bofori":
							stack[layer]["sound"].load(new URLRequest("http://yle.fi/bofori/assets/sound/teaserComp.mp3"));
							break;
						case "aivo":
							stack[layer]["sound"].load(new URLRequest("http://yle.fi/bofori/assets/sound/aivoComp.mp3"));
							break;
					}
				
					refreshAudio();
				};
				
				extension.playAsset = function(asset:*, layer:int) {
					trace("music / playAsset: " + asset + " / " + layer);
				};
				
				extension.setVolume = function(value:Number, layer:int) {
					trace("music / setVolume: " + value + " / " + layer);
				};
				
				extension.setGlobalVolume = function(value:Number) {
					trace("music / setGlobalVolume");
				};
				
				// return the highest layer in stack
				function highestLayer():int {
					var max = 0;
					for (var layer in stack) {
						if (stack[layer]) {
							if (layer > max) {
								max = layer;
							}
						}
					}
					return max;
				}
				
				// refresh the audio
				function refreshAudio():void {
						
					var highest:int = highestLayer();
				
//					trace("refreshAudio, highestLayer = " + highest);
					
					// go through the stack and play the highest layer, stop the rest.
					for (var layer in stack) {
						if (stack[layer]) {
							if (layer < highest) {
								if (stack[layer]["channel"]) {
									stack[layer]["position"] = stack[layer]["channel"].position;
									stack[layer]["channel"].removeEventListener(Event.SOUND_COMPLETE, stack[layer]["onSoundComplete"]);
									stack[layer]["onSoundComplete"] = null;
									stack[layer]["channel"].stop();
									stack[layer]["channel"] = null;
								}
							} else  {
								if (stack[layer]["sound"]) {
									var position:Number = stack[layer]["position"];
									if (stack[layer]["channel"]) {
										position = stack[layer]["channel"].position;
									}
//									trace("playing from position " + position);
									stack[layer]["channel"] = stack[layer]["sound"].play(position);
									stack[layer]["channel"].soundTransform = t;
									stack[layer]["onSoundComplete"] = function() {
										stack[highest]["channel"] = null;
										stack[highest]["position"] = 0;
										refreshAudio(); 
									}
									stack[layer]["channel"].addEventListener(Event.SOUND_COMPLETE, stack[layer]["onSoundComplete"]);
								}
							}
						}
					}
				}
			};
		}
	}
}
