/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! Changes a GeometryNode's mesh into a dynamically generated rectangle in the (x,y)-plane.
	Its origin is local (0,0,0).
	Adds the following attributes:
		- textureRect  DataWrapper: [uMin,vMin,uMax,vMax]
		- rectDimX  DataWrapper: Number
		- rectDimY  DataWrapper: Number
	The rectangle is updated when a value is changed.

	\see MinSG.PersistentNodeTrait
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.GeometryNode node){
	node.rectDimX := new Std.DataWrapper(node.getBB().getExtentX());
	node.rectDimY := new Std.DataWrapper(node.getBB().getExtentY());
	
	var textureRectSerialized = node.getNodeAttributeWrapper('textureRect', "[0,0,1,1]");
	node.textureRect := new Std.DataWrapper;
	
	node.textureRect( new Geometry.Rect( parseJSON(textureRectSerialized())...) ); // init
	node.textureRect.onDataChanged += [textureRectSerialized] => fn(textureRectSerialized, Geometry.Rect newRect){
		textureRectSerialized( toJSON([newRect.x(),newRect.y(),newRect.width(),newRect.height()],false) );
	};
	
	var regenerate = [node,node.rectDimX,node.rectDimY,node.textureRect]=>fn(node,rectDimX,rectDimY,textureRect, ...){
		var mb = new Rendering.MeshBuilder;
		mb.color( new Util.Color4f(1,1,1,1) );

		var uvRect = textureRect();
		var w = rectDimX();
		var h = rectDimY();
		mb	.normal( [0,0,1] )
			.position( [0,0,0] )
			.texCoord0( [uvRect.getMinX(),uvRect.getMinY()])
			.addVertex();
		mb	.position( [ w,0,0] )
			.texCoord0( [uvRect.getMaxX(),uvRect.getMinY()])
			.addVertex();
		mb	.position( [ w,h,0] )
			.texCoord0( [uvRect.getMaxX(),uvRect.getMaxY()])
			.addVertex();
		mb	.position( [ 0,h,0] )
			.texCoord0( [uvRect.getMinX(),uvRect.getMaxY()])
			.addVertex();
		mb.addQuad(0,1,2,3);

		node.setMesh( mb.buildMesh() );
	};
	node.rectDimX.onDataChanged += regenerate;
	node.rectDimY.onDataChanged += regenerate;
	node.textureRect.onDataChanged += regenerate;

};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){

		return [ 
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "X",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.rectDimX
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3,2],
				GUI.RANGE_FN_BASE : 10,
				GUI.LABEL : "Y",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.rectDimY
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "uv",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : {
					var r = node.textureRect();
					var serializedUV = new Std.DataWrapper( toJSON([r.x(),r.y(),r.width(),r.height()],false) );
					serializedUV.onDataChanged += [node.textureRect] => fn(rectWrapper, String s){
						rectWrapper( new Geometry.Rect( parseJSON(s)...) );
					};
					serializedUV;
				},
				GUI.OPTIONS_PROVIDER : [node.rectDimX,node.rectDimY] => fn(rectDimX,rectDimY){
					return [
						"[0,0,1,1]",
						"[0,0,"+rectDimX()+","+rectDimY()+"]",
						(rectDimX()!=0 ? ["[0,0,1,"+(1/rectDimX())+"]"] : [])...,
						(rectDimY()!=0 ? ["[0,0,"+(1/rectDimY())+",1]"] : [])...
					];
				}
			},
		];
	});
});

return trait;

