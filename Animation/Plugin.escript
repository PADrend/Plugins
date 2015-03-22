/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Animation/plugin.escript
 ** 2011-04 Claudius
 **/

GLOBALS.AnimationPlugin:=new Plugin({
			Plugin.NAME	: 'Animation',
			Plugin.VERSION : 1.1,
			Plugin.DESCRIPTION : "Story based animations",
			Plugin.AUTHORS : "Claudius",
			Plugin.OWNER : "Claudius",
			Plugin.REQUIRES : ["NodeEditor","PADrend","PADrend/Serialization"]
});

static Listener = Std.require('LibUtilExt/deprecated/Listener');

static Utils = Std.require('Animation/Utils');
static PlaybackContext = Std.require('Animation/PlaybackContext');
static Story = Std.require('Animation/Animations/Story');
static KeyFrameAnimation = Std.require('Animation/Animations/KeyFrameAnimation');
static BlendingAnimation = Std.require('Animation/Animations/BlendingAnimation');


// \note Disabled because it messes up the serialization of KeyFrameAnimations
//if(MinSG.isSet($SkeletalAnimationBehaviour))
//    loadOnce(__DIR__+"/Animations/SkeletalAnimation.escript");
//

AnimationPlugin.window := void;
AnimationPlugin.activeStory := void;
AnimationPlugin.stories := void;
AnimationPlugin.storyBoardPanel := void;
AnimationPlugin.playbackContext := void;
AnimationPlugin.storyCounter := 0;

//! ---|> Plugin
AnimationPlugin.init @(override) :=fn(){

	Listener.ANIMATION_PLUGIN_ACTIVE_STORY_CHANGED := $ANIMATION_PLUGIN_ACTIVE_STORY_CHANGED;

	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.register('PADrend_PluginsMenu.animation',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Animation editor",
				GUI.ON_CLICK : fn() { AnimationPlugin.showWindow(0, 50, 600, 300); }
			});
		});
	}
	this.stories = [];

	this.createNewStory();

	return true;
};


AnimationPlugin.createNewStory := fn(){
	var story = new Story("Story "+ (++storyCounter) );
	this.selectStory(story);
	return story;
};


AnimationPlugin.getActiveStory := fn(){
	return this.activeStory;
};

AnimationPlugin.importStory := fn(filename){
	out("\Importing story '",filename,"' ... ");
	var result = Utils.loadAnimation(filename);
	out(result,"\n");
	if(result---|>Story){
		result.filename := filename;
		this.getActiveStory().addAnimation(result); 
	}else{
		Runtime.warn("Could not load story.");
	}
	return result;
};

AnimationPlugin.loadStory := fn(filename){
	out("\Loading story '",filename,"' ... ");
	var result=Utils.loadAnimation(filename);
	out(result,"\n");
	if(result---|>Story){
		result.filename := filename;
		this.selectStory(result); 
	}else{
		Runtime.warn("Could not load story.");
	}
	return result;
};

AnimationPlugin.mergeStory := fn(filename){
	out("\Merging story '",filename,"' ... ");
	var result=Utils.loadAnimation(filename);
	out(result,"\n");
	if(result---|>Story){
		// steal all animations at one, so that the old owner can't move them around while they are removed. 
		var tmp = [];
		result.animations.swap(tmp);
		
		foreach(tmp as var animation){
			this.activeStory.addAnimation(animation);
			out(".");
		}
		result.destroy();
		out("\n");		
	}else{
		Runtime.warn("Could not load story.");
	}
	return result;
};

AnimationPlugin.rebuildStoryGUI := fn(){
	
	if( this.storyBoardPanel ){
		this.storyBoardPanel.clear();
		this.storyBoardPanel.getParentComponent().remove(this.storyBoardPanel);
	}
	this.storyBoardPanel = this.activeStory.createStoryBoardPanel( this.playbackContext );
	storyBoardPanel.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(4,20),new Geometry.Vec2(-8,-35) );
	
	this.window+=storyBoardPanel;
};

AnimationPlugin.saveCurrentStory := fn(filename){
	out("\nSaving story as '",filename,"' ... ");
	var result=Utils.saveAnimation(filename,this.activeStory);
	out(result,"\n");
	this.activeStory.filename := filename;
	return result;
};

