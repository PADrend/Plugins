/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
			Plugin.NAME				:	"ImageCompare",
			Plugin.VERSION			:	"1.0",
			Plugin.DESCRIPTION		:	"Display the two source images and the resulting image of an ImageCompareEvaluator.",
			Plugin.AUTHORS			:	"Benjamin Eikel",
			Plugin.OWNER			:	"Benjamin Eikel",
			Plugin.LICENSE			:	"Mozilla Public License, v. 2.0",
			Plugin.REQUIRES			:	["Evaluator"]
});

//! Result of the ImageCompareEvaluator.
static currentQuality = new Std.DataWrapper(0.0);
plugin.currentQuality := currentQuality;

//! Status of the output of the three textures of the ImageCompareEvaluator.
static displayTexturesEnabled = new Std.DataWrapper(false);
plugin.displayTexturesEnabled := displayTexturesEnabled;

static tempScene; //! Temporary storage for the current PADrend scene.

plugin.init := fn() {
	if(!MinSG.isSet($AbstractImageComparator)) {
		out(__FILE__,__LINE__," MinSG::ImageCompare not supported. Did you compile with MINSG_EXT_IMAGECOMPARE defined?\n");
		return false;
	}
	
	static revoceExtensions = new Std.MultiProcedure;
	displayTexturesEnabled.onDataChanged += fn(enable){
		revoceExtensions();
		if(enable){
			revoceExtensions += Util.registerExtensionRevocably('PADrend_BeforeRendering', ex_BeforeRendering);
			revoceExtensions += Util.registerExtensionRevocably('PADrend_AfterRendering', ex_AfterRendering);
		}
	};
	
	{ // init shader file locator
		var shaderLocator = new Util.FileLocator;
		var storedLocation = systemConfig.getValue('ImageCompare.shaderLocation',false);
		if(storedLocation){
			shaderLocator.addSearchPath(storedLocation);
		}else{
			if(getEnv('MINSG_DATA_DIR'))
				shaderLocator.addSearchPath( getEnv('MINSG_DATA_DIR') );
			shaderLocator.addSearchPath( "../share/MinSG/data/" );
			shaderLocator.addSearchPath( "modules/MinSG/data/" );
			shaderLocator.addSearchPath( "../modules/MinSG/data/" );
		}
		MinSG.AbstractOnGpuComparator.initShaderFileLocator( shaderLocator );
		if( !shaderLocator.locateFile( new Util.FileName("shader/ImageCompare/ImageCompare.vs")) ){
			Runtime.warn("ImageCompareEvaluator: shader resource files could not be located.");
		}
	}

	Util.registerExtension('Evaluator_QueryEvaluators', fn(Array evaluatorList) {
		evaluatorList += new (Std.require( 'ImageCompare/ImageCompareEvaluator' ));
		evaluatorList += new (Std.require( 'ImageCompare/ImageReadEvaluator' ));
		evaluatorList += new (Std.require( 'ImageCompare/ImageWriteEvaluator' ));
	});
	return true;
};


static ex_BeforeRendering = fn(...) {

	var evaluator = EvaluatorManager.getSelectedEvaluator();
	if(!(evaluator ---|> ( Std.require( 'ImageCompare/ImageCompareEvaluator' ))) || !evaluator.isReady()) {
		displayTexturesEnabled(false);
		return;
	}
	
	tempScene = PADrend.getCurrentScene();
	PADrend.selectScene(void);
};

static ex_AfterRendering = fn(...) {
	if(!displayTexturesEnabled()) 
		return;
	
	PADrend.selectScene(tempScene);
	
	var evaluator = EvaluatorManager.getSelectedEvaluator();
	var angle = evaluator.getCameraAngle();
	var rect = evaluator.measurementResolution;
	if(rect.isA(Geometry.Vec2))
		rect = new Geometry.Rect(0,0,rect.x(),rect.y());
	
	var measurementCamera = PADrend.getActiveCamera().clone();
	measurementCamera.setRelTransformation(PADrend.getActiveCamera().getWorldTransformationMatrix());
	measurementCamera.applyVerticalAngle(angle);
	measurementCamera.setViewport(rect);
	frameContext.pushAndSetCamera(measurementCamera);
	
	evaluator.beginMeasure();
	evaluator.measure(frameContext, PADrend.getCurrentScene(), rect);
	evaluator.endMeasure(frameContext);
	
	frameContext.popCamera();
	
	// Update GUI
	currentQuality(evaluator.getResults()[0]);
	
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

return plugin;
