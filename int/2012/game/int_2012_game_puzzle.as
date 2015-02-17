package  {
	
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import flash.display.BitmapData;

	import flash.ui.Multitouch;
	import flash.events.TouchEvent;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class int_2012_game_puzzle extends MovieClip {
		
		public function int_2012_game_puzzle(Z:*) {
			
			var THIS:* = this;
			
			var pieceWidth:Number;
			var pieceHeight:Number;
			var marginWidth:Number;
			var marginHeight:Number;
			
			var pieces:Array = new Array();
			var placeMcArray:Array = new Array();
			var pieceMcArray:Array = new Array();

			var cols:Number = Z.parameters.cols;
			var rows:Number = Z.parameters.rows;
			var foundPieces:int = 0;
			var backgroundAlpha:Number = parseFloat(Z.parameters.backgroundAlpha) / 100;
			if (!backgroundAlpha) backgroundAlpha = 0.3;
			var draggableStyle:XML = "" + Z.parameters.draggableStyle != "" ? Z.parameters.draggableStyle[0] : null;
			var draggedStyle:XML = "" + Z.parameters.draggedStyle != "" ? Z.parameters.draggedStyle[0] : null;
							
			var bgContainer:Sprite = new Sprite();
			bgContainer.alpha = backgroundAlpha;
			addChild(bgContainer);
			var placesContainer:Sprite = new Sprite();
			addChild(placesContainer);
			var piecesContainer:Sprite = new Sprite();
			addChild(piecesContainer);

			var sizeSprite:Sprite = new Sprite();
			addChild(sizeSprite);
			Z.hat.magicast_run = function() {				
				removeChild(sizeSprite);
				
				THIS.graphics.beginFill(0x000000, 0);
				THIS.graphics.drawRect(-10000, -10000, 20000, 20000);
				THIS.graphics.endFill();

				pieceWidth = image.width / cols;
				pieceHeight = image.height / rows;
				marginWidth = pieceWidth * 0.15;
				marginHeight = pieceWidth * 0.15;

				var bmd:BitmapData = new BitmapData(image.width, image.height);									
				bmd.draw(image);
				var bg:Bitmap = new Bitmap(bmd);
				bg.smoothing = true;
				bgContainer.addChild(bg);

				var c, r;

				var h_edges:Array = new Array();
				for (c=0; c<cols-1; c++) {
					h_edges[c] = new Array();				
					for (r=0; r<rows; r++) {
						h_edges[c][r] = Math.random() < 0.5 ? 0 : 1;
					}
				}
				var v_edges:Array = new Array();
				for (c=0; c<cols; c++) {
					v_edges[c] = new Array();				
					for (r=0; r<rows-1; r++) {
						v_edges[c][r] = Math.random() < 0.5 ? 0 : 1;
					}
				}
				
				for (c=0; c<cols; c++) {
					pieces[c] = new Array();				
					for (r=0; r<rows; r++) {
						var shape:Sprite = new Sprite();
						shape.graphics.lineStyle(0, 0, 0);
						shape.graphics.beginFill(0x000000, 1);
						shape.graphics.drawRect(0, 0, pieceWidth + marginWidth * 2, pieceHeight + marginHeight * 2);
						shape.graphics.beginFill(0xffffff, 1);
						shape.graphics.drawRect(marginWidth, marginHeight, pieceWidth, pieceHeight);
						if (c>0) {
							shape.graphics.beginFill(h_edges[c-1][r] ? 0x000000 : 0xffffff, 1);
							shape.graphics.drawCircle(marginWidth, marginHeight + pieceHeight / 2, marginWidth);
						}
						if (c<cols-1) {
							shape.graphics.beginFill(h_edges[c][r] ? 0xffffff : 0x000000, 1);
							shape.graphics.drawCircle(marginWidth + pieceWidth, marginHeight + pieceHeight / 2, marginWidth);
						}
						if (r>0) {
							shape.graphics.beginFill(v_edges[c][r-1] ? 0x000000 : 0xffffff, 1);
							shape.graphics.drawCircle(marginWidth + pieceWidth / 2, marginHeight, marginHeight);
						}
						if (r<rows-1) {
							shape.graphics.beginFill(v_edges[c][r] ? 0xffffff : 0x000000, 1);
							shape.graphics.drawCircle(marginWidth + pieceWidth / 2, marginHeight + pieceHeight, marginHeight);
						}
						shape.graphics.endFill();
						var shapeBmd:BitmapData		= new BitmapData(pieceWidth + marginWidth * 2, pieceHeight + marginHeight * 2, true, 0x00000000);
						shapeBmd.draw(shape);
						(new Rectangle(marginWidth, marginHeight, pieceWidth, pieceHeight), 0xffffffff);
						var tmpBmd:BitmapData		= new BitmapData(pieceWidth + marginWidth * 2, pieceHeight + marginHeight * 2);
						var m:Matrix 				= new Matrix();
						m.translate(-pieceWidth * c + marginWidth, -pieceHeight * r + marginHeight);
						tmpBmd.draw(bmd, m);
						tmpBmd.copyChannel(
							shapeBmd,
							new Rectangle(0, 0, tmpBmd.width, tmpBmd.height),
							new Point(0, 0),
							1, 8
						);
						pieces[c][r] = tmpBmd;
					}

				}

				var nro:int = 0;
				for (var j:Number =0; j<pieces.length; j++) {
					for (var k:Number=0; k<pieces[j].length; k++) {
						function kikka() {
							var pieceNro:Number				= nro++;

							var placeContainer:MovieClip 	= new MovieClip();
							placesContainer.addChild(placeContainer);
							placeContainer.alpha = 0;
							placeMcArray.push(placeContainer);
							
							var pieceContainer:MovieClip 	= new MovieClip(); 
							piecesContainer.addChild(pieceContainer);
							pieceMcArray.push(pieceContainer);
							
							var place:Bitmap = new Bitmap(pieces[j][k]);
							place.smoothing = true;
							place.width = pieceWidth + marginWidth * 2;
							place.height = pieceHeight + marginHeight * 2;
							placeContainer.x = j * pieceWidth;
							placeContainer.y = k * pieceHeight;
							
							placeContainer.addChild(place);
							place.x = -marginWidth;
							place.y = -marginHeight;
							
							var piece:Bitmap = new Bitmap(pieces[j][k]);
							piece.smoothing = true;
							piece.width = pieceWidth + marginWidth * 2;
							piece.height = pieceHeight + marginHeight * 2;
							pieceContainer.x = randomNumber(0, image.width);
							pieceContainer.y = randomNumber(0, image.height);
							
							var styled = Z.styler.create(piece, draggableStyle);
							pieceContainer.addChild(styled);
							styled.x = -marginWidth;
							styled.y = -marginHeight;
						
							var hit1:Sprite = new Sprite();
							hit1.graphics.lineStyle(0, 0, 0);
							hit1.graphics.beginFill(0x000000, 0);
							hit1.graphics.drawRect(-marginWidth / 2, -marginHeight / 2, pieceWidth + marginWidth, pieceHeight + marginHeight);
							hit1.graphics.endFill();
							pieceContainer.addChild(hit1);
							
							var hit2:Sprite = new Sprite();
							hit2.graphics.lineStyle(0, 0, 0);
							hit2.graphics.beginFill(0x000000, 0);
							hit2.graphics.drawRect(-marginWidth / 2, -marginHeight / 2, pieceWidth + marginWidth, pieceHeight + marginHeight);
							hit2.graphics.endFill();
							placeContainer.addChild(hit2);
						
							pieceContainer.pieceNro = pieceNro;							
							pieceContainer.piece = piece;
							pieceContainer.styled = styled;
							pieceContainer.hit = hit1;

							placeContainer.hit = hit2;

							if (Z.mahti.multitouch) {
								Z.wrapEventListener(pieceContainer.hit, TouchEvent.TOUCH_BEGIN, function(e:TouchEvent) {
									Z.styler.update(styled, piece, draggedStyle);
									piecesContainer.setChildIndex(pieceContainer, piecesContainer.numChildren - 1);
									pieceContainer.dragTouchPointID = e.touchPointID;
									var p:Point = new Point(e.stageX, e.stageY);
									p = THIS.globalToLocal(p);
									pieceContainer.startDragX = pieceContainer.x;
									pieceContainer.startDragY = pieceContainer.y;
									pieceContainer.startDragPointerX = p.x;
									pieceContainer.startDragPointerY = p.y;
									pieceContainer.dragTouchPointID = e.touchPointID;
								});
							} else {
								Z.wrapEventListener(pieceContainer.hit, MouseEvent.MOUSE_DOWN, function(e:Event) {
									if (endDrag != null) {
										endDrag();
									}
													
									Z.styler.update(styled, piece, draggedStyle);
									piecesContainer.setChildIndex(pieceContainer, piecesContainer.numChildren - 1);
									pieceContainer.startDrag();
									
									endDrag = function() {
										Z.styler.update(pieceContainer.styled, pieceContainer.piece, draggableStyle);
										pieceContainer.stopDrag();
										checkGame(pieceContainer.pieceNro, stage.mouseX, stage.mouseY);
										endDrag = null;
									}
								});
							}
						}
						kikka();
					}
				}
			}
			
			var endDrag:Function;
			
			if (Z.mahti.multitouch) {
				Z.wrapEventListener(this, TouchEvent.TOUCH_MOVE, function(e:TouchEvent) {
					var p:Point = new Point(e.stageX, e.stageY);
					p = THIS.globalToLocal(p);
					for (var i:int = 0 ; i<pieceMcArray.length ; i++) {
						if (pieceMcArray[i].dragTouchPointID == e.touchPointID) {
							pieceMcArray[i].x = pieceMcArray[i].startDragX - pieceMcArray[i].startDragPointerX + p.x;
							pieceMcArray[i].y = pieceMcArray[i].startDragY - pieceMcArray[i].startDragPointerY + p.y;
						}
					}
				});
				Z.wrapEventListener(this, TouchEvent.TOUCH_END, function(e:TouchEvent) {
					for (var i:int = 0 ; i<pieceMcArray.length ; i++) {
						if (pieceMcArray[i].dragTouchPointID == e.touchPointID) {
							Z.styler.update(pieceMcArray[i].styled, pieceMcArray[i].piece, draggableStyle);
							checkGame(pieceMcArray[i].pieceNro, e.stageX, e.stageY);
							pieceMcArray[i].dragTouchPointID = -1;
						}
					}
				});				
				Z.wrapEventListener(this, TouchEvent.TOUCH_ROLL_OUT, function(e:TouchEvent) {
					for (var i:int = 0 ; i<pieceMcArray.length ; i++) {
						if (pieceMcArray[i].dragTouchPointID == e.touchPointID) {
							Z.styler.update(pieceMcArray[i].styled, pieceMcArray[i].piece, draggableStyle);
							checkGame(pieceMcArray[i].pieceNro, e.stageX, e.stageY);
							pieceMcArray[i].dragTouchPointID = -1;
						}
					}
				});				
			} else {
				Z.wrapEventListener(this, MouseEvent.MOUSE_UP, function(e:Event) {
					if (endDrag != null) {
						endDrag();
					}
				});
				Z.wrapEventListener(this, MouseEvent.ROLL_OUT, function(e:Event) {
					if (endDrag != null) {
						endDrag();
					}
				});
			}

			var image:*;
			if ("" + Z.parameters.imageAsset != "") {
				Z.autoReady = false;
				image = Z.create(Z.parameters.imageAsset[0]);
				image.bind("ready", Z.wrap(function():void {
					try {
						image.content.smoothing = true;
					} catch (e:Error) {
					}
					sizeSprite.graphics.drawRect(0, 0, image.width, image.height);
					Z.ready();
				}));
			} else {
				var bmd:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.imageValue[0]);
				image = new Bitmap(bmd);
				image.smoothing = true;
				sizeSprite.graphics.drawRect(0, 0, image.width, image.height);
			}
			
/////-----------------FUNCTIONS--------------		
			function randomNumber (min:Number,max:Number) {
				 var rndNumber:Number=Math.floor(Math.random()*max)+min;
				 return rndNumber;
			}				
				
			function checkGame(itemId, x, y) {
				
				var piece 		= pieceMcArray[itemId];
				var target 		= placeMcArray[itemId];
				// target center
				var p1:Point = placeMcArray[itemId].localToGlobal(new Point(
					pieceWidth / 2,
					pieceHeight / 2
				));
				// mouse
				var p2:Point = new Point(x, y);

				//-----------raahattava osuu kohteeseeen			
				if (piece.hit.hitTestPoint(p1.x, p1.y, true) || target.hit.hitTestPoint(p2.x, p2.y, true)) {
					
					piece.alpha = 0;
					piece.mouseEnabled = false;
					piece.mouseChildren = false;
					foundPieces++;
				
					//----kaikki raahattu-----
					if (foundPieces == rows * cols) {
						Z.tweener.start(target, ["alpha"], [1], .2, "easeOutRegular", 0, function() {
							bgContainer.alpha = 1;
							placesContainer.alpha = 0;
							Z.hat.magicast_triggerEvent("complete");
						});
					} else {
						Z.tweener.start(target, ["alpha"], [1], .2, "easeOutRegular", 0);
					}
					
				//----raahattava ei osu kohteeseen
				} else {
				}
			}
		}
	}
}