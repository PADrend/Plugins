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
/*! Changes a GeometryNode's mesh into a dynamically generated cylinder.
	Its origin is local (0,0,0) pointing upward in y-direction.
	Adds the following attributes:
		- cylRadius   DataWrapper: The cylinder's radius x/z-plane
		- cylHeight   DataWrapper: The cylinder's height in y direction.
		- cylNumSegments   DataWrapper: The cylinder's number of segments.
	The cylinder is updated when a value is changed.

	\see MinSG.PersistentNodeTrait
	\todo generate texture coordinates
*/
static trait = new MinSG.PersistentNodeTrait('ObjectTraits/DynamicCylinderTrait');

trait.onInit += fn(MinSG.GeometryNode node){
	var cylRadius = node.getNodeAttributeWrapper('cylRadius', node.getBB().getExtentX()*0.5 );
	var cylHeight =  node.getNodeAttributeWrapper('cylHeight',node.getBB().getExtentY());
	var cylNumSegments = node.getNodeAttributeWrapper('cylSegments',6);
	var cylColor = node.getNodeAttributeWrapper('cylColor',"1 1 1 0.5");
	
	var regenerate = [node,cylRadius,cylHeight,cylNumSegments,cylColor]=>fn(node,cylRadius,cylHeight,cylNumSegments,cylColor,...){
		var radius = cylRadius();
		var height = cylHeight();
		var stepDeg = 360/cylNumSegments();
		
		var mb = new Rendering.MeshBuilder;
		mb.color( new Util.Color4f(cylColor().split(" ")) );
		
		
		{ // disc 1
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
		{ // disc 2
			mb.normal( [0, 1, 0] );
			mb.position( [0, height, 0] );
			var i_center = mb.addVertex();

			var tCenter = new Geometry.Vec2( 0.75,0.75 );
			mb.texCoord0( tCenter + [-0.24,0.0] );
			mb.position( [-radius, height, 0] );
			mb.addVertex();
			for(var d=stepDeg; d<359.999; d+=stepDeg){
				var rad = d.degToRad();
				mb.position( [-rad.cos()*radius ,height, rad.sin()*radius] );
				mb.texCoord0( tCenter + [-rad.cos()*0.24,rad.sin()*0.24] );

				var i = mb.addVertex();
				mb.addTriangle(i_center,i-1,i);
			}
			mb.addTriangle(i_center,mb.getNextIndex()-1,i_center+1);
		}
		{ // cylinder
			var i = mb.getNextIndex();
			mb.normal( [-1, 0, 0] );
			mb.texCoord0( [0.0, 0.0] );			mb.position( [-radius, 0, 0] );					mb.addVertex();
			mb.texCoord0( [0.0, 0.5] );			mb.position( [-radius, height, 0] );			mb.addVertex();
			i+=2;
			for(var d=stepDeg; d<359.999; d+=stepDeg){
				var rad = d.degToRad();
				var x = -rad.cos();
				var z = rad.sin();
				mb.normal( [x,0,z] );				
				mb.texCoord0( [d/360.0, 0.0] );				mb.position( [x*radius  ,0, z*radius] );				mb.addVertex();
				mb.texCoord0( [d/360.0, 0.5] );				mb.position( [x*radius  ,height, z*radius] );			mb.addVertex();
				i+=2;
				mb.addQuad(i-1,i-3,i-4,i-2);
			}
			mb.normal( [-1, 0, 0] );
			mb.texCoord0( [1.0, 0.0] );			mb.position( [-radius, 0, 0] );					mb.addVertex();
			mb.texCoord0( [1.0, 0.5] );			mb.position( [-radius, height, 0] );			mb.addVertex();
			i+=2;
			mb.addQuad(i-1,i-3,i-4,i-2);
		}

		node.setMesh( mb.buildMesh() );
	};
	cylRadius.onDataChanged += regenerate;
	cylHeight.onDataChanged += regenerate;
	cylNumSegments.onDataChanged += regenerate;
	node.cylRadius := cylRadius;
	node.cylHeight := cylHeight;
	node.cylNumSegments := cylNumSegments;	
	node.cylColor := cylColor;	
	
	// guess if the mesh is already a cylinder
	if(!node.getMesh() || node.getMesh().getVertexCount() != (cylNumSegments().floor()*4 +4) || node.getBB().getExtentY().round() != cylHeight().round() )
		regenerate();
};

trait.allowRemoval();
trait.onRemove += fn(node){
	cylRadius.onDataChanged.clear();
	cylHeight.onDataChanged.clear();
	cylNumSegments.onDataChanged.clear();
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ "DynamicCylinder",
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
				GUI.LABEL : "cylRadius",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.cylRadius
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "cylHeight",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.cylHeight
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [3,32],
				GUI.RANGE_STEP_SIZE : 1,
				GUI.LABEL : "cylNumSegments",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.cylNumSegments
			},
		];
	});
});

return trait;

