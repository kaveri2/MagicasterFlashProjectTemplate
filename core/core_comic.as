package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import com.gskinner.utils.Rndm;
	
	public class core_comic extends MovieClip {

		public function core_comic(Z:*) {

			Z.hat.plugin = function() {
			
				var extension:* = Z.createHat();
				Z.parent.registerExtension("comic", extension);

				extension.drawLine = function(s:Sprite, points:Array, format:XML = undefined, progressStart:Number = 0, progressEnd:Number = 1) {

					var i:int, j:int;
					var tmp:Number;

					var closed:Boolean = false;
					
					/*
					if (closed===undefined) {
						closed = points[0].subtract(points[points.length - 1]).length==0;
					}
					*/

					if (format==null) {
						format = new XML("<format></format>");
					}

					var presetFormat:XML = new XML("<format></format>");
					var preset:String = "" + format.preset;
					for (i=0 ; i<Z.parameters.lineFormat.length() ; i++) {
						if ("" + Z.parameters.lineFormat[i].preset == preset) {
							presetFormat = Z.parameters.lineFormat[i];
						}
					}

					function getParameter(name) {
						if ("" + format[name] != "") {
							return format[name];
						}
						return presetFormat[name];
					}
					
					var randomSeed:uint = Math.random() * uint.MAX_VALUE;
					if (getParameter("randomSeed")) {
						randomSeed = parseInt("" + getParameter("randomSeed"));
					}
					var color:uint = 0;
					if (getParameter("color")) {
						color = parseInt("" + getParameter("color"));							
					}
					var alpha:Number = 1;
					if (getParameter("alpha")) {
						alpha = parseFloat("" + getParameter("alpha"));
					}
					var edgeWidth:Number = 0;
					if (getParameter("edgeWidth")) {
						edgeWidth = parseInt("" + getParameter("edgeWidth"));
					}					
					var edgeColor:uint = 0;
					if (getParameter("edgeColor")) {
						edgeColor = parseInt("" + getParameter("edgeColor"));
					}
					var edgeAlpha:uint = 1;
					if (getParameter("edgeAlpha")) {
						edgeAlpha = parseFloat("" + getParameter("edgeAlpha"));
					}
					var cornerSharpness:Number = 0;
					if (getParameter("cornerSharpness")) {
						cornerSharpness = parseFloat("" + getParameter("cornerSharpness"));
					}
					var endRoundness:Number = 0;
					if (getParameter("endRoundness")) {
						endRoundness = parseFloat("" + getParameter("endRoundness"));
					}
					var randomMin:Number = 1;
					if (getParameter("randomMin")) {
						randomMin = parseFloat("" + getParameter("randomMin"));
					}
					var randomMax:Number = 1;
					if (getParameter("randomMax")) {
						randomMax = parseFloat("" + getParameter("randomMax"));
					}
					
					var p:Point;
					var v:Point;
					var n:Point;
					var l:Number;
					
					var start:Point;
					var end:Point;
					var vBack:Point;
					var vFwd:Point;
					var tmp_vBack:Point;
					var tmp_vFwd:Point;
					var n_vBack:Point;
					var n_vFwd:Point;
										
					var firstSegmentWidth:Number;
					var segmentWidth:Number;
					var nextSegmentWidth:Number;
					var segmentDistance:Number = 0;
					var totalEdgeDistance:Number = 0;
										
					var startNormal:Point;
					var endNormal:Point;
					
					function drawEdge(points:Array, edge:int) {

						Rndm.seed = randomSeed * (edge + 1) * 999999;
						Rndm.random();
							
						var m:Matrix = new Matrix();
						m.rotate(Math.PI / 2 * (edge==0 ? 1 : -1));

						function calculateWidth(p:Number) {
							return Rndm.float(randomMin, randomMax);
						}

						var oldEdgeP:Point = null;
					
						var thickness:Number = 0;
						for (i=0 ; i<100 ; i=i+1) {
							thickness = Math.max(thickness, calculateWidth(i / 100));
						}
						var sliceLength:Number = thickness / 4;
						
						var sampleInterval:Number = sliceLength;
						if (getParameter("sampleInterval")) {
							sampleInterval = parseFloat("" + getParameter("sampleInterval"));
						}

						var a1:Array = new Array();	
						var a2:Array = new Array();	
					
						// calculate normals	
						for (i=0 ; i<points.length; i++) {
							vBack = null;
							vFwd = null;
							n_vBack = null;
							n_vFwd = null;
							n = null;
							
							if (i > 0) {
								start = points[i - 1];
							} else if (closed) {
								start = points[points.length - 1];
							} else {
								start = null;
							}
							p = points[i];
							if (i < points.length - 1) {
								end = points[i + 1];
							} else if (closed) {
								end = points[0];
							} else {
								end = null;
							}
						
							if (start) {
								vBack = p.subtract(start);
								n_vBack = m.transformPoint(vBack);
								n_vBack.normalize(1);
								n = n_vBack.clone();
							}
							if (end) {
								vFwd = end.subtract(p);
								n_vFwd = m.transformPoint(vFwd);
								n_vFwd.normalize(1);
								if (n_vBack) {
									n = n_vBack.add(n_vFwd);
								} else {
									n = n_vFwd.clone();
								}
							}
							n.normalize(1);
							
							function dotProduct(v1:Point, v2:Point) {
								return v1.x * v2.x + v1.y * v2.y;
							}		
							
							function addToArray(i, p, n, normalLength, convex, end) {
								n.normalize(1);
								var n1:Point = n.clone();
								var p1:Point = p.clone();
								var p2:Point = p.clone();
								n1.normalize(normalLength * thickness * 2);
								p2 = p.add(n1);
								n1.normalize(normalLength * thickness);
								p1 = p.add(n1);
								a1.push({
									index: i,
									point: p, 
									edgePoint: p1,
									helpPoint: p2, 
									convex: convex,
									end: end
								});
							}
							
							var dp1:Number = 0;
							var dp2:Number = 1;
							if (start && end) {
								tmp_vBack = vBack.clone();
								tmp_vBack.normalize(1);
								tmp_vFwd = vFwd.clone();
								tmp_vFwd.normalize(1);
								dp1 = dotProduct(n_vBack, tmp_vFwd);
								dp2 = dotProduct(tmp_vBack, tmp_vFwd);
							}
							var convex:Boolean = dp1<=0;
							if (start) {
								if (convex) {
									addToArray(i, p, n_vBack, 1, convex);
								} else {
									if (dp2>=0) {
										vBack.normalize(Math.min(vBack.length, thickness * Math.abs(dp1) * 2));
									} else {
										vBack.normalize(Math.min(vBack.length, thickness * 2 / Math.abs(dp1) * 2));
									}
									addToArray(i, p.subtract(vBack), n_vBack, 1, convex, false);
								}
							} else {
								tmp_vFwd = vFwd.clone();
								vFwd.normalize(-1);
								addToArray(i, p, vFwd, endRoundness, false, true);	
							}
							if (start && end) {
								var nl:Number;
								if (dp2>=0) {
									nl = 1 + Math.abs(Math.pow(dp1, 2) * (Math.SQRT2 - 1));
								} else {
									nl = 2 / Math.abs(dp1);
								}
								addToArray(i, p, n, nl, convex, false);
							}
							if (end) {
								if (convex) {
									addToArray(i, p, n_vFwd, 1, convex);
								} else {
									if (dp2>=0) {
										vFwd.normalize(Math.min(vFwd.length, thickness * Math.abs(dp1) * 2));
									} else {
										vFwd.normalize(Math.min(vFwd.length, thickness * 2 / Math.abs(dp1) * 2));
									}
									addToArray(i, p.add(vFwd), n_vFwd, 1, convex, false);
								}
							} else {
								tmp_vBack = vBack.clone();
								tmp_vBack.normalize(1);
								addToArray(i, p, vBack, endRoundness, false, true);
							}
						}
					
						var totalEdgeLength:Number = 0;
					
						// add points
						var lastEdgePoint:Point = null;
						var lastPoint:Point = null;
						for (i=0 ; i<a1.length; i++) {
							var start_a:* = null
							var end_a:* = null;
							if (i < a1.length - 1) {
								start_a = a1[i];
								end_a = a1[i + 1];
							} else if (closed) {
								start_a = a1[i];
								end_a = a1[0];
							}
							if (start_a && end_a) {
								v = end_a.edgePoint.subtract(start_a.edgePoint);
								l = v.length;
								var segments:Number = Math.ceil(l / sliceLength);
								for (j = 0 ; j<segments+1 ; j++) {
									// let only the last to follow through...
									if (j==segments && i<a1.length-1) {
										break;
									}
									var interpolation:Number = Number(j) / segments;
									var point:Point = Point.interpolate(end_a.point, start_a.point, interpolation);
									var edgePoint:Point = Point.interpolate(end_a.edgePoint, start_a.edgePoint, interpolation);
									var helpPoint:Point = Point.interpolate(end_a.helpPoint, start_a.helpPoint, interpolation);
					//				var normal:Point = Point.interpolate(end_a.normal, start_a.normal, interpolation);
					//				var normalLength:Number =  interpolation * end_a.normalLength + (1 - interpolation) * start_a.normalLength;
									var normal:Point = edgePoint.subtract(point);
									var normalLength:Number = normal.length / thickness;
									normal.normalize(1);
									var edgeLength:Number = 0;
									if (lastEdgePoint) {
										edgeLength = lastEdgePoint.subtract(edgePoint).length;
									}
									totalEdgeLength = totalEdgeLength + edgeLength;
									a2.push({
										index: start_a.index,
										point: point,
										edgePoint: edgePoint,
										helpPoint: helpPoint,
										normal: normal,
										normalLength: normalLength,
										convex: end_a.convex || start_a.convex,
										edgeLength: edgeLength});
									lastEdgePoint = edgePoint.clone();
								}
							}
						}
					
						totalEdgeDistance = segmentDistance = 0;
						firstSegmentWidth = segmentWidth = calculateWidth(0);
						nextSegmentWidth = calculateWidth(sampleInterval);
						
						for (i=0 ; i<a2.length; i++) {
	
							totalEdgeDistance = totalEdgeDistance + a2[i].edgeLength;
							segmentDistance = segmentDistance + a2[i].edgeLength;

							while (segmentDistance >= sampleInterval) {
								segmentDistance = segmentDistance - sampleInterval;
								if (totalEdgeDistance + sampleInterval >= totalEdgeLength) {
									segmentWidth = nextSegmentWidth;
									nextSegmentWidth = firstSegmentWidth; 
								} else {
									segmentWidth = nextSegmentWidth;
									nextSegmentWidth = calculateWidth(totalEdgeDistance / totalEdgeLength);
								}
							}
							
							var tmp:Number = segmentDistance / sampleInterval;
							var edgeWidth:Number = ((1 - tmp) * segmentWidth + tmp * nextSegmentWidth);
					
							if (a2[i].convex) {
								p = a2[i].point.clone();
								n = a2[i].normal.clone();
								l = (1 - cornerSharpness) * 1 + cornerSharpness * (a2[i].normalLength);
								n.normalize(l * edgeWidth);
							} else {
								p = a2[i].helpPoint.clone();
								n = a2[i].normal.clone();
								l = (1 - cornerSharpness) * (1 + (a2[i].normalLength - 1) * 2) + cornerSharpness * (a2[i].normalLength);
								n.normalize(l * edgeWidth - thickness * a2[i].normalLength * 2);
							}
					
							if (i==0) {
								if (edge==0) {
									startNormal = n;
								} else if (!closed) {
									n = startNormal;
								}
							}
					
							if (i==a2.length-1) {
								if (edge==0) {
									endNormal = n;
								} else if (!closed) {
									n = endNormal;
								}
							}
							v = p.add(n);
							
							a2[i].v = v;
						}
						
						for (i=0 ; i<a2.length ; i++) {
							/*
							if (!shapes[a2[i].index]) {
								shapes[a2[i].index] = new Array(new Array(), new Array());
							}
							shapes[a2[i].index][edge].push(v);
							*/
							s.graphics.lineStyle(0, 0, 0);
							s.graphics.beginFill(color, alpha);
							s.graphics.moveTo(a2[i].v.x, a2[i].v.y);
							s.graphics.lineTo(a2[i].point.x, a2[i].point.y);
							if (oldEdgeP) {
								s.graphics.lineTo(a2[i - 1].point.x, a2[i - 1].point.y);
								s.graphics.lineTo(oldEdgeP.x, oldEdgeP.y);
								s.graphics.lineStyle(edgeWidth, edgeColor, edgeAlpha);
							}
							oldEdgeP = a2[i].v.clone();
							s.graphics.lineTo(a2[i].v.x, a2[i].v.y);
							s.graphics.endFill();
							/**/
							/*
							if (i==0 && (edge==0 || closed)) {
								graphics.moveTo(p.x + n.x, p.y + n.y);
							} else {
								graphics.lineTo(p.x + n.x, p.y + n.y);
							}
							/**/
							/*
							graphics.lineStyle(1, 0, 0.5);
							graphics.lineTo(a2[i].point.x, a2[i].point.y);
							graphics.lineTo(a2[i].edgePoint.x, a2[i].edgePoint.y);
							graphics.lineTo(a2[i].helpPoint.x, a2[i].helpPoint.y);
							graphics.lineTo(p.x + n.x, p.y + n.y);
							graphics.lineStyle(2, 0, 0.5);
							/**/							
						}
					}
										
					// calculate total center length	
					var totalCenterLength:Number = 0;
					for (i=0 ; i<points.length; i++) {
						p = points[i];
						if (i < points.length - 1) {
							end = points[i + 1];
						} else if (closed) {
							end = points[0];
						} else {
 							end = null;
						}
						if (end) {
							totalCenterLength = totalCenterLength + end.subtract(p).length;
						}
					}
					var progressStartCenterLength:Number = totalCenterLength * progressStart;
					var progressEndCenterLength:Number = totalCenterLength * progressEnd;

					// modify points array
					var centerDistance:Number = 0;
					var modifiedPoints:Array = new Array();
					for (i=0 ; i<points.length; i++) {
						p = points[i];
						if (i < points.length - 1) {
							end = points[i + 1];
						} else if (closed) {
							end = points[0];
						} else {
							end = null;
						}
						if (end) {
							vFwd = end.subtract(p);
							if (centerDistance + vFwd.length < progressStartCenterLength) {
								// do not add points
							} else {
								if (centerDistance <= progressStartCenterLength) {
									tmp_vFwd = vFwd.clone();
									tmp_vFwd.normalize(progressStartCenterLength - centerDistance);
									modifiedPoints.push(p.add(tmp_vFwd));
								}
								if (centerDistance + vFwd.length > progressEndCenterLength) {
									vFwd.normalize(progressEndCenterLength - centerDistance);
									modifiedPoints.push(p.add(vFwd));
									break;
								} else {
									if (end != points[0]) {
										modifiedPoints.push(p.add(vFwd));
									}
								}
							}
							centerDistance = centerDistance + vFwd.length;
						}
					}
				
					closed = progressStart == 1 && progressEnd == 1 && closed;
				
					drawEdge(modifiedPoints, 0);
					drawEdge(modifiedPoints, 1);
					
				}
			}
		}
	}
}