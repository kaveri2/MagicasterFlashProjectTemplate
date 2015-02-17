package  {
	
	import flash.net.URLRequest;
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;	
	import flash.events.Event;
	
	public class core_sound extends MovieClip {
		
		public function core_sound(Z:*) {
			
			var extension:* = Z.createHat();
			Z.parent.registerExtension("sound", extension);

			extension.play = function(id:String, volume:Number) {
//				trace("sound / play: " + id+ " / " + volume);
				
				switch(id) {
					case "select":
						Z.hat.playAsset({type: "core", value: "sound/select.mp3"});
						break;
				}
			};
			
			/*
			var soundChannels:Array = new Array();
			var soundChannelIndex:int = 0;
			*/
			
			extension.playAsset = function(asset:*, volume:Number) {
//				trace("sound / playAsset: " + asset + " / " + volume);
				
				var ur:URLRequest = Z.buildAssetURLRequest(asset);
				var s:Sound = new Sound();
				s.load(ur);
				var st:SoundTransform = new SoundTransform(volume);
				var sc:SoundChannel = s.play(0, 0, st);
				
				/*
				var i:int = soundChannelIndex++;
				soundChannels[i] = sc;
				sc.addEventListener(Event.SOUND_COMPLETE, function(e:Event) {
					delete soundChannels[i];
				});
				*/
			};
			
			extension.setGlobalVolume = function(value:Number) {
//				trace("sound / setGlobalVolume: " + value);
			};
			
			if (Z.magicastInterface) {
				Z.magicastInterface.playSound = function(magicast_hat:*, parameters:XML) {
					Z.sound.play("" + parameters.id, "" + parameters.volume != "" ? (0 + parameters.volume) / 100 : 100);
				};
				Z.magicastInterface.playSoundAsset = function(magicast_hat:*, parameters:XML) {
					Z.sound.playAsset(parameters.asset, "" + parameters.volume != "" ? (0 + parameters.volume) / 100 : 100);
				};
			}			

		}
	}
	
}
