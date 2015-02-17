package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	
	public class int_example_magicast extends MovieClip {
		
		public function int_example_magicast(Z:*) {

			// this is used in the examples
			var s:Sprite = new Sprite();

			// CHAPTER 1: PARAMETERS
			
			// the layer will be given parameters as XMLList
			var number:Number = "" + Z.parameters.number != "" ? parseFloat("" + Z.parameters.number) : 0;

			// CHAPTER 2: INITIALIZATION
			
			// loading assets through Z
			if ("" + Z.parameters.asset != "") {
				// don't trigger "ready" before important assets have loaded
				Z.autoReady = false;
				var asset:* = Z.create(Z.parameters.asset);
				Z.bind("ready", function():void {				   
				   s.addChild(asset);
					Z.ready();
				});
			} 
			
			// Magicast automatically calculates layer's bounds when Z event "ready" has been triggered,
			// but it can also be set manually
			var bounds:Rectangle;
			Z.hat.magicast_setBounds(bounds); // if null, Magicast will recalculate the bounds
			
			// Magicast will tell each layer when they are actually put on the screen and when they should start working
			var running:Boolean = false;
			Z.hat.magicast_run = function():void {
				running = true;
			};
			
			// Magicast will ask the layer to adjust to given dimensions, just before calculating new calculations
			// the arguments may or may not be defined, depending on layer properties
			Z.hat.magicast_adjust = function(width:Number, height:Number, aspectRatio:Number):void {
				// adjust the contents
				s.width = width != undefined ? width : 100;
				s.height = height != undefined ? height : 100;
				// see how adjustments affected the bounds and tell Magicast
				var adjustedWidth:Number = s.width;
				var adjustedHeight:Number = s.height;
				Z.hat.magicast_setBounds(new Rectangle(adjustedWidth, adjustedHeight));
			};
			
			// Magicast will set the layer's x,y,width,height,scaleX,scaleY,rotation,alpha
			// unless magicast_render function is defined
			Z.hat.magicast_render = function():void {
				// manually render the contents to the desired location
				s.x = Z.hat.magicast_calculations["x"];
				s.y = Z.hat.magicast_calculations["y"];			
				// other variables are:
				// - width, height: the desired width and height of the object
				// - scaleX, scaleY: on top of width and height, how much they are scaled
				// - rotation
				// - alpha
			};
			
			// CHAPTER 3: Communicating with Magicast
			
			// Most importantly layers should trigger events Magicast
			// Note that they are being ignored until magicast_run has been called
			
			// events are simply strings...
			Z.hat.magicast_triggerEvent("eventName");
			
			// ...which can contain parameters...
			Z.hat.magicast_triggerEvent("eventName", XMLList("<parameter1>value1</parameter1>"));
			
			// ...or even be tied to a point on the screen (which will be translated to Magicast's coordinate space)			
			Z.hat.magicast_triggerEvent("eventName", XMLList("<parameter1>value1</parameter1>"), new Point(0, 0));
			
			// Magicast combines the layer's name to the event and compares it to events of the triggers, 
			// which look like this:
			// <event><layer>{this layer's name}</layer><name>{triggered event name}</name></event>
			
			// Through triggers and events, Magicast will run actions.
			// If the action is connected to a layer, it will end up here:
			
			Z.hat.magicast_runAction = function(method:String, parameters:XMLList, eventParameters:XMLList, newPoint:Point):void {
				// The parameters come from Magicast XML:
				// <action>
				//   <layer>{this layer's name}</layer>
				//   <method>{passed unchanged}</method>
				//   <parameters>{passed unchanged}</parameters>
				//  </action>
				
				// eventParameters are the parameters of the original event
				// newPoint is the Point of the event, transformed to this layer's coordinate space.
			};
			
			// CHAPTER 5: Other Magicast features
			
			// Getting and setting global variables
			// - Useful in transferring objects between layers
			
			var variableName:String = "variableName";
			if ("" + Z.parameters.variableName != "") {
				variableName = "" + Z.parameters.variableName;
			}
			Z.hat.magicast_hat.setVariable(variableName, {description: "this is a complex object with a callback function", callback: function() {}});
			
			// And another layer can fetch that:
			var complexObject:* = Z.hat.magicast_hat.getVariable(variableName);
			
			// CHAPTER 6: Z(adam) features
			
			// Z event "tick"
			
			var totalTime:Number = 0;
			Z.bind("tick", function(time:Number):void {
				   if (running) {
					   totalTime = totalTime + time;
				   }
				   trace("Layer has been running for " + totalTime + " seconds!");
			});

			// Z.targetWidth, Z.targetHeight and Z event "targetSizeChange"
			// - Tells the whole Magicast's size (though can be adjusted using layer properties)
			// - Overlapping with magicast_render, so may not be very useful with most layers...
			
			function doResize() {
				// center the content to the screen
				s.x = Z.targetWidth / 2;
				s.y = Z.targetHeight / 2;
			}
			Z.bind("targetSizeChange", function():void {
				doResize();
			});
			doResize(); // one time right away

			// CHAPTER 7: Taking care of memory leaks
			
			// Z event "destroy"
			
			Z.bind("destroy", function():void {
				// remove event listeners
				// stop sounds
				// etc.
			});
			
			// Wrap event listeners through Z, it will
			// automatically call removeEventListener on Z destruction
			
			Z.wrapEventListener(s, MouseEvent.CLICK, function(e:MouseEvent):void {
				// anonymous functions have never been so much fun!
			});
			
			// Wrap objects through Z, when binding to the events of Z extensions
			// (not required in direct Z events)
			
			// example: Tweener moves an object
			
			Z.tweener.start(s, "x", 100, 1, "linear", 0, Z.wrap(function():void {
				// FYI:
				// Tweener extension will check if the callback is a wrapper like this:
				var wrapper:* = Z.wrap("content");
				if(Z.isWrapper(wrapper)) {
					if (wrapper.object != null) {
						trace(wrapper.object);
					}
				}
			}));
			
		}
	}
}