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
 *	[Plugin:Tools_CameraWindow] Tools/Camera/OptionPanel.escript
 *	2011-10-20	Benjamin Eikel	Creation.
 */

CameraWindowPlugin.createOptionPanel := fn(MinSG.AbstractCameraNode camera) {
	var panel = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.FLAGS				:	GUI.LOWERED_BORDER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 4, 2]
	});

	if(camera != PADrend.getActiveCamera()) {
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Make Active",
			GUI.TOOLTIP				:	"Make the selected camera the active camera",
			GUI.ON_CLICK			:	[camera] => fn(camera) {
											PADrend.setActiveCamera(camera);
											executeExtensions('CameraWindowPlugin_CamerasChanged');
										},
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Copy Active Transformation",
			GUI.TOOLTIP				:	"Apply the position and direction of the active camera to the selected camera",
			GUI.ON_CLICK			:	[camera] => fn(camera) {
											camera.setMatrix(PADrend.getActiveCamera().getWorldMatrix());
										},
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Copy Active Viewport",
			GUI.TOOLTIP				:	"Apply the viewport of the active camera to the selected camera",
			GUI.ON_CLICK			:	[camera] => fn(camera) {
											camera.setViewport(PADrend.getActiveCamera().getViewport());
											executeExtensions('CameraWindowPlugin_CameraConfigurationChanged', camera);
										},
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;

		var dollyStorage = DataWrapper.createFromValue(void);
		var moveCamera = DataWrapper.createFromValue(false);
		moveCamera.onDataChanged +=	[camera, dollyStorage] => fn(camera, dollyStorage, moveCamera) {
										if(moveCamera) {
											dollyStorage(PADrend.getCameraMover().getDolly());
											PADrend.getCameraMover().setDolly(camera);
										} else {
											PADrend.getCameraMover().setDolly(dollyStorage());
											dollyStorage(void);
										}
									};
		panel += {
			GUI.TYPE				:	GUI.TYPE_BOOL,
			GUI.LABEL				:	"Move this Camera",
			GUI.TOOLTIP				:	"Exchange the dolly with this camera",
			GUI.DATA_WRAPPER		:	moveCamera,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
	}

	var displayFrustum = DataWrapper.createFromValue(false);
	displayFrustum.onDataChanged +=	[camera] => fn(camera, displayFrustum) {
										if(displayFrustum) {
											registerExtension('PADrend_AfterRenderingPass', [camera, this] => fn(camera, displayFrustum, dummy) {
												if(!displayFrustum()) {
													return Extension.REMOVE_EXTENSION;
												}
												camera.display(GLOBALS.frameContext, MinSG.SHOW_META_OBJECTS);
												return Extension.CONTINUE;
											});
										}
									};
	panel += {
		GUI.TYPE				:	GUI.TYPE_BOOL,
		GUI.LABEL				:	"Display Frustum",
		GUI.TOOLTIP				:	"Display the frustum of the selected camera",
		GUI.DATA_WRAPPER		:	displayFrustum,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var displayCameraImageData = new ExtObject({
		$camera				:	camera,
		$icon				:	void,
		$isRegisteredBefore	:	false,
		$isRegisteredAfter	:	false,
		$doDisplay			:	DataWrapper.createFromValue(0),

		$textureToIcon 		: fn(texture, icon){
			texture.download(GLOBALS.renderingContext);
			var bitmap = Rendering.createBitmapFromTexture(GLOBALS.renderingContext, texture);
			icon.setImageData(new GUI.ImageData(bitmap));
			icon.setImageRect(new Geometry.Rect(0, 0, texture.getWidth(), texture.getHeight()));
			// Keep aspect ratio.
			icon.setHeight(icon.getWidth() * texture.getHeight() / texture.getWidth());
		},

		$fbo 				: new Rendering.FBO(),
		$colorTexture 		: void,
		$depthTexture 		: void,

		$debugCamera		: void,

		$beforeRendering 	: fn(p) {
			

			if(doDisplay() == 1 && gui.isCurrentlyEnabled(icon)) {
				prepare();
				return Extension.CONTINUE;
			}
			if(doDisplay() == 2 && gui.isCurrentlyEnabled(icon)) {
				prepare();

				if(!debugCamera)
					debugCamera = new MinSG.DebugCamera();

				debugCamera.enable(renderingContext, camera, PADrend.getActiveCamera(), fbo);
				
				return Extension.CONTINUE;
			}

			isRegisteredBefore = false;
			return Extension.REMOVE_EXTENSION;
		},

		$prepare			: fn(){
			var viewport = camera.getViewport();
			var texWidth = viewport.getX() + viewport.getWidth();
			var texHeight = viewport.getY() + viewport.getHeight();
			if(!colorTexture || colorTexture.getWidth() != texWidth || colorTexture.getHeight() != texHeight) {
				colorTexture = Rendering.createStdTexture(texWidth, texHeight, true);
				depthTexture = Rendering.createDepthTexture(texWidth, texHeight);
				
				fbo.attachColorTexture(GLOBALS.renderingContext, colorTexture);
				fbo.attachDepthTexture(GLOBALS.renderingContext, depthTexture);
			}
			
			GLOBALS.renderingContext.pushAndSetFBO(fbo);
			
			// Clear the texture.
			if(viewport.getX() != 0 || viewport.getY() != 0) {
				GLOBALS.renderingContext.pushViewport();
				GLOBALS.renderingContext.setViewport(0, 0, texWidth, texHeight);
				GLOBALS.renderingContext.pushScissor();
				GLOBALS.renderingContext.setScissor(new Rendering.ScissorParameters(new Geometry.Rect(0, 0, texWidth, texHeight)));
				GLOBALS.renderingContext.clearScreen(new Util.Color4f(1, 0, 0, 1));
				GLOBALS.renderingContext.popScissor();
				GLOBALS.renderingContext.popViewport();
			}
			GLOBALS.renderingContext.clearScreen(PADrend.getBGColor());
			
			GLOBALS.renderingContext.popFBO();
		},

		$afterRendering 	: fn(p) {
			
			if(doDisplay() == 1 && gui.isCurrentlyEnabled(icon)) {
				
				GLOBALS.renderingContext.pushAndSetFBO(fbo);
				PADrend.renderScene(PADrend.getRootNode(), camera, PADrend.getRenderingFlags(), PADrend.getBGColor(),PADrend.getRenderingLayers());
				GLOBALS.renderingContext.popFBO();

				GLOBALS.frameContext.setCamera(PADrend.getActiveCamera());

				textureToIcon(colorTexture, icon);

				return Extension.CONTINUE;
			}

			if(doDisplay() == 2 && gui.isCurrentlyEnabled(icon)) {
								
				debugCamera.disable(renderingContext);
				textureToIcon(colorTexture, icon);
				
				return Extension.CONTINUE;
			}
			
			isRegisteredAfter = false;
			return Extension.REMOVE_EXTENSION;
		}
		
	});
	
	displayCameraImageData.doDisplay.onDataChanged += displayCameraImageData->fn(displayCameraImage) {
		if(displayCameraImage != 0) {
			if(!isRegisteredAfter){
				registerExtension('PADrend_AfterRendering', this->afterRendering);
				isRegisteredAfter = true;
			}
			if(!isRegisteredBefore){
				registerExtension('PADrend_BeforeRendering', this->beforeRendering);
				isRegisteredBefore = true;
			}
		}
	};
	
	
	panel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.LABEL				:	"Display Camera Image",
		GUI.TOOLTIP				:	"Use the selected camera to render an image of the scene",
		GUI.DATA_WRAPPER		:	displayCameraImageData.doDisplay,
		GUI.OPTIONS				:	[[0,"disabled"], [1, "second camera"], [2, "debug camera"]],
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	displayCameraImageData.icon = gui.create({
		GUI.TYPE				:	GUI.TYPE_ICON,
		GUI.ICON				:	gui.createIcon(gui.createImage(1, 1), new Geometry.Rect(0, 0, 1, 1)),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	});
	panel += displayCameraImageData.icon;
	panel++;

	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Save Camera Image ...",
		GUI.TOOLTIP				:	"Open a dialog to choose a file to save the camera image to ",
		GUI.ON_CLICK			:	[displayCameraImageData.icon] => fn(GUI.Icon icon) {
										var dialog = new GUI.FileDialog("Save Camera Image", PADrend.getDataPath(), [".png", ".bmp"],
											[icon] => fn(GUI.Icon icon, fileName) {
												Util.saveBitmap(icon.getImageData().getBitmap(), fileName);
											}
										);
										dialog.init();
									},
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};

	return panel;
};
