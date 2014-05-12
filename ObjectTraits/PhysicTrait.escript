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

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/PhysicTrait');


trait.onInit += fn( node){
    @(once) static PhysicSceneTrait = Std.require('Physics/PhysicSceneTrait');
    if(!Physics.getActiveWorld()){
		var scene = PADrend.getCurrentScene();
		if(!Traits.queryTrait(scene,PhysicSceneTrait))
			Traits.addTrait(scene,PhysicSceneTrait);
		PADrend.message("Physic World is created!");
	}
    if(!Physics.isPhysicsNode(node)){
        Physics.getActiveWorld().addNodeToPhyiscWorld(node);
    }
    node.physic_mass := node.getNodeAttributeWrapper('physic_mass', 0 );
    node.physic_mass.onDataChanged += [node]=>fn(node,d){
        Physics.getActiveWorld().updateMass(node,d);
    };

    node.physic_friction := node.getNodeAttributeWrapper('physic_friction', 0 );
    node.physic_friction.onDataChanged += [node]=>fn(node,d){
        Physics.getActiveWorld().updateFriction(node,d);
    };

    node.physic_rollingFriction := node.getNodeAttributeWrapper('physic_rollingFriction', 0 );
    node.physic_rollingFriction.onDataChanged += [node]=>fn(node,d){
        Physics.getActiveWorld().updateRollingFriction(node,d);
    };

    node.physic_shapeType := node.getNodeAttributeWrapper('physic_shapeType', {MinSG.Physics.SHAPE_TYPE : MinSG.Physics.SHAPE_TYPE_BOX} );
    node.physic_shapeType.onDataChanged += [node]=>fn(node,d){
        Physics.getActiveWorld().updateShape(node,d);
    };

    node.physic_localSurfaceVelocity:= node.getNodeAttributeWrapper('physic_localSurfaceVelocity', "0 0 0");
    node.physic_localSurfaceVelocity.onDataChanged += [node]=>fn(node,d){
        var vec = new Geometry.Vec3(d.split(" "));
        Physics.getActiveWorld().updateLocalSurfaceVelocity(node,vec);
    };
};

trait.allowRemoval();
Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
            {
                GUI.TYPE : GUI.TYPE_NUMBER,
                GUI.WIDTH : 100,
                GUI.LABEL : "Mass",
                GUI.DATA_WRAPPER : node.physic_mass
            },
            {GUI.TYPE : GUI.TYPE_NEXT_ROW	},
            {
                GUI.TYPE : GUI.TYPE_NUMBER,
                GUI.WIDTH : 100,
                GUI.LABEL : "Friction",
                GUI.DATA_WRAPPER : node.physic_friction
            },
            {GUI.TYPE : GUI.TYPE_NEXT_ROW	},
            {
                GUI.TYPE : GUI.TYPE_NUMBER,
                GUI.WIDTH : 150,
                GUI.LABEL : "Roll Fric.",
                GUI.DATA_WRAPPER : node.physic_rollingFriction
            },
            {GUI.TYPE : GUI.TYPE_NEXT_ROW	},
            {
                GUI.TYPE : GUI.TYPE_SELECT,
                GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 20, 20],
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
                GUI.WIDTH : 200,
                GUI.LABEL : "LocalSurfaceVelocity",
                GUI.DATA_WRAPPER : node.physic_localSurfaceVelocity

		];
	});
});

return trait;
