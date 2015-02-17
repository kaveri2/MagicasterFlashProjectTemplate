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
	
	public class int_2012_broadcastEventSender extends MovieClip {
		
		public function int_2012_broadcastEventSender(Z:*) {
			
			Z.hat.magicast_runAction = function(method:String, parameters:XML) {
				if (method=="send") {
					Z.broadcastMessager.send("" + Z.parameters.channel, XMLList("<name>" + parameters.name + "</name>" + "<parameters>" + parameters.parameters + "</parameters>"));
				}
			}
			
		}
	}
	
}
