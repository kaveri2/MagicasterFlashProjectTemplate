package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.*;	
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	
	public class int_2013_text extends MovieClip {
		
		public function int_2013_text(Z:*) {

			var minWidth:Number = 20;
			var minHeight:Number = 20;
			
			var text:String = "" + Z.parameters.text;
			var editable:Boolean = "" + Z.parameters.editable == "true";
			
			var width:Number;
			var widthSet:Boolean = false;
			if ("" + Z.parameters.width != "") {
				width = parseFloat("" + Z.parameters.width);
				widthSet = true;
			}
			var height:Number;
			var heightSet:Boolean = false;
			if ("" + Z.parameters.height != "") {
				height = parseFloat("" + Z.parameters.height);
				heightSet = true;
			}
			
			var format:XML;
			if ("" + Z.parameters.format != "") {
				format = Z.parameters.format[0];
			}
			var style:XML;
			if ("" + Z.parameters.style != "") {
				style = Z.parameters.style[0];
			}

			Z.hat.magicast_runAction = function(method:String, parameters:XML) {
				if (method=="changeText") {
					textField.text = "" + Z.parameters.text;
					renderedData = "";
				}
				if (method=="changeFormat") {
					format = parameters.format[0];
					renderedData = "";
					update();
				}
				if (method=="changeStyle") {
					style = parameters.style[0];
					renderedData = "";
				}
			};

			var renderedData:String = "";
			Z.hat.magicast_render = function() {
				var calculations:* = Z.hat.magicast_calculations;

				container1.x = calculations.x;
				container1.y = calculations.y;
				container1.scaleX = calculations.scaleX;
				container1.scaleY = calculations.scaleY;
				container1.alpha = calculations.alpha;
				
				var data:String = textField.text + "," + calculations.rotation;
				
				if (renderedData != data) {

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
					
					r2 = bmd.getColorBoundsRect(0xffffffff, 0x00000000, false);
					if (widthSet) {
						r2.x = 0;
						r2.width = width;
					}
					if (heightSet) {
						r2.y = 0;
						r2.height = height;
					}
					Z.hat.magicast_setBounds(r2);
	
					textField.x = -r1.x;
					textField.y = -r1.y;
	
					textFieldMask.graphics.clear();
					textFieldMask.graphics.beginFill(0xff0000);
					textFieldMask.graphics.drawRect(r2.x, r2.y, Math.max(minWidth, r2.width), Math.max(minWidth, r2.height));
					/*
					textFieldMask.graphics.drawRect(
							widthSet ? 0 : r2.x, heightSet ? 0 : r2.y, 
							widthSet ? width : Math.max(minWidth, r2.width), heightSet ? height : Math.max(minHeight, r2.height));
					*/
					container2.rotation = calculations.rotation;
					if (style) {
						if (styled) {
							Z.styler.update(styled, container2, style);
						} else {
							styled = Z.styler.create(container2, style);
							container1.removeChild(container2);
							container1.addChild(styled);
						}
					}
					renderedData = data;
				}

				if (style) {
					styled.x = -calculations.referenceX - r2.x;
					styled.y = -calculations.referenceY - r2.y;
				} else {
					container2.x = -calculations.referenceX - r2.x;
					container2.y = -calculations.referenceY - r2.y;					
				}
				
			}
						
			var container1:Sprite = new Sprite();
			addChild(container1);
			var styled:*;
			var container2:Sprite = new Sprite();
			container1.addChild(container2);
			var textFieldMask:Sprite = new Sprite();
			container2.addChild(textFieldMask);
			var textField:TextField;
			
			/*
			this.mouseEnabled = false;
			container1.mouseEnabled = false;
			container1.mouseChildren = false;
			container2.mouseEnabled = false;
			*/
			
			var r2:Rectangle;
			function update() {
				if (textField) {
					container2.removeChild(textField);
				}
				textField = Z.textFormatter.createTextField(format);
				container2.addChild(textField);
				
				textField.multiline = true;
				textField.text = text;
				textField.width = widthSet ? width : 1000;
				textField.height = heightSet ? height : 1000;
//				textField.autoSize = TextFieldAutoSize.LEFT;
			}
			
			update();
		}
	}
}
