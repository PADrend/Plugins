/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
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
static PathManagement = Std.require('Waypoints/PathManagement');

static createWaypointCell = fn(MinSG.Waypoint waypoint, listView) {
	var cell = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});

	cell.txtDesc := gui.create({
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Description",
		GUI.TEXT_ALIGNMENT		:	GUI.TEXT_ALIGN_MIDDLE,
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.3, 33]
	});
	cell.edtDesc := gui.create({
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Description",
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.3, 33]
	});

	cell.txtTime := gui.create({
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Time",
		GUI.TEXT_ALIGNMENT		:	GUI.TEXT_ALIGN_MIDDLE,
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.2, 33]
	});
	cell.edtTime := gui.create({
		GUI.TYPE				:	GUI.TYPE_NUMBER,
		GUI.LABEL				:	"Time",
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.2, 33]
	});

	cell.createEditGUI := [waypoint] => fn(MinSG.Waypoint waypoint) {
		this.clear();

		this.add(this.iconArea);
		this.add(this.edtTime);
		this.add(this.edtDesc);
		this.add(this.btnSetPos);
		this.add(this.btnCancel);
		this.add(this.btnSave);

		this.btnSetPos.setSwitch(false);
		this.btnSetPos.newSRT := void;
		this.btnSetPos.oldSRT := waypoint.getRelTransformationSRT();

		this.update();
	};

	cell.createViewGUI := fn() {
		this.clear();

		this.add(this.iconArea);
		this.add(this.txtTime);
		this.add(this.txtDesc);
		this.add(this.btnFlyTo);
		this.add(this.btnEdit);

		this.update();
	};

	cell.btnSave := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save",
		GUI.TOOLTIP				:	"Save changes",
		GUI.ON_CLICK			:	[cell,waypoint] => fn(cell, waypoint) {
										waypoint.setRelTransformation(cell.btnSetPos.oldSRT);
										PathManagement.updateWaypoint(waypoint,
											cell.edtTime.getData(),
											cell.edtDesc.getData(),
											cell.btnSetPos.newSRT
										);
										cell.createViewGUI();
									},
		GUI.SIZE				:	[GUI.HEIGHT_ABS, 0, 33]
	});
	cell.btnCancel := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Cancel",
		GUI.TOOLTIP				:	"Cancel edit",
		GUI.ON_CLICK			:	[cell,waypoint] => fn(cell, waypoint) {
										waypoint.setRelTransformation(cell.btnSetPos.oldSRT);
										cell.createViewGUI();
									},
		GUI.SIZE				:	[GUI.HEIGHT_ABS, 0, 33]
	});

	cell.btnEdit := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.ICON				:	__DIR__ + "/../resources/Edit32.png",
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Edit waypoint",
		GUI.FLAGS				:	GUI.FLAT_BUTTON,
		GUI.ON_CLICK			:	cell -> cell.createEditGUI
	});

	cell.btnFlyTo := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.ICON				:	__DIR__ + "/../resources/Goto32.png",
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Fly to waypoint",
		GUI.FLAGS				:	GUI.FLAT_BUTTON,
		GUI.ON_CLICK			:	[waypoint,listView] => fn(MinSG.Waypoint waypoint, listView) {
										PathManagement.flyTo(waypoint.getTime());
										listView.setData(waypoint);
									}
	});

	cell.btnSetPos := gui.create({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.ICON				:	__DIR__ + "/../resources/Position32.png",
		GUI.LABEL				:	"",
		GUI.TOOLTIP				:	"Set waypoint's SRT to current camera's SRT",
		GUI.FLAGS				:	GUI.FLAT_BUTTON,
		GUI.ON_CLICK			:	[waypoint] => fn(MinSG.Waypoint waypoint) {
										this.newSRT = PADrend.getDolly().getRelTransformationSRT();
										waypoint.setRelTransformation(this.newSRT);
									}
	});
	cell.btnSetPos.newSRT := void;
	cell.btnSetPos.oldSRT := void;

	cell.iconArea := gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 44, 33]
	});
	cell.update := [waypoint] => fn(MinSG.Waypoint waypoint) {
		this.iconArea.clear();

		if(waypoint != void){
			// update gui
			var tmp=PathManagement.getWaypointDescription(waypoint);
			this.edtDesc.setData(tmp);
			this.txtDesc.setText(tmp);

			tmp=waypoint.getTime();
			this.edtTime.setData(tmp);
			this.txtTime.setText(tmp);

			if(waypoint.isSet($shotIcon)) {
				iconArea += {
					GUI.TYPE				:	GUI.TYPE_ICON,
					GUI.ICON				:	gui.createIcon(waypoint.shotIcon.getImageData(), waypoint.shotIcon.getImageRect()),
					GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 44, 33]
				};
			}
		} else {
			// hide gui, show error
			this.edtDesc.setData("!!!! ERROR !!!!");
			this.txtDesc.setText("!!!! ERROR !!!!");
		}
	};

	cell.createViewGUI();

	return cell;
};

