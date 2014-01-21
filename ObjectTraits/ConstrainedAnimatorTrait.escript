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

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/ConstrainedAnimatorTrait');

trait.onInit += fn(MinSG.Node node){
	//! \see ObjectTraits/ActionPerformerTrait
	@(once) static ActionPerformerTrait = Std.require('ObjectTraits/ActionPerformerTrait');
	if(!Traits.queryTrait(node,ActionPerformerTrait))
		Traits.addTrait(node,ActionPerformerTrait);
	
	//! \see ObjectTraits/AnimatorBaseTrait
	@(once) static AnimatorBaseTrait = Std.require('ObjectTraits/AnimatorBaseTrait');
	if(!Traits.queryTrait(node,AnimatorBaseTrait))
		Traits.addTrait(node,AnimatorBaseTrait);
	
	
	node.animatorSpeed := node.getNodeAttributeWrapper('animatorSpeed',1.0);
	node.animatorMax := node.getNodeAttributeWrapper('animatorMax',1.0);
	node.animatorMin := node.getNodeAttributeWrapper('animatorMin',0.0);
	node.animatorSmoothness := node.getNodeAttributeWrapper('animatorSmoothness',0.3);

	node._animatorSourcePos := false;
	node._animatorSourceTime := false;
	node._animatorTargetPos := false;
	node._animatorTargetTime := false;
	node._animatorPos := new DataWrapper(node.animatorMin());
	node._animatorPos.onDataChanged += node->fn(pos){
		//! \see ObjectTraits/AnimatorBaseTrait
		this.animationCallbacks("play",pos);
	};
	
	node.animatorGoToMin := fn(time=void){		this.animatorGoTo(this.animatorMin(),time);	};
	node.animatorGoToMax := fn(time=void){		this.animatorGoTo(this.animatorMax(),time);	};
	
	
	static handler = fn(...){
		var smoothness = animatorSmoothness();
		var p0 = new Geometry.Vec2(0.0, 0);
		var p1 = new Geometry.Vec2(smoothness, 0);
		var p2 = new Geometry.Vec2(smoothness, 1);
		var p3 = new Geometry.Vec2(1.0, 1);
		
		while( !this.isDestroyed() && this._animatorTargetPos){
			var relTime = (PADrend.getSyncClock()-this._animatorSourceTime) / (_animatorTargetTime-this._animatorSourceTime);

			if(relTime>=1.0){
				var pos = this._animatorTargetPos;
				this._animatorTargetPos = void; // finished
				this._animatorPos(pos);

				//! \see ObjectTraits/AnimatorBaseTrait
				this.animationCallbacks("pause",pos);
				break;
			}else if(relTime>=0.0){
				var smoothedTime = Geometry.interpolateCubicBezier(p0,p1,p2,p3,relTime).y();
				
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
			this.addActionHandler(this->handler);	//! \see ObjectTraits/ActionPerformerTrait
		
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
				GUI.RANGE : [0.0,1.0],
				GUI.LABEL : "pos",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node._animatorPos
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
