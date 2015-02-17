package org.zadam
{

	import flash.events.EventDispatcher;
	import flash.display.MovieClip;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	public class ZadamContext extends Proxy
	{

		private static var _counter:int;
		private var _id:int = _counter++;

		private var _parent:ZadamContext;
		private var _parameters:*;
		internal var _hat:ZadamHat;

		internal var _children:Dictionary;
		private var _hats:Dictionary;
				
		private var _weakWrappers:Dictionary;
		private var _strongWrappers:Dictionary;
		private var _weakBinds:Array;
		private var _strongBinds:Array;
		
		private var _wrapperDestroyListeners:Dictionary;
		private var _eventListenerWrappers:Dictionary;

		private var _extensions:Array;
		private var _assetClassProviders:Array;
		private var _assetURLRequestBuilders:Array;

		private var _ready:Boolean = false;
		public var autoReady:Boolean = true;

		public var name:String;

		public var getBytesTotal:Function;
		public var getBytesLoaded:Function;

		internal var _targetWidth:Number;
		public function get targetWidth():Number
		{
			return _targetWidth;
		}
		internal var _targetHeight:Number;
		public function get targetHeight():Number
		{
			return _targetHeight;
		}

		public function ZadamContext(parent:ZadamContext, parameters:*, options:*)
		{
			_parent = parent;
			_parameters = parameters;

			_children = new Dictionary(true);
			
			_hats = new Dictionary(true);
			
			_weakWrappers = new Dictionary(true);
			_strongWrappers = new Dictionary(false);
			_weakBinds = new Array();
			_strongBinds = new Array();
			
			_wrapperDestroyListeners = new Dictionary(false);
			_eventListenerWrappers = new Dictionary(true);
			
			_extensions = new Array();
			_assetClassProviders = new Array();
			_assetURLRequestBuilders = new Array();

			if (options && options.name)
			{
				this.name = options.name;
			}

			if (options && options.hat)
			{
				_hat = options.hat;
			}
			else
			{
				_hat = createHat();
			}

			if (options)
			{
				if (options.targetWidth)
				{
					_targetWidth = options.targetWidth;
				}
				if (options.targetHeight)
				{
					_targetHeight = options.targetHeight;
				}
			}

			ZadamCore.instance.createInstance(this);
		}

		public function createChild(parameters:*, options:*):ZadamContext
		{
			var Z:ZadamContext = new ZadamContext(this, parameters, options);
			_children[Z] = true;
			return Z;
		}

		public function get binds():Array
		{
			var a1:Array = new Array();
			var a2:Array = new Array();
			var i:*;
			for (i in _weakBinds)
			{
				a1[i] = true;
			}
			for (i in _strongBinds)
			{
				a1[i] = true;
			}
			for (i in a1)
			{
				a2.push(i);
			}
			return a2;
		}

		public function bind(name:String, o:Object, weak:Boolean = false):void
		{
			if (name=="tick")
			{
				ZadamCore.instance.addTickZadamContext(this);
			}
			
			if (name=="ready" && _ready)
			{
				_call("ready", o, null);
			}
			
			if (o is ZadamWrapper)
			{
				var f:Function = function() {
					unbind(name, o, weak);
					delete _wrapperDestroyListeners[o];
				};
				o.addDestroyListener(f);
				_wrapperDestroyListeners[o] = f;
			}
			else if (o is Function)
			{
				if (weak) {
					ZadamCore.instance.log(this, "Potential weak reference bug in ZadamContext.bind('" + name + "')", 3);					
				} else {
					ZadamCore.instance.log(this, "Potential memory leak in ZadamContext.bind('" + name + "')", 3);
				}
			}
			else
			{
				return;
			}

			if (weak)
			{
				if (!_weakBinds[name])
				{
					_weakBinds[name] = new Dictionary(true);
				}
				_weakBinds[name][o] = true;
			}
			else
			{
				if (! _strongBinds[name])
				{
					_strongBinds[name] = new Dictionary(false);
				}
				_strongBinds[name][o] = true;
			}
		}

		public function unbind(name:String, o:Object, weak:Boolean = false):void
		{
			if (weak)
			{
				if (_weakBinds[name] && _weakBinds[name][o])
				{
					delete _weakBinds[name][o];
				}
			}
			else
			{
				if (_strongBinds[name] && _strongBinds[name][o])
				{
					delete _strongBinds[name][o];
				}
			}
		}

		private function _call(name:String, o:Object, args:Array):void
		{
			try
			{
				if (o is ZadamWrapper)
				{
					if (o.object) {
						o.object.apply(null, args);
					}
				}
				else if (o is Function)
				{
					o.apply(null, args);
				}
			}
			catch (e:Error)
			{
				ZadamCore.instance.log(this, "Caught exception triggering '" + name + "'!\n" + e.getStackTrace(), 2);
			}
		}

		internal function _trigger(name:String, ... args):void
		{			
			var i:*;
			if (_weakBinds[name])
			{
				for (i in _weakBinds[name])
				{
					if (i)
					{
						_call(name, i, args);
					}
				}
			}
			if (_strongBinds[name])
			{
				for (i in _strongBinds[name])
				{
					if (i)
					{
						_call(name, i, args);
					}
				}
			}
		}

		public function create(a:*, options:* = null):IZprite
		{
			a = new AssetDefinition(a);
			return ZadamCore.instance.createZprite(this, a, options);
		}

		public function ready():void
		{
			if (! _ready)
			{
				_ready = true;
				_trigger("ready");
			}
		}

		public function toString():String
		{
			return "ZadamContext: '" + (name ? name : "#" + _id) + "'";
		}

		public function buildAssetURLRequest(a:*):URLRequest
		{
			var ad:AssetDefinition = new AssetDefinition(a);

			ZadamCore.instance.log(this, "Building URLRequest for asset: " + ad, 7);

			var type:String = "" + ad.type;

			if (type=="url")
			{
				return new URLRequest(ad.value);
			}

			var builder:Function = findAssetURLRequestBuilder(type);
			if (builder != null)
			{
				return builder(ad.value);
			}

			return new URLRequest();
		}

		public function registerAssetClassProvider(type:String, provider:Function):void
		{
			_assetClassProviders[type] = provider;
		}

		public function findAssetClassProvider(type:String):Function
		{
			if (_assetClassProviders[type])
			{
				return _assetClassProviders[type];
			}
			if (_parent)
			{
				return _parent.findAssetClassProvider(type);
			}
			return undefined;
		}

		public function registerAssetURLRequestBuilder(type:String, builder:Function):void
		{
			_assetURLRequestBuilders[type] = builder;
		}

		public function findAssetURLRequestBuilder(type:String):Function
		{
			if (_assetURLRequestBuilders[type])
			{
				return _assetURLRequestBuilders[type];
			}
			if (_parent)
			{
				return _parent.findAssetURLRequestBuilder(type);
			}
			return undefined;
		}

		public function registerExtension(name:String, extension:Object):void
		{
			_extensions[name] = extension;
		}

		public function get id():int
		{
			return _id;
		}

		public function get parent():ZadamContext
		{
			return _parent;
		}

		public function get parameters():*
		{
			return _parameters;
		}

		public function get hat():ZadamHat
		{
			return _hat;
		}

		public function isWrapper(o:*):Boolean
		{
			return o is ZadamWrapper;
		}

		public function createWrapper(content:*, weak:Boolean = false):ZadamWrapper
		{
			var wrapper:ZadamWrapper = new ZadamWrapper(this,content);
			ZadamCore.instance.log(this, "Created " + wrapper, 7);
			if (weak) {
				_weakWrappers[wrapper] = true;			
			} else {
				_strongWrappers[wrapper] = true;
			}
			return wrapper;
		}

		public function wrapped(o:*):Boolean
		{
			return isWrapper(o);
		}

		public function wrap(content:*):ZadamWrapper
		{
			return createWrapper(content);
		}
		
		public function wrapEventListener(ed:EventDispatcher, type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false) {
			if (!_eventListenerWrappers[ed]) {
				_eventListenerWrappers[ed] = new Array();
			}
			var a:Array = new Array(type, listener, useCapture, priority, useWeakReference);
			_eventListenerWrappers[ed].push(a);
			ed.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		public function isHat(o:*):Boolean
		{
			return o is ZadamHat;
		}

		public function createHat(parent:ZadamHat = null):ZadamHat
		{
			var hat:ZadamHat = new ZadamHat(this, parent);
			ZadamCore.instance.log(this, "Created " + hat, 7);
			_hats[hat] = hat;
			return hat;
		}

		override flash_proxy function getProperty(name:*):*
		{
			if (_extensions[name])
			{
				return _extensions[name];
			}
			if (parent)
			{
				return parent[name];
			}
			return undefined;
		}

		override flash_proxy function setProperty(name:*, value:*):void
		{
			// not available
		}

		override flash_proxy function callProperty(name:*, ... args):*
		{
			// not available
			return undefined;
		}
				
		public function setLogTraceLevel(level:int):void {
			ZadamCore.instance.log(this, "Setting log's trace level to " + level, 1);
			ZadamCore.instance.logTraceLevel = level;
		}

		public function log(message:String, level:int = 7):void
		{
			ZadamCore.instance.log(this, message, level);
		}

		internal function destroy():void
		{
			ZadamCore.instance.log(this, "Destroying", 7);

			// let everyone know about the destruction;
			_trigger("destroy");

			var i:*, j:*;

			// 
			ZadamCore.instance.removeTickZadamContext(this);

			// destroy created children;
			for (i in _children)
			{
				i.destroy();
				delete _children[i];
			}
			_children = null;
			delete parent._children[this];

			// destroy created hats
			for (i in _hats)
			{
				i.destroy();
				delete _hats[i];
			}
			_hats = null;

			// destroy created wrappers
			for (i in _weakWrappers)
			{
				i.destroy();
				delete _weakWrappers[i];
			}
			_weakWrappers = null;
			for (i in _strongWrappers)
			{
				i.destroy();
				delete _strongWrappers[i];
			}
			_strongWrappers = null;
			
			for (i in _wrapperDestroyListeners)
			{
				i.removeDestroyListener(_wrapperDestroyListeners[i]);
				delete _wrapperDestroyListeners[i];
			}
			_wrapperDestroyListeners = null;
			 
			for (i in _eventListenerWrappers)
			{
				if (_eventListenerWrappers[i]) {
					for (j in _eventListenerWrappers[i]) {
						i.removeEventListener(
							_eventListenerWrappers[i][j][0], 
							_eventListenerWrappers[i][j][1],
							_eventListenerWrappers[i][j][2]
						);
					}
					delete _eventListenerWrappers[i][j];
				}
				delete _eventListenerWrappers[i];
			}
			_eventListenerWrappers = null;
			 
			// destroy references
			_parameters = null;
			_parent = null;
			_weakBinds = null;
			_strongBinds = null;

			_extensions = null;
			_assetClassProviders = null;
			_assetURLRequestBuilders = null;
			
			getBytesTotal = null;
			getBytesLoaded = null;

			ZadamCore.instance.destroyInstance(this);
		}

		public function getDebugInfo():String
		{
			return ZadamCore.instance.getDebugInfo();
		}
	}
}