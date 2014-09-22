/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
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
** GUI construction for the editor part of the Waypoints-Plugin.
**/
loadOnce(__DIR__+"/WaypointEditorCell.escript");
static Listener = Std.require('LibUtilExt/deprecated/Listener');

WaypointsPlugin.createEditorTab:=fn(tabbedPanel){
	var pan = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});

	var tw = gui.create({
		GUI.TYPE				:	GUI.TYPE_LIST,
		GUI.OPTIONS				:	[],
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 10, 10],
		GUI.LIST_ENTRY_HEIGHT	:	35
	});

	WaypointsPlugin.updatePath := [tw] => fn(listView, [MinSG.PathNode, void] path) {
		listView.clear();
		if(!path) {
			return;
		}
		var waypoints = path.getWaypoints();
		if(!waypoints) {
			return;
		}
		
		foreach(waypoints as var waypoint) {
			listView += [waypoint, createWaypointCell(waypoint, listView)];
		}
	};

	registerExtension('Waypoints_PathChanged', WaypointsPlugin -> WaypointsPlugin.updatePath);

	/**
	* Button-bar
	*/
	// Add waypoint-buttons
	var toolbarEntries = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MINIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW	
	});
	var iconPath=__DIR__+"/../resources/";

	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "+Below",
		GUI.ON_CLICK : [tw] => fn(listView) {
			var path = WaypointsPlugin.getCurrentPath();
			if(!path)
				return;

			var wp = void;

			var markedComponents = listView.getData();
			if(!markedComponents.empty()) {
				wp = markedComponents[0];
			}

			if(wp == void) {
				// take first waypoint
				var wps=path.getWaypoints();
				if(wps)
					wp=wps[0];
			}

			if(wp != void) {
				var nextTime=void;
				foreach( path.getWaypoints() as var key,var wpNext){
					nextTime = wpNext.getTime();
					if(nextTime > wp.getTime()) {
						break;
					}
				}
				if(nextTime == void) {
					nextTime = wp.getTime()+1;
				}
				else {
					nextTime = (nextTime+wp.getTime())/2.0;
				}

				// add waypoint at nextTime
				WaypointsPlugin.createWaypointAtCam( nextTime);
				// Select the new waypoint
				listView.setData(path.getWaypoint(nextTime));
			}
		},
		GUI.ICON : iconPath+"AddBelow32.png",
		GUI.TOOLTIP : "Add waypoint below (first) selected waypoint"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Add",
		GUI.ON_CLICK : [tw] => fn(listView) {
			var path = WaypointsPlugin.getCurrentPath();
			if(!path)
				return;

			var nextTime=path.countChildren() == 0 ? 0 : path.getMaxTime()+1;
			WaypointsPlugin.createWaypointAtCam( nextTime);
			// Select the new waypoint
			listView.setData(path.getWaypoint(nextTime));
		},
		GUI.ICON : iconPath+"Add32.png",
		GUI.TOOLTIP : "Add waypoint at end of path"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "+Loop",
		GUI.ON_CLICK : [tw] => fn(listView) {
			var path = WaypointsPlugin.getCurrentPath();
			if(!path)
				return;

			if(path.countChildren() == 0)
				return;

			var nextTime=path.getMaxTime()+1;
			WaypointsPlugin.closeLoop();
			// Select the new waypoint
			listView.setData(path.getWaypoint(nextTime));
		},
		GUI.ICON : iconPath+"CloseLoop32.png",
		GUI.TOOLTIP : "Add waypoint to close loop (same SRT as first waypoint)"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Reload",
		GUI.ON_CLICK : fn(){
			executeExtensions('Waypoints_PathChanged', WaypointsPlugin.getCurrentPath());
		},
		GUI.ICON : iconPath+"Reload32.png",
		GUI.TOOLTIP : "Refresh list of waypoints"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Delete",
		GUI.ON_CLICK : [tw] => fn(listView) {
			var markedWaypoints = listView.getData();
			listView.setData(void);
			foreach(markedWaypoints as var waypoint) {
				WaypointsPlugin.removeWaypoint(waypoint);
			}
		},
		GUI.ICON : iconPath+"Trash32.png",
		GUI.TOOLTIP : "Delete ALL selected waypoints"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Swap",
		GUI.ON_CLICK : [tw] => fn(listView) {
			var markedWaypoints = listView.getData();

			if(markedWaypoints.count() != 2) {
				PADrend.message("Please select two waypoints.");
			} else {
				var wp1 = markedWaypoints[0];
				var wp2 = markedWaypoints[1];

				var srt = wp1.getRelTransformationSRT();
				var desc = WaypointsPlugin.getWaypointDescription(wp1);

				WaypointsPlugin.changeWaypoint(wp1, void, WaypointsPlugin.getWaypointDescription(wp2), wp2.getRelTransformationSRT());
				WaypointsPlugin.changeWaypoint(wp2, void, desc, srt);
			}
		},
		GUI.ICON : iconPath+"Swap32.png",
		GUI.TOOLTIP : "Swap selected waypoints (timestamp)"
	};
	
	var speedDataWrapper = DataWrapper.createFromValue(1.0);
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Timestamp",
		GUI.MENU : [
			{
				GUI.TYPE 			:	GUI.TYPE_BUTTON,
				GUI.LABEL			:	"Set to indices",
				GUI.TOOLTIP			:	"Calculate timestamps from indices",
				GUI.ON_CLICK		:	WaypointsPlugin -> WaypointsPlugin.setTimecodesToIndices
			},
			"*From distance*",
			{
				GUI.TYPE			:	GUI.TYPE_RANGE,
				GUI.TOOLTIP			:	"Movement speed for timestamp from distance",
				GUI.RANGE			:	[0, 20],
				GUI.DATA_WRAPPER	:	speedDataWrapper
			},
			{
				GUI.LABEL			:	"Calculate",
				GUI.TOOLTIP			:	"Calculate by distance and speed (slider)",
				GUI.ON_CLICK		:	[tw, speedDataWrapper] => fn(listView, speed) {
											WaypointsPlugin.setTimecodesByDistance(WaypointsPlugin.getCurrentPath(), speed());
										}
			}

		],
		GUI.ICON : iconPath+"Time32.png",
		GUI.TOOLTIP : "Options to recalculate timestamps"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Shots",
		GUI.ON_CLICK : fn(){
			// choose directory and size
			var fileDialog=new GUI.FileDialog("Save screenshots",PADrend.getDataPath(),[""],fn(files){
				if(!WaypointsPlugin.getCurrentPath())
					return;

				var wps = WaypointsPlugin.getCurrentPath().getWaypoints();
				var oldViewport=camera.getViewport();
				var oldSRT=PADrend.getDolly().getRelTransformationSRT();

				if(!dir.endsWith('/'))
					dir+='/';

				camera.setViewport(new Geometry.Rect(0,0,edtWidth.getText(),edtHeight.getText()));
				foreach(wps as var wp){
					PADrend.getDolly().setRelTransformation(wp.getRelTransformationSRT());
					// -------------------
					// ---- Render Scene
					frameContext.beginFrame();
					frameContext.setCamera(camera);
					renderingContext.clearScreen(PADrend.getBGColor());
					PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());

					var filename= dir+"wp_"+wp.getTime();
					//filename+=".bmp";
					var tex=Rendering.createTextureFromScreen();
					//var b=Rendering.saveTexture(renderingContext,tex,filename+".bmp");
					var desc=wp.getNodeAttribute('desc');
					if(desc && desc != ""){
						Rendering.saveTexture(renderingContext,tex,filename+"_("+desc+").bmp");
					} else {
						Rendering.saveTexture(renderingContext,tex,filename+".bmp");
					}
					PADrend.SystemUI.swapBuffers();
				}
				PADrend.getDolly().setRelTransformation(oldSRT);
				camera.setViewport(oldViewport);
			});
			fileDialog.folderSelector:=true;
			var optionPanel=fileDialog.createOptionPanel(150,240);
			optionPanel.add(gui.createLabel("Width: "));
			optionPanel.nextColumn();
			fileDialog.edtWidth:=gui.createTextfield(80,15,640);
			optionPanel.add(fileDialog.edtWidth);
			optionPanel.nextRow();
			optionPanel.add(gui.createLabel("Height: "));
			optionPanel.nextColumn();
			fileDialog.edtHeight:=gui.createTextfield(80,15,480);
			optionPanel.add(fileDialog.edtHeight);
			optionPanel.nextRow(4);

			fileDialog.init();
		},
		GUI.ICON : iconPath+"Screenshot32.png",
		GUI.TOOLTIP : "Save screenshots of each waypoint in some directory"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Undo",
		GUI.ON_CLICK : WaypointsPlugin -> WaypointsPlugin.getCommandHistory().undo,
		GUI.ON_INIT : fn(description){
			Listener.add( Listener.CMD_UNDO_REDO_CHANGED,
				this->fn(type,sender){
					if(sender != WaypointsPlugin.getCommandHistory())
						return;

					if(!sender.canUndo())
						this.setTooltip("Nothing to be undone");
					else {
						this.setTooltip("Undo \""+sender.getUndoTop().getDescription()+"\"");
					}
				});
		},
		GUI.ICON : iconPath+"Undo32.png",
		GUI.TOOLTIP : "Nothing to be undone"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Redo",
		GUI.ON_CLICK : WaypointsPlugin -> WaypointsPlugin.getCommandHistory().redo,
		GUI.ON_INIT : fn(description){
			Listener.add( Listener.CMD_UNDO_REDO_CHANGED,
				this->fn(type,sender){
					if(sender != WaypointsPlugin.getCommandHistory())
						return;

					if(!sender.canRedo())
						this.setTooltip("Nothing to be redone");
					else {
						this.setTooltip("Redo \""+sender.getRedoTop().getDescription()+"\"");
					}
				});
		},
		GUI.ICON : iconPath+"Redo32.png",
		GUI.TOOLTIP : "Nothing to be redone"
	};

	pan += toolbarEntries;
	pan++;

	pan += tw;

	var tab=tabbedPanel.addTab("Path-Editor",
		pan
		);
	tab.setTooltip("Editor for paths");
};
