/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var Evaluator = new Type(MinSG.ScriptedEvaluator);

Evaluator._constructor ::= fn() {
	this.imageComparator := void;

	this.firstImageDirectory := Std.DataWrapper.createFromEntry(PADrend.configCache, 'MinSG.ImageCompare.firstReadDirectory', "");
	this.secondImageDirectory := Std.DataWrapper.createFromEntry(PADrend.configCache, 'MinSG.ImageCompare.secondReadDirectory', "");
	this.imageCounter := new Std.DataWrapper(0);

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
	var firstFile = this.firstImageDirectory() + "/" + this.imageCounter() + ".png";
	var secondFile = this.secondImageDirectory() + "/" + this.imageCounter() + ".png";
	var firstTexture = Rendering.createTextureFromFile(firstFile);
	var secondTexture = Rendering.createTextureFromFile(secondFile);
	if(	firstTexture.getWidth() != secondTexture.getWidth() ||
		firstTexture.getHeight() != secondTexture.getHeight()) {
		Runtime.warn("Textures differ in width or height.");
		return;
	}
	var resultTexture = Rendering.createStdTexture(firstTexture.getWidth(), firstTexture.getHeight(), true);
	this.imageCounter(this.imageCounter() + 1);

	var value = imageComparator.compare(renderingContext, firstTexture, secondTexture, resultTexture);
	if(!value) {
		Runtime.warn("Image comparison failed.");
		return;
	}
	result = value;
	
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
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(halfW, halfH, width, height), firstTexture, new Geometry.Rect(0, 0, 1, 1));
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(halfW, 0, width, height), secondTexture, new Geometry.Rect(0, 0, 1, 1));
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(0, 0, width, height), resultTexture, new Geometry.Rect(0, 0, 1, 1));
	PADrend.SystemUI.swapBuffers();
	
	return this;
};

Evaluator.getResults @(override) ::= fn() {
	return [result];
};

Evaluator.getMaxValue @(override)  ::= fn() {
	return result;
};

Evaluator.getMode @(override) ::= fn() {
	return MinSG.Evaluator.SINGLE_VALUE;
};

Evaluator.setMode @(override) ::= fn(dummy) {
};

Evaluator.getEvaluatorTypeName @(override) ::= fn() {
	return "ImageReadEvaluator";
};

Evaluator.setImageComparator ::= fn(MinSG.AbstractImageComparator comparator) {
	imageComparator = comparator;
};

Evaluator.createConfigPanel @(override) ::= fn() {
	// parent::createConfigPanel()
	var panel = (this -> MinSG.Evaluator.createConfigPanel)();

	panel += {
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.LABEL			:	"First image directory",
		GUI.TOOLTIP			:	"First directory from which the images will be read",
		GUI.DATA_WRAPPER	:	this.firstImageDirectory,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.LABEL			:	"Second image directory",
		GUI.TOOLTIP			:	"Second directory from which the images will be read",
		GUI.DATA_WRAPPER	:	this.secondImageDirectory,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_NUMBER,
		GUI.LABEL			:	"Image counter",
		GUI.TOOLTIP			:	"Counter that is increased for every written image by one and used as file name",
		GUI.DATA_WRAPPER	:	this.imageCounter,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
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
	imageComparatorDropDown.onDataChanged = [this, panel]=>fn(MinSG.Evaluator evaluator, panel,data) {
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
