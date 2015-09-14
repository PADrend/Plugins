/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
/*! Changes a GeometryNode's mesh into a dynamically generated cone.
	Its origin is local (0,0,0) pointing upward in y-direction.
	Adds the following attributes:
		- coneRadius   DataWrapper: The cone's radius x/z-plane
		- coneHeight   DataWrapper: The cone's height in y direction.
		- coneNumSegments   DataWrapper: The cone's number of segments.
	The cone is updated when a value is changed.

	\see MinSG.PersistentNodeTrait
	\todo generate texture coordinates
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.GeometryNode node){
	var coneRadius = node.getNodeAttributeWrapper('coneRadius', node.getBB().getExtentX()*0.5 );
	var coneHeight =  node.getNodeAttributeWrapper('coneHeight',node.getBB().getExtentY());
	var coneNumSegments = node.getNodeAttributeWrapper('coneSegments',6);
	
	var regenerate = [node,coneRadius,coneHeight,coneNumSegments]=>fn(node,coneRadius,coneHeight,coneNumSegments,...){
		var radius = coneRadius();
		var height = coneHeight();
		var stepDeg = 360/coneNumSegments();
		
		var mb = new Rendering.MeshBuilder;
		mb.color( new Util.Color4f(1,1,1,1) );
				
		{ // disc
			mb.normal( [0, -1, 0] );
			mb.position( [0, 0, 0] );
			var i_center = mb.addVertex();
			
			var tCenter = new Geometry.Vec2( 0.25,0.75 );
			mb.texCoord0( tCenter + [-0.24,0.0] );
			mb.position( [-radius, 0, 0] );
			mb.addVertex();
			for(var d=stepDeg; d<359.999; d+=stepDeg){
				var rad = d.degToRad();
				mb.position( [-rad.cos()*radius, 0, rad.sin()*radius] );
				mb.texCoord0( tCenter + [-rad.cos()*0.24,rad.sin()*0.24] );

				var i = mb.addVertex();
				mb.addTriangle(i_center,i,i-1);
			}
			mb.addTriangle(i_center,i_center+1,mb.getNextIndex()-1);
		}
		{ // cone
			mb.normal( [0, 1, 0] );
			mb.position( [0, height, 0] );
			var i_center = mb.addVertex();

			var tCenter = new Geometry.Vec2( 0.75,0.75 );
			mb.texCoord0( tCenter + [-0.24,0.0] );
			mb.position( [-radius, 0, 0] );
			mb.addVertex();
			for(var d=stepDeg; d<359.999; d+=stepDeg){
				var rad = d.degToRad();
				mb.position( [-rad.cos()*radius ,0, rad.sin()*radius] );
				mb.texCoord0( tCenter + [-rad.cos()*0.24,rad.sin()*0.24] );

				var i = mb.addVertex();
				mb.addTriangle(i_center,i-1,i);
			}
			mb.addTriangle(i_center,mb.getNextIndex()-1,i_center+1);
		}
		node.setMesh( mb.buildMesh() );
	};
	coneRadius.onDataChanged += regenerate;
	coneHeight.onDataChanged += regenerate;
	coneNumSegments.onDataChanged += regenerate;
	node.coneRadius := coneRadius;
	node.coneHeight := coneHeight;
	node.coneNumSegments := coneNumSegments;	
	
	// guess if the mesh is already a cone
	if(!node.getMesh() || node.getMesh().getVertexCount() != (coneNumSegments().floor()+1) || node.getBB().getExtentY().round() != coneHeight().round() )
		regenerate();
};

trait.allowRemoval();
trait.onRemove += fn(node){
	coneRadius.onDataChanged.clear();
	coneHeight.onDataChanged.clear();
	coneNumSegments.onDataChanged.clear();
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "coneRadius",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.coneRadius
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "coneHeight",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.coneHeight
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [3,32],
				GUI.RANGE_STEP_SIZE : 1,
				GUI.LABEL : "coneNumSegments",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.coneNumSegments
			},
		];
	});
});

return trait;

