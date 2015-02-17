package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	public class int_2013_magicast extends MovieClip 
	{
		public function int_2013_magicast(Z:*) 
		{
			
			var loader:*;
			
			Z.hat.magicast_render = function() {
				var c:* = Z.hat.magicast_calculations;
				loader.x = c.x;
				loader.y = c.y;
				loader.scaleX = c.scaleX;
				loader.scaleY = c.scaleY;
				loader.alpha = c.alpha;
				loader.rotation = c.rotation;					
			}			
			
			loader = Z.create({
				type: "core", value: "magicastLoader.swf", 
				parameters: Z.parameters.children()
			});
			addChild(loader);
			loader.bind("ready", function():void {
				Z.ready();
			});
			
			Z.bind("targetSizeChange", doResize, true);
			function doResize() {
				if (loader) {
					loader.setTargetSize(Z.targetWidth, Z.targetHeight);
				}
			}
			doResize();
			
			Z.hat.getMagicast = function() {
				if (loader) {
					return loader.hat.getMagicast();
				}
			}
		}
	}
}