/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2015 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.GroupNode node){

	node.stateContainer := node.getNodeAttributeWrapper('stateAnmiation_stateId', "" ); // enthält den MaterialState
	node.state_animationSpeed := node.getNodeAttributeWrapper('stateAnmiation_animationSpeed', 1 );
	var activeNode = new Std.DataWrapper;

	activeNode.onDataChanged += [new Std.MultiProcedure, node.stateContainer] => fn(revoce,stateContainer, node){
		revoce();
		var state = PADrend.getSceneManager().getRegisteredState(stateContainer());
		if(state){
			if(node && !node.isDestroyed())
				revoce+=Std.addRevocably(node, state);
		}
		else
			PADrend.message("No state with the ID ",stateContainer(), " is existed" );

	};

	Std.Traits.assureTrait(node,module('./_AnimatedBaseTrait'));

	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		outln("onAnimationInit (StateAnimationTrait)");
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationPlay += [activeNode]=>fn(activeNode,time,lastTime){
		var children = MinSG.getChildNodes(this);
		activeNode( children[ (time * this.state_animationSpeed()).floor()%children.count() ] );

	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationStop += [activeNode]=>fn(activeNode,...){
		outln("onAnimationStop (StateAnimationTrait)");
		activeNode(void);
	};
};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [1,10],
				GUI.LABEL : "m/sek",
				GUI.WIDTH : 200,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.state_animationSpeed
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
				GUI.LABEL : "StateId",
				GUI.OPTIONS_PROVIDER : fn(){
						return PADrend.getSceneManager().getNamesOfRegisteredStates();
					},
				GUI.DATA_WRAPPER : node.stateContainer
			},
		];
	});
});

return trait;

