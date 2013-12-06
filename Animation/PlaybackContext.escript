/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/PlaybackContext.escript
 ** 2011-04 Claudius
 **/

loadOnce( __DIR__+"/Animation.escript" );
loadOnce( __DIR__+"/Animations/Story.escript" );

Animation.PlaybackContext := new Type();
var PlaybackContext = Animation.PlaybackContext;

PlaybackContext.story := void;
PlaybackContext.playing := void;
PlaybackContext.looping := true;
PlaybackContext.clockStartingTime := 0; // real seconds
PlaybackContext.currentTime := 0; // animation seconds
PlaybackContext.extensionRegistered := false;
PlaybackContext.timeUpdatedListener := void;

PlaybackContext.timeScale := 1.0; // animation seconds / real seconds


//! (ctor)
PlaybackContext._constructor ::= fn( Animation.Story _story ){
	this.story = _story;
	this.timeUpdatedListener = [];
};


//! @param listener   void | $REMOVE  fn(PlaybackContext){ ... }
PlaybackContext.addListener ::= fn(listener){
	this.timeUpdatedListener += listener;
};

PlaybackContext.execute ::= fn( [Number,void] time = void){
	if(!time) 
		time = currentTime;
	time = (time*100).round() * 0.01;
	this.currentTime = time;
	this.story.execute(time);
	
	this.timeUpdatedListener.filter( this->fn(l){
		return l(this) != $REMOVE;
	});
	
	out("                      \r",this.currentTime,"\t");
	if(this.playing && this.looping && time>=this.story.getDuration()){
		this.jumpTo(0);
	}else if(time>=this.story.getDuration()+1)
		this.pause();
};

PlaybackContext.getCurrentTime ::= fn(){
	return this.currentTime;
};

PlaybackContext.getStory ::= fn(){
	return this.story;
};

PlaybackContext.getTimeScale ::= fn(){
	return this.timeScale;
};


PlaybackContext.isPlaying ::= fn(){
	return this.playing;
};

PlaybackContext.jumpRel ::= fn(tDiff){
	if(tDiff < -this.currentTime)
		tDiff = -this.currentTime;
	this.clockStartingTime-=tDiff/this.timeScale;
	this.currentTime+=tDiff;
	this.execute(currentTime);
	
	PADrend.executeCommand( new Command({	
			Command.EXECUTE : (fn(currentTime,clockStartingTime){ 
				var ctxt=AnimationPlugin.playbackContext;
				ctxt.jumpTo(currentTime);
				ctxt.clockStartingTime=clockStartingTime;
			}).bindLastParams(currentTime,clockStartingTime),
			Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }) 
	);
};

PlaybackContext.jumpTo ::= fn(t){
	this.jumpRel(t-currentTime);
};

PlaybackContext.pause ::= fn(){
	this.playing = false;
};

PlaybackContext.play ::= fn(){
	this.clockStartingTime = PADrend.getSyncClock()- (this.currentTime/this.timeScale);
	
	this.playing = true;
	if(!this.extensionRegistered){
		registerExtension('PADrend_AfterFrame',this->fn(...){
			if(!this.playing){
				this.extensionRegistered=false;
				return Extension.REMOVE_EXTENSION;
			}
			this.execute( (PADrend.getSyncClock()-this.clockStartingTime) * this.timeScale) ;
		});
		this.extensionRegistered = true;
	}
	// send command to connected clients
	PADrend.executeCommand( new Command({	
			Command.EXECUTE : (fn(clockStartingTime){ 
				var ctxt=AnimationPlugin.playbackContext;
				ctxt.play();
				ctxt.clockStartingTime=clockStartingTime;
			}).bindLastParams(clockStartingTime),
			Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }) 
	);
};

PlaybackContext.setLooping ::= fn(Bool l){
	this.looping = l;
};

PlaybackContext.setTimeScale ::= fn(newTimeScale){
	if(newTimeScale<=0.01)
		newTimeScale = 0.01;
	this.timeScale = newTimeScale;
	this.clockStartingTime = PADrend.getSyncClock()-(this.currentTime/this.timeScale);
	
	// send command to connected clients
	PADrend.executeCommand( new Command({	
			Command.EXECUTE : (fn(newTimeScale,clockStartingTime){ 
				var ctxt=AnimationPlugin.playbackContext;
				ctxt.setTimeScale(newTimeScale);
				ctxt.clockStartingTime=clockStartingTime;
			}).bindLastParams(newTimeScale,clockStartingTime),
			Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }) 
	);
	
};

PlaybackContext.stop ::= fn(){
	this.playing = false;
	this.execute(-0.01); // move before the start to disable all animations
	
	PADrend.executeCommand( new Command({	
		Command.EXECUTE : (fn(clockStartingTime){ 
			var ctxt = AnimationPlugin.playbackContext;
			ctxt.stop();
			ctxt.clockStartingTime = clockStartingTime;
		}).bindLastParams(clockStartingTime),
		Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }) 
	);
};

