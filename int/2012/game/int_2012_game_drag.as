package 
{

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.*;

	import flash.ui.Multitouch;
	import flash.events.TouchEvent;
	import flash.events.Event;
	import flash.geom.Point;

	public class int_2012_game_drag extends MovieClip
	{

		public function int_2012_game_drag(Z:*)
		{

			var THIS:* = this;
			Z.hat.magicast_run = function() {
				THIS.graphics.beginFill(0x000000, 0);
				THIS.graphics.drawRect(-10000, -10000, 20000, 20000);
				THIS.graphics.endFill();
			};

			var containers:Array = new Array();
			var targetCount:Number = 0;
			var targetFound:Number = 0;
			
			var successSoundLength:Number = Z.parameters.successSoundAsset.length();
			var failureSoundLength:Number = Z.parameters.failureSoundAsset.length();
			
			// legacy trick
			var notDraggableStyle:XML = "" + Z.parameters.notDraggableStyle != "" ? Z.parameters.notDraggableStyle[0] : null;
			var clickableStyle:XML = "" + Z.parameters.clickableStyle != "" ? Z.parameters.clickableStyle[0] : notDraggableStyle;
			var clickedStyle:XML = "" + Z.parameters.clickedStyle != "" ? Z.parameters.clickedStyle[0] : notDraggableStyle;
			
			var draggableStyle:XML = "" + Z.parameters.draggableStyle != "" ? Z.parameters.draggableStyle[0] : null;
			var draggedStyle:XML = "" + Z.parameters.draggedStyle != "" ?  Z.parameters.draggedStyle[0] : null;
			
			var completeStyle:XML = "" + Z.parameters.completeStyle != "" ? Z.parameters.completeStyle[0] : null;
			
			Z.autoReady = false;
			var readyCount:int = 0;
			
			var dragged:*;
			
			//-----------ELEMENTS--------------------------
			for (var i:Number=0; i<Z.parameters.item.length(); i++)
			{

				function kikka()
				{

					var container:MovieClip = new MovieClip();
					addChild(container);
					container.index = i;
					container.passive = "" + Z.parameters.item[i].passive == "true";
					container.draggable = "" + Z.parameters.item[i].draggable == "true";
					container.x = Z.parameters.item[i].x;
					container.y = Z.parameters.item[i].y;
					containers.push(container);
					
					var img:*;
					if ("" + Z.parameters.item[i].imageAsset != "") {
						var img:* = Z.create(Z.parameters.item[i].imageAsset.children());
						img.bind("ready", Z.wrap(function():void {
							try {
								img.content.smoothing = true;
							} catch (e:Error) {
							}
							var styled:*;
							if (container.passive) {
								styled = Z.styler.create(img, null);							
							} else {
								if (container.draggable) {
									styled = Z.styler.create(img, draggableStyle);
								} else {
									styled = Z.styler.create(img, clickableStyle);							
								}
							}
							container.addChild(styled);
							container.styled = styled;
							readyCount++;
							if (readyCount==Z.parameters.item.length()) {
								Z.ready();
							}
						}));
					} else {
						var bmd:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.item[i].imageValue[0]);
						img = new Bitmap(bmd);
						img.smoothing = true;
						var styled:*;
						if (container.passive) {
							styled = Z.styler.create(img, null);
						} else {
							if (container.draggable) {
								styled = Z.styler.create(img, draggableStyle);
							} else {
								styled = Z.styler.create(img, clickableStyle);
							}
						}
						container.addChild(styled);
						container.styled = styled;
						readyCount++;
						if (readyCount==Z.parameters.item.length()) {
							Z.ready();
						}
					}
					container.img = img;

					if ("" + Z.parameters.item[i].targetItemId != "") {
						for (var j:Number=0; j<Z.parameters.item.length(); j++) {
							var itemId:String = Z.parameters.item[j].id;
							var targetId:String = Z.parameters.item[i].targetItemId;
							if (itemId == targetId) {
								container.targetItemIndex = j;
								targetCount++;
							}
						}
					}
					
					if (Z.mahti.multitouch) {
						Z.wrapEventListener(container,  TouchEvent.TOUCH_BEGIN, function(e:TouchEvent) {
							var p:Point = new Point(e.stageX, e.stageY);
							p = THIS.globalToLocal(p);
							if (container.draggable) {
								var tmp:MovieClip = new MovieClip();
								addChild(tmp);
								var tmpIndex = getChildIndex(tmp);
								setChildIndex(container, tmpIndex - 1);
								removeChild(tmp);
								container.startDragX = container.x;
								container.startDragY = container.y;
								container.startDragPointerX = p.x;
								container.startDragPointerY = p.y;
								container.dragTouchPointID = e.touchPointID;
								if (!container.passive) {
									Z.styler.update(container.styled, container.img, draggedStyle);
								}
							} else {
								if (!container.passive) {
									Z.styler.update(container.styled, container.img, clickedStyle);
								}
							}						
						});
					} else {
						Z.wrapEventListener(container, MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
							if (container.draggable) {
								var tmp:MovieClip = new MovieClip();
								addChild(tmp);
								var tmpIndex = getChildIndex(tmp);
								setChildIndex(container, tmpIndex - 1);
								removeChild(tmp);
								dragged = container;
								container.startDrag();
								if (!container.passive) {
									Z.styler.update(container.styled, container.img, draggedStyle);
								}
							} else {
								if (!container.passive) {
									Z.styler.update(container.styled, container.img, clickedStyle);
								}
							}						
						});						
					}
				}

				kikka();
			}
			
			if (!Z.mahti.multitouch) {
				Z.wrapEventListener(this, MouseEvent.MOUSE_UP, function(e:Event) {
					endDrag(dragged);
				});
				Z.wrapEventListener(this, MouseEvent.ROLL_OUT, function(e:Event) {
					endDrag(dragged);
				});
			} else {
				Z.wrapEventListener(this, TouchEvent.TOUCH_MOVE, function(e:TouchEvent) {
					var p:Point = new Point(e.stageX, e.stageY);
					p = THIS.globalToLocal(p);
					for (var i:int = 0 ; i<containers.length ; i++) {
						if (containers[i].dragTouchPointID == e.touchPointID) {
							if (containers[i].draggable) {
								containers[i].x = containers[i].startDragX - containers[i].startDragPointerX + p.x;
								containers[i].y = containers[i].startDragY - containers[i].startDragPointerY + p.y;
							}							
						}
					}
				});
				Z.wrapEventListener(this, TouchEvent.TOUCH_END, function(e:TouchEvent) {
					for (var i:int = 0 ; i<containers.length ; i++) {
						if (containers[i].dragTouchPointID == e.touchPointID) {
							endDrag(containers[i]);
						}
					}
				});
				Z.wrapEventListener(this, TouchEvent.TOUCH_ROLL_OUT, function(e:TouchEvent) {
					for (var i:int = 0 ; i<containers.length ; i++) {
						if (containers[i].dragTouchPointID == e.touchPointID) {
							endDrag(containers[i]);
						}
					}
				});
			}					
			
			function endDrag(container) {
				if (container) {
					if (container.draggable) {
						if (!container.passive) {
							Z.styler.update(container.styled, container.img, draggableStyle);
							if (!Z.mahti.multitouch) {
								container.stopDrag();
							}
						}
					} else {
						if (!container.passive) {
							Z.styler.update(container.styled, container.img, clickableStyle);
						}						
					}
					checkGame(container.index, container.targetItemIndex);
					container.dragTouchPointID = -1;
				}
				dragged = null;
			}

			//------------FUNCTIONS--------------------------
			function randomNumber(min:Number,max:Number)
			{
				var rndNumber:Number = Math.floor(Math.random() * max) + min;
				return rndNumber;
			}

			function checkGame(itemIndex, targetIndex)
			{

				var container = containers[itemIndex];	
				var targetContainer = containers[targetIndex];
				
				var itemOrigX = Z.parameters.item[itemIndex].x;
				var itemOrigY = Z.parameters.item[itemIndex].y;
				var itemLockX = Z.parameters.item[itemIndex].targetLockX;
				var itemLockY = Z.parameters.item[itemIndex].targetLockY;

				if (targetContainer && container.hitTestObject(targetContainer))
				{
					if (!container.passive) {
						Z.styler.update(container.styled, container.img, completeStyle);					
					}
					
					//-----------raahattava osuu kohteeseeen

					if ("" + Z.parameters.item[itemIndex].successEventName != "") {
						Z.hat.magicast_triggerEvent("" + Z.parameters.item[itemIndex].successEventName);	
					} else if ("" + Z.parameters.successEventName != "") {
						Z.hat.magicast_triggerEvent("" + Z.parameters.successEventName);
					}

					if ("" + Z.parameters.item[itemIndex].targetLock == "true") {
						Z.tweener.start(container, ["x", "y"], [itemLockX, itemLockY], .2);
					} else if ("" + Z.parameters.item[itemIndex].targetVanish == "true") {
						Z.tweener.start(container, ["alpha"], [0], .2);
					}

					if ("" + Z.parameters.item[itemIndex].successSoundAsset != "") {
						Z.sound.playAsset(Z.parameters.item[itemIndex].successSoundAsset.children(), 1);
					} else if (successSoundLength) {
						Z.sound.playAsset(Z.parameters.successSoundAsset[randomNumber(0, successSoundLength)].children(), 1);
					}

					container.mouseEnabled = false;
					container.mouseChildren = false;
					
					targetFound++;

					//----kaikki raahattu-----
					if (targetCount == targetFound) {
						Z.hat.magicast_triggerEvent("complete");
					}
					
				}
				else
				{
					//----raahattava ei osu kohteeseen
					
					if ("" + Z.parameters.item[itemIndex].failureEventName != "") {
						Z.hat.magicast_triggerEvent("" + Z.parameters.item[itemIndex].failureEventName);	
					} else if ("" + Z.parameters.failureEventName != "") {
						Z.hat.magicast_triggerEvent("" + Z.parameters.failureEventName);	
					}
					
					if ("" + Z.parameters.item[itemIndex].bounceBack == "true")
					{
						Z.tweener.start(container, ["x", "y"], [itemOrigX, itemOrigY], .2);
					}
					
					if ("" + Z.parameters.item[itemIndex].failureSoundAsset != "") {
						Z.sound.playAsset(Z.parameters.item[itemIndex].failureSoundAsset.children(), 1);
					} else if (failureSoundLength) {
						Z.sound.playAsset(Z.parameters.failureSoundAsset[randomNumber(0, failureSoundLength)].children(), 1);
					}
				}
			}
		}
	}
}