package  {
	
	import flash.net.URLRequest;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class core_textFormatter extends MovieClip {
		
		public function core_textFormatter(Z:*) {
			Z.hat.plugin = function() {
			
				var extension:* = Z.createHat();
				Z.parent.registerExtension("textFormatter", extension);

				extension.createTextField = function(format:XML = null) {
					
					var t:TextField = new TextField();
					t.selectable = false;
					t.multiline = true;
					
					if (format==null) {
						format = new XML("<format></format>");
					}

					var presetFormat:XML = new XML("<format></format>");
					var preset:String = "" + format.preset;
					for (var i:int=0 ; i<Z.parameters.format.length() ; i++) {
						if ("" + Z.parameters.format[i].preset == preset) {
							presetFormat = Z.parameters.format[i];
						}
					}

					function getParameter(name) {
						if ("" + format[name] != "") {
							return format[name];
						}
						return presetFormat[name];
					}
					
					var tf:TextFormat;
					if (getParameter("font") && builders["" + getParameter("font")]) {
						tf = builders["" + getParameter("font")].call(null);
						if (tf) {
							t.embedFonts = true;
						} else {
							tf = new TextFormat();
						}
					} else {
						tf = new TextFormat();
					}
					
					if (getParameter("size")) {
						tf.size = parseFloat("" + getParameter("size"));
					}
					if (getParameter("leading")) {
						tf.leading = parseFloat("" + getParameter("leading"));
					}
					if (getParameter("color")) {
						tf.color = parseInt("" + getParameter("color"));
					}
					
					t.defaultTextFormat = tf;

					return t;
				};
	
				var builders:Array = new Array();
				extension.registerTextFormatBuilder = function(font:String, f:Function) {
					builders[font] = f;
				};
				
			};
		}
	}
	
}
