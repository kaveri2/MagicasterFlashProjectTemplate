package  {
	
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import fl.motion.Animator;
	import com.coreyoneil.collision.CollisionList;
	import com.adobe.utils.ArrayUtil;
	
	public class core_magicast extends MovieClip {
		
		function isNumber(s:String) : Boolean {
//			trace("isNumber '" + s + "' = " + Boolean(s.match(/^-?[0-9]*.?[0-9]*$/)));
			if (!s) return false;
			return Boolean(s.match(/^-?[0-9]*.?[0-9]*$/));
		}

		var Z:*;
		
		var visibilityTest1:Sprite;
		var visibilityTest2:Sprite;
		
		var THIS:* = this;
		var background:Sprite;
				
		var spriteReloadWait:Number = 5;

		var xml:XML;
		
		var id:int;
		var variables:Object;

		var nodeChangeInProgress:Boolean;
		
		var format:String; 
		
		var debugMode:Boolean;
		var debugStartTime:Number;
		var debugGrid:Sprite;
		var debugWindowContainer:Sprite;
		var debugWindow:core_magicast_DebugWindow;
		
		var layers:Array;
		var newLayers:Array;
		var orderedTriggers:Array;
		var triggers:Array;
		var newTriggers:Array;
		
		var nodeName:String;
		var nodeXML:XML;
		
		var properties:Object;
		var calculations:Object;
			
		// for calculating camera's DX and DY when dragging
		var cameraMoveOldX:Number;
		var cameraMoveOldY:Number;
				
		// for scrolling and dragging
		var cameraPointerIndex:Number;
		var cameraDragStartPointerX:Number;
		var cameraDragStartPointerY:Number;
		var cameraDragStartX:Number;
		var cameraDragStartY:Number;
		var cameraDragged:Boolean;
		
		var layersContainer:Sprite;
		var debugLayersContainer:Sprite;
		
		var pointers:Array;
		var pointerLayers:Array;
		var clickDisablers:Array;
		
		// NEW SYNTAX
		var collisionDetectionGroups:Array;
				
		public function core_magicast(_Z:*) {

			Z = _Z;
						
			xml = Z.parameters;

			// helpers for visibility testing
			visibilityTest1 = new Sprite();
			this.addChild(visibilityTest1);
			visibilityTest1.graphics.drawRect(0, 0, 1, 1);
			visibilityTest2 = new Sprite();
			this.addChild(visibilityTest2);
			visibilityTest2.graphics.drawRect(0, 0, 1, 1);			
			
			background = new Sprite();
			this.addChild(background);

			// initialize empty triggers and layers
			triggers = new Array();
			layers = new Array();
			
			collisionDetectionGroups = new Array();
			
			format = "" + xml.format;			
			debugMode = "" + xml.debug == "true";
			
			properties = {
				cameraRelX: 50,
				cameraRelY: 50,
				cameraMoveX: 0,
				cameraMoveY: 0,
				cameraMoveDX: 0,
				cameraMoveDY: 0
			};
			
			calculations = {
				cameraX: 0,
				cameraY: 0
			};
				
			pointers = new Array();
			pointerLayers = new Array();
			clickDisablers = new Array();
			
			cameraPointerIndex = -1;
			cameraDragged = false;
			
			variables = new Object();
			
			function pointerEnter(index:int, p:Point, e:Event) {
				//trace("pointerEnter " + index + " " + p + " " + e.target);
				
				pointers[index] = new Point();
				pointers[index].x = Math.max(0, Math.min(Z.targetWidth, p.x));
				pointers[index].y = Math.max(0, Math.min(Z.targetWidth, p.y));
			}
				
			function pointerLeave(index:int, p:Point, e:Event) {
				//trace("pointerLeave " + index + " " + p + " " + e.target);
				var layer = pointerLayers[index];
				if (layer && layer.properties.moveMethod == "drag") {
					layer.dragged = false;
				}
				delete pointerLayers[index];
			}
			
			function pointerMove(index:int, p:Point, e:Event) {
				//trace("pointerMove " + index + " " + p + " " + e.target);
				
				pointers[index] = new Point(Math.max(0, Math.min(Z.targetWidth, p.x)), Math.max(0, Math.min(Z.targetWidth, p.y)));
				
				var layer = pointerLayers[index];
				if (layer && layer.properties.moveMethod == "drag") {
					layer.dragged = true;
				} else if (cameraPointerIndex == index) {
					if (cameraDragged || Math.pow(pointers[cameraPointerIndex].x - cameraDragStartPointerX, 2) +  Math.pow(pointers[cameraPointerIndex].y - cameraDragStartPointerY, 2) > Math.pow(properties.cameraMoveDragRadius, 2)) {
						cameraDragged = true;
						e.stopImmediatePropagation();
					}
				}
			}
			
			function pointerDown1(index:int, p:Point, e:Event) {
				//trace("pointerDown1 " + index + " " + p + " " + e.target);
				
				pointers[index] = new Point(Math.max(0, Math.min(Z.targetWidth, p.x)), Math.max(0, Math.min(Z.targetWidth, p.y)));
				
				// new pointer
				if (cameraPointerIndex == index) {
					cameraPointerIndex = -1;
				}
				
				// should not be possible...
				var layer = pointerLayers[index];
				if (layer && layer.properties.moveMethod == "drag") {
					layer.dragged = false;
				}
				delete pointerLayers[index];
			}	
			
			function pointerDown2(index:int, p:Point, e:Event) {
				//trace("pointerDown2 " + index + " " + p + " " + e.target);

				var layer = pointerLayers[index];
				if (layer && layer.properties.moveMethod == "drag") {
					// draggable layer, don't move camera
				} else if (properties.cameraMoveMethod == "drag") {
					cameraPointerIndex = index;
					cameraDragStartPointerX = pointers[cameraPointerIndex].x;
					cameraDragStartPointerY = pointers[cameraPointerIndex].y;
					cameraDragStartX = properties.cameraMoveX;
					cameraDragStartY = properties.cameraMoveY;
				}
			}
			
			function pointerUp(index:int, p:Point, e:Event) {
				//trace("pointerUp " + index + " " + p + " " + e.target);
				
				clickDisablers[index] = false;
				
				// dragging camera, don't let the event pass forward
				if (cameraPointerIndex == index) {
					if (cameraDragged) {
						cameraDragged = false;
						clickDisablers[index] = true;
						e.stopImmediatePropagation();
					}
					// forget pointer
					cameraPointerIndex = -1;
				} else {
					var layer = pointerLayers[index];
					if (layer) {
						if (layer.properties.moveMethod == "drag") {
							// trigger dragEnd even if dragging didn't actually happen
							triggerEvent(layer.name, "dragEnd");
							// dragging layer, don't let the event pass forward
							if (layer.dragged) {
								layer.dragged = false;
								clickDisablers[index] = true;
								e.stopImmediatePropagation();
							}
						}
						delete pointerLayers[index];
					}
				}
			}
			
			function pointerClick(index:int, p:Point, e:Event) {
				//trace("pointerClick " + index + " " + p + " " + e.target);
				
				var newX:Number, newY:Number, time:Number;
				
				if (clickDisablers[index]) {
					e.stopImmediatePropagation();
				} else {
					
					if (properties.cameraMoveMethod == "click") {
						var scale:Number = (1 + (1 - 1) / properties.cameraParallaxLevel) / properties.cameraParallaxLevel;
						newX = ((p.x - (Z.targetWidth / 2 - properties.cameraMoveX * scale)) / scale) / calculations.width * 100;
						newY = ((p.y - (Z.targetHeight / 2 - properties.cameraMoveY * scale)) / scale) / calculations.height * 100;
						time = 
							properties.cameraMoveClickSpeed ? 
								Math.sqrt(Math.pow(properties.cameraMoveX - newX, 2) + Math.pow(properties.cameraMoveY - newY, 2)) :
								properties.cameraMoveClickTime;
						if (time) {
							Z.tweener.start(
								properties, 
								["cameraMoveX", "cameraMoveY"], 
								[newX, newY], 
								time,
								properties.cameraMoveClickEase
							);
						} else {
							properties.cameraMoveX = newX;
							properties.cameraMoveY = newY;
						}
					}
				
					var i:*;
					for (i in layers) {
						var layer:* = layers[i];
						if (layer.properties.moveMethod == "click") {
							newX = p.x - (layer.calculations.x - layer.properties.moveX);
							newY = p.y - (layer.calculations.y - layer.properties.moveY);
							time =
								layer.properties.moveClickSpeed ? 
									Math.sqrt(Math.pow(layer.properties.moveX - newX, 2) + Math.pow(layer.properties.moveY - newY, 2)) :
									layer.properties.moveClickTime;
							if (time) {
								Z.tweener.start(
									layer.properties, 
									["moveX", "moveY"], 
									[newX, newY], 
									time,
									layer.properties.moveClickEase
								);
							} else {
								layer.properties.moveX = newX;
								layer.properties.moveY = newY;
							}
						}
					}
				}
			}

			if (Z.mahti.multitouch) {
				Z.wrapEventListener(this, TouchEvent.TOUCH_ROLL_OVER, function(e:TouchEvent) {
					pointerEnter(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, false);
				Z.wrapEventListener(this, TouchEvent.TOUCH_ROLL_OUT, function(e:TouchEvent) {
					pointerLeave(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, false);
				Z.wrapEventListener(this, TouchEvent.TOUCH_MOVE, function(e:TouchEvent) {
					pointerMove(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
				Z.wrapEventListener(this, TouchEvent.TOUCH_BEGIN, function(e:TouchEvent) {
					pointerDown1(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
				Z.wrapEventListener(this, TouchEvent.TOUCH_BEGIN, function(e:TouchEvent) {
					pointerDown2(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, false);
				Z.wrapEventListener(this, TouchEvent.TOUCH_END, function(e:TouchEvent) {
					pointerUp(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
				Z.wrapEventListener(this, TouchEvent.TOUCH_TAP, function(e:TouchEvent) {
					pointerClick(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
			} else {
				Z.wrapEventListener(this, MouseEvent.ROLL_OVER, function(e:MouseEvent) {
					pointerEnter(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, false);
				Z.wrapEventListener(this, MouseEvent.ROLL_OUT, function(e:MouseEvent) {
					pointerLeave(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, false);
				Z.wrapEventListener(this, MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
					pointerMove(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
				Z.wrapEventListener(this, MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
					pointerDown1(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
				Z.wrapEventListener(this, MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
					pointerDown2(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, false);
				Z.wrapEventListener(this, MouseEvent.MOUSE_UP, function(e:MouseEvent) {
					pointerUp(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
				Z.wrapEventListener(this, MouseEvent.CLICK, function(e:MouseEvent) {
					pointerClick(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)), e);
				}, true);
			}
				
			layersContainer = new Sprite();
			layersContainer.mouseEnabled = false;
			addChild(layersContainer);
			
			if (debugMode) {
								
				debugLayersContainer = new Sprite();
				debugLayersContainer.mouseEnabled = false;
				debugLayersContainer.mouseChildren = false;
				addChild(debugLayersContainer);
				
				debugGrid = new Sprite();
				debugGrid.mouseEnabled = false;
				addChild(debugGrid);
				
				debugWindowContainer = new Sprite();
				debugWindowContainer.mouseEnabled = false;
				addChild(debugWindowContainer);

				debugWindow = new core_magicast_DebugWindow();
				debugWindow.mouseEnabled = false;
				debugWindowContainer.addChild(debugWindow);
				
				debugWindow.text.text = "";
				debugWindow.alpha = 0.80;
				debugWindow.x = 10;
				debugWindow.y = 10;
				debugStartTime = getTimer();
			
				debugWindow.text.selectable = false;
				debugWindow.text.mouseEnabled = false;
				debugWindow.buttons.sel.gotoAndStop(1);
				Z.wrapEventListener(debugWindow.buttons.sel, MouseEvent.CLICK, function() {
					if (debugWindow.buttons.sel.currentFrame==1) {
						debugWindow.buttons.sel.gotoAndStop(2);
						debugWindow.text.selectable = true;
						debugWindow.text.mouseEnabled = true;
					} else {
						debugWindow.buttons.sel.gotoAndStop(1);
						debugWindow.text.selectable = false;
						debugWindow.text.mouseEnabled = false;
					}
				});
			
				debugWindow.buttons.big.gotoAndStop(1);
				Z.wrapEventListener(debugWindow.buttons.big, MouseEvent.CLICK, function() {
					if (debugWindow.buttons.big.currentFrame==1) {
						debugWindow.buttons.big.gotoAndStop(2);
					} else {
						debugWindow.buttons.big.gotoAndStop(1);
					}
					doResize();
				});
			
				Z.wrapEventListener(debugWindow.buttons.node, Event.CHANGE, function(e:Event) {
					changeNode(e.currentTarget.text);
				});
				
				Z.wrapEventListener(debugWindow.buttons.grid, Event.CHANGE, function(e:Event) {
					drawDebugGrid();
				});
				
			}
			
			Z.registerAssetURLRequestBuilder("random", function(value:*) {
				var totalWeight:Number = 0;
				for (var i:int=0 ; i<value.option.length() ; i++) {
					totalWeight = totalWeight + parseFloat(value.option[i].weight);
				}
				var randomWeight = Math.random() * totalWeight;
				var weight = 0;
				var index = -1;
				while (weight < randomWeight) {
					index = index + 1;
					weight = weight + parseFloat(value.option[index].weight);
				}
				if (index > -1) {
					return Z.buildAssetURLRequest(value.option[index].value[0]);
				}
			});
			
			Z.registerAssetURLRequestBuilder("conditional", function(value:*) {
				for (var i:int=0 ; i<value["case"].length() ; i++) {
					if (checkConditions(value["case"][i].condition)) {
						return Z.buildAssetURLRequest(value["case"][i].value);
					}
				}
			});			
				
			Z.bind("destroy", Z.wrap(function() {			   
			
				var i:*;
				for (i in layers) {
					Z.tweener.stop(layers[i].properties);
					removeLayerSprite(layers[i]);
					delete layers[i];
				}
				layers = null;
				for (i in newLayers) {
					Z.tweener.stop(newLayers[i].properties);
					removeLayerSprite(newLayers[i]);
					delete newLayers[i];
				}
				newLayers = null;
				for (i in triggers) {
					delete triggers[i];
				}
				triggers = null;
				for (i in newTriggers) {
					delete newTriggers[i];
				}
				newTriggers = null;

				var s:*;
				try {
					while(true) {
						s = debugLayersContainer.getChildAt(0);
						debugLayersContainer.removeChild(s);
					}
				} catch (e) {
				}
				
			}));

			Z.hat.setVariable = function(name, value) {
				return setVariable(name, value);
			};
			
			Z.hat.getVariable = function(name) {
				return getVariable(name);
			};
			
			Z.hat.changeProperty = function(property:*, value:*, time:Number, ease:String = "", wait:Number = 0, completeEvent:* = null) {
				changeProperty(property, value, time, ease, wait, completeEvent);
			};
			
			Z.hat.getLayerProperties = function(layerName:String) {
				if (layers["name_" + layerName]) return layers["name_" + layerName].properties;
				return undefined;
			};
			
			Z.hat.getLayerSprite = function(layerName:String) {
				if (layers["name_" + layerName]) return layers["name_" + layerName].zprite;
				return undefined;
			};
			
			Z.hat.resolveAndTriggerEvent = function(parameters:*) {
				resolveAndTriggerEvent(null, parameters);
			};
			
			Z.hat.triggerEvent = function(layerName:String, eventName:String, arguments:Object = undefined, point:Point = undefined) {
				triggerEvent(layerName, eventName, arguments, point);
			};
			
			Z.hat.runAction = function(layerName:String, method:String, parameters:XML, eventArguments:Object = undefined, eventPoint:Point = undefined) {
				runAction(layerName, method, parameters, eventArguments, eventPoint);
			};
						
			Z.hat.update = function(newXml:XMLList) {
				xml = XML("<xml>" + newXml + "</xml>");
//				changeNode("" + nodeXML.name, true);
			};

			Z.hat.run = function() {
				changeNode("" + xml.node[0].name);
			};
			
			Z.hat.properties = properties;
			
			Z.bind("tick", Z.wrap(function(time:Number) {
				tick(time);  
			}));
			
			Z.bind("targetSizeChange", Z.wrap(function() {
				doResize();
			}));
			doResize();
		}
		
		function removeFromCollisionDetection(layer) {
			for (var i:* in collisionDetectionGroups) {
				var sources = collisionDetectionGroups[i].sources;
				var targets = collisionDetectionGroups[i].targets;
				if (sources[layer.name]) {
					delete sources[layer.name];
				}
				if (targets[layer.name]) {
					delete targets[layer.name];
				}
			}
		}
		
		function applyCollisionDetectionGroup(layer:*, data:XML) {
			var name:String = "" + data.name;
			if (!collisionDetectionGroups[name]) {
				collisionDetectionGroups[name] = {
					sources: new Array(),
					targets: new Array()
				};
			}
			var sources:Array = collisionDetectionGroups[name].sources;
			var targets:Array = collisionDetectionGroups[name].targets;
			
			if ("" + data.source == "true") {
				sources[layer.name] = {
					pixelPerfect: "" + data.pixelPerfect != "false",
					layer: layer,
					result: false,
					lastResult: (sources[layer.name] ? sources[layer.name].lastResult : false)
				};
			}
			else {
				if (sources[layer.name]) {
					delete sources[layer.name];
				}
			}
			if ("" + data.target == "true") {
				targets[layer.name] = {
					pixelPerfect: "" + data.pixelPerfect != "false",
					layer: layer,
					result: false,
					lastResult: (targets[layer.name] ? targets[layer.name].lastResult : false)
				};
			}
			else {
				if (targets[layer.name]) {
					delete targets[layer.name];
				}
			}
		}
			
		function resolveAndSetVariable(variable:*, value:*) {
			setVariable("" + variable.name, value);
		}
		
		function setVariable(name, value) {
			variables[name] = value;
			debug("Variable '" + name+ "' = '" + value + "'", "#000099");
		}
		
		function getVariable(name) {
			return variables[name];
		}
		
		function doResize() {
			
			if (!Z.targetWidth || !Z.targetHeight) return;
			
			var ar:Number;
		
			if (properties.relWidth) calculations.width = Z.targetWidth * properties.relWidth / 100;
			else calculations.width = 0;
			if (properties.relHeight) calculations.height = Z.targetHeight * properties.relHeight / 100;
			else calculations.height = 0;
			if (properties.absWidth) calculations.width = calculations.width + properties.absWidth;
			if (properties.absHeight) calculations.height = calculations.height + properties.absHeight;	
						
			if (properties.maintainAspectRatio=="min") {
				ar = calculations.width / calculations.height;
				if (ar > properties.aspectRatio) {
					calculations.width = calculations.height * properties.aspectRatio;
				} else {
					calculations.height = calculations.width / properties.aspectRatio;
				}
			}
			if (properties.maintainAspectRatio=="max") {
				ar = calculations.width / calculations.height;
				if (ar > properties.aspectRatio) {
					calculations.height = calculations.width / properties.aspectRatio;
				} else {
					calculations.width = calculations.height * properties.aspectRatio;
				}
			}
			
			background.graphics.clear();
			background.graphics.lineStyle(0, 0, 0);
			background.graphics.beginFill(0x000000, 0);
			background.graphics.drawRect(0, 0, Z.targetWidth, Z.targetHeight);
			background.graphics.endFill();
			
			if (debugMode) {
				debugWindow.text.width = Z.targetWidth - 20;
				
				if (debugWindow.buttons.big.currentFrame==1) {
					debugWindow.text.height = 100;
				} else {
					debugWindow.text.height = Z.targetHeight - 20;
				}
		
				debugWindow.buttons.y = 0;
				debugWindow.buttons.x = debugWindow.text.width;		
			}
			
			tick(0);
		}
					
		function drawDebugGrid() {
			debugGrid.graphics.clear();
			var n = parseFloat(debugWindow.buttons.grid.text);
			var x:Number, y:Number;
			if (n) {
				if (n>=19) {
					debugGrid.graphics.lineStyle(1, 0x333333);
					for (x=0 ; x<calculations.width ; x=x+n) {
						debugGrid.graphics.moveTo(x, 0);
						debugGrid.graphics.lineTo(x, calculations.height);
					}
					for (y=0 ; y<calculations.height ; y=y+n) {
						debugGrid.graphics.moveTo(0, y);
						debugGrid.graphics.lineTo(calculations.width, y);
					}
				}
				debugGrid.graphics.lineStyle(1, 0x0000ff);
				for (x=0 ; x<100 ; x=x+n) {
					debugGrid.graphics.moveTo(x * calculations.width / 100, 0);
					debugGrid.graphics.lineTo(x * calculations.width / 100, calculations.height);
				}
				for (y=0 ; y<100 ; y=y+n) {
					debugGrid.graphics.moveTo(0, y * calculations.height / 100);
					debugGrid.graphics.lineTo(calculations.width, y * calculations.height / 100);
				}
			}
		}
		
		function debug(text, color) {
			//trace(text);
			if (debugMode) {
				var time = (getTimer() - debugStartTime) / 1000;
				if (!color) color = "#000000";
				text = "<font color=\"" + color + "\">" + time + ": " + text + "</font><br />";
				debugWindow.text.htmlText = text + debugWindow.text.htmlText;
			}
		}
		
		function tickLayer(layer, time) {
			
			if (layer.calculated) return;
			layer.calculated = true;
			if (!layer.ready) return;
									
			var layerProperties = layer.properties;
			
			var refFrameLayer:* = null;
			var refFrameLayerProperties:* = null;
			var refFrameLayerCalculations:* = null;
			if (layerProperties.refFrame) {
				refFrameLayer = layers["name_" + layerProperties.refFrame];
				if (refFrameLayer) {
					tickLayer(refFrameLayer, time);
					refFrameLayerProperties = refFrameLayer.properties;
					refFrameLayerCalculations = refFrameLayer.calculations;
				}
			}
			
			var layerCalculations = layer.calculations;

			// for setting targetSize
			var targetWidthSet:Boolean = false;
			var targetWidth:Number = 0;
			var targetHeightSet:Boolean = false;
			var targetHeight:Number = 0;
			
			var widthSet:Boolean = false;
			var width:Number = 0;
			var heightSet:Boolean = false;
			var height:Number = 0;

			var scale:Number;

			// default calculations
			layerCalculations.parallaxLevel = 0;
			layerCalculations.parallaxLevelX = 0;
			layerCalculations.parallaxLevelY = 0;
			layerCalculations.x = 0;
			layerCalculations.y = 0;
			layerCalculations.width = 0;
			layerCalculations.height = 0;
			layerCalculations.scaleX = layerProperties.scaleX / 100;
			layerCalculations.scaleY = layerProperties.scaleY / 100;
			layerCalculations.rotation = layerProperties.rotation;
			layerCalculations.skewX = layerProperties.skewX;
			layerCalculations.skewY = layerProperties.skewY;
			layerCalculations.alpha = layerProperties.alpha / 100;
			
			var tmp:Number, b1:Boolean, b2:Boolean;
						
			// working with magicast's width and height...			
			// layers using parallaxLevel are relative to the content area
			// other layers are relative to the viewport
		
			var tw:Number, th:Number;
			
			if (layerProperties.parallaxLevel || (refFrameLayerCalculations && refFrameLayerCalculations.parallaxLevel)) {
				tw = calculations.width / 100;
				th = calculations.height / 100;
			} else {
				tw = Z.targetWidth / 100;
				th = Z.targetHeight / 100;
			}
			
			// size & targetSize
										
			tmp = 0;
			b1 = false;
			if (layerProperties.relWidth != null) { tmp = tw * layerProperties.relWidth; b1 = true; }
			if (layerProperties.absWidth != null) { tmp = tmp + layerProperties.absWidth; b1 = true; }
			if (b1) { widthSet = true; width = tmp; }
						
			tmp = 0;
			b2 = false;
			if (layerProperties.relHeight != null) { tmp = th * layerProperties.relHeight; b2 = true; }
			if (layerProperties.absHeight != null) { tmp = tmp + layerProperties.absHeight; b2 = true; }
			if (b2) { heightSet = true; height = tmp; }
			
			tmp = 0;
			b1 = false;
			if (layerProperties.relTargetWidth != null) { tmp = tw * layerProperties.relTargetWidth; b1 = true; }
			if (layerProperties.absTargetWidth != null) { tmp = tmp + layerProperties.absTargetWidth; b1 = true; }
			if (b1) { targetWidthSet = true; targetWidth = tmp; }
	
			tmp = 0;
			b2 = false;
			if (layerProperties.relTargetHeight != null) { tmp = th * layerProperties.relTargetHeight; b2 = true; }
			if (layerProperties.absTargetHeight != null) { tmp = tmp + layerProperties.absTargetHeight; b2 = true; }
			if (b2) { targetHeightSet = true; targetHeight = tmp; }
			
			if (refFrameLayerCalculations) {

				// working with reference frame's width and height...
				
				var rtw:Number = refFrameLayerCalculations.width / 100;
				var rth:Number = refFrameLayerCalculations.height / 100;
		
				if (layerProperties.refFrameRelWidth != null) {
					widthSet = true;
					width = width + rtw * layerProperties.refFrameRelWidth;
				} 
				if (layerProperties.refFrameRelHeight != null) {
					heightSet = true;
					height = height + rth * layerProperties.refFrameRelHeight;					
				}
				
				if (layerProperties.refFrameRelTargetWidth != null) { 
					targetWidthSet = true;
					targetWidth = targetWidth + rtw * layerProperties.refFrameRelTargetWidth;
				}
				if (layerProperties.refFrameRelTargetHeight != null) {
					targetHeightSet = true; 
					targetHeight = targetHeight + rth * layerProperties.refFrameRelTargetHeight;
				}
				
			}

			// let layer adjust to given width, height, aspectRatio
			// this may change layer bounds, which affects rest of the calculations
			
			if (layer.zprite && layer.zprite.hat.magicast_adjust) {
				layer.zprite.hat.magicast_adjust(widthSet ? width : null, heightSet ? height : null, layerProperties.aspectRatio);
			}
			
			// reference point
			
			tmp = 0;
			b1 = false;
			if (layerProperties.relReferenceX != null) { tmp = (layer.originalWidth ? layer.originalWidth / 100 * layerProperties.relReferenceX : 0); b1 = true; }
			if (layerProperties.absReferenceX != null) { tmp = tmp + layerProperties.absReferenceX; b1 = true; }
			if (b1) layerCalculations.referenceX = tmp;
			else layerCalculations.referenceX = (layer.originalReferenceX ? layer.originalReferenceX : 0);

			tmp = 0;
			b2 = false;
			if (layerProperties.relReferenceY != null) { tmp = (layer.originalHeight ? layer.originalHeight / 100 * layerProperties.relReferenceY : 0); b2 = true; }
			if (layerProperties.absReferenceY != null) { tmp = tmp + layerProperties.absReferenceY; b2 = true; }
			if (b2) layerCalculations.referenceY = tmp;
			else layerCalculations.referenceY = (layer.originalReferenceY ? layer.originalReferenceY : 0);
													
			// x, y
			
			if (layerProperties.relX != null) layerCalculations.parallaxLevelX = tw * layerProperties.relX;
			if (layerProperties.absX != null) layerCalculations.parallaxLevelX = layerCalculations.parallaxLevelX + layerProperties.absX;
			if (layerProperties.selfRelX != null) layerCalculations.parallaxLevelX = layerCalculations.parallaxLevelX; // TODO
	
			if (layerProperties.relY != null) layerCalculations.parallaxLevelY = th * layerProperties.relY;
			if (layerProperties.absY != null) layerCalculations.parallaxLevelY = layerCalculations.parallaxLevelY + layerProperties.absY;
			if (layerProperties.selfRelY != null) layerCalculations.parallaxLevelY = layerCalculations.parallaxLevelY; // TODO;
			
			if (layerProperties.parallaxLevel != null) layerCalculations.parallaxLevel = layerProperties.parallaxLevel;
			
			// animator
			
			if (layer.animatorSprites.abs) {
				layerCalculations.parallaxLevelX = layerCalculations.parallaxLevelX + layer.animatorSprites.abs.x;
				layerCalculations.parallaxLevelY = layerCalculations.parallaxLevelY + layer.animatorSprites.abs.y;
				layerCalculations.rotation = layerCalculations.rotation + layer.animatorSprites.abs.rotation;
				/*layerCalculations.skewX = layerCalculations.skewX + layer.animatorSprites.abs.skewX;*/
				/*layerCalculations.skewY = layerCalculations.skewY + layer.animatorSprites.abs.skewY;*/
				layerCalculations.scaleX = layerCalculations.scaleX * layer.animatorSprites.abs.scaleX;
				layerCalculations.scaleY = layerCalculations.scaleY * layer.animatorSprites.abs.scaleY;
			}
						
			if (refFrameLayerCalculations) {
		
				// scale
				if (layerProperties.refFrameAnchorScaleX) layerCalculations.scaleX = layerCalculations.scaleX * refFrameLayerCalculations.scaleX;
				if (layerProperties.refFrameAnchorScaleY) layerCalculations.scaleY = layerCalculations.scaleY * refFrameLayerCalculations.scaleY;
			
				// rotation
				if (layerProperties.refFrameAnchorRotation) layerCalculations.rotation = layerCalculations.rotation + refFrameLayerCalculations.rotation;

				// alpha
				if (layerProperties.refFrameAnchorAlpha) layerCalculations.alpha = layerCalculations.alpha * refFrameLayerCalculations.alpha;

				// x, y
				
				if (layerProperties.refFrameAnchorX) layerCalculations.parallaxLevelX = layerCalculations.parallaxLevelX + refFrameLayerCalculations.parallaxLevelX;
				var tmpX:Number = refFrameLayer.originalWidth ? -refFrameLayerCalculations.referenceX / refFrameLayer.originalWidth * refFrameLayerCalculations.width : 0;
				if (layerProperties.refFrameAbsX != null) tmpX = tmpX + layerProperties.refFrameAbsX;
				if (layerProperties.refFrameRelX != null) tmpX = tmpX + layerProperties.refFrameRelX * refFrameLayerCalculations.width / 100;
				if (layerProperties.refFramSelfRelX != null) tmpX = tmpX; // TODO

				if (layerProperties.refFrameAnchorY) layerCalculations.parallaxLevelY = layerCalculations.parallaxLevelY + refFrameLayerCalculations.parallaxLevelY;
				var tmpY:Number = refFrameLayer.originalHeight ? -refFrameLayerCalculations.referenceY / refFrameLayer.originalHeight * refFrameLayerCalculations.height : 0;
				if (layerProperties.refFrameAbsY != null) tmpY = tmpY + layerProperties.refFrameAbsY;
				if (layerProperties.refFrameRelY != null) tmpY = tmpY + layerProperties.refFrameRelY * refFrameLayerCalculations.height / 100;
				if (layerProperties.refFramSelfRelY != null) tmpY = tmpY; // TODO
				
				// special case: 
				// if reference layer is not scaled according to parallax, the reference plane must be scaled
				if (refFrameLayerCalculations.parallaxLevel && !refFrameLayerCalculations.parallaxScale) {
					scale = properties.cameraParallaxLevel / (1 + (refFrameLayerCalculations.parallaxLevel - 1) / properties.cameraParallaxLevel);
				} else {
					scale = 1;
				}
				
				tmpX = tmpX * refFrameLayerCalculations.refFrameScaleX * scale;
				tmpY = tmpY * refFrameLayerCalculations.refFrameScaleY * scale;
				var tmpCos:Number = Math.cos(refFrameLayerCalculations.rotation / 360 * Math.PI * 2);
				var tmpSin:Number = Math.sin(refFrameLayerCalculations.rotation / 360 * Math.PI * 2);								
				layerCalculations.parallaxLevelX = layerCalculations.parallaxLevelX + (tmpX * tmpCos - tmpY * tmpSin);
				layerCalculations.parallaxLevelY = layerCalculations.parallaxLevelY + (tmpY * tmpCos + tmpX * tmpSin);
				
				// parallaxLevel
				if (layerProperties.refFrameAnchorParallaxLevel) layerCalculations.parallaxLevel = layerCalculations.parallaxLevel + refFrameLayerCalculations.parallaxLevel;
			}

			if (!targetWidthSet) targetWidth = tw * 100;
			if (!targetHeightSet) targetHeight = th * 100;
			
			layerCalculations.targetWidth = targetWidth;
			layerCalculations.targetHeight = targetHeight;
			
			if (layerProperties.maintainAspectRatio == "min" || layerProperties.maintainAspectRatio == "max") {
				width = widthSet ? width : layer.originalWidth;
				height = heightSet ? height : layer.originalHeight;
				widthSet = true;
				heightSet = true;
				tmp =  (layerProperties.aspectRatio || layer.originalAspectRatio) / (width / height);
				if (layerProperties.maintainAspectRatio == "max") {
					if (tmp>1) {
						width = width * tmp;
					} else if (tmp<1) {
						height = height / tmp;
					}
				} else {
					if (tmp>1) {
						height = height / tmp;
					} else if (tmp<1) {
						width = width * tmp;
					}
				}
			} else if (layerProperties.aspectRatio) {
				if (!widthSet && heightSet) {
					width = height * layerProperties.aspectRatio;
					widthSet = true;
				} else if (!heightSet && widthSet) {
					height = width / layerProperties.aspectRatio;
					heightSet = true;
				}
			}
			
			layerCalculations.refFrameScaleX = layerCalculations.scaleX;// * (layer.originalWidth ? (width / layer.originalWidth) : 1);
			layerCalculations.refFrameScaleY = layerCalculations.scaleY;// * (layer.originalHeight ? (height / layer.originalHeight) : 1);
			
			layerCalculations.width = (widthSet ? width : (layer.originalWidth ? layer.originalWidth : 0));
			layerCalculations.height = (heightSet ? height : (layer.originalHeight ? layer.originalHeight : 0));
			
			// converting x and y with layers using parallaxLevel
			
			if (layerCalculations.parallaxLevel) {
				scale = (1 + (layerCalculations.parallaxLevel - 1) / properties.cameraParallaxLevel) / properties.cameraParallaxLevel;
				if (layerProperties.parallaxScale) {
					layerCalculations.scaleX = layerCalculations.scaleX * scale;
					layerCalculations.scaleY = layerCalculations.scaleY * scale;
				}
				layerCalculations.x = Z.targetWidth / 2 + (layerCalculations.parallaxLevelX + layerProperties.moveX - calculations.cameraX) * scale;
				layerCalculations.y = Z.targetHeight / 2 + (layerCalculations.parallaxLevelY + layerProperties.moveY - calculations.cameraY) * scale;
			} else {
				scale = 1;
				layerCalculations.x = layerCalculations.parallaxLevelX + layerProperties.moveX;
				layerCalculations.y = layerCalculations.parallaxLevelY + layerProperties.moveY;
			}
			
			// used in calculating DX and DY, so only update when ticks have time
			if (time) {
				layer.moveOldX = layerProperties.moveX;
				layer.moveOldY = layerProperties.moveY;				
			}
	
			// in case of dragging, move under pointer and re-calculate move position
			if (layer.dragged) {
				if (layerProperties.moveMethod == "drag") {
					tmp = layer.dragStartX + (pointers[layer.pointerIndex].x - layer.dragStartPointerX);
					layerProperties.moveX = (tmp - (layerCalculations.x - layerProperties.moveX)) / scale;
					layerCalculations.x = tmp;
					tmp = layer.dragStartY + (pointers[layer.pointerIndex].y - layer.dragStartPointerY);
					layerProperties.moveY = (tmp - (layerCalculations.y - layerProperties.moveY)) / scale;
					layerCalculations.y = tmp;
				} else {
					// moveMethod has been changed while dragging
					layer.dragged = false;
				}
			}
			
			if (time) {
				
				// layer follows the first pointer
				if (layerProperties.moveMethod == "follow") {
					if (pointers[0]) {
						var cumuTime:Number = 0;
						var cumuX:Number = 0;
						var cumuY:Number = 0;
						layer.followPoints.push({time: time, x: pointers[0].x, y: pointers[0].y});
						var a:Array = new Array();
						while (cumuTime < layerProperties.moveFollowTime && layer.followPoints.length > 0) {
							var p:* = layer.followPoints.pop();
							cumuTime = cumuTime + p.time;
							cumuX = cumuX + p.x * p.time;
							cumuY = cumuY + p.y * p.time;
							a.unshift(p);
						}
						layer.followPoints = a;						
						layerProperties.moveX = cumuX / cumuTime - (layerCalculations.x - layerProperties.moveX);
						layerProperties.moveY = cumuY / cumuTime - (layerCalculations.y - layerProperties.moveY);
						
					} else {
						layer.followPoints = new Array();
					}
				} else {
					// physics move the layer unless it is dragged
					if (!layer.dragged) {
						var speed:Number = Math.sqrt(Math.pow(layerProperties.moveDX, 2) + Math.pow(layerProperties.moveDY, 2));
						if (speed) {
							var newSpeed:Number = speed;
							if (speed > layerProperties.moveMaxSpeed) {
								newSpeed = layerProperties.moveMaxSpeed;
							}
							newSpeed = Math.max(0, newSpeed - newSpeed * layerProperties.moveFriction * time);
							var m:Number = newSpeed / speed;
							layerProperties.moveX = layerProperties.moveX + layerProperties.moveDX * m * time;
							layerProperties.moveY = layerProperties.moveY + layerProperties.moveDY * m * time;					
						}
					}
				}
								
				layerProperties.moveDX = (layerProperties.moveX - layer.moveOldX) / time;
				layerProperties.moveDY = (layerProperties.moveY - layer.moveOldY) / time;			
			}
			
			layerCalculations.parallaxLevelX = layerCalculations.parallaxLevelX + layerProperties.moveX;
			layerCalculations.parallaxLevelY = layerCalculations.parallaxLevelY + layerProperties.moveY;
		}
		
		function renderLayer(layer) {
			
			if (!layer.ready) return;
			
			var tmpX:Number, tmpY:Number;
			var layerProperties = layer.properties;
			var layerCalculations = layer.calculations;
			
			var i:*;
			
			if (debugMode) {
				layer.debugSprite.graphics.clear();
				layer.debugSprite.graphics.lineStyle(1, 0x000000, 0.5);
				var tmpScaleX:Number = (layer.originalWidth ? layerCalculations.width / layer.originalWidth : 1);
				var tmpScaleY:Number = (layer.originalHeight ? layerCalculations.height / layer.originalHeight : 1);
				tmpX = (layer.originalReferenceX - layerCalculations.referenceX) * tmpScaleX;
				tmpY = (layer.originalReferenceY - layerCalculations.referenceY) * tmpScaleY;
				layer.debugSprite.graphics.moveTo(tmpX, tmpY);
				layer.debugSprite.graphics.lineTo(tmpX + 5, tmpY + 5);
				layer.debugSprite.graphics.lineTo(tmpX - 5, tmpY + 5);
				layer.debugSprite.graphics.lineTo(tmpX, tmpY);
				tmpX = 0;
				tmpY = 0;
				layer.debugSprite.graphics.lineTo(tmpX, tmpY);
				layer.debugSprite.graphics.lineTo(tmpX + 10, tmpY - 10);
				layer.debugSprite.graphics.lineTo(tmpX - 10, tmpY - 10);
				layer.debugSprite.graphics.lineTo(tmpX, tmpY);
				if (layerProperties.moveX || layerProperties.moveY) {
					tmpX = (-layerProperties.moveX);
					tmpY = (-layerProperties.moveY);
					layer.debugSprite.graphics.moveTo(0, 0);
					layer.debugSprite.graphics.lineTo(tmpX, tmpY);
					layer.debugSprite.graphics.moveTo(tmpX - 5, tmpY - 5);
					layer.debugSprite.graphics.lineTo(tmpX + 5, tmpY + 5);
					layer.debugSprite.graphics.moveTo(tmpX - 5, tmpY + 5);
					layer.debugSprite.graphics.lineTo(tmpX + 5, tmpY - 5);
				}
				/*
				tmpX = 0 - layerCalculations.referenceX;
				tmpY = 0 - layerCalculations.referenceY;				
				layer.debugSprite.graphics.lineTo(tmpX, tmpY);
				*/
				
				layer.debugSprite.graphics.beginFill(0x000000, 0.01);
				layer.debugSprite.graphics.drawRect(0 - layerCalculations.referenceX * tmpScaleX, 0 - layerCalculations.referenceY * tmpScaleY, layerCalculations.width, layerCalculations.height);
				layer.debugSprite.graphics.endFill();
			}
			
			var sprite = layer.zprite;
			if (sprite != null) {

				sprite.setTargetSize(layerCalculations.targetWidth, layerCalculations.targetHeight);

				// smoothing only works on Bitmap objects
				try {
					sprite.content.smoothing = layerProperties.smoothing;
				} catch (e:Error) {
				}

				sprite.visible = layerProperties.visible;

				if (sprite.hat.magicast_render) {
					sprite.setReferencePoint(0, 0);				
					sprite.x = 0;
					sprite.y = 0;
					sprite.scaleX = sprite.scaleY = 1;
					sprite.rotation = 0;
					sprite.alpha = 1;
					sprite.hat.magicast_render();
				} else {	
					sprite.setReferencePoint(layerCalculations.referenceX - layer.originalReferenceX, layerCalculations.referenceY - layer.originalReferenceY);
					sprite.x = layerCalculations.x;
					sprite.y = layerCalculations.y;
					sprite.scaleX = (layer.originalWidth ? layerCalculations.width / layer.originalWidth : 1) * layerCalculations.scaleX;
					sprite.scaleY = (layer.originalHeight ? layerCalculations.height / layer.originalHeight : 1) * layerCalculations.scaleY;
					sprite.rotation = layerCalculations.rotation;
					sprite.alpha = layerCalculations.alpha;
				}
				
				if (layerProperties.mask) {
					var maskLayer:*;
					maskLayer = layers["name_" + layerProperties.mask];
					if (maskLayer) {
						// WHY???
						if (maskLayer.zprite is Loader) {
							if (sprite.mask != maskLayer.zprite.content) {
								sprite.mask = maskLayer.zprite.content;
							}
						} else {
							if (sprite.mask != maskLayer.zprite.content) {
								sprite.mask = maskLayer.zprite.content;
							}
						}
					} else {
						if (sprite.mask != null) {
							sprite.mask = null;
						}
					}
				} else {
					if (sprite.mask != null) {
						sprite.mask = null;
					}
				}
			}

			if (debugMode) {
				layer.debugSprite.x = layerCalculations.x;
				layer.debugSprite.y = layerCalculations.y;
				layer.debugSprite.scaleX = layerCalculations.scaleX;
				layer.debugSprite.scaleY = layerCalculations.scaleY;
				layer.debugSprite.rotation = layerCalculations.rotation;
			}
			
			// trigger visibility events
			if (layerProperties.triggerVisibilityEvents) {
				
				var tmpCos:Number = Math.cos(layerCalculations.rotation / 360 * Math.PI * 2);
				var tmpSin:Number = Math.sin(layerCalculations.rotation / 360 * Math.PI * 2);
				var p1:Point = new Point(
					layerCalculations.x + (-layerCalculations.referenceX * layerCalculations.scaleX * tmpCos - layerCalculations.referenceY * layerCalculations.scaleY * tmpSin), 
					layerCalculations.y + (-layerCalculations.referenceY * layerCalculations.scaleY * tmpCos + layerCalculations.referenceX * layerCalculations.scaleX * tmpSin));
				var p2:Point = new Point(
					layerCalculations.x + ((layerCalculations.width - layerCalculations.referenceX) * layerCalculations.scaleX * tmpCos - layerCalculations.referenceY * layerCalculations.scaleY * tmpSin), 
					layerCalculations.y + (-layerCalculations.referenceY * layerCalculations.scaleY * tmpCos + (layerCalculations.width - layerCalculations.referenceX) * layerCalculations.scaleX * tmpSin));
				var p3:Point = new Point(
					layerCalculations.x + ((layerCalculations.width - layerCalculations.referenceX) * layerCalculations.scaleX * tmpCos - (layerCalculations.height - layerCalculations.referenceY) * layerCalculations.scaleY * tmpSin), 
					layerCalculations.y + ((layerCalculations.height - layerCalculations.referenceY) * layerCalculations.scaleY * tmpCos + (layerCalculations.width - layerCalculations.referenceX) * layerCalculations.scaleX * tmpSin));
				var p4:Point = new Point(
					layerCalculations.x + (-layerCalculations.referenceX * layerCalculations.scaleX * tmpCos - (layerCalculations.height - layerCalculations.referenceY) * layerCalculations.scaleY * tmpSin), 
					layerCalculations.y + ((layerCalculations.height - layerCalculations.referenceY) * layerCalculations.scaleY * tmpCos + layerCalculations.referenceX * layerCalculations.scaleX * tmpSin));
								
				var t1:Boolean = p1.x >= 0 && p1.y >= 0 && p1.x <= Z.targetWidth && p1.y <= Z.targetHeight; 
				var t2:Boolean = p2.x >= 0 && p2.y >= 0 && p2.x <= Z.targetWidth && p2.y <= Z.targetHeight; 
				var t3:Boolean = p3.x >= 0 && p3.y >= 0 && p3.x <= Z.targetWidth && p3.y <= Z.targetHeight; 
				var t4:Boolean = p4.x >= 0 && p4.y >= 0 && p4.x <= Z.targetWidth && p4.y <= Z.targetHeight; 
				
				// simple case 1: all points visible
				if (t1 && t2 && t3 && t4) {
					if (layer.lastVisibilityEvent != "fullVisibility") {
						layer.lastVisibilityEvent = "fullVisibility"; 
						triggerEvent(layer.name, "fullVisibility");
					}
				// simple case 2: at least one point visible
				} else if (t1 || t2 || t3 || t4) {
					if (layer.lastVisibilityEvent != "partialVisibility") {
						layer.lastVisibilityEvent = "partialVisibility"; 
						triggerEvent(layer.name, "partialVisibility");
					}
				// simple case 3: all points over one edge
				} else if (
					(p1.x < 0 && p2.x < 0 && p3.x < 0 && p4.x < 0) ||
					(p1.x > Z.targetWidth && p2.x > Z.targetWidth && p3.x > Z.targetWidth && p4.x > Z.targetWidth) ||
					(p1.y < 0 && p2.y < 0 && p3.y < 0 && p4.y < 0) ||
					(p1.y > Z.targetHeight && p2.y > Z.targetHeight && p3.y > Z.targetHeight && p4.y > Z.targetHeight)
					) {
					if (layer.lastVisibilityEvent != "noVisibility") {
						layer.lastVisibilityEvent = "noVisibility"; 
						triggerEvent(layer.name, "noVisibility");
					}					
				// complex case: use hitTest
				} else {
					visibilityTest1.width = Z.targetWidth;
					visibilityTest1.height = Z.targetHeight;
					visibilityTest2.rotation = layerCalculations.rotation;
					visibilityTest2.x = p1.x;
					visibilityTest2.y = p1.y;
					visibilityTest2.width = layerCalculations.width * layerCalculations.scaleX;
					visibilityTest2.height = layerCalculations.height * layerCalculations.scaleY;
					if (visibilityTest1.hitTestObject(visibilityTest2)) {
						if (layer.lastVisibilityEvent != "partialVisibility") {
							layer.lastVisibilityEvent = "partialVisibility"; 
							triggerEvent(layer.name, "partialVisibility");
						}
					} else {
						if (layer.lastVisibilityEvent != "noVisibility") {
							layer.lastVisibilityEvent = "noVisibility"; 
							triggerEvent(layer.name, "noVisibility");
						}					
					}
				}
			}
		}
		
		function tick(time) {
			
			if (!Z.targetWidth || !Z.targetHeight) return;

			var i, j, k, layer, sprite, layerProperties, layerCalculations;
						
			if (nodeChangeInProgress) {
				var p:Number = 0;
				var c:Number = 0;
				for (i in newLayers) {
					if (newLayers[i].zprite) {
						c = c + 1;
						if (newLayers[i].ready) {
							p = p + 1;
						} else if (newLayers[i].zprite.getBytesTotal()) {
							p = p + newLayers[i].zprite.getBytesLoaded() / newLayers[i].zprite.getBytesTotal();
						}
					}
				}
				Z.hat.trigger("loadProgress", p / c);
			}
							
			var tmp:Number, b1:Boolean, b2:Boolean;
		
			// scale at parallaxLevel 1
			var scale:Number = (1 + (1 - 1) / properties.cameraParallaxLevel) / properties.cameraParallaxLevel;
					
			// OLD SYNTAX
			if (properties.relCameraX != null) {
				properties.cameraMoveX = calculations.width * properties.relCameraX / 100 -
					(properties.cameraAbsX ? properties.cameraAbsX : 0) -
					(properties.cameraRelX ? properties.cameraRelX / 100 * calculations.width : 0);					
			}
			if (properties.relCameraY != null) {
				properties.cameraMoveY = calculations.height * properties.relCameraY / 100 -
					(properties.cameraAbsY ? properties.cameraAbsY : 0) -
					(properties.cameraRelY ? properties.cameraRelY / 100 * calculations.height : 0);					
			}
			
			// if time is zero, tick was called by doResize -> nothing is moving
			if (time) {
				cameraMoveOldX = properties.cameraMoveX;
				cameraMoveOldY = properties.cameraMoveY;
				// camera is being dragged
				if (properties.cameraMoveMethod == "drag" && cameraPointerIndex != -1) {
					properties.cameraMoveX = cameraDragStartX + (cameraDragStartPointerX - pointers[cameraPointerIndex].x) * properties.cameraParallaxLevel;
					properties.cameraMoveY = cameraDragStartY + (cameraDragStartPointerY - pointers[cameraPointerIndex].y) * properties.cameraParallaxLevel;
				// camera follows the first pointer
				} else if (properties.cameraMoveMethod == "follow" && cameraPointerIndex == 0) {
					// TODO
				// camera scrolls when the first pointer is on the edge
				} else if (properties.cameraMoveMethod == "scroll" && cameraPointerIndex == 0) {
					// TODO
				// physics move the camera
				} else {
					var cameraSpeed:Number = Math.sqrt(Math.pow(properties.cameraMoveDX, 2) + Math.pow(properties.cameraMoveDY, 2));
					if (cameraSpeed) {
						var newCameraSpeed:Number = cameraSpeed;
						if (cameraSpeed > properties.cameraMoveMaxSpeed) {
							newCameraSpeed = properties.cameraMoveMaxSpeed;
						}
						newCameraSpeed = Math.max(0, newCameraSpeed - newCameraSpeed * properties.cameraMoveFriction * time);
						var m:Number = newCameraSpeed / cameraSpeed;
						properties.cameraMoveX = properties.cameraMoveX + properties.cameraMoveDX * m * time;
						properties.cameraMoveY = properties.cameraMoveY + properties.cameraMoveDY * m * time;
					}
				}
				properties.cameraMoveDX = (properties.cameraMoveX - cameraMoveOldX) / time;
				properties.cameraMoveDY = (properties.cameraMoveY - cameraMoveOldY) / time;
			}
			
			calculations.cameraX = 
				properties.cameraMoveX + 
				(properties.cameraAbsX ? properties.cameraAbsX : 0) + 
				(properties.cameraRelX ? properties.cameraRelX / 100 * calculations.width : 0);				
			calculations.cameraY = 
				properties.cameraMoveY + 
				(properties.cameraAbsY ? properties.cameraAbsY : 0) + 
				(properties.cameraRelY ? properties.cameraRelY / 100 * calculations.height : 0);
			
			// check camera bounds (and stop motion if necessary)
			if (calculations.width * scale < Z.targetWidth) {
				properties.cameraMoveX = (calculations.width / 2) - (calculations.cameraX - properties.cameraMoveX);
				calculations.cameraX = calculations.width / 2;		
				properties.cameraMoveDX = 0;
			} else {
				if (calculations.cameraX < Z.targetWidth / scale / 2) {
					properties.cameraMoveX = (Z.targetWidth / scale / 2) - (calculations.cameraX - properties.cameraMoveX);
					calculations.cameraX = Z.targetWidth / scale / 2;
					properties.cameraMoveDX = 0;
				}
				if (calculations.cameraX > calculations.width - Z.targetWidth / scale / 2) {
					properties.cameraMoveX = (calculations.width - Z.targetWidth / scale / 2) - (calculations.cameraX - properties.cameraMoveX);
					calculations.cameraX = calculations.width - Z.targetWidth / scale / 2;
					properties.cameraMoveDX = 0;
				}
			}
			if (calculations.height * scale < Z.targetHeight) {
				properties.cameraMoveY = (calculations.height / 2) - (calculations.cameraY - properties.cameraMoveY);
				calculations.cameraY = calculations.height / 2;		
				properties.cameraMoveDY = 0;
			} else {
				if (calculations.cameraY < Z.targetHeight / scale / 2) {
					properties.cameraMoveY = (Z.targetHeight / scale / 2) - (calculations.cameraY - properties.cameraMoveY);
					calculations.cameraY = Z.targetHeight / scale / 2;
					properties.cameraMoveDY = 0;
				}
				if (calculations.cameraY > calculations.height - Z.targetHeight / scale / 2) {
					properties.cameraMoveY = (calculations.height - Z.targetHeight / scale / 2) - (calculations.cameraY - properties.cameraMoveY);
					calculations.cameraY = calculations.height - Z.targetHeight / scale / 2;
					properties.cameraMoveDY = 0;
				}
			}
			
			// OLD SYNTAX
			if (properties.relCameraX != null) {
				properties.relCameraX = calculations.cameraX / calculations.width * 100;
			}
			if (properties.relCameraY != null) {
				properties.relCameraY = calculations.cameraY / calculations.height * 100;
			}			
			
			for (i in layers) {
				layer = layers[i];
				layer.calculated = false;
			}						
			for (i in layers) {
				layer = layers[i];
				tickLayer(layer, time);
			}
			for (i in layers) {
				layer = layers[i];
				renderLayer(layer);
			}
			
			var cl:CollisionList;
			var ca:Array;

			// OLD SYNTAX
			for (i in layers) {
				layer = layers[i];
				if (layer.properties.triggerCollisionEvents) {
					for (j in layers) {
						if (layer.depth < layers[j].depth && layers[j].zprite && layers[j].properties.triggerCollisionEvents) {
							if (layer.zprite is Loader) {
								cl = new CollisionList(layer.zprite.content, layers[j].zprite.content);
							} else {
								cl = new CollisionList(layer.zprite.content, layers[j].zprite.content);
							}
							ca = cl.checkCollisions();
							var collides:Boolean = ca.length > 0;
							if (layer.lastCollisionResult[layers[j].name]) {
								if (!collides) {
									triggerEvent(layer.name, "miss_" + layers[j].name);
									layer.lastCollisionResult[layers[j].name] = false;
								}
							} else {
								if (collides) {
									triggerEvent(layer.name, "hit_" + layers[j].name);
									layer.lastCollisionResult[layers[j].name] = true;
								}								
							}
						}
					}
				}
			}			
						
			// NEW SYNTAX
			for (i in collisionDetectionGroups) {
				
				var collisionDetectionGroup = collisionDetectionGroups[i];
				var source:*, target:*;
				for (j in collisionDetectionGroups[i].sources) {
					source = collisionDetectionGroups[i].sources[j];
					if (source) {
						source.result = false;
					}
				}
				for (j in collisionDetectionGroups[i].targets) {
					target = collisionDetectionGroups[i].targets[j];
						if (target) {
						target.result = false;
						if (target.layer.zprite) {
							for (k in collisionDetectionGroups[i].sources) {
								source = collisionDetectionGroups[i].sources[k];
								if (source.layer != target.layer) {
									var sourceCollides:Boolean = false;
									if (source.layer.zprite) {
										if (target.layer.zprite.content.hitTestObject(source.layer.zprite.content)) {
											if (target.pixelPerfect || source.pixelPerfect) {
												cl = new CollisionList(target.layer.zprite.content, source.layer.zprite.content);
												ca = cl.checkCollisions();
												if (ca.length > 0) {
													target.result = true;
													source.result = true;
												}
											} else {
												target.result = true;
												source.result = true;
											}
										}
									}
								}
							}
						}
						if (target.lastResult) {
							if (!target.result) {
								triggerEvent(target.layer.name, "collisionEnd_" + i);
							}
						} else {
							if (target.result) {
								triggerEvent(target.layer.name, "collisionStart_" + i);
							}								
						}
						target.lastResult = target.result;
					}
				}
				for (j in collisionDetectionGroups[i].sources) {				
					source = collisionDetectionGroups[i].sources[j];
					if (source) {
						if (source.lastResult) {
							if (!source.result) {
								triggerEvent(source.layer.name, "collisionEnd_" + i);
							}
						} else {
							if (source.result) {
								triggerEvent(source.layer.name, "collisionStart_" + i);
							}								
						}
						source.lastResult = source.result;
					}
				}
			}
			
			if (debugMode) {				
				scale = (1 + (1 - 1) / properties.cameraParallaxLevel) / properties.cameraParallaxLevel;
		
				debugGrid.scaleX = debugGrid.scaleY = scale;
				debugGrid.x = Z.targetWidth / 2 - properties.cameraMoveX * scale;
				debugGrid.y = Z.targetHeight / 2 - properties.cameraMoveY * scale;
		
				if (time) {
					debugWindow.buttons.fps.text = Math.round(1 / time);
				}
				
				var debugMouseX = (-debugGrid.x + THIS.mouseX) / scale;
				var debugMouseY = (-debugGrid.y + THIS.mouseY) / scale;
				debugWindow.buttons.mouse.text = 
					(Math.round(debugMouseX * 10) / 10) + "x" + (Math.round(debugMouseY * 10) / 10) + "px = " + 
					(Math.round(debugMouseX / calculations.width * 1000) / 10) + "x" + (Math.round(debugMouseY / calculations.height * 1000) / 10) + "%";
				debugWindow.buttons.camera.text = 
					(Math.round(properties.relCameraX * 10) / 10) + "x" + (Math.round(properties.relCameraY * 10) / 10) + "%" + 
					" & " + 
					(Math.round(properties.cameraMoveX * 10) / 10) + "x" + (Math.round(properties.cameraMoveY * 10) / 10) + "px" + 
					" & " + 
					(Math.round(properties.cameraMoveDX * 10) / 10) + "x" + (Math.round(properties.cameraMoveDY * 10) / 10) + "px/s";
			}
		}
		
		function removeLayerEventListeners(layer) {
			try {
				layer.sprite.removeEventListener(TouchEvent.TOUCH_ROLL_OVER, layer.touchRollOver);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(TouchEvent.TOUCH_ROLL_OUT, layer.touchRollOut);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(TouchEvent.TOUCH_BEGIN, layer.touchBegin);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(TouchEvent.TOUCH_END, layer.touchEnd);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(TouchEvent.TOUCH_TAP, layer.touchTap);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(MouseEvent.ROLL_OVER, layer.rollOver);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(MouseEvent.ROLL_OUT, layer.rollOut);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(MouseEvent.MOUSE_DOWN, layer.mouseDown);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(MouseEvent.MOUSE_UP, layer.mouseUp);
			} catch (e) {
			}
			try {
				layer.sprite.removeEventListener(MouseEvent.CLICK, layer.click);
			} catch (e) {
			}
		}
		
		function updateLayerEventListeners(layer) {	
		
			// if layer is not yet ready, don't do anything
			if (layer.zprite == null) return;

			removeLayerEventListeners(layer);
				
			if (layer.properties.moveMethod == "drag" || layer.properties.triggerPointerEvents) {
				layer.sprite.buttonMode = true;
				layer.sprite.mouseEnabled = true;
				if (Z.mahti.multitouch) {
					layer.sprite.addEventListener(TouchEvent.TOUCH_BEGIN, layer.touchBegin);
					layer.sprite.addEventListener(TouchEvent.TOUCH_END, layer.touchEnd);
					layer.sprite.addEventListener(TouchEvent.TOUCH_TAP, layer.touchTap);
				} else {
					layer.sprite.addEventListener(MouseEvent.MOUSE_DOWN, layer.mouseDown);
					layer.sprite.addEventListener(MouseEvent.MOUSE_UP, layer.mouseUp);
					layer.sprite.addEventListener(MouseEvent.CLICK, layer.click);
				}
				if (layer.properties.triggerPointerEvents) {
					if (Z.mahti.multitouch) {
						layer.sprite.addEventListener(TouchEvent.TOUCH_ROLL_OVER, layer.touchRollOver);
						layer.sprite.addEventListener(TouchEvent.TOUCH_ROLL_OUT, layer.touchRollOut);
					} else {
						layer.sprite.addEventListener(MouseEvent.ROLL_OVER, layer.rollOver);
						layer.sprite.addEventListener(MouseEvent.ROLL_OUT, layer.rollOut);
					}
				}
			} else {
				layer.sprite.buttonMode = false;
				layer.sprite.mouseEnabled = false;
			}

			if (layer.properties.useHandCursor === false) {
				layer.sprite.useHandCursor = false;				
			}
		}
	
		function createLayerSprite(layer) {
		
			if (layer.created) return;
			layer.created = true;
			
			if (debugMode) {
				var debugSprite = new Sprite();
				layer.debugSprite = debugSprite;
			}		
								
			if ("" + layer.asset == "") {
				debug("Creating assetless layer: " + layer.name, "#990000");
				layerReady(layer.name);
			} else {
				debug("Creating layer: " + layer.name, "#000000");
					
				var hat:* = Z.createHat();				
				
				hat.magicast_hat = Z.hat;
				
				hat.magicast_setBounds = function(bounds:Rectangle = null) {
					setLayerBounds(layer, bounds);
				};
								
				hat.magicast_properties = layer.properties;
				hat.magicast_calculations = layer.calculations;

				hat.magicast_resolveAndGetValue = function(parameters:*):* {
					return resolveAndGetValue(layer, parameters);
				};
				
				// OLD SYNTAX
				hat.magicast_setVariable = function(name:String, value:*) {
					return setVariable(name, value);
				};
				
				hat.magicast_triggerEvent = function(name, ... args) {
					triggerEvent(layer.name, name, args);
				};
				
				// NEW SYNTAX
				hat.magicast_resolveAndSetVariable = function(variable:*, value:*) {
					return resolveAndSetVariable(variable, value);
				};

				hat.magicast_resolveAndTriggerEvent = function(parameters, eventArguments:Object = null, eventPoint:Point = null) {
					resolveAndTriggerEvent(layer, parameters, eventArguments, eventPoint);
				};
				
				hat.magicast_debug = function(message) {
					debug("Debug: " + layer.name + " / " + message, "#999999");
				};
	
				layer.sprite = new Sprite();
				layer.zprite = Z.create(XML(layer.asset), {hat: hat});
				layer.sprite.addChild(layer.zprite);
				layer.zprite.mouseEnabled = false; // never trigger pointerEvents at this level
			
				layer.zprite.bind("ready", Z.wrap(function() {
					debug("Layer ready: " + layer.name, "#009900");
					layerReady(layer.name);
				}));
				
				layer.zprite.bind("loadFailure", Z.wrap(function() {
					debug("Layer creation failure, not retrying: " + layer.name, "#990000");
					layerReady(layer.name);
				}));
				
				layer.zprite.bind("loadRetry", Z.wrap(function() {
					debug("Layer creation failure, retrying: " + layer.name, "#990000");
				}));				
			}
		}
		
		function removeLayerSprite(layer) {
			debug("Removing layer sprite: " + layer.name, "#999900");
			if (layer.zprite != null) {
				try {
					layersContainer.removeChild(layer.sprite);
				} catch (e) {
				}
				removeFromCollisionDetection(layer);
				removeLayerEventListeners(layer);
				layer.zprite.destroy();
				delete(layer.zprite);
			}
			if (debugMode) {
				debugLayersContainer.removeChild(layer.debugSprite);
				delete(layer.debugSprite);
			}
		}
		
		var updating:Boolean;
		function changeNode(node:String, update:Boolean = false) {
						
			if (nodeChangeInProgress) return;

			var i:*, j:*;
			var property:*, pName:String, pValue:String;
		
			debug("Change node: " + node + (update?" (update)":""), "#000099");

			updating = update;

			// first, chek if the node exists
			var found = false;
			for (i=0 ; i<xml.node.length() ; i++) {
				if ("" + xml.node[i].name == node) {
					nodeXML = xml.node[i];
					found = true;
				}
			}
			if (!found) return;
			
			Z.hat.trigger("nodeChange", "" + nodeXML.name);
			nodeChangeInProgress = true;
			triggerEvent("", "loadStart");
			if (updating) {
				triggerEvent("", "updateStart");
			}
			Z.hat.trigger("loadStart");	
				
			if (debugMode) {
				debugWindow.buttons.node.text = node;
			}
			
			newTriggers = new Array();
		
			// create new triggers	
			for (i=0 ; i<nodeXML.trigger.length() ; i++) {
		
				var triggerXML = nodeXML.trigger[i];
				var triggerName = triggerXML.name
								
				// create new trigger if supposed to
				if (!triggers["name_" + triggerName] || triggerXML.overwrite=="true") {
					newTriggers["name_" + triggerName] = {};
				} else {
					newTriggers["name_" + triggerName] = triggers["name_" + triggerName];
				}
				
				var trigger = newTriggers["name_" + triggerName];	

				trigger.depth = i;

				if (!trigger.name) {
					trigger.name = triggerName;
					trigger.immediate = "" + triggerXML.immediate == "true";					
					trigger.events = new Array();
					for (j=0 ; j<triggerXML.event.length() ; j++) {
						trigger.events.push({
							layer: "" + triggerXML.event[j].layer, 
							name: "" + triggerXML.event[j].name
						});
					}
					trigger.condition = triggerXML.condition; // TODO: parse
					trigger.action = triggerXML.action; // TODO: parse
				}
			}

			newLayers = new Array();

			// initialize new layers
			for (i=0 ; i<nodeXML.layer.length() ; i++) {
				function kikka() {
					var layerXML = nodeXML.layer[i];
					var layerName = "" + layerXML.name;
			
					// create new layer if supposed to
					if (!layers["name_" + layerName] || layerXML.overwrite == "true") {
						newLayers["name_" + layerName] = {};
					} else {
						newLayers["name_" + layerName] = layers["name_" + layerName];
					}
					
					var layer = newLayers["name_" + layerName];
					
					// create room for the layer
					layer.depth = i;

					if (debugMode) {
						debugLayersContainer.addChild(new Sprite());
					}
			
					// if layer exist from previous node
					if (layer.name != null) {
						
					// new layer
					} else {
									
						layer.name = layerName;
						layer.asset = layerXML.asset;
						layer.running = false;
						layer.added = false;
						layer.ready = false;
						
						layer.dragged = false;
						
						// layer properties
						layer.properties = {};
						layer.calculations = {};
						
						layer.lastVisibilityEvent = "";

						// OLD SYNTAX
						layer.lastCollisionResult = new Array();
						
						// NEW SYNTAX
						if (layerXML.collisionDetectionGroup) {
							for (j=0 ; j<layerXML.collisionDetectionGroup.length() ; j++) {
								applyCollisionDetectionGroup(layer, layerXML.collisionDetectionGroup[j]);
							}
						}
							
						// motionXML
						layer.animators = {};
						layer.animatorSprites = {};
						
						if (layerXML.property) {
							for (j=0 ; j<layerXML.property.length() ; j++) {
								property = layerXML.property[j];
								pName = "" + property.name;
								pValue = "" + property.value;
								if (isNumber(pValue)) {
									layer.properties[pName] = parseFloat(pValue);
								} else {
									layer.properties[pName] = pValue;
								}
							}
						}
			
						// required properties
						if (layer.properties.parallaxLevel == null) layer.properties.parallaxLevel = 0;
						if (layer.properties.rotation == null) layer.properties.rotation = 0;
						if (layer.properties.skewX == null) layer.properties.skewX = 0;
						if (layer.properties.skewY == null) layer.properties.skewY = 0;
						if (layer.properties.scaleX == null) layer.properties.scaleX = 100;
						if (layer.properties.scaleY == null) layer.properties.scaleY = 100;
						if (layer.properties.alpha == null) layer.properties.alpha = 100;
						
						// boolean properties
						layer.properties.visible = "" + layer.properties.visible != "false";
						layer.properties.smoothing = "" + layer.properties.smoothing != "false";
						layer.properties.cacheAsBitmap = "" + layer.properties.cacheAsBitmap == "true";
						layer.properties.useHandCursor = "" + layer.properties.useHandCursor == "true";
						layer.properties.triggerPointerEvents = 
							"" + layer.properties.triggerPointerEvents == "true" || // NEW SYNTAX
							"" + layer.properties.triggerMouseEvents == "true"; // OLD SYNTAX
						layer.properties.triggerVisibilityEvents = "" + layer.properties.triggerVisibilityEvents == "true";
						layer.properties.triggerCollisionEvents = "" + layer.properties.triggerCollisionEvents == "true";
						layer.properties.parallaxScale = "" + layer.properties.parallaxScale != "false";
						layer.properties.parallaxRotate = "" + layer.properties.parallaxRotate != "false";
						layer.properties.refFrameAnchorX = "" + layer.properties.refFrameAnchorX != "false";
						layer.properties.refFrameAnchorY = "" + layer.properties.refFrameAnchorY != "false";
						layer.properties.refFrameAnchorScaleX = "" + layer.properties.refFrameAnchorScaleX != "false";
						layer.properties.refFrameAnchorScaleY = "" + layer.properties.refFrameAnchorScaleY != "false";
						layer.properties.refFrameAnchorParallaxLevel = "" + layer.properties.refFrameAnchorParallaxLevel != "false";
						layer.properties.refFrameAnchorRotation = "" + layer.properties.refFrameAnchorRotation != "false";
						layer.properties.refFrameAnchorAlpha = "" + layer.properties.refFrameAnchorAlpha != "false";

						// move properties
						if (layer.properties.moveMaxSpeed == null) layer.properties.moveMaxSpeed = 0;
						if (layer.properties.moveFriction == null) layer.properties.moveFriction = 2;
						if (layer.properties.moveClickSpeed == null) layer.properties.moveClickSpeed = 0;			
						if (layer.properties.moveClickTime == null) layer.properties.moveClickTime = 1;			
						if (layer.properties.moveClickEase == null) layer.properties.moveClickEase = "linear";
						if (layer.properties.moveFollowTime == null) layer.properties.moveFollowTime = 1;

						// OLD SYNTAX
						if (layer.properties.draggable) layer.properties.moveMethod = "drag";
						if (layer.properties.dragX) layer.properties.moveX = layer.properties.dragX;
						if (layer.properties.dragY) layer.properties.moveY = layer.properties.dragY;

						// move position must be a number
						layer.properties.moveX = layer.properties.moveX ? layer.properties.moveX : 0;
						layer.properties.moveY = layer.properties.moveY ? layer.properties.moveX : 0;
						
						layer.autoCreate = "" + layerXML.autoCreate != "false";
						
						layer.pointerIndex = -1;
						layer.followPoints = new Array();
						
						layer.pointerEnter = function(index:int, p:Point) {
							//trace("pointerEnter " + layer.name + " " + p);
							
							if (layer.properties.triggerPointerEvents) {
								triggerEvent(layer.name, "pointerEnter");
							}	
						};
						layer.pointerLeave = function(index:int, p:Point) {
							//trace("pointerLeave " + layer.name + " " + p);
							
							if (layer.properties.triggerPointerEvents) {
								triggerEvent(layer.name, "pointerLeave");
							}	
						};
						layer.pointerDown = function(index:int, p:Point) {
							//trace("pointerDown " + index + " " + layer.name + " " + p + " " + layer.properties.moveMethod);
							
							layer.pointerIndex = index;
							pointerLayers[index] = layer;
																											
							if (layer.properties.triggerPointerEvents) {
								triggerEvent(layer.name, "pointerDown");
							}
							
							if (layer.properties.moveMethod == "drag") {
								// not yet dragged
								layer.dragged = false;
								layer.dragStartX = layer.calculations.x;
								layer.dragStartY = layer.calculations.y;
								layer.dragStartPointerX = p.x;
								layer.dragStartPointerY = p.y;
								triggerEvent(layer.name, "dragStart");
							}
						};
						layer.pointerUp = function(index:int, p:Point) {
							//trace("pointerUp " + layer.name + " " + p + " " + layer.properties.moveMethod);
							
							if (layer.properties.triggerPointerEvents) {
								triggerEvent(layer.name, "pointerUp");
							}
						};
						layer.pointerClick = function(index:int, p:Point) {
							//trace("pointerClick " + layer.name + " " + p + " " + layer.properties.moveMethod);
							
							if (layer.properties.triggerPointerEvents) {
								triggerEvent(layer.name, "click");
							}
						};
						layer.touchRollOver = function(e:TouchEvent) {
							layer.pointerEnter(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.touchRollOut = function(e:TouchEvent) {
							layer.pointerLeave(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.touchBegin = function(e:TouchEvent) {
							layer.pointerDown(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.touchEnd = function(e:TouchEvent) {
							layer.pointerUp(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.touchTap = function(e:TouchEvent) {
							layer.pointerClick(e.touchPointID, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.rollOver = function(e:MouseEvent) {
							layer.pointerEnter(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.rollOut = function(e:MouseEvent) {
							layer.pointerLeave(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.mouseDown = function(e:MouseEvent) {
							layer.pointerDown(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.mouseUp = function(e:MouseEvent) {
							layer.pointerUp(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
						layer.click = function(e:MouseEvent) {
							layer.pointerClick(0, THIS.globalToLocal(new Point(e.stageX, e.stageY)));
						};
					}
				}
				kikka();
			}

			// create new layers
			for (i in newLayers) {
				if (!newLayers[i].ready && newLayers[i].autoCreate) {
					createLayerSprite(newLayers[i]);
				} else {
					newLayers[i].ready = true;
				}
			}
			
			// check if node change is already complete
			if (nodeChangeInProgress) {
				var ready:Boolean = true;
				for (i in newLayers) {
					if (!newLayers[i].ready) {
						ready = false;
					}
				}
				if (ready) {
					nodeChangeComplete();
				}
			}
		}
		
		// get property or calculation
		function resolveAndGetProperty(layer:*, parameters:*) {		
			var p:*;
			var c:*;
			if (parameters.layer) {
				if (layers["name_" + parameters.layer]) {
					p = layers["name_" + parameters.layer].properties;
					c = layers["name_" + parameters.layer].calculations;
				} else {
					return;
				}
			} else {
				if (layer && "" + parameters.level != "magicast") {
					p = layer.properties;
					c = layer.calculations;
				} else {
					p = properties;
					c = calculations;
				}
			}
			return p[parameters.name] || c[parameters.name];
		}
		
		function resolveAndGetValue(layer:*, parameters:*, eventArguments:Object = undefined, eventPoint:Point = undefined) {
			switch ("" + parameters.type) {
				case "constant":
					if (parameters.value[0]) return "" + parameters.value[0];
					return null;
				break;
				case "eventArgument":
					return eventArguments["" + parameters.value];
				break;
				case "variable":
					return variables["" + parameters.value.name];
				break;
				case "property":
					return resolveAndGetProperty(layer, parameters.value);
				break;
				case "calculation":
					var func:String = "" + parameters.value["function"];
					var v1:* = resolveAndGetValue(layer, parameters.value.value[0], eventArguments, eventPoint);
					var v2:* = resolveAndGetValue(layer, parameters.value.value[1], eventArguments, eventPoint);
					var value:*;
					switch (func) {
						case "add" :
							value = parseFloat(v1) + parseFloat(v2);
							break;
						case "dec" :
							value = parseFloat(v1) - parseFloat(v2);
							break;
						case "mul" :
							value = parseFloat(v1) * parseFloat(v2);
							break;
						case "div" :
							value = parseFloat(v1) / parseFloat(v2);
							break;
						case "concat" :
							value = "" + v1 + v2;
							break;
					}
					return value;
				break;
				case "random":					
					var totalWeight:Number = 0;
					for (var i:int=0 ; i<parameters.value.option.length() ; i++) {
						totalWeight = totalWeight + parseFloat("" + parameters.value.option[i].weight);
					}
					var randomWeight:Number = Math.random() * totalWeight;
					var weight:Number = 0;
					var index:int = -1;
					while (weight < randomWeight) {
						index = index + 1;
						weight = weight + parseFloat(parameters.value.option[index].weight);
					}
					if (index>-1) {
						return resolveAndGetValue(layer, parameters.value.option[index].value[0], eventArguments, eventPoint); 
					}
				break;
			}
			
			// no type = constant
			return "" + parameters;
		}
		
		function checkConditions(condition:XMLList, eventArguments:Object = undefined, eventPoint:Point = undefined) {
			
			for (var i=0 ; i<condition.length() ; i++) {
				
				var v1:*, v2:*;
				
				// OLD SYNTAX
				if ("" + condition[i].variable != "") {
					v1 = getVariable("" + condition[i].variable);
					v2 = "" + condition[i].argument;
				// NEW SYNTAX
				} else {
					if ("" + condition[i].value[0] != "") {
						v1 = resolveAndGetValue(null, condition[i].value[0], eventArguments, eventPoint);
					}
					if ("" + condition[i].value[1] != "") {
						v2 = resolveAndGetValue(null, condition[i].value[1], eventArguments, eventPoint);
					}
				}

				if (isNumber(v1)) {
					v1 = parseFloat(v1);
				}
				if (isNumber(v2)) {
					v2 = parseFloat(v2);
				}
				
				var r:Boolean = true;
				var o:String = "" + condition[i].operator;
				switch (o) {
					case "eq" :
						o = "==";
						if (v1 != v2) {
							r = false;
						}
						break;
					case "ne" :
						o = "!=";
						if (v1 == v2) {
							r = false;
						}
						break;
					case "lt" :
						o = "&lt;";
						if (v1 >= v2) {
							r = false;
						}
						break;
					case "gt" :
						o = "&gt;";
						if (v1 <= v2) {
							r = false;
						}
						break;
					case "isNull" :
						o = "IS NULL";
						if (v1 != null) {
							r = false;
						}
						break;
					case "isNotNull" :
						o = "IS NOT NULL";
						if (v1 == null) {
							r = false;
						}
						break;
				}
				if (!r) {
					return false;
				}
			}
			return true;
		}
		
		function runActions(action:XMLList, eventArguments:Object = undefined, eventPoint:Point = undefined) {
			for (var i=0 ; i<action.length() ; i++) {
				function kikka() {
					var timer:Timer;
					var wait:Number = parseFloat(action[i].wait);
					var layer:String = "" + action[i].layer;
					var method:String = "" + action[i].method;										  
					var p = null;
					if ("" + action[i].parameters) {
						p = XML(action[i].parameters);
					}
					function run(catching:Boolean = true) {
						if (catching) {
							try {
								runAction(layer, method, p, eventArguments, eventPoint);
							} catch (e:Error) {
								debug("Node change detected at delayed action!", "#000099");
							}
						} else {
							runAction(layer, method, p, eventArguments, eventPoint);
						}
						timer = null;
					}
					if (!isNaN(wait) && wait > 0) {
						timer = new Timer(wait * 1000, 1);
						timer.start();
						Z.wrapEventListener(timer, TimerEvent.TIMER_COMPLETE, run);
					} else {
						run(false);
					}
				}
				kikka();
			}
		}
		function changeProperty(property:*, value:*, time:Number, ease:String, wait:Number, completeEvent:*) {
			
			var p:*;
			var layer:*;
			
			if ("" + property.layer != "") {
				if (layers["name_" + property.layer]) {
					layer = layers["name_" + property.layer];
					p = layer.properties;
				} else {
					return;
				}
			} else {
				p = properties;
			}
			
			// OLD SYNTAX
			if (property.name=="triggerMouseEvents") {
				property.name = "triggerPointerEvents";
			} else if (property.name=="draggable") {
				property.name = "moveMethod";
				value = (value == "true" ? "drag" : "");
			} else if (property.name=="dragX") {
				property.name = "moveX";
			} else if (property.name=="dragY") {
				property.name = "moveY";
			} else if (property.name=="cameraMovementMethod") {
				property.name = "cameraMoveMethod";
			}

			if (!isNumber(value) || !time) {
				Z.tweener.stop(p, property.name);
				
				// DEFAULT: false
				if (
					property.name=="smoothing" ||
					property.name=="cacheAsBitmap" ||
					property.name=="useHandCursor" ||
					property.name=="triggerPointerEvents" ||
					property.name=="triggerVisibilityEvents" ||
					property.name=="triggerCollisionEvents") {
					p[property.name] = "" + value == "true";
					
				// DEFAULT: true
				} else if (
					property.name=="visible" ||
					property.name=="parallaxScale" ||
					property.name=="parallaxRotate" ||
					property.name=="refFrameAnchorX" ||
					property.name=="refFrameAnchorY" ||
					property.name=="refFrameAnchorScaleX" ||
					property.name=="refFrameAnchorScaleY" ||
					property.name=="refFrameAnchorParallaxLevel" ||
					property.name=="refFrameAnchorAlpha" ||
					property.name=="refFrameAnchorAlpha") {
					p[property.name] = "" + value != "false";
				} else {
					if (isNumber(value)) {
						p[property.name] = parseFloat(value);
					} else {
						p[property.name] = value;											
					}
				}
				if (layer && (property.name=="moveMethod" || property.name=="triggerPointerEvents")) {
					updateLayerEventListeners(layer);
				}
				if (completeEvent) {
					triggerEvent(completeEvent.layer, completeEvent.name, completeEvent.arguments, completeEvent.point);
				}
			} else {
				if (!p[property.name]) {
					p[property.name] = 0;	
				}
				Z.tweener.stop(p, property.name);
				Z.tweener.start(p, property.name, parseFloat(value), time, ease ? ease : undefined, wait ? wait : undefined, function() {
					if (completeEvent) {
						triggerEvent(completeEvent.layer, completeEvent.name, completeEvent.arguments, completeEvent.point);
					}
				});
			}
		}
		
		function runAction(layerName:String, method:String, parameters:XML, eventArguments:Object = undefined, eventPoint:Point = undefined) {
			debug("Running action: " + layerName + " / " + method, "#000099");
			
			var f:Function;
			var name:String, value:*;
			var variable:String;
			
			// for random options
			var totalWeight:Number, weight:Number, randomWeight:Number;
			var i:int;
			
			var rect:Rectangle;
			var bmd:BitmapData;
			var m:Matrix;
			
			// for tweening and animators
			var layer;
			var animator;
			
			if (layerName != "") {
				if (layers["name_" + layerName]) {
					layer = layers["name_" + layerName];
				} else {
					return;
				}
				var sprite = layer.zprite;
				if (sprite) {
					var newPoint:Point = undefined;
					if (eventPoint) {
						newPoint = eventPoint; // TODO
					}
					if (sprite.hat.magicast_runAction is Function) {
						f = sprite.hat.magicast_runAction;
						try {
							f.call(null, method, parameters, eventArguments, newPoint);
						} catch (e) {
							try {
								f.call(null, method, parameters, eventArguments);
							} catch (e) {
								try {
									f.call(null, method, parameters);
								} catch (e) {
									try {
										f.call(null, method);
									} catch (e) {
									}
								}
							}
						}
					}
				}
			} else {
				switch (method) {
					case "print":
						break;
					case "createAnimator":
						layer = layers["name_" + parameters.layer];
						var moSprite:Sprite = layer.animatorSprites["" + parameters.type] = new Sprite();
						var moData:XML = XML(parameters.data.children()[0]);
						var startFrame:int = 0 + parameters.startFrame;
						layer.animators["" + parameters.type] = new Animator(moData, moSprite);
						debug("Animator Created for layer: " + parameters.layer,"#009900");
						if ("" + parameters.loop == "true") {
							layer.animators["" + parameters.type].autoRewind = true;
							layer.animators["" + parameters.type].repeatCount = 0;
						}
						if ("" + parameters.paused != "true") {
							layer.animators["" + parameters.type].play(startFrame);
						}
						break;
					case "destroyAnimator":
						layer = layers["name_" + parameters.layer];
						layer.animators["" + parameters.type] = null;
						layer.animatorSprites["" + parameters.type] = null;
						break;
					case "controlAnimator":
						layer = layers["name_" + parameters.layer];
						animator = layer.animators["" + parameters.type];
						switch ("" + parameters.command) {
							case "play":
								animator.play(); 
								break;
							case "stop":
								animator.stop(); 
								break;
							case "pause":
								animator.pause(); 
								break;
							case "resume":
								animator.resume(); 
								break;
						}
						break;
					case "openBrowser":
						navigateToURL(new URLRequest("" + parameters.URL), "" + parameters.target != "" ? "" + parameters.target : "_blank");
						break;
					case "triggerEvent":
						// OLD SYNTAX
						if ("" + parameters.option != "") {
							totalWeight = 0;
							for (i = 0 ; i<parameters.option.length() ; i++) {
								weight = "" + parameters.option[i].weight != "" ? parseFloat("" + parameters.option[i].weight) : 0;
								totalWeight = totalWeight + weight;
							}
							randomWeight = Math.random() * totalWeight;
							for (i = 0 ; i<parameters.option.length() ; i++) {
								weight = "" + parameters.option[i].weight != "" ? parseFloat("" + parameters.option[i].weight) : 0;
								randomWeight = randomWeight - weight;
								if (randomWeight<=0) {
									triggerEvent("" + parameters.option[i].layer, "" + parameters.option[i].name);
									break;
								}
							}
						// NEW SYNTAX
						} else {
							resolveAndTriggerEvent(null, parameters, null, null);
						}
						break;
					case "changeProperty":
						var property:*;
						// OLD SYNTAX
						if ("" + parameters.property.name == "") {
							property = {layer: parameters.layer, name: parameters.property};
						// NEW SYNTAX
						} else {
							property = {layer: parameters.property.layer, name: parameters.property.name};
						}
						var completeEvent:*;
						// OLD SYNTAX
						if ("" + parameters.completeEventName != "") {
							completeEvent = {layer: "", name: parameters.completeEventName};
						}
						// NEW SYNTAX
						if ("" + parameters.completeEvent != "") {
							completeEvent = resolveEvent(null, parameters.completeEvent, eventArguments);
						}
						changeProperty(property, resolveAndGetValue(null, parameters.value[0], eventArguments), parameters.time, parameters.ease, parameters.wait, completeEvent);
						break;
					case "createLayer":
						createLayerSprite("" + layers["name_" + parameters.layer]);
						break;	
					case "removeLayer":
						layer = layers["name_" + parameters.layer];
						removeLayerSprite(layer);
						break;	
					case "captureImage":
						layer = layers["name_" + parameters.layer];
						if (layer) {
							bmd = new BitmapData(layer.calculations.width, layer.calculations.height, true, 0x00000000);
							m = new Matrix();
							m.translate(-layer.calculations.x, -layer.calculations.y);
							m.rotate(-layer.calculations.rotation / 180 * Math.PI);
							m.translate(layer.calculations.referenceX * layer.calculations.scaleX, layer.calculations.referenceY * layer.calculations.scaleY);
							m.scale(1 / layer.calculations.scaleX, 1 / layer.calculations.scaleY);
							if (parameters.drawLayer[0]) {
								for (i = 0 ; i<parameters.drawLayer.length() ; i++) {
									layer = layers["name_" + parameters.drawLayer[i]];
									if (layer && layer.sprite) {
										bmd.draw(layer.sprite, m);
									}
								}
							} else {
								bmd.draw(THIS, m);
							}
							// OLD SYNTAX
							if ("" + parameters.variable.name == "") {
								setVariable(parameters.variable, bmd);
							// NEW SYNTAX
							} else {
								resolveAndSetVariable(parameters.variable, bmd);
							}
						}
						break;
					case "changeNode":
						// OLD SYNTAX
						if ("" + parameters.option != "") {
							totalWeight = 0;
							for (i = 0 ; i<parameters.option.length() ; i++) {
								weight = Number(parameters.option[i].weight);
								totalWeight = totalWeight + weight;
							}
							randomWeight = Math.random() * totalWeight;
							for (i = 0 ; i<parameters.option.length() ; i++) {
								weight = 0 + parameters.option[i].weight;
								randomWeight = randomWeight - weight;
								if (randomWeight<=0) {
									changeNode(parameters.option[i].node);
									throw new Error();
								}
							}
						// NEW SYNTAX 
						} else {
							changeNode(resolveAndGetValue(null, parameters.value[0], eventArguments, eventPoint));
						}
						break;
					case "setVariable" :
						// OLD SYNTAX
						if ("" + parameters.name != "") {
							name = "" + parameters.name;
							value = "" + parameters.value;
							setVariable(name, value);							
						// NEW SYNTAX
						} else {
							resolveAndSetVariable(parameters.variable, resolveAndGetValue(null, parameters.value[0], eventArguments));
						}
						break;
					// OLD SYNTAX
					case "calculateVariable" :
						name = "" + parameters.name;
						value = getVariable(name);
						var func:String = "" + parameters["function"];
						var argument:String = "" + parameters.argument
						switch (func) {
							case "add" :
								value = parseFloat(value) + parseFloat(argument);
								break;
							case "dec" :
								value = parseFloat(value) - parseFloat(argument);
								break;
							case "mul" :
								value = parseFloat(value) * parseFloat(argument);
								break;
							case "div" :
								value = parseFloat(value) / parseFloat(argument);
								break;
							case "concat" :
								value = "" + value + argument;
								break;
						}
						setVariable(name, value);
						break;
					case "applyCollisionDetectionGroup" :
						layer = layers["name_" + parameters.layer];
						applyCollisionDetectionGroup(layer, parameters.collisionDetectionGroup[0]);
						break;
					default:
						debug("Z.magicastInterface." + method, "#000099");
						f = Z.magicastInterface["" + method];
						var p:*;
						if (f!=null) {
							try {
								p = XML(parameters);
							} catch (e) {
								p = null;
							}
							try {
								f.call(null, Z.hat, p, eventArguments, newPoint);
							} catch (e) {
								try {
									f.call(null, Z.hat, p, eventArguments);
								} catch (e) {
									try {
										f.call(null, Z.hat, p);
									} catch (e) {
										try {
											f.call(null, Z.hat);
										} catch (e) {
											try {
												f.call(null);
											} catch (e) {
											}
										}
									}
								}
							}
						}
						break;
				}
			}
		}
		
		function setLayerBounds(layer, bounds:Rectangle = null) {
			
			if (bounds == null && layer.zprite == null) return;

			layer.originalReferenceX = 0;
			layer.originalReferenceY = 0;
			layer.originalWidth = 0;
			layer.originalHeight = 0;

			if (bounds) {
				layer.originalBounds = bounds;
			} else {
				layer.originalBounds = layer.zprite.getBounds(null);
			}

			layer.originalReferenceX = -layer.originalBounds.x;
			layer.originalReferenceY = -layer.originalBounds.y;
			layer.originalWidth = layer.originalBounds.width;
			layer.originalHeight = layer.originalBounds.height;
			
			layer.originalAspectRatio = layer.originalHeight ? layer.originalWidth / layer.originalHeight : 0;
		}
		
		function layerReady(layerName) {
				
			var layer = newLayers["name_" + layerName];
			layer.ready = true;
			
			updateLayerEventListeners(layer);

			if (!layer.originalBounds) {
				setLayerBounds(layer);
			}
			
			var ready = true;
			for (var i:* in newLayers) {
				if (!newLayers[i].ready) {
					ready = false;
				}
			}
			
			if (ready) {
				
				// if this is the time to start all layers
				if (nodeChangeInProgress) {
					nodeChangeComplete();
					
				// if the rest of the layers have already started, run only one layer
				} else {
					if (layer.zprite != null) {
//						layersContainer.removeChildAt(layer.depth);
//						layersContainer.addChildAt(layer.sprite, layer.depth);
						
						layersContainer.addChild(layer.sprite);
						layer.added = true;
						setChildIndexes();
						
						if (layer.zprite.hat.magicast_run) {
							layer.zprite.hat.magicast_run();
						}
					}
					if (debugMode) {
						debugLayersContainer.removeChildAt(layer.depth);
						debugLayersContainer.addChildAt(layer.debugSprite, layer.depth);
					}
					layer.running = true;
					doResize();
				}
			}			
		}
		
		function setChildIndexes() {
			var i:*;
			var max:int = -1;
			var a:Array = new Array();
			for (i in layers) {
				if (layers[i].added) {
					a[layers[i].depth] = layers[i];
				}
				if (layers[i].depth > max) {
					max = layers[i].depth;
				}
			}
			var b:Array = new Array();
			for (i=0 ; i<max+1 ; i++) {
				if (a[i]) {
					b.push(a[i]);
				}
			}
			for (i=0 ; i<b.length ; i++) {
				layersContainer.setChildIndex(b[i].sprite, i);
			}
		}
		
		function nodeChangeComplete() {

			debug("Node change complete!", "#000099");
			
			nodeChangeInProgress = false;
			
			triggerEvent("", "loadComplete");
			if (updating) {
				triggerEvent("", "updateComplete");
			}
			Z.hat.trigger("loadComplete");
			
			var i:*;
			var property:*, pName:String, pValue:String;
			
			// set node properties if node has changed
			if ("" + nodeXML.name != nodeName) {
				if (nodeXML.property) {
					for (i=0 ; i<nodeXML.property.length() ; i++) {
						property = nodeXML.property[i];
						pName = "" + property.name;
						pValue = "" + property.value;
						if (isNumber(pValue)) {
							properties[pName] = parseFloat(pValue);
						} else {
							properties[pName] = pValue;
						}
					}
				}
				
				if (!properties.cameraParallaxLevel) properties.cameraParallaxLevel = 1;

				if (!properties.cameraMoveMaxSpeed) properties.cameraMoveMaxSpeed = 2000;
				if (!properties.cameraMoveFriction) properties.cameraMoveFriction = 2;

				if (!properties.cameraMoveDragRadius) properties.cameraMoveDragRadius = 10;
				
				if (!properties.cameraMoveClickSpeed) properties.cameraMoveClickSpeed = 1;			
				if (!properties.cameraMoveClickTime) properties.cameraMoveClickTime = 1;			
				if (!properties.cameraMoveClickEase) properties.cameraMoveClickEase = "linear";
				
				// OLD SYNTAX
				if (properties.cameraMovementMethod) properties.cameraMoveMethod = properties.cameraMovementMethod;
			}
			nodeName = "" + nodeXML.name;			

			// remove old layers
			for (i in layers) {
				if (layers[i] != newLayers[i] && layers[i].zprite) {
					Z.tweener.stop(layers[i].properties);
					try {
						removeLayerSprite(layers[i]);
					} catch (e) {
					}
				}
			}

			// make new layers proper layers
			layers = new Array();
			for (i in newLayers) {
				layers[i] = newLayers[i];
			}
			newLayers = null;

			// add new layers
			for (i in layers) {
				if (layers[i].zprite != null) {
					if (!layers[i].added) {
						layersContainer.addChild(layers[i].sprite);
						layers[i].added = true;
					}
				}
				
				if (debugMode) {
					debugLayersContainer.removeChildAt(layers[i].depth);
					debugLayersContainer.addChildAt(layers[i].debugSprite, layers[i].depth);						
				}
			}

			setChildIndexes();
			
			// make new triggers proper triggers
			orderedTriggers = new Array();
			triggers = new Array();
			for (i in newTriggers) {
				triggers[i] = newTriggers[i];
				orderedTriggers[triggers[i].depth] = i;
			}
			newTriggers = null;
			
			/*
			for (i in orderedTriggers) {
				trace(i + " = " + triggers[orderedTriggers[i]].name);
			}
			*/
			
			// run new layers
			for (i in layers) {				
				if (!layers[i].running) {
					if (layers[i].zprite != null) {
						if (layers[i].zprite.hat.magicast_run) {
							layers[i].zprite.hat.magicast_run();
						}
					}
					layers[i].running = true;
				}
			}

			doResize();

			// run immediate triggers
			try {
				for (i in orderedTriggers) {
					var trigger:* = triggers[orderedTriggers[i]];
					if (trigger.immediate) {
						trigger.immediate = false; // trigger not immediate any more
						if (checkConditions(trigger.condition)) {
							runActions(trigger.action);
						}
					}
				}
			} catch (e:Error) {
//				trace(e.getStackTrace());
				debug("Node change detected at immediate trigger!", "#000099");
			}			
		}
		
		function resolveEvent(layer:*, parameters:*, eventArguments:Object = undefined, eventPoint:Point = undefined) {
			var layerName:String = "";
			if (layer) {
				layerName = layer.name;
			}
			if (parameters.layer) {
				layerName = parameters.layer;
			}
			if ("" + parameters.level == "magicast") {
				layerName = "";
			}
			var eventName:String = parameters.name;
			var arguments:Object = new Object();
			for (var i:int=0 ; i<parameters.argument.length() ; i++) {
				arguments[parameters.argument[i].name] = resolveAndGetValue(layer, parameters.argument[i].value[0], eventArguments, eventPoint);
			}
			//
			return {layer: layerName, name: eventName, arguments: arguments, point: eventPoint};
		}
		
		function resolveAndTriggerEvent(layer, parameters, eventArguments:Object = undefined, eventPoint:Point = undefined) {
			var event:* = resolveEvent(layer, parameters, eventArguments, eventPoint);
			triggerEvent(event.layer, event.name, event.arguments, event.point);
		}
		
		function triggerEvent(layerName:String, eventName:String, arguments:Object = undefined, point:Point = undefined) {
			
			var i:*, j:int;
			
			if (point) {
				debug("Event triggered: " + layerName + " / " + eventName + " @ " + point.x + ", " + point.y, "#999900");
			} else {
				debug("Event triggered: " + layerName + " / " + eventName, "#999900");
			}
			
			if (point) {
				var sprite = layers["name_" + layerName].zprite;
				point.x = (point.x * sprite.scaleX / 100) + sprite.x - (sprite.referenceX ? sprite.referenceX : 0);
				point.y = (point.y * sprite.scaleY / 100) + sprite.y - (sprite.referenceY ? sprite.referenceY : 0);
			}
			
			// check triggers
			try {
				for (i in orderedTriggers) {
					var trigger:* = triggers[orderedTriggers[i]];
					var triggered:Boolean = false;
					for (j=0 ; j<trigger.events.length ; j++) {
						if (trigger.events[j].layer==layerName && trigger.events[j].name==eventName) {
							triggered = true;
						}
					}
					if (triggered) {
						if (checkConditions(trigger.condition, arguments, point)) {
							runActions(trigger.action, arguments, point);
						}
					}
				}
			} catch (e:Error) {
				debug("Node change detected at event trigger!", "#000099");
			}
		}
	}
}
