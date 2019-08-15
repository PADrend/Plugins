/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*
 *	[Plugin:Tools_CameraWindow] Tools/Camera/Window.escript
 *	2011-10-20	Benjamin Eikel	Creation.
 */

CameraWindowPlugin.createWindow := fn() {
	var width = 500;
	var height = 700;
	var posX = GLOBALS.renderingContext.getWindowWidth() - width;
	var posY = 10;
	var window = gui.createWindow(width, height, "Cameras", GUI.ONE_TIME_WINDOW);
	window.setPosition(posX, posY);

	var windowPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});
	window += windowPanel;

	var cameraPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW
	});

	window.selectCamera := [cameraPanel]=>fn(GUI.Container panel, [MinSG.AbstractCameraNode, void] newCamera) {
		panel.clear();
		if(!newCamera) {
			return;
		}
		panel += CameraWindowPlugin.createConfigPanel(newCamera);
		panel++;
		panel += CameraWindowPlugin.createOptionPanel(newCamera);
	};

	var cameraDropDown = gui.create({
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.LABEL				:	"Selected Camera:",
		GUI.TOOLTIP				:	"Select a camera from the set of cameras currently in the scene graph.",
		GUI.OPTIONS				:	[],
		GUI.ON_DATA_CHANGED		:	window -> window.selectCamera,
		GUI.SIZE				:	[GUI.WIDTH_ABS, -65, 0]
	});
	windowPanel += cameraDropDown;
	registerExtension('CameraWindowPlugin_CamerasChanged', [cameraDropDown, window]=>fn(dropDown, window) {
		// Make sure the listener will be removed when the window was closed.
		if(!gui.isCurrentlyEnabled(dropDown)) {
			return false;
		}

		var previouslySelected = dropDown.getData();

		dropDown.clear();
		var cameras = MinSG.collectNodes(PADrend.getRootNode(), MinSG.AbstractCameraNode);
		foreach(cameras as var camera) {
			var cameraString = camera.toString();
			if(camera == PADrend.getActiveCamera()) {
				cameraString += " (active)";
			}
			dropDown.addOption(camera, cameraString);
		}

		if(previouslySelected) {
			dropDown.setData(previouslySelected);
			window.selectCamera(previouslySelected);
		}
	});
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.TOOLTIP				:	"Refresh the list of cameras",
		GUI.ICON				:	"#RefreshSmall",
		GUI.ICON_COLOR			:	GUI.BLACK,
		GUI.ON_CLICK			:	fn() {
										executeExtensions('CameraWindowPlugin_CamerasChanged');
									}
	};
	windowPanel += {
		GUI.TYPE				:	GUI.TYPE_MENU,
		GUI.LABEL				:	"+",
		GUI.TOOLTIP				:	"Add a new camera",
		GUI.MENU				:	[
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Perspective at dolly",
											GUI.TOOLTIP		:	"Add a new perspective camera (MinSG.CameraNode) to the dolly",
											GUI.ON_CLICK	:	fn() {
																	var camera = new MinSG.CameraNode();
																	PADrend.getDolly().addChild(camera);
																	executeExtensions('CameraWindowPlugin_CamerasChanged');
																}
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Orthographic at dolly",
											GUI.TOOLTIP		:	"Add a new orthographic camera (MinSG.CameraNodeOrtho) to the dolly",
											GUI.ON_CLICK	:	fn() {
																	var camera = new MinSG.CameraNodeOrtho();
																	PADrend.getDolly().addChild(camera);
																	executeExtensions('CameraWindowPlugin_CamerasChanged');
																}
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Perspective at scene",
											GUI.TOOLTIP		:	"Add a new perspective camera (MinSG.CameraNode) to the scene",
											GUI.ON_CLICK	:	fn() {
																	var camera = new MinSG.CameraNode();
																	PADrend.getCurrentScene().addChild(camera);
																	executeExtensions('CameraWindowPlugin_CamerasChanged');
																}
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Orthographic at scene",
											GUI.TOOLTIP		:	"Add a new orthographic camera (MinSG.CameraNodeOrtho) to the scene",
											GUI.ON_CLICK	:	fn() {
																	var camera = new MinSG.CameraNodeOrtho();
																	PADrend.getCurrentScene().addChild(camera);
																	executeExtensions('CameraWindowPlugin_CamerasChanged');
																}
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Perspective at root",
											GUI.TOOLTIP		:	"Add a new perspective camera (MinSG.CameraNode) to the scene",
											GUI.ON_CLICK	:	fn() {
												var camera = new MinSG.CameraNode();
												PADrend.getRootNode().addChild(camera);
												executeExtensions('CameraWindowPlugin_CamerasChanged');
											}
										},
										{
											GUI.TYPE		:	GUI.TYPE_BUTTON,
											GUI.LABEL		:	"Orthographic at root",
											GUI.TOOLTIP		:	"Add a new orthographic camera (MinSG.CameraNodeOrtho) to the scene",
											GUI.ON_CLICK	:	fn() {
												var camera = new MinSG.CameraNodeOrtho();
												PADrend.getRootNode().addChild(camera);
												executeExtensions('CameraWindowPlugin_CamerasChanged');
											}
										}
									],
		GUI.WIDTH				:	15,
		GUI.MENU_WIDTH			:	150
	};
	windowPanel++;
	windowPanel += cameraPanel;

	// Make sure that the panel is initially filled with the default options.
	executeExtensions('CameraWindowPlugin_CamerasChanged');
	window.selectCamera(PADrend.getActiveCamera());

	return window;
};
