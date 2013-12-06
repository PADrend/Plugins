/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*
 *	[Plugin:Tools_CameraWindow] Tools/Camera/ConfigPanel.escript
 *	2011-10-20	Benjamin Eikel	Creation.
 */

CameraWindowPlugin.createNearPlaneSlider := fn(MinSG.AbstractCameraNode camera, Bool label) {
	return gui.create({
		GUI.TYPE				:	GUI.TYPE_RANGE,
		GUI.LABEL				:	label ? "Near Plane" : void,
		GUI.TOOLTIP				:	"Distance between the camera position and the front side of the camera frustum",
		GUI.RANGE				:	[0.01, 10],
		GUI.RANGE_STEP_SIZE		:	0.01,
		GUI.DATA_VALUE			:	camera.getNearPlane(),
		GUI.ON_DATA_CHANGED		:	(fn(data, MinSG.AbstractCameraNode camera) {
										if(camera == PADrend.getActiveCamera()) {
											// If this is the active camera, broadcast the changes to all connected instances.
											PADrend.executeCommand((fn(data) {
												var camera = PADrend.getActiveCamera();
												camera.setNearFar(data, camera.getFarPlane());
											}).bindLastParams(data));
										} else {
											camera.setNearFar(data, camera.getFarPlane());
										}
									}).bindLastParams(camera),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	});
};

CameraWindowPlugin.createFarPlaneSlider := fn(MinSG.AbstractCameraNode camera, Bool label) {
	return gui.create({
		GUI.TYPE				:	GUI.TYPE_RANGE,
		GUI.LABEL				:	label ? "Far Plane" : void,
		GUI.TOOLTIP				:	"Distance between the camera position and the back side of the camera frustum",
		GUI.RANGE				:	[1, 10000],
		GUI.RANGE_STEP_SIZE		:	1,
		GUI.DATA_VALUE			:	camera.getFarPlane(),
		GUI.ON_DATA_CHANGED		:	(fn(data, MinSG.AbstractCameraNode camera) {
										if(camera == PADrend.getActiveCamera()) {
											// If this is the active camera, broadcast the changes to all connected instances.
											PADrend.executeCommand((fn(data) {
												var camera = PADrend.getActiveCamera();
												camera.setNearFar(camera.getNearPlane(), data);
											}).bindLastParams(data));
										} else {
											camera.setNearFar(camera.getNearPlane(), data);
										}
									}).bindLastParams(camera),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	});
};

