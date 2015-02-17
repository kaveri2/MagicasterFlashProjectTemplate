package  
{	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.*;	
	import flash.text.*;
	import flash.geom.*;
	
	public class int_2013_comic_line extends MovieClip 
	{
		
		public function int_2013_comic_line(Z:*) 
		{
			var container1:Sprite = new Sprite();
			var container2:Sprite = new Sprite();
			container1.addChild(container2);

			Z.hat.magicast_run = function() {
				addChild(container1);
			};

			var s:Sprite = new Sprite();
		
			var shapeBitmap:Bitmap = new Bitmap();
			container2.addChild(shapeBitmap);
			
			var comicLineFormat:XML = null;
			if (Z.parameters && "" + Z.parameters.comicLineFormat != "") {
				comicLineFormat = Z.parameters.comicLineFormat[0];
			} 
			
			var oldData:String = "";
			Z.hat.magicast_render = function() {
				var c:* = Z.hat.magicast_calculations;
				container1.x = c.x;
				container1.y = c.y;
				container1.scaleX = c.scaleX;
				container1.scaleY = c.scaleY;
				container1.rotation = c.rotation;
				container1.alpha = c.alpha;
				container2.x = -c.referenceX;
				container2.y = -c.referenceY;
				var data:String = "" + 
					c.width + "," + 
					c.height + "," + 
					Z.hat.magicast_properties.phase;
				if (data != oldData) 
				{
					var phase:Number = "" + Z.hat.magicast_properties.phase != "" ? parseFloat(Z.hat.magicast_properties.phase) / 100 : 1;
					var points:Array = new Array();
					points.push(new Point(0, 0));
					points.push(new Point(c.width, c.height));
					
					s.graphics.clear();
					Z.comic.drawLine(s, points, comicLineFormat, 0, 1);
					
					var bmd:BitmapData = shapeBitmap.bitmapData;
					if (bmd) {
						bmd.dispose();
					}
					var r:Rectangle = s.getBounds(null);
					if (r.width && r.height) {
						bmd = new BitmapData(r.width, r.height, true, 0x00000000);
						var tmpMatrix:Matrix = new Matrix();
						tmpMatrix.translate(-r.x, -r.y);
						bmd.draw(s, tmpMatrix);
						shapeBitmap.bitmapData = bmd;
						shapeBitmap.smoothing = true;
						shapeBitmap.x = r.x;
						shapeBitmap.y = r.y;
					}					
					
					oldData = data;
				}
			};

			this.mouseEnabled 	= false;
			this.mouseChildren 	= false;

		}
		
	}
	
}
