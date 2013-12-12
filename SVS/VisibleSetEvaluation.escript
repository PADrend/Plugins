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
declareNamespace($SVS);

SVS.createMeasurementCamera := fn(	MinSG.GroupNode node, 
													MinSG.SVS.VisibilitySphere visibilitySphere, 
													Geometry.Vec3 viewingDirection, 
													Number resolution) {
	var sphere = visibilitySphere.getSphere();
	var worldMatrix = node.getWorldMatrix();
	var camera = MinSG.SVS.createSamplingCamera(sphere,
																worldMatrix,
																resolution);
	MinSG.SVS.transformCamera(camera,
											sphere,
											worldMatrix,
											viewingDirection);
	return camera;
};

SVS.measureExactVisibleSet := fn(	MinSG.GroupNode node,
												MinSG.AbstractCameraNode camera) {
	frameContext.pushAndSetCamera(camera);

	var evaluator = new MinSG.CostEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluator.beginMeasure();
	evaluator.measure(frameContext, node, camera.getViewport());
	evaluator.endMeasure(frameContext);

	frameContext.popCamera();

	return evaluator.getResults().front();
};

SVS.measureVisibleSetQuality := fn(	MinSG.GroupNode node, 
													MinSG.SVS.VisibilitySphere visibilitySphere,
													Number resolution) {
	var fbo = new Rendering.FBO;
	var color = Rendering.createStdTexture(resolution, resolution, true);
	var depth = Rendering.createDepthTexture(resolution, resolution);
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext, color);
	fbo.attachDepthTexture(renderingContext, depth);

	var samples = visibilitySphere.getSamples();
	var output = "Sample\t";
	output += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
	output += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
	output += "OverestimationCardinality\tOverestimationBenefits\tOverestimationCosts\t";
	output += "UnderestimationCardinality\tUnderestimationBenefits\tUnderestimationCosts\n";
	foreach(samples as var index, var sample) {
		var camera = SVS.createMeasurementCamera(node, visibilitySphere, sample.getPosition(), resolution);
		var exactVisibleSet = SVS.measureExactVisibleSet(node, camera);
		var potentiallyVisibleSet = sample.getValue();
		var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
		var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
		output += "" +
					index + "\t" +
					SVS.getVisibleSetStrings(exactVisibleSet) + "\t" +
					SVS.getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
					SVS.getVisibleSetStrings(overestimation) + "\t" +
					SVS.getVisibleSetStrings(underestimation) + "\n";
	}

	renderingContext.popFBO();

	var fileName = Util.createTimeStamp() + "_SVS-VisibleSetEvaluation-Samples-" + resolution + ".tsv";
	if(node.isSet($name) && !node.name.empty()) {
		fileName = node.name.replace(".minsg", "") + "-VisibleSetEvaluation-Samples-" + resolution + ".tsv";
	}
	Util.saveFile(fileName, output);
	outln("Data written to file \"", fileName, "\"");
};

