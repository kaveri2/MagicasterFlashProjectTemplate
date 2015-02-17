package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.events.*;	

	import flash.ui.Multitouch;
	import flash.events.TouchEvent;
	import flash.events.Event;
	
	public class int_2012_game_card extends MovieClip {
		
		public function int_2012_game_card(Z:*) {
			
			var disbled:Boolean = false;
			
			Z.autoReady = false;
			
			var sizeSprite:Sprite = new Sprite();
			addChild(sizeSprite);
			Z.hat.magicast_run = function() {
				removeChild(sizeSprite);
				for (var i:int = 0 ; i<items.length ; i++) {
					addChild(containers[i]);
					containers[i].x = maxWidth / 2 + (i % cols) * (maxWidth + padding);
					containers[i].y = maxHeight / 2 + Math.floor(i / cols) * (maxHeight + padding);
				}
			}
			
			var i:int;

			var selectedSoundLength:Number = Z.parameters.selectedSoundAsset.length();
			var successSoundLength:Number = Z.parameters.successSoundAsset.length();
			var failureSoundLength:Number = Z.parameters.failureSoundAsset.length();

			var containers:Array = new Array(); 
			var disabled:Boolean = false;
			
			var padding:Number = "" + Z.parameters.padding != "" ? parseFloat("" + Z.parameters.padding) : 0;
			var maxWidth:Number = 0;
			var maxHeight:Number = 0;
			
			var items:Array = new Array();
			for (i=0; i<Z.parameters.item.length(); i++) {
				items.push(Z.parameters.item[i]);
			}
			if ("" + Z.parameters.randomize == "true") {
				items.sort(randomFunction);
			}

			var ordered:Boolean = "" + Z.parameters.ordered == "true";
			var nextKey:String = "";
			
			var cols:int = parseInt(Z.parameters.cols);
			var rows:int = parseInt(Z.parameters.rows);
			if (cols==0 && rows>0) {
				cols = Math.ceil(items.length / rows);
			}
			if (rows==0 && cols>0) {
				rows = Math.ceil(items.length / cols);
			}
			
			var style:XML = "" + Z.parameters.style != "" ? Z.parameters.style[0] : null;
			var selectedStyle:XML = "" + Z.parameters.selectedStyle != "" ? Z.parameters.selectedStyle[0] : null;
			
			var totalOk:int = 0;
			
			for (i=0; i<items.length; i++) {
				
				function kikka () {
					
					var itemIndex:int = i;
					
					var container:MovieClip = new MovieClip(); 
					containers.push(container);
					
					container.key = "" + items[i].key;
					container.selected = false;
					container.removed = false;
					container.back = new Sprite();
					container.front = new Sprite();
					container.flip = false;
					
					var ok:int = 0;
					function oneReady() {
						ok++;
						if (ok==5) {
							var frontStyle = Z.styler.create(container.front, style);
							container.addChild(frontStyle);
							container.frontStyle = frontStyle;
							var backStyle;
							if (container.flip) {
								backStyle = Z.styler.create(container.back, style);
								container.addChild(backStyle);
								container.frontStyle.alpha = 0;
								container.frontStyle.scaleX = 0;
							} else {
								backStyle = new Sprite();
							}
							container.backStyle = backStyle;
							if (container.selectedImage) {
								container.addChild(container.selectedImage);
								container.selectedImage.alpha = 0;
							}
							if (container.width > maxWidth) {
								maxWidth = container.width;
							}
							if (container.height > maxHeight) {
								maxHeight = container.height;
							}
						}
						totalOk++;
						if (totalOk==items.length * 5) {
							sizeSprite.graphics.drawRect(0, 0, cols * maxWidth + (cols - 1) * padding, rows * maxHeight + (rows - 1) * padding);
 							Z.ready();
						}
					}
					
					var img1:*;
					if ("" + Z.parameters.backBackgroundImageAsset != "") {
						container.flip = true;
						img1 = Z.create(Z.parameters.backBackgroundImageAsset.children());
						container.back.addChild(img1);
						img1.bind("ready", Z.wrap(function() {
							try {
								img1.content.smoothing = true;
							} catch (e:Error) {
							}
							img1.setReferencePoint(img1.width / 2, img1.height / 2);
							oneReady();
						}));
					} else if ("" + Z.parameters.backBackgroundImageValue != "") {
						var bmd1:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.backBackgroundImageValue[0]);
						img1 = new Bitmap(bmd1);
						img1.smoothing = true;
						img1.x = -img1.width / 2;
						img1.y = -img1.height / 2;
						container.back.addChild(img1);
						oneReady();
					} else {
						oneReady();
					}
					if ("" + items[i].backImageAsset != "") {
						container.flip = true;
						var img2:* = Z.create(items[i].backImageAsset.children());
						container.back.addChild(img2);
						img2.bind("ready", Z.wrap(function() {
							try {
								img2.content.smoothing = true;
							} catch (e:Error) {
							}
							img2.setReferencePoint(img2.width / 2, img2.height / 2);
							oneReady();
						}));
					} else if ("" + Z.parameters.backImageValue != "") {
						var bmd2:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.backImageValue[0]);
						img2 = new Bitmap(bmd2);
						img2.smoothing = true;
						img2.x = -img2.width / 2;
						img2.y = -img2.height / 2;
						container.back.addChild(img2);
						oneReady();
					} else {
						oneReady();
					}
					if ("" + Z.parameters.frontBackgroundImageAsset != "") {
						var img3:* = Z.create(Z.parameters.frontBackgroundImageAsset.children());
						container.front.addChild(img3);
						img3.bind("ready", Z.wrap(function() {
							try {
								img3.content.smoothing = true;
							} catch (e:Error) {
							}
							img3.setReferencePoint(img3.width / 2, img3.height / 2);
							oneReady();
						}));
					} else if ("" + Z.parameters.frontBackgroundImageValue != "") {
						var bmd3:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.frontBackgroundImageValue[0]);
						img3 = new Bitmap(bmd3);
						img3.smoothing = true;
						img3.x = -img3.width / 2;
						img3.y = -img3.height / 2;
						container.front.addChild(img3);
						oneReady();
					} else {
						oneReady();
					}
					if ("" + items[i].frontImageAsset != "") {
						var img4:* = Z.create(items[i].frontImageAsset.children());
						container.front.addChild(img4);
						img4.bind("ready", Z.wrap(function() {
							try {
								img4.content.smoothing = true;
							} catch (e:Error) {
							}
							img4.setReferencePoint(img4.width / 2, img4.height / 2);
							oneReady();
						}));
					} else if ("" + Z.parameters.frontImageValue != "") {
						var bmd4:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.frontImageValue[0]);
						img4 = new Bitmap(bmd4);
						img4.smoothing = true;
						img4.x = -img4.width / 2;
						img4.y = -img4.height / 2;
						container.front.addChild(img4);
						oneReady();
					} else {
						oneReady();
					}
					var img5:*;
					if ("" + Z.parameters.selectedImageAsset != "") {
						img5 = Z.create(Z.parameters.selectedImageAsset.children());
						container.selectedImage = img5;
						img5.bind("ready", Z.wrap(function() {
							try {
								img5.content.smoothing = true;
							} catch (e:Error) {
							}
							img5.setReferencePoint(img5.width / 2, img5.height / 2);
							oneReady();
						}));
					} else if ("" + Z.parameters.selectedImageValue != "") {
						var bmd5:BitmapData = Z.hat.magicast_resolveAndGetValue(Z.parameters.selectedImageValue[0]);
						img5 = new Bitmap(bmd5);
						img5.smoothing = true;
						container.selectedImage = img5;
						oneReady();
					} else {
						oneReady();
					}
					
					Z.wrapEventListener(container, Z.mahti.multitouch ? TouchEvent.TOUCH_TAP : MouseEvent.CLICK, function(e:Event) {
						
						var i:int;
						
						if (disabled || container.selected || container.removed) {
							return;
						}

						// OLD SYNTAX
						if ("" + items[itemIndex].selectedEventName != "") {
							Z.hat.magicast_triggerEvent("" + items[itemIndex].selectedEventName);	
						} else if ("" + Z.parameters.selectedEventName != "") {
							Z.hat.magicast_triggerEvent("" + Z.parameters.selectedEventName);
						}
						
						// NEW SYNTAX
						if ("" + items[itemIndex].selectedEvent != "") {
							Z.hat.magicast_resolveAndTriggerEvent(items[itemIndex].selectedEvent[0]);
						} else if ("" + Z.parameters.selectedEvent != "") {
							Z.hat.magicast_resolveAndTriggerEvent(Z.parameters.selectedEvent[0]);
						}

						if ("" + items[itemIndex].selectedSoundAsset != "") {
							Z.sound.playAsset(items[itemIndex].selectedSoundAsset.children(), 1);
						} else if (selectedSoundLength) {
							Z.sound.playAsset(Z.parameters.selectedSoundAsset[randomNumber(0, selectedSoundLength)].children(), 1);
						}

						container.selected = true;
						disabled = true;

						if (selectedStyle) {
							Z.styler.update(container.frontStyle, container.front, selectedStyle);
							if (container.flip) {
								Z.styler.update(container.backStyle, container.back, selectedStyle);
							}
						}

						if (container.selectedImage) {
							Z.tweener.stop(container.selectedImage, ["alpha"]);
							Z.tweener.start(container.selectedImage, ["alpha"], [1], 0.2, "linear", 0)
						}

						function nextStep() {

							disabled = false;

							var correct:Boolean = true;
							if (ordered && container.key != nextKey) {
								correct = false;
							}
							var allCorrect:Boolean = true;
							if (container.key == "") {
								correct = false;
								allCorrect = false;
							} else {
								for (i=0 ; i<containers.length; i++) {
									if (containers[i].selected && 
										containers[i].key != container.key) correct = false;
									if (!containers[i].selected &&
										containers[i].key == container.key) allCorrect = false;
								}
							}
							
							if (!correct) {

								// OLD SYNTAX
								if ("" + items[itemIndex].failureEventName != "") {
									Z.hat.magicast_triggerEvent("" + items[itemIndex].failureEventName);	
								} else if ("" + Z.parameters.failureEventName != "") {
									Z.hat.magicast_triggerEvent("" + Z.parameters.failureEventName);
								// NEW SYNTAX
								} else if ("" + items[itemIndex].failureEvent != "") {
									Z.hat.magicast_resolveAndTriggerEvent(items[itemIndex].failureEvent[0]);	
								} else if ("" + Z.parameters.failureEvent != "") {
									Z.hat.magicast_resolveAndTriggerEvent(Z.parameters.failureEvent[0]);
								}
							
								if ("" + items[itemIndex].failureSoundAsset != "") {
									Z.sound.playAsset(items[itemIndex].failureSoundAsset.children(), 1);
								} else if (failureSoundLength) {
									Z.sound.playAsset(Z.parameters.failureSoundAsset[randomNumber(0, failureSoundLength)].children(), 1);
								}
								
								var disabling:Boolean = false;
								for (i=0 ; i<containers.length; i++) {
									if (containers[i].selected) {
										containers[i].selected = false;
	
										if (containers[i].selectedImage) {
											Z.tweener.stop(containers[i].selectedImage, ["alpha"]);
											Z.tweener.start(containers[i].selectedImage, ["alpha"], [0], 0.2, "linear")
										}
	
										if (containers[i].flip) {
											Z.tweener.stop(containers[i].frontStyle, ["scaleX", "alpha"]);
											Z.tweener.start(containers[i].frontStyle, ["scaleX", "alpha"], [0, 0], 0.3, "linear", 0 + 1.5);
											Z.tweener.stop(containers[i].backStyle, ["scaleX", "alpha"]);
											if (!disabling) {
												disabled = true;												
												Z.tweener.start(containers[i].backStyle, ["scaleX", "alpha"], [1, 1], 0.3, "linear", 0.3 + 1.5, Z.wrap(function() {
													disabled = false;   
												}));
												disabling = true;
											} else {
												Z.tweener.start(containers[i].backStyle, ["scaleX", "alpha"], [1, 1], 0.3, "linear", 0.3 + 1.5);
											}
										}
										
										if (selectedStyle) {
											Z.styler.update(containers[i].frontStyle, containers[i].front, style);
											if (containers[i].flip) {
												Z.styler.update(containers[i].backStyle, containers[i].back, style);
											}
										}
																			
									}
								}
							}
							
							if (allCorrect) {

								// OLD SYNTAX
								if ("" + items[itemIndex].successEventName != "") {
									Z.hat.magicast_triggerEvent("" + items[itemIndex].successEventName);	
								} else if ("" + Z.parameters.successEventName != "") {
									Z.hat.magicast_triggerEvent("" + Z.parameters.successEventName);
								// NEW SYNTAX
								} else if ("" + items[itemIndex].successEvent != "") {
									Z.hat.magicast_resolveAndTriggerEvent(items[itemIndex].successEvent[0]);
								} else if ("" + Z.parameters.successEvent != "") {
									Z.hat.magicast_resolveAndTriggerEvent(Z.parameters.successEvent[0]);
								}
							
								if ("" + items[itemIndex].successSoundAsset != "") {
									Z.sound.playAsset(items[itemIndex].successSoundAsset.children(), 1);
								} else if (successSoundLength) {
									Z.sound.playAsset(Z.parameters.successSoundAsset[randomNumber(0, successSoundLength)].children(), 1);
								}
								
								var allRemoved:Boolean = true;
								for (i=0 ; i<containers.length ; i++) {
									if (containers[i].selected) {
										containers[i].selected = false;
										containers[i].removed = true;
										
										if (containers[i].selectedImage) {
											Z.tweener.stop(containers[i].selectedImage, ["alpha"]);
											Z.tweener.start(containers[i].selectedImage, ["alpha"], [0], 0.2, "linear")
										}
										
										var waitTime:Number = container.flip ? 1.5 : 0;
										Z.tweener.stop(containers[i].backStyle, ["alpha"]);
										Z.tweener.start(containers[i].backStyle, ["alpha"], [0], 1, "linear", waitTime);
										Z.tweener.stop(containers[i].frontStyle, ["alpha"]);
										Z.tweener.start(containers[i].frontStyle, ["alpha"], [0], 1, "linear", waitTime);
									}
									if (containers[i].key != "" && !containers[i].removed) {
										allRemoved = false;
									}
								}
								if (allRemoved) {
									Z.hat.magicast_triggerEvent("complete");
								}
							}
						}
	
						if (container.flip) {
							Z.tweener.stop(container.backStyle, ["scaleX"]);
							Z.tweener.start(container.backStyle, ["scaleX"], [0], 0.3, "linear", 0);
							Z.tweener.stop(container.frontStyle, ["scaleX", "alpha"]);
							Z.tweener.start(container.frontStyle, ["scaleX", "alpha"], [1, 1], 0.3, "linear", .3, Z.wrap(function() {
								nextStep();
							}));
						} else {
							nextStep();
						}

					});					
				}
				
				kikka();
			}
			
			function randomFunction(a, b) {
				if (Math.random()>0.5) {
					return 1;
				} else {
					return -1;
				}
			}
		
			function randomNumber(min:Number, max:Number) {
				 var rndNumber:Number=Math.floor(Math.random( )* max)+min;
				 return rndNumber;
			}
		}
	}
}