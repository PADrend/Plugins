/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*!
    ...

    Links

        Node -- target ------> Node

	Properties
		targetAnchor	String

*/

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

static NodeAnchors = module('LibMinSGExt/NodeAnchors');

static TYPE_P2P = "p2p";
static TYPE_HINGE = "hinge";

trait.onInit += fn(MinSG.Node node){
	//! \see ObjectTraits/PhysicTrait
	Std.Traits.assureTrait(node,module('./PhysicTrait'));

    node.physConstraint_targetNodes := new DataWrapper; // if nodeLinks are used, manual entries get overwritten.
    node.physConstraint_targetAnchorId := node.getNodeAttributeWrapper('phys_conTargetAnchor',"anchor#0");
    node.physConstraint_sourceAnchorId := node.getNodeAttributeWrapper('phys_conSourceAnchor',"anchor#0");
    node.physConstraint_type := node.getNodeAttributeWrapper('phys_conType',TYPE_P2P);
	
	var update = [new Std.DataWrapper([]),node, node.physConstraint_targetNodes, node.physConstraint_targetAnchorId, node.physConstraint_sourceAnchorId]=> fn(priorNodes, node,connectedNodes,targetAnchorId,sourceAnchorId,...){
		var simulationCtxt = node.physic_simulationCtxt();	//! \see ObjectTraits/PhysicTrait
		if(simulationCtxt){
			var world = simulationCtxt.getPhysicsWorld();
			// remove old connections
			foreach(priorNodes() as var node2)
				world.removeConstraintBetweenNodes(node,node2);
			
			var sourcePos = new Geometry.Vec3;
			var sourceDir = new Geometry.Vec3(0,0,1);
			{
				var anchor = NodeAnchors.findAnchor(node,sourceAnchorId());
				if(anchor){
					if(anchor().isA(Geometry.Vec3)){
						sourcePos = anchor();
					}else if(anchor().isA(Geometry.SRT)){
						sourcePos = anchor().getTranslation();
						sourceDir = anchor().getDirVector();
					}
				}
			}
			outln( "sourcePos:",sourcePos, ":",sourceAnchorId() );
			// register new connections
			var targetAId = targetAnchorId();
			foreach(connectedNodes() as var targetNode){
				var localTargetPos = new Geometry.Vec3;
				var localTargetDir = new Geometry.Vec3(0,0,1);
				
				var anchor = NodeAnchors.findAnchor(targetNode,targetAId);
				if(anchor){
					if(anchor().isA(Geometry.Vec3)){
						localTargetPos = anchor();
					}else if(anchor().isA(Geometry.SRT)){
						localTargetPos = anchor().getTranslation();
						localTargetDir = anchor().getDirVector();
					}
				}
				switch( node.physConstraint_type() ){
					case TYPE_P2P:
						world.addConstraint_p2p(targetNode,localTargetPos, node,sourcePos);
						outln( "targetPos:",localTargetPos, ":",targetAId );
						break;
					case TYPE_HINGE:
						world.addConstraint_hinge(targetNode,localTargetPos,localTargetDir, node,sourcePos,sourceDir);
						outln( "Hinge:",localTargetPos, ":",targetAId );
						break;
					default:
						Runtime.warn("Invalid constraint type: "+node.physConstraint_type());
				
				}
			}
			priorNodes( connectedNodes().clone() );
			print_r("Connected nodes:",priorNodes());
			
			node.physics_updateShape(); // trigger update
		}
	};
	
	node.physConstraint_targetNodes.onDataChanged += update;
	node.physConstraint_targetAnchorId.onDataChanged += update;
	node.physConstraint_sourceAnchorId.onDataChanged += update;
	node.physConstraint_type.onDataChanged += update;
	node.physics_updateConstraints := update;

	{	// target connection
		static ROLE_NAME = "physics_constraintLink";
		
		//! \see ObjectTraits/NodeLinkTrait
		Std.Traits.assureTrait(node,module('ObjectTraits/Basic/NodeLinkTrait'));

		//! \see ObjectTraits/NodeLinkTrait
		node.availableLinkRoleNames += ROLE_NAME;

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesLinked += fn( role,Array nodes){
			if(role==ROLE_NAME)
				this.physConstraint_targetNodes( this.getLinkedNodes(ROLE_NAME) );
		};
		// connect to existing links
		//! \see ObjectTraits/NodeLinkTrait
		if(!node.getLinkedNodes(ROLE_NAME).empty()){
            node.physConstraint_targetNodes( node.getLinkedNodes(ROLE_NAME) );
		}

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesUnlinked += fn(role,Array nodes){
			if(role==ROLE_NAME)
				this.physConstraint_targetNodes( this.getLinkedNodes(ROLE_NAME) );		};
	}
	


};

trait.allowRemoval();

module.on('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [

			{
				GUI.TYPE : GUI.TYPE_SELECT,
				GUI.LABEL : "type",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.physConstraint_type,
				GUI.OPTIONS : [ [TYPE_P2P,"Point to point"],[TYPE_HINGE,"Hinge"] ]

			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "sourceAnchorId",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.physConstraint_sourceAnchorId,
				GUI.OPTIONS_PROVIDER : [node] => fn(node){
					var entries = [];
					foreach( NodeAnchors.findAnchors(node) as var name,var anchor)
                        entries += name;
					return entries;
				}

			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "targetAnchorId",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.physConstraint_targetAnchorId,
				GUI.OPTIONS_PROVIDER : [node] => fn(node){
					var entries = [];
//					foreach( NodeAnchors.findAnchors(node) as var name,var anchor)
//                        entries += name;
					if(node.physConstraint_targetNodes()){
						foreach(node.physConstraint_targetNodes() as var node2)
							foreach(NodeAnchors.findAnchors(node2) as var name,var anchor)
								entries += name;
					}
					return entries;
				}

			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Update Constraints",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.ON_CLICK : node.physics_updateConstraints

			},
		];
	});
});

return trait;

