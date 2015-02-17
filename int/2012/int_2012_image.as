package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;	
	import flash.geom.Rectangle;
	
	public class int_2012_image extends MovieClip {
		
		public function int_2012_image(Z:*) {

			this.mouseEnabled = false;
			this.mouseChildren = false;			

			Z.getBytesLoaded = function() {
				if (image && !(image is Bitmap)) {
					return image.getBytesLoaded();
				}
				return 0;
			}
			
			Z.getBytesTotal = function() {
				if (image && !(image is Bitmap)) {
					return image.getBytesTotal();
				}
				return 0;
			}

			var originalReferenceX:Number = 0;
			var originalReferenceY:Number = 0;
			var originalWidth:Number = 0;
			var originalHeight:Number = 0;

			var style:XML;
			if ("" + Z.parameters != "") {
				style = Z.parameters.style[0];
			}

			Z.hat.magicast_run = function() {
			}
			
			Z.hat.magicast_runAction = function(method:String, parameters:XML) {
				// OLD SYNTAX
				// NEW SYNTAX
				if (method=="changeStyle" || method=="setStyle") {
					style = parameters.style[0];
					renderedData = "";
				}
				var newImage:*;
				var bounds:Rectangle;
				if (method=="changeAsset") {
					newImage = Z.create(parameters.asset.children());
					newImage.bind("ready", Z.wrap(function() {   
						if (image) {
							container2.removeChild(image);
						}
						image = newImage;
						try {
							image.content.smoothing = true;
						} catch (e:Error) {
						}
						container2.addChild(image);
						var bounds:Rectangle = image.getBounds(null);
						originalReferenceX = -bounds.x;
						originalReferenceY = -bounds.y;
						originalWidth = bounds.width;
						originalHeight = bounds.height;
						Z.hat.magicast_setBounds(bounds);
						renderedData = "";
					}));
				}
				// OLD SYNTAX
				if (method=="changeVariable") {
					if (image) {
						container2.removeChild(image);
					}
					image = null;
					try {
						bmd = Z.hat.magicast_hat.getVariable("" + parameters.name);
						image = new Bitmap(bmd);
						image.smoothing = true;
						container2.addChild(image);
						bounds = image.getBounds(null);
						originalReferenceX = -bounds.x;
						originalReferenceY = -bounds.y;
						originalWidth = bounds.width;
						originalHeight = bounds.height;
						Z.hat.magicast_setBounds(bounds);
					} catch (e:Error) {
					}
					renderedData = "";
				}
				// NEW SYNTAX
				if (method=="setValue") {
					if (image) {
						container2.removeChild(image);
					}
					image = null;
					try {
						bmd = Z.hat.magicast_resolveAndGetValue(parameters.value);
						image = new Bitmap(bmd);
						image.smoothing = true;
						container2.addChild(image);
						bounds = image.getBounds(null);
						originalReferenceX = -bounds.x;
						originalReferenceY = -bounds.y;
						originalWidth = bounds.width;
						originalHeight = bounds.height;
						Z.hat.magicast_setBounds(bounds);
					} catch (e:Error) {
					}
					renderedData = "";
				}
			};

			var renderedData:String = "";
			Z.hat.magicast_render = function() {
				var calculations:* = Z.hat.magicast_calculations;
				
				container1.x = calculations.x;
				container1.y = calculations.y;
				container1.alpha = calculations.alpha;
				
				var data:String = calculations.width + "." + calculations.height + "." + calculations.scaleX + "." + calculations.scaleY + "." + calculations.rotation + "." + calculations.referenceX + "." + calculations.referenceY;
				
				if (renderedData != data && image) {
					image.width = calculations.width * calculations.scaleX;
					image.height = calculations.height * calculations.scaleY;
					image.x =  (originalReferenceX - calculations.referenceX) / originalWidth * image.width;
					image.y =  (originalReferenceY - calculations.referenceY) / originalHeight * image.height;
					container2.rotation = calculations.rotation;
					if (styled) {
						Z.styler.update(styled, container2, style);
					} else {
						styled = Z.styler.create(container2, style);
						container1.addChild(styled);
					}
					renderedData = data;
				}
			}
			
			var type:String = "";
			if (Z.parameters.type != undefined) {
				type = Z.parameters.type;
			}
						
			var container1 = new Sprite();
			addChild(container1);
			var container2 = new Sprite();
			var styled:*;
			var image:*;
			
			if ("" + Z.parameters.asset) {
				Z.autoReady = false;
				image = Z.create(Z.parameters.asset.children());
				image.bind("ready", Z.wrap(function() {
					try {
						image.content.smoothing = true;
					} catch (e:Error) {
					}
					container2.addChild(image);
					var bounds:Rectangle = image.getBounds(null);
					originalReferenceX = -bounds.x;
					originalReferenceY = -bounds.y;
					originalWidth = bounds.width;
					originalHeight = bounds.height;
					Z.hat.magicast_setBounds(bounds);
					Z.ready();
				}));
			}
			
			var bmd:BitmapData;
			var bounds:Rectangle;
			
			// OLD SYNTAX
			if (!image && "" + Z.parameters.variable) {
				try {
					bmd = Z.hat.magicast_hat.getVariable("" + Z.parameters.variable.name);
					image = new Bitmap(bmd);
					image.smoothing = true;
					container2.addChild(image);
					bounds = image.getBounds(null);
					originalReferenceX = -bounds.x;
					originalReferenceY = -bounds.y;
					originalWidth = bounds.width;
					originalHeight = bounds.height;
					Z.hat.magicast_setBounds(bounds);
				} catch (e:Error) {
				}
			}
			// NEW SYNTAX
			if (!image && "" + Z.parameters.value) {
				try {
					bmd = Z.hat.magicast_resolveAndGetValue(Z.parameters.value[0]);
					image = new Bitmap(bmd);
					image.smoothing = true;
					container2.addChild(image);
					bounds = image.getBounds(null);
					originalReferenceX = -bounds.x;
					originalReferenceY = -bounds.y;
					originalWidth = bounds.width;
					originalHeight = bounds.height;
					Z.hat.magicast_setBounds(bounds);
				} catch (e:Error) {
				}
			}			
		}
	}
}
