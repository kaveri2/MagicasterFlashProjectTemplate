package  {
	
	import flash.system.System;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.setTimeout;
	
	public class core_zadamDebug extends MovieClip {
		
		public function core_zadamDebug(Z:*) {

			Z.hat.plugin = function() {
				var t:TextField = new TextField();
				addChild(t);
				t.type = TextFieldType.DYNAMIC;
				t.selectable = false;
				t.mouseEnabled = false;
				
				function doResize() {
					t.y = 50;
					t.width = Z.targetWidth;
					t.height = Z.targetHeight - 50;
				}
				
				Z.bind("targetSizeChange", doResize);
				doResize();
				
				Z.bind("tick", function(time:Number) {
					var s:String = Z.getDebugInfo();
					t.text = time + "\n" + s.length + "\n" + s;
				});
				
				function x() {
					Z.p2.closePopupMagicast();
//					Z.p2.openPopupMagicast(XMLList(<data><debug>false</debug><node><name>start</name><layer><name>loppukuva</name></layer></node></data>));
					Z.p2.openPopupMagicast(XMLList(
	<data>
<debug>false</debug>
<node>
	<name>start</name>
	<layer>
		<name>loppukuva</name>
		<asset>
			<type>ext</type>
			<value>2012/sekalaiset/ikonit/p2Logo.jpg</value>
			<parameters/>
		</asset>
	</layer>
	<layer>
		<name>vid</name>
		<asset>
			<type>int</type>
			<value>2012/video.swf</value>
			<parameters>
				<asset>
					<type>ext</type>
					<value>2012/sekalaiset/sisaltojuonnot/P2_Katsele_1.mp4</value>
					<parameters/>
				</asset>
			</parameters>
		</asset>
	</layer>
</node>

	</data>
	));
	/*
	*/
					System.gc();
					setTimeout(x, Math.random() * 5000);
				}
				x();
			};
		}	
	}
}
