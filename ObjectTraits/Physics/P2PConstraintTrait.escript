/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
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

trait.onInit += fn(MinSG.Node node){
    node.__targetNode := new DataWrapper;
    node.__targetAnchorId := node.getNodeAttributeWrapper('p2pTargetAnchor',"anchor#0");
    static roleName = "physic_constraint_targetAnchor";
    static world = Physics.getWorld( node );

    // ---------------------------------------------------------

	//! \see ObjectTraits/PhysicTrait
	Traits.assureTrait(node,module('./PhysicTrait'));

	//! \see ObjectTraits/NodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	// ---------------------------------------------------

	{	// target connection

		//! \see ObjectTraits/NodeLinkTrait
		node.availableLinkRoleNames += roleName;

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesLinked += fn(role,Array nodes){
			if(role==roleName){
				this.__targetNode(nodes.empty() ? void : nodes.back());
				var pivot = this.getAnchor(this.__targetAnchorId());
				if(!pivot)
                    pivot = this.__targetNode().getAnchor(this.__targetAnchorId());
                print_r(pivot);
				world.applyP2PConstraint(this, this.__targetNode(), pivot());
			}
		};
		// connect to existing links
		//! \see ObjectTraits/NodeLinkTrait
		if(!node.getLinkedNodes(roleName).empty()){
            node.__targetNode( node.getLinkedNodes(roleName).back() );
            var pivot = node.getAnchor(node.__targetAnchorId());
				if(!pivot)
                    pivot = node.__targetNode().getAnchor(node.__targetAnchorId());
				world.applyP2PConstraint(node, node.__targetNode(), pivot());
		}


		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesUnlinked += fn(role,Array nodes){
			if(role==roleName)
				this.__targetNode(void);
		};
	}

};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [

			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "targetAnchorId",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.__targetAnchorId,
				GUI.OPTIONS_PROVIDER : [node] => fn(node){
					var entries = [];
					foreach(node.findAnchors() as var name,var anchor)
                        entries += name;
					if(node.__targetNode()){
						foreach(node.__targetNode().findAnchors() as var name,var anchor)
							entries += name;
					}
					return entries;
				}

			},
		];
	});
});

return trait;

