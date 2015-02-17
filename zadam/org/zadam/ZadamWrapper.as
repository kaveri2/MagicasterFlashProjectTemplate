package org.zadam
{

	import flash.events.Event;
	import flash.utils.Dictionary;

	public class ZadamWrapper
	{

		private static var _counter:int;
		private var _id:int = _counter++;

		private var _creator:ZadamContext;
		private var _object:Object;
		
		private var _destroyListeners:Dictionary;

		public function ZadamWrapper(creator:ZadamContext, object:Object)
		{
			_creator = creator;
			_object = object;
			_destroyListeners = new Dictionary(false);
		}

		public function get Z():ZadamContext
		{
			return _creator;
		}

		public function get object():Object
		{
			return _object;
		}
		
		public function addDestroyListener(f:Function):void {
			_destroyListeners[f] = true;
		}
		
		public function removeDestroyListener(f:Function):void {
			delete _destroyListeners[f];
		}

		public function toString():String
		{
			return "ZadamWrapper: '#" + _id + "' (created by " + Z + ")";
		}

		internal function destroy():void
		{
			ZadamCore.instance.log(this, "Destroying", 7);
			
			for (var i:* in _destroyListeners) {
				i.call();
				delete _destroyListeners[i];
			}
			_destroyListeners = null;

			_creator = null;
			_object = null;

			ZadamCore.instance.destroyInstance(this);
		}

	}
}