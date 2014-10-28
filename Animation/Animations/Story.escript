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
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/Animations/Story.escript
 ** 2011-04 Claudius
 **
 ** Story-Animation-Type
 **/

static AnimationBase = module('./AnimationBase');
static PlaybackContext = module('../PlaybackContext');


// -----------------------------------------------------------------
// Story ---|> AnimationBase
static T = new Type(AnimationBase);


module('../Utils').constructableAnimationTypes["Story (animation group)"] = T;

Traits.addTrait(T,Traits.PrintableNameTrait,$Story);

T.animations := void;
T.typeName ::= "Story";


//! (ctor)
T._constructor ::= fn(name="Story",startTime=0)@(super(name,startTime,1)){
	this.animations = [];
	this.__status.updatingChildren := false;
	this.__status.animationsSorted := false; // -1 : false : 1
};

T.addAnimation ::= fn(AnimationBase animation){
	var added = false;
	
	if(!this.animations.contains(animation)){
		this.animations += animation;
		added = true;
		
		// register this story as listener for changes of the new animation
		animation.addUpdateListener( this->fn(evt){
			if(evt.animation.getStory()!=this){
				this.animations.removeValue(evt.animation);
				out("Animation removed.");
				this._updateAnimations();
				this._updated($ANIMATION_REMOVED,evt.animation);
				return $REMOVE;
			}
			this._updateAnimations();
		});
	}

	if(animation.getStory() != this)
		animation.setStory(this);
		
	if(added)
		this._updated($ANIMATION_ADDED,animation);
};

//! ---|> AnimationBase
T.destroy @(override) ::= fn(){

	var tmp = this.animations.clone(); // clone the array as the a.detroy may change the animation array.
	foreach(tmp as var a) 
		a.destroy();
	
	// call base type's function.
	(this->AnimationBase.destroy)();
		
};

//! ---|> AnimationBase
T.doExecute @(override) ::= fn(Number localTime){

	// moving forward through time? ---> sort animations by starting time; earliest starting time first.
	if(localTime >= this.__status.lastTime && this.__status.animationsSorted != 1){
		this.animations.sort( fn(a1,a2){	return a1.getStartTime()<a2.getStartTime();	} );
		this.__status.animationsSorted = 1;
//		out("\nSort +: ");
//		foreach(this.animations as var animation)
//			out(" ",animation.getStartTime());
//		out("\n");
	}
	// time traveling? ---> sort animations by their ending times; latest ending time first.
	else if(localTime < this.__status.lastTime && this.__status.animationsSorted != -1){
		this.animations.sort( fn(a1,a2){	return a1.getEndTime()>a2.getEndTime();	} );
		this.__status.animationsSorted = -1;
//		out("\nSort -: ");
//		foreach(this.animations as var animation)
//			out(" ",animation.getEndTime());
//		out("\n");
	}
	
	
	foreach(this.animations as var animation){
		try{
			animation.execute( localTime-animation.getStartTime() );
		}catch(e){
			Runtime.warn(e);
		}
	}
};

T.removeAnimation ::= fn(AnimationBase animation){
	if(animation.getStory() == this)
		animation.setStory(void);
};

//! ---|> AnimationBase
T.undo  @(override) ::= fn(){
	// make shure all animations are undone (in the right order)
	this.doExecute(-0.1);
//	out(" ",this.name," undo \n");
};


T.getAnimations ::= fn(){
	return this.animations.clone();
};

//! (internal) called if an animation has changed.
T._updateAnimations ::= fn(){
	if(this.__status.updatingChildren)
		return;
		
	this.__status.updatingChildren =  true; // disable recursive updates
	
	if(this.animations.empty()){
		this.setDuration(1);
		return;
	}
	var max = 0;
	var min = 1000000;
	foreach( this.animations as var animation){
		var t = animation.getEndTime();
		if(t>max)
			max = t;
		t = animation.getStartTime();
		if(t<min) 
			min = t;
	}
	if( min<0 ){
		this.setStartTime( this.getStartTime()+min );
		foreach( this.animations as var animation){
			animation.setStartTime( animation.getStartTime()-min );
		}
		this.setDuration(max-min);	
	}
	else 
		this.setDuration(max);	
	this.__status.animationsSorted = false;
	
	this.__status.updatingChildren =  false;
};
	
