/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@uni-paderborn.de>
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
	pathRepeater_update() is called manually or if a property changed.

	Uses the following links:
		repeaterSource		Nodes to be cloned into the node

	Uses the following public members:
		pathRepeater_offset		DataWrapper "x y z" displacementVector as String
		pathRepeater_count			DataWrapper Number of copies
		pathRepeater_update			fn() Re-create the linked nodes (destroys the node's current contents)

	\note Adds the ObjectTraits/NodeLinkTrait to the subject node.
*/
static PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

static TreeQuery = module('LibMinSGExt/TreeQuery');
static createRelativeNodeQuery = fn(MinSG.Node source,MinSG.Node target){
	return TreeQuery.createRelativeNodeQuery(PADrend.getResponsibleSceneManager(source),source,target);
};
static NodeLinkTrait = module('../Basic/NodeLinkTrait');
static PathAnimationTrait = module('../Animation/PathAnimationTrait');
static PathRestrictionTrait = module('../Misc/PathRestrictionTrait');

static LINK_ROLE_REPEATER_SOURCE_NODE = 'repeaterSource';
static LINK_ROLE_PATH_NODE = 'pathNode';
trait.onInit += fn(MinSG.GroupNode node){

	node.pathRepeater_pathNode := new DataWrapper;
	node.pathRepeater_offset := node.getNodeAttributeWrapper('pathRepeater_offset', 1 );
	node.pathRepeater_count := node.getNodeAttributeWrapper('pathRepeater_count', 0 ); // init with 0 so that setting this value initializes the creation process.
	node.pathRepeater_update := fn(...){
		foreach( MinSG.getChildNodes(this) as var c)
			MinSG.destroy(c);
		var path = this.pathRepeater_pathNode();
		if(!path)
			return;
		var startTime = 0; // TODO: something something start time

		// clone source node
		var nodes = new Map;
		foreach(this.getLinkedNodes(LINK_ROLE_REPEATER_SOURCE_NODE) as var source){ //! \see ObjectTraits/Basic/NodeLinkTrait
			nodes[source] = [];
			for(var i=1;i<=this.pathRepeater_count();++i){
				var node2 = source.clone();
				node2.setTempNode(true); // don't save repeated nodes
				this += node2;
				nodes[source] += [node2, i];
			}
		}
		PersistentNodeTrait.initTraitsInSubtree( this );

		// fix node links and transform nodes
		foreach(nodes as var source, var clones) {
			foreach(clones as var entry) {
				// fix relative node links
				if(Traits.queryTrait(entry[0], NodeLinkTrait)) {
					foreach(entry[0].accessLinkedNodes().clone() as var nodeLink) {
						entry[0].removeLinkedNodes(nodeLink.role, nodeLink.query);
					}
					foreach(source.accessLinkedNodes() as var nodeLink) {
						if(!nodeLink.nodes.empty()) {
							var query = createRelativeNodeQuery(entry[0], nodeLink.nodes.front());
							entry[0].addLinkedNodes(nodeLink.role, query);
						}
					}
				}
					
				var transformation = void;				
				// update offsets of path animation trait
				if(Traits.queryTrait(entry[0], PathAnimationTrait)) {
					entry[0].pathOffset(entry[1]*this.pathRepeater_offset());
					transformation = entry[0].getPathWorldTransformation(startTime);
				} else {
					var t = startTime + (entry[1]*this.pathRepeater_offset());
					t %= path.getMaxTime();
					if(t<0)
						t += path.getMaxTime();
					transformation = path.getWorldTransformationSRT() * path.getPosition(t);
				}
				entry[0].setWorldTransformation( transformation );
			}
		}
	};
		
	//! \see ObjectTraits/Basic/NodeLinkTrait
	Std.Traits.assureTrait(node,NodeLinkTrait);


	//! \see ObjectTraits/Helper/NodeLinkTrait
	node.availableLinkRoleNames += LINK_ROLE_REPEATER_SOURCE_NODE;
	node.availableLinkRoleNames += LINK_ROLE_PATH_NODE;

	node.onNodesLinked += [node] => fn(node, role,Array nodes){
		if(role==LINK_ROLE_REPEATER_SOURCE_NODE)
			node.pathRepeater_update();
		if(role==LINK_ROLE_PATH_NODE)
			node.pathRepeater_pathNode(nodes.empty() ? void : nodes.back());
	};
	node.onNodesUnlinked += [node] => fn(node, role,Array nodes){
		if(role==LINK_ROLE_REPEATER_SOURCE_NODE)
			node.pathRepeater_update();
		if(role==LINK_ROLE_PATH_NODE)
			node.pathRepeater_pathNode(void);
	};

	// connect to existing links
	//! \see ObjectTraits/NodeLinkTrait
	if(!node.getLinkedNodes(LINK_ROLE_PATH_NODE).empty())
		node.pathRepeater_pathNode( node.getLinkedNodes(LINK_ROLE_PATH_NODE).back() );

	if(node.pathRepeater_count() > 0 && node.countChildren() == 0)
		node.pathRepeater_update();

	node.pathRepeater_offset.onDataChanged += node->node.pathRepeater_update ;
	node.pathRepeater_count.onDataChanged += node->node.pathRepeater_update ;
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
			GUI.DATA_WRAPPER : node.pathRepeater_offset,
			GUI.LABEL : "Offset",
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
		};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.DATA_WRAPPER : node.pathRepeater_count,
			GUI.LABEL : "Number",
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
		};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ON_CLICK : node->node.pathRepeater_update,
			GUI.LABEL : "Refresh"
		};
		return entries;
	});
});

return trait;
