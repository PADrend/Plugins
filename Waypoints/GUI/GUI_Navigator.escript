/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
**	[Plugin:Waypoints/GUI] Waypoints/GUI.escript
**
** GUI construction for the navigator part of the Waypoints-Plugin.
**/
static PathManagement = Std.module('Waypoints/PathManagement');


static createWaypointScreenshotCell = fn(MinSG.Waypoint waypoint) {
	var cell = gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	PathManagement.getWaypointDescription(waypoint),
		GUI.ON_CLICK			:	[waypoint] => fn(MinSG.Waypoint waypoint) {
											PathManagement.flyTo(waypoint.getTime());
									},
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 120, 90]
	});

	if(waypoint.isSet($shotIcon)) {
		cell += {
			GUI.TYPE				:	GUI.TYPE_ICON,
			GUI.ICON				:	gui.createIcon(waypoint.shotIcon.getImageData(), waypoint.shotIcon.getImageRect()),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 4, 4],
			GUI.POSITION			:	GUI.POSITION_CENTER_XY
		};
	}

	cell += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	waypoint.getTime(),
		GUI.COLOR				:	GUI.BLACK,
		GUI.POSITION			:	[
										GUI.POS_X_ABS | GUI.REFERENCE_X_LEFT | GUI.ALIGN_X_LEFT |
										GUI.POS_Y_ABS | GUI.REFERENCE_Y_TOP | GUI.ALIGN_Y_TOP,
										5, 5
									]
	};
	cell += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	waypoint.getTime(),
		GUI.COLOR				:	GUI.WHITE,
		GUI.POSITION			:	[
										GUI.POS_X_ABS | GUI.REFERENCE_X_RIGHT | GUI.ALIGN_X_RIGHT |
										GUI.POS_Y_ABS | GUI.REFERENCE_Y_BOTTOM | GUI.ALIGN_Y_BOTTOM,
										5, 5
									]
	};

	return cell;
};

return fn(tabbedPanel){
	var panel = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});

	var toolbarEntries=[];
	var iconPath = __DIR__+"/../resources/";
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Prev",
		GUI.ON_CLICK : fn(){	PathManagement.flyToPrevWaypoint();	},
		GUI.ICON : iconPath+"SkipPrev32.png",
		GUI.TOOLTIP : "Fly to previous waypoint",
		GUI.FLAGS : GUI.FLAT_BUTTON
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Play",
		GUI.ON_CLICK : fn(){
			if(!PathManagement.animation_active()){
				// play!
				PathManagement.animation_active(true);
				this.setSwitch(true);
			} else {
				// pause
				PathManagement.animation_active(false);
				this.setSwitch(false);
			}
		},
		GUI.ICON : iconPath+"Next32.png",
		GUI.TOOLTIP : "Fly along the path",
		GUI.FLAGS : GUI.FLAT_BUTTON
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Next",
		GUI.ON_CLICK : fn(){	PathManagement.flyToNextWaypoint();		},
		GUI.ICON : iconPath+"SkipNext32.png",
		GUI.TOOLTIP : "Fly to next waypoint",
		GUI.FLAGS : GUI.FLAT_BUTTON
	};
	var timeSlider = gui.create({
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.TOOLTIP			:	"Select time on path",
		GUI.RANGE			:	[0, 0],
		GUI.RANGE_STEP_SIZE	:	0.1,
		GUI.WIDTH			:	310,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,50,32],
		GUI.DATA_WRAPPER	:	PathManagement.animation_currentTime
	});
	Util.registerExtension('Waypoints_PathChanged', timeSlider -> fn(...) {
		var path = PathManagement.getActivePath();
		if(path) {
			var waypoints = path.getWaypoints();
			if(waypoints.empty()) {
				this.setRange(0, 1, 1);
			} else {
				this.setRange(0, path.getMaxTime(), waypoints.count() *20- 1);
			}
			this.setData(PathManagement.animation_currentTime());
		} else {
			this.setData(0);
		}
	});

	toolbarEntries += timeSlider;

	toolbarEntries+={
		GUI.LABEL:"Settings",
		GUI.MENU:[
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Update screenshots",
				GUI.ON_CLICK : PathManagement -> PathManagement.updateScreenshots,
				GUI.TOOLTIP : "Update screenshots for the waypoint-list"
			},
			"*Camera speed*",
			{
				GUI.TYPE			:	GUI.TYPE_RANGE,
				GUI.RANGE			:	[-2, 3],
				GUI.RANGE_STEPS		:	500,
				GUI.RANGE_FN_BASE	:	10,
				GUI.DATA_WRAPPER	:	PathManagement.animation_speed
			}
		],
		GUI.ICON : iconPath+"Settings32.png",
		GUI.TOOLTIP : "Settings",
		GUI.FLAGS : GUI.FLAT_BUTTON
	};

	panel += gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,5,32],
		GUI.CONTENTS : toolbarEntries
	});

	panel.nextRow(4);
	
	var descriptionText = new Std.DataWrapper("Current waypoint: --");
	panel += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.DATA_WRAPPER : descriptionText
	};
	
	Util.registerExtension('Waypoints_SelectedWaypointChanged',
		[descriptionText] => fn(descriptionText, timestamp){
			// get nearest waypoint
			var path = PathManagement.getActivePath();
			if(!path)
				descriptionText("Waypoint: --");
			else {
				var wps=path.getWaypoints();
				var best_wp=void;
				var best_diff=path.getMaxTime()*2;

				foreach(wps as var wp){
					var diff=(wp.getTime()-timestamp).abs();
					if(diff < best_diff){
						best_wp=wp;
						best_diff=diff;
						if(diff == 0)
							break;
					}
					else
						break;
				}
				var s = "Waypoint: ["+timestamp+"]";
				if(best_wp){
					var description = PathManagement.getWaypointDescription(best_wp);
					if(!description.empty())
						s += " | "+description;
				}
				descriptionText(s);
			}
		});

	panel.nextRow(4);

	var waypointsPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 5, 5]
	});
	waypointsPanel.enableAutoBreak();
	panel += waypointsPanel;

	Util.registerExtension('Waypoints_PathChanged', [waypointsPanel] => fn(container,path) {
		container.clear();
		if(!path) 
			return;

		var waypoints = path.getWaypoints();
		if(waypoints) 
			foreach(waypoints as var waypoint) 
				container += createWaypointScreenshotCell(waypoint);
	});

	var tab = tabbedPanel.addTab("Path-Navigator", panel);
	tab.setTooltip("Navigate along a camera path");
};
