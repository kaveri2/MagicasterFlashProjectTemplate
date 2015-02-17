package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.events.Event;
	import flash.events.MouseEvent;

	import flash.ui.Multitouch;
	import flash.events.TouchEvent;
	import flash.events.Event;
	import flash.geom.Matrix;
	
	public class int_2012_ugc_canvas extends MovieClip {
		
		public function int_2012_ugc_canvas(Z:*) {
			
			var superSampleFactor:Number = Z.parameters.superSampleFactor[0] ? parseFloat(Z.parameters.superSampleFactor) : 1;
			var color:uint = Z.parameters.brushColor[0] ? parseInt(Z.parameters.brushColor) : (Z.parameters.color[0] ? parseInt(Z.parameters.color) : 0x000000);
			var alpha:Number = Z.parameters.brushAlpha[0] ? parseFloat(Z.parameters.brushAlpha) / 100 : (Z.parameters.alpha[0] ? parseFloat(Z.parameters.alpha) / 100 : 1);
			var thickness:Number = Z.parameters.brushThickness[0] ? parseFloat(Z.parameters.brushThickness) : (Z.parameters.thickness[0] ? parseFloat(Z.parameters.thickness) : 4);
			var blendMode:String = Z.parameters.brushBlendMode[0] ? "" + Z.parameters.brushBlendMode : (Z.parameters.blendMode[0] ? "" + Z.parameters.blendMode : "normal");
			var variableName = "" + Z.parameters.variable.name;
			var scale:String = Z.parameters.scale[0] ? "" + Z.parameters.scale : "";
			
			var originalWidth;
			var originalHeight;
						
			var linesToRemove:Array = new Array();
			
			var pointers:Array = new Array();
			var maxPointerIndex:int = 0;

			var container:Sprite = new Sprite();
			addChild(container);
			var bitmapData:BitmapData;
			var canvas:Bitmap = new Bitmap();
			container.addChild(canvas);
			var linesMask:Sprite = new Sprite();
			container.addChild(linesMask);	
			linesMask.graphics.beginFill(0x000000, 0);
			linesMask.graphics.drawRect(0, 0, 100, 100);
			var lines:Sprite = new Sprite();
			container.addChild(lines);
			lines.mask = linesMask;
			var hit:Sprite = new Sprite();
			container.addChild(hit);	
			hit.graphics.beginFill(0x000000, 0);
			hit.graphics.drawRect(0, 0, 100, 100);
			
			var m:Matrix;
			
			var image:*;
			if ("" + Z.parameters.imageAsset != "") {
				Z.autoReady = false;
				image = Z.create(Z.parameters.imageAsset[0]);
				image.bind("ready", Z.wrap(function():void {
					try {
						image.content.smoothing = true;
					} catch (e:Error) {
					}
					bitmapData = new BitmapData(image.width * superSampleFactor, image.height * superSampleFactor, true, 0x00000000);
					canvas.bitmapData = new BitmapData(image.width * superSampleFactor, image.height * superSampleFactor);
					m = new Matrix();
					m.scale(superSampleFactor, superSampleFactor);
					bitmapData.draw(image, m);
					linesMask.width = hit.width = originalWidth = bitmapData.width;
					linesMask.height = hit.height = originalHeight = bitmapData.height;
					Z.ready();
				}));
			} else if ("" + Z.parameters.imageData != "") {
				var bmd:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.imageData[0]);
				bitmapData = new BitmapData(bmd.width * superSampleFactor, bmd.height * superSampleFactor, true, 0x00000000);
				canvas.bitmapData = new BitmapData(image.width * superSampleFactor, image.height * superSampleFactor);
				m = new Matrix();
				m.scale(superSampleFactor, superSampleFactor);
				bitmapData.draw(bmd, m);
				linesMask.width = hit.width = originalWidth = bitmapData.width;
				linesMask.height = hit.height = originalHeight = bitmapData.height;
			} else {
				canvas.bitmapData = new BitmapData(100 * superSampleFactor, 100 * superSampleFactor);
				linesMask.width = hit.width = originalWidth = 100;
				linesMask.height = hit.height = originalHeight = 100;
			}
						
			var requestUpdateCanvas:int = 2;
			
			Z.hat.magicast_adjust = function(width, height, aspectRatio) {
				
				var w:Number, h:Number;
				
				if (width) {
					w = width;
				} else if (aspectRatio) {
					w = (height ? height : originalHeight) * aspectRatio;
				} else {
					w = originalWidth;
				}
				if (height) {
					h = height;
				} else if (aspectRatio) {
					h = (width ? width : originalWidth) / aspectRatio;
				} else {
					h = originalHeight;
				}
				
				w = Math.floor(w);
				h = Math.floor(h);
								
				// size changed more than 1%?
				if (Math.abs(w - originalWidth) > originalWidth / 100 || Math.abs(h - originalHeight) > originalHeight / 100) {	
					
					var bmd:BitmapData;
					
					var stopped:Boolean = false;
					bmd = new BitmapData(w * superSampleFactor, h * superSampleFactor, true, 0x00000000);
					if (bitmapData) {
						bmd = new BitmapData(w * superSampleFactor, h * superSampleFactor, true, 0x00000000);
						var scaleWidth:Boolean = (scale == "both" || (scale == "down" && w < originalWidth) || (scale == "up" && w > originalWidth));
						var scaleHeight:Boolean = (scale == "both" || (scale == "down" && h < originalHeight) || (scale == "up" && h > originalHeight));
						if (scaleWidth || scaleHeight) {
							for (var i:int = 0; i <= maxPointerIndex; i++) {
								var pointer:* = pointers[i];
								if (pointer) {
									endDrawing(pointer);
									delete pointers[0];
									stopped = true;
								}
							}
						}
						var m:Matrix = new Matrix();
						m.scale(
							scaleWidth ?  w / originalWidth : 1,
							scaleHeight ?  h / originalHeight : 1);
						bmd.draw(bitmapData, m, null, null, null, true);
						bitmapData.dispose();
					}
					bitmapData = bmd;
					
					bmd = new BitmapData(w * superSampleFactor, h * superSampleFactor, true, 0x00000000);
					canvas.bitmapData.dispose();
					canvas.bitmapData = bmd;
					canvas.smoothing = true;
					canvas.scaleX = canvas.scaleY = 1 / superSampleFactor;
					
					requestUpdateCanvas = 2;
					
					linesMask.width = hit.width = originalWidth = w;
					linesMask.height = hit.height = originalHeight = h;
					
					Z.hat.magicast_setBounds(new Rectangle(0, 0, w, h));
					
					if (stopped) {
						updateVariable();
						Z.hat.magicast_triggerEvent("endDrawing");	
					}
				}				
				
				if (requestUpdateCanvas > 0) {
					updateCanvas();
					requestUpdateCanvas = 0;
				}				
			}
			
			Z.bind("tick", function(time:Number) {
				for (var i:int = 0; i <= maxPointerIndex; i++) {
					var pointer:* = pointers[i];
					if (pointer) {
						continueDrawing(pointer);
					}
				}
			});
			
			Z.hat.magicast_runAction = function(method:String, parameters:XML) {
				// OLD SYNTAX
				if (method=="setVariable") {
					if ("" + parameters.name) {
						variableName = "" + parameters.name;
						updateVariable();
					}
				}
				if (method=="setBrushThickness") {
					thickness = parseFloat(Z.hat.magicast_resolveAndGetValue(parameters.value[0]));
				}
				if (method=="setBrushColor") {
					color = parseInt(Z.hat.magicast_resolveAndGetValue(parameters.value[0]));
				}
				if (method=="setBrushAlpha") {
					alpha = parseFloat(Z.hat.magicast_resolveAndGetValue(parameters.value[0])) / 100;
				}
				if (method=="setBrushBlendMode") {
					blendMode = "" + Z.hat.magicast_resolveAndGetValue(parameters.value[0]);
				}
				if (method=="draw") {
					// TODO
					requestUpdateCanvas = 2;
				}
				if (method=="clearCanvas") {
					bitmapData.fillRect(bitmapData.rect, 0x00000000);
					requestUpdateCanvas = 2;
					updateVariable();
				}
				if (method=="fillCanvas") {
					bitmapData.fillRect(bitmapData.rect, parseInt(Z.hat.magicast_resolveAndGetValue(parameters.colorValue[0])));
					requestUpdateCanvas = 2;
					updateVariable();
				}
				if (method=="stopDrawing") {
					for (var i:int = 0; i <= maxPointerIndex; i++) {
						var pointer:* = pointers[i];
						endDrawing(pointer);
						delete pointers[0];
					}
					updateVariable();
				}
			};			
			
			if (Z.mahti.multitouch) {
				
				Z.wrapEventListener(hit, TouchEvent.TOUCH_BEGIN, function(e:TouchEvent) {
					maxPointerIndex = Math.max(maxPointerIndex, e.touchPointID);
					var line:Sprite = new Sprite();
					if (blendMode != "normal") {
						line.visible = false;
					}
					var pointer:* = {
						line: line,
						drawCoords: null,
						drawCommands: null,
						thickness: thickness,
						color: color,
						alpha: alpha,
						blendMode: blendMode,
						p: new Point(e.stageX, e.stageY)
					};
					pointers[e.touchPointID] = pointer;
					startDrawing(pointer);
					requestUpdateCanvas = 1;
					Z.hat.magicast_triggerEvent("startDrawing");
				});

				Z.wrapEventListener(hit, TouchEvent.TOUCH_MOVE, function(e:TouchEvent) {
					var pointer:* = pointers[e.touchPointID];
					if (pointer) {
						pointer.p = new Point(e.stageX, e.stageY);
					}
				});

				Z.wrapEventListener(hit, TouchEvent.TOUCH_END, function(e:TouchEvent) {
					var pointer:* = pointers[e.touchPointID];
					if (pointer) {
						endDrawing(pointer);
						delete pointers[e.touchPointID];
						updateVariable();
						Z.hat.magicast_triggerEvent("endDrawing");	
					}
				});

				Z.wrapEventListener(hit, TouchEvent.TOUCH_ROLL_OUT, function(e:TouchEvent) {
					var pointer:* = pointers[e.touchPointID];
					if (pointer) {
						endDrawing(pointer);
						delete pointers[e.touchPointID];
						updateVariable();
						Z.hat.magicast_triggerEvent("endDrawing");	
					}
				});
				
			} else {
				
				Z.wrapEventListener(hit, MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
					var pointer:* = pointers[0];
					if (pointer) {
						pointer.p = new Point(e.stageX, e.stageY);
					}
				});

				Z.wrapEventListener(hit, MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
					var line = new Sprite();
					if (blendMode != "normal") {
						line.visible = false;
					}
					var pointer:* = {
						line: line,
						drawCoords: null,
						drawCommands: null,
						thickness: thickness,
						color: color,
						alpha: alpha,
						blendMode: blendMode,
						p: new Point(e.stageX, e.stageY)
					};
					pointers[0] = pointer;
					startDrawing(pointer);
					requestUpdateCanvas = 1;
					Z.hat.magicast_triggerEvent("startDrawing");
				});

				Z.wrapEventListener(hit, MouseEvent.MOUSE_UP, function(e:MouseEvent) {
					var pointer:* = pointers[0];
					if (pointer) {
						endDrawing(pointer);
						delete pointers[0];
						updateVariable();
						Z.hat.magicast_triggerEvent("endDrawing");	
					}
				});

				Z.wrapEventListener(hit, MouseEvent.MOUSE_OUT, function(e:MouseEvent) {
					var pointer:* = pointers[0];
					if (pointer) {
						endDrawing(pointer);
						delete pointers[0];
						updateVariable();
						Z.hat.magicast_triggerEvent("endDrawing");	
					}
				});				
			}
			
			function updateCanvas() {
				var i:int;
				var pointer:*;
				var cont:Boolean = requestUpdateCanvas == 2;
				
				var line:*;
				while (line = linesToRemove.pop()) {
					lines.removeChild(line);
				}
				
				if (!cont) {
					for (i = 0; i <= maxPointerIndex; i++) {
						pointer = pointers[i];
						if (pointer && pointer.blendMode != "normal") {
							cont = true;
						}
					}
					if (!cont) {
						return;
					}
				}
				var m:Matrix = new Matrix();
				m.scale(superSampleFactor, superSampleFactor);
				canvas.bitmapData.fillRect(canvas.bitmapData.rect, 0);
				canvas.bitmapData.draw(bitmapData);
				for (i = 0; i <= maxPointerIndex; i++) {
					pointer = pointers[i];
					if (pointer && pointer.blendMode != "normal") {
						canvas.bitmapData.draw(pointer.line, m, null, pointer.blendMode, null, true);
					}
				}
			}
			
			function startDrawing(pointer) {
				var p:Point = lines.globalToLocal(pointer.p);
				pointer.drawCoords = new Vector.<Number>();
				pointer.drawCommands = new Vector.<int>();
				pointer.line.graphics.clear();
				if (pointer.x != null) {
					pointer.line.graphics.beginFill(pointer.color, pointer.alpha);
					pointer.line.graphics.drawCircle(pointer.x, pointer.y, pointer.thickness / 2);
					pointer.drawCoords.push(pointer.x, pointer.y);
					pointer.drawCommands.push(1);				
					pointer.x = p.x;
					pointer.y = p.y;
					pointer.drawCoords.push(pointer.x, pointer.y);
					pointer.drawCommands.push(2);
				} else {
					pointer.x = p.x;
					pointer.y = p.y;
					pointer.line.graphics.beginFill(pointer.color, pointer.alpha);
					pointer.line.graphics.drawCircle(pointer.x, pointer.y, pointer.thickness / 2);
					pointer.drawCoords.push(pointer.x, pointer.y);
					pointer.drawCommands.push(1);				
				}
				lines.addChild(pointer.line);
			}
			
			function continueDrawing(pointer) {
				var p:Point = lines.globalToLocal(pointer.p);
				if (pointer.x != p.x || pointer.y != p.y) {
					pointer.x = p.x;
					pointer.y = p.y;
					pointer.drawCoords.push(pointer.x, pointer.y);
					pointer.drawCommands.push(2);
					pointer.line.graphics.clear();
					pointer.line.graphics.lineStyle(pointer.thickness, pointer.color, pointer.alpha);
					pointer.line.graphics.drawPath(pointer.drawCommands, pointer.drawCoords);					
					requestUpdateCanvas = 1;
				}
			}
			
			function endDrawing(pointer) {
				var m:Matrix = new Matrix();
				m.scale(superSampleFactor, superSampleFactor);
				bitmapData.draw(pointer.line, m, null, pointer.blendMode, null, true);
				linesToRemove.push(pointer.line);
				requestUpdateCanvas = 2;
			}
			
			// OLD SYNTAX
			function updateVariable() {
				if (variableName) {
					var bmd:BitmapData = new BitmapData(originalWidth, originalHeight, true, 0x00000000);
					m = new Matrix();
					m.scale(1 / superSampleFactor, 1 / superSampleFactor);
					bmd.draw(bitmapData, m);
					Z.hat.magicast_hat.setVariable(variableName, bmd);
				}
			}
			
		}
	}
}