AnimationPlugin.selectStory := fn(Story story){
	this.activeStory = story;
	if(this.playbackContext){
		this.playbackContext.stop();
	}
	this.playbackContext = new PlaybackContext(story);
		
	// high level story? -> register
	if(!this.stories.contains(story) && !story.getStory()){
		this.stories+=story;
	}
	
	Listener.notify(Listener.ANIMATION_PLUGIN_ACTIVE_STORY_CHANGED,story);
//	out("Story:",getStoryPath(story).implode("|") ,"\n");
	
	var path  = this.getStoryPath(story);
	if(path.front()!="???"){
		static Command = Std.require('LibUtilExt/Command');
		// send command to connected clients
		PADrend.executeCommand( new Command({	
				Command.EXECUTE : [path]=>fn(path){ 	AnimationPlugin.selectStoryByPath(path);	},
				Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }) 
		);
	}
//	}
};


//! @return [ filename of base story, name of substory, ... , name of given story]
AnimationPlugin.getStoryPath := fn(Story story){
	var components = [];
	while(story){
		if(!story.getStory()){
			components.pushFront( story.isSet($filename) ? story.filename : "???" );
			break;
		}
		components.pushFront(story.getName());
		story = story.getStory();
	}
	return components;
};

//! @param [ filename of base story, name of substory, ... , name of given story]
AnimationPlugin.getStoryByPath := fn(Array path){
	var debugPathString = path.implode("|");
	// first entry is filename
	var filename = path.popFront();
	var story;
	foreach(this.stories as var baseStory){
		if(baseStory.isSet($filename) && baseStory.filename==filename){
			story = baseStory;
			break;
		}
	}
	// not loaded? try to load
	if(!story){
		out("Loading story '",filename,"'\n");
		story = this.loadStory(filename);
	}
	if(!story){
		Runtime.warn("Could not load story '"+filename+"'");
		return;
	}
	// find substory according to path
	while(!path.empty()){
		var name = path.popFront();
		var found = false;
		foreach(story.getAnimations() as var s){
			if(s.getName() == name){
				story = s;
				found = true;
				break;
			}
		}
		if(!found || !(story---|>Story)){
			Runtime.warn("Could not find story '"+debugPathString+"'");
			return;
		}
	}
	return story;
}; 

//AnimationPlugin.selectStoryByPath(['./R/BG_12247/R1.story','Kleines WS mit Roboter']);
AnimationPlugin.selectStoryByPath := fn(Array path){
	var story = this.getStoryByPath(path);
	if(story)
		this.selectStory(story);
};

// -----------------------------------------------

