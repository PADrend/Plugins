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

/*! 
	Uses the following links:


	\note Adds the ObjectTraits/NodeLinkTrait to the subject node.
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


static LINK_ROLE_REPEATER_SOURCE_NODE = 'repeaterSource';
trait.onInit += fn(MinSG.GroupNode node){

	node.linearRepeaterDistance := node.getNodeAttributeWrapper('linearRepeaterDistance', "1 0 0" );
	node.linearRepeaterNumber := node.getNodeAttributeWrapper('linearRepeaterNumber', "0" );
	node.updateRepeatedNodes := fn(){
		foreach( MinSG.getChildNodes(this) as var c)
			MinSG.destroy(c);
		var localDir = new Geometry.Vec3( this.linearRepeaterDistance().split(" ")... );
		var worldDir = this.localDirToWorldDir( localDir );
		foreach(this.getLinkedNodes(LINK_ROLE_REPEATER_SOURCE_NODE) as var source){ //! \see ObjectTraits/Basic/NodeLinkTrait
			for(var i=0;i<this.linearRepeaterNumber();++i){
				var node2 = source.clone();
				this += node2;
				node2.moveLocal( node2.worldDirToLocalDir( worldDir*i) );
			}
		}
	};

	//! \see ObjectTraits/Basic/NodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));


	//! \see ObjectTraits/Helper/NodeLinkTrait
	node.availableLinkRoleNames += LINK_ROLE_REPEATER_SOURCE_NODE;
	node.onNodesLinked += [node] => fn(node, role,Array nodes){
		if(role==LINK_ROLE_REPEATER_SOURCE_NODE)
			node.updateRepeatedNodes();
	};
	node.onNodesUnlinked += [node] => fn(node, role,Array nodes){
		if(role==LINK_ROLE_REPEATER_SOURCE_NODE)
			node.updateRepeatedNodes();
	};
	
	// dont't do anything on init; the subtree should be filled already.
	
	node.linearRepeaterDistance.onDataChanged += node->node.updateRepeatedNodes ;
	node.linearRepeaterNumber.onDataChanged += node->node.updateRepeatedNodes ;
};

trait.allowRemoval();

trait.onRemove += fn(node){
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		var entries = [	];
		entries += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.DATA_WRAPPER : node.linearRepeaterDistance,
			GUI.LABEL : "Distance [x y z]",
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
		};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.DATA_WRAPPER : node.linearRepeaterNumber,
			GUI.LABEL : "Number",
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
		};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ON_CLICK : node->node.updateRepeatedNodes,
			GUI.LABEL : "Refresh"
		};
		return entries;
	});
});

return trait;

