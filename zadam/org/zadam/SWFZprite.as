package org.zadam {
	
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.utils.getQualifiedClassName;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
		
	public class SWFZprite extends Loader implements IZprite {
		
		internal var Z:ZadamContext;
		public var loadRetry:Boolean = true;
		public var retryTime:Number = 5;
		private var retryTimer:Timer;
		private var url:URLRequest;
		private var context:LoaderContext;
		private var _referenceX:Number;
		private var _referenceY:Number;
		private var _referenceSet:Boolean = false;
//		private var binaryLoader:URLLoader;
		
		public function SWFZprite(creator:ZadamContext, url:URLRequest, parameters:XML, options:*) {		
		
			Z = creator.createChild(parameters, options);
			Z.name = url.url;
	
			this.url = url;
	
			ZadamCore.instance.zadamContexts[contentLoaderInfo] = Z;

			contentLoaderInfo.addEventListener(Event.INIT, _onInit);
			contentLoaderInfo.addEventListener(Event.COMPLETE, _onComplete);
			addEventListener(IOErrorEvent.IO_ERROR, _onIOError);
			contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _onIOError);
			contentLoaderInfo.addEventListener(Event.UNLOAD, _onUnload);

			var applicationDomain:ApplicationDomain = new ApplicationDomain(ZadamCore.instance.getApplicationDomain());
			context = new LoaderContext(false, applicationDomain);
			
			// in AIR, use insecure load
			/*
			try {
				if (url.url.indexOf(".swf")) {
					context["allowLoadBytesCodeExecution"] = true;
					binaryLoader = new URLLoader();
					binaryLoader.dataFormat = URLLoaderDataFormat.BINARY;
					binaryLoader.addEventListener(Event.COMPLETE, _onBinaryLoaderComplete);				
					binaryLoader.addEventListener(IOErrorEvent.IO_ERROR, _onBinaryLoaderIoError);				
					binaryLoader.load(url);
					ZadamCore.instance.log(this, "Started loading using binary loader", 5);
				} else {
					load(url, context);
					ZadamCore.instance.log(this, "Started loading", 5);
				}
			} catch (e:Error) {
			*/
			ZadamCore.instance.log(this, "Started loading", 5);
			load(url, context);
			/*
			}
			*/

			ZadamCore.instance.createInstance(this);
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
			_referenceSet = true;
			_referenceX = x;
			_referenceY = y;
			if (content) {
				content.x = -_referenceX;
				content.y = -_referenceY;
			}
		}
		
		public function getBytesTotal():int {
			var b:int;
//			if (binaryLoader) {
//				b = binaryLoader.bytesTotal;
//			} else {
				b = contentLoaderInfo.bytesTotal;
//			}
			if (Z.getBytesTotal is Function) b = b + Z.getBytesTotal();
			return b;
		}

		public function getBytesLoaded():int {
			var b:int;
//			if (binaryLoader) {
//				b = binaryLoader.bytesLoaded;
//			} else {
				b = contentLoaderInfo.bytesLoaded;
//			}
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
			return "SWFZprite: '" + url.url + "'";
		}
		
		public function destroy():void {
			_destroy();
			unload();
//			unloadAndStop(true);
		}
		
		public function _destroy():void {
			ZadamCore.instance.log(this, "Destroying", 7);
			
			try {
				close();
			} catch (e:Error) {
				// no worries
			}
			
			Z.destroy();
			Z = null;

			delete ZadamCore.instance.zadamContexts[contentLoaderInfo];

			contentLoaderInfo.removeEventListener(Event.INIT, _onInit);
			contentLoaderInfo.removeEventListener(Event.COMPLETE, _onComplete);
			removeEventListener(IOErrorEvent.IO_ERROR, _onIOError);
			contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, _onIOError);
			contentLoaderInfo.removeEventListener(Event.UNLOAD, _onUnload);
			if (retryTimer) {
				retryTimer.removeEventListener(TimerEvent.TIMER, _onTimer);
			}
			
/*
			if (binaryLoader) {
				binaryLoader.removeEventListener(Event.COMPLETE, _onBinaryLoaderComplete);				
				binaryLoader.removeEventListener(IOErrorEvent.IO_ERROR, _onBinaryLoaderIoError);				
			}
*/
			
			ZadamCore.instance.destroyInstance(content);
			ZadamCore.instance.destroyInstance(this);
		}
		
		private function _onInit(e:Event):void {
			if (_referenceSet) {
				content.x = -referenceX;
				content.y = -referenceY;
			}
			ZadamCore.instance.createInstance(content);
			if (Z.autoReady) {
				Z.ready();
			}
		}
		
		private function _onComplete(e:Event):void {
			ZadamCore.instance.log(this, "Load complete", 5);
			Z._trigger("loadComplete");
		}

		private function _onIOError(e:Event):void {
			if (loadRetry) {
				ZadamCore.instance.log(this, "Load failure, will retry in " + retryTime + " seconds", 3);
				if (retryTimer == null) {
					retryTimer = new Timer(retryTime * 1000, 1);
					retryTimer.addEventListener(TimerEvent.TIMER, _onTimer);
				}
				retryTimer.start();
				Z._trigger("loadRetry");
			} else {
				ZadamCore.instance.log(this, "Load failure, will not retry", 3);
				Z._trigger("loadFailure");
			}
		}

		private function _onUnload(e:Event):void {
			destroy();
		}
		
		private function _onTimer(e:TimerEvent):void {
			ZadamCore.instance.log(this, "Retry loading", 5);			
			load(url, context);
		}

/*
		internal function _onBinaryLoaderComplete(event:Event):void
		{
			ZadamCore.instance.log(this, "Load complete", 5);
			loadBytes(binaryLoader.data, context);
		}
		
		private function _onBinaryLoaderIoError(e:Event):void {
			ZadamCore.instance.log(this, "Load failure", 3);
			Z._trigger("loadFailure");
		}
*/
				
	}
}