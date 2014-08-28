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

SVS.setUpProjectionEvaluationWindow := fn() {
	var width = 300;
	var height = 270;
	var posX = GLOBALS.renderingContext.getWindowWidth() - width;
	var posY = 0;
	var window = gui.createWindow(width, height, "SVS Projection Evaluation", GUI.ONE_TIME_WINDOW);
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
	selectedNode.onDataChanged += fn(selectedNode, DataWrapper visibilitySphere) {
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
	}.bindLastParams(visibilitySphere);
	registerExtension('NodeEditor_OnNodesSelected', fn(nodes, guiElement, dataWrapper) {
		if(guiElement.isDestroyed()) {
			return Extension.REMOVE_EXTENSION;
		}
		dataWrapper.refresh();
	}.bindLastParams(panel, selectedNode));

	visibilitySphere.onDataChanged += fn(visibilitySphere, DataWrapper numSamplingDirections) {
		if(!visibilitySphere) {
			numSamplingDirections(0);
			return;
		}
		numSamplingDirections(visibilitySphere.getSamples().count());
	}.bindLastParams(numSamplingDirections);

	panel += "*Actions*";
	panel++;

	var sampleIndex = DataWrapper.createFromValue(0);
	panel += {
		GUI.TYPE			:	GUI.TYPE_NUMBER,
		GUI.LABEL			:	"Sample index",
		GUI.TOOLTIP			:	"Index of the sample that is used for actions.",
		GUI.DATA_WRAPPER	:	sampleIndex,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var frustumAngle = DataWrapper.createFromValue(1);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Frustum angle",
		GUI.TOOLTIP			:	"Apex angle of the camera frustum.",
		GUI.RANGE			:	[1, 90],
		GUI.RANGE_STEP_SIZE :	1,
		GUI.DATA_WRAPPER	:	frustumAngle,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var resolution = DataWrapper.createFromValue(512);
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

	var createCamera = fn(MinSG.GroupNode node, 
						  MinSG.SVS.VisibilitySphere visibilitySphere, 
						  Geometry.Vec3 viewingDirection, 
						  Number frustumAngle,
						  Number resolution) {
		var worldSphere = MinSG.SVS.transformSphere(visibilitySphere.getSphere(),
																  node.getWorldTransformationMatrix());
		var radius = worldSphere.getRadius();
		// Make sure that the camera is not exactly on the sphere surface
		var cameraDistance = 1.001;

		var camera = void;
		if(frustumAngle == 0) {
			camera = new MinSG.CameraNodeOrtho;
			camera.setClippingPlanes(-radius, radius, -radius, radius);
			cameraDistance *= radius;
		} else {
			camera = new MinSG.CameraNode;
			var halfAngle = frustumAngle / 2.0;
			camera.setAngles(-halfAngle, halfAngle, -halfAngle, halfAngle);
			cameraDistance *= radius / halfAngle.degToRad().sin();
		}
		if(cameraDistance <= radius) {
			outln("Camera is not outside the sphere.");
			return;
		}

		camera.setViewport(new Geometry.Rect(0, 0, resolution, resolution));

		// Make sure the sphere is enclosed by near and far plane
		camera.setNearFar(cameraDistance - radius, cameraDistance + radius);

		camera.setWorldOrigin(worldSphere.getCenter() + viewingDirection * cameraDistance);
		camera.rotateToWorldDir(viewingDirection);

		return camera;
	};

	var computeExactVisibleSet = fn(MinSG.GroupNode node,
									MinSG.AbstractCameraNode camera) {
		frameContext.pushAndSetCamera(camera);

		var evaluator = new MinSG.CostEvaluator(MinSG.Evaluator.SINGLE_VALUE);
		evaluator.beginMeasure();
		evaluator.measure(frameContext, node, camera.getViewport());
		evaluator.endMeasure(frameContext);

		frameContext.popCamera();

		return evaluator.getResults().front();
	};

	var evaluateSamplePoints = fn(createCamera,
								  computeExactVisibleSet,
								  getVisibleSetStrings,
								  MinSG.GroupNode node, 
								  MinSG.SVS.VisibilitySphere visibilitySphere,
								  Number resolution) {
		var fbo = new Rendering.FBO();
		var color = Rendering.createStdTexture(resolution, resolution, true);
		var depth = Rendering.createDepthTexture(resolution, resolution);
		renderingContext.pushAndSetFBO(fbo);
		fbo.attachColorTexture(renderingContext, color);
		fbo.attachDepthTexture(renderingContext, depth);

		var samples = visibilitySphere.getSamples();
		var output = "Sample\tFrustumAngle\t";
		output += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
		output += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
		output += "OverestimationCardinality\tOverestimationBenefits\tOverestimationCosts\t";
		output += "UnderestimationCardinality\tUnderestimationBenefits\tUnderestimationCosts\n";
		foreach(samples as var index, var sample) {
			for(var angle = 0; angle <= 90; ++angle) {
				var camera = createCamera(node, visibilitySphere, sample.getPosition(), angle, resolution);
				var exactVisibleSet = computeExactVisibleSet(node, camera);
				var potentiallyVisibleSet = sample.getValue();
				var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
				var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
				output += "" +
							index + "\t" +
							angle + "\t" +
							getVisibleSetStrings(exactVisibleSet) + "\t" +
							getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
							getVisibleSetStrings(overestimation) + "\t" +
							getVisibleSetStrings(underestimation) + "\n";
			}
		}

		renderingContext.popFBO();

		var fileName = Util.createTimeStamp() + "_SVS-ProjectionEvaluation-Samples-" + resolution + ".tsv";
		Util.saveFile(fileName, output);
		outln("Data written to file \"", fileName, "\"");
	}.bindFirstParams(createCamera, computeExactVisibleSet, SVS.getVisibleSetStrings);

	var evaluateRandomDirections = fn(createCamera,
									  computeExactVisibleSet,
									  getVisibleSetStrings,
									  MinSG.GroupNode node, 
									  MinSG.SVS.VisibilitySphere visibilitySphere,
									  Number resolution) {
		var fbo = new Rendering.FBO();
		var color = Rendering.createStdTexture(resolution, resolution, true);
		var depth = Rendering.createDepthTexture(resolution, resolution);
		renderingContext.pushAndSetFBO(fbo);
		fbo.attachColorTexture(renderingContext, color);
		fbo.attachDepthTexture(renderingContext, depth);

		var outputNearest = "Inclination\tAzimuth\tFrustumAngle\t";
		outputNearest += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
		outputNearest += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
		outputNearest += "OverestimationCardinality\tOverestimationBenefits\tOverestimationCosts\t";
		outputNearest += "UnderestimationCardinality\tUnderestimationBenefits\tUnderestimationCosts\n";
		var outputMax3 = outputNearest;
		var outputNearestOrthoDiff = "Inclination\tAzimuth\tFrustumAngle\t";
		outputNearestOrthoDiff += "EVSCardinality\tEVSBenefits\tEVSCosts\t";
		outputNearestOrthoDiff += "PVSCardinality\tPVSBenefits\tPVSCosts\t";
		outputNearestOrthoDiff += "DiffCardinality\tDiffBenefits\tDiffCosts\n";
		var outputMax3OrthoDiff = outputNearestOrthoDiff;
		for(var i = 0; i < 10000; ++i) {
			var inclination = (1.0 - Rand.uniform(0.0, 2.0)).acos();
			var azimuth = Rand.uniform(0.0, 2.0 * Math.PI);
			var direction = Geometry.Sphere.calcCartesianCoordinateUnitSphere(inclination, azimuth);

			var pvsNearest = visibilitySphere.queryValue(direction, MinSG.SVS.INTERPOLATION_NEAREST);
			var pvsMax3 = visibilitySphere.queryValue(direction, MinSG.SVS.INTERPOLATION_MAX3);

			var underestimationOrthoNearest = void;
			var underestimationOrthoMax3 = void;

			for(var frustumAngle = 0; frustumAngle <= 90; frustumAngle += 15) {
				var camera = createCamera(node, visibilitySphere, direction, frustumAngle, resolution);

				var exactVisibleSet = computeExactVisibleSet(node, camera);
				{ // NEAREST
					var potentiallyVisibleSet = pvsNearest;
					var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
					var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
					outputNearest += "" +
								inclination + "\t" +
								azimuth + "\t" +
								frustumAngle + "\t" +
								getVisibleSetStrings(exactVisibleSet) + "\t" +
								getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
								getVisibleSetStrings(overestimation) + "\t" +
								getVisibleSetStrings(underestimation) + "\n";
					if(frustumAngle == 0) {
						underestimationOrthoNearest = underestimation;
					}
					var orthoDiff = underestimation.makeDifference(underestimationOrthoNearest);
					outputNearestOrthoDiff += "" +
								inclination + "\t" +
								azimuth + "\t" +
								frustumAngle + "\t" +
								getVisibleSetStrings(exactVisibleSet) + "\t" +
								getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
								getVisibleSetStrings(orthoDiff) + "\n";
				}
				{ // MAX3
					var potentiallyVisibleSet = pvsMax3;
					var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
					var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
					outputMax3 += "" +
								inclination + "\t" +
								azimuth + "\t" +
								frustumAngle + "\t" +
								getVisibleSetStrings(exactVisibleSet) + "\t" +
								getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
								getVisibleSetStrings(overestimation) + "\t" +
								getVisibleSetStrings(underestimation) + "\n";
					if(frustumAngle == 0) {
						underestimationOrthoMax3 = underestimation;
					}
					var orthoDiff = underestimation.makeDifference(underestimationOrthoMax3);
					outputMax3OrthoDiff += "" +
								inclination + "\t" +
								azimuth + "\t" +
								frustumAngle + "\t" +
								getVisibleSetStrings(exactVisibleSet) + "\t" +
								getVisibleSetStrings(potentiallyVisibleSet) + "\t" +
								getVisibleSetStrings(orthoDiff) + "\n";
				}
			}
			outln(i, " finished");
		}

		renderingContext.popFBO();

		var fileNameNearest = Util.createTimeStamp() + "_SVS-ProjectionEvaluation-Directions-" + resolution + "-Nearest.tsv";
		var fileNameMax3 = Util.createTimeStamp() + "_SVS-ProjectionEvaluation-Directions-" + resolution + "-Max3.tsv";
		Util.saveFile(fileNameNearest, outputNearest);
		Util.saveFile(fileNameMax3, outputMax3);
		outln("Data written to files \"", fileNameNearest, "\" and \"", fileNameMax3, "\".");
		var fileNameDiffNearest = Util.createTimeStamp() + "_SVS-ProjectionEvaluation-Directions-" + resolution + "-Nearest-Diff.tsv";
		var fileNameDiffMax3 = Util.createTimeStamp() + "_SVS-ProjectionEvaluation-Directions-" + resolution + "-Max3-Diff.tsv";
		Util.saveFile(fileNameDiffNearest, outputNearestOrthoDiff);
		Util.saveFile(fileNameDiffMax3, outputMax3OrthoDiff);
		outln("Difference data written to files \"", fileNameDiffNearest, "\" and \"", fileNameDiffMax3, "\".");
	}.bindFirstParams(createCamera, computeExactVisibleSet, SVS.getVisibleSetStrings);

	var randomDirectionsEvaluator = fn(createCamera,
									   MinSG.GroupNode node, 
									   MinSG.SVS.VisibilitySphere visibilitySphere,
									   Number resolution) {
		var fbo = new Rendering.FBO();
		var color = Rendering.createStdTexture(resolution, resolution, true);
		var depth = Rendering.createDepthTexture(resolution, resolution);
		renderingContext.pushAndSetFBO(fbo);
		fbo.attachColorTexture(renderingContext, color);
		fbo.attachDepthTexture(renderingContext, depth);

		var evaluator = EvaluatorManager.getSelectedEvaluator();
		if(!evaluator) {
			Runtime.exception("Invalid evaluator.");
		}

		var output = "Inclination\tAzimuth\tFrustumAngle\tValue\n";
		for(var i = 0; i < 300; ++i) {
			var inclination = (1.0 - Rand.uniform(0.0, 2.0)).acos();
			var azimuth = Rand.uniform(0.0, 2.0 * Math.PI);
			var direction = Geometry.Sphere.calcCartesianCoordinateUnitSphere(inclination, azimuth);

			for(var frustumAngle = 0; frustumAngle <= 90; frustumAngle += 5) {
				var camera = createCamera(node, visibilitySphere, direction, frustumAngle, resolution);

				frameContext.pushAndSetCamera(camera);

				evaluator.beginMeasure();
				evaluator.measure(frameContext, node, camera.getViewport());
				evaluator.endMeasure(frameContext);

				frameContext.popCamera();

				output += "" +
							inclination + "\t" +
							azimuth + "\t" +
							frustumAngle + "\t" +
							evaluator.getResults().front() + "\n";
			}
			outln(i, " finished");
		}

		renderingContext.popFBO();

		var fileName = Util.createTimeStamp() + "_SVS-ProjectionEvaluation-Evaluator-" + resolution + ".tsv";
		Util.saveFile(fileName, output);
		outln("Data written to file \"", fileName, "\"");
	}.bindFirstParams(createCamera);

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
		GUI.LABEL			:	"Set new camera",
		GUI.TOOLTIP			:	"Create a camera using the given frustum angle and transform it to use the viewing direction of the current sample.",
		GUI.ON_CLICK		:	fn(createCamera,
								   DataWrapper selectedNode, 
								   DataWrapper visibilitySphere, 
								   DataWrapper sampleIndex, 
								   DataWrapper frustumAngle,
								   DataWrapper resolution) {
									if(!selectedNode()) {
										outln("No node is selected.");
										return;
									}
									if(!visibilitySphere()) {
										outln("No visibility sphere found.");
										return;
									}
									var samples = visibilitySphere().getSamples();
									if(sampleIndex() >= samples.count()) {
										outln("Invalid sample index.");
										return;
									}
									var camera = createCamera(selectedNode(), visibilitySphere(), samples[sampleIndex()].getPosition(), frustumAngle(), resolution());
									var dolly = PADrend.getCameraMover().getDolly();
									dolly.setRelTransformation(camera.getRelTransformationSRT());
									PADrend.getActiveCamera().setAngles(camera.getAngles());
									PADrend.getActiveCamera().setNearFar(camera.getNearPlane(), camera.getFarPlane());
								}.bindFirstParams(createCamera, selectedNode, visibilitySphere, sampleIndex, frustumAngle, resolution),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Output over- and underestimation",
		GUI.TOOLTIP			:	"Output the difference between the exact visible set\nand the potentially visible set.",
		GUI.ON_CLICK		:	fn(computeExactVisibleSet,
								   DataWrapper selectedNode, 
								   DataWrapper visibilitySphere, 
								   DataWrapper sampleIndex) {
									if(!selectedNode()) {
										outln("No node is selected.");
										return;
									}
									if(!visibilitySphere()) {
										outln("No visibility sphere found.");
										return;
									}
									var samples = visibilitySphere().getSamples();
									if(sampleIndex() >= samples.count()) {
										outln("Invalid sample index.");
										return;
									}
									var exactVisibleSet = computeExactVisibleSet(selectedNode(), PADrend.getActiveCamera());
									var potentiallyVisibleSet = samples[sampleIndex()].getValue();
									var overestimation = potentiallyVisibleSet.makeDifference(exactVisibleSet);
									var underestimation = exactVisibleSet.makeDifference(potentiallyVisibleSet);
									out("Overestimation:");
									print_r(overestimation);
									out("Underestimation:");
									print_r(underestimation);
								}.bindFirstParams(computeExactVisibleSet, selectedNode, visibilitySphere, sampleIndex),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Evaluate sample points",
		GUI.TOOLTIP			:	"Evaluate the quality of the visibility information\nin the sample points of the current sphere by using\ndifferent frustum angles.",
		GUI.ON_CLICK		:	fn(evaluateSamplePoints,
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
									evaluateSamplePoints(selectedNode(), visibilitySphere(), resolution());
								}.bindFirstParams(evaluateSamplePoints, selectedNode, visibilitySphere, resolution),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Evaluate random directions",
		GUI.TOOLTIP			:	"Evaluate the quality of the visibility information\nfor random viewing directions by using\ndifferent frustum angles.",
		GUI.ON_CLICK		:	fn(evaluateRandomDirections,
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
								}.bindFirstParams(evaluateRandomDirections, selectedNode, visibilitySphere, resolution),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Random directions with evaluator",
		GUI.TOOLTIP			:	"Measure using an evaluator for random\nviewing directions by using\ndifferent frustum angles.",
		GUI.ON_CLICK		:	fn(randomDirectionsEvaluator,
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
									randomDirectionsEvaluator(selectedNode(), visibilitySphere(), resolution());
								}.bindFirstParams(randomDirectionsEvaluator, selectedNode, visibilitySphere, resolution),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"TSV output",
		GUI.TOOLTIP			:	"Output data of the visibility sphere\nto a file with tab-separated values.",
		GUI.ON_CLICK		:	fn(outputVisibilitySpheretoTSV, DataWrapper visibilitySphere) {
									if(!visibilitySphere()) {
										outln("No visibility sphere found.");
										return;
									}
									outputVisibilitySpheretoTSV(visibilitySphere());
								}.bindFirstParams(outputVisibilitySpheretoTSV, visibilitySphere),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	selectedNode.forceRefresh();
};
