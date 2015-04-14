/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! Changes a GeometryNode's mesh into a dynamically generated cylinder.
	Its origin is local (0,0,0) pointing upward in y-direction.
	Adds the following attributes:
		- sphereRadius  				DataWrapper: The sphere's radius 
		- sphereInclinationSegments		DataWrapper: The number of the sphere's inclinationSegments 
		- sphereAzimuthSegments			DataWrapper: The number of the sphere's azimuthSegments 
	The spherer is updated when a value is changed.

	\see MinSG.PersistentNodeTrait
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.GeometryNode node){
		
	var sphereRadius = node.getNodeAttributeWrapper('sphereRadius', node.getMesh() ? node.getBB().getExtentX()*0.5 : 0.5 );
	var sphereInclinationSegments =  node.getNodeAttributeWrapper('sphereInclinationSegments',8);
	var sphereAzimuthSegments =  node.getNodeAttributeWrapper('sphereAzimuthSegments',8);

	
	var regenerate = [node,sphereRadius,sphereInclinationSegments,sphereAzimuthSegments]=>fn(node,sphereRadius,sphereInclinationSegments,sphereAzimuthSegments,...){
		var mb = new Rendering.MeshBuilder;
		mb.color(new Util.Color4f(1,1,1,1));
		mb.addSphere( new Geometry.Sphere([0,0,0],sphereRadius()),sphereInclinationSegments(),sphereAzimuthSegments() );
		node.setMesh( mb.buildMesh() );
	};
	sphereRadius.onDataChanged += regenerate;
	sphereInclinationSegments.onDataChanged += regenerate;
	sphereAzimuthSegments.onDataChanged += regenerate;
	node.sphereRadius := sphereRadius;
	node.sphereInclinationSegments := sphereInclinationSegments;
	node.sphereAzimuthSegments := sphereAzimuthSegments;	

	if(!node.getMesh() || node.getMesh().getPrimitiveCount() != (sphereInclinationSegments()-1)*sphereAzimuthSegments()*2 || (node.getBB().getExtentMax()-sphereRadius()*2).abs()>sphereRadius()*0.05 )
		regenerate();
};

trait.allowRemoval();
trait.onRemove += fn(node){
	sphereRadius.onDataChanged.clear();
	sphereInclinationSegments.onDataChanged.clear();
	sphereAzimuthSegments.onDataChanged.clear();
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "sphereRadius",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.sphereRadius
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [3,32],
				GUI.RANGE_STEP_SIZE : 1,
				GUI.LABEL : "sphereInclinationSegments",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.sphereInclinationSegments
			},			
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [3,32],
				GUI.RANGE_STEP_SIZE : 1,
				GUI.LABEL : "sphereAzimuthSegments",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.sphereAzimuthSegments
			},
		];
	});
});

return trait;

