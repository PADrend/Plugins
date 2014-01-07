/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/DynamicBoxTrait');

trait.onInit += fn(MinSG.GeometryNode node){
	var dimX = new Std.DataWrapper(node.getBB().getExtentX());
	var dimY = new Std.DataWrapper(node.getBB().getExtentY());
	var dimZ = new Std.DataWrapper(node.getBB().getExtentZ());
	
	var regenerate = [node,dimX,dimY,dimZ]=>fn(node,dimX,dimY,dimZ,value){
		var mb = new Rendering.MeshBuilder;
		mb.color( new Util.Color4f(1,1,1,1) );
		var x = dimX();
		var y = dimY();
		var z = dimZ();
		mb.addBox( new Geometry.Box(new Geometry.Vec3(x*0.5,y*0.5,z*0.5),x,y,z) );
		node.setMesh( mb.buildMesh() );
	};
	dimX.onDataChanged += regenerate;
	dimY.onDataChanged += regenerate;
	dimZ.onDataChanged += regenerate;
	node.dimX := dimX;
	node.dimY := dimY;
	node.dimZ := dimZ;	
};

trait.allowRemoval();

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ "DynamicBox",
			{
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Remove trait",
				GUI.LABEL : "-",
				GUI.WIDTH : 20,
				GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
					if(Traits.queryTrait(node,trait))
						Traits.removeTrait(node,trait);
					refreshCallback();
				}
			},		
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "X",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.dimX
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "Y",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.dimY
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "Z",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.dimZ
			},
		];
	});
});

return trait;

