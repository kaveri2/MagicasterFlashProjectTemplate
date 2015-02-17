package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.external.ExternalInterface;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Bitmap;
	import flash.filters.DropShadowFilter;
	import flash.filters.BlurFilter;
	import flash.filters.BitmapFilter;
	import flash.geom.Matrix;
	import flash.geom.ColorTransform;
		
	public class core_example_styler extends MovieClip {

		public function core_example_styler(Z:*) {
			Z.hat.plugin = function() {

				var extension:* = Z.createHat();
				Z.parent.registerExtension("styler", extension);
				
				function create(styled:Sprite, content:DisplayObject, parameters:*, extra:*) {
					if (!parameters) {
						parameters = XML("<root></root>");					
					} if (parameters is XMLList) {
						parameters = XML("<root>" + parameters.toXMLString() + "</root>");
					}
					
					var space:Number = 32;
					
					var bounds:Rectangle;
					var bmd:BitmapData;
					var m:Matrix;
					
					var tmp:Sprite = new Sprite();
					
					var type:String = "" + parameters.type;
					if (type=="" || type=="none") {
						styled.addChild(content);
						return;
					}
					
					var parent:DisplayObjectContainer = content.parent;
					var index:int;
					if (parent) {
						index = parent.getChildIndex(content);
					}
					tmp.addChild(content);
					
					bounds = tmp.getBounds(null);
					bmd = new BitmapData((bounds.width + space * 2) * 2, (bounds.height + space * 2) * 2, true, 0x00000000);
			
					m = new Matrix();
					m.translate(-bounds.x + space, -bounds.y + space);
					m.scale(2, 2);
					bmd.draw(tmp, m, null, null, null, true);
					
					var shadowOnly:Boolean = true;

					if ("" + parameters.border!="false") {
						shadowOnly = false;
						
						var blur:Number;
						switch (type) {
							case "pressable":
								blur = 7;
								break;
							case "pressed":
								blur = 7;
								break;
							case "draggable":
								blur = 7;
								break;
							case "dragged":
								blur = 7;
								break;
							case "component":
								blur = 7;
								break;
							default:
								blur = 7;
								break;
						}
						
						bmd.applyFilter(
								bmd, 
								new Rectangle(0, 0, bmd.width, bmd.height), 
								new Point(0, 0), 
								new BlurFilter(7, 7, 15)
							);
						bmd.threshold(
								bmd, 
								new Rectangle(0, 0, bmd.width, bmd.height), 
								new Point(0, 0), 
								">",
								0x00000000,
								0xffffffff,
								0xff000000
							);
							
							if ("" + parameters.borderShadow=="true") {
							
							}
					}

					if ("" + parameters.content!="false") {
						shadowOnly = false;
					}

					if ("" + parameters.shadow!="false") {
						if (shadowOnly) {
							bmd.colorTransform(bmd.rect, new ColorTransform(0, 0, 0, 1, 0, 0, 0, 0));
						}
						var f:BitmapFilter;
						switch (type) {
							case "pressable":
								f = new DropShadowFilter(8, 45, 0x000000, 1, 8, 8, 1, 15);
								break;
							case "pressed":
								f = new DropShadowFilter(2, 45, 0x000000, 1, 4, 4, 0.5, 15);
								break;
							case "draggable":
								f = new DropShadowFilter(4, 45, 0x000000, 1, 8, 8, 0.75, 15);
								break;
							case "dragged":
								f = new DropShadowFilter(8, 45, 0x000000, 1, 16, 16, 1.5, 15);
								break;
							case "component":
								f = new DropShadowFilter(0, 0, 0x000000, 1, 4, 4, 1, 15);
								break;
							default:
								f = new DropShadowFilter(8, 45, 0x000000, 1, 16, 16, 1, 15);
								break;
						}
						if (f) {
							bmd.applyFilter(
									bmd, 
									new Rectangle(0, 0, bmd.width, bmd.height), 
									new Point(0, 0), 
									f
								);
						}
					}

					var bm:Bitmap = new Bitmap();

					var cropBounds:Rectangle = bmd.getColorBoundsRect(0xffffffff, 0x00000000, false);
					if (cropBounds.width && cropBounds.height) {
						var cropBmd:BitmapData = new BitmapData(Math.ceil(cropBounds.width / 2), Math.ceil(cropBounds.height / 2), true, 0x00000000);
						m = new Matrix();
						m.translate(-cropBounds.x, -cropBounds.y);
						m.scale(0.5, 0.5);
						cropBmd.draw(bmd, m, null, null, new Rectangle(0, 0, bmd.width, bmd.height), true);

						if ("" + parameters.content!="false") {
							m = new Matrix();
							m.translate(space - cropBounds.x / 2 - bounds.x, space - cropBounds.y / 2 - bounds.y);
							cropBmd.draw(tmp, m, null, null, null, true);
						}
						
						bmd.dispose();
						bmd = null;						

						bm.bitmapData = cropBmd;
						bm.smoothing = true;
						bm.x = bounds.x - space + cropBounds.x / 2;
						bm.y = bounds.y - space + cropBounds.y / 2;
					}
					
					styled.addChild(bm);
					
					if (parent) {
						parent.addChildAt(content, index);
					}
					
				}
					
				extension.create = function(content:DisplayObject, parameters:*, extra:* = null) {
					var styled:Sprite = new Sprite();
					create(styled, content, parameters, extra);
					return styled;
				};
				
				extension.update = function(styled:DisplayObject, content:DisplayObject, parameters:*, extra:* = null) {
					try {
						while (true) {
							DisplayObjectContainer(styled).removeChildAt(0)
						}
					} catch (e:Error) { }
					create(styled, content, parameters, extra);
				}
				
				extension.destroy = function(styled:DisplayObject) {
				
				};
			};
		}
	}
}
