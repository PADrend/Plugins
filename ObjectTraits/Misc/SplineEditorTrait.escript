/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014-2015 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());
static TransformationObserverTrait = Std.module('LibMinSGExt/Traits/TransformationObserverTrait');

static locationToPos = fn(l){	return l.isA(Geometry.Vec3) ? l : l.getTranslation(); };

module.on('PADrend/gui',fn(gui){
	gui.register('SplineEditorTrait_ControlPointType1_Config',fn(dataAndIndex){
		[var pointNr, var data] = dataAndIndex;
		return "Foo "+pointNr;
	});
});

static getConfigEntries_PointType1 = fn(pointNr, data){
	return [
		"*Spline control point #"+pointNr+"*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Toggle SRT/Pos",
			GUI.ON_CLICK: [pointNr, data.spline_controlPoints] =>fn(pointNr, points){

				var point = points()[pointNr];
				if(point.location.isA(Geometry.Vec3)){
					var srt = new Geometry.SRT;
					srt.setTranslation(point.location);
					point.location = srt;
				}else{
					point.location = point.getPosition();
				}
				points.forceRefresh();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Add after",
			GUI.ON_CLICK: [data.splineNode,pointNr, data.spline_controlPoints] =>fn(splineNode,pointNr, points){
				if(pointNr<points().count()-1) {
					points( points().slice(0,pointNr+2)
								.append([	splineNode.spline_createControlPoint(locationToPos(splineNode.spline_calcLocation( pointNr/3+0.4 ))),
											splineNode.spline_createControlPoint(splineNode.spline_calcLocation( pointNr/3+0.5 )),
											splineNode.spline_createControlPoint(locationToPos(splineNode.spline_calcLocation( pointNr/3+0.6 ))) ])
								.append(points().slice(pointNr+2)) );
				}else{
					var l0 = points()[pointNr].location.clone();
					var p0 = locationToPos(l0);
					var p1 = locationToPos(splineNode.spline_calcLocation( pointNr/3-1 ));
					points( points().clone().append([	splineNode.spline_createControlPoint( p0 - (p1-p0)*0.3),
														splineNode.spline_createControlPoint( p0 - (p1-p0)*0.7),
														splineNode.spline_createControlPoint( l0.isA(Geometry.SRT) ? l0.translate( p0-p1 ) : l0 - (p1-p0) ) ]) );
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Add before",
			GUI.ON_CLICK: [data.splineNode,pointNr, data.spline_controlPoints] =>fn(splineNode,pointNr, points){
				if(pointNr>0) {
					points( points().slice(0,pointNr-1)
								.append([	splineNode.spline_createControlPoint(locationToPos(splineNode.spline_calcLocation( pointNr/3-0.6 ))),
											splineNode.spline_createControlPoint(splineNode.spline_calcLocation( pointNr/3-0.5 )),
											splineNode.spline_createControlPoint(locationToPos(splineNode.spline_calcLocation( pointNr/3-0.4 ))) ])
								.append(points().slice(pointNr-1)) );
				}else{
					var l0 = points()[0].location.clone();
					var p0 = locationToPos(l0);
					var p1 = locationToPos(splineNode.spline_calcLocation( 1 ));
					points( [	splineNode.spline_createControlPoint( l0.isA(Geometry.SRT) ? l0.translate( p0-p1 ) : l0 - (p1-p0) ),
								splineNode.spline_createControlPoint( p0 - (p1-p0)*0.3),
								splineNode.spline_createControlPoint( p0 - (p1-p0)*0.7) ].append(points()) );
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Delete",
			GUI.ON_CLICK: [pointNr, data.spline_controlPoints] =>fn(pointNr, points){
				var arr = points().clone();
				var arr2 = [];
				if(pointNr < arr.size()-1){
					for(var i = 0; i<arr.size() ; i++){
						if(i < pointNr || i > pointNr+2)
							arr2 += arr[i];
					}
					points(arr2);
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Corner",
			GUI.ON_CLICK: [pointNr, data.spline_controlPoints] =>fn(pointNr, points){
				var pos = points()[pointNr].getPosition();
				var prev = points()[pointNr-3];
				if(prev)
					points()[pointNr-1].location = pos*0.75 + prev.getPosition()*0.25;
				var next = points()[pointNr+3];
				if(next)
					points()[pointNr+1].location = pos*0.75 + next.getPosition()*0.25;
				points.forceRefresh();
			}
		},
		// Test the function spline_calcLocationByLength(Number) see splineTrait!
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "dist.",
			GUI.ON_CLICK: [data]=>fn(data){
				doIt(20, data);

			}

		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Debug",
			GUI.ON_CLICK: [data]=>fn(data){
				foreach(data.spline_controlPoints() as var index, var point){
					outln(index,"\t",point.location);
				}

			}

		},
		'----'
	];
};
static getConfigEntries_PointType2 = fn(pointNr, data){
	return [
		"*Spline control point #"+pointNr+"*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Set straight",
			GUI.ON_CLICK: [pointNr, data.spline_controlPoints] =>fn(pointNr, points){
				if(pointNr%3 == 1){
					var pos = points()[pointNr-1].getPosition();
					var other = points()[pointNr+2];
					if(other)
						points()[pointNr].location = pos*0.75 + other.getPosition()*0.25;
				}else if(pointNr%3 == 2){
					var pos = points()[pointNr+1].getPosition();
					var other = points()[pointNr-2];
					if(other)
						points()[pointNr].location = pos*0.75 + other.getPosition()*0.25;
				}
				points.forceRefresh();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Set smooth",
			GUI.ON_CLICK: [pointNr, data.spline_controlPoints] =>fn(pointNr, points){
				if(pointNr%3 == 1){
					var pos = points()[pointNr-1].getPosition();
					var other = points()[pointNr-2];
					if(other)
						points()[pointNr].location = pos*2.0 - other.getPosition();
				}else if(pointNr%3 == 2){
					var pos = points()[pointNr+1].getPosition();
					var other = points()[pointNr+2];
					if(other)
						points()[pointNr].location = pos*2.0 - other.getPosition();
				}
				points.forceRefresh();
			}
		},
		'----'
	];
};

static blendingState = new MinSG.BlendingState;

static rebuildEditNodes = fn( data ){
	foreach(data.editNodes  as var n)
		MinSG.destroy(n);
	data.editNodes.clear();

	@(once) module.on('PADrend/gui',fn(gui){
		gui.register('PADrend_SceneToolMenu.00_splineEdit',fn(){
			var node = NodeEditor.getSelectedNode();
			return node.isSet($__getConfigEntries) ? node.__getConfigEntries() : [];
		});
	});

	foreach(data.spline_controlPoints() as var pointNr, var point){
		var geoNode = new MinSG.GeometryNode;

		geoNode.setTempNode(true);
		geoNode.setRelOrigin(point.getPosition());
		geoNode += blendingState;
		Std.Traits.addTrait(geoNode,module('../Basic/MetaObjectTrait'));

		module('LibMinSGExt/NodeAnchors').createAnchor(geoNode,'placingPos', new Geometry.Vec3(0,0,0)); // snap to origin and not to lower bounding box center
	
//		geoNode.setRelScaling(0.3);

		if(pointNr % 3== 0)
			geoNode.__getConfigEntries := [pointNr,data] => getConfigEntries_PointType1;
		else
			geoNode.__getConfigEntries := [pointNr,data] => getConfigEntries_PointType2;

			
		geoNode.onClick :=	fn(event){	module('PADrend/gui').openMenu(new Geometry.Vec2(event.x, event.y),this.__getConfigEntries()); };

		Std.Traits.assureTrait(geoNode, TransformationObserverTrait );
		geoNode.onNodeTransformed += [pointNr, data]=>fn(pointNr, data, ...){
			if(data.detectNodeTransformations){
				++data.editNodeTransformationInProgress;
				var arr = data.spline_controlPoints();

				if(pointNr % 3 == 0){
					var deltaMovement =  this.getRelOrigin()-arr[pointNr].getPosition();
					if(arr[pointNr+1]){
						arr[pointNr+1].location += deltaMovement;
						data.editNodes[pointNr+1].moveRel( deltaMovement );
					}
					if(arr[pointNr-1]){
						arr[pointNr-1].location +=  deltaMovement;
						data.editNodes[pointNr-1].moveRel( deltaMovement );
					}
				}
				if(arr[pointNr].location.isA(Geometry.Vec3))
					arr[pointNr].location.setValue(this.getRelOrigin());
				else // srt (without scaling)
					arr[pointNr].location.setValue( this.getRelTransformationSRT().setScale(1.0) );

				--data.editNodeTransformationInProgress;
				if( data.editNodeTransformationInProgress == 0)
					data.spline_controlPoints.forceRefresh();
			}
		};

		data.editNodes += geoNode;
		data.splineNode += geoNode;
	};
};

static rebuildSplineMesh = fn( data ){
	if(data.curveNode){
		MinSG.destroy(data.curveNode);
		data.curveNode = void;
	}
	if(data.additionalLinesNode){
		MinSG.destroy(data.additionalLinesNode);
		data.additionalLinesNode = void;
	}


	var splinePoints = data.splineNode.spline_calcPositions(0.05);
	if(!splinePoints.empty()){

		var builder = new Rendering.MeshBuilder;
		builder.normal(new Geometry.Vec3(0,0,1));
		builder.color(new Util.Color4f(0.9,0,0,0.5));

		var lastPos = splinePoints[0];
		foreach(splinePoints as var i, var pos){
			builder.position(lastPos).addVertex();
			builder.position(lastPos*0.3 + pos*0.7).addVertex();
			lastPos = pos;
		}
		var m = builder.buildMesh();
		m.setDrawLines();
		data.curveNode = new MinSG.GeometryNode(m);
		data.curveNode.setTempNode(true);
		Std.Traits.addTrait(data.curveNode,module('../Basic/MetaObjectTrait'));
		data.splineNode += data.curveNode;
	}

	var mb2 = new Rendering.MeshBuilder;
	mb2.normal(new Geometry.Vec3(0,0,1));
	mb2.color(new Util.Color4f(0.2,0,0,0.1));

	var bb = new Geometry.Box;
	bb.invalidate();
	// connections to controlPoints
	var points = data.splineNode.spline_controlPoints();
	for(var i=0; i<points.count(); i+=3){
		bb.include(points[i].getPosition());
		if(i>0){
			mb2.position(points[i-1].getPosition()).addVertex();
			mb2.position(points[i].getPosition()).addVertex();
		}
		if(i<points.count()-1){
			mb2.position(points[i+1].getPosition()).addVertex();
			mb2.position(points[i].getPosition()).addVertex();
		}
	}
	// directions
	var length = bb.getDiameter() / 50;
	for(var i=0; i<points.count()-3; i+=3){
		if(points[i].location.isA(Geometry.SRT) && points[i+3].location.isA(Geometry.SRT) ){
			for(var d=0;d<=1.001;d+=0.1){
				var srt = data.splineNode.spline_calcLocation(i/3+d);
				if(srt.isA(Geometry.SRT)){
					var yVec = srt.getUpVector();
					var zVec = srt.getDirVector();

					mb2.color(new Util.Color4f(0.5,0,0,0.1));
					mb2.position(srt.getTranslation()).addVertex();
					mb2.position(srt.getTranslation()+yVec.cross(zVec)*length).addVertex();

					mb2.color(new Util.Color4f(0,0.5,0,0.1));
					mb2.position(srt.getTranslation()).addVertex();
					mb2.position(srt.getTranslation()+yVec*length).addVertex();

					mb2.color(new Util.Color4f(0,0,0.5,0.1));
					mb2.position(srt.getTranslation()).addVertex();
					mb2.position(srt.getTranslation()+zVec*length).addVertex();
				}
			}
		}
	}

	if(!mb2.isEmpty()){
		var m = mb2.buildMesh();
		m.setDrawLines();
		data.additionalLinesNode = new MinSG.GeometryNode(m);
		data.additionalLinesNode.setTempNode(true);
		Std.Traits.addTrait(data.additionalLinesNode,module('../Basic/MetaObjectTrait'));

		data.splineNode += data.additionalLinesNode;
	}
};
static updateEditNodes = fn( data ){
	static controlMesh;
	static posMesh;
	static srtMesh;
	@(once) {
		{
			var mb = new Rendering.MeshBuilder;
			mb.color(new Util.Color4f(1,1,0,0.4));
			mb.addSphere( new Geometry.Sphere([0,0,0],0.2),10,10 );
			controlMesh = mb.buildMesh();
		}
		{
			var mb = new Rendering.MeshBuilder;
			mb.color(new Util.Color4f(0,1,0,0.4));
			mb.addSphere( new Geometry.Sphere([0,0,0],0.3),10,10 );
			posMesh = mb.buildMesh();
		}
		{
			var mb = new Rendering.MeshBuilder;
			mb.color(new Util.Color4f(0,1,0,0.4));
			mb.addBox(new Geometry.Box(new Geometry.Vec3(0,0,0),0.4,0.4,0.4));
			srtMesh = mb.buildMesh();
		}
	}
	var requireRebuild = false;
	data.detectNodeTransformations = false;
	var bb = new Geometry.Box;
	bb.invalidate();
	foreach(data.spline_controlPoints() as var pointNr, var point){
		var editNode = data.editNodes[pointNr];
		if(!editNode.getParent()){ // if the user accidentally deleted a control node.
			outln("Rebuild required!");
			requireRebuild = true;
			continue;
		}
		bb.include(point.getPosition());
		if(pointNr % 3 != 0){
			editNode.setMesh(controlMesh);
			editNode.setRelOrigin(point.location);
		}else if(point.location.isA(Geometry.Vec3)){
			editNode.setMesh(posMesh);
			editNode.setRelOrigin(point.location);
		}else{
			editNode.setMesh(srtMesh);
			editNode.setRelTransformation(point.location);
		}
	}
	var scale = bb.getDiameter() / 50;
	foreach(data.spline_controlPoints() as var pointNr, var point){
		data.editNodes[pointNr].setScale(scale);
	}
	data.detectNodeTransformations = true;
	return requireRebuild;
};

trait.onInit += fn( MinSG.GroupNode splineNode){
	Std.Traits.assureTrait(splineNode,module('./SplineTrait'));
	var data = new ExtObject;
	data.editNodeTransformationInProgress := 0;
	data.detectNodeTransformations := false;
	data.editNodes := [];
	data.curveNode := void;
	data.additionalLinesNode := void;
	data.spline_controlPoints := splineNode.spline_controlPoints; //! \see SplineTrait
	data.splineNode := splineNode;

	data.spline_controlPoints.onDataChanged += [data]=>fn(data, ...){
//		if(data.editNodeTransformationInProgress==0){
			if( data.editNodes.count()!=data.spline_controlPoints().count() )
				rebuildEditNodes(data);
			if(updateEditNodes(data)){
				rebuildEditNodes(data);
				updateEditNodes(data);
			}
			rebuildSplineMesh(data);
//		}

	};

	rebuildEditNodes(data);
	updateEditNodes(data);
	rebuildSplineMesh(data);
};

// Test the function spline_calcLocationByLength(Number) see splineTrait!
static doIt = fn(Number v, data){
	var totallenghth = data.splineNode.spline_calcLength(data);
	var distance = totallenghth / 10;
	for(var l = 0; l <=totallenghth; l+=distance){
		var transformation = data.splineNode.spline_calcLocationByLength(l,data);
		var geoNode = new MinSG.GeometryNode;
		var mb = new Rendering.MeshBuilder;
		mb.color(new Util.Color4f(1,0,1,0.4));
		mb.addSphere( new Geometry.Sphere([0,0,0],0.1),10,10 );
		geoNode.setMesh(mb.buildMesh());
		if(transformation.isA(Geometry.Vec3))
			geoNode.setRelOrigin(transformation);
		else
			geoNode.setRelTransformation(transformation);
		data.splineNode += geoNode;
	}

};

trait.allowRemoval();

return trait;

