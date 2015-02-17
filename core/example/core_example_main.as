package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.external.ExternalInterface;
		
	public class core_example_main extends MovieClip {
		
		public function core_example_main(Z:*) {
			Z.hat.plugin = function() {
			
				var lastPathCompare:String = "";
				
				var foreground:* = null;
				var mainMagicast:* = null;
				
				if (ExternalInterface.available) {
					ExternalInterface.addCallback("core_example_main_hashChange", function(hash:String) {
						if (hash != Z.magicaster.path.name) {
							Z.magicaster.changePath(hash);
						}
					});
				}
				
				Z.magicaster.bind("pathChange", Z.wrap(function() {
	
					var pathCompare:String = "";	
					
					if (Z.magicaster.path.id) {
						if (ExternalInterface.available) {
							ExternalInterface.call("setTitle", "" + Z.magicaster.path.data.name);
							ExternalInterface.call("setHash", "" + Z.magicaster.path.name);
						} else {
						}
						if ("" + Z.magicaster.path.data.magicast) {
							pathCompare = "magicastId_" + Z.magicaster.path.data.magicast.id;
							if (pathCompare != lastPathCompare) {				
								Z.example.openMainMagicast(Z.magicaster.path.data.magicast.children());
							}
						} else {
							Z.example.closeMainMagicast();
						}
					}
	
					lastPathCompare = pathCompare;				
					
				}));
				
				Z.magicaster.bind("start", Z.wrap(function():void {
							 
					foreground = Z.ui.createComponent("foreground", {type: "core", value: "example/foreground.swf"});
					foreground.bind("ready", function() {
						if (Z.magicaster.test) {
							if ("" + Z.magicaster.test.mainMagicast != "") {
								Z.example.openMainMagicast(Z.magicaster.test.mainMagicast.children());
							}
						} else {
							Z.magicaster.changePath("" + Z.parameters.path);
						}
					});
					
				}));
	
				var extension:* = Z.createHat();
				Z.parent.registerExtension("example", extension);
							
				extension.openMainMagicast = function(parameters:XMLList) {	
					mainMagicast = Z.ui.createComponent("mainMagicast", 
						{
							type: "core", 
							value: "example/mainMagicast.swf", 
							parameters: parameters
						});
					return mainMagicast;
				};
				
				extension.openSystemDialog = function(parameters:XMLList) {
					// TODO
				};
				extension.closeSystemDialog = function() {
					// TODO
				};
				
				if (Z.magicastInterface) {
					Z.magicastInterface.openMainMagicast = function(magicast:*, parameters:XML) {
						extension.openMainMagicast(parameters.children());
					};
				}
			};
		}
	}
}
