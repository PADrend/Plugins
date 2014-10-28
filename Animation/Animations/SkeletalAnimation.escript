/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/***
 *	[ SkeletalAnimation.escript] 
 *	01.07.12 Lukas Kopecki
 *
 *  code mostly inheriated from NodeAnimation from Claudius
 */

static KeyFrameAnimation = module('./KeyFrameAnimation');
static AnimationBase = module('./AnimationBase');

// -----------------------------------------------------------------
// SkeletalAnimation ---|> AnimationBase
static T = new Type(KeyFrameAnimation);


Traits.addTrait(SkeletalAnimation,Traits.PrintableNameTrait,$SkeletalAnimation);

module('../Utils').constructableAnimationTypes["SkeletalAnimation"] = T;

T.nodeId := "";
T.typeName ::= "SkeletalAnimation";
T.skeletalBehavior := void;
T.joints := [];

// extension to regular keyframes
// each pose stores one keyframe of all deforming joints inside the skeletaltree.
KeyFrameAnimation.KeyFrame.poses := new Array();

//! (ctor)
T._constructor ::= fn(node=void, animation, _startTime=0, _duration=1)@(super("SkeletalAnimation", _startTime, _duration))
{
	this.__status.node := void;
	this.__status.originalMatrix := void;
	
	if(!node)
		return;
	
	if(!animation)
		return;
	
	if(!(node.skeleton ---|> MinSG.SkeletalNode))
	{
		this.skeletalBehavior := void;
		this.joints = [];
		
		return;
	}
	
	this.skeletalBehavior := animation;
	this.__status.node = node;
	
	foreach(skeletalBehavior.getPoses() as var pose)
	{
		foreach(pose.getTimeline() as var time)
		{
			var found = false;
			foreach(this.keyFrames as var key)
			{
				if(key.time == time)
				{
					key.poses.pushBack(pose);
					found = true;
				}
			}
			if(!found)
			{
				var keyframe = new KeyFrameAnimation.KeyFrame(time);
				keyframe.poses.pushBack(pose);
				keyFrames.pushBack(keyframe);
			}
		
		}
	}
};

//! ---|> AnimationBase
T.doEnter ::= fn(){
	// call base type's function.
	(this->AnimationBase.doEnter)();
	
	if(!this.skeletalBehavior)
		return;
	
	if(!(this.skeletalBehavior ---|> MinSG.SkeletalAnimationBehaviour))
		return;
	
	foreach(this.skeletalBehavior.getPoses() as var pose)
		pose.restart();
};

T.doExecute ::= fn(Number localTime)
{
	if(!skeletalBehavior)
		return;
	
	if(!(skeletalBehavior ---|> MinSG.SkeletalAnimationBehaviour))
	   return;
	
	this.skeletalBehavior.gotoTime(localTime);
};

//! ---|> AnimationBase
T.undo ::= fn(){
	if(this.skeletalBehavior)
	   this.skeletalBehavior.gotoTime(0.0);
	
	this.skeletalBehavior.stopAnimation();
	
	// call base type's function.
	(this->AnimationBase.undo)();
};

T.getSkeletalBehavior ::= fn(){
	return this.skeletalBehavior;
};

T.insertPose ::= fn(time){
	if(!this.__status.node)
		return;
	
	foreach(keyFrames as var key, var val)
		if(val.time == time)
		{
			out("A Keyframe already exists at"+time+"s.\n");
			return;
		}
	

	var i;
	this.keyFrames += void;
	for(i=keyFrames.count()-2; i>0; --i)
	{
		if(keyFrames[i].time < time)
			break;
		
		keyFrames[i+1] = keyFrames[i];
	}
	i++;
	keyFrames[i] = new KeyFrameAnimation.KeyFrame(time);
	keyFrames[i].poses = [];
	foreach(this.skeletalBehavior.getPoses() as var pose)
		keyFrames[i].poses += pose;
	
	foreach(keyFrames[i].poses as var pose)
	{
		pose.addValue(pose.getNode().getRelTransformationMatrix(), time, MinSG.SkeletalAbstractPose.LINEAR, i);
		pose.restart();
	}
	
	this._updated($KEY_FRAME_CHANGED,keyFrames[i]);
	
	//  if animation is currently active, apply changes immediately
	if(this.isActive()){
		this.execute(this.__status.lastTime);
	}
};

