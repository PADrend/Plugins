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

/*! 
	Replaces the content of a group node with multiple copies of linked nodes. 
	The copies are iteratively transformed with a given translation vector.
	The nodes are not created automatically when the trait is initialized but only if 
	linearRepeater_update() is called manually or if a property changed.
		
	Uses the following links:
		repeaterSource		Nodes to be cloned into the node

	Uses the following public members:
		linearRepeater_displacement		DataWrapper "x y z" displacementVector as String
		linearRepeater_count			DataWrapper Number of copies
		linearRepeater_update			fn() Re-create the linked nodes (destroys the node's current contents)

	\note Adds the ObjectTraits/NodeLinkTrait to the subject node.
*/
static PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


static LINK_ROLE_REPEATER_SOURCE_NODE = 'repeaterSource';
trait.onInit += fn(MinSG.GroupNode node){

	node.linearRepeater_displacement := node.getNodeAttributeWrapper('linearRepeater_displacement', "1 0 0" );
	node.linearRepeater_count := node.getNodeAttributeWrapper('linearRepeater_count', 0 ); // init with 0 so that setting this value initializes the creation process.
	node.linearRepeater_update := fn(...){
		foreach( MinSG.getChildNodes(this) as var c)
			MinSG.destroy(c);
		var localDir = new Geometry.Vec3( this.linearRepeater_displacement().split(" ")... );
		var worldDir = this.localDirToWorldDir( localDir );
		foreach(this.getLinkedNodes(LINK_ROLE_REPEATER_SOURCE_NODE) as var source){ //! \see ObjectTraits/Basic/NodeLinkTrait
			for(var i=1;i<=this.linearRepeater_count();++i){
				var node2 = source.clone();
				this += node2;
				node2.moveLocal( node2.worldDirToLocalDir( worldDir*i) );
			}
		}
		PersistentNodeTrait.initTraitsInSubtree( this );

	};

	//! \see ObjectTraits/Basic/NodeLinkTrait
	Std.Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));


	//! \see ObjectTraits/Helper/NodeLinkTrait
	node.availableLinkRoleNames += LINK_ROLE_REPEATER_SOURCE_NODE;
	node.onNodesLinked += [node] => fn(node, role,Array nodes){
		if(role==LINK_ROLE_REPEATER_SOURCE_NODE)
			node.linearRepeater_update();
	};
	node.onNodesUnlinked += [node] => fn(node, role,Array nodes){
		if(role==LINK_ROLE_REPEATER_SOURCE_NODE)
			node.linearRepeater_update();
	};
	
	// dont't do anything on init; the subtree should be filled already.
	
	node.linearRepeater_displacement.onDataChanged += node->node.linearRepeater_update ;
	node.linearRepeater_count.onDataChanged += node->node.linearRepeater_update ;
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
			GUI.DATA_WRAPPER : node.linearRepeater_displacement,
			GUI.LABEL : "Distance [x y z]",
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
		};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.DATA_WRAPPER : node.linearRepeater_count,
			GUI.LABEL : "Number",
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
		};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ON_CLICK : node->node.linearRepeater_update,
			GUI.LABEL : "Refresh"
		};
		return entries;
	});
});

return trait;

