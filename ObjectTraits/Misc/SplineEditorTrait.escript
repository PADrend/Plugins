/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
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

trait.onInit += fn( MinSG.GroupNode splineNode){

	var data = new ExtObject;
	data.localTransformationInProgress := new Std.DataWrapper(0);
	data.editNodes := [];
	data.curveNode := void; // TEMP!
	@(once) static mesh = Rendering.MeshBuilder.createSphere(10, 10);

	var rebuild = [splineNode, data] =>fn( splineNode, data){
		foreach(data.editNodes  as var n)
			MinSG.destroy(n);
		data.editNodes.clear();
		foreach(splineNode.spline_controlPoints() as var id, var point){
			var geoNode = new MinSG.GeometryNode(mesh);
			geoNode.setWorldOrigin(point);
			geoNode.setRelScaling(0.3);
			Std.Traits.assureTrait(geoNode, TransformationObserverTrait );

			geoNode.onNodeTransformed += [id, splineNode, data]=>fn(id, splineNode, data, ...){
				data.localTransformationInProgress(data.localTransformationInProgress()+1);
				var arr = splineNode.spline_controlPoints().clone();
				var relMovement =  this.getRelOrigin()-arr[id];
				arr[id] = arr[id] + relMovement;
				if(id % 3== 0){
					if(arr[id+1]){
						arr[id+1] = arr[id+1] + relMovement;
						data.editNodes[id+1].moveRel( relMovement );
					}
					if(arr[id-1]){
						arr[id-1] = arr[id-1] + relMovement;
						data.editNodes[id-1].moveRel( relMovement );
					}

				}
				splineNode.spline_controlPoints(arr);
				data.localTransformationInProgress(data.localTransformationInProgress()-1);
			};
			if(id % 3== 0){
				geoNode.onClick := [id, splineNode, data] =>fn(id, splineNode, data, event){
					var entries = [];
					entries +=
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Add after",
							GUI.ON_CLICK: [id, splineNode] =>fn(id, splineNode){
								var arr = splineNode.spline_controlPoints().clone();
								var arr2 = [];
								if(arr[id-1]){
									var dir = ( arr[id] - arr[id-1]) / 4;
									for(var i = 0; i<3 ; i++){
										arr += (new Geometry.Vec3( arr[id].x(),  arr[id].y(),  arr[id].z())) + dir * (i+1);
									}
									splineNode.spline_controlPoints(arr);
								}
								else {
									var dir = new Geometry.Vec3(5,0,0);
									if(arr[id+1])
										dir = (arr[id+1] -  arr[id]) / 4;
									arr2 += arr[id];
									for(var i = 0; i<3 ; i++){
										arr2 += (new Geometry.Vec3( arr[id].x(),  arr[id].y(),  arr[id].z())) + dir * (i+1);
									}
									for(var i = id+1; i<arr.size() ; i++){
										arr2 += arr[i];
									}
									splineNode.spline_controlPoints(arr2);

								}


							}
						};
					entries +=
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Add befor",
							GUI.ON_CLICK: [id, splineNode] =>fn(id, splineNode){
								var arr = splineNode.spline_controlPoints().clone();
								var arr2 = [];
								if(arr[id-1]){
									var dir = (arr[id-1] - arr[id]) / 4;
									for(var i = 0; i<id ; i++){
										arr2 += arr[i];
									}
									for(var i = 0; i<3 ; i++){
										arr2 += (new Geometry.Vec3(arr[id].x(), arr[id].y(), arr[id].z())) + dir * (i+1);
									}
									arr2 += arr[id];
									splineNode.spline_controlPoints(arr2);
								}
								else{
									var dir = new Geometry.Vec3(-5,0,0);
									if(arr[id+1])
										dir = (arr[id] - arr[id+1]) / 4;
									for(var i = 0; i<3 ; i++){
										arr2 += (new Geometry.Vec3(arr[id].x(), arr[id].y(), arr[id].z())) + dir * (i+1);
									}
									for(var i =0; i<arr.size() ; i++){
										arr2 += arr[i];
									}
									splineNode.spline_controlPoints(arr2);

								}

							}
						};
					entries +=
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Delete",
							GUI.ON_CLICK: [id, splineNode] =>fn(id, splineNode){
								var arr = splineNode.spline_controlPoints().clone();
								var arr2 = [];
								if(id < arr.size()-1){
									for(var i = 0; i<arr.size() ; i++){
									if(i < id || i > id+2)
										arr2 += arr[i];
									}
									splineNode.spline_controlPoints(arr2);
								}
							}
						};
						entries +=
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Straight",
							GUI.ON_CLICK: [id, splineNode, data] =>fn(id, splineNode, data){
								var arr = splineNode.spline_controlPoints().clone();
								if(arr[id+1])
									arr[id+1] = new Geometry.Vec3(arr[id].x() + 5, arr[id].y(), arr[id].z());
								if(arr[id-1])
									arr[id-1] = new Geometry.Vec3(arr[id].x() - 5, arr[id].y(), arr[id].z());
								splineNode.spline_controlPoints(arr);
							}
						};
					gui.openMenu(new Geometry.Vec2(event.x, event.y),entries, 100);

				};
			};
			geoNode.setTempNode(true);
			data.editNodes += geoNode;
			splineNode += geoNode;
		}
	};

	var createSplineMesh = [data, splineNode]=>fn(data, splineNode){
		var splinePoints = splineNode.spline_createSplinePoints(0.1);
		if(data.curveNode)
			MinSG.destroy(data.curveNode);
		if(!splinePoints.empty()){
			var builder = new Rendering.MeshBuilder;
			builder.normal(new Geometry.Vec3(0,0,1));
			builder.color(new Util.Color4f(1,1,0,1));
			foreach(splinePoints as var point)
				builder.color(new Util.Color4f(0.2,0,0,0.1)).position(point).addVertex();
			var m = builder.buildMesh();
			m.setDrawLineStrip();
			data.curveNode = new MinSG.GeometryNode(m);
			data.curveNode.setTempNode(true);
			splineNode += data.curveNode;
		}

	};

	splineNode.spline_controlPoints.onDataChanged += [data,rebuild, createSplineMesh, splineNode]=>fn(data,rebuild, createSplineMesh, splineNode, ...){
		if(data.localTransformationInProgress()==0)
			rebuild();

		createSplineMesh();
	};

	rebuild();
	createSplineMesh();
};

trait.allowRemoval();

return trait;

