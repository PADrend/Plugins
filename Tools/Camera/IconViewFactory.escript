/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2014 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return fn(MinSG.AbstractCameraNode camera) {
	var cameraViewIcon = gui.create({
		GUI.TYPE	:	GUI.TYPE_ICON,
		GUI.ICON	:	gui.createIcon(gui.createImage(1, 1), new Geometry.Rect(0, 0, 1, 1)),
		GUI.SIZE	:	[GUI.WIDTH_FILL_ABS, 10, 0]
	});
	cameraViewIcon.refreshCameraView := DataWrapper.createFromValue(false);
	cameraViewIcon.afterRenderingRegistered := false;

	static fbo = new Rendering.FBO;
	static colorTexture = void;
	static depthTexture = void;

	cameraViewIcon.refreshCameraView.onDataChanged += [camera, cameraViewIcon] => fn(MinSG.AbstractCameraNode camera,
																					 icon, 
																					 unused) {
		if(icon.refreshCameraView() && !icon.afterRenderingRegistered) {
			registerExtension('PADrend_AfterRendering', 
							  [camera, icon] => fn(MinSG.AbstractCameraNode camera,
												   icon,
												   unused) {
				if(!gui.isCurrentlyEnabled(icon)) {
					icon.afterRenderingRegistered = false;
					return Extension.REMOVE_EXTENSION;
				}
				var viewport = camera.getViewport();
				var texWidth = viewport.getX() + viewport.getWidth();
				var texHeight = viewport.getY() + viewport.getHeight();
				if(!colorTexture
							|| colorTexture.getWidth() != texWidth
							|| colorTexture.getHeight() != texHeight) {
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

				GLOBALS.frameContext.pushCamera();
				PADrend.renderScene(PADrend.getRootNode(), camera, PADrend.getRenderingFlags(), PADrend.getBGColor());
				GLOBALS.frameContext.popCamera();
				GLOBALS.renderingContext.popFBO();

				colorTexture.download(GLOBALS.renderingContext);
				var bitmap = Rendering.createBitmapFromTexture(GLOBALS.renderingContext, colorTexture);
				icon.setImageData(new GUI.ImageData(bitmap));
				icon.setImageRect(new Geometry.Rect(0, 0, colorTexture.getWidth(), colorTexture.getHeight()));
				// Keep aspect ratio.
				icon.setHeight(icon.getWidth() * colorTexture.getHeight() / colorTexture.getWidth());

				return Extension.CONTINUE;
			});
			icon.afterRenderingRegistered = true;
		}
	};

	return cameraViewIcon;
};
