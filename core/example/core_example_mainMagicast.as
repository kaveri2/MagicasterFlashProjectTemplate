package  {
	
	import flash.display.MovieClip;
	
	public class core_example_mainMagicast extends MovieClip {
		
		public function core_example_mainMagicast(Z:*) {

			var loader:*;
			loader = Z.create({
				type: "core", value: "magicastLoader.swf", 
				parameters: XMLList("<musicLayer>1</musicLayer><overlay><type>core</type><value>example/magicastLoaderOverlay.swf</value></overlay>" + Z.parameters.children().toXMLString())
			});
			addChild(loader);
			
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
