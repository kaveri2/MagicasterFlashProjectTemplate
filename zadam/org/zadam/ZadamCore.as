package org.zadam {

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.LocalConnection;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	public class ZadamCore {
	
		public static const VERSION:String = "0.7";
		
		public var logTraceLevel:int = 7;
	
		public static var instance:ZadamCore;
	
		public var zadamContexts:Dictionary;
		
		private var tickZadamContexts:Dictionary;
		private var logZadamContexts:Dictionary;
		
		public var allInstances:Dictionary;
		public var destroyedInstances:Dictionary;
		
		private var applicationDomain:ApplicationDomain;
		
		public static function intialize(root:DisplayObject):void {
			instance = new ZadamCore();
			root.addEventListener(Event.ENTER_FRAME, function():void {
				instance.tick();
			});
		}

		public function ZadamCore() {
			zadamContexts = new Dictionary(true);
			tickZadamContexts = new Dictionary(true);
			logZadamContexts = new Dictionary(true);
			
			allInstances = new Dictionary(true);
			destroyedInstances = new Dictionary(true);
			
			applicationDomain = ApplicationDomain.currentDomain;
			
			var sprite:Object = applicationDomain.getDefinition("flash.display.Sprite");
			sprite.prototype.ZADAM = function(parent:ZadamContext = undefined):ZadamContext {
				log(this, "ZADAM(" + this + " / " + getQualifiedClassName(this) + ")", 6);
				return zadamContexts[this["loaderInfo"]];
			};			
        }
		
		public function getApplicationDomain():ApplicationDomain {
			return applicationDomain;
		}		
		
		internal function createZprite(parent:ZadamContext, a:AssetDefinition, options:* = null):IZprite {

			ZadamCore.instance.log(this, "createZprite", 7);

			if (a.type=="class") {
				return new ClassZprite(parent, applicationDomain.getDefinition(a.value) as Class, a.parameters, options);				
			} else {
				var provider:Function = parent.findAssetClassProvider(a.type);
				if (provider != null) {
					var c:Class = provider(a.value);
					if (c) {
						return new ClassZprite(parent, c, a.parameters, options);
					}
				}
				var url:URLRequest = parent.buildAssetURLRequest(a);
				return new SWFZprite(parent, url, a.parameters, options);
			}
		}

		public function log(source:Object, message:String, level:int):void {
			var i:*;
			if (level<=logTraceLevel) {
				trace(level + ": " + source + " --> " + message);
			}
			for (i in logZadamContexts) {
				i._trigger("log", source, level, message);
			}			
		}
				
		public function getDebugInfo():String {
			var i:*;
			var s:String;
			var tmp:String;
			
			s = "ZadamCore.getDebugInfo()" + "\n";
			
			tmp = "";
			for (i in destroyedInstances) {
				tmp += i + " (" + destroyedInstances[i] + " ticks)\n";
			}
			if (tmp!="") {
				s += "Destroyed instances:\n";
				s += "--------------------\n";
				s += tmp;
			}			

			return s;			
		}		
		
		private var lastTime:int;

		public function tick():void {
			var i:*;
			
			var newTime:Number = getTimer();
			var tickTime:Number = (newTime - lastTime) / 1000;
			lastTime = newTime;
			
			for (i in tickZadamContexts) {
				i._trigger("tick", tickTime);
			}
			
			// GARBAGE COLLECTION
			for (i in destroyedInstances) {
				destroyedInstances[i] = destroyedInstances[i] + 1;
			}
		}
		
		internal function addTickZadamContext(Z:ZadamContext):void {
			tickZadamContexts[Z] = true;
		}
	
		internal function removeTickZadamContext(Z:ZadamContext):void {
			delete tickZadamContexts[Z];
		}
	
		internal function createInstance(o:Object):void {
			allInstances[o] = 0;
		}

		internal function destroyInstance(o:Object):void {
			destroyedInstances[o] = allInstances[o];
			delete allInstances[o];
		}

	}
}