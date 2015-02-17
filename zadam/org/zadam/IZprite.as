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
	
	internal interface IZprite {
		
		function get hat():ZadamHat;
		
		function get targetWidth():Number;
		function get targetHeight():Number;
		function setTargetSize(w:Number, h:Number):void;

		function get referenceX():Number;
		function get referenceY():Number;
		function setReferencePoint(x:Number, y:Number):void;
		
		function getBytesTotal():int;
		function getBytesLoaded():int;

		function bind(... args):void;
		function unbind(... args):void;
		
		function destroy():void;
		
	}
}