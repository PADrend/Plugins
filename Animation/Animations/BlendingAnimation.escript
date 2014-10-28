/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2014 Claudius Jähn <claudius@uni-paderborn.de>
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

static NodeAnimation = module('./NodeAnimation');

// -----------------------------------------------------------------
// BlendingAnimation ---|> NodeAnimation ---|> AnimationBase
static T = new Type(NodeAnimation);

module('../Utils').constructableAnimationTypes["BlendingAnimation"] = T;


Traits.addTrait(T,Traits.PrintableNameTrait,$BlendingAnimation);

T.targetAlpha := 0.5;
T.typeName ::= "BlendingAnimation";


//! (ctor)
T._constructor ::= fn(_name="BlendingAnimation",_startTime=0,_duration=1)@(super(_name,_startTime,_duration)){
	this.__status.originalAlpha := void;
	this.__status.blendingState := void;
};

//! ---|> AnimationBase
T.doEnter @(override) ::= fn(){

	// call base type's function.
	(this->NodeAnimation.doEnter)();

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
//T.doLeave @(override) ::= fn(){
//	// call base type's function.
//	(this->NodeAnimation.doLeave)();
//};

//! ---|> AnimationBase
T.doExecute @(override) ::= fn(Number localTime){
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
T.undo @(override) ::= fn(){
	// call base type's function.
	(this->NodeAnimation.undo)();

//	out(" - ",this.__status.originalAlpha," ... ",this.getTargetAlpha(),"\n");

	// restore original alpha value and unset state
	if(this.__status.blendingState){
		this.__status.blendingState.setBlendConstAlpha(this.__status.originalAlpha);
		this.__status.blendingState = void;
	}
	
};

T.getTargetAlpha ::= fn(){
	return this.targetAlpha;
};

T.setTargetAlpha ::= fn(newTargetAlpha){
	if(newTargetAlpha!=this.targetAlpha){
			
		this.targetAlpha = newTargetAlpha;
		this._updated($TARGET_ALPHA_CHANGED,newTargetAlpha);	

		//  if animation is currently active, apply changes immediately 
		if(this.isActive()){
			this.execute(this.__status.lastTime);
		}
	}
};

PADrend.Serialization.registerType( T, "Animation.BlendingAnimation")
	.initFrom( PADrend.Serialization.getTypeHandler(NodeAnimation) ) //! --|> NodeAnimation
	.addDescriber( fn(ctxt,T obj,Map d){		d['targetAlpha'] = obj.getTargetAlpha();	})
	.addInitializer( fn(ctxt,T obj,Map d){	obj.setTargetAlpha(d['targetAlpha']);	});



// -----------------------------------------------------------------
// GUI

//! ---|> AnimationBase
T.getMenuEntries @(override) := fn(storyBoardPanel){
	// call base type's function.
	var m = (this->NodeAnimation.getMenuEntries)(storyBoardPanel);
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
T.createAnimationBar @(override) ::= fn(storyBoardPanel){
	// call base type's function.
	var animationBar = (this->NodeAnimation.createAnimationBar)(storyBoardPanel);
	
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
return T;