CameraWindowPlugin.createConfigPanel := fn(MinSG.AbstractCameraNode camera) {
	var panel = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.FLAGS				:	GUI.LOWERED_BORDER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 4, 2]
	});

	panel += "*Camera*";
	panel++;

	panel += CameraWindowPlugin.createNearPlaneSlider(camera, true);
	panel++;

	panel += CameraWindowPlugin.createFarPlaneSlider(camera, true);
	panel++;

	if(camera == PADrend.getActiveCamera()) {
		// Do not allow changes to the viewport of the active camera.
		var viewport = camera.getViewport();
		panel += {
			GUI.TYPE				:	GUI.TYPE_NUMBER,
			GUI.LABEL				:	"Viewport X",
			GUI.TOOLTIP				:	"X screen space coordinate for the camera viewport\nChanging the viewport is forbidden for the active camera",
			GUI.DATA_VALUE			:	viewport.getX(),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
			GUI.FLAGS				:	GUI.LOCKED
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_NUMBER,
			GUI.LABEL				:	"Viewport Y",
			GUI.TOOLTIP				:	"Y screen space coordinate for the camera viewport\nChanging the viewport is forbidden for the active camera",
			GUI.DATA_VALUE			:	viewport.getY(),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
			GUI.FLAGS				:	GUI.LOCKED
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_NUMBER,
			GUI.LABEL				:	"Viewport Width",
			GUI.TOOLTIP				:	"Width in screen space units for the camera viewport\nChanging the viewport is forbidden for the active camera",
			GUI.DATA_VALUE			:	viewport.getWidth(),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
			GUI.FLAGS				:	GUI.LOCKED
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_NUMBER,
			GUI.LABEL				:	"Viewport Height",
			GUI.TOOLTIP				:	"Height in screen space units for the camera viewport\nChanging the viewport is forbidden for the active camera",
			GUI.DATA_VALUE			:	viewport.getHeight(),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
			GUI.FLAGS				:	GUI.LOCKED
		};
	} else {
		var winWidth = GLOBALS.renderingContext.getWindowWidth();
		var winHeight = GLOBALS.renderingContext.getWindowHeight();
		var viewportRefreshGroup = new GUI.RefreshGroup();
		registerExtension('CameraWindowPlugin_CameraConfigurationChanged', (fn(	MinSG.AbstractCameraNode changedCamera,
																				MinSG.AbstractCameraNode selectedCamera,
																				GUI.RefreshGroup refreshGroup,
																				GUI.Component component) {
			// Make sure the listener will be removed when the window was closed.
			if(!gui.isCurrentlyEnabled(component)) {
				return false;
			}
			if(changedCamera == selectedCamera) {
				refreshGroup.refresh();
			}
		}).bindLastParams(camera, viewportRefreshGroup, panel));
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Viewport X",
			GUI.TOOLTIP				:	"X screen space coordinate for the camera viewport",
			GUI.RANGE				:	[0, 2 * winWidth],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getViewport().getX();
										},
			GUI.ON_DATA_CHANGED		:	camera -> fn(data) {
											var viewport = this.getViewport();
											viewport.setX(data);
											this.setViewport(viewport, true);
										},
			GUI.DATA_REFRESH_GROUP	:	viewportRefreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Viewport Y",
			GUI.TOOLTIP				:	"Y screen space coordinate for the camera viewport",
			GUI.RANGE				:	[0, 2 * winHeight],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getViewport().getY();
										},
			GUI.ON_DATA_CHANGED		:	camera -> fn(data) {
											var viewport = this.getViewport();
											viewport.setY(data);
											this.setViewport(viewport, true);
										},
			GUI.DATA_REFRESH_GROUP	:	viewportRefreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Viewport Width",
			GUI.TOOLTIP				:	"Width in screen space units for the camera viewport",
			GUI.RANGE				:	[1, 2 * winWidth],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getViewport().getWidth();
										},
			GUI.ON_DATA_CHANGED		:	camera -> fn(data) {
											var viewport = this.getViewport();
											viewport.setWidth(data);
											this.setViewport(viewport, true);
										},
			GUI.DATA_REFRESH_GROUP	:	viewportRefreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Viewport Height",
			GUI.TOOLTIP				:	"Height in screen space units for the camera viewport",
			GUI.RANGE				:	[1, 2 * winHeight],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getViewport().getHeight();
										},
			GUI.ON_DATA_CHANGED		:	camera -> fn(data) {
											var viewport = this.getViewport();
											viewport.setHeight(data);
											this.setViewport(viewport, true);
										},
			GUI.DATA_REFRESH_GROUP	:	viewportRefreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
	}
	panel++;

	if(camera ---|> MinSG.CameraNode) {
		panel += "*Perspective Camera*";
		panel++;

		var refreshGroup = new GUI.RefreshGroup();

		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Left Angle",
			GUI.TOOLTIP				:	"Angle between the viewing direction and the left side of the camera frustum",
			GUI.RANGE				:	[-89, 0],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getAngles()[0];
										},
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											var oldAngles = camera.getAngles();
											oldAngles[0] = data;
											camera.setAngles(oldAngles);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Right Angle",
			GUI.TOOLTIP				:	"Angle between the viewing direction and the right side of the camera frustum",
			GUI.RANGE				:	[0, 89],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getAngles()[1];
										},
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											var oldAngles = camera.getAngles();
											oldAngles[1] = data;
											camera.setAngles(oldAngles);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Bottom Angle",
			GUI.TOOLTIP				:	"Angle between the viewing direction and the bottom side of the camera frustum",
			GUI.RANGE				:	[-89, 0],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getAngles()[2];
										},
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											var oldAngles = camera.getAngles();
											oldAngles[2] = data;
											camera.setAngles(oldAngles);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Top Angle",
			GUI.TOOLTIP				:	"Angle between the viewing direction and the top side of the camera frustum",
			GUI.RANGE				:	[0, 89],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											return this.getAngles()[3];
										},
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											var oldAngles = camera.getAngles();
											oldAngles[3] = data;
											camera.setAngles(oldAngles);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Horizontal Angle",
			GUI.TOOLTIP				:	"Angle between the left side and the right side of the camera frustum",
			GUI.RANGE				:	[1, 179],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											var angles = this.getAngles();
											return (-angles[0] + angles[1]);
										},
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.applyHorizontalAngle(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Vertical Angle",
			GUI.TOOLTIP				:	"Angle between the bottom side and the top side of the camera frustum",
			GUI.RANGE				:	[1, 179],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> fn() {
											var angles = this.getAngles();
											return (-angles[2] + angles[3]);
										},
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.applyVerticalAngle(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};


	} else if(camera ---|> MinSG.CameraNodeOrtho) {
		panel += "*Orthographic Camera*";
		panel++;

		var winWidth = GLOBALS.renderingContext.getWindowWidth();
		var winHeight = GLOBALS.renderingContext.getWindowHeight();

		var refreshGroup = new GUI.RefreshGroup();

		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Unit Scale",
			GUI.TOOLTIP				:	"Scale factor for conversion between object space and screen space units",
			GUI.RANGE				:	[0.0005, 1],
			GUI.RANGE_STEP_SIZE		:	0.0005,
			GUI.DATA_VALUE			:	1,
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.setFrustumFromScaledViewport(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Left",
			GUI.TOOLTIP				:	"Coordinate of the left clipping plane of the camera frustum",
			GUI.RANGE				:	[-winWidth / 2, 0],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> camera.getLeftClippingPlane,
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.setLeftClippingPlane(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Right",
			GUI.TOOLTIP				:	"Coordinate of the right clipping plane of the camera frustum",
			GUI.RANGE				:	[0, winWidth / 2],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> camera.getRightClippingPlane,
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.setRightClippingPlane(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Bottom",
			GUI.TOOLTIP				:	"Coordinate of the bottom clipping plane of the camera frustum",
			GUI.RANGE				:	[-winHeight / 2, 0],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> camera.getBottomClippingPlane,
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.setBottomClippingPlane(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	"Top",
			GUI.TOOLTIP				:	"Coordinate of the top clipping plane of the camera frustum",
			GUI.RANGE				:	[0, winHeight / 2],
			GUI.RANGE_STEP_SIZE		:	1,
			GUI.DATA_PROVIDER		:	camera -> camera.getTopClippingPlane,
			GUI.ON_DATA_CHANGED		:	(fn(data, camera, refreshGroup) {
											camera.setTopClippingPlane(data);
											refreshGroup.refresh();
										}).bindLastParams(camera, refreshGroup),
			GUI.DATA_REFRESH_GROUP	:	refreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
	}
	return panel;
};
