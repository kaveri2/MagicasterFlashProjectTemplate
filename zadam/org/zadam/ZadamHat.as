package org.zadam
{

	import flash.utils.flash_proxy;
	import flash.utils.Proxy;
	import flash.utils.Dictionary;

	public class ZadamHat extends Proxy
	{

		private static var _counter:int;
		private var _id:int = _counter++;

		private var _wrapperDestroyListeners:Dictionary;

		private var _weakBinds:Array;
		private var _strongBinds:Array;
		private var _childBinds:Array;
		
		private var _properties:Array;

		private var _creator:ZadamContext;
		private var _parent:ZadamHat;

		public function ZadamHat(creator:ZadamContext, parent:ZadamHat = null)
		{
			_creator = creator;
			_parent = parent;
			
			_wrapperDestroyListeners = new Dictionary(false);

			_weakBinds = new Array();
			_strongBinds = new Array();
			_childBinds = new Array();
			
			_properties = new Array();

			ZadamCore.instance.createInstance(this);
		}
		
		public function get Z():ZadamContext
		{
			return _creator;
		}		

		internal function _childBind(child:ZadamHat, name:String):void
		{
			if (! _childBinds[name])
			{
				_childBinds[name] = new Dictionary(true);
			}

			_childBinds[name][child] = true;

			if (_parent)
			{
				_parent._childBind(child, name);
			}
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
			for (i in _childBinds)
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
				if (!weak)
				{
					ZadamCore.instance.log(this, "Potential memory leak in ZadamContext.bind('" + name + "')", 3);
				}
			}
			else
			{
				return;
			}

			if (weak)
			{
				if (! _weakBinds[name])
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

			if (_parent)
			{
				_parent._childBind(this, name);
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

		internal function _childTrigger(name:String, args:Array):void
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
			if (_childBinds[name])
			{
				for (i in _childBinds[name])
				{
					if (i)
					{
						i._childTrigger(name, args);
					}
				}
			}
		}

		public function trigger(name:String, ... args):void
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
			if (_childBinds[name])
			{
				for (i in _childBinds[name])
				{
					if (i)
					{
						i._childTrigger(name, args);
					}
				}
			}
		}

		override flash_proxy function getProperty(name:*):*
		{
			var v:* = _properties[name];
			if (! v && _parent)
			{
				v = _parent[name];
			}
			return v;
		}

		override flash_proxy function setProperty(name:*, value:*):void
		{
			_properties[name] = value;
		}

		override flash_proxy function hasProperty(name:*):Boolean
		{
			return _properties[name] != null;
		}

		override flash_proxy function callProperty(name:*, ... args):*
		{
			var v:* = _properties[name];
			if (! v && _parent)
			{
				v = _parent[name];
			}
			if (v)
			{
				try
				{
					return v.apply(null, args);
				}
				catch (e:Error)
				{
					ZadamCore.instance.log(this, "Caught exception calling '" + name + "'!\n" + e.getStackTrace(), 2);
				}
			}
			return undefined;
		}

		public function toString():String
		{
			return "ZadamHat: '#" + _id + "' (created by " + Z + ")";
		}

		internal function destroy():void
		{	
			ZadamCore.instance.log(this, "Destroying", 7);

			var i:*;
			for (i in _wrapperDestroyListeners)
			{
				i.removeDestroyListener(_wrapperDestroyListeners[i]);
				delete _wrapperDestroyListeners[i];
			}
			_wrapperDestroyListeners = null;

			_weakBinds = null;
			_strongBinds = null;
			_properties = null;

			_childBinds = null;

			_creator = null;
			_parent = null;

			ZadamCore.instance.destroyInstance(this);

		}

	}
}