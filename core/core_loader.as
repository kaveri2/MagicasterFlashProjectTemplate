package  {
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.StageDisplayState;
	import flash.filters.*;
	import flash.geom.ColorTransform;
	import flash.text.TextFormat;
	import flash.text.TextField;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.net.URLRequest;
	import flash.media.Sound;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.text.Font;
	
	public class core_loader extends MovieClip {
		
		var Z:*;
				
		var pluginsReady:int = 0;
		var pluginsLoaded:Boolean = false;
		var pluginIndex:int;
		var currentlyLoadingPlugin:*;
		var plugins:Array;
		
		var animation:*;
		var animationComplete:Boolean;

		public function core_loader(_Z:*) {
		
			Z = _Z;

			var i:int;
			plugins = new Array();

			var extension:* = Z.createHat();
			Z.registerExtension("loader", extension);
			extension.container = this;
						
			Z.setLogTraceLevel(0 + Z.parameters.logTraceLevel);
			
			if ("" + Z.parameters.fullScreen == "true") {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			
			for (i=0 ; i < Z.parameters.assetURLRequestBuilder.length() ; i++) {
				function kikka() {
					var URLPrefix:String = Z.parameters.assetURLRequestBuilder[i].URLPrefix;
					var URLSuffix:String = Z.parameters.assetURLRequestBuilder[i].URLSuffix;
					var forceFLV:Boolean = Z.parameters.assetURLRequestBuilder[i].forceFLV == "true";
					Z.registerAssetURLRequestBuilder(Z.parameters.assetURLRequestBuilder[i].type, function(value:*) {
						if (forceFLV) {
							value = "" + value;
							value = value.split(".mp4").join(".mp4.flv");
							value = value.split(".m4v").join(".m4v.flv");
						}
						return new URLRequest(URLPrefix + value + URLSuffix);
					});
				}
				kikka();
			}

			for (i=0 ; i < Z.parameters.assetClassProvider.length() ; i++) {
				// TODO
			}

			if ("" + Z.parameters.animation != "") {
				animationComplete = false;
				animation = Z.create(Z.parameters.animation, {targetWidth: Z.targetWidth, targetHeight: Z.targetHeight});
				addChild(animation);
				animation.hat.progress = 0;
				animation.hat.bind("complete", function() {
					animationComplete = true;
				});
				animation.bind("ready", function() {
					startLoad();
				});
			} else {
				animationComplete = true;
				startLoad();
			}
		}
		
		function startLoad() {
			
			for (var i:int=0 ; i < Z.parameters.plugin.length() ; i++) {
				var xml:XML = Z.parameters.plugin[i];
				var p:* = Z.create(xml, {name: "plugin:" + pluginIndex, targetWidth: Z.targetWidth, targetHeight: Z.targetHeight});
				p.bind("ready", Z.wrap(function() {
					pluginsReady++;
					if (pluginsReady==Z.parameters.plugin.length()) {
						pluginsLoaded = true;
						if (animation) {
							animation.hat.trigger("loadComplete");
						}
					}
				}));
				plugins.push(p);
				addChild(p);
			}

			Z.bind("tick", tick);
			tick(0);
			
			Z.bind("targetSizeChange", Z.wrap(function() {
				if (animation) {
					animation.setTargetSize(Z.targetWidth, Z.targetHeight);
				}
				for (var i:* in plugins) {
					plugins[i].setTargetSize(Z.targetWidth, Z.targetHeight);
				}
			}));
		}

		function tick(time:Number) {
			
			if (animation) {
				var p:Number = 0;
				for (var i:int=0 ; i<plugins.length ; i++) {
					if (plugins[i].getBytesTotal()) {
						p = p + (plugins[i].getBytesLoaded() / plugins[i].getBytesTotal()) / plugins.length;
					}
				}
				animation.hat.trigger("loadProgress", p);
			}

			if (animationComplete && pluginsLoaded) {
				if (animation) {
					animation.destroy();
					removeChild(animation);
					animation = null;
				}
				Z.unbind("tick", tick);
				start();
			}
		}
		
		function start() {			
			for (var i:int=0 ; i<plugins.length ; i++) {
				plugins[i].hat.plugin();
			}
			Z.loader.trigger("start");
		}
		
	}
}