return fn(tabbedPanel){
	var panel = gui.create({
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

	registerExtension('Waypoints_PathChanged', [tw] => fn(listView, [MinSG.PathNode, void] path) {
		listView.clear();
		if(!path)
			return;
		var waypoints = path.getWaypoints();
		if(!waypoints)
			return;
		foreach(waypoints as var waypoint)
			listView += [waypoint, createWaypointCell(waypoint, listView)];
	});

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
			var path = PathManagement.getActivePath();
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
				PathManagement.createWaypointAtCam( nextTime);
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
			var path = PathManagement.getActivePath();
			if(!path)
				return;

			var nextTime=path.countChildren() == 0 ? 0 : path.getMaxTime()+1;
			PathManagement.createWaypointAtCam( nextTime);
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
			var path = PathManagement.getActivePath();
			if(!path)
				return;

			if(path.countChildren() == 0)
				return;

			var nextTime=path.getMaxTime()+1;
			PathManagement.closeLoop();
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
			executeExtensions('Waypoints_PathChanged', PathManagement.getActivePath());
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
				PathManagement.removeWaypoint(waypoint);
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
				var desc = PathManagement.getWaypointDescription(wp1);

				PathManagement.updateWaypoint(wp1, void, PathManagement.getWaypointDescription(wp2), wp2.getRelTransformationSRT());
				PathManagement.updateWaypoint(wp2, void, desc, srt);
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
				GUI.ON_CLICK		:	PathManagement -> PathManagement.setTimecodesToIndices
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
											PathManagement.setTimecodesByDistance(PathManagement.getActivePath(), speed());
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
			var fileDialog=new (module('LibGUIExt/FileDialog'))("Save screenshots",PADrend.getDataPath(),[""],fn(files){
				if(!PathManagement.getActivePath())
					return;

				var wps = PathManagement.getActivePath().getWaypoints();
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
		GUI.ON_CLICK : fn(){ PathManagement.getCommandHistory().undo(); },
		GUI.ON_INIT : fn(description){
			PathManagement.getCommandHistory().onUndoRedoChanged += this->fn(){
				if(!PathManagement.getCommandHistory().canUndo())
					this.setTooltip("Nothing to be undone.");
				else 
					this.setTooltip("Undo \""+PathManagement.getCommandHistory().getUndoTop().getDescription()+"\"");
			};
		},
		GUI.ICON : iconPath+"Undo32.png",
		GUI.TOOLTIP : "Nothing to be undone"
	};
	toolbarEntries+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Redo",
		GUI.ON_CLICK : fn(){ PathManagement.getCommandHistory().redo(); },
		GUI.ON_INIT : fn(description){
			PathManagement.getCommandHistory().onUndoRedoChanged += this->fn(){
				if(!PathManagement.getCommandHistory().canRedo())
					this.setTooltip("Nothing to be redone.");
				else 
					this.setTooltip("Redo \""+PathManagement.getCommandHistory().getRedoTop().getDescription()+"\"");

			};
		},
		GUI.ICON : iconPath+"Redo32.png",
		GUI.TOOLTIP : "Nothing to be redone"
	};

	panel += toolbarEntries;
	panel++;

	panel += tw;

	var tab=tabbedPanel.addTab("Path-Editor",
		panel
		);
	tab.setTooltip("Editor for paths");
};
