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

 /**
	The node provides a collision shape used for physics objects (having the PhyicsTrait).
	Adds the following public attributes:

		physics_createCollisionShape(world) -> MinSG.Phyics.CollisionShape creates and returns the collisionShape
		physics_shapeType() 			DataWrapper for a shape type constant; default is SHAPE_TYPE_BOUNDING_BOX.
		
	The trait offers the foolowing public attributes:
		SHAPE_TYPE_BOUNDING_BOX
		SHAPE_TYPE_SPHERE
		_collectShapeNodes( root ) 		(internal) collect all nodes with shapes.
	
 */
 
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static Tools = module('../Tools');

static trait = new PersistentNodeTrait(module.getId());

trait.SHAPE_TYPE_BOUNDING_BOX := 'BB';
trait.SHAPE_TYPE_SPHERE := 'Sphere';

static ATTR_COLLISION_SHAPE_MARKER = "$CIs$physicShapeMarker"; // copy but don't save

// helper
trait._collectShapeNodes := fn(MinSG.Node root){
	return MinSG.collectNodesReferencingAttribute(root,ATTR_COLLISION_SHAPE_MARKER);
};


trait.onInit += fn( MinSG.Node node){
	node.setNodeAttribute( ATTR_COLLISION_SHAPE_MARKER, true );

	node.physics_shapeType := node.getNodeAttributeWrapper('physics_cShape', trait.SHAPE_TYPE_BOUNDING_BOX );
	node.physics_createCollisionShape := fn( world ){
		switch(this.physics_shapeType()){
			case trait.SHAPE_TYPE_BOUNDING_BOX:
				return world.createShape_AABB(this.getBoundingBox());
			case trait.SHAPE_TYPE_SPHERE:
				return world.createShape_Sphere(new Geometry.Sphere(this.getBoundingBox().getCenter(),this.getBoundingBox().getExtentMax()*0.5));
		default: 
			Runtime.exception("CollisionShapeTrait: Invalid shape type '"+this.physics_shapeType()+"'");
		}
	};
};

trait.allowRemoval();
module.on('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_SELECT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "ShapeType",
				GUI.OPTIONS : [
					[trait.SHAPE_TYPE_BOUNDING_BOX,'Bounding box'],
					[trait.SHAPE_TYPE_SPHERE,'Sphere'],
				],
				GUI.DATA_WRAPPER : node.physics_shapeType

			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},

		];
	});
});

return trait;
