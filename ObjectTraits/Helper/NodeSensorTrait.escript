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

/*! The NodeSensorTrait is a helper trait transforming the node into a sensor for intersecting GeometryNodes.
	Whenever a GeometryNode in the subtree below nodeSensor_rootNode starts intersecting the node's WorldBB,
	moves while intersecting, or stops intersecting, the callbacks nodeSensor_onNodesChanged are notified 
	with an array of the currently intersecting nodes.	
	The following members are added to the given Node:
			
	- node.nodeSensor_rootNode			DataWrapper( Node or void )
	- node.nodeSensor_onNodesChanged	MultiProcedure( Array of GeometryNodes)

	\note Adds the MinSG.NodeAddedObserverTrait to nodeSensor_rootNode.
	\note Adds the MinSG.NodeRemovedObserverTrait to nodeSensor_rootNode.
	\note Adds the MinSG.TransformationObserverTrait to nodeSensor_rootNode and the subject node
*/
static trait = new Traits.GenericTrait('ObjectTraits/Helper/NodeSensorTrait');

trait.onInit += fn(MinSG.Node node){
	
	node.nodeSensor_rootNode := new DataWrapper;
	node.nodeSensor_onNodesChanged := new MultiProcedure;
	node.nodeSensor_observedNodes @(private) := new Set;

	var querySensor = node->fn(rootNode, modifiedNode, ...){
		if(rootNode!=this.nodeSensor_rootNode()||this.isDestroyed()||rootNode.isDestroyed())
			return $REMOVE;
		if(!modifiedNode)
			return;

		var worldBB = this.getWorldBB();
		
		var notify = false;
		if(MinSG.isInSubtree(this,modifiedNode) ){
			notify = true;
		}else{
			foreach(MinSG.collectGeoNodes(modifiedNode) as var alteredGeomNode){
				if(this.nodeSensor_observedNodes.contains(alteredGeomNode)||worldBB.intersects(alteredGeomNode.getWorldBB()) ){
					notify = true;
					break;					
				}
			}
		}
		if(notify){
			var intersectingNodes = MinSG.collectGeoNodesIntersectingBox(rootNode,worldBB);	
			this.nodeSensor_observedNodes = new Set(intersectingNodes);
			this.nodeSensor_onNodesChanged(intersectingNodes);
		}
	};


	node.nodeSensor_rootNode.onDataChanged += [node,querySensor] => fn(node,querySensor, [MinSG.Node,void] rootNode){
		
		if(rootNode){
			var handler = [rootNode] => querySensor;

			//! \see MinSG.NodeAddedObserverTrait
			Traits.assureTraitassureTrait(dolly, Std.require('LibMinSGExt/Traits/NodeAddedObserverTrait'));
			rootNode.onNodeAdded += handler;
			
			//! \see MinSG.NodeRemovedObserverTrait
			Traits.assureTrait(rootNode, Std.require('LibMinSGExt/Traits/NodeRemovedObserverTrait'));
			rootNode.onNodeRemoved += handler;
			
			//! \see MinSG.TransformationObserverTrait
			Traits.assureTrait(rootNode, Std.require('LibMinSGExt/Traits/TransformationObserverTrait'));
			rootNode.onNodeTransformed += handler;
			
			node.onNodeTransformed += handler;
		}
		
	};

	
//		
//	node.nodeSensor_onNodesChanged += fn(nodes){
//		print_r(nodes);
//	};
	
	
};

return trait;
