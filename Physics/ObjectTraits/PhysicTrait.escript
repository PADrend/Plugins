/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static Tools = module('../Tools');

static trait = new PersistentNodeTrait(module.getId());

static ATTR_PHYSIC_MARKER = "$CIs$physicMarker"; // copy but don't save

// helper
trait._collectPhysicNodes := fn(MinSG.Node root){
	return MinSG.collectNodesReferencingAttribute(root,ATTR_PHYSIC_MARKER);
};

trait.onInit += fn( MinSG.Node node){

	node.setNodeAttribute( ATTR_PHYSIC_MARKER,true);

	// properties
	node.physic_linearDamping := node.getNodeAttributeWrapper('physic_linearDamping', 0 );
	node.physic_angularDamping := node.getNodeAttributeWrapper('physic_angularDamping', 0 );
	node.physic_mass := node.getNodeAttributeWrapper('physic_mass', 1 );
	node.physic_isKinematic := node.getNodeAttributeWrapper('physic_kinematic', false );
	node.physic_friction := node.getNodeAttributeWrapper('physic_friction', 0.1 );
	node.physic_rollingFriction := node.getNodeAttributeWrapper('physic_rollingFriction', 0.1 );
	node.physic_localSurfaceVelocity:= node.getNodeAttributeWrapper('physic_localSurfaceVelocity', "0 0 0");
	node.physic_simulationCtxt := new Std.DataWrapper(void);
	node.__simulationCtxt := void;
	
	node.physic_simulationCtxt.onDataChanged += [node] => fn(node, simulationCtxt ){
		if(node.__simulationCtxt){
			Runtime.warn("Changing a node's physics simulation is unimpleneted.");
			return;
		}
		var world = simulationCtxt.getPhysicsWorld();

		world.setAngularDamping( node, node.physic_angularDamping() );
		node.physic_angularDamping.onDataChanged 		+= [world,node]=>fn(world,node,d){	world.setAngularDamping(node,d);					};

		world.setLinearDamping( node, node.physic_linearDamping() );
		node.physic_linearDamping.onDataChanged 		+= [world,node]=>fn(world,node,d){	world.setLinearDamping(node,d);					};

		world.setMass( node, node.physic_mass() );
		node.physic_mass.onDataChanged 					+= [world,node]=>fn(world,node,d){	world.setMass(node,d);					};

		world.setFriction( node, node.physic_friction() );
		node.physic_friction.onDataChanged 				+= [world,node]=>fn(world,node,d){	world.setFriction(node,d);				};
	
		world.markAsKinematicObject( node, node.physic_isKinematic() );
		node.physic_isKinematic.onDataChanged 			+= [world,node]=>fn(world,node,d){	world.markAsKinematicObject(node,d);	};
			
		world.setRollingFriction( node, node.physic_rollingFriction() );
		node.physic_rollingFriction.onDataChanged 		+= [world,node]=>fn(world,node,d){	world.setRollingFriction(node,d);		};

		world.updateLocalSurfaceVelocity(node,new Geometry.Vec3(node.physic_localSurfaceVelocity().split(" ")));
		node.physic_localSurfaceVelocity.onDataChanged	+= [world,node]=>fn(world,node,d){
			world.updateLocalSurfaceVelocity(node,new Geometry.Vec3(d.split(" ")));
		};
		node.physics_updateShape :=  [world,node]=>fn(world,node){	
			@(once) static CollisionShapeTrait = module('./CollisionShapeTrait');
			
			var shapeEntries = []; // [shape,SRT]*
			foreach(CollisionShapeTrait._collectShapeNodes(node) as var shapeNode){
				var worldSRT = shapeNode.getWorldTransformationSRT();
				shapeEntries += [
						shapeNode.physics_createCollisionShape(world),
						new Geometry.SRT(	node.worldPosToLocalPos( worldSRT.getTranslation() ),
											node.worldDirToLocalDir( worldSRT.getDirVector() ),
											node.worldDirToLocalDir( worldSRT.getUpVector() ))
				];
			}
			if(shapeEntries.empty()){
				outln("No CollsionShape found; using BB.");
				world.setShape(node, world.createShape_AABB(node.getBoundingBox()));
			}else{
				world.setShape(node, world.createShape_Composed(shapeEntries) );
			}
		};
		PADrend.planTask(0, node.physics_updateShape ); // wait for all shapes to be ready.

		node.__simulationCtxt = simulationCtxt;
	};
	
	// connection to world
	var simulationCtxt = Tools.queryResposibleSimulationContext(node);
	if(simulationCtxt){
		node.physic_simulationCtxt(simulationCtxt);
	}
};

trait.allowRemoval();
module.on('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			node.physic_simulationCtxt() ? 
				{
					GUI.TYPE : GUI.TYPE_LABEL,
					GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
					GUI.LABEL : "Simulation: "+node.physic_simulationCtxt(),
				} :
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
					GUI.LABEL : "Create/Connect simulation",
					GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
						node.physic_simulationCtxt( Tools.assureSimulationContextAtSceneRoot(node)  );
						refreshCallback();
					}
				}
			,
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Mass",
				GUI.DATA_WRAPPER : node.physic_mass,
				GUI.TOOLTIP : "Mass in kg."
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Is kinematic",
				GUI.DATA_WRAPPER : node.physic_isKinematic,
				GUI.TOOLTIP : "Set to true to animated nodes with mass 0."
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Friction",
				GUI.RANGE : [0,10],
				GUI.RANGE_STEP_SIZE : 0.1,
				GUI.DATA_WRAPPER : node.physic_friction
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Roll Fric.",
				GUI.RANGE : [0,10],
				GUI.RANGE_STEP_SIZE : 0.1,
				GUI.DATA_WRAPPER : node.physic_rollingFriction
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Angular damping",
				GUI.RANGE : [0,1],
				GUI.RANGE_STEP_SIZE : 0.01,
				GUI.DATA_WRAPPER : node.physic_angularDamping
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.RANGE : [0,1],
				GUI.RANGE_STEP_SIZE : 0.01,
				GUI.LABEL : "Linear damping",
				GUI.DATA_WRAPPER : node.physic_linearDamping
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "LocalSurfaceVelocity",
				GUI.DATA_WRAPPER : node.physic_localSurfaceVelocity
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Update Shape",
				GUI.ON_CLICK : [node]=>fn(node){
					if(node.isSet($physics_updateShape)) // method is only available if a simulation has been created.
						node.physics_updateShape();
				}
			},
			{GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.LABEL : "Stop motion",
				GUI.ON_CLICK : [node] => fn(node){
					var simulationCtxt = node.physic_simulationCtxt();
					if(simulationCtxt){
						var world = simulationCtxt.getPhysicsWorld();
						if(world){
							world.setAngularVelocity(node,[0,0,0]);
							world.setLinearVelocity(node,[0,0,0]);
						}
					}
				}
			}

		];
	});
});

return trait;