T.adaptStartingTime := fn(){
	if(this.__status.updatingChildren)
		return;
		
	this.__status.updatingChildren =  true; // disable recursive updates
	
	if(this.animations.empty()){
		this.setDuration(1);
		return;
	}
	var max = 0;
	var min = 1000000;
	foreach( this.animations as var animation){
		var t = animation.getEndTime();
		if(t>max)
			max = t;
		t = animation.getStartTime();
		if(t<min) 
			min = t;
	}
//	\todo move to external function?
	if( min!=0 ){
		this.setStartTime( this.getStartTime()+min );
		foreach( this.animations as var animation){
			animation.setStartTime( animation.getStartTime()-min );
		}
	}
	this.setDuration(max-min);	
	this.__status.animationsSorted = false;
	this.__status.updatingChildren =  false;
};

PADrend.Serialization.registerType( T, "Animation.Story")
	.initFrom( PADrend.Serialization.getTypeHandler(AnimationBase) ) //! --|> AnimationBase
	.addDescriber( fn(ctxt,T obj,Map d){
		d['animations'] = ctxt.createDescription(obj.animations);
	})
	.addInitializer( fn(ctxt,T obj,Map d){
		foreach(d['animations'] as var aDescription )
			obj.addAnimation( ctxt.createObject(aDescription) );
	});


// -----------------------------------------------------------------
// GUI: Story

