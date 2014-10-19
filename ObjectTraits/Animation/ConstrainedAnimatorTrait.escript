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

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


static simpleSmootTime = fn(relTime,smoothness){
	if(smoothness == 0||relTime<0||relTime>=1.0){
		return relTime;
	}else{
		//! \see http://en.wikipedia.org/wiki/Smoothstep
		var s = relTime*relTime*(3.0-2.0*relTime);
		return smoothness * s + (1.0-smoothness) * relTime;
	}
};

trait.onInit += fn(MinSG.Node node){
	//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
	Traits.assureTrait(node, module('../Basic/_ContinuousActionPerformerTrait'));
	
	//! \see ObjectTraits/Animation/_AnimatorBaseTrait
	Traits.assureTrait(node, module('./_AnimatorBaseTrait'));
	
	
	node.animatorDefaultSpeed := node.getNodeAttributeWrapper('animatorSpeed',1.0);
	node.animatorMax := node.getNodeAttributeWrapper('animatorMax',1.0);
	node.animatorMin := node.getNodeAttributeWrapper('animatorMin',0.0);
	node.animatorSmoothness := node.getNodeAttributeWrapper('animatorSmoothness',0.3);

	node._animatorRepeating := false;
	node._animatorSourceLocalTime := false;
	node._animatorSourceTime := false;
	node._animatorTargetLocalTime := false;
	node._animatorTargetTime := false;
	node._animatorLocalTime := new DataWrapper(node.animatorMin());
	node._animatorLocalTime.onDataChanged += node->fn(localTime){
		//! \see ObjectTraits/Helper/AnimatorBaseTrait
		this.animationCallbacks("play",localTime);
	};
	
	node.animatorGoToMin := fn(time=void){		this.animatorGoTo(this.animatorMin(),time);	};
	node.animatorGoToMax := fn(time=void){		this.animatorGoTo(this.animatorMax(),time);	};
	
	node.animationPlay := fn(startingTime=void){		this.animatorGoTo(this.animatorMax(),startingTime,void,true);	};
		
	static handler = fn(...){
	
		while( !this.isDestroyed() && this._animatorTargetLocalTime){
			var relTime = (PADrend.getSyncClock()-this._animatorSourceTime) / ( this._animatorTargetTime-this._animatorSourceTime);

			if(relTime>=1.0){ //finished
				if(this._animatorRepeating){
					this._animatorSourceLocalTime = this.animatorMin();
					this._animatorTargetLocalTime = this.animatorMax();
					this._animatorSourceTime = this._animatorTargetTime;
					this._animatorTargetTime += (this.animatorMax() - this.animatorMin()) / this.animatorDefaultSpeed();
					
					this._animatorLocalTime(this.animatorMin());
					continue;
				}

				var localTime = this._animatorTargetLocalTime;
				this._animatorTargetLocalTime = void; // finished
				this._animatorLocalTime(localTime);

				//! \see ObjectTraits/Helper/AnimatorBaseTrait
				this.animationCallbacks("pause",localTime);
				break;
			}else if(relTime>=0.0){
				var smoothedTime = simpleSmootTime( relTime,this.animatorSmoothness() );
//				Geometry.interpolateCubicBezier(p0,p1,p2,p3,relTime).y();
				
				var localTime = _animatorTargetLocalTime* smoothedTime + (1 - smoothedTime)*_animatorSourceLocalTime;
				this._animatorLocalTime(localTime);
			}
			yield;
		}
		return $REMOVE;
	};
	
	node.animatorGoTo := fn( Number targetLocalTime, startingTime = void, endTime = void, repeat = false ){
		this._animatorRepeating = repeat;
		
		if(targetLocalTime == _animatorLocalTime() && !repeat)
			return;
		if(!startingTime)
			startingTime = PADrend.getSyncClock();

		this._animatorTargetTime = endTime ? endTime : startingTime + (targetLocalTime-_animatorLocalTime()).abs() / this.animatorDefaultSpeed();
		
		if(!this._animatorTargetLocalTime)
			this.addActionHandler(this->handler);	//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
		
		this._animatorSourceTime = startingTime;
		this._animatorSourceLocalTime = _animatorLocalTime();
		this._animatorTargetLocalTime = targetLocalTime;
	};
	
//	node.animationPlay := fn( time=void ){
//		this._animatorIsActive = false;
//	};
	node.animationStop := fn( time=void ){
		this.animationCallbacks("stop",time ? time : PADrend.getSyncClock());
		this._animatorTargetLocalTime = void;
		this._animatorTargetTime = void;
		this._animatorSourceLocalTime = void;
		this._animatorLocalTime( this.animatorMin() );
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
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.0,node.animatorMax()],
				GUI.LABEL : "localTime",
				GUI.RANGE_STEP_SIZE : 0.05,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node._animatorLocalTime
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,10],
				GUI.LABEL : "speed",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorDefaultSpeed
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.0,1],
				GUI.RANGE_STEP_SIZE : 0.1,
				GUI.LABEL : "smoothness",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorSmoothness
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
				GUI.LABEL : "min",
				GUI.WIDTH : 50,
				GUI.ON_CLICK : node->node.animatorGoToMin
			},	
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "max",
				GUI.WIDTH : 50,
				GUI.ON_CLICK : node->node.animatorGoToMax
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
