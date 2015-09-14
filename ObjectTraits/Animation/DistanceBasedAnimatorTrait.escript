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
	
	//! \see ObjectTraits/Animation/_AnimatorBaseTrait
	Traits.assureTrait(node, module('./_AnimatorBaseTrait'));
	
	node.animatorMax := node.getNodeAttributeWrapper('animatorMax',1.0);
	node.animatorMin := node.getNodeAttributeWrapper('animatorMin',0.0);
	
	node.maxDistance := node.getNodeAttributeWrapper('maxDistance',1.0);
	node.minDistance := node.getNodeAttributeWrapper('minDistance',0.0);
	
	node.autoStart := node.getNodeAttributeWrapper('autoStart',false);	
	node.useBoundingBox := node.getNodeAttributeWrapper('useBoundingBox',false);
	
	node._animatorLocalTime := new DataWrapper(node.animatorMin());
	node._animatorLocalTime.onDataChanged += node->fn(localTime){
		//! \see ObjectTraits/Helper/AnimatorBaseTrait
		this.animationCallbacks("play",localTime);
	};
	
	
	node._animatorIsActive := false;
	
	node.animationPlay := fn( ... ){
		if(!this._animatorIsActive){
			this._animatorIsActive = true;
			
			//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
			this.addActionHandler( this->fn(...){
				var lastTime = this._animatorLocalTime();
				while( !this.isDestroyed() && this._animatorIsActive){				
					var camera = PADrend.getActiveCamera();
					var dist = this.useBoundingBox() ?
						this.getWorldBB().getDistance(camera.getWorldPosition()) :
						this.getWorldPosition().distance(camera.getWorldPosition());
					
					var relTime = (dist-this.minDistance()) / (this.maxDistance()-this.minDistance()) * (this.animatorMax()-this.animatorMin()) - this.animatorMin();
					relTime = relTime.clamp(this.animatorMin(), this.animatorMax());
					
					if(relTime != lastTime)
						this._animatorLocalTime(relTime);
					lastTime = relTime;
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
		this.animationCallbacks("stop",this._animatorLocalTime());
	};
			
	if(node.autoStart())
		node.animationPlay();
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
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "autostart",
				GUI.SIZE : [GUI.WIDTH_FILL_REL | GUI.HEIGHT_ABS,0.5,15 ],
				GUI.DATA_WRAPPER : node.autoStart
			},	
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "use bounding box",
				GUI.SIZE : [GUI.WIDTH_FILL_REL | GUI.HEIGHT_ABS,0.5,15 ],
				GUI.DATA_WRAPPER : node.useBoundingBox
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "min",
				GUI.SIZE : [GUI.WIDTH_FILL_REL | GUI.HEIGHT_ABS,0.5,15 ],
				GUI.DATA_WRAPPER : node.animatorMin
			},	
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "max",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorMax
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Distance min",
				GUI.SIZE : [GUI.WIDTH_FILL_REL | GUI.HEIGHT_ABS,0.5,15 ],
				GUI.DATA_WRAPPER : node.minDistance
			},	
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "max",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.maxDistance
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "stop",
				GUI.WIDTH : 50,
				GUI.ON_CLICK : node->node.animationStop
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "play",
				GUI.WIDTH : 50,
				GUI.ON_CLICK : node->node.animationPlay
			},	
		];
	});
});

return trait;