//!
AnimationPlugin.createNavBar:=fn(width,height){

	var panel=gui.createPanel(width,height,GUI.AUTO_LAYOUT|GUI.LOWERED_BORDER);
	panel.setMargin(2);
	panel.setTooltip("Navigation bar");


	panel.refresh:=fn( activeStory ){
		
		this.clear();
		var breadcrumbAnimations=[];

		var text="";
		if(activeStory){
			text = AnimationPlugin.getNameForStory(activeStory);
			for(var p=activeStory.getStory(); p ; p=p.getStory())
				breadcrumbAnimations.pushFront(p);
		}else {
			text=" ---- ";
		}
		var b = gui.create( {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : ">",
			GUI.WIDTH : 10,
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.TOOLTIP : "Select Story ",
			GUI.ON_CLICK : fn(){
				AnimationPlugin.openChildSelectorMenu(this.getAbsPosition()+new Geometry.Vec2(0,10),AnimationPlugin.stories); 
			}
		});
		b.setColor(GUI.PASSIVE_COLOR_1);
		this+=b;
		
		
		// breadcrumb
		foreach(breadcrumbAnimations as var animation){
			var b = gui.create( {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : AnimationPlugin.getNameForStory(animation),
				GUI.WIDTH : 100,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Select Story:"+AnimationPlugin.getNameForStory(animation),
				GUI.ON_CLICK : animation->fn(){AnimationPlugin.selectStory(this); }
			});
			b.setColor(GUI.PASSIVE_COLOR_1);
			this+=b;
			
			b = gui.create( {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : ">",
				GUI.WIDTH : 10,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Select substory of "+AnimationPlugin.getNameForStory(animation),
			});
			b.onClick = [b,animation]->fn(){
				AnimationPlugin.openChildSelectorMenu(this[0].getAbsPosition()+new Geometry.Vec2(0,10),this[1]); 
			};				
			this += b;
			b.setColor(GUI.PASSIVE_COLOR_1);

		}

//		// label
		b = gui.create( {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : text,
			GUI.WIDTH : 100,
			GUI.BUTTON_SHAPE : GUI.BUTTON_SHAPE_TOP,
			GUI.ON_CLICK : fn(){
				setText(AnimationPlugin.getNameForStory(AnimationPlugin.getActiveStory()));
			}
		});
		this+=b;

		if(activeStory){
			var b = gui.create( {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : ">",
				GUI.WIDTH : 10,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Select substory of "+AnimationPlugin.getNameForStory(activeStory),
			});
			b.onClick = [b,activeStory]->fn(){
				AnimationPlugin.openChildSelectorMenu(this[0].getAbsPosition()+new Geometry.Vec2(0,10),this[1]); 
			};				
			this += b;
			b.setColor(GUI.PASSIVE_COLOR_1);
	
		}
	};

	Listener.add(Listener.ANIMATION_PLUGIN_ACTIVE_STORY_CHANGED,
		panel->fn(type,story){this.refresh(story);} );

	return panel;
};

AnimationPlugin.getNameForStory := fn(Story story){
	var s=story.getName();
	if(story.isSet($filename))
		s+=" ("+story.filename+")";
	return s;
};

//!
AnimationPlugin.openChildSelectorMenu:=fn(Geometry.Vec2 pos,[Array,Story] stories){
	var m=gui.createMenu();
	m.entries:=[];
	
	if(stories.isA(Story)){
		var parentStory = stories;
		stories = [];
		foreach(parentStory.getAnimations() as var animation){
			if(animation.isA(Story))
				stories += animation;
		}
	}
	
	foreach(stories as var story){
		m+={
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : this.getNameForStory(story),
			GUI.ON_CLICK : story->fn(){AnimationPlugin.selectStory(this);}
		};
	}
	m.open( pos );
};



// -----------------------------------------------


