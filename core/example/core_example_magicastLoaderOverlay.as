package  {
	
	import flash.display.MovieClip;
	
	public class core_example_magicastLoaderOverlay extends MovieClip {
		
		public function core_example_magicastLoaderOverlay(Z:*) {

			var appearTime:Number = 0.5;
			var appearWaitTime:Number = 1.5;
			var disappearTime:Number = 0.25;

			if (Z.hat.loading) {
				dim.visible = true;
				dim.alpha = 0;
				Z.tweener.start(dim, "alpha", 0.8, appearTime, undefined, 0);
				animation.visible = true;
				animation.alpha = 0;
				Z.tweener.start(animation, "alpha", 1, appearTime, undefined, 0);			
			} else {
				dim.visible = false;
				animation.visible = false;
			}
			Z.hat.bind("loadStart", Z.wrap(function() {
				dim.visible = true;
				Z.tweener.stop(dim, "alpha");
				Z.tweener.start(dim, "alpha", 0.8, appearTime, undefined, appearWaitTime);
				animation.visible = true;
				Z.tweener.stop(animation, "alpha");
				Z.tweener.start(animation, "alpha", 1, appearTime, undefined, appearWaitTime);
			}));
			Z.hat.bind("loadProgress", Z.wrap(function(p:Number) {
			}));
			Z.hat.bind("loadComplete", Z.wrap(function() {
				Z.tweener.stop(dim, "alpha");
				Z.tweener.start(dim, "alpha", 0, disappearTime, undefined, 0, function() {
					dim.visible = false;
				});
				Z.tweener.stop(animation, "alpha");
				Z.tweener.start(animation, "alpha", 0, disappearTime, undefined, 0, function() {
					animation.visible = false;
				});
			}));
		
			if (Z.serverConnection.loadRetrying) {
			} else {
			}
			Z.serverConnection.bind("loadRetryingStart", Z.wrap(function() {
			}));
			Z.serverConnection.bind("loadRetryingStop", Z.wrap(function() {
			}));
			
			Z.bind("targetSizeChange", Z.wrap(function() {
				doResize();   
			}));
			function doResize() {
				dim.width = Z.targetWidth;
				dim.height = Z.targetHeight;
				animation.x = Z.targetWidth / 2;
				animation.y = Z.targetHeight / 2;
			}
			doResize();
			
		}
	}
	
}
