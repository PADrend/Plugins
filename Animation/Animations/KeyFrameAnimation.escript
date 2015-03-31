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
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/Animations/KeyFrameAnimation.escript
 ** 2011-04 Claudius
 **
 ** KeyFrameAnimation-Type
 **/

static NodeAnimation = module('./NodeAnimation');

// -----------------------------------------------------------------
// KeyFrameAnimation ---|> NodeAnimation ---|> AnimationBase
static T = new Type(NodeAnimation);

module('../Utils').constructableAnimationTypes["KeyFrameAnimation"] = T;

Traits.addTrait(T,Traits.PrintableNameTrait,$KeyFrameAnimation);

T.keyFrames := void;
T.typeName ::= "KeyFrameAnimation";

// ----------------------------------------------------------
static KeyFrame = new Type;
KeyFrame.srt := void;
KeyFrame.time := 0;
//! (ctor) KeyFrame
KeyFrame._constructor ::= fn(_time=0.0,Geometry.SRT _srt=new Geometry.SRT()){
	this.time = _time;
	this.srt = _srt;
//	out("####\n");
};
T.KeyFrame ::= T;
// ----------------------------------------------------------



//! (ctor)
T._constructor ::= fn(_name="KeyFrameAnimation",_startTime=0,_duration=1)@(super(_name,_startTime,_duration)){
	this.__status.originalSRT := void;
	this.keyFrames = [];
	
//	this.insertKeyFrame(1.0,new Geometry.SRT());
};

//! ---|> AnimationBase
T.doEnter @(override)  ::= fn(){

	// call base type's function.
	(this->NodeAnimation.doEnter)();

	var node = this.getNode();
	if(!node)
		return;

	if(!this.__status.originalSRT)
		this.__status.originalSRT = node.getRelTransformationSRT(); 
};
//
////! ---|> AnimationBase
//T.doLeave ::= fn(){
//	// call base type's function.
//	(this->NodeAnimation.doLeave)();
//};

//! ---|> AnimationBase
T.doExecute @(override)  ::= fn(Number localTime){
	if(!this.__status.node || this.keyFrames.empty() || !this.__status.originalSRT )
		return;

	// search for keyframes before and after (by linear search)
	var keyFrame1;
	var keyFrame2;
	foreach(this.keyFrames as var keyFrame){
		keyFrame1 = keyFrame2;
		keyFrame2 = keyFrame;
		if(keyFrame.time>localTime)
			break;
	}
	var time1;
	var srt1;
	if(keyFrame1){
		time1 = keyFrame1.time;
		srt1 = keyFrame1.srt;
	}else{
		time1 = 0;
		srt1 = this.__status.originalSRT;
	}
	
	// interpolate position
	var tDiff = keyFrame2.time-time1;
	if(tDiff<=0){
		this.__status.node.setRelTransformation(keyFrame2.srt );
	}else{
		this.__status.node.setRelTransformation(new Geometry.SRT(srt1,keyFrame2.srt, (localTime-time1)/tDiff ));
	}
};

T.getKeyFrame ::= fn(index){
	return this.keyFrames[index];
};

T.insertKeyFrame ::= fn( time, Geometry.SRT srt){
	foreach(this.keyFrames as var kf){
		if(kf.time == time){
			Runtime.warn("There is already a key frame at "+time+"s.");
			return;
		}
	}
	
	this.keyFrames += void;
	// move all later key frames
	var i;
	for(i=this.keyFrames.count()-2;i>=0;--i){
		if(this.keyFrames[i].time<time)
			break;
		this.keyFrames[i+1] = this.keyFrames[i];
	}
	++i;
	this.keyFrames[i] = new KeyFrame;
	
	this.setKeyFrame(i,time,srt);
};

T.removeKeyFrame ::= fn( index){
	if(!this.keyFrames[index])
		return;
	
	this.keyFrames.removeIndex(index);
	this._updated($KEY_FRAME_REMOVED,void);
	
	//  if animation is currently active, apply changes immediately 
	if(this.isActive()){
		this.execute(this.__status.lastTime);
	}
};

