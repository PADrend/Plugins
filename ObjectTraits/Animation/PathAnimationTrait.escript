/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2015 Mouns Almarrani <murrani@mail.upb.de>
 * Copyright (C) 2015 Sascha Brandt <myeti@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

static LINK_ROLE_PATH_NODE = 'pathNode';
static LINK_ROLE_PATH_RESTRICTOR = 'pathRestrictor';

trait.onInit += fn(MinSG.Node node){
	node.path_pathNode := new DataWrapper;
	node.path_pathRescrictor := new DataWrapper;
	node.animationSpeed := node.getNodeAttributeWrapper('path_animationSpeed', 1 );
	node.repeatAnimation := node.getNodeAttributeWrapper('path_repeatAnimation', false );
	node.pathOffset := node.getNodeAttributeWrapper('path_pathOffset', 0 );
	
	node.getPathTime := fn(time) {
		var path = this.path_pathNode();
		var maxTime = path.getMaxTime();
		var t = (this.animationSpeed() * time) + this.pathOffset();
		var restrictor = this.path_pathRescrictor();
		if(restrictor) {
			var diff = restrictor.pathMax() - restrictor.pathMin();
			t = this.repeatAnimation() ? t % diff : t.clamp(0,diff);
			if(t<0)
				t += diff;
			t += restrictor.pathMin();			
		} 
		t = this.repeatAnimation() ? t % maxTime : t.clamp(0,maxTime);
		if(t<0)
			t += maxTime;
		return t;
	};

	node.getPathWorldTransformation := fn(time) {
		var path = this.path_pathNode();
		var t = this.getPathTime(time);
		//transf.setTranslation(path.localPosToWorldPos(transf.getTranslation()));
		return path.getWorldTransformationSRT() * path.getPosition(t);
	};
	
	//! \see ObjectTraits/NodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	{	// node connection

		//! \see ObjectTraits/NodeLinkTrait
		node.availableLinkRoleNames += LINK_ROLE_PATH_NODE;
		node.availableLinkRoleNames += LINK_ROLE_PATH_RESTRICTOR;

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesLinked += fn(role,Array nodes){
			if(role==LINK_ROLE_PATH_NODE){
				this.path_pathNode(nodes.empty() ? void : nodes.back());
			} else if (role==LINK_ROLE_PATH_RESTRICTOR) {
				this.path_pathRescrictor(nodes.empty() ? void : nodes.back());
				if(this.path_pathRescrictor())
					Traits.assureTrait(this.path_pathRescrictor(), module('../Misc/PathRestrictionTrait'));
			}

			if(this.path_pathNode()) {
				this.setWorldTransformation(this.getPathWorldTransformation(0));
			}
		};
		// connect to existing links
		//! \see ObjectTraits/NodeLinkTrait
		if(!node.getLinkedNodes(LINK_ROLE_PATH_RESTRICTOR).empty()){
      node.path_pathRescrictor( node.getLinkedNodes(LINK_ROLE_PATH_RESTRICTOR).back() );
			if(node.path_pathRescrictor())
				Traits.assureTrait(node.path_pathRescrictor(), module('../Misc/PathRestrictionTrait'));
		}
		if(!node.getLinkedNodes(LINK_ROLE_PATH_NODE).empty()){
    	node.path_pathNode( node.getLinkedNodes(LINK_ROLE_PATH_NODE).back() );
			node.setWorldTransformation(node.getPathWorldTransformation(0));
		}

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesUnlinked += fn(role,Array nodes){
			if(role==LINK_ROLE_PATH_NODE)
				this.path_pathNode(void);
			else if (role==LINK_ROLE_PATH_RESTRICTOR)
				this.path_pathRescrictor(void);
		};
	}

	Traits.assureTrait(node,module('./_AnimatedBaseTrait'));

	//! \see ObjectTraits/Helper/AnimatorBaseTrait
	Traits.assureTrait(node, module('./_AnimatorBaseTrait'));

	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		outln("onAnimationInit (PathAnimationTrait)");
		this.animationCallbacks("play", 0);
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationPlay += fn(time,lastTime){
		if(this.path_pathNode() ---|> MinSG.PathNode){
			this.setWorldTransformation(this.getPathWorldTransformation(time));
			this.animationCallbacks("play", this.getPathTime(time));
		}else outln("No path node selected!");
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationStop += fn(...){
		outln("onAnimationStop (PathAnimationTrait)");
		this.setWorldTransformation(this.getPathWorldTransformation(0));
		this.animationCallbacks("stop", 0);
	};
};

trait.allowRemoval();
trait.onRemove += fn(node){
	this.animationCallbacks("stop", 0);
	node.animationCallbacks.clear(); //! \see ObjectTraits/Helper/AnimatorBaseTrait
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [1,10],
				GUI.LABEL : "speed",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animationSpeed
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "offset",
				GUI.WIDTH : 150,
				GUI.DATA_WRAPPER : node.pathOffset
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Rep. anim.",
				GUI.DATA_WRAPPER : node.repeatAnimation
			}
		];
	});
});

return trait;
