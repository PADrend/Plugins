/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
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
loadOnce(__DIR__+"/WaypointScreenshotCell.escript");

WaypointsPlugin.createNavigatorTab:=fn(tabbedPanel){
	var pan = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});

	// we start with camera paused but attached
	WaypointsPlugin.setCameraPause(true);
	WaypointsPlugin.attachCamera();

	var toolbarEntries=[];
	var iconPath=__DIR__+"/../resources/";
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Prev",
		GUI.ON_CLICK : fn(){
			WaypointsPlugin.flyToPrevWaypoint();
		},
		GUI.ICON : iconPath+"SkipPrev32.png",
		GUI.TOOLTIP : "Fly to previous waypoint"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Play",
		GUI.ON_CLICK : fn(){
			if(WaypointsPlugin.isCameraPause()){
				// play!
				WaypointsPlugin.attachCamera();
				WaypointsPlugin.setCameraPause(false);
				this.setSwitch(true);
			} else {
				// pause
				WaypointsPlugin.setCameraPause(true);
				this.setSwitch(false);
			}
		},
		'initFunc':fn(){
			registerExtension('Waypoints_PathAttachmentChanged',
				this->fn(attachment){
					if(attachment == 'cam'){
						this.setSwitch(!WaypointsPlugin.isCameraPause());
					}
				});
		},
		GUI.ICON : iconPath+"Next32.png",
		GUI.TOOLTIP : "Fly along the path"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Next",
		GUI.ON_CLICK : fn(){
			WaypointsPlugin.flyToNextWaypoint();
		},
		GUI.ICON : iconPath+"SkipNext32.png",
		GUI.TOOLTIP : "Fly to next waypoint"
	};
	var slWaypoints = gui.create({
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.TOOLTIP			:	"Select time on path",
		GUI.RANGE			:	[0, 0],
		GUI.RANGE_STEPS		:	0,
		GUI.WIDTH			:	310,
		GUI.HEIGHT			:	32,
		GUI.ON_DATA_CHANGED	:	WaypointsPlugin -> WaypointsPlugin.flyTo
	});
	var sliderUpdateFunc = slWaypoints -> fn(__ignored) {
		var path = WaypointsPlugin.getCurrentPath();
		if(path) {
			var waypoints = path.getWaypoints();
			if(waypoints.empty()) {
				this.setRange(0, 0, 0);
			} else {
				this.setRange(0, path.getMaxTime(), waypoints.count() - 1);
			}
			this.setData(WaypointsPlugin.getSelectedWaypoint());
		} else {
			this.setData(0);
		}
	};
	registerExtension('Waypoints_PathChanged', sliderUpdateFunc);
	registerExtension('Waypoints_SelectedWaypointChanged', slWaypoints -> fn(timecode) {
		this.setData(timecode);
	});
	toolbarEntries += slWaypoints;

	var cameraSpeed = DataWrapper.createFromFunctions(	WaypointsPlugin -> WaypointsPlugin.getCameraSpeed, 
														WaypointsPlugin -> WaypointsPlugin.setCameraSpeed,
														true);
	registerExtension(	'Waypoints_PathAttachmentChanged', 
						(fn(newAttachment, dataWrapper) {
							dataWrapper.refresh();
						}).bindLastParams(cameraSpeed));

	toolbarEntries+={
		GUI.LABEL:"Settings",
		GUI.MENU:[
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Update screenshots",
				GUI.ON_CLICK : WaypointsPlugin -> WaypointsPlugin.updateScreenshots,
				GUI.TOOLTIP : "Update screenshots for the waypoint-list"
			},
			"*Camera speed*",
			{
				GUI.TYPE			:	GUI.TYPE_RANGE,
				GUI.RANGE			:	[-2, 3],
				GUI.RANGE_STEPS		:	500,
				GUI.RANGE_FN_BASE	:	10,
				GUI.DATA_WRAPPER	:	cameraSpeed
			}
		],
		GUI.ICON : iconPath+"Settings32.png",
		GUI.TOOLTIP : "Settings"
	};

	var toolbar=gui.createToolbar(500,32, toolbarEntries);
	pan += toolbar;

	pan.nextRow(4);
	pan.add(gui.createLabel("Description:"));
	var txtDesc=gui.createLabel("<no description>");
	registerExtension('Waypoints_SelectedWaypointChanged',
		txtDesc->fn(timestamp){
			// get nearest waypoint
			var path=WaypointsPlugin.getCurrentPath();
			if(!path)
				this.setText("<no description>");
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
				//out("Timestamp "+timestamp+", best diff: "+best_diff\n");
				this.setText(best_wp ? WaypointsPlugin.getWaypointDescription(best_wp) : "<no description>");
			}
		});
	pan.add(txtDesc);

	pan.nextRow(4);

	var waypointsPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 5, 5]
	});
	waypointsPanel.enableAutoBreak();
	pan += waypointsPanel;

	registerExtension('Waypoints_PathChanged', (fn(path, container) {
		container.clear();
		if(!path) {
			return;
		}
		var waypoints = path.getWaypoints();
		if(!waypoints) {
			return;
		}

		foreach(waypoints as var waypoint) {
			container += WaypointsPlugin.createWaypointScreenshotCell(waypoint);
		}
	}).bindLastParams(waypointsPanel));

	var tab = tabbedPanel.addTab("Path-Navigator", pan);
	tab.setTooltip("Navigation inside a path");
};
