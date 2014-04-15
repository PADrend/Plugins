/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/Animations/AnimationBase.escript
 ** 2011-04 Claudius
 **
 ** abstract base type for all animations
 **/

loadOnce(__DIR__+"/../Animation.escript");

// -----------------------------------------------------------------
// AnimationBase

Animation.AnimationBase := new Type();
var AnimationBase = Animation.AnimationBase;
Traits.addTrait(AnimationBase,Traits.PrintableNameTrait,$AnimationBase);


AnimationBase.story := void;
AnimationBase.name := void;
AnimationBase.startTime := 0; 	//! Relative to its story in integer timesteps
AnimationBase.duration := 1; 	//! Seconds
AnimationBase.row := 0;   		//! Row in a storyboard.
AnimationBase.__updateListener := void;
AnimationBase.__status := void;

AnimationBase.typeName ::= "AnimationBase";

AnimationBase._constructor ::= fn(_name="AnimationBase",_startTime=0,_duration=1){
	this.__updateListener = [];
	this.__status = new ExtObject( {
		$lastTime : -1,
		$active : false
	});
	this.name = _name;
	this.startTime = _startTime;
	this.duration = _duration;
};

AnimationBase.execute ::= fn(Number localTime){
	if(!this.__status) //  this animation has been destroyed
		return;
	
	if(localTime<0){
		// playback time moved before the beginning? -> undo
		if(this.__status.active || this.__status.lastTime>0){
			this.__status.active = false;
			this.undo();
//			out("UNDO: ",this.getName(),"\n");
		}
	}
	else if(localTime>=duration){
		// playback time moved  after the ending? -> leave
		if(this.__status.active){
			this.__status.active = false;
			this.doLeave();
		} // did we overjump the animation?
		else if(this.__status.lastTime<0) { 
			this.doEnter();
			this.doLeave();
		}
	}else{
		if(!this.__status.active){
			this.__status.active=true;
			this.doEnter();
		}
		doExecute(localTime);
	}
	this.__status.lastTime = localTime;

};

/*! ---o
	Called in every step when the animation is active.	*/
AnimationBase.doExecute ::= fn(Number localTime){
	out(" ",this.name,"(",localTime,") ");
};

/*! ---o
	Called before the animation is (re-)activated. */
AnimationBase.doEnter ::= fn(){
//	out(" ",this.name," init \n");
};

/*! ---o
	Called when the animation was active, but the current playback time imoved after the animation's ending. */
AnimationBase.doLeave ::= fn(){
	this.doExecute(this.getDuration());
//	out(" ",this.name," exit \n");
};

/*! ---o
	Called when the animation was active, but the current playback time jumped before ths beginning. */
AnimationBase.undo ::= fn(){
//	this.doExecute(0);
//	out(" ",this.name," undo \n");
};

AnimationBase.getDuration ::= fn(){
	return this.duration;
};

AnimationBase.getEndTime ::= fn(){
	return this.startTime + this.duration;
};

//! ---o
AnimationBase.getInfo ::= fn(){
	return this.getName() + "\n" + 
		getTypeName() +" from "+getStartTime().format(2,false)+"s to "+this.getEndTime().format(2,false)+"s ("+this.getDuration()+"s)";
};

AnimationBase.getName ::= fn(){
	return this.name;
};

AnimationBase.getRow ::= fn(){
	return this.row;
};

AnimationBase.getStartTime ::= fn(){
	return this.startTime;
};
AnimationBase.getStory ::= fn(){
	return this.story;
};

AnimationBase.getTypeName ::= fn(){
	return this.typeName;
};

AnimationBase.isActive ::= fn(){
	return this.__status.active;
};

AnimationBase.setName ::= fn(String newName){
	if(this.name!=newName){
		this.name = newName;
		this._updated($NAME_CHANGED,newName);
	}
};

AnimationBase.setDuration ::= fn(Number newDuration){
	if(newDuration<0)
		newDuration=0;
	if(newDuration!=this.duration){
		this.duration = newDuration;
		this._updated($DURATION_CHANGED,duration);	
	}
};

AnimationBase.setStartTime ::= fn(Number newStartTime){
	if(newStartTime!=this.startTime){
		this.startTime = newStartTime;
		this._updated($START_TIME_CHANGED,duration);	
	}
};

AnimationBase.setRow ::= fn(Number newRow){
	if(newRow!=this.row){
		this.row = newRow;
		this._updated($ROW_CHANGED,newRow);	
	}
};

//! (interal) Called by Story.addAnimation(...)
AnimationBase.setStory ::= fn( [Animation.Story,void] newStory ){
	if(newStory!=story){
		this.story = newStory;
		if(newStory)
			newStory.addAnimation(this);
		this._updated($STORY_CHANGED,newStory);
	}
};

//! (internal)
AnimationBase._updated ::= fn(type,data=void){
	var tmp = [];
	var evt = new ExtObject( {$animation:this,$type:type, $data:data });
	foreach(this.__updateListener as var l){
		if( l(evt)!=$REMOVE )
			tmp+=l;
	}
	this.__updateListener.swap(tmp);
};

AnimationBase.addUpdateListener ::= fn(listener){
	this.__updateListener += listener;
};

AnimationBase.removeUpdateListener ::= fn(listener){
	this.__updateListener.removeValue(listener);
};

