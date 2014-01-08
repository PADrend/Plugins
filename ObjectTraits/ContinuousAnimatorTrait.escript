/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/ContinuousAnimatorTrait');

trait.onInit += fn(MinSG.Node node){
	@(once) static AnimatorBaseTrait = Std.require('ObjectTraits/AnimatorBaseTrait');
	
	if(!Traits.queryTrait(node,AnimatorBaseTrait))
		Traits.addTrait(node,AnimatorBaseTrait);
	
	
	node.animatorSpeed := new DataWrapper(  node.getNodeAttribute("animatorSpeed"); );
	if(!node.animatorSpeed())
		node.animatorSpeed(1.0);
	node.animatorSpeed.onDataChanged += [node] => fn(node,speed){
		node.setNodeAttribute("animatorSpeed",speed);
	};
	
	node._animatorIsActive := false;
	node._animatorTimer := 0;
	node.animationPlay := fn(){
		if(!this._animatorIsActive){
			this._animatorIsActive = true;
			
			Util.registerExtension( 'PADrend_AfterFrame', this->fn(...){
				var lastTime = PADrend.getSyncClock();
				while( !this.isDestroyed() && this._animatorIsActive){
					var t = PADrend.getSyncClock();
					this._animatorTimer += (t-lastTime)*this.animatorSpeed();
					lastTime = t;
					//! \see ObjectTraits/AnimatorBaseTrait
					this.animationCallbacks("play",this._animatorTimer);
					yield;
				}
				return $REMOVE;
			});
		}
	};
	
	node.animationPause := fn(){
		this._animatorIsActive = false;
	};
	node.animationStop := fn(){
		this._animatorIsActive = false;
		this.animationCallbacks("stop",this._animatorTimer);
		this._animatorTimer = 0;
	};
	
};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.animationStop();
	node.animationCallbacks.clear(); //! \see ObjectTraits/AnimatorBaseTrait
	
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ "Animator",
			{
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Remove trait",
				GUI.LABEL : "-",
				GUI.WIDTH : 20,
				GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
					if(Traits.queryTrait(node,trait))
						Traits.removeTrait(node,trait);
					refreshCallback();
				}
			},		
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,10],
				GUI.LABEL : "speed",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animatorSpeed
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
