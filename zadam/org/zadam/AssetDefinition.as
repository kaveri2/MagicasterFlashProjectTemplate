package org.zadam {

	import flash.net.URLRequest;

	public class AssetDefinition {
	
		public var type:String;
		public var value:XML;
		public var parameters:XML;
	
		public function AssetDefinition(a:*) {		
		
			if (a==null || a==undefined) {
				// error
			} else if (a is AssetDefinition) {
				type = a.type;
				value = a.value;
				parameters = a.parameters;
			} else if (a is XML || a is XMLList) {
				if (a is XMLList) {
					if (a.length()==1) {
						a = a[0];
					} else {
						a = XML("<asset>" + a.toXMLString() + "</asset>");
					}
				}
				if (a.type.length()>0) {
					type = a.type[0].text();
				}
				if (a.value.length()>0) {
					value =  a.value[0];
				}
				if (a.parameters.length()>0) {
					parameters = a.parameters[0];
				}
			} else if (a is String) {
				type = "url";
				value = XML("<value>" + a + "</value>");
			} else {
				if (a.type is String) {
					type = a.type;
				}
				if (a.value is String) {
					value = XML("<value>" + a.value + "</value>");
				}
				if (a.value is XML || a.value is XMLList) {
					value = XML("<value>" + a.value.toXMLString() + "</value>");
				}
				if (a.parameters is String) {
					parameters = XML("<parameters>" + a.parameters + "</parameters>");
				}
				if (a.parameters is XML || a.parameters is XMLList) {
					parameters = XML("<parameters>" + a.parameters.toXMLString() + "</parameters>");
				}
			}
			
		}		
		
		public function toString():String {
			return ("AssetDefinition: type=" + type + ", value=" + value + ", parameters=" + (parameters ? "" + parameters.toXMLString().length + " characters" : "null") + "");
		}
		
	}	
}
