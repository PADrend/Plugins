/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2011 Robert Gmyr
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Waypoints] Waypoints/Plugin.escript
 ** 2008-11
 **/

/***
 **   WaypointsPlugin ---|> Plugin
 **/
GLOBALS.WaypointsPlugin:=new Plugin({
		Plugin.NAME : 'Waypoints',
		Plugin.DESCRIPTION : 
			"Manages and creates paths (MinSG.PathNodes).\n"+
            " [p] ... add waypoint to current path.\n"+
            " [PgUp]/[PgDown] ... fly to next/prev waypoint",
		Plugin.VERSION : 1.2,
		Plugin.AUTHORS : "Jan Krems, Claudius Jaehn, Benjamin Eikel",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : [
			/**
			 * [public, event]
			 * Executed when the path has/was changed. That is when
			 * 1. the count of waypoints has changed
			 * 2. the index of a waypoint has changed (timestamp changed)
			 * 3. the attributes of a waypoint have changed
			 *
			 * Argument: The path
			 */
			'Waypoints_PathChanged',

			/**
			 * [public, event]
			 * Executed when the path list has/was changed. That is when
			 * 1. a new path is added (loaded/created)
			 * 2. a path is removed (not implemented yet)
			 *
			 * Argument: WaypointsPlugin
			 *
			 * Changes:
			 * 1. count of paths (WaypointsPlugin.getPaths)
			 */
			'Waypoints_PathListChanged',

			/**
			 * [public, event]
			 * Executed when the current waypoint has/was changed. That is when
			 * 1. The target of "flyTo" has been reached
			 *
			 * Argument: The new position (timestamp)
			 *
			 * Changes:
			 * 1. The current waypoint (WaypointsPlugin.getCurrentWaypoint)
			 */
			'Waypoints_SelectedWaypointChanged',

			/**
			 * [public, event]
			 * Executed when something gets attached/detached to/from
			 * the current path.
			 *
			 * Argument: A string ("cam", "pig", etc.)
			 *
			 * Changes:
			 * 1. If the pig is attached (WaypointsPlugin.isPigAttached)
			 * 2. If the camera is attached (WaypointsPlugin.isCameraAttached)
			 */
			'Waypoints_PathAttachmentChanged'
		]
});


Std.require('LibUtilExt/Command');

loadOnce(__DIR__+"/Interface.escript");
loadOnce(__DIR__+"/GUI/GUI.escript");
loadOnce(__DIR__+"/GUI/GUI_Editor.escript");
loadOnce(__DIR__+"/GUI/GUI_Navigator.escript");

/**
 * Plugin initialization.
 * ---|> Plugin
 */
WaypointsPlugin.init:=fn() {
	Util.requirePlugin('NodeEditor');


	{	// Register ExtensionPointHandler:
		registerExtension('PADrend_AfterFrame',    			this->this.ex_AfterFrame);
		registerExtension('PADrend_AfterRenderingPass',    this->this.ex_AfterRenderingPass);
		registerExtension('PADrend_Init',               this->this.ex_Init);
        registerExtension('PADrend_KeyPressed',         this->this.ex_KeyPressed);
	}
    {   //  variables
        this.paths:=void;//[];	// buffered path-list, void means not valid
        this.curPath:=void;	// current/selected path
        this.showPath:=false;

        // inserting of waypoints
        this.insertIndex:=0;

        // flight control
        this.flight_startTime:=void;
        this.flight_startPoint:=void;
        this.flight_endTime:=void;
        this.flight_endPoint:=void;
        this.flight_targetIndex:=0;
        this.flight_time:=systemConfig.getValue('Waypoint.flightTime',1.0);
        this.polynomPoints:=[ new Geometry.Vec2(0,0),new Geometry.Vec2(0.3,0.2),new Geometry.Vec2(0.8,0.9),new Geometry.Vec2(1,1)];

        // attaching objects
        this.pig:=void;				// used to store the pig-node (so it has not to be created every time)
		this.pigAttached:=false;
		this.pigSpeed:=1.0;
		this.pigPause:=false;
		this.cameraAttached:=false;
		this.cameraSpeed:=1.0;
		this.cameraPause:=false;
	}
	{
		// Command history (Util/Command.escript)
		this.cmdHistory:=new CommandHistory;
	}
	
	Util.requirePlugin('PADrend/RemoteControl').registerFunctions({
		// [ [time,description]* ] 
		'Waypoints.getWaypointList' : this->fn(){
			var path = WaypointsPlugin.getCurrentPath();
			if(!path){
				PADrend.message("No active path.");
				return [];
			}
			var wps = [];
			foreach(path.getWaypoints() as var wp){
				wps += [wp.getTime(), WaypointsPlugin.getWaypointDescription(wp)];
			}
			return wps;
		},
		'Waypoints.flyTo' : this->fn(time){
			WaypointsPlugin.flyTo(time,2.5);
		}
	});
	return true;
};

