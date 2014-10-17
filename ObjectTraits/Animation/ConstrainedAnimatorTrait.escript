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
	
	
	node.animatorSpeed := node.getNodeAttributeWrapper('animatorSpeed',1.0);
	node.animatorMax := node.getNodeAttributeWrapper('animatorMax',1.0);
	node.animatorMin := node.getNodeAttributeWrapper('animatorMin',0.0);
	node.animatorSmoothness := node.getNodeAttributeWrapper('animatorSmoothness',0.3);
	node.animatorRepeat := node.getNodeAttributeWrapper('animatorRepeat',false);

	node._animatorSourcePos := false;
	node._animatorSourceTime := false;
	node._animatorTargetPos := false;
	node._animatorTargetTime := false;
	node._animatorPos := new DataWrapper(node.animatorMin());
	node._animatorPos.onDataChanged += node->fn(pos){
		//! \see ObjectTraits/Helper/AnimatorBaseTrait
		this.animationCallbacks("play",pos);
	};
	
	node.animatorGoToMin := fn(time=void){		this.animatorGoTo(this.animatorMin(),time);	};
	node.animatorGoToMax := fn(time=void){		this.animatorGoTo(this.animatorMax(),time);	};
	
	
	static handler = fn(...){
	
		while( !this.isDestroyed() && this._animatorTargetPos){
			var relTime = (PADrend.getSyncClock()-this._animatorSourceTime) / (_animatorTargetTime-this._animatorSourceTime);

			if(relTime>=1.0){
//				if(this.animatorRepeat()){
//					this._animatorTargetTime += this.animatorMax();
//					this._animatorSourceTime += this.animatorMax();
//					this._animatorPos( 0 );
//					continue;
//				}

				var pos = this._animatorTargetPos;
				this._animatorTargetPos = void; // finished
				this._animatorPos(pos);

				//! \see ObjectTraits/Helper/AnimatorBaseTrait
				this.animationCallbacks("pause",pos);
				break;
			}else if(relTime>=0.0){
				var smoothedTime = simpleSmootTime( relTime,this.animatorSmoothness() );
//				Geometry.interpolateCubicBezier(p0,p1,p2,p3,relTime).y();
				
				var pos = _animatorTargetPos* smoothedTime + (1 - smoothedTime)*_animatorSourcePos;
				this._animatorPos(pos);
			}
			yield;
		}
		return $REMOVE;
	};
	
	node.animatorGoTo := fn( Number targetPosition, startingTime = void, endTime = void ){
		if(targetPosition == _animatorPos())
			return;
		if(!startingTime)
			startingTime = PADrend.getSyncClock();

		this._animatorTargetTime = endTime ? endTime : startingTime + (targetPosition-_animatorPos()).abs() / this.animatorSpeed();
		
		if(!this._animatorTargetPos)
			this.addActionHandler(this->handler);	//! \see ObjectTraits/Basic/_ContinuousActionPerformerTrait
		
		this._animatorSourceTime = startingTime;
		this._animatorSourcePos = _animatorPos();
		this._animatorTargetPos = targetPosition;
	};
	
//	node.animationPlay := fn( time=void ){
//		this._animatorIsActive = false;
//	};
	node.animationStop := fn( time=void ){
		this.animationCallbacks("stop",time ? time : PADrend.getSyncClock());
		this._animatorTargetPos = void;
		this._animatorTargetTime = void;
		this._animatorSourcePos = void;
		this._animatorPos( this.animatorMin() );
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
				GUI.LABEL : "pos",
				GUI.RANGE_STEP_SIZE : 0.05,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node._animatorPos
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,10],
				GUI.LABEL : "speed",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorSpeed
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
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "repeat",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animatorRepeat
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
				GUI.LABEL : "min",
				GUI.WIDTH : 70,
				GUI.ON_CLICK : node->node.animatorGoToMin
			},	
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "max",
				GUI.WIDTH : 70,
				GUI.ON_CLICK : node->node.animatorGoToMax
			},	
		];
	});
});

return trait;
