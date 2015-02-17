package  {
	
	import flash.display.MovieClip;
	
	public class core_magicastInterface extends MovieClip {
		
		public function core_magicastInterface(Z:*) {
			Z.hat.plugin = function() {
				var extension:* = Z.createHat();
				Z.parent.registerExtension("magicastInterface", extension);
			};
		}
		
	}
}