// see Util/Command.escript
WaypointsPlugin.getCommandHistory:=fn(){
	return this.cmdHistory;
};

/**
 * [ext:PADrend_Init
 */
WaypointsPlugin.ex_Init:=fn(){
	// used for attaching camera/pig to the path
	this.behaviourManager:=new MinSG.BehaviourManager();

	// load inital path if set in config
	var f=systemConfig.getValue('Waypoint.initialPath',false);
	if(f)
		loadPath(f);

	gui.registerComponentProvider('PADrend_MainWindowTabs.20_Waypoints',this->createMainWindowTab);
};



/**
 * [ext:PADrend_AfterFrame]
 */
WaypointsPlugin.ex_AfterFrame:=fn(...){
    this.behaviourManager.executeBehaviours(PADrend.getSyncClock());

    if(flight_endPoint){
        var currentPos;
        var now=PADrend.getSyncClock();
        if(now>flight_endTime){
            currentPos=this.flight_endPoint;
            this.flight_startTime=false;
            this.flight_startPoint=void;
            this.flight_endTime=false;
            this.flight_endPoint=void;
        }else{
            var d = (now-flight_startTime) / (flight_endTime-flight_startTime);
            d = Geometry.interpolate2dPolynom(this.polynomPoints,d);
//            d=d.pow(1.5);
            currentPos=new Geometry.SRT(this.flight_startPoint,this.flight_endPoint,d);
        }
        PADrend.getDolly().setRelTransformation(currentPos);
    } else if(this.isCameraAttached() && !this.isCameraPause()){
    	executeExtensions('Waypoints_SelectedWaypointChanged', this.getCameraTimestamp() );
    }
};

WaypointsPlugin.getCameraTimestamp:=fn(){
	var time = this.followPathBehavior.getPosition();
	var maxTime = curPath.getMaxTime();
	if(time > maxTime && maxTime!=0 )
		time-=(time/maxTime).floor() * maxTime;
	while(time < 0){
		time += maxTime;
	}
	return time;
};

/**
 * [ext:PADrend_KeyPressed]
 */
WaypointsPlugin.ex_KeyPressed:=fn(evt) {
	if (evt.key == Util.UI.KEY_P){  // add way [p]oint
        WaypointsPlugin.createWaypointAtCam();
        return true;
	}else if (evt.key==Util.UI.KEY_KPMULTIPLY){  // '*' on keypad
		WaypointsPlugin.flyToNextWaypoint();
	    return true;
	}else if (evt.key==Util.UI.KEY_KPDIVIDE){  // '/' on keypad
		WaypointsPlugin.flyToPrevWaypoint();
	    return true;
	}

    return false;
};
/**
 * [ext:PADrend_AfterRenderingPass]
 */
WaypointsPlugin.ex_AfterRenderingPass:=fn(...){
	if(!showPath || !getCurrentPath())
		return;

	var path = getCurrentPath();
	renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
	renderingContext.multMatrix_modelToCamera(path.getWorldTransformationMatrix());
	renderingContext.applyChanges();
	path.display(frameContext, MinSG.SHOW_META_OBJECTS);
	renderingContext.popMatrix_modelToCamera();
};


/*! Shortcut for use in console. */
GLOBALS.flyTo:=WaypointsPlugin->WaypointsPlugin.flyTo;

return WaypointsPlugin;
// ------------------------------------------------------------------------------
