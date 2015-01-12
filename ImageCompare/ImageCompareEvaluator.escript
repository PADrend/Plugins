/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012,2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var Evaluator = new Type(MinSG.ScriptedEvaluator);

Evaluator._constructor ::= fn() {
	this.firstScene := void;
	this.secondScene := void;
	
	this.imageComparator := void;
	
	this.fbo := new Rendering.FBO;
	this.firstTexture := void;
	this.secondTexture := void;
	this.depthTexture := void;
	this.resultTexture := void;
	
	this.result := void;
};

Evaluator.beginMeasure @(override)::= fn() {
	result = void;
	return this;
};

Evaluator.endMeasure @(override) ::= fn(MinSG.FrameContext frameContext) {
	return this;
};


Evaluator.measure @(override) ::= fn(MinSG.FrameContext frameContext, MinSG.Node node, Geometry.Rect rect) {
	var width = rect.getWidth();
	var height = rect.getHeight();
	
	if(!firstTexture||firstTexture.getWidth()!=width||firstTexture.getHeight()!=height){
		outln("ImageCompareEvaluator: Recreate textures.");
		firstTexture = Rendering.createStdTexture(width, height, true);
		secondTexture = Rendering.createStdTexture(width, height, true);
		depthTexture = Rendering.createDepthTexture(width,height);
		resultTexture = Rendering.createStdTexture(width, height, true);
	}
	
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachDepthTexture(renderingContext,depthTexture);
	
	renderingContext.pushViewport();
	renderingContext.setViewport(rect.getX(), rect.getY(), rect.getWidth(), rect.getHeight());
	

	fbo.attachColorTexture(renderingContext,firstTexture);
	PADrend.selectScene(firstScene);
	PADrend.renderScene(PADrend.getRootNode(), void, PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers());
	
	fbo.attachColorTexture(renderingContext,secondTexture);
	PADrend.selectScene(secondScene);
	PADrend.renderScene(PADrend.getRootNode(), void, PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers());
	
	renderingContext.popViewport();
	
	renderingContext.popFBO();
	
	var value = imageComparator.compare(renderingContext, firstTexture, secondTexture, resultTexture);
	if(!value) {
		Runtime.warn("Image comparison failed.");
		return;
	}
	if(!this.result || value<this.result) // for multiple directions, take lowerst quality sample.
		result = value;

	return this;
};

Evaluator.getResults @(override) ::= fn() {
	return [result];
};

Evaluator.getMaxValue @(override) ::= fn() {
	return result;
};

Evaluator.getMode @(override) ::= fn() {
	return MinSG.Evaluator.SINGLE_VALUE;
};

Evaluator.setMode @(override) ::= fn(dummy) {
};

Evaluator.getEvaluatorTypeName @(override) ::= fn() {
	return "ImageCompareEvaluator";
};

Evaluator.setFirstScene ::= fn(MinSG.Node s) {
	firstScene = s;
	
	if(MinSG.isSet($MAR)){ // only used for MultiAlgorithmRendering (Diss Ralf)
		foreach(s.getStates() as var state)
			if(state ---|> MinSG.MAR.AlgoSelector)
				algoSelector = state;
	}
};

Evaluator.setSecondScene ::= fn(MinSG.Node s) {
	secondScene = s;
	
	if(MinSG.isSet($MAR)){ // only used for MultiAlgorithmRendering (Diss Ralf)
		foreach(s.getStates() as var state)
			if(state ---|> MinSG.MAR.AlgoSelector)
				algoSelector = state;
	}
};

Evaluator.algoSelector := void; // only used for MultiAlgorithmRendering (Diss Ralf)

Evaluator.setScenes ::= fn(MinSG.Node first, MinSG.Node second) {
	setFirstScene(first);
	setSecondScene(second);
};

Evaluator.setImageComparator ::= fn(MinSG.AbstractImageComparator comparator) {
	imageComparator = comparator;
};

Evaluator.isReady ::= fn() {
	return (firstScene && secondScene && imageComparator);
};

Evaluator.getFirstTexture ::= fn() {
	return firstTexture;
};

Evaluator.getSecondTexture ::= fn() {
	return secondTexture;
};

Evaluator.getResultTexture ::= fn() {
	return resultTexture;
};

