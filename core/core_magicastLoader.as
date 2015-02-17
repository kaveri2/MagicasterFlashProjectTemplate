package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	public class core_magicastLoader extends MovieClip {
		
		public function core_magicastLoader(Z:*) {
			
			var magicastContainer:Sprite = new Sprite();
			addChild(magicastContainer);
			var magicast:*;
			
			var overlay:* = null;
			if ("" + Z.parameters.overlay != "") {
				overlay = Z.create(Z.parameters.overlay);
				addChild(overlay);
			}
			
			var magicastData:XMLList;
			
			var musicLayer:int = Z.parameters ? 0 + Z.parameters.musicLayer : 0;
			var id:int = Z.parameters ? 0 + Z.parameters.id : 0;
			var check:String = Z.parameters ? "" + Z.parameters.check : "";
			
			function fetch(refresh:Boolean) {
				if (!refresh) {
					if (overlay) {
						overlay.hat.loading = true;
						overlay.hat.trigger("loadStart");
					}
				}
				Z.serverConnection.callMethod(
					"Magicast.get", 
					XMLList("<id>" + id + "</id><check>" + check + "</check><refresh>" + (refresh ? "true" : "false") + "</refresh>"),
					Z.wrap(function(xml:XML) {
						if ("" + xml.errorMessage == "") {
							create(xml);
						} else {
						}
					}));
			}
			
			function create(xml:XML) {
				
				var newMagicastData = xml.data.children();
				
				if (!magicast) {
					magicastData = newMagicastData;
					magicast = Z.create({type: "core", value: "magicast.swf", parameters: magicastData});
					magicast.hat.bind("nodeChange", Z.wrap(function(node:String) {
						/*
						Z.serverConnection.callMethod(
							"Magicast.nodeChanged", 
							XMLList("<id>" + id + "</id><check>" + check + "</check><node>" + node + "</node>")
							);
						*/
						Z.mahti.trigger("nodeChange", id, node);
					}));
					if (overlay) {
						magicast.hat.bind("loadStart", Z.wrap(function() {
							overlay.hat.loading = true;
							overlay.hat.trigger("loadStart");
						}));
						magicast.hat.bind("loadProgress", Z.wrap(function(p:Number) {
							overlay.hat.trigger("loadProgress", p);
						}));
						magicast.hat.bind("loadComplete", Z.wrap(function() {
							overlay.hat.loading = false;
							overlay.hat.trigger("loadComplete");
						}));
					}
					magicastContainer.addChild(magicast);
					doResize();
					
					magicast.bind("ready", Z.wrap(function() {
						magicast.hat.run();
					}));
					
				} else if (magicastData != newMagicastData) {
					magicastData = newMagicastData;
					magicast.hat.update(magicastData);
				}
			}
							
			Z.bind("destroy", Z.wrap(function() {
				Z.music.stop(musicLayer);
				if (magicast) {
					magicast.destroy();
					magicastContainer.removeChild(magicast);
					magicast = null;
				}
				if (overlay) {
					overlay.destroy();
					removeChild(overlay);
					overlay = null;
				}
			}));
			
			// create content
			if ("" + Z.parameters.data != "") {
				create(Z.parameters);
			} else {
				fetch(false);
				Z.mahti.bind("accessUpdate", Z.wrap(function() {
					fetch(true);
				}));
			}

			var magicastInterface = Z.createHat(Z.magicastInterface);
			magicastInterface.playMusic = function(magicast_hat:*, parameters:XML) {
				Z.music.play("" + parameters.id, musicLayer);
			};
			magicastInterface.playMusicAsset = function(magicast_hat:*, parameters:XML) {
				Z.music.playAsset(parameters.asset, musicLayer);
			};
			magicastInterface.setMusicVolume = function(magicast_hat:*, parameters:XML) {
				Z.music.setVolume(0 + parameters.value, musicLayer);
			};
			Z.registerExtension("magicastInterface", magicastInterface);
			
			Z.bind("targetSizeChange", Z.wrap(function() {
				doResize();   
			}));
			function doResize() {	
				if (magicast) {
					magicast.setTargetSize(Z.targetWidth, Z.targetHeight);
				}
				if (overlay) {
					overlay.setTargetSize(Z.targetWidth, Z.targetHeight);
				}
			}
			doResize();
			
			Z.hat.getMagicast = function() {
				return magicast;
			};
			
		}
	}
	
}
