package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.events.MouseEvent;	
	import flash.display.Bitmap;
	
	public class core_example_foreground extends MovieClip {
		
		public function core_example_foreground(Z:*) {
			
			pathName.visible = false;
			closeButton.visible = false;
			pathName.text.text = "";
			
			Z.wrapEventListener(closeButton, MouseEvent.CLICK, function(e:*) {
				Z.mahti.changePath("");
			});
			
			Z.mahti.bind("pathChange", Z.wrap(function() {
				pathName.visible = false;
				closeButton.visible = false;
				if (Z.mahti.path.id) {
					if ("" + Z.mahti.path.data.name != "") {
						closeButton.visible = true;
						pathName.visible = true;
						pathName.text.text = "" + Z.mahti.path.data.name;
					}
				}
			}));
			
		}
		
	}
	
}
