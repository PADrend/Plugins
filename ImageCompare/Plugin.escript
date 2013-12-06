/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

GLOBALS.ImageComparePlugin := new Plugin({
			Plugin.NAME				:	"ImageCompare",
			Plugin.VERSION			:	"1.0",
			Plugin.DESCRIPTION		:	"Display the two source images and the resulting image of an ImageCompareEvaluator.",
			Plugin.AUTHORS			:	"Benjamin Eikel",
			Plugin.OWNER			:	"Benjamin Eikel",
			Plugin.LICENSE			:	"Mozilla Public License, v. 2.0",
			Plugin.REQUIRES			:	["Evaluator"]
});

//! Result of the ImageCompareEvaluator.
ImageComparePlugin.quality := DataWrapper.createFromValue(0.0);
//! Status of the output of the three textures of the ImageCompareEvaluator.
ImageComparePlugin.displayTextures := DataWrapper.createFromValue(false);
//! Temporary storage for the current PADrend scene.
ImageComparePlugin.tempScene := void;

ImageComparePlugin.init := fn() {
	if(!MinSG.isSet($AbstractImageComparator)) {
		out(__FILE__,__LINE__," MinSG::ImageCompare not supported. Did you compile with MINSG_EXT_IMAGECOMPARE defined?\n");
		return false;
	}
	{
		load(__DIR__ + "/ImageCompareEvaluator.escript");
		load(__DIR__ + "/ImageReadEvaluator.escript");
		load(__DIR__ + "/ImageWriteEvaluator.escript");
	}
	{
		registerExtension('PADrend_BeforeRendering', this -> this.ex_BeforeRendering);
		registerExtension('PADrend_AfterRendering', this -> this.ex_AfterRendering);
		
		registerExtension('Evaluator_QueryEvaluators', this -> this.ex_QueryEvaluators);
	}
	return true;
};

ImageComparePlugin.ex_QueryEvaluators := fn(Array evaluatorList) {
	evaluatorList += new MinSG.ImageCompareEvaluator;
	evaluatorList += new MinSG.ImageReadEvaluator;
	evaluatorList += new MinSG.ImageWriteEvaluator;
};

ImageComparePlugin.ex_BeforeRendering := fn(...) {
	if(!displayTextures()) {
		return;
	}
	var evaluator = EvaluatorManager.getSelectedEvaluator();
	if(!(evaluator ---|> MinSG.ImageCompareEvaluator) || !evaluator.isReady()) {
		displayTextures(false);
		return;
	}
	
	tempScene = PADrend.getCurrentScene();
	PADrend.selectScene(void);
};

ImageComparePlugin.ex_AfterRendering := fn(...) {
	if(!displayTextures()) {
		return;
	}
	
	PADrend.selectScene(tempScene);
	
	var evaluator = EvaluatorManager.getSelectedEvaluator();
	var angle = evaluator.getCameraAngle();
	var rect = evaluator.measurementResolution;
	
	var measurementCamera = PADrend.getActiveCamera().clone();
	measurementCamera.setMatrix(PADrend.getActiveCamera().getWorldMatrix());
	measurementCamera.applyVerticalAngle(angle);
	measurementCamera.setViewport(rect);
	frameContext.pushAndSetCamera(measurementCamera);
	
	evaluator.beginMeasure();
	evaluator.measure(frameContext, PADrend.getCurrentScene(), rect);
	evaluator.endMeasure(frameContext);
	
	frameContext.popCamera();
	
	// Update GUI
	quality(evaluator.getResults()[0]);
	
	var halfW = renderingContext.getWindowWidth() / 2;
	var halfH = renderingContext.getWindowHeight() / 2;
	var width = rect.getWidth();
	var height = rect.getHeight();
	if(width > halfW) {
		width = halfW;
	}
	if(height > halfH) {
		height = halfH;
	}
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(halfW, halfH, width, height), evaluator.getFirstTexture(), new Geometry.Rect(0, 0, 1, 1));
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(halfW, 0, width, height), evaluator.getSecondTexture(), new Geometry.Rect(0, 0, 1, 1));
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(0, 0, width, height), evaluator.getResultTexture(), new Geometry.Rect(0, 0, 1, 1));
};

return ImageComparePlugin;