//! ---|> AnimationBase
T.undo @(override) ::= fn(){
	// restore original srt and unset values
	if(this.__status.node && this.__status.originalSRT){
		
		this.__status.node.setRelTransformation(this.__status.originalSRT);
		this.__status.originalSRT = void;
	}
	// call base type's function.
	(this->NodeAnimation.undo)();
};


T.setKeyFrame ::= fn( index, time, Geometry.SRT srt){
	if(index >= this.keyFrames.count()){
		Runtime.warn();
		return;
	}
	var kf = this.keyFrames[index];
	kf.srt = srt.clone();

	if(time<0)
		time = 0;

	// ordering not violated?
	if( (index==0 || time>=this.keyFrames[index-1].time) && (index>=this.keyFrames.count()-1 || time<this.keyFrames[index+1].time) ){
		kf.time = time;
		if(index == this.keyFrames.count()-1)
			this.setDuration(time);
	}
	
	this._updated($KEY_FRAME_CHANGED,kf);

	//  if animation is currently active, apply changes immediately 
	if(this.isActive()){
		this.execute(this.__status.lastTime);
	}
};


PADrend.Serialization.registerType( KeyFrame, "Animation.KeyFrameAnimation.KeyFrame")
	.addDescriber( fn(ctxt,KeyFrame obj,Map d){
		d['time'] = obj.time;
		d['srt'] = ctxt.createDescription(obj.srt);
	})
	.setFactory( fn(ctxt,type,Map d){
		return new type( d['time'],ctxt.createObject(d['srt']));
	});


PADrend.Serialization.registerType( T, "Animation.KeyFrameAnimation")
	.initFrom( PADrend.Serialization.getTypeHandler(NodeAnimation) ) //! --|> NodeAnimation
	.addDescriber( fn(ctxt, T obj,Map d){		d['keyFrames'] = ctxt.createDescription(obj.keyFrames);	})
	.addInitializer( fn(ctxt, T obj,Map d){	obj.keyFrames = ctxt.createObject(d['keyFrames']);	});

// -----------------------------------------------------------------
// GUI

//! ---|> AnimationBase
T.getMenuEntries @(override) := fn(storyBoardPanel){
	// call base type's function.
	var m = (this->NodeAnimation.getMenuEntries)(storyBoardPanel);
	m+="----";
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Add keyframe",
		GUI.TOOLTIP : "Add a new keyframe at current playback time.\nNote: Only works if current playback time is after the starting time.",
		GUI.WIDTH : 150,
		GUI.ON_CLICK : [this,storyBoardPanel]->fn(){
			var animation = this[0];
			var storyBoardPanel = this[1];
			var insertionTime = storyBoardPanel.playbackContext ? storyBoardPanel.playbackContext.getCurrentTime()-animation.getStartTime() :
				 animation.__status.lastTime;
			if(insertionTime<0){
				Runtime.warn("New keyframes can only be added after the starting time");
				return;
			}

			var srt = animation.__status.node ? animation.__status.node.getRelTransformationSRT() : new Geometry.SRT();
			animation.insertKeyFrame(insertionTime,srt);
		}
	};

	return m;
};