Evaluator.createConfigPanel @(override)  ::= fn() {
	// parent::createConfigPanel()
	var panel = (this -> MinSG.Evaluator.createConfigPanel)();

	panel += "First Scene:";
	panel.nextColumn();
	panel += "Second Scene:";
	panel++;
	
	var getSceneListOptions = fn(){
		var scenes = [ [void,"none"] ];
		foreach(PADrend.SceneManagement.getSceneList() as var scene) {
			var label = "";
			if(scene.isSet($filename)) {
				label += scene.filename;
			}
			if(!scene.constructionString.empty()) {
				label += "[ " + scene.constructionString + " ]";
			}
			scenes += [scene,label ];
		}
		return scenes;
	};

	panel += {
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.OPTIONS_PROVIDER : getSceneListOptions,
		GUI.DATA_VALUE : firstScene,
		GUI.ON_DATA_CHANGED : this->setFirstScene,
		GUI.WIDTH : 200
	};
	panel.nextColumn();
	panel += {
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.OPTIONS_PROVIDER : getSceneListOptions,
		GUI.DATA_VALUE : secondScene,
		GUI.ON_DATA_CHANGED : this->setSecondScene,
		GUI.WIDTH : 200
	};
	
	panel++;

	
	panel += [{
		GUI.LABEL : "Quality",
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.WIDTH : 300,
		GUI.DATA_WRAPPER : Util.requirePlugin('ImageCompare').currentQuality,
		GUI.FLAGS : GUI.LOCKED
	}];
	
	panel++;
	
	panel += [{
		GUI.LABEL : "Display Textures",
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.WIDTH : 100,
		GUI.DATA_WRAPPER : Util.requirePlugin('ImageCompare').displayTexturesEnabled,
	}];
	
	panel++;
	panel += "----";
	panel++;
	
	panel += "Image Comparator:";
	var imageComparatorDropDown = gui.createDropdown(150, 15);
	panel.imageComparatorDD := imageComparatorDropDown;
	// Store the comparator here to hold a reference so that it is not deleted immediately.
	panel.imageComparator := void;
	imageComparatorDropDown.addOption("new MinSG.SimilarPixelCounter()", "Similar Pixel Counter");
	imageComparatorDropDown.addOption("new MinSG.SSIMComparator()", "SSIM Comparator");
	imageComparatorDropDown.addOption("new MinSG.AverageComparator()", "Average Comparator");
	imageComparatorDropDown.addOption("new MinSG.PyramidComparator()", "Pyramid Comparator");
	imageComparatorDropDown.onDataChanged = [this, panel]=>fn( MinSG.Evaluator evaluator, panel, data) {
		var comparator = eval(panel.imageComparatorDD.getData() + ";");
		if(comparator ---|> MinSG.AbstractImageComparator) {
			panel.imageComparator = comparator;
			evaluator.setImageComparator(comparator);
		}
		panel.imageComparatorOptions.rebuild(comparator);
	};
	panel += imageComparatorDropDown;
	panel++;
	
	var imageComparatorOptions = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 5, 5],
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});
	panel.imageComparatorOptions := imageComparatorOptions;
	imageComparatorOptions.rebuild := fn(MinSG.AbstractImageComparator comparator) {
		this.clear();
		if(comparator ---|> MinSG.AbstractOnGpuComparator) {
			var options = new ExtObject();
			options.filterSize := comparator.getFilterSize();
			options.filterType := comparator.getFilterType();
			options.texDownSize := comparator.getTextureDownloadSize();

			var refreshGroup = new GUI.RefreshGroup();
			this += {
				GUI.LABEL : "Filter Type",
				GUI.TYPE : GUI.TYPE_RADIO,
				GUI.DATA_OBJECT : options,
				GUI.DATA_ATTRIBUTE : $filterType,
				GUI.OPTIONS : [[MinSG.AbstractOnGpuComparator.GAUSS, "Gauss-Filter"],[MinSG.AbstractOnGpuComparator.BOX, "Box-Filter"]],
				GUI.DATA_REFRESH_GROUP : refreshGroup
			};
			this++;
			this += {
				GUI.LABEL : "Filter Size",
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0, 15],
				GUI.RANGE_STEPS : 15,
				GUI.DATA_OBJECT : options,
				GUI.DATA_ATTRIBUTE : $filterSize,
				GUI.DATA_REFRESH_GROUP : refreshGroup
			};
			this++;
			this += {
				GUI.LABEL : "Texture Download Size",
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0, 14],
				GUI.RANGE_STEPS : 14,
				GUI.RANGE_FN_BASE : 2,
				GUI.DATA_OBJECT : options,
				GUI.DATA_ATTRIBUTE : $texDownSize,
				GUI.DATA_REFRESH_GROUP : refreshGroup
			};
			if(comparator ---|> MinSG.PyramidComparator){
				options.minTestSize := comparator.getMinimalTestSize();
				this++;
				this += {
					GUI.LABEL : "Minimal Test Size",
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0, 14],
					GUI.RANGE_STEPS : 14,
					GUI.RANGE_FN_BASE : 2,
					GUI.DATA_OBJECT : options,
					GUI.DATA_ATTRIBUTE : $minTestSize,
					GUI.DATA_REFRESH_GROUP : refreshGroup
				};
				options.internalComp := comparator.getInternalComparator().getType();
				this++;
				this += {
					GUI.LABEL : "Internal Comparator",
					GUI.TYPE : GUI.TYPE_SELECT,
					GUI.OPTIONS : [[MinSG.AverageComparator, "Average Comparator"],[MinSG.SSIMComparator, "SSIM Comparator"]],
					GUI.DATA_OBJECT : options,
					GUI.DATA_ATTRIBUTE : $internalComp,
					GUI.DATA_REFRESH_GROUP : refreshGroup
				};
			}
			refreshGroup += [comparator, options]=>fn(comparator, options) {
				comparator.setFilterSize(options.filterSize);
				comparator.setTextureDownloadSize(options.texDownSize);
				comparator.setFilterType(options.filterType);
				if(comparator ---|> MinSG.PyramidComparator){
					comparator.setMinimalTestSize(options.minTestSize);
					comparator.setInternalComparator(new options.internalComp(););
				}
			};
		}
	};
	panel += imageComparatorOptions;
	
	// Make sure the current values are set on the evaluator.
	(panel -> imageComparatorDropDown.onDataChanged)(void);
		
	return panel;
};
return Evaluator;
