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

static createPathMenu = fn() {
	var pathListEntries = [];
	print_r(PathManagement.getRegisteredPaths());
	foreach(PathManagement.getRegisteredPaths() as var path) {
		pathListEntries += [path, {
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 0],
			GUI.CONTENTS			:	[
				NodeEditor.getString(path.toString()) + " @ " + NodeEditor.getString(path.getParent()),
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
																					GUI.ON_CLICK	:	[path] => fn(MinSG.PathNode path) {
								PADrend.getRootNode() += path;
								gui.closeAllMenus();
																										}
																				},
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"... scene",
																					GUI.ON_CLICK	:	[path] => fn(MinSG.PathNode path) {
								PADrend.getCurrentScene() += path;
								gui.closeAllMenus();
																										}
																				},
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"... selected node",
																					GUI.ON_CLICK	:	[path] => fn(MinSG.PathNode path) {
								NodeEditor.getSelectedNode() += path;
								gui.closeAllMenus();
																										}
																				},
																				"----",
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
							GUI.LABEL		:	"Select in NodeEditor",
																					GUI.TOOLTIP		:	"Select PathNode in NodeEditor",
																					GUI.ON_CLICK	:	[path] => fn(MinSG.PathNode path) {
																											NodeEditor.selectNode(path);
																										}
																				},
																				"----",
																				{
																					GUI.TYPE		:	GUI.TYPE_BUTTON,
																					GUI.LABEL		:	"Delete",
																					GUI.ON_CLICK	:	[path] => fn(MinSG.PathNode path) {
								PathManagement.unregisterPath(path);
																											MinSG.destroy(path);
																											gui.closeAllMenus();
																										}
																				}
																			]
											}
										]
		}];
	}

	var entries = [];
	entries += {
		GUI.TYPE				:	GUI.TYPE_LIST,
		GUI.OPTIONS				:	pathListEntries,
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 500, 150],
		GUI.DATA_PROVIDER		:	PathManagement -> PathManagement.getActivePath,
		GUI.ON_DATA_CHANGED		:	fn(data) {
				if( data && !data.empty()) 
					PathManagement.activatePath(data[0]);
											}
	};
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Scan for PathNodes in current scene",
		GUI.ON_CLICK : fn(){
			PathManagement.scanForPathNodes( PADrend.getRootNode());
			gui.closeAllMenus();
									}
	};
	return entries;
};

/**
* Creates the panel used to select the path, create a path, load, save etc.
*/
static addPathMenu = fn(panel){
	var toolBar = [];
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"New path",
		GUI.TOOLTIP				:	"Create new path",
		GUI.ON_CLICK			:	fn() {
			var newPath = PathManagement.createPath();
			PathManagement.activatePath(newPath);
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_MENU,
		GUI.LABEL				:	"Select path >>",
		GUI.MENU				:	createPathMenu,
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Load path ...",
		GUI.TOOLTIP				:	"Load a path from a file",
		GUI.ON_CLICK			:	fn() {
										GUI._openFileDialog("Load path", systemConfig.getValue('Waypoint.path', "."), ".path",
				PathManagement -> PathManagement.loadPath);
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save path ...",
		GUI.TOOLTIP				:	"Save the current path to a file",
		GUI.ON_CLICK			:	fn() {
										GUI._openFileDialog("Save path", systemConfig.getValue('Waypoint.path', "."), ".path",
				PathManagement -> PathManagement.savePath);
									},
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};
	toolBar += {
		GUI.TYPE				:	GUI.TYPE_BOOL,
		GUI.LABEL				:	"Show",
		GUI.TOOLTIP				:	"Show/Hide current path in the scene",
		GUI.DATA_WRAPPER		:	PathManagement.showPath,
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.2, 0]
	};

	var component = gui.createToolbar(500, 20, toolBar);
	component.setExtLayout(GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_ABS,new Geometry.Vec2(0,0),new Geometry.Vec2(2,0));
	if(panel != void)
		panel.add(component);
	return component;
};

return fn() {
	// page-panel
	var page = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW,
	});

	// Toolbar
	addPathMenu(page);

	// main
	var subTabs = gui.create({	
		GUI.TYPE : GUI.TYPE_TABBED_PANEL,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS,4,4],
	});
	module('./GUI_Navigator')(subTabs);
	module('./GUI_Editor')(subTabs);

	page.nextRow();
	page.add(subTabs);

	// -------------------------------------------------------------------

	executeExtensions('Waypoints_PathChanged', PathManagement.getActivePath() );
	executeExtensions('Waypoints_SelectedWaypointChanged', PathManagement.animation_currentTime() );

	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : page,
		GUI.LABEL : "Waypoints"
	};
};
