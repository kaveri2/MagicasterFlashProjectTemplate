package  {
	
	import flash.display.MovieClip;	
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class int_2012_broadcastEventReceiver extends MovieClip {
		
		public function int_2012_broadcastEventReceiver(Z:*) {
			
			Z.broadcastMessager.bind("" + Z.parameters.channel, Z.wrap(function(data:XML) {
				Z.hat.magicast_triggerEvent(data.name, data.parameters);
			}));
			
		}
	}
	
}
