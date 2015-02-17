package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
    import flash.events.*;
    import flash.geom.Rectangle;
    import flash.media.StageWebView;
    import flash.net.*;	
    import flash.geom.Point;
	
	public class int_2013_webView extends MovieClip 
	{
		public function int_2013_webView(Z:*) 
		{

			var THIS:* = this;
			
			var webView:StageWebView = new StageWebView();
			
			var readyTriggered:Boolean = false;
			var url:String = "" + Z.parameters.url;
			if (url) {
				Z.autoReady = false;
				webView.loadURL(url);
			} else {
				readyTriggered = true;
			}
			Z.wrapEventListener(webView, flash.events.Event.COMPLETE, function(e:Event) {
				if (!readyTriggered) {
					Z.ready();
					readyTriggered = true;
				}
				Z.hat.magicast_triggerEvent("complete");
			});
			Z.wrapEventListener(webView, flash.events.ErrorEvent.ERROR, function(e:Event) {
				Z.hat.magicast_triggerEvent("error");
			});
			Z.wrapEventListener(webView, flash.events.LocationChangeEvent.LOCATION_CHANGE, function(e:Event) {
				Z.hat.magicast_triggerEvent("locationChange");
			});
			Z.wrapEventListener(webView, flash.events.LocationChangeEvent.LOCATION_CHANGING, function(e:Event) {
				Z.hat.magicast_triggerEvent("locationChanging");
			});

			Z.hat.magicast_run = function() {
				webView.stage = THIS.stage;
			}
			
			Z.hat.magicast_runAction = function(method:String, parameters:XML) {
				if (method == "setUrl") {
					url = "" + parameters.url;
					webView.loadURL(url);
				}
				if (method == "reload") {
					webView.reload();
				}
				if (method == "back") {
					webView.historyBack();
				}
				if (method == "forward") {
					webView.historyForward();
				}
			};
			
			var renderedData:String = "";
			Z.hat.magicast_render = function() {
				var calculations:* = Z.hat.magicast_calculations;
				
				var p1:Point = THIS.localToGlobal(new Point(calculations.x, calculations.y));
				var p2:Point = THIS.localToGlobal(new Point(calculations.x + calculations.width, calculations.y + calculations.height));
				p2 = p2.subtract(p1);
				
				var data:String = p1.x + "." + p1.y + "." + p2.x + "." + p2.y;
				
				if (renderedData != data) {
					webView.viewPort = new Rectangle(p1.x, p1.y, p2.x, p2.y);
					renderedData = data;
				}
			}
			
			Z.bind("destroy", function() {
				webView.dispose();
			});
        }    
	}
}