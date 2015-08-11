/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myet@mail.uni-paderborn.de>
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
	//! \see ObjectTraits/Helper/AnimatorBaseTrait
	Traits.assureTrait(node, module('./_AnimatorBaseTrait'));

	//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
	Traits.assureTrait(node, module('../Basic/_ContinuousActionPerformerTrait'));
	
	node.animatorSpeed_high := node.getNodeAttributeWrapper('animatorSpeed_high',1.0);
	node.animatorSpeed_low := node.getNodeAttributeWrapper('animatorSpeed_low',0.0);
	node.animatorFrequency := node.getNodeAttributeWrapper('animatorFrequency',1.0);
	
	node._animatorIsActive := false;
	node._animatorTimer := 0;
	node.animationPlay := fn( startingTime = void ){
		if(!this._animatorIsActive){
			if(!startingTime)
				startingTime = PADrend.getSyncClock();
			this._animatorIsActive = true;
			
			//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
			this.addActionHandler( [startingTime]=>this->fn(startingTime, ...){
				var lastTime = startingTime;
				while( !this.isDestroyed() && this._animatorIsActive){
					var t = PADrend.getSyncClock();
					var high = ((t-startingTime)  % (1/this.animatorFrequency())) <= (1/this.animatorFrequency()*0.5);
					this._animatorTimer += (t-lastTime) * (high ? this.animatorSpeed_high() : this.animatorSpeed_low());
					lastTime = t;
					//! \see ObjectTraits/Helper/AnimatorBaseTrait
					this.animationCallbacks("play",this._animatorTimer);
					yield;
				}
				return $REMOVE;
			});
		}
	};
	
	node.animationPause := fn( time=void ){
		this._animatorIsActive = false;
	};
	node.animationStop := fn( time=void ){
		this._animatorIsActive = false;
		this.animationCallbacks("stop",time ? time : this._animatorTimer);
		this._animatorTimer = 0;
	};
	
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.animationStop();
	node.animationCallbacks.clear(); //! \see ObjectTraits/Helper/AnimatorBaseTrait
	
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ 
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,10],
				GUI.LABEL : "speed high",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorSpeed_high
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,10],
				GUI.LABEL : "speed low",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorSpeed_low
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,10],
				GUI.LABEL : "frequency",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorFrequency
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "stop",
				GUI.WIDTH : 70,
				GUI.ON_CLICK : node->node.animationStop
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "pause",
				GUI.WIDTH : 70,
				GUI.ON_CLICK : node->node.animationPause
			},	
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "play",
				GUI.WIDTH : 70,
				GUI.ON_CLICK : node->node.animationPlay
			},	
		];
	});
});

return trait;
