package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class int_example_comic extends MovieClip {
		
		public function int_example_comic(Z:*) {

			var points:Array = new Array();
			for (var angle:Number=0 ; angle<Math.PI*2 ; angle=angle+0.1) {
				var tmp_x:Number = 200 * Math.cos(angle);
				var tmp_y:Number = 100 * Math.sin(angle);
				points.push(new Point(tmp_x, tmp_y));
			}

			var s:Sprite = new Sprite();
			addChild(s);

			var oldPhase:int = 0;
			Z.hat.magicast_render = function() {
				s.x = Z.hat.magicast_calculations.x;
				s.y = Z.hat.magicast_calculations.y;
				var phase:Number = parseFloat(Z.hat.magicast_properties.phase);
				if (phase != oldPhase) {
					s.graphics.clear();
					Z.comic.drawLine(s, points, true, phase / 100);
					oldPhase = phase;
				}
			};
   
		}
	}
}

