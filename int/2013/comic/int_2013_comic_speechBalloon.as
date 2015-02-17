package  
{	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.*;	
	import flash.text.*;
	import flash.geom.*;
	import flash.events.Event;
	
	public class int_2013_comic_speechBalloon extends MovieClip 
	{
		
		public function int_2013_comic_speechBalloon(Z:*) 
		{

			var comicLineFormat:XML = null;
			if (Z.parameters && "" + Z.parameters.comicLineFormat != "") {
				comicLineFormat = Z.parameters.comicLineFormat[0];
			} 

			var container:Sprite = new Sprite();

			var s:Sprite = new Sprite();
		
			var shapeBitmap:Bitmap = new Bitmap();
			container.addChild(shapeBitmap);
			
			var textFieldMask:Sprite = new Sprite();
			container.addChild(textFieldMask);

			var text:String = "" + Z.parameters.text;
			text = text.replace("\r", "");
			var editable:Boolean = "" + Z.parameters.editable == "true";
			
			var angle:Number =  "" + Z.parameters.angle != "" ? parseFloat("" + Z.parameters.angle) : 0;
			while (angle < 0) angle = angle + 360;
			while (angle >= 360) angle = angle - 360;
			var angleRadians:Number = angle * Math.PI / 180;
			
			var invertedAngle:Number = angle + 180;
			while (invertedAngle < 0) invertedAngle = invertedAngle + 360;
			while (invertedAngle >= 360) invertedAngle = invertedAngle - 360;
			var invertedAngleRadians:Number = invertedAngle * Math.PI / 180;
			
			var margin:Number = "" + Z.parameters.margin != "" ? parseFloat("" + Z.parameters.margin) : 5;
			var minWidth:Number = margin * 4;
			var minHeight:Number = margin * 4;
			
			var arrowLength:Number = "" + Z.parameters.arrowLength != "" ? parseFloat("" + Z.parameters.arrowLength) : 20;
			var distance:Number = "" + Z.parameters.distance != "" ? parseFloat("" + Z.parameters.distance) : 10;
			var n:Number = "" + Z.parameters.n != "" ? parseFloat("" + Z.parameters.n) : 4;
			
			var textField:TextField = Z.textFormatter.createTextField(Z.parameters.textFormat[0]);
			textField.multiline = true;
			textField.width = 1000;
			textField.height = 1000;
//			textField.autoSize = TextFieldAutoSize.LEFT;
			if (editable) {
				textField.type = TextFieldType.INPUT;
				textField.selectable = true;
			}
			textField.text = text;
			Z.wrapEventListener(textField, Event.CHANGE, function(e:Event) {
			});
			container.addChild(textField);
			textField.mask = textFieldMask;

			Z.hat.magicast_run = function() {
				addChild(container);
			};
			
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				if (name=="changeText") {
					textField.text = "" + parameters.text;
				}
			};

			var oldData:String = "";
			Z.hat.magicast_render = function() {
				
				var i:int;
				
				container.x = Z.hat.magicast_calculations.x;
				container.y = Z.hat.magicast_calculations.y;
				
				var phase:Number = Z.hat.magicast_properties.phase!==undefined ? parseFloat(Z.hat.magicast_properties.phase) / 100 : 1;
				var data:String = "" + textField.text + "," + phase;
				
				if (data != oldData) {
					
					textField.type = TextFieldType.DYNAMIC;
					textField.selectable = false;
					textField.mask = null;
					
					var r1:Rectangle = textField.getBounds(null);
					
					var bmd:BitmapData = new BitmapData(r1.width, r1.height, true, 0x00000000);
					var tmpMatrix:Matrix = new Matrix();
					tmpMatrix.translate(-r1.x, -r1.y);
					bmd.draw(textField, tmpMatrix);

					if (editable) {
						textField.type = TextFieldType.INPUT;
						textField.selectable = true;
					}
					textField.mask = textFieldMask;

					var r2:Rectangle = bmd.getColorBoundsRect(0xffffffff, 0x00000000, false);
	
					// multiply width and height towards hyperellipse n
					var w:Number = margin * 2 + Math.max(minWidth, r2.width) * (1 + (Math.SQRT2 - 1) * 2 / n);
					var h:Number = margin * 2 + Math.max(minHeight, r2.height) * (1 + (Math.SQRT2 - 1) * 2 / n);
		
					var a:Number = w / 2;
					var b:Number = h / 2;
					var m:Number = 4;
					var n1:Number = n;
					var n2:Number = n;
					var n3:Number = n;
					
					var aRadStep:Number = Math.PI * 2 / 360;
		
					// count the center
					var centerX:Number = (distance + arrowLength) * Math.cos(angleRadians);
					var centerY:Number = (distance + arrowLength) * Math.sin(angleRadians); + (h / 2) * Math.sin(angleRadians);
					
					var l:Number = Math.sqrt(w * w + h * h);
					var newAngleRadians:Number = Math.atan2(h / l * Math.sin(angleRadians), w / l * Math.cos(angleRadians));
					
					var radius:Number = Math.pow((Math.pow(Math.abs(Math.cos(m * newAngleRadians / 4) / a), n2) + Math.pow(Math.abs(Math.sin(m * newAngleRadians / 4) / b), n3)), -(1/n1));
					centerX = centerX + radius * Math.cos(newAngleRadians);
					centerY = centerY + radius * Math.sin(newAngleRadians);

					var points:Array = new Array();
					for (var aRad:Number = newAngleRadians + Math.PI; aRad < newAngleRadians + Math.PI + Math.PI * 2; aRad = aRad + aRadStep) {						
						radius = Math.pow((Math.pow(Math.abs(Math.cos(m * aRad / 4) / a), n2) + Math.pow(Math.abs(Math.sin(m * aRad / 4) / b), n3)), -(1/n1));
						points.push(new Point(centerX + radius * Math.cos(aRad), centerY + radius * Math.sin(aRad)));
					}
					points.push(new Point(points[0].x, points[0].y));

					s.graphics.clear();

					if (phase>0.8) {
						textFieldMask.graphics.clear();
						textFieldMask.graphics.beginFill(0x000000);
						textFieldMask.graphics.drawRect(0, 0, Math.max(minWidth, r2.width), Math.max(minHeight, r2.height));
						s.graphics.lineStyle(0,0,0);
						s.graphics.beginFill(0xffffff, (phase - 0.8) / 0.2);
						for (i = 0; i<points.length; i=i+1) {
							s.graphics.lineTo(points[i].x, points[i].y);
						}
						s.graphics.endFill();
						textField.alpha = (phase - 0.8) / 0.2;
						textField.visible = true;
						textFieldMask.visible = true;
					} else {
						textField.visible = false;
						textFieldMask.visible = false;
					}
										
					if (phase>0.2) {
						Z.comic.drawLine(s, points, comicLineFormat, 0, Math.min(1, (phase - 0.2) / 0.6));
					}
					if (phase>0.0) {
						points = new Array();
						points.push(new Point(
							(distance) * Math.cos(angleRadians),
							(distance) * Math.sin(angleRadians)
						));
						points.push(new Point(
							(distance + arrowLength) * Math.cos(angleRadians),
							(distance + arrowLength) * Math.sin(angleRadians)
						));
//						radius = Math.pow((Math.pow(Math.abs(Math.cos(m * invertedAngleRadians / 4) / a), n2) + Math.pow(Math.abs(Math.sin(m * invertedAngleRadians / 4) / b), n3)), -(1/n1));
//						points.push(new Point(centerX + radius * Math.cos(invertedAngleRadians), centerY + radius * Math.sin(invertedAngleRadians)));
						Z.comic.drawLine(s, points, comicLineFormat, 0, Math.min(1, phase / 0.2));
					}

					bmd = shapeBitmap.bitmapData;
					if (bmd) {
						bmd.dispose();
					}
					var r:Rectangle = s.getBounds(null);
					if (r.width && r.height) {
						bmd = new BitmapData(r.width, r.height, true, 0x00000000);
						tmpMatrix = new Matrix();
						tmpMatrix.translate(-r.x, -r.y);
						bmd.draw(s, tmpMatrix);
						shapeBitmap.bitmapData = bmd;
						shapeBitmap.smoothing = true;
						shapeBitmap.x = r.x;
						shapeBitmap.y = r.y;
					}

					textField.x = centerX - r1.x - r2.x - r2.width / 2;
					textField.y = centerY - r1.y - r2.y - r2.height / 2;	
					textFieldMask.x = centerX - r2.width / 2;
					textFieldMask.y = centerY - r2.height / 2;	
					
					oldData = data;
				}
			};
		}		
	}
}
