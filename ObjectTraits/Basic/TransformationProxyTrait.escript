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


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


static transformationInProgress = false;
static LINK_ROLE_RELATIVE = 'transform';
static LINK_ROLE_SNAP = 'transformSnap'; // snap lower center of bounding boxes(rotation and pos)
static LINK_ROLE_SNAP_POS = 'transformSnapPos'; // snap lower center of bounding boxes (only
static LINK_ROLES = [LINK_ROLE_RELATIVE,LINK_ROLE_SNAP,LINK_ROLE_SNAP_POS];

trait.onInit += fn(MinSG.Node node){
	node.transformationProxyEnabled := new DataWrapper(true);
	
	//! \see ObjectTraits/BasicNodeLinkTrait
	Traits.assureTrait(node,module('./NodeLinkTrait'));	
	
	//! \see ObjectTraits/Basic/NodeLinkTrait
	foreach(LINK_ROLES as var role)
		node.availableLinkRoleNames += role;
	
	var transformedNodes = new Map; // node -> [role, originalSRT ]
	var connectTo = [transformedNodes] => fn(transformedNodes, MinSG.Node newNode,role){
		transformedNodes[newNode] = [role, newNode.getRelTransformationSRT()];
	};
	var disconnectFrom = [transformedNodes] => fn(transformedNodes, MinSG.Node removedNode){
		if(transformedNodes[removedNode]){
			removedNode.setRelTransformation( transformedNodes[removedNode][1] );
			transformedNodes.unset( removedNode );
		}
	};
	
	var localToWorld_SRT =  node.getWorldTransformationSRT();
	localToWorld_SRT.setScale(1.0);

	var transformConnectedNodes = [transformedNodes, localToWorld_SRT.inverse()] => fn(transformedNodes,lastWorldToLocal_SRT, node){
		var localToWorld_SRT = node.getWorldTransformationSRT();
		localToWorld_SRT.setScale(1.0);
		lastWorldToLocal_SRT.setScale(1.0);

		if(node.transformationProxyEnabled() && !transformationInProgress){
			transformationInProgress = true;
			try{
				var relWorldTransformation = localToWorld_SRT * lastWorldToLocal_SRT;
				var relWorldRotation = relWorldTransformation.getRotation();
				var worldLocation = node.localPosToWorldPos( node.getBB().getRelPosition(0.5,0,0.5) );

				foreach(transformedNodes as var cNode, var mixed){
					var role = mixed[0];
					var clientWorldSRT = cNode.getWorldTransformationSRT();

					switch(role){
						case LINK_ROLE_RELATIVE:{
							clientWorldSRT.setRotation( relWorldRotation * clientWorldSRT.getRotation());
							clientWorldSRT.setTranslation( relWorldTransformation * clientWorldSRT.getTranslation() );
							cNode.setWorldTransformation(clientWorldSRT);
							break;
						}
						case LINK_ROLE_SNAP:{
							clientWorldSRT.setRotation( localToWorld_SRT.getRotation() );
							cNode.setWorldTransformation(clientWorldSRT);
							var cWorldPosition = cNode.localPosToWorldPos( cNode.getBB().getRelPosition(0.5,0,0.5) );
							cNode.moveLocal( cNode.worldDirToLocalDir( worldLocation-cWorldPosition ));
							break;
						}
						case LINK_ROLE_SNAP_POS:{
							var cWorldPosition = cNode.localPosToWorldPos( cNode.getBB().getRelPosition(0.5,0,0.5) );
							cNode.moveLocal( cNode.worldDirToLocalDir( worldLocation-cWorldPosition ));
							break;
						}
						default: 
							Runtime.warn("TransformationProxyTrait: invalid link role '"+role+"'");
					}
					
				}
			}catch(e){ // finally
				transformationInProgress = false;
				throw(e);
			}
			transformationInProgress = false;
		}
		lastWorldToLocal_SRT.setValue( localToWorld_SRT.inverse() );
		
	};

	//! \see ObjectTraits/Basic/NodeLinkTrait
	node.onNodesLinked += [connectTo,transformConnectedNodes] => fn(connectTo,transformConnectedNodes, role,Array nodes){
		if( LINK_ROLES.contains(role) ){
			foreach(nodes as var node)
				connectTo(node,role);
			transformConnectedNodes(this);
		}
	};
	
	//! \see ObjectTraits/Basic/NodeLinkTrait
	node.onNodesUnlinked += [disconnectFrom] => fn(disconnectFrom, role,Array nodes){
		if( LINK_ROLES.contains(role) ){
			foreach(nodes as var node)
				disconnectFrom(node);
		}
	};
	
	// connect to existing links

	//! \see ObjectTraits/NodeLinkTrait
	foreach( LINK_ROLES as var role){
		foreach(node.getLinkedNodes(role) as var cNode)
			connectTo(cNode,role);
	}
	transformConnectedNodes(node);
		
	// ------------------
	//! \see  MinSG.TransformationObserverTrait
	Traits.assureTrait(node, module('LibMinSGExt/Traits/TransformationObserverTrait'));
	node.onNodeTransformed += [transformConnectedNodes] => fn(transformConnectedNodes, node){
		if(node==this)
			transformConnectedNodes(this);
	};
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.transformationProxyEnabled(false);
//	node.buttonFn1(void);
//	node.buttonFn2(void);
//	node.buttonLinkRole(void);
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "active",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.transformationProxyEnabled
			},
		];
	});
});

return trait;