//!
AnimationPlugin.showWindow:=fn(posX, posY, widht, height){
	if(window){
		window.setEnabled(true);
		window.activate();
		return;
	}
	window=gui.createWindow(widht,height,"StoryBoard editor");
	window.setPosition(posX,posY);

	var toolbar=gui.createPanel(150,15,GUI.AUTO_LAYOUT);
	toolbar.setMargin(0);
	toolbar.setPadding(0);
	
	toolbar += {
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "File",
		GUI.WIDTH : 50,
		GUI.BUTTON_SHAPE : GUI.BUTTON_SHAPE_BOTTOM_LEFT,
		GUI.MENU : [
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "New story",
				GUI.ON_CLICK : this->fn(){
					this.createNewStory();
				}
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Open story...",
				GUI.ON_CLICK : this->fn(){
					gui.openDialog({
						GUI.TYPE : GUI.TYPE_FILE_DIALOG,
						GUI.LABEL : "Open story",
						GUI.DIR : PADrend.getDataPath(),
						GUI.ENDINGS : [".story"],
						GUI.ON_ACCEPT  : this->fn(filename){	this.loadStory(filename);	}
					});
				}
			},			
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Import story...",
				GUI.ON_CLICK : this->fn(){
					gui.openDialog({
						GUI.TYPE : GUI.TYPE_FILE_DIALOG,
						GUI.LABEL : "Import story",
						GUI.DIR : PADrend.getDataPath(),
						GUI.ENDINGS : [".story"],
						GUI.ON_ACCEPT  : this->fn(filename){	this.importStory(filename);	}
					});
				},
				GUI.TOOLTIP : "Load and add a story as one animation block into the current story."
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Merge story...",
				GUI.ON_CLICK : this->fn(){
					gui.openDialog({
						GUI.TYPE : GUI.TYPE_FILE_DIALOG,
						GUI.LABEL : "Merge story",
						GUI.DIR : PADrend.getDataPath(),
						GUI.ENDINGS : [".story"],
						GUI.ON_ACCEPT  : this->fn(filename){	this.mergeStory(filename);	}
					});
				},
				GUI.TOOLTIP : "Add the animations of a saved story into the current story."
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Save story",
				GUI.ON_CLICK : this->fn(){ 
					if(this.activeStory.isSet($filename)){
						this.saveCurrentStory(this.activeStory.filename);
					}else{
						gui.openDialog({
							GUI.TYPE : GUI.TYPE_FILE_DIALOG,
							GUI.LABEL : "Save story",
							GUI.DIR : PADrend.getDataPath(),
							GUI.ENDINGS : [".story"],
							GUI.ON_ACCEPT  : this->fn(filename){	this.saveCurrentStory(filename);	}
						});
					}
				}
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Save story as...",
				GUI.ON_CLICK : this->fn(){
					gui.openDialog({
						GUI.TYPE : GUI.TYPE_FILE_DIALOG,
						GUI.LABEL : "Save story",
						GUI.DIR : PADrend.getDataPath(),
						GUI.ENDINGS : [".story"],
						GUI.ON_ACCEPT  : this->fn(filename){	this.saveCurrentStory(filename);	}
					});					
				}
			}
		]
	};	

	toolbar += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Stop",
		GUI.WIDTH : 40,
		GUI.ON_CLICK : this->fn(){ this.playbackContext.stop();},
		GUI.BUTTON_SHAPE : GUI.BUTTON_SHAPE_MIDDLE,
	};	
	toolbar += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Play",
		GUI.WIDTH : 40,
		GUI.ON_CLICK : this->fn(){ 
			if(this.playbackContext.isPlaying()) {
				this.playbackContext.pause();
			}else {
				this.playbackContext.play();
			
			}
		},
		GUI.BUTTON_SHAPE : GUI.BUTTON_SHAPE_MIDDLE,

	};
	toolbar += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "...",
		GUI.WIDTH : 15,
		GUI.BUTTON_SHAPE : GUI.BUTTON_SHAPE_BOTTOM_RIGHT,
		GUI.ON_CLICK : fn(){
			var entries = [];
			entries += {
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0.1,4],
				GUI.RANGE_STEPS : 39,
				GUI.DATA_VALUE : AnimationPlugin.playbackContext.getTimeScale(),
				GUI.ON_DATA_CHANGED : fn(data){
					AnimationPlugin.playbackContext.setTimeScale(data);
				},
				GUI.LABEL : "Speed"
			};
			gui.openMenu(this.getAbsPosition()+new Geometry.Vec2(-1,this.getWidth()-3),entries,150);
		},
		GUI.TOOLTIP : "Options"
	};
	toolbar.setPosition(new Geometry.Vec2(10,0));
	window.getHeader()+=toolbar;


	var nb = createNavBar(500,20);
	nb.setMargin(1);
	nb.setExtLayout(
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(-24,18) );
	nb.setPosition( new Geometry.Vec2(4,2));
	window+=nb;
	nb.refresh(this.getActiveStory());

	var deleteButton = gui.create({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "X",
		GUI.WIDTH : 15,
		GUI.ON_CLICK : this->fn(){
			var storyToDelete = this.getActiveStory();
			var newStory = storyToDelete.getStory();
			
			storyToDelete.destroy();
			this.stories.removeValue(storyToDelete);
			
			if(!newStory)
				newStory = this.stories[0];
			if(!newStory)
				newStory = this.createNewStory();
			this.selectStory(newStory);
		},
		GUI.TOOLTIP : "Delete active story",
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP , 4,3]
	});

	window+=deleteButton;
	
	rebuildStoryGUI();
			
	Listener.add(Listener.ANIMATION_PLUGIN_ACTIVE_STORY_CHANGED,
		this->fn(...){this.rebuildStoryGUI();} );


	window.setEnabled(true);
	window.activate();
	return;
};

// ---------------------------------------------------------
return AnimationPlugin;
