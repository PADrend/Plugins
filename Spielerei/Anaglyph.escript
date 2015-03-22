/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2011 Robert Gmyr
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/Anaglyph.escript
 ** 2011-03 Gmyr
 **/
static plugin = new Plugin({
		Plugin.NAME : 'Spielerei_AnaglyphPlugin',
		Plugin.DESCRIPTION :  "Rendering of anaglyph 3D images.",
		Plugin.VERSION :  1.0,
		Plugin.AUTHORS : "Gmyr",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

static leftEyeColor;
static rightEyeColor;

plugin.init @(override) := fn() {
	static revoce = new Std.MultiProcedure;
	static enabled = new Std.DataWrapper(false);
	enabled.onDataChanged += fn(b){
		revoce();
		if(b){
			revoce += Util.registerExtensionRevocably('PADrend_BeforeRendering',ex_BeforeRendering);
			revoce += Util.registerExtensionRevocably('PADrend_AfterRendering',ex_AfterRendering);
		}
	};

	registerExtension('PADrend_Init',fn(){
		gui.register('Spielerei.anaglyph',[
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Anaglyph 3D",
				GUI.DATA_WRAPPER : enabled,
				GUI.TOOLTIP : "Currently broken!"
			}
		]);
	});
	leftEyeColor = new Util.Color4f(systemConfig.getValue('Spielerei.Anaglyph.leftEyeColor', [1.0, 0.0, 0.0]).clone().pushBack(1.0));
	rightEyeColor = new Util.Color4f(systemConfig.getValue('Spielerei.Anaglyph.rightEyeColor', [0.0, 1.0, 1.0]).clone().pushBack(1.0));

	return true;
};


static ex_BeforeRendering = fn(...) {
	PADrend.getRootNode().deactivate();
};

static ex_AfterRendering = fn(...) {
	PADrend.getRootNode().activate();
	renderingContext.clearScreen(new Util.Color4f(0.0, 0.0, 0.0, 1.0));

	var fbo = new Rendering.FBO();
	var colorTexture = Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	var depthTexture = Rendering.createDepthTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight());

	PADrend.getDolly().setObserverOffsetEnabled(false);
	renderEye(fbo, colorTexture, depthTexture, leftEyeColor);
	PADrend.getDolly().setObserverOffsetEnabled(true);
	renderEye(fbo, colorTexture, depthTexture, rightEyeColor);
	PADrend.getDolly().setObserverOffsetEnabled(false);
	
	frameContext.setCamera(PADrend.getActiveCamera());
};

static renderEye = fn(fbo, colorTexture, depthTexture, eyeColor) {
	frameContext.setCamera(PADrend.getActiveCamera());
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext,colorTexture);
	fbo.attachDepthTexture(renderingContext,depthTexture);
	renderingContext.clearScreen(new Util.Color4f(0.0, 0.0, 0.0, 0.0));
	PADrend.getRootNode().display(frameContext, PADrend.getRenderingFlags());
	applyColorFilter(eyeColor);
	renderingContext.popFBO();
	blendToCurrentImage(colorTexture);
};

static applyColorFilter = fn(filterColor) {
	var blending = new Rendering.BlendingParameters;
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.DST_COLOR, Rendering.BlendFunc.ZERO);
	renderingContext.pushAndSetBlending(blending);
	renderingContext.pushAndSetLighting(false);
	renderingContext.pushAndSetColorMaterial(filterColor);
	Rendering.drawFullScreenRect(renderingContext);
	renderingContext.popMaterial();
	renderingContext.popLighting();
	renderingContext.popBlending();
};

static blendToCurrentImage = fn(colorTexture) {
	var blending = new Rendering.BlendingParameters();
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.ONE, Rendering.BlendFunc.ONE);
	renderingContext.pushAndSetBlending(blending);
	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0, 0, renderingContext.getWindowWidth(), renderingContext.getWindowHeight()), colorTexture, new Geometry.Rect(0, 0, 1, 1));
	renderingContext.popBlending();
};

return plugin;
