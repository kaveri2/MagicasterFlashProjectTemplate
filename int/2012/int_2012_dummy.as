package  {
	
	import flash.display.MovieClip;
	import flash.text.TextFieldAutoSize;
	import flash.events.MouseEvent;
		
	public class int_2012_dummy extends MovieClip {
		
		public function int_2012_dummy(Z:*) {
			
			text.text.text = "" + Z.parameters.text;
			text.text.autoSize = TextFieldAutoSize.LEFT;
			text.text.wordWrap = false;
			
			box.width = text.width + 40;
			box.height = text.height + 40;
			
			text.mouseEnabled = false;	
			text.text.mouseEnabled = false;	
			
			if ("" + Z.parameters.button == "true") {
				Z.wrapEventListener(box, MouseEvent.CLICK, function() {
					Z.hat.magicast_triggerEvent("click");	 
				});				
			} else {
				box.mouseEnabled = false;
			}

		}
	}
	
}
