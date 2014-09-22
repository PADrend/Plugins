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


trait.onInit += fn( node){
	@(once) static PhysicSceneTrait = module('Physics/PhysicSceneTrait');


	var world = Physics.getWorld( node );

	node.physic_mass := node.getNodeAttributeWrapper('physic_mass', 1 );
	node.physic_mass.onDataChanged += [world,node]=>fn(world,node,d){
		world.updateMass(node,d);
	};

	node.physic_friction := node.getNodeAttributeWrapper('physic_friction', 0 );
	node.physic_friction.onDataChanged += [world,node]=>fn(world,node,d){
		world.updateFriction(node,d);
	};

	node.physic_rollingFriction := node.getNodeAttributeWrapper('physic_rollingFriction', 0 );
	node.physic_rollingFriction.onDataChanged += [world,node]=>fn(world,node,d){
		world.updateRollingFriction(node,d);
	};

	node.physic_shapeType := node.getNodeAttributeWrapper('physic_shapeType', {MinSG.Physics.SHAPE_TYPE : MinSG.Physics.SHAPE_TYPE_BOX} );
	node.physic_shapeType.onDataChanged += [world,node]=>fn(world,node,d){
		world.updateShape(node,d);
	};

	node.physic_localSurfaceVelocity:= node.getNodeAttributeWrapper('physic_localSurfaceVelocity', "0 0 0");
	node.physic_localSurfaceVelocity.onDataChanged += [world,node]=>fn(world,node,d){
		var vec = new Geometry.Vec3(d.split(" "));
		world.updateLocalSurfaceVelocity(node,vec);
	};
	world.addNodeToPhyiscWorld(node, node.physic_shapeType());
	world.updateShape(node,node.physic_shapeType());
	world.updateFriction(node,node.physic_friction());
	world.updateRollingFriction(node,node.physic_rollingFriction());
	world.updateLocalSurfaceVelocity(node, new Geometry.Vec3(node.physic_localSurfaceVelocity().split(" ")));
	world.updateMass(node,node.physic_mass());

};

trait.allowRemoval();
module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Mass",
				GUI.DATA_WRAPPER : node.physic_mass
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Friction",
				GUI.DATA_WRAPPER : node.physic_friction
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Roll Fric.",
				GUI.DATA_WRAPPER : node.physic_rollingFriction
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_SELECT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Phy. obj. shape",
				GUI.OPTIONS : [
					[{MinSG.Physics.SHAPE_TYPE : MinSG.Physics.SHAPE_TYPE_BOX},'Dynamic_Box'],
					[{MinSG.Physics.SHAPE_TYPE : MinSG.Physics.SHAPE_TYPE_CONVEX_HULL},'Dynamic_ConvexHull'],
					[{MinSG.Physics.SHAPE_TYPE : MinSG.Physics.SHAPE_TYPE_STATIC_TRIANGLE_MESH},'Static_TriangleMesh'],
					[{MinSG.Physics.SHAPE_TYPE : MinSG.Physics.SHAPE_TYPE_SPHERE},'Dynamic_Sphere']],
				GUI.DATA_WRAPPER : node.physic_shapeType

			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "LocalSurfaceVelocity",
				GUI.DATA_WRAPPER : node.physic_localSurfaceVelocity
			}

		];
	});
});

return trait;
