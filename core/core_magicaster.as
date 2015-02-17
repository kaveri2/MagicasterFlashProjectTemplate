package  {
	
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.xml.XMLNode;
	import flash.external.ExternalInterface;
	import flash.desktop.NativeApplication;
	import flash.system.Capabilities;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	public class core_magicaster extends MovieClip {
		
		public function core_magicaster(Z:*) {
									
			Z.hat.plugin = function() {
				var extension:* = Z.createHat();
				Z.parent.registerExtension("magicaster", extension);

				extension.clientName = "" + Z.parameters.clientName;
				extension.path = {name: "", loading: false};
				extension.active = true;
				
				// multitouch
				extension.multitouch = false;
				if ("" + Z.parameters.multitouch == "true") {
					if (Multitouch.supportsTouchEvents) {
						extension.multitouch = true;
						Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
					}
				} else {
					if (Multitouch.supportsTouchEvents) {
						Multitouch.inputMode = MultitouchInputMode.NONE;
					}
				}
	
				function searchPath(name:String) {
					extension.path = {name: name, loading: true};
					Z.serverConnection.callMethod("Path.search", XML("<name>" + name + "</name>"), function(xml:XML) {
						if ("" + xml) {
							extension.path = {name: name, id: 0 + xml.id, data: xml.data[0], loading: false};
						} else {
							extension.path = {name: name, loading: false};
						}
						extension.trigger("pathChange");
					}, function() {
						// error -> try again
						searchPath(name);
					});
				}
	
				extension.changePath = function(name:String) {
					searchPath(name);
				};
							
				extension.test = ("" + Z.parameters.test) ? Z.parameters.test[0] : null;			
				
				function updateStatus() {
					var nowGetTimer:int = getTimer();
					Z.serverConnection.callMethod(
						"Session.updateStatus", 
						XMLList(
							"<uptime>" + ((nowGetTimer - startGetTimer) / 1000) + "</uptime>" + 
							"<idleTime>" + ((nowGetTimer - idleStartGetTimer) / 1000) + "</idleTime>" +
							"<active>" + (extension.active ? "true" : "false") + "</active>"
						// success
						), function(data:XML) {
							statusUpdateTimer.reset();
							statusUpdateTimer.start();
						// failure
						}, function() {
							statusUpdateTimer.reset();
							statusUpdateTimer.start();							
						});					
				}
				
				var statusUpdateTimer:Timer = new Timer(60 * 1000, 1);
				Z.wrapEventListener(statusUpdateTimer, TimerEvent.TIMER, function() {
					if (extension.active) {
						updateStatus();
					}
				});
				
				var startGetTimer:int;
				var idleStartGetTimer:int;
				extension.resetIdleTimer = function() {
					idleStartGetTimer = getTimer();
				};
				
				try {
					function kikka() {
						NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, function(e:Event):void {
							extension.active = true;
							updateStatus();
						});
						NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, function(e:Event):void {
							extension.active = false;
							updateStatus();
						});
					} 
					kikka();
				} catch (e:Error) {
				}
				
				Z.serverConnection.bind("Access.update", Z.wrap(function(xml:XML) {
					extension.trigger("accessUpdate");
				}));
				
				function setClient(name:String, event:String) {
					Z.serverConnection.callMethod("Client.set", XMLList("<name>" + name + "</name><capabilities>" + Capabilities.serverString + "</capabilities>"), function(xml:XML) {
						extension.trigger(event);
						if (event=="start") {
							startGetTimer = idleStartGetTimer = getTimer();
							statusUpdateTimer.start();
						}
					}, function() {
						setClient(name, event);
					});
				}
							
				Z.loader.bind("start", Z.wrap(function() {	
					if ("" + Z.parameters.clientName != "") {
						if ("" + Z.parameters.test != "") {
							extension.trigger("start");
						} else {
							setClient("" + Z.parameters.clientName, "start");
						}
					} else {
						extension.trigger("start");
					}
				}));

				Z.serverConnection.bind("loadFailure", Z.wrap(function() {
					extension.trigger("loadFailure");
				}));
				Z.serverConnection.bind("loadRetry", Z.wrap(function() {
					extension.trigger("loadRetry");
				}));
				Z.serverConnection.bind("sessionExpire", Z.wrap(function() {
					if (Z.parameters.clientName) {
						setClient("" + Z.parameters.clientName, "sessionExpire");
					} else {
						extension.trigger("sessionExpire");
					}
				}));
				
				if (Z.magicastInterface) {
					Z.magicastInterface.grantSessionAccess = function(magicast_hat:*, parameters:XML) {
						Z.serverConnection.callMethod("Session.grantAccess", parameters.children(), function(xml:XML) {
						});
					};
					Z.magicastInterface.denySessionAccess = function(magicast_hat:*, parameters:XML) {
						Z.serverConnection.callMethod("Session.denyAccess", parameters.children(), function(xml:XML) {
						});
					};
					Z.magicastInterface.changePath = function(magicast_hat:*, parameters:XML) {
						extension.changePath("" + parameters.name);
					};
					Z.magicastInterface.getPath = function(magicast_hat:*, parameters:XML) {
						magicast_hat.setVariable("" + parameters.variable, extension.path.name);
					};
				}
			};
		}
	}
}