T.createStoryBoardPanel ::= fn( PlaybackContext playbackContext){
	var panel = gui.create({
		GUI.TYPE : GUI.TYPE_PANEL,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_ABS,4,2],
		GUI.FLAGS : GUI.LOWERED_BORDER|GUI.BACKGROUND,
		GUI.ON_MOUSE_BUTTON : fn(evt){
			if(!evt.pressed)
				return $CONTINUE;
				
			if(evt.button == Util.UI.MOUSE_BUTTON_RIGHT) {
				this.openMenu(evt);
				return $BREAK;
			} else if(evt.button == Util.UI.MOUSE_WHEEL_DOWN) {
				if(this.pixelsPerTimeUnit>1){
					--this.pixelsPerTimeUnit;
					this.refresh();	
				}
				return $BREAK;
			} else if(evt.button == Util.UI.MOUSE_WHEEL_UP) {
				if(this.pixelsPerTimeUnit<64){
					++this.pixelsPerTimeUnit;
					this.refresh();
				}
				return $BREAK;
			}
			return $CONTINUE;
		}
	});
	// add a basic black backround
	panel.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
											gui._createRectShape(new Util.Color4ub(0,0,0,220),new Util.Color4ub(20,20,20,20),true)));

	// the client area has its own grid background, which only ranges to the last component
	panel.getContentContainer().clearLayouters();
	panel.getContentContainer().setExtLayout(GUI.WIDTH_CHILDREN_ABS|GUI.HEIGHT_CHILDREN_ABS,new Geometry.Vec2(0,0),new Geometry.Vec2(0,2));
	panel.getContentContainer().setFlag(GUI.BACKGROUND,true); 

	panel.pixelsPerTimeUnit := 10;
	panel.rowSize := 30;
	panel.story := this;
	panel.refreshListener := [];
	panel.playbackContext := playbackContext;
	panel.fontColor := new Util.Color4ub(255,255,255,255);
	
	panel.openMenu := fn(evt) {
		var entries = [];
		var localPos = gui.screenPosToGUIPos( [evt.x,evt.y] ) - getAbsPosition() - getContentContainer().getPosition();
		var time = this.getTimeForPosition(localPos.getX());
		var row = (localPos.getY() / this.rowSize).floor();
		
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Jump here: "+time.format(2,false)+" s",
			GUI.ON_CLICK : [this.playbackContext,time]->fn(){
				this[0].jumpTo(this[1]);
			}
		};
		entries += "----";
		entries+={
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Story name",
			GUI.WIDTH : 150,
			GUI.DATA_VALUE : this.story.getName(),
			GUI.ON_DATA_CHANGED : this.story->fn(data){
				this.setName(data);
			}
		};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Copy this story",
			GUI.ON_CLICK : this.story->fn(){
				var s = PADrend.serialize(this);
				out(s);
				module('../Utils').animationClipboard = s;
			}
		};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Paste",
			GUI.ON_CLICK : [this, localPos]->fn(){
				if(!module('../Utils').animationClipboard){
					Runtime.warn("Clipboard is empty.");
					return;
				}
				try{
					var animation = PADrend.deserialize(module('../Utils').animationClipboard);
					animation.setStartTime( this[0].getTimeForPosition(this[1].getX()) );
					animation.setRow( (this[1].getY()/this[0].rowSize).floor() );
					this[0].story.addAnimation(animation);
				}catch(e){
					Runtime.warn(e);
				}
			}
		};		
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "adaptStartingTime",
			GUI.ON_CLICK : this.story->fn(){
				this.adaptStartingTime();
			}
		};
		entries += "----";
		foreach(module('../Utils').constructableAnimationTypes as var name,var type){
			entries += { // temp
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Add "+name,
				GUI.ON_CLICK : [this, localPos, type]->fn(){
					var animation = new this[2]();
					animation.setStartTime( this[0].getTimeForPosition(this[1].getX()) );
					animation.setRow( (this[1].getY()/this[0].rowSize).floor() );
					// if the animation animates a node, try to assign the currently selected node.
					if( animation.isA(module('./NodeAnimation')) ){
						if(animation.setSelectedNode())
							animation.setName( animation.getName()+":"+animation.getNodeId() );
					}
					this[0].story.addAnimation(animation);
				}
			};
		}
		gui.openMenu( gui.screenPosToGUIPos( [evt.x,evt.y] ) - new Geometry.Vec2(3,3), entries);
	};
	
	panel.getPositionForTime := fn(time){
		return pixelsPerTimeUnit*time;
	};
	panel.getTimeForPosition := fn(pos){
		var t= pos/pixelsPerTimeUnit;
		t = (t*100).round() * 0.01;
		return t;
	};

	
	panel.refresh := fn(){
		// update grid background
		this.getContentContainer().clearProperties();
		this.getContentContainer().addProperty(
				new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
									gui._createGridShape(new Util.Color4ub(120,120,120,80),new Util.Color4ub(80,80,80,60),0,getPositionForTime(1.0),0,4)));
		this.refreshListener.filter(fn(listener){
			return listener()!=$REMOVE;
		});
	};
	
	// -------
	// time bar
	panel.timeBar := gui.create({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 5 , -2 ],
		GUI.LABEL : "",
		GUI.DRAGGING_ENABLED : true,
		GUI.ON_DRAG : panel->fn(evt){
			this.playbackContext.jumpRel(getTimeForPosition(evt.deltaX));
		},
		GUI.FLAGS : GUI.FLAT_BUTTON // timeBar itself is invisible
	});
	// add visible marker
	panel.timeBar += {
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 1 , -0.01 ],
		GUI.LABEL : "",
		GUI.FLAGS : GUI.BACKGROUND
	};
	panel.timeBar.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
		gui._createRectShape(GUI.ACTIVE_COLOR_3,new Util.Color4ub(20,20,20,0),false)));
	
	panel += panel.timeBar;
	panel.refreshTimeBar := fn(){
		this.timeBar.setPosition( new Geometry.Vec2(this.getPositionForTime(this.playbackContext.getCurrentTime()),0));
	};

	// move time bar if the current time changed
	playbackContext.addListener( panel->fn(ctxt){
		if(ctxt.getStory()!=this.story)
			return $REMOVE;
		this.refreshTimeBar();
	});
	
	// move time bar if storyBoard changed (e.g. the time scaling)
	panel.refreshListener += panel->fn(){
		this.refreshTimeBar();
	};

	// -------
	// init
	this.addUpdateListener( panel->fn(evt){
//		out("Story changed",evt.type,"\n");
		if(evt.type == $ANIMATION_ADDED){
			evt.data.createAnimationBar(this);
			refresh();
		}
		this.playbackContext.execute();
	});

	foreach(this.animations as var a){
		a.createAnimationBar(panel);
	}
	
	panel.refresh();
	
	return panel;
};

//! ---|> AnimationBase
T.getMenuEntries  @(override) := fn(storyBoardPanel){
	// call base type's function.
	var m = (this->AnimationBase.getMenuEntries)(storyBoardPanel);
	m+="----";
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Open...",
		GUI.WIDTH : 150,
		GUI.ON_CLICK : this->fn(){
			AnimationPlugin.selectStory(this);
		}
	};
	return m;
};

return T;
