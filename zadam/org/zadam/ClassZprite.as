package org.zadam {
	
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.utils.getQualifiedClassName;
	
	public class ClassZprite extends Sprite implements IZprite {
		
		public var content:Sprite;
		internal var Z:ZadamContext;
		private var _referenceX:Number;
		private var _referenceY:Number;
		
		public function ClassZprite(creator:ZadamContext, c:Class, parameters:XML, options:*) {		

			Z = creator.createChild(parameters, options);
			Z.name = c.toString();
			
			content = new c(Z);
			addChild(content);
			
			ZadamCore.instance.log(this, "Creating '" + c + "'", 5);

			ZadamCore.instance.createInstance(this);
			
			if (Z.autoReady) {
				Z.ready();
			}	
		}
		
		public function get hat():ZadamHat {
			return Z.hat;
		}

		public function get targetWidth():Number {
			return Z._targetWidth;
		}

		public function get targetHeight():Number {
			return Z._targetHeight;
		}

		public function setTargetSize(w:Number, h:Number):void {
			if (Z._targetWidth!=w || Z._targetHeight!=h) {
				Z._targetWidth = w;
				Z._targetHeight = h;
				Z._trigger("targetSizeChange");
			}
		}

		public function get referenceX():Number {
			return _referenceX;
		}

		public function get referenceY():Number {
			return _referenceY;
		}

		public function setReferencePoint(x:Number, y:Number):void {
			_referenceX = x;
			_referenceY = y;
			content.x = -_referenceX;
			content.y = -_referenceY;
		}
		
		public function getBytesTotal():int {
			var b:int = 0; 
			if (Z.getBytesTotal is Function) b = b + Z.getBytesTotal();
			return b;
		}

		public function getBytesLoaded():int {
			var b:int = 0; 
			if (Z.getBytesLoaded is Function) b = b + Z.getBytesLoaded();
			return b;
		}

		public function bind(... args):void {
			Z.bind.apply(Z, args);
		}

		public function unbind(... args):void {
			Z.unbind.apply(Z, args);
		}
	
		public override function toString():String {
			return "ClassZprite: '" + getQualifiedClassName(content) + "'";
		}
		
		public function destroy():void {
			ZadamCore.instance.log(this, "Destroying", 7);

			Z.destroy();
			Z = null;
			
			ZadamCore.instance.destroyInstance(this);
		}
		
	}
}