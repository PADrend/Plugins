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


 /*
     Use global listener, broadcast and time

 */

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.Node node){
	
	//! \see ObjectTraits/Basic/NodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	//! \see ObjectTraits/Basic/_NodeIntersectionSensorTrait
	Traits.assureTrait(node,module('../Basic/_NodeIntersectionSensorTrait'));

	node.onEnterFn := node.getNodeAttributeWrapper('onEnterFn', "animationPlay" );
	node.onLeaveFn := node.getNodeAttributeWrapper('onLeaveFn', "animationPause" );
	node.triggerLinkRole := node.getNodeAttributeWrapper('triggerLinkRole', "switch" );
  node.onEnterFn_params := node.getNodeAttributeWrapper('onEnterFn_params', "['$TIME']" );
  node.onLeaveFn_params := node.getNodeAttributeWrapper('onLeaveFn_params', "['$TIME']" );

	
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
	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += "switch";

	node.triggerState := new DataWrapper(false);	
	node.triggerState.onDataChanged += [node]=>fn(node, value){
		var time = PADrend.getSyncClock();
		//! \see ObjectTraits/NodeLinkTrait
		var nodes = node.getLinkedNodes( node.triggerLinkRole() );

		var fnName = value ? node.onEnterFn() : node.onLeaveFn();
    var params = value ? parseJSON(node.onEnterFn_params()) : parseJSON(node.onLeaveFn_params());

    if(!params || !(params ---|> Array)) {
      Runtime.warn("NodeTriggerTrait: could not parse parameter string: "+ value ? node.onEnterFn_params() : node.onLeaveFn_params());
      params = [];
    }
		for(var i=0; i<params.count(); ++i) {
			if(params[i] == '$TIME')
				params[i] = time;
		}
		
		if(!fnName.empty()){
			foreach(nodes as var node){
				try{
					(node->node.getAttribute(fnName))(params...);
				}catch(e){
					Runtime.warn(e);
				}
			}
		}
	};
	
	//! \see ObjectTraits/Helper/NodeSensorTrait
	node.nodeSensor_onNodesChanged += [node]=>fn(node,Array geomNodes){
		if(node.triggerState() && geomNodes.empty())
			node.triggerState(false);
		else if(!node.triggerState() && !geomNodes.empty())
			node.triggerState(true);
	};

};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.onEnterFn(void);
	node.onLeaveFn(void);
	node.onEnterFn_params(void);
	node.onLeaveFn_params(void);
	node.triggerLinkRole(void);
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "onEnter",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.onEnterFn
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "onEnter parameter",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.onEnterFn_params
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "onLeave",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.onLeaveFn
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "onLeave parameter",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.onLeaveFn_params
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "linkRole",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.triggerLinkRole
			},

		];
	});
});

return trait;
