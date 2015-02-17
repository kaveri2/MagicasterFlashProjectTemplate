package  {
	
	import flash.display.MovieClip;
	import flash.utils.setTimeout;
	import com.tweenman.Easing;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import com.adobe.images.JPGEncoder;
	import flash.net.FileReference;
	
	public class core_fs extends MovieClip {
		
		public function core_fs(Z:*) {

			Z.hat.plugin = function() {
				
				var extension:* = Z.createHat();
				Z.parent.registerExtension("fs", extension);
				
				Z.magicastInterface.saveFile = function(magicast_hat:*, parameters:XML) {
					
					if ("" + parameters.variable != "") {
						var v:* = magicast_hat.getVariable("" + parameters.variable);
						var fn:String = "" + parameters.filename;
						var jpegQuality:int = 85;
						if (v is BitmapData) {
							if (fn == "") {
								fn = "file.jpg";
							}
							var encoder:JPGEncoder = new JPGEncoder(jpegQuality);
							var byteArray:ByteArray = encoder.encode(v);
							var fileReference:FileReference = new FileReference();
							fileReference.save(byteArray, fn);
							
							/*
							var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
							var jpgURLRequest:URLRequest = new URLRequest(url + "?content-type=" + ct + "&filename=" + fn);
							jpgURLRequest.requestHeaders.push(header);
							jpgURLRequest.method = URLRequestMethod.POST;
							jpgURLRequest.data = jpgStream;
							navigateToURL(jpgURLRequest, "_blank");
							*/
						}
					}
					
				}
			};
		}
	}
}
