/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/Animations/BlendingAnimation.escript
 ** 2011-04 Claudius
 **
 ** BlendingAnimation-Type
 ** Search for a BlendingState at the attached node and alter the alpha value.
 **/

loadOnce(__DIR__+"/NodeAnimation.escript");

// -----------------------------------------------------------------
// BlendingAnimation ---|> NodeAnimation ---|> AnimationBase
Animation.BlendingAnimation := new Type(Animation.NodeAnimation);
var BlendingAnimation = Animation.BlendingAnimation;
Traits.addTrait(BlendingAnimation,Traits.PrintableNameTrait,$BlendingAnimation);

BlendingAnimation.targetAlpha := 0.5;
BlendingAnimation.typeName ::= "BlendingAnimation";

Animation.constructableAnimationTypes["BlendingAnimation"] = BlendingAnimation;

//! (ctor)
BlendingAnimation._constructor ::= fn(_name="BlendingAnimation",_startTime=0,_duration=1)@(super(_name,_startTime,_duration)){
	this.__status.originalAlpha := void;
	this.__status.blendingState := void;
};

//! ---|> AnimationBase
BlendingAnimation.doEnter ::= fn(){

	// call base type's function.
	(this->Animation.NodeAnimation.doEnter)();

	var node = this.getNode();
	if(!node)
		return;

	var newBlendingState;

	var states = node.getStates();
	foreach(states as var state){
		if(state---|>MinSG.BlendingState){
			newBlendingState = state;
			break;
		}
	}
	if(!newBlendingState){
		Runtime.warn("Node has no blending state: '"+this.getNodeId()+"'");
		this.__status.originalAlpha = void;
		this.__status.blendingState = void;
		return;
	}
	// found new blending state, store state and original alpha value
	if(newBlendingState!=this.__status.blendingState){
		this.__status.blendingState = newBlendingState;
		this.__status.originalAlpha = newBlendingState.getBlendConstAlpha();
	}
};
//
////! ---|> AnimationBase
//BlendingAnimation.doLeave ::= fn(){
//	// call base type's function.
//	(this->Animation.NodeAnimation.doLeave)();
//};

//! ---|> AnimationBase
BlendingAnimation.doExecute ::= fn(Number localTime){
	if(!this.__status.blendingState)
		return;
	if(duration==0)
		this.__status.blendingState.setBlendConstAlpha(this.targetAlpha );
	else{
		var t = localTime / duration;
		this.__status.blendingState.setBlendConstAlpha( t*this.targetAlpha + (1.0-t) * this.__status.originalAlpha );
	}
	
};

//! ---|> AnimationBase
BlendingAnimation.undo ::= fn(){
	// call base type's function.
	(this->Animation.NodeAnimation.undo)();

//	out(" - ",this.__status.originalAlpha," ... ",this.getTargetAlpha(),"\n");

	// restore original alpha value and unset state
	if(this.__status.blendingState){
		this.__status.blendingState.setBlendConstAlpha(this.__status.originalAlpha);
		this.__status.blendingState = void;
	}
	
};

BlendingAnimation.getTargetAlpha ::= fn(){
	return this.targetAlpha;
};

BlendingAnimation.setTargetAlpha ::= fn(newTargetAlpha){
	if(newTargetAlpha!=this.targetAlpha){
			
		this.targetAlpha = newTargetAlpha;
		this._updated($TARGET_ALPHA_CHANGED,newTargetAlpha);	

		//  if animation is currently active, apply changes immediately 
		if(this.isActive()){
			this.execute(this.__status.lastTime);
		}
	}
};

PADrend.Serialization.registerType( Animation.BlendingAnimation, "Animation.BlendingAnimation")
	.initFrom( PADrend.Serialization.getTypeHandler(Animation.NodeAnimation) ) //! --|> NodeAnimation
	.addDescriber( fn(ctxt,Animation.BlendingAnimation obj,Map d){		d['targetAlpha'] = obj.getTargetAlpha();	})
	.addInitializer( fn(ctxt,Animation.BlendingAnimation obj,Map d){	obj.setTargetAlpha(d['targetAlpha']);	});



// -----------------------------------------------------------------
// GUI

//! ---|> AnimationBase
BlendingAnimation.getMenuEntries := fn(storyBoardPanel){
	// call base type's function.
	var m = (this->Animation.NodeAnimation.getMenuEntries)(storyBoardPanel);
	m+="----";
	m+={
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Target alpha",
		GUI.WIDTH : 150,
		GUI.DATA_VALUE : this.getTargetAlpha(),
		GUI.ON_DATA_CHANGED : this->fn(data){
			this.setTargetAlpha(data);
		}
	};
	m+={
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "duration",
		GUI.WIDTH : 150,
		GUI.DATA_VALUE : this.getDuration(),
		GUI.ON_DATA_CHANGED : this->fn(data){
			this.setDuration(data);
		}
	};
	return m;
};

//! ---|> AnimationBase
BlendingAnimation.createAnimationBar ::= fn(storyBoardPanel){
	// call base type's function.
	var animationBar = (this->Animation.NodeAnimation.createAnimationBar)(storyBoardPanel);
	
	// duration
	animationBar.durationGrabber := gui.create({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "",
		GUI.WIDTH : 4,
		GUI.HEIGHT : 6,
		GUI.DRAGGING_ENABLED : true,
		GUI.ON_DRAG : animationBar->fn(evt){
			this.animation.setDuration( this.animation.getDuration()+this.storyBoardPanel.getTimeForPosition(evt.deltaX*0.5) );
		},
		GUI.TOOLTIP : "Blending duration\nAdjust by dragging."
	});
	animationBar.durationGrabber.setButtonShape(GUI.BUTTON_SHAPE_TOP_RIGHT);
	animationBar += animationBar.durationGrabber;
	
	animationBar.refresh = [animationBar,animationBar.refresh]->fn(){
		// call original refresh method
		(this[0]->this[1]) ();
		this[0].durationGrabber.setPosition( new Geometry.Vec2(this[0].storyBoardPanel.getPositionForTime(this[0].animation.getDuration()),17 ));
	};
	return animationBar;
//	storyBoardPanel->storyBoardPanel.getTimeForPosition(evt.deltaX*0.5)
	
};
