package  {
	
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	
	
	public class int_2012_languageManager extends MovieClip {
		
		
		public function int_2012_languageManager(Z:*) {

			Z.parent.registerAssetURLRequestBuilder("languageManager", function() {
													
			});

			var extension:* = Z.createHat();
			Z.parent.registerExtension("languageManager", extension);
			
			var playId:String;
			var playLanguage:String;
			var playText:String;
			var playAssetUrlRequest:URLRequest;
			
			var sc:SoundChannel;
			var s:Sound;			
			var i:int;
			
			var languages:Array = new Array();
			
			for (i = 0 ; i < Z.parameters.language.length() ; i++) {
				var language = Z.parameters.language[i];
				languages[0 + language.priotity] = "" + language.name;
			}
			
			var items:Array = new Array();
			
			for (i = 0 ; i < Z.parameters.item.length() ; i++) {
				var item = Z.parameters.item[i];
				if (!items["" + item.id]) {
					items["" + item.id] = new Array();
				}
				items["" + item.id]["" + item.language] = item;
//				trace("" + item.id + " kielellä " + item.language + " lisätty");
			}
			
			Z.hat.magicast_runAction = function(name:String, parameters:XML) {
				if (name=="enqueue") {
					extension.enqueue("" + parameters.id, 0 + parameters.priority, "" + parameters.language);
				}
				if (name=="enqueueAudio") {
					extension.enqueueAudio("" + parameters.id, 0 + parameters.priority, "" + parameters.language);
				}
				if (name=="enqueueVideo") {
					extension.enqueueVideo("" + parameters.id, 0 + parameters.priority, "" + parameters.language);
				}
				if (name=="play") {
					extension.play("" + parameters.id, 0 + parameters.priority, "" + parameters.language);
				}
				if (name=="playAudio") {
					extension.playAudio("" + parameters.id, 0 + parameters.priority, "" + parameters.language);
				}
				if (name=="playVideo") {
					extension.playVideo("" + parameters.id, 0 + parameters.priority, "" + parameters.language);
				}
				if (name=="setLanguage") {
					extension.setLanguage("" + parameters.name, 0 + parameters.priority);
				}
			};
			
			var queue:Array = new Array();
			
			extension.enqueue = function(id:String, priority:int = 0, language:String = ""):void {
				queue.push({type: "all", id: id, priority: priority, language: language});
			}
			extension.enqueueAudio = function(id:String, priority:int = 0, language:String = ""):void {
				queue.push({type: "audio", id: id, priority: priority, language: language});
			};
			extension.enqueueVideo = function(id:String, priority:int = 0, language:String = ""):void {
				queue.push({type: "video", id: id, priority: priority, language: language});
			};
			
			var currentItem:*;
			
			extension.skip = function():void {
				
				if (sc) {
					Z.hat.magicast_triggerEvent("audioStop", currentItem);
					extension.trigger("audioStop", currentItem);
					sc.stop();
					sc = null;
				}
				
				var element = queue.shift();
				if (element) {
//					trace("soitetaan " + element.id + " prioriteetillä " + element.priority + "");
					if (element.type=="all" || element.type=="audio") {
						var language:String;
						if (element.language != "") language = element.language;
						else language = languages[element.priority];
//						trace("eli kielellä " + language + "");
						if (items[element.id] && items[element.id][language]) {
//							trace("joka löytyi");
							var item = items[element.id][language];
							currentItem = item;
//							trace("eli mp3 " + item.audioAsset);
							s = new Sound();
							Z.wrapEventListener(s, IOErrorEvent.IO_ERROR, function(e:Event) {
								extension.skip();
							});
							Z.wrapEventListener(s, Event.COMPLETE, function(e:Event) {
								// asynchronous check
								if (item==currentItem) {
//									trace("ALKAA: " + item);
									Z.hat.magicast_triggerEvent("audioStart", item);
									extension.trigger("audioStart", item);
									sc = s.play();
									Z.wrapEventListener(sc, Event.SOUND_COMPLETE, function(e:Event) {
//										trace("LOPPUI: " + item);
										sc = null;
										Z.hat.magicast_triggerEvent("audioComplete", item);
										extension.trigger("audioComplete", item);
										extension.skip();
									});
								}
							});
							s.load(Z.buildAssetURLRequest(item.audioAsset[0]));
						} else {
//							trace("joka ei löytynyt");
							extension.skip();
						}
					}
					if (element.type=="all" || element.type=="video") {
					}
				}
			}
			
			extension.stop = function():void {
				queue = new Array();
				extension.skip();
			}
			extension.play = function(id:String, priority:int = 0, language:String = ""):void {
				queue = new Array();
				queue.push({type: "all", id: id, priority: priority, language: language});
				extension.skip();
			}
			extension.playAudio = function(id:String, priority:int = 0, language:String = ""):void {
				queue = new Array();
				queue.push({type: "audio", id: id, priority: priority, language: language});
				extension.skip();
			}
			extension.playVideo = function(id:String, priority:int = 0, language:String = ""):void {
				queue = new Array();
				queue.push({type: "video", id: id, priority: priority, language: language});
				extension.skip();
			};
			
			extension.getAudioAsset = function(id:String, priority:int = 0, language:String = ""):* {
				return null;
			};
			extension.getVideoAsset = function(id:String, priority:int = 0, language:String = ""):* {
				return null;
			};
			extension.getAsset = function(id:String, priority:int = 0, language:String = ""):* {
				return null;
			};
			extension.getText = function(id:String, priority:int = 0, language:String = ""):String {
				if (!language) language = languages[priority];
				if (items[id] && items[id][language]) {
					return "" + items[id][language].text;
				}
				return "";
			};
			
			extension.setLanguage = function(language:String, priority:int = 0) {
				languages[priority] = language;
			};
			
			Z.bind("destroy", Z.wrap(function() {
				if (sc) {
					sc.stop();
				}
				s = null;
				sc = null;
				currentItem = null;
			}));

		}
	}
	
}
