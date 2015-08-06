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
 **/

/***
 **   WaypointsPlugin ---|> Plugin
 **/
GLOBALS.WaypointsPlugin := new Plugin({
		Plugin.NAME : 'Waypoints',
		Plugin.DESCRIPTION :
			"Manages and creates paths (MinSG.PathNodes).\n"+
            " [p] ... add waypoint to current path.\n"+
            " [PgUp]/[PgDown] ... fly to next/prev waypoint",
		Plugin.VERSION : 1.2,
		Plugin.AUTHORS : "Jan Krems, Claudius Jaehn, Benjamin Eikel",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['SceneEditor'],
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
			 * Executed when the current waypoint has/was changed. That is when
			 * 1. The target of "flyTo" has been reached
			 *
			 * Argument: The new position (timestamp)
			 *
			 * Changes:
			 * 1. The current waypoint (WaypointsPlugin.getCurrentWaypoint)
			 */
			'Waypoints_SelectedWaypointChanged',

		]
});


static PathManagement = Std.module('Waypoints/PathManagement');

WaypointsPlugin.init @(override) := fn() {
	Util.requirePlugin('NodeEditor');

	Util.registerExtension('PADrend_Init', fn(){
		// load inital path if set in config
		var f = systemConfig.getValue('Waypoint.initialPath',false);
		if(f)
			PathManagement.loadPath(f);

		PathManagement.animation_attachedCamera(PADrend.getDolly());

		var t = new (Std.module('Waypoints/Tool_PathEditor'));
		PADrend.registerUITool('PathTools_PathEditor')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	});
	module.on('PADrend/gui',fn(gui){
		gui.register('PADrend_MainWindowTabs.20_Waypoints',fn(){
			return Std.module('Waypoints/GUI/GUI')();
		});

		gui.loadIconFile( __DIR__+"/resources/Icons.json");

		static Style = module('PADrend/GUI/Style');
		static switchFun = fn(button,b){
			if(button.isDestroyed())
				return $REMOVE;
			foreach(Style.TOOLBAR_ACTIVE_BUTTON_PROPERTIES as var p)
				b ? button.addProperty(p) : button.removeProperty(p);
		};

		gui.register('PADrend_ToolsToolbar.90_pathTools', [{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.PRESET : './toolIcon',
			GUI.ICON : '#PathEditMode',
			GUI.WIDTH : 24,
			GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('PathTools_PathEditor');	},
			GUI.ON_INIT : fn(){
				PADrend.accessUIToolConfigurator('PathTools_PathEditor')
					.registerActivationListener( [this,true]=>switchFun )
					.registerDeactivationListener( [this,false]=>switchFun );
			},
			GUI.TOOLTIP : "PathEditor: Edit a path node's waypoints."
		}]);
	});

	Util.requirePlugin('PADrend/RemoteControl').registerFunctions({
		// [ [time,description]* ]
		'Waypoints.getWaypointList' : this->fn(){
			var path = PathManagement.getActivePath();
			if(!path){
				PADrend.message("No active path.");
				return [];
			}
			var wps = [];
			foreach(path.getWaypoints() as var wp){
				wps += [wp.getTime(), PathManagement.getWaypointDescription(wp)];
			}
			return wps;
		},
		'Waypoints.flyTo' : this->fn(time){
			PathManagement.flyTo(time,2.5);
		}
	});
	return true;
};

// public interface
WaypointsPlugin.animation_speed := PathManagement.animation_speed;
WaypointsPlugin.createPath := PathManagement.createPath;
WaypointsPlugin.createWaypointAtCam := PathManagement.createWaypointAtCam;
WaypointsPlugin.flyTo := PathManagement.flyTo;
WaypointsPlugin.getActivePath := PathManagement.getActivePath;
WaypointsPlugin.getRegisteredPaths := PathManagement.getRegisteredPaths;
WaypointsPlugin.loadPath := PathManagement.loadPath;
WaypointsPlugin.removeWaypoint := PathManagement.removeWaypoint;
WaypointsPlugin.setWaypointDescription := PathManagement.setWaypointDescription;

return WaypointsPlugin;
// ------------------------------------------------------------------------------