T.setKeyFrame ::= fn(index, time, srt=void)
{
	var keyframe = getKeyFrame(index);
	foreach(keyframe.poses as var pose)
	{
		var timeline = pose.getTimeline();
		foreach(timeline as var index, var value)
		{
			if((value - keyframe.time).abs() < 0.001)
			{
				if(index > 0)
					if(timeline[index-1] >= time)
						return;
				
				if(index < timeline.size()-1)
					if(timeline[index+1] < time)
						return;
				
				timeline[index] = time;
				if(!pose.setTimeline(timeline))
					out("Could not change Timeline!\n");
				else
					pose.restart();
				break;
			}
		}
	}
	keyframe.time = time;
	
	this._updated($KEY_FRAME_CHANGED,keyframe);
	
	//  if animation is currently active, apply changes immediately
	if(this.isActive())
		this.execute(this.__status.lastTime);
};

T.updateKeyFrame ::= fn(index)
{
	foreach(keyFrames[index].poses as var pose)
	{
		pose.updateValueAtIndex(pose.getNode().getRelTransformationMatrix(), index);
		pose.restart();
	}
	
	
	this._updated($KEY_FRAME_REMOVED,void);
	
	//  if animation is currently active, apply changes immediately
	if(this.isActive())
		this.execute(this.__status.lastTime);
};

T.removeKeyFrame ::= fn(index)
{
	foreach(this.keyFrames[index].poses as var pose)
	{
		pose.removeValue(index);
		pose.restart();
	}
	
	this.keyFrames.removeIndex(index);
	
	this._updated($KEY_FRAME_REMOVED,void);
	
	//  if animation is currently active, apply changes immediately
	if(this.isActive())
		this.execute(this.__status.lastTime);
};

T.getKeyFrame ::= fn(index)
{
	return keyFrames[index];
};

PADrend.Serialization.registerType( SkeletalAnimation.KeyFrame, "Animation.SkeletalAnimation.KeyFrame")
	.addDescriber( fn(ctxt,KeyFrameAnimation.KeyFrame obj,Map d){
				  d['time'] = obj.time;
				  d['keyFrames'] = ctxt.createDescription(obj.poses);
				  })
	.setFactory( fn(ctxt,type,Map d){	return new type (d['time'], ctxt.createObject(d['poses']));	});


PADrend.Serialization.registerType( T, "Animation.SkeletalAnimation")
	.initFrom( PADrend.Serialization.getTypeHandler(Animation.AnimationBase) ) //! --|> AnimationBase
	.addDescriber( fn(ctxt,KeyFrameAnimation.KeyFrame obj,Map d){
		d['nodeId'] = obj.getNodeId();
		d['keyFrames'] = ctxt.createDescription(obj.keyFrames);
	})
	.addInitializer( fn(ctxt,T obj,Map d){
		obj.setNodeId(d['nodeId']);
		obj.KeyFrames = ctxt.createObject(d['keyFrames']);
	});

// -----------------------------------------------------------------
// GUI

//! ---o
T.getMenuEntries := fn(storyBoardPanel){
	// call base type's function.
	var m = (this->AnimationBase.getMenuEntries)(storyBoardPanel);
	m+="----";
	var idInput = gui.create({
									  GUI.TYPE : GUI.TYPE_TEXT,
									  GUI.LABEL : "NodeId",
									  GUI.WIDTH : 150,
									  GUI.DATA_VALUE : this.getNodeId(),
									  GUI.ON_DATA_CHANGED : this->fn(data){
									  this.setNodeId(data);
									  }
									  });	
	m+=idInput;
	
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Add Pose",
		GUI.TOOLTIP : "Add a new Pose for Skeletal Animation.",
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
			
			animation.insertPose(insertionTime);
		}
	};
	return m;
};

return T;
