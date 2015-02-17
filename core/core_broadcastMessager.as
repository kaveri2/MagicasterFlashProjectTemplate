package  {
	
	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;	
	import flash.events.Event;	
	import flash.events.IOErrorEvent;	
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class core_broadcastMessager extends MovieClip {
		
		public function core_broadcastMessager(Z:*) {

			Z.hat.plugin = function() {
				var extension:* = Z.createHat();
				Z.parent.registerExtension("broadcastMessager", extension);
	
				var delay:int = 500;
				
				var fromId:int = 0;
				var t:Timer = new Timer(delay, 0);
				Z.wrapEventListener(t, TimerEvent.TIMER, function(e:TimerEvent) {
					var binds:Array = extension.binds;
					for (var i:int = 0 ; i<binds.length ; i++) {
						var channel:String = binds[i];
						Z.serverConnection.callMethod("BroadcastMessage.receive", XMLList("<channel>" + channel + "</channel>" + "<fromId>" + fromId + "</fromId>"), Z.wrap(function(xml:XML) {
							fromId = Math.max(fromId, 0 + xml.nextId);
							for (var j:* in xml.message) {
								extension.trigger(channel, xml.message[j].data[0]);
							}
						}));
						
					}
				});
				t.start();
				
				extension.send = function(channel:String, data:XMLList) {
					Z.serverConnection.callMethod("BroadcastMessage.send", XMLList("<channel>" + channel + "</channel>" + "<data>" + data+ "</data>"), Z.wrap(function(xml:XML) {
					}));
				};
				
				if (Z.magicastInterface) {
					Z.magicastInterface.sendBroadcastMessage = function(magicast_hat:*, p:XML) {
						extension.send("" + p.channel, p.data.children());
					};
				}
			};
		}
	}
}