//! ---|> AnimationBase
T.createAnimationBar @(override) ::= fn(storyBoardPanel){
	// call base type's function.
	var animationBar = (this->NodeAnimation.createAnimationBar)(storyBoardPanel);
	
	animationBar.grabbers := [];
	animationBar.refresh = [animationBar,animationBar.refresh]->fn(){
		var animationBar = this[0];
		// call original refresh method
		(animationBar->this[1]) ();
		
		if(animationBar.grabbers.count() != animationBar.animation.keyFrames.count()){
			while(animationBar.grabbers.count() < animationBar.animation.keyFrames.count()){
				var index = animationBar.grabbers.count();
				var grabber = gui.create({
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "",
					GUI.WIDTH : 4,
					GUI.HEIGHT : 6,
					GUI.BUTTON_SHAPE : GUI.BUTTON_SHAPE_TOP_RIGHT,
					GUI.ON_INIT : [index,animationBar] => fn(index,animationBar){
						this.index := index;
						this.animationBar := animationBar;
					},
					GUI.DRAGGING_ENABLED : true,
					GUI.ON_DRAG : fn(evt){
						var animation  = this.animationBar.animation;
						var storyBoardPanel  = this.animationBar.storyBoardPanel;
						var kf = animation.getKeyFrame(this.index);
						animation.setKeyFrame(this.index, 
							kf.time+storyBoardPanel.getTimeForPosition(evt.deltaX*0.5), kf.srt);
						if(storyBoardPanel.playbackContext && !storyBoardPanel.playbackContext.isPlaying()){
//							storyBoardPanel.playbackContext.execute(kf.time+animation.getStartTime());
							storyBoardPanel.playbackContext.execute();
						}
						
					},
					GUI.CONTEXT_MENU_PROVIDER : [animationBar,index] => fn(animationBar,index){
						var animation  = animationBar.animation;
						var storyBoardPanel  = animationBar.storyBoardPanel;
						var kf = animation.getKeyFrame(index);

						var entries = [];
						entries += {
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Jump here #1: "+ (animation.getStartTime()+kf.time) +"s",
							GUI.ON_CLICK : [ storyBoardPanel.playbackContext,(animation.getStartTime()+kf.time) ]->fn(){
								this[0].execute(this[1]);
							}
						};
						entries += {
							GUI.TYPE : GUI.TYPE_NUMBER,
							GUI.WIDTH : 150,
							GUI.LABEL : "Time",
							GUI.DATA_VALUE : kf.time,
							GUI.ON_DATA_CHANGED : [index,animationBar]->fn(data){
								var index = this[0];
								var animationBar = this[1];
								var storyBoardPanel  = animationBar.storyBoardPanel;
								var animation  = animationBar.animation;
								var kf = animation.getKeyFrame(index);

								animation.setKeyFrame( index, data, kf.srt );									
								
								if(storyBoardPanel.playbackContext && !storyBoardPanel.playbackContext.isPlaying()){
									storyBoardPanel.playbackContext.execute();
								}
							}
						};
						entries += {
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Remove this key frame",
							GUI.ON_CLICK : [ animation,index ]->fn(){
								this[0].removeKeyFrame(this[1]);
							}
						};							
						entries += {
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Update position",
							GUI.ON_CLICK : [ animation,index ]->fn(){
								var animation = this[0];
								var index = this[1];
								var kf = animation.getKeyFrame(index);
								var n = animation.findNode();
								if(n){
									animation.setKeyFrame(index,kf.time,n.getRelTransformationSRT());
								}
							}
						};
						entries += {
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Duplicate at current time",
							GUI.ON_CLICK : [ animation,index,storyBoardPanel.playbackContext ]->fn(){
								var animation = this[0];
								var index = this[1];
								var kf = animation.getKeyFrame(index);
								var playbackContext = this[2];
								animation.insertKeyFrame(playbackContext.getCurrentTime()-animation.getStartTime(),kf.srt);
							}
						};
						return entries;
					},
				});
				animationBar.grabbers += grabber;
				animationBar+=grabber;
			}
			while(animationBar.grabbers.count() > animationBar.animation.keyFrames.count()){
				var grabber = animationBar.grabbers.popBack();
				grabber.getParentComponent().remove(grabber); // grabber.destroy
			}
		}
		foreach(animationBar.grabbers as var index,var grabber){
			var kf = animationBar.animation.getKeyFrame(index);
			grabber.setPosition(animationBar.storyBoardPanel.getPositionForTime(kf.time), 17);
			grabber.setTooltip("#"+index+": "+kf.time);
		}
	};
	return animationBar;
};

return T;
