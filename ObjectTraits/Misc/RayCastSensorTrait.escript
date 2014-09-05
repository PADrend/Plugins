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

/*! Shoots a ray in local y-up direction and triggers a linked node with the 
	detected distance.

	Uses the following links:
	 - 'rayCastRoot'	(single node) Geometry nodes in this subtree are detected.
	 - 'distance

	\note Adds the ObjectTraits/NodeLinkTrait to the subject node.
	\note Adds the ObjectTraits/Helper/NodeSensorTrait to the subject node.
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


static rayCast = fn(sensorNode,Array geomNodes){
	@(once) static rayCaster = new (module('LibMinSGExt/RendRayCaster'));
	
	geomNodes = geomNodes.clone();
	geomNodes.removeValue(sensorNode);
	
	if(geomNodes.empty())
		return false;

	var source = sensorNode.localPosToWorldPos( sensorNode.getBB().getRelPosition(0.5,0.0,0.5) );
	var target = sensorNode.localPosToWorldPos( sensorNode.getBB().getRelPosition(0.5,1.0,0.5) );
	var d = rayCaster.queryIntersection(frameContext,geomNodes,source,target);
	if(d){
		var length = (d-source).length();
		return length;
	}
	return d;

};

trait.onInit += fn(MinSG.Node node){

	//! \see ObjectTraits/Basic/NodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	//! \see ObjectTraits/Basic/_NodeIntersectionSensorTrait
	Traits.assureTrait(node,module('../Basic/_NodeIntersectionSensorTrait'));


	//! \see ObjectTraits/Helper/NodeLinkTrait
	node.availableLinkRoleNames += 'rayCastRoot';
	node.onNodesLinked += [node] => fn(node, role,Array nodes){
		if(role=='rayCastRoot')
			node.nodeSensor_rootNode(nodes.front());		//! \see ObjectTraits/Helper/NodeSensorTrait
	};
	node.onNodesUnlinked += [node] => fn(node, role,Array nodes){
		if(role=='rayCastRoot')
			node.nodeSensor_rootNode( void );				//! \see ObjectTraits/Helper/NodeSensorTrait
	};
	
	// init already connected nodes
	var exisitingLinks = node.getLinkedNodes('rayCastRoot');
	if(!exisitingLinks.empty()){
		node.nodeSensor_rootNode(exisitingLinks.front());	//! \see ObjectTraits/Helper/NodeSensorTrait
	}
	
	//! \see ObjectTraits/Helper/NodeSensorTrait
	node.nodeSensor_onNodesChanged += [node]=>fn(node,Array geomNodes){
		print_r(rayCast(node,geomNodes));
	};
	
};

trait.allowRemoval();

trait.onRemove += fn(node){
	node.nodeSensor_rootNode( void );	//! \see ObjectTraits/Helper/NodeSensorTrait
	// remove links?
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		var entries = [	];
		return entries;
	});
});

return trait;

