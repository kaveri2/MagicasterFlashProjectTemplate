package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;

	public class core_ui extends MovieClip {
		
		var minWidth:int;
		var minHeight:int;
		var maxWidth:int;
		var maxHeight:int;

		var wrapper1:Sprite;
		var wrapper2:Sprite;
		
		var w:Number;
		var h:Number;		

		var components:Array;
		var componentContainers:Array;
		
		public function core_ui(Z:*) {
			Z.hat.plugin = function() {
				minWidth = parseInt(Z.parameters.minWidth);
				minHeight = parseInt(Z.parameters.minHeight);
				maxWidth = parseInt(Z.parameters.maxWidth);
				maxHeight = parseInt(Z.parameters.maxHeight);
				
				wrapper1 = new Sprite();
				addChild(wrapper1);
				wrapper2 = new Sprite();
				wrapper1.addChild(wrapper2);			
	
				var extension:* = Z.createHat();
				Z.parent.registerExtension("ui", extension);
				
				extension.createComponent = function(name:String, asset:*, options:* = null) {	
					if (componentContainers[name]) {
						extension.destroyComponent(name);
						var o:* = {targetWidth: w, targetHeight: h};
						if (options) {
							if (options.hat) {
								o.hat = options.hat;
							}
						}
						var c:* = Z.create(asset, o);
						components[name] = c;
						componentContainers[name].addChild(c);
						return c;
					}
				};
				extension.destroyComponent = function(name:String) {
					if (components[name]) {
						components[name].destroy();
						componentContainers[name].removeChild(components[name]);
						delete components[name];
					}
				};
				extension.getComponent = function(name:String) {
					return components[name];	
				};
	
				components = new Array();
				componentContainers = new Array();
				for (var i=0 ; i < Z.parameters.component.length() ; i++) {
					var c = new Sprite();
					wrapper2.addChild(c);
					componentContainers[Z.parameters.component[i]] = c;
				}
				
				function doResize() {
					
					w = Z.targetWidth;
					h = Z.targetHeight;
					
					var s:Number = 1;
					s = Math.min(Z.targetWidth / minWidth, Z.targetHeight / minHeight);
					if (s<1) {
						w = Z.targetWidth / s;
						h = Z.targetHeight / s;
					} else {
						s = Math.max(Z.targetWidth / maxWidth, Z.targetHeight / maxHeight);
						if (s>1) {
							w = Z.targetWidth / s;
							h = Z.targetHeight / s;
							var s2:Number = Math.min(w / minWidth, h / minHeight);
							if (s2<1) {
								w = w / s2;
								h = h / s2;
								s = s * s2;
							}
						} else {
							s = 1;
						}
					}
		
					for (var i:* in components) {
						components[i].setTargetSize(w, h);
					}
					
					wrapper1.scaleX = s;
					wrapper1.scaleY = s;
				}
				
				if (ExternalInterface.available) {
					ExternalInterface.addCallback("core_ui_setMinSize", function(w:int, h:int) {
						minWidth = w;
						minHeight = h;
					});
					ExternalInterface.addCallback("core_ui_setMaxSize", function(w:int, h:int) {
						maxWidth = w;
						maxHeight = h;
					});
				}
				
				Z.bind("targetSizeChange", Z.wrap(function () {
					doResize();  
				}));
				doResize();
				
			};
		}		
	}
}
