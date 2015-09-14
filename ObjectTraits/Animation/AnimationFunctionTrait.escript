/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.Node node){
	//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
	Traits.assureTrait(node, module('../Basic/_ContinuousActionPerformerTrait'));
		
		//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	Traits.assureTrait(node,module('./_AnimatedBaseTrait'));

	//! \see ObjectTraits/Animation/_AnimatorBaseTrait
	Traits.assureTrait(node, module('./_AnimatorBaseTrait'));
	
	node.__animatorFnInternal := fn(t, lt) { return t; };
	node.animatorFn := node.getNodeAttributeWrapper('animatorFn',"t");
	// sanitize imported string
	node.animatorFn(node.animatorFn().replaceAll("&#38;","&"));
		
	node.animatorFn.onDataChanged += node->fn(fun) {
		try{
			this.__animatorFnInternal = eval( "return fn(t, lt){ return "+fun+";};" );
		}catch(e){
			Runtime.warn(e);
			this.__animatorFnInternal = fn(t, lt) { return t; };
		}
	};
	node.animatorFn.onDataChanged(node.animatorFn());
	
	node._animatorLocalTime := new DataWrapper(0);
		
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		this._animatorLocalTime(this.__animatorFnInternal(time, 0));
		this.animationCallbacks("play", this._animatorLocalTime());
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationPlay += fn(time,lastTime){
		this._animatorLocalTime(this.__animatorFnInternal(time,lastTime));
		this.animationCallbacks("play", this._animatorLocalTime());
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationStop += fn(time,lastTime){
		this._animatorLocalTime(this.__animatorFnInternal(time,lastTime));
		this.animationCallbacks("stop", this._animatorLocalTime());
	};
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.animationCallbacks.clear(); //! \see ObjectTraits/Helper/AnimatorBaseTrait
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [	
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.TOOLTIP : "Function",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorFn
			},	
		];
	});
});

return trait;
