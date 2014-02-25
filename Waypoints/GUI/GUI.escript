/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
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
** GUI construction for the Waypoints-Plugin.
**/

WaypointsPlugin.getWaypointDescription:=fn(wp,def=""){
	var desc = wp.getNodeAttribute('desc');
	return desc ? desc : def;
};

WaypointsPlugin.setWaypointDescription:=fn(wp,desc){
	if(desc=="")
		wp.unsetNodeAttribute('desc');
	else
		wp.setNodeAttribute('desc',desc);
};

WaypointsPlugin.createPathMenu := fn() {
	var paths = WaypointsPlugin.collectPaths();
	var pathListEntries = [];
	foreach(paths as var path) {
		pathListEntries += [path, {
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 0],
			GUI.CONTENTS			:	[
											path.name ? path.name : NodeEditor.getString(path.getParent()) + ":" + NodeEditor.getString(path.toString()),
											{
												GUI.TYPE				:	GUI.TYPE_MENU,
												GUI.LABEL				:	"->",
												GUI.TOOLTIP				:	"Path opertions ...",
												GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 20, 15],
												GUI.MENU				:	[
																				"*Attach to ...*",
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"... root",
																					GUI.ON_CLICK	:	(fn(MinSG.PathNode path) {
																											WaypointsPlugin.attachPath(path,PADrend.getRootNode());
																										}).bindFirstParams(path)
																				},
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"... scene",
																					GUI.ON_CLICK	:	(fn(MinSG.PathNode path) {
																											WaypointsPlugin.attachPath(path,PADrend.getCurrentScene());
																										}).bindFirstParams(path)
																				},
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"... selected node",
																					GUI.ON_CLICK	:	(fn(MinSG.PathNode path) {
																											WaypointsPlugin.attachPath(path,NodeEditor.getSelectedNode());
																										}).bindFirstParams(path)
																				},
																				"----",
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"Select PathNode",
																					GUI.TOOLTIP		:	"Select PathNode in NodeEditor",
																					GUI.ON_CLICK	:	(fn(MinSG.PathNode path) {
																											NodeEditor.selectNode(path);
																										}).bindFirstParams(path)
																				},
																				"----",
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"Delete",
																					GUI.ON_CLICK	:	(fn(MinSG.PathNode path) {
																											MinSG.destroy(path);
																											executeExtensions('Waypoints_PathListChanged');
																											gui.closeAllMenus();
																										}).bindFirstParams(path)
																				}
																			]
											}
										]
		}];
	}

	var pathMenu = [];
	pathMenu += {
		GUI.TYPE				:	GUI.TYPE_LIST,
		GUI.OPTIONS				:	pathListEntries,
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 500, 150],
		GUI.DATA_PROVIDER		:	WaypointsPlugin -> WaypointsPlugin.getCurrentPath,
		GUI.ON_DATA_CHANGED		:	fn(data) {
											if(!data || data.empty()) {
												return;
											}
											WaypointsPlugin.activatePath(data[0]);
									}
	};
	return pathMenu;
};

/**
* Creates the panel used to select the path, create a path, load, save etc.
*/
WaypointsPlugin.addPathMenu:=fn(panel=void){
	var toolBar = [];
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"New",
		GUI.TOOLTIP				:	"Create new path",
		GUI.ON_CLICK			:	fn() {
										var newPath = WaypointsPlugin.createPath();
										WaypointsPlugin.activatePath(newPath);
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_MENU,
		GUI.LABEL				:	"Select ...",
		GUI.MENU		:	this -> createPathMenu,
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load ...",
		GUI.TOOLTIP				:	"Load a path from file",
		GUI.ON_CLICK			:	fn() {
										fileDialog("Load path", systemConfig.getValue('Waypoint.path', "."), ".path",
											WaypointsPlugin -> WaypointsPlugin.loadPath);
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save ...",
		GUI.TOOLTIP				:	"Save the current path to file",
		GUI.ON_CLICK			:	fn() {
										fileDialog("Save path", systemConfig.getValue('Waypoint.path', "."), ".path",
											WaypointsPlugin -> WaypointsPlugin.savePath);
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Show",
		GUI.TOOLTIP				:	"Show/Hide current path in the scene",
		GUI.ON_CLICK			:	this -> fn() {
										showPath = !showPath;
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};

	var component = gui.createToolbar(500, 20, toolBar);
	component.setExtLayout(GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_ABS,new Geometry.Vec2(0,0),new Geometry.Vec2(2,0));
	if(panel != void)
		panel.add(component);
	return component;
};

WaypointsPlugin.createMainWindowTab @(private) := fn() {
	// page-panel
	var page = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW,
	});

	// Toolbar
	var toolbar=this.addPathMenu(page);

	// main
	var subTabs = gui.create({	
		GUI.TYPE : GUI.TYPE_TABBED_PANEL,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS,4,4],
	});
	this.createNavigatorTab(subTabs);
	this.createEditorTab(subTabs);

	page.nextRow();
	page.add(subTabs);

	// -------------------------------------------------------------------

	executeExtensions('Waypoints_PathChanged', WaypointsPlugin.getCurrentPath() );
	executeExtensions('Waypoints_SelectedWaypointChanged', WaypointsPlugin.getSelectedWaypoint() );
	executeExtensions('Waypoints_PathAttachmentChanged', 'pig' );
	executeExtensions('Waypoints_PathAttachmentChanged', 'cam' );

	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : page,
		GUI.LABEL : "Waypoints"
	};
};
