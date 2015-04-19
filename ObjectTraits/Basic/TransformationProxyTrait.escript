/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

// 	module('LibMinSGExt/NodeAnchors').createAnchor(nodeContainer,'placingPos')(new Geometry.Vec3(0,0,0));

static transformationInProgress = false;
static LINK_ROLE_ABS_DELTA = 'transform';
static LINK_ROLE_REL_DELTA = 'transformRel';
static LINK_ROLE_SNAP = 'transformSnap'; // snap lower center of target's bounding box to proxy's origin(rotation and position)
static LINK_ROLE_SNAP_OFFSET = 'transformSnapOffset';  // preserve the same relative transformation between the proxy and the target.
static LINK_ROLE_SNAP_POS = 'transformSnapPos'; // snap lower center of target's bounding box to proxy's origin (only position)
static LINK_ROLES = [LINK_ROLE_ABS_DELTA,LINK_ROLE_REL_DELTA,LINK_ROLE_SNAP,LINK_ROLE_SNAP_OFFSET,LINK_ROLE_SNAP_POS];

trait.onInit += fn(MinSG.Node node){
	node.transformationProxyEnabled := new DataWrapper(true);
	
	//! \see ObjectTraits/BasicNodeLinkTrait
	Std.Traits.assureTrait(node,module('./NodeLinkTrait'));	
	
	//! \see ObjectTraits/Basic/NodeLinkTrait
	foreach(LINK_ROLES as var role)
		node.availableLinkRoleNames += role;
	
	var transformedNodes = new Map; // node -> [role, originalSRT, ?offsetTransformation_TargetToSource ]
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
	var localToRel_SRT =  node.getRelTransformationSRT();
	localToRel_SRT.setScale(1.0);

	var updateTransformationOffsets = [node,transformedNodes] => fn(sourceNode,transformedNodes){
		var worldToLocalSource_Matrix = sourceNode.getWorldTransformationMatrix().inverse();
		foreach(transformedNodes as var targetNode, var entry){
			if(entry[0]==LINK_ROLE_SNAP_OFFSET){
				var localTargetToWorld_Matrix = targetNode.getWorldTransformationMatrix();
				entry[2] = localTargetToWorld_Matrix * worldToLocalSource_Matrix;
				outln("updateTransformationOffsets: ",entry[2]);
			}else{
				outln(entry[0]);
			}
		}
	};
	
	node.transformationProxyEnabled.onDataChanged += [updateTransformationOffsets]=>fn(updateTransformationOffsets,b){
		if(b)updateTransformationOffsets();
	};
	
	var transformConnectedNodes = [transformedNodes,	localToWorld_SRT.inverse(),	localToRel_SRT.inverse(),	new Std.DataWrapper(false)] => 
								fn(transformedNodes,	lastWorldToLocal_SRT,		lastRelToLocal_SRT,			transformationInProgress, node){
		var localToWorld_SRT = node.getWorldTransformationSRT();
		localToWorld_SRT.setScale(1.0);
		lastWorldToLocal_SRT.setScale(1.0);
		
		var localToRel_SRT = node.getRelTransformationSRT();
		localToRel_SRT.setScale(1.0);
		lastRelToLocal_SRT.setScale(1.0);
		
		if(node.transformationProxyEnabled() && !transformationInProgress()){
			transformationInProgress(true);
			try{

				foreach(transformedNodes as var targetNode, var entry){
					var role = entry[0];
					switch(role){
						case LINK_ROLE_ABS_DELTA:{
							var deltaWorldTransformation = localToWorld_SRT * lastWorldToLocal_SRT;
							var deltaWorldRotation = deltaWorldTransformation.getRotation();
							var targetWorldSRT = targetNode.getWorldTransformationSRT();
							targetWorldSRT.setRotation( deltaWorldRotation * targetWorldSRT.getRotation());
							targetWorldSRT.setTranslation( deltaWorldTransformation * targetWorldSRT.getTranslation() );
							targetNode.setWorldTransformation(targetWorldSRT);
							break;
						}
						case LINK_ROLE_REL_DELTA:{
							var deltaRelTransformation = localToRel_SRT * lastRelToLocal_SRT;
							targetNode.setRelTransformation( targetNode.getRelTransformationSRT() * deltaRelTransformation);
							break;
						}
						case LINK_ROLE_SNAP:{
							var targetWorldSRT = targetNode.getWorldTransformationSRT();
							targetWorldSRT.setRotation( localToWorld_SRT.getRotation() );
							targetNode.setWorldTransformation(targetWorldSRT);
							var targetWorldPosition = targetNode.localPosToWorldPos( targetNode.getBB().getRelPosition(0.5,0,0.5) );
							targetNode.moveLocal( targetNode.worldDirToLocalDir( node.getWorldOrigin()-targetWorldPosition ));
							break;
						}
						case LINK_ROLE_SNAP_OFFSET:{
							var proxy_localToWorldMatrix = new Geometry.Matrix4x4(localToWorld_SRT);
							targetNode.setWorldTransformation( (proxy_localToWorldMatrix*entry[2])._toSRT() );
							break;
						}
						case LINK_ROLE_SNAP_POS:{
							var targetWorldPosition = targetNode.localPosToWorldPos( targetNode.getBB().getRelPosition(0.5,0,0.5) );
							targetNode.moveLocal( targetNode.worldDirToLocalDir( node.getWorldOrigin()-targetWorldPosition ));
							break;
						}
						default: 
							Runtime.warn("TransformationProxyTrait: invalid link role '"+role+"'");
					}
					
				}
			}catch(e){ // finally
				transformationInProgress(false);
				throw(e);
			}
			transformationInProgress(false);
		}
		lastWorldToLocal_SRT.setValue( localToWorld_SRT.inverse() );
		lastRelToLocal_SRT.setValue( localToRel_SRT.inverse() );
		
	};

	//! \see ObjectTraits/Basic/NodeLinkTrait
	node.onNodesLinked += [connectTo,transformConnectedNodes,updateTransformationOffsets] => fn(connectTo,transformConnectedNodes, updateTransformationOffsets,role,Array nodes){
		if( LINK_ROLES.contains(role) ){
			foreach(nodes as var node)
				connectTo(node,role);
			updateTransformationOffsets();
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
		foreach(node.getLinkedNodes(role) as var targetNode)
			connectTo(targetNode,role);
	}
	updateTransformationOffsets();
	transformConnectedNodes(node);
		
	// ------------------
	//! \see  MinSG.TransformationObserverTrait
	Std.Traits.assureTrait(node, module('LibMinSGExt/Traits/TransformationObserverTrait'));
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
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : "Link role info (?)",
				GUI.TOOLTIP : 
					
					"transform \n    apply the proxie's world transformations \n"
					"transformRel \n    apply the proxie's relative transformations \n"
					"transformSnap \n    snap lower center of target's bounding box to proxy's origin(rotation and position) \n"
					"transformSnapOffset \n    preserve the relative transformation between the proxy and the target \n"
					"transformSnapPos \n    snap lower center of target's bounding box to proxy's origin(only position)"
			}
		];
	});
});

return trait;
