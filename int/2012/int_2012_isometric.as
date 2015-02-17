package  {
	
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.display.Sprite;	
	
	public class int_2012_isometric extends MovieClip {
		
		public function int_2012_isometric(Z:*) {

			Z.autoReady = false;
	
			var sprite = Z.create(Z.parameters.asset.children());
			addChild(sprite);
			sprite.bind("ready", function() {
				var m = new Matrix();
				m.rotate(-45 * Math.PI/180);
				m.scale(1, 1 / Math.sqrt(3));
				sprite.transform.matrix = m;
				Z.ready();
			});

		}
	}
	
}
