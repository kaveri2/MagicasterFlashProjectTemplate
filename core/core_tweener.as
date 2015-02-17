package  {
	
	import flash.display.MovieClip;
	import flash.utils.setTimeout;
	import com.tweenman.Easing;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class core_tweener extends MovieClip {		
		
		public function core_tweener(Z:*) {
			Z.hat.plugin = function() {
			
				var extension:* = Z.createHat();
				Z.parent.registerExtension("tweener", extension);
				
				var tweens:Array = new Array();
				var onMotionFinishes:Array = new Array();
				
				extension.stop = function(obj:*, props:*) {
					var i:int;
					var j:*;
					var t:Tween;
					// handle properties always as array 
					if (!props) {
						for (j in tweens) {
							if (tweens[j].obj==obj) {
								tweens[j].removeEventListener(TweenEvent.MOTION_FINISH, onMotionFinishes[j]);
								tweens[j].stop();
								delete tweens[j];
								delete onMotionFinishes[j];
							}
						}
					} else {
						if (!(props is Array)) {
							props = new Array(props);
						}
						for (i=0 ; i<props.length ; i++) {
							var prop = props[i];
							for (j in tweens) {
								if (tweens[j].obj==obj && tweens[j].prop==prop) {
									tweens[j].removeEventListener(TweenEvent.MOTION_FINISH, onMotionFinishes[j]);
									tweens[j].stop();
									delete tweens[j];
									delete onMotionFinishes[j];
								}
							}
						}
					}
				};
				
				extension.start = function(obj:*, props:*, vals:*, time:Number, func:* = null, startTime:Number = 0, callback:Object = null) {
					
					var a:Array = new Array();
					var i:*;
					
					// handle properties always as array 
					if (!(props is Array)) {
						props = new Array(props);
					}
					for (i=0 ; i<props.length ; i++) {
						var prop = props[i];
						
						// find the corresponding value			
						var val;
						if (vals is Array) {
							val = vals[i];
						} else {
							val = vals;
						}
						// figure out the easing function
						var f:Function = null;
						if (func is Function) {
							f = func;
						} else if (func is String) {
							f = Easing[func];
						}
						// create tween
						var index:int = tweens.length;
						tweens[index] = new Tween(obj, prop, f, obj[prop], val, time, true);
						onMotionFinishes[index] = function(e:Event) {
							if (tweens[index]) {
								tweens[index].removeEventListener(TweenEvent.MOTION_FINISH, onMotionFinishes[index]);
								delete tweens[index];
								delete onMotionFinishes[index];
								if (callback!=null) {
									try {
										if (Z.wrapped(callback)) {
											if (callback.object) {
												callback.object.call(null);
											}
										} else if (callback is Function) {
											callback.call(null);
										}
									} catch (e) {
										Z.log("Caught exception executing tween callback!\n" + e.getStackTrace(), 2);				
									}
									callback = null;
								}
							}
						}
						tweens[index].addEventListener(TweenEvent.MOTION_FINISH, onMotionFinishes[index]);
						tweens[index].stop();
						a.push(index);
					}
					
					var timer:Timer;
					if (startTime) {
						timer = new Timer(startTime * 1000, 1);
						timer.addEventListener(TimerEvent.TIMER_COMPLETE, run);
						timer.start();
					} else {
						run();
					}
					
					function run() {
						for (var i:* in a) {
							if (tweens[a[i]]) {
								tweens[a[i]].resume();
							}
						}
						if (timer) {
							timer.removeEventListener(TimerEvent.TIMER_COMPLETE, run);
							timer = null;
						}
					}
					
					var retA:Array = new Array();
					for (i in a) {
						if (tweens[a[i]]) {
							retA.push(tweens[a[i]]);
						}
					}
					if (retA.length>1) {
						return retA;
					} else if (retA.length>0) {
						return tweens[a[0]];
					} else {
						return null;
					}
				};
			};
		}
	}
}
