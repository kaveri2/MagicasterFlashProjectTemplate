package  {
	
	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;	
	import flash.events.Event;	
	import flash.events.IOErrorEvent;	
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	import flash.utils.clearInterval;
	import flash.events.ProgressEvent;
	
	public class core_serverConnection extends MovieClip {
				
		public function core_serverConnection(Z:*) {
			Z.hat.plugin = function() {
				var callbacks:Array = new Array();
				
				var HTTPUrl:String = Z.parameters.HTTPUrl;
				
				var callInterval:Number = "" + Z.parameters.callInterval != "" ? parseFloat(Z.parameters.callInterval) : 100;
				var callIntervalId:int = 0;
				var retryInterval:Number = "" + Z.parameters.retryInterval != "" ? parseFloat(Z.parameters.retryInterval) : 5000;
				var failureInterval:Number = "" + Z.parameters.failureInterval != "" ? parseFloat(Z.parameters.failureInterval) : 5000;
				
				var useSocket:Boolean = false;
				
				var sessionKey:String = "";
				
				var callQueue:Array = new Array();
				
				var retrying:int = 0;
				
				var extension:* = Z.createHat();
				Z.parent.registerExtension("serverConnection", extension);
				
				extension.loadRetrying = false;

				extension.callMethod = function(name:String, parameters:* = null, success:* = null, failure:* = null, progress:* = null) {	
					callMethodDelayed(name, parameters, success, failure, progress);
					
					// do not make requests before receiving sessionKey
					if (sessionKey != "" && !callIntervalId) {
						callIntervalId = setInterval(parseCallQueue, callInterval);
					}
				}
	
				extension.callMethodDelayed = function(name:String, parameters:* = null, success:* = null, failure:* = null, progress:* = null) {	
					callMethodDelayed(name, parameters, success, failure, progress);
				}
	
				function callMethodDelayed(name:String, parameters:*, success:*, failure:*, progress:*) {
					var id:Number = callbacks.push({success: success, failure: failure, progress: progress}) - 1;
					callQueue.push({name: name, parameters: parameters, callbackId: id});
				}
				
				function parseCallQueue() {

					if (callIntervalId) {
						clearInterval(callIntervalId);
						callIntervalId = 0;
					}
					
					if (useSocket) {
						
						// TODO!!!
						
					} else {
				
						var retryIntervalId:int = 0;
						var i:int;
						var callIds:Array = new Array();
						
						// request to be sent
						var request:XML = <request></request>;
						request.appendChild(XML("<sessionKey>" + sessionKey + "</sessionKey>"));
						
						// only do methodCalls if sessionKey is set
						if (sessionKey) {
							var s:String = "";						
							for (i=0 ; i<callQueue.length ; i++) {
								s = s + "'" + callQueue[i].name + "', ";
								var methodCall:XML = 
									<methodCall></methodCall>;
								methodCall.@name = callQueue[i].name;
								methodCall.@id = callQueue[i].callbackId;
								if (callQueue[i].parameters) {
									methodCall.appendChild(callQueue[i].parameters);
								}
								request.appendChild(methodCall);
								
								callIds.push(callQueue[i].callbackId);
							}
							s = s.substr(0, s.length - 2);
							Z.log("serverConnection request: " + s + " = " + request.toXMLString().length + " bytes", 5);
							Z.log(request.toXMLString(), 7);

							callQueue = new Array();
						}
						
						var loader:URLLoader = new URLLoader();
						var ur:URLRequest = new URLRequest();
						ur.url = HTTPUrl;
						ur.method = "POST";
						ur.data = request.toXMLString();
						loader.load(ur);

						loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
						function onProgress(event:ProgressEvent) {
							for (i=0 ; i<callIds.length ; i++)  {
								if (callbacks[callIds[i]]) {
									var progress:* = callbacks[callIds[i]].progress;
									try {
										if (Z.wrapped(progress)) {
											if (progress.object) {
												progress.object.call(null, event.bytesLoaded, event.bytesTotal, attempts);
											}
										} else if (progress is Function) {
											progress.call(null, event.bytesLoaded, event.bytesTotal, attempts);
										}
									} catch (e) {
										Z.log("Caught exception executing methodCall progress callback '#" + callIds[i] + "'!\n" + e.getStackTrace(), 2);
									}
								}
							}
						}
						var attempts:int = 0;
						loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
						function onIOError(event:IOErrorEvent) {
							extension.trigger("loadFailure");
							if (retryInterval) {
								extension.trigger("loadRetry");
								if (attempts==0) {
									if (retrying==0) {
										extension.loadRetrying = true;
										extension.trigger("loadRetryingStart");
									}
									retrying++;
								}
								attempts++;
								Z.log("serverConnection IO error " + attempts + ", trying again...", 4);
								retryIntervalId = setInterval(function() {
										clearInterval(retryIntervalId);
										loader.load(ur);
									}, retryInterval);
								for (i=0 ; i<callIds.length ; i++)  {
									if (callbacks[callIds[i]]) {
										var progress:* = callbacks[callIds[i]].progress;
										try {
											if (Z.wrapped(progress)) {
												if (progress.object) {
													progress.object.call(null, 0, 0, attempts);
												}
											} else if (progress is Function) {
												progress.call(null, 0, 0, attempts);
											}
										} catch (e) {
											Z.log("Caught exception executing methodCall progress callback '#" + callIds[i] + "'!\n" + e.getStackTrace(), 2);
										}
									}
								}
							} else {
								Z.log("serverConnection IO error, not trying again", 2);
								setTimeout(function() {
									for (i=0 ; i<callIds.length ; i++)  {
										if (callbacks[callIds[i]]) {
											var failure:* = callbacks[callIds[i]].failure;
											try {
												if (Z.wrapped(failure)) {
													if (failure.object) {
														failure.object.call(null);
													}
												} else if (failure is Function) {
													failure.call(null);
												}
											} catch (e) {
												Z.log("Caught exception executing methodCall failure callback '#" + callIds[i] + "'!\n" + e.getStackTrace(), 2);
											}
											delete callbacks[callIds[i]];
										}
									}
								}, failureInterval);
							}
						}
						loader.addEventListener(Event.COMPLETE, onComplete);
						function onComplete(event:Event) {
							Z.log("serverConnection response: " + s + " = " + loader.data.length + " bytes", 5);
							Z.log(loader.data, 7);
														
							try {
								var xml:XML = new XML(loader.data);
								parseXML(xml);
							} catch (e:Error) {
								extension.trigger("parseError");								
								Z.log("serverConnection XML parse error!\n" + e.getStackTrace(), 3);
							}
							setTimeout(function() {
								for (i=0 ; i<callIds.length ; i++)  {
									if (callbacks[callIds[i]]) {
										Z.log("serverConnection methodReturn '#" + callIds[i] + "' missing!\n", 3);
										var failure:* = callbacks[callIds[i]].failure;
										try {
											if (Z.wrapped(failure)) {
												if (failure.object) {
													failure.object.call(null);
												}
											} else if (failure is Function) {
												failure.call(null);
											}
										} catch (e) {
											Z.log("Caught exception executing methodCall failure callback '#" + callIds[i] + "'!\n" + e.getStackTrace(), 2);
										}
										delete callbacks[callIds[i]];
									}
								}
							}, failureInterval);
							loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
							loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
							loader.removeEventListener(Event.COMPLETE, onComplete);
							loader = null;
							
							if (attempts > 0) {
								retrying--;
								if (retrying==0) {
									extension.loadRetrying = false;
									extension.trigger("loadRetryingStop");
								}
							}
							
							// attempt to get the first sessionKey failed, keep on trying...
							if (sessionKey == "") {
								callIntervalId = setInterval(parseCallQueue, failureInterval);
							}
						}							
					}
				}
				
				function parseXML(xml:XML) {
							
					var i:int;
					
					for (i=0 ; i<xml.children().length() ; i++) {
						
						var child:XML = xml.children()[i];
								
						switch (String(child.name()).toUpperCase()) {
							
							//
							case "SESSIONKEY":
							if (sessionKey != "") {
								extension.trigger("sessionExpire");
							}
							sessionKey = "" + child;
							
							// now we have sessionKey -> see if there are calls waiting
							if (callQueue.length && !callIntervalId) {
								callIntervalId = setInterval(parseCallQueue, callInterval);
							}
							break;
										
							//
							case "EVENT":
							extension.trigger(child.@name, child);
							break;
							
							//
							case "METHODRETURN":							
							var id:int = child.@id;
							var success:* = callbacks[id].success;
							if (success) {
								try {
									if (Z.wrapped(success)) {
										if (success.object) {
											success.object.call(null, child);
										}
									} else if (success is Function) {
										success.call(null, child);
									}
								} catch (e) {
									Z.log("Caught exception executing methodCall success callback '#" + id + "'!\n" + e.getStackTrace(), 2);				
								}
							}
							delete callbacks[id];
							
							break;
						}
					}		
				}
				
				// send empty request to get sessionKey
				callIntervalId = setInterval(parseCallQueue, callInterval);
			};
		}
	}	
}