SVS.setUpVisibleSetEvaluationWindow := fn() {
	var width = 300;
	var height = 270;
	var posX = GLOBALS.renderingContext.getWindowWidth() - width;
	var posY = 0;
	var window = gui.createWindow(width, height, "SVS Visible Set Evaluation", GUI.ONE_TIME_WINDOW);
	window.setPosition(posX, posY);

	var panel = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});
	window += panel;

	panel += "*Information*";
	panel++;

	var selectedNode = DataWrapper.createFromFunctions(NodeEditor -> NodeEditor.getSelectedNode, void, true);
	panel += {
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.LABEL			:	"Selected Node:",
		GUI.DATA_WRAPPER	:	selectedNode,
		GUI.FLAGS			:	GUI.LOCKED,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var numSamplingDirections = DataWrapper.createFromValue(0);
	panel += {
		GUI.TYPE			:	GUI.TYPE_NUMBER,
		GUI.LABEL			:	"#SamplingDirections:",
		GUI.TOOLTIP			:	"Number of sampling directions stored in the visibility sphere.",
		GUI.DATA_WRAPPER	:	numSamplingDirections,
		GUI.FLAGS			:	GUI.LOCKED,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Refresh",
		GUI.ON_CLICK		:	selectedNode -> selectedNode.forceRefresh,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var visibilitySphere = DataWrapper.createFromValue(void);
	selectedNode.onDataChanged += [visibilitySphere] => fn(DataWrapper visibilitySphere, selectedNode) {
		if(!selectedNode || !(selectedNode ---|> MinSG.GroupNode)) {
			visibilitySphere(void);
			return;
		}
		// Search a node that has a visibility sphere by traversing the tree
		var nodes = [selectedNode];
		while(!nodes.empty()) {
			var node = nodes.popBack();
			if(MinSG.SVS.hasVisibilitySphere(node)) {
				visibilitySphere(MinSG.SVS.retrieveVisibilitySphere(node));
				return;
			}
			nodes.append(MinSG.getChildNodes(node));
		}
	};
	registerExtension('NodeEditor_OnNodesSelected', [panel, selectedNode] => fn(guiElement, dataWrapper, nodes) {
		if(guiElement.isDestroyed()) {
			return Extension.REMOVE_EXTENSION;
		}
		dataWrapper.refresh();
	});

	visibilitySphere.onDataChanged += [numSamplingDirections] => fn(DataWrapper numSamplingDirections, visibilitySphere) {
		if(!visibilitySphere) {
			numSamplingDirections(0);
			return;
		}
		numSamplingDirections(visibilitySphere.getSamples().count());
	};

	panel += "*Actions*";
	panel++;

	var resolution = DataWrapper.createFromValue(8192);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Resolution",
		GUI.TOOLTIP			:	"Horizontal and vertical resolution in pixels that will be used for rendering.",
		GUI.RANGE			:	[6, 13],
		GUI.RANGE_STEPS		:	7,
		GUI.RANGE_FN_BASE	:	2,
		GUI.DATA_WRAPPER	:	resolution,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var evaluateRandomDirections = fn(MinSG.GroupNode node, 
									  MinSG.SVS.VisibilitySphere visibilitySphere,
									  Number resolution) {
		var fbo = new Rendering.FBO;
		var color = Rendering.createStdTexture(resolution, resolution, true);
		var depth = Rendering.createDepthTexture(resolution, resolution);
		renderingContext.pushAndSetFBO(fbo);
		fbo.attachColorTexture(renderingContext, color);
		fbo.attachDepthTexture(renderingContext, depth);

		var outputNearest = "Inclination\tAzimuth\t";
		outputNearest += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
		outputNearest += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
		outputNearest += "OverestimationCardinality\tOverestimationBenefits\tOverestimationCosts\t";
		outputNearest += "UnderestimationCardinality\tUnderestimationBenefits\tUnderestimationCosts\n";
		var outputMax3 = outputNearest;
		for(var i = 0; i < 2000; ++i) {
			var inclination = (1.0 - Rand.uniform(0.0, 2.0)).acos();
			var azimuth = Rand.uniform(0.0, 2.0 * Math.PI);
			var direction = Geometry.Sphere.calcCartesianCoordinateUnitSphere(inclination, azimuth);

			var pvsNearest = visibilitySphere.queryValue(direction, MinSG.SVS.INTERPOLATION_NEAREST);
			var pvsMax3 = visibilitySphere.queryValue(direction, MinSG.SVS.INTERPOLATION_MAX3);

			var camera = SVS.createMeasurementCamera(node, visibilitySphere, direction, resolution);

			var exactVisibleSet = SVS.measureExactVisibleSet(node, camera);
			{ // NEAREST
				var potentiallyVisibleSet = pvsNearest;
				var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
				var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
				outputNearest += "" +
							inclination + "\t" +
							azimuth + "\t" +
							SVS.getVisibleSetStrings(exactVisibleSet) + "\t" +
							SVS.getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
							SVS.getVisibleSetStrings(overestimation) + "\t" +
							SVS.getVisibleSetStrings(underestimation) + "\n";
			}
			{ // MAX3
				var potentiallyVisibleSet = pvsMax3;
				var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
				var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
				outputMax3 += "" +
							inclination + "\t" +
							azimuth + "\t" +
							SVS.getVisibleSetStrings(exactVisibleSet) + "\t" +
							SVS.getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
							SVS.getVisibleSetStrings(overestimation) + "\t" +
							SVS.getVisibleSetStrings(underestimation) + "\n";
			}
			outln(i, " finished");
		}

		renderingContext.popFBO();

		var fileNameNearest = Util.createTimeStamp() + "_SVS-VisibleSetEvaluation-Directions-" + resolution + "-Nearest.tsv";
		var fileNameMax3 = Util.createTimeStamp() + "_SVS-VisibleSetEvaluation-Directions-" + resolution + "-Max3.tsv";
		Util.saveFile(fileNameNearest, outputNearest);
		Util.saveFile(fileNameMax3, outputMax3);
		outln("Data written to files \"", fileNameNearest, "\" and \"", fileNameMax3, "\".");
	};

	var outputVisibilitySpheretoTSV = fn(MinSG.SVS.VisibilitySphere visibilitySphere) {
		var samples = visibilitySphere.getSamples();
		var output = "Sample\tBenefits\tCosts\n";
		foreach(samples as var sampleIndex, var sample) {
			var visibilityVector = sample.getValue();
			var nodes = visibilityVector.getNodes();
			foreach(nodes as var node) {
				output += "" +
							sampleIndex + "\t" +
							visibilityVector.getBenefits(node) + "\t" +
							visibilityVector.getCosts(node) + "\n";
			}
		}

		var fileName = Util.createTimeStamp() + "_SVS-VisibilitySphere.tsv";
		Util.saveFile(fileName, output);
		outln("Data written to file \"", fileName, "\"");
	};

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Evaluate at sample points",
		GUI.TOOLTIP			:	"Evaluate the quality of the visibility information\nin the sample points of the current sphere by using\ndifferent frustum angles.",
		GUI.ON_CLICK		:	[selectedNode, visibilitySphere, resolution] =>
								fn(DataWrapper selectedNode, 
								   DataWrapper visibilitySphere,
								   DataWrapper resolution) {
									if(!selectedNode()) {
										outln("No node is selected.");
										return;
									}
									if(!visibilitySphere()) {
										outln("No visibility sphere found.");
										return;
									}
									SVS.measureVisibleSetQuality(selectedNode(), visibilitySphere(), resolution());
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Evaluate at random points",
		GUI.TOOLTIP			:	"Evaluate the quality of the visibility information\nfor random viewing directions by using\ndifferent frustum angles.",
		GUI.ON_CLICK		:	[evaluateRandomDirections, selectedNode, visibilitySphere, resolution] =>
								fn(evaluateRandomDirections,
								   DataWrapper selectedNode, 
								   DataWrapper visibilitySphere,
								   DataWrapper resolution) {
									if(!selectedNode()) {
										outln("No node is selected.");
										return;
									}
									if(!visibilitySphere()) {
										outln("No visibility sphere found.");
										return;
									}
									evaluateRandomDirections(selectedNode(), visibilitySphere(), resolution());
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"TSV output",
		GUI.TOOLTIP			:	"Output data of the visibility sphere\nto a file with tab-separated values.",
		GUI.ON_CLICK		:	[outputVisibilitySpheretoTSV, visibilitySphere] =>
								fn(outputVisibilitySpheretoTSV, DataWrapper visibilitySphere) {
									if(!visibilitySphere()) {
										outln("No visibility sphere found.");
										return;
									}
									outputVisibilitySpheretoTSV(visibilitySphere());
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	selectedNode.forceRefresh();
};
