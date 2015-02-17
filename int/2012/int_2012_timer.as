package  {
	
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.Event;
	import flash.events.TimerEvent;
	
	public class int_2012_timer extends MovieClip {

		public function int_2012_timer(Z:*) {
			
			Z.autoReady = false;
			
			var delay:int = 			0 + Z.parameters.delay;
			var repeat:int = 			0 + Z.parameters.repeat;
			var triggerEvt:String =		"" + Z.parameters.triggerEvent;
			var completeEvt:String =	"complete";
			var startStopped = "" + Z.parameters.startStopped == "true";
						
			if ("" + Z.parameters.completeEvent) {
				var completeEvt:String = "" + Z.parameters.completeEvent;
			} 
			
			var t:Timer = new Timer(delay, repeat);
						
			Z.wrapEventListener(t, TimerEvent.TIMER, function(e:Event) {
				Z.hat.magicast_triggerEvent(triggerEvt);
			});
			
			Z.wrapEventListener(t, TimerEvent.TIMER_COMPLETE, function(e:Event) {
				Z.hat.magicast_triggerEvent(completeEvt);   
			});
			
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				switch	(name) {
					case "start":
						t.start();
						break;
					case "stop":
						t.stop();
						break;
					case "reset":
						t.reset();
						break;
				}
			}
			
			Z.bind("destroy", Z.wrap(function() {
				t.stop();
				t = null;
			}));
			
			Z.ready();
			
			if (!startStopped) {
				t.start();
			}
			
		}

	}
	
}
