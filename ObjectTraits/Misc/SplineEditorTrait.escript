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
static TransformationObserverTrait = Std.require('LibMinSGExt/Traits/TransformationObserverTrait');


static openMenu = fn(pointNr, data, event){
	gui.openMenu(new Geometry.Vec2(event.x, event.y),[
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
			GUI.ON_CLICK: [data,pointNr, data.spline_controlPoints] =>fn(data,pointNr, points){
				var arr = points().clone();
				var arr2 = [];
				if(arr[pointNr-1]){
					var dir = ( arr[pointNr].getPosition() - arr[pointNr-1].getPosition()) / 4;
					for(var i = 0; i<3 ; i++)
						arr += data.splineNode.spline_createControlPoint((new Geometry.Vec3( arr[pointNr].getPosition().x(),  arr[pointNr].getPosition().y(),  arr[pointNr].getPosition().z())) + dir * (i+1));
					points(arr);
				}
				else {
					var dir = new Geometry.Vec3(5,0,0);
					if(arr[pointNr+1])
						dir = (arr[pointNr+1].getPosition() -  arr[pointNr].getPosition()) / 4;
					arr2 += arr[pointNr];
					for(var i = 0; i<3 ; i++)
						arr2 += data.splineNode.spline_createControlPoint((new Geometry.Vec3( arr[pointNr].getPosition().x(),  arr[pointNr].getPosition().y(),  arr[pointNr].getPosition().z())) + dir * (i+1));

					for(var i = pointNr+1; i<arr.size() ; i++)
						arr2 += arr[i];
					points(arr2);
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Add before",
			GUI.ON_CLICK: [data,pointNr, data.spline_controlPoints] =>fn(data,pointNr, points){
				var arr = points().clone();
				var arr2 = [];
				if(arr[pointNr-1]){
					var dir = (arr[pointNr-1].getPosition() - arr[pointNr].getPosition()) / 4;
					for(var i = 0; i<pointNr ; i++)
						arr2 += arr[i];
					for(var i = 0; i<3 ; i++)
						arr2 += data.splineNode.spline_createControlPoint(
												(new Geometry.Vec3(arr[pointNr].getPosition().x(), arr[pointNr].getPosition().y(), arr[pointNr].getPosition().z())) + dir * (i+1));
					arr2 += arr[pointNr];
					points(arr2);
				}
				else{
					var dir = new Geometry.Vec3(-5,0,0);
					if(arr[pointNr+1])
						dir = (arr[pointNr].getPosition() - arr[pointNr+1].getPosition()) / 4;
					for(var i = 0; i<3 ; i++)
						arr2 += data.splineNode.spline_createControlPoint(
												(new Geometry.Vec3(arr[pointNr].getPosition().x(), arr[pointNr].getPosition().y(), arr[pointNr].getPosition().z())) + dir * (i+1));
					for(var i =0; i<arr.size() ; i++)
						arr2 += arr[i];
					points(arr2);

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

		}
	], 100);
};
static openMenu2 = fn(pointNr, data, event){
	gui.openMenu(new Geometry.Vec2(event.x, event.y),[
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
		
	], 100);
};



static rebuildEditNodes = fn( data ){
	foreach(data.editNodes  as var n)
		MinSG.destroy(n);
	data.editNodes.clear();


	foreach(data.spline_controlPoints() as var pointNr, var point){
		var geoNode = new MinSG.GeometryNode;
		geoNode.setTempNode(true);
		geoNode.setRelOrigin(point.getPosition());
//		geoNode.setRelScaling(0.3);

		if(pointNr % 3== 0)
			geoNode.onClick := [pointNr, data] => openMenu;
		else
			geoNode.onClick := [pointNr, data] => openMenu2;

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
		builder.color(new Util.Color4f(0.2,0,0,0.1));
		//-------------------test---------------
//		var mb = new Rendering.MeshBuilder;
//		mb.color(new Util.Color4f(0,1,0,0.4));
//		mb.addSphere( new Geometry.Sphere([0,0,0],0.3),5,5 );
//		var posMesh = mb.buildMesh();

		foreach(splinePoints as var i, var point){
			if(i>0)
				builder.position(point).addVertex();
			builder.position(point).addVertex();
//			var n = new MinSG.GeometryNode(posMesh);
//			n.setRelOrigin(point);
//			data.splineNode +=n;
		}
		var m = builder.buildMesh();
		m.setDrawLines();
		data.curveNode = new MinSG.GeometryNode(m);
		data.curveNode.setTempNode(true);
		data.splineNode += data.curveNode;
	}

	var mb2 = new Rendering.MeshBuilder;
	mb2.normal(new Geometry.Vec3(0,0,1));
	mb2.color(new Util.Color4f(0.2,0,0,0.1));

	// connections to controlPoints
	var points = data.splineNode.spline_controlPoints();
	for(var i=0; i<points.count(); i+=3){
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
	for(var i=0; i<points.count()-3; i+=3){
		if(points[i].location.isA(Geometry.SRT) && points[i+3].location.isA(Geometry.SRT) ){
			for(var d=0;d<=1.001;d+=0.1){
				var srt = data.splineNode.spline_calcLocation(i/3+d);
				if(srt.isA(Geometry.SRT)){
					var yVec = srt.getUpVector();
					var zVec = srt.getDirVector();

					mb2.color(new Util.Color4f(0.5,0,0,0.1));
					mb2.position(srt.getTranslation()).addVertex();
					mb2.position(srt.getTranslation()+yVec.cross(zVec)*0.5).addVertex();

					mb2.color(new Util.Color4f(0,0.5,0,0.1));
					mb2.position(srt.getTranslation()).addVertex();
					mb2.position(srt.getTranslation()+yVec*0.5).addVertex();

					mb2.color(new Util.Color4f(0,0,0.5,0.1));
					mb2.position(srt.getTranslation()).addVertex();
					mb2.position(srt.getTranslation()+zVec*0.5).addVertex();
				}
			}
		}
	}

	if(!mb2.isEmpty()){
		var m = mb2.buildMesh();
		m.setDrawLines();
		data.additionalLinesNode = new MinSG.GeometryNode(m);
		data.additionalLinesNode.setTempNode(true);
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
			mb.addSphere( new Geometry.Sphere([0,0,0],0.1),10,10 );
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
			mb.addBox(new Geometry.Box(new Geometry.Vec3(0,0,0),0.3,0.3,0.3));
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
	var scale = bb.getDiameter() / 30;
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