//! ---o
AnimationBase.destroy ::= fn(){
	if(this.__status){
		if(this.__status.lastTime>0){  // needs to be undone?
			this.undo();
		}
		setStory(void);
		this.__updateListener.clear();
		this.__status = void;
	}
};

PADrend.Serialization.registerType( Animation.AnimationBase, "Animation.AnimationBase")
	.enableIdentityTracking()
	.addDescriber( fn(ctxt,Animation.AnimationBase obj,Map d){
		d['name'] = obj.getName();
		d['startTime'] = obj.getStartTime();
		d['duration'] = obj.getDuration();
		d['row'] = obj.getRow();
	})
	.addInitializer( fn(ctxt,Animation.AnimationBase obj,Map d){
		obj.setName( d['name'] );
		obj.setStartTime( d['startTime'] );
		obj.setDuration( d['duration'] );
		obj.setRow( d['row'] );
	});

// -----------------------------------------------------------------
// GUI

//! ---o
AnimationBase.getMenuEntries := fn(storyBoardPanel){
	var m=[];
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Copy",
		GUI.ON_CLICK : this->fn(){
			var s = PADrend.serialize(this);
			out(s);
			Animation.animationClipboard = s;
		}
	};
	m+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Delete",
		GUI.ON_CLICK : this->fn(){
			this.setStory(void);
		}
	};
	m+="----";
	m+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Name",
		GUI.WIDTH : 150,
		GUI.DATA_VALUE : this.getName(),
		GUI.ON_DATA_CHANGED : this->fn(data){
			this.setName(data);
		}
	};
	m+={
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Start time",
		GUI.WIDTH : 150,
		GUI.DATA_VALUE : this.getStartTime(),
		GUI.ON_DATA_CHANGED : this->fn(data){
			this.setStartTime(data);
		}
	};
	return m;
};

//! ---o
AnimationBase.createAnimationBar ::= fn(storyBoardPanel){
	var animationBar = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.WIDTH : 100,
		GUI.HEIGHT : storyBoardPanel.rowSize-5,
		GUI.CONTEXT_MENU_PROVIDER : [storyBoardPanel] => this->fn(storyBoardPanel){	return getMenuEntries(storyBoardPanel);},
		GUI.CONTEXT_MENU_WIDTH : 150,
		GUI.FLAGS : 0//GUI.BORDER
	});
	
	
	gui.createContainer(100,storyBoardPanel.rowSize,0); //GUI.BORDER
	storyBoardPanel += animationBar;
	
	animationBar.valid := true;
	animationBar.animation := this;
	animationBar.storyBoardPanel := storyBoardPanel;
	animationBar._rowShiftCounter := 0;

	
	// name
	animationBar.nameLabel := gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : this.getName(),
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, 
							0,0],
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -0.01 ,12 ],		
		GUI.COLOR : storyBoardPanel.fontColor
	});
	animationBar += animationBar.nameLabel;
	
	// mover
	var mover = gui.create({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : " ",
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, 
							0,12],
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -3 ,3 ], // -3, as the animation bar itself is a little bit extended to the right
		GUI.DRAGGING_ENABLED : true,
		GUI.ON_DRAG : animationBar->fn(evt){
			this.animation.setStartTime( this.animation.getStartTime()+storyBoardPanel.getTimeForPosition(evt.deltaX*0.5) );
			this._rowShiftCounter += evt.deltaY;
			if(_rowShiftCounter < -30){
				if(this.animation.getRow()>0)
					this.animation.setRow(this.animation.getRow()-1);
				_rowShiftCounter = 0;
			}else if(_rowShiftCounter > 30){
				this.animation.setRow(this.animation.getRow()+1);
				_rowShiftCounter = 0;
			}
		},
		GUI.TOOLTIP : "Drag to move"
	});

	mover.setButtonShape(GUI.BUTTON_SHAPE_MIDDLE);
	
	animationBar+=mover;
	
	// -----
	
	animationBar.refresh := fn(){
		this.setPosition( new Geometry.Vec2( this.storyBoardPanel.getPositionForTime(this.animation.getStartTime()) ,
											this.storyBoardPanel.rowSize*this.animation.getRow() ));
		// set the width a little bit larger to allow picking of markers at the end of the time range
		this.setWidth( [ this.storyBoardPanel.getPositionForTime(this.animation.getDuration()) ,3].max()+3 );
		this.nameLabel.setText( 
			this.animation.getName() +" ["+this.animation.getStartTime().format(2,false)+" - "+this.animation.getEndTime().format(2,false)+"]" );
		
		this.setTooltip(this.animation.getInfo());
	};
	animationBar.delete := fn(){
		if(valid){
			out("~AnimationBar\n");
			this.clear();
			this.getParentComponent().remove(this);
			valid=false;
		}
	};
	
	// if the animation changed, update or delete the animationBar.
	this.addUpdateListener( animationBar -> fn(evt){
		if(evt.type == $STORY_CHANGED){
			if(evt.data!=this.storyBoardPanel.story){
				this.delete();
				return $REMOVE;
			}
		}
		this.refresh();
	});
	
	// if the storyBoardPanel changed (e.g. the zoom level changed), refresh the animation Bar.
	storyBoardPanel.refreshListener += animationBar->fn(){
		if(!valid)
			return $REMOVE;
		this.refresh();
	};
	
	animationBar.refresh();
	return animationBar;
};

